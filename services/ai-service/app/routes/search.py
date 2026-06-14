from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone
import uuid
import json
import time

from app.core.database import get_db
from app.models.knowledge import KnowledgeDocument, KnowledgeChunk, SearchLog

router = APIRouter(prefix="/api/v1/ai", tags=["ai"])


@router.get("/search")
async def knowledge_search(
    q: str = Query(..., min_length=2),
    doc_type: str = None,
    limit: int = Query(10, le=50),
    db: AsyncSession = Depends(get_db),
):
    start = time.time()

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
    documents = result.scalars().all()

    elapsed_ms = int((time.time() - start) * 1000)

    log = SearchLog(
        id=uuid.uuid4(),
        query=q,
        results_count=len(documents),
        top_result_id=documents[0].id if documents else None,
        response_time_ms=elapsed_ms,
    )
    db.add(log)
    await db.commit()

    return {
        "success": True,
        "data": [
            {
                "id": str(d.id),
                "title": d.title,
                "content": d.content[:500],
                "doc_type": d.doc_type,
                "tags": d.tags,
                "score": 1.0,
            }
            for d in documents
        ],
        "meta": {"query": q, "count": len(documents), "time_ms": elapsed_ms},
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
    await db.commit()
    return {"success": True, "data": {"id": str(doc.id)}}


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
    return {"success": True, "data": docs}


@router.get("/documents/{doc_id}")
async def get_document(doc_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(KnowledgeDocument).where(KnowledgeDocument.id == doc_id))
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    return {"success": True, "data": doc}


@router.delete("/documents/{doc_id}")
async def delete_document(doc_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(KnowledgeDocument).where(KnowledgeDocument.id == doc_id))
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    doc.is_active = False
    await db.commit()
    return {"success": True, "message": "Document deleted"}


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

    return {
        "success": True,
        "data": {
            "documents": docs_count,
            "chunks": chunks_count,
            "searches": searches_count,
        },
    }
