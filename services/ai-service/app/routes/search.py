from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy import select, func, or_, text
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone
from typing import List
import uuid
import json
import time
import numpy as np

from app.core.database import get_db
from app.models.knowledge import KnowledgeDocument, KnowledgeChunk, SearchLog
from app.services.embeddings import generate_embedding, generate_embeddings, chunk_text

router = APIRouter(prefix="/api/v1/ai", tags=["ai"])


def cosine_similarity(a: List[float], b: List[float]) -> float:
    a_np = np.array(a)
    b_np = np.array(b)
    dot = np.dot(a_np, b_np)
    norm_a = np.linalg.norm(a_np)
    norm_b = np.linalg.norm(b_np)
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return float(dot / (norm_a * norm_b))


@router.get("/search")
async def knowledge_search(
    q: str = Query(..., min_length=2),
    doc_type: str = None,
    limit: int = Query(10, le=50),
    use_vectors: bool = Query(True),
    db: AsyncSession = Depends(get_db),
):
    start = time.time()

    if use_vectors:
        query_embedding = generate_embedding(q)

        chunk_query = select(KnowledgeChunk).join(
            KnowledgeDocument, KnowledgeChunk.document_id == KnowledgeDocument.id
        ).where(KnowledgeDocument.is_active == True)

        if doc_type:
            chunk_query = chunk_query.where(KnowledgeDocument.doc_type == doc_type)

        result = await db.execute(chunk_query)
        all_chunks = result.scalars().all()

        scored = []
        for chunk in all_chunks:
            if chunk.embedding:
                score = cosine_similarity(query_embedding, chunk.embedding)
                scored.append((chunk, score))

        scored.sort(key=lambda x: x[1], reverse=True)
        top_chunks = scored[:limit]

        documents = []
        seen_docs = set()
        for chunk, score in top_chunks:
            if chunk.document_id not in seen_docs:
                seen_docs.add(chunk.document_id)
                doc_result = await db.execute(
                    select(KnowledgeDocument).where(KnowledgeDocument.id == chunk.document_id)
                )
                doc = doc_result.scalar_one_or_none()
                if doc:
                    documents.append({
                        "id": str(doc.id),
                        "title": doc.title,
                        "content": chunk.content[:500],
                        "doc_type": doc.doc_type,
                        "tags": doc.tags,
                        "score": round(score, 4),
                    })
    else:
        query = (
            select(KnowledgeDocument)
            .where(
                KnowledgeDocument.is_active == True,
                or_(
                    KnowledgeDocument.title.ilike(f"%{q}%"),
                    KnowledgeDocument.content.ilike(f"%{q}%"),
                    KnowledgeDocument.tags.ilike(f"%{q}%"),
                ),
            )
        )
        if doc_type:
            query = query.where(KnowledgeDocument.doc_type == doc_type)
        query = query.limit(limit)

        result = await db.execute(query)
        docs = result.scalars().all()
        documents = [
            {
                "id": str(d.id),
                "title": d.title,
                "content": d.content[:500],
                "doc_type": d.doc_type,
                "tags": d.tags,
                "score": 1.0,
            }
            for d in docs
        ]

    elapsed_ms = int((time.time() - start) * 1000)

    log = SearchLog(
        id=uuid.uuid4(),
        query=q,
        results_count=len(documents),
        top_result_id=uuid.UUID(documents[0]["id"]) if documents else None,
        response_time_ms=elapsed_ms,
    )
    db.add(log)
    await db.commit()

    return {
        "success": True,
        "data": documents,
        "meta": {"query": q, "count": len(documents), "time_ms": elapsed_ms, "vector_search": use_vectors},
    }


@router.post("/documents")
async def create_document(data: dict, db: AsyncSession = Depends(get_db)):
    doc = KnowledgeDocument(
        id=uuid.uuid4(),
        title=data.get("title"),
        content=data.get("content"),
        doc_type=data.get("doc_type", "guide"),
        source=data.get("source"),
        tags=data.get("tags"),
    )
    db.add(doc)
    await db.flush()

    chunks = chunk_text(doc.content)
    if chunks:
        embeddings = generate_embeddings(chunks)
        for i, (chunk_content, embedding) in enumerate(zip(chunks, embeddings)):
            chunk = KnowledgeChunk(
                id=uuid.uuid4(),
                document_id=doc.id,
                chunk_index=i,
                content=chunk_content,
                embedding=embedding,
                tokens=len(chunk_content.split()),
            )
            db.add(chunk)
        doc.embedding_status = "done"

    await db.commit()
    return {"success": True, "data": {"id": str(doc.id), "chunks": len(chunks)}}


@router.post("/documents/upload")
async def upload_document(
    file: UploadFile = File(...),
    doc_type: str = "guide",
    tags: str = "",
    db: AsyncSession = Depends(get_db),
):
    content = await file.read()
    text_content = content.decode("utf-8", errors="ignore")

    if not text_content.strip():
        raise HTTPException(status_code=400, detail="Empty file")

    doc = KnowledgeDocument(
        id=uuid.uuid4(),
        title=file.filename or "Uploaded document",
        content=text_content,
        doc_type=doc_type,
        source=f"upload:{file.filename}",
        tags=tags,
    )
    db.add(doc)
    await db.flush()

    chunks = chunk_text(text_content)
    if chunks:
        embeddings = generate_embeddings(chunks)
        for i, (chunk_content, embedding) in enumerate(zip(chunks, embeddings)):
            chunk = KnowledgeChunk(
                id=uuid.uuid4(),
                document_id=doc.id,
                chunk_index=i,
                content=chunk_content,
                embedding=embedding,
                tokens=len(chunk_content.split()),
            )
            db.add(chunk)
        doc.embedding_status = "done"

    await db.commit()
    return {"success": True, "data": {"id": str(doc.id), "chunks": len(chunks), "filename": file.filename}}


@router.post("/documents/batch")
async def batch_create_documents(data: dict, db: AsyncSession = Depends(get_db)):
    documents = data.get("documents", [])
    if not documents:
        raise HTTPException(status_code=400, detail="No documents provided")

    created = []
    for doc_data in documents:
        doc = KnowledgeDocument(
            id=uuid.uuid4(),
            title=doc_data.get("title"),
            content=doc_data.get("content"),
            doc_type=doc_data.get("doc_type", "guide"),
            source=doc_data.get("source"),
            tags=doc_data.get("tags"),
        )
        db.add(doc)
        await db.flush()

        chunks = chunk_text(doc.content)
        if chunks:
            embeddings = generate_embeddings(chunks)
            for i, (chunk_content, embedding) in enumerate(zip(chunks, embeddings)):
                chunk = KnowledgeChunk(
                    id=uuid.uuid4(),
                    document_id=doc.id,
                    chunk_index=i,
                    content=chunk_content,
                    embedding=embedding,
                    tokens=len(chunk_content.split()),
                )
                db.add(chunk)
            doc.embedding_status = "done"

        created.append({"id": str(doc.id), "chunks": len(chunks)})

    await db.commit()
    return {"success": True, "data": {"created": len(created), "documents": created}}


@router.get("/documents")
async def list_documents(
    doc_type: str = None,
    limit: int = Query(50, le=200),
    db: AsyncSession = Depends(get_db),
):
    query = select(KnowledgeDocument).where(KnowledgeDocument.is_active == True)
    if doc_type:
        query = query.where(KnowledgeDocument.doc_type == doc_type)
    query = query.order_by(KnowledgeDocument.created_at.desc()).limit(limit)

    result = await db.execute(query)
    docs = result.scalars().all()
    return {
        "success": True,
        "data": [
            {
                "id": str(d.id),
                "title": d.title,
                "doc_type": d.doc_type,
                "tags": d.tags,
                "embedding_status": d.embedding_status,
                "created_at": d.created_at.isoformat() if d.created_at else None,
            }
            for d in docs
        ],
    }


@router.get("/documents/{doc_id}")
async def get_document(doc_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(KnowledgeDocument).where(KnowledgeDocument.id == doc_id))
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    chunks_result = await db.execute(
        select(KnowledgeChunk)
        .where(KnowledgeChunk.document_id == doc.id)
        .order_by(KnowledgeChunk.chunk_index)
    )
    chunks = chunks_result.scalars().all()

    return {
        "success": True,
        "data": {
            "id": str(doc.id),
            "title": doc.title,
            "content": doc.content,
            "doc_type": doc.doc_type,
            "tags": doc.tags,
            "source": doc.source,
            "chunks": len(chunks),
            "embedding_status": doc.embedding_status,
            "created_at": doc.created_at.isoformat() if doc.created_at else None,
        },
    }


@router.delete("/documents/{doc_id}")
async def delete_document(doc_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(KnowledgeDocument).where(KnowledgeDocument.id == doc_id))
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    await db.execute(
        text("DELETE FROM ai.knowledge_chunks WHERE document_id = :doc_id"),
        {"doc_id": doc_id},
    )
    doc.is_active = False
    await db.commit()
    return {"success": True, "message": "Document and chunks deleted"}


@router.get("/stats")
async def get_stats(db: AsyncSession = Depends(get_db)):
    docs_count = (await db.execute(
        select(func.count()).select_from(KnowledgeDocument).where(KnowledgeDocument.is_active == True)
    )).scalar()

    chunks_count = (await db.execute(
        select(func.count()).select_from(KnowledgeChunk)
    )).scalar()

    searches_count = (await db.execute(
        select(func.count()).select_from(SearchLog)
    )).scalar()

    embedded_count = (await db.execute(
        select(func.count()).select_from(KnowledgeChunk).where(KnowledgeChunk.embedding.isnot(None))
    )).scalar()

    return {
        "success": True,
        "data": {
            "documents": docs_count,
            "chunks": chunks_count,
            "embedded_chunks": embedded_count,
            "searches": searches_count,
            "embedding_coverage": f"{embedded_count}/{chunks_count}" if chunks_count > 0 else "0/0",
        },
    }


@router.post("/reindex")
async def reindex_documents(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(KnowledgeDocument).where(
            KnowledgeDocument.is_active == True,
            KnowledgeDocument.embedding_status != "done",
        )
    )
    docs = result.scalars().all()

    reindexed = 0
    for doc in docs:
        await db.execute(
            text("DELETE FROM ai.knowledge_chunks WHERE document_id = :doc_id"),
            {"doc_id": str(doc.id)},
        )

        chunks = chunk_text(doc.content)
        if chunks:
            embeddings = generate_embeddings(chunks)
            for i, (chunk_content, embedding) in enumerate(zip(chunks, embeddings)):
                chunk = KnowledgeChunk(
                    id=uuid.uuid4(),
                    document_id=doc.id,
                    chunk_index=i,
                    content=chunk_content,
                    embedding=embedding,
                    tokens=len(chunk_content.split()),
                )
                db.add(chunk)
            doc.embedding_status = "done"
            reindexed += 1

    await db.commit()
    return {"success": True, "data": {"reindexed": reindexed}}
