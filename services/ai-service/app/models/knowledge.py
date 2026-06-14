import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Text, Float, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class KnowledgeDocument(Base):
    __tablename__ = "knowledge_documents"
    __table_args__ = {"schema": "ai"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String(500), nullable=False)
    content = Column(Text, nullable=False)
    doc_type = Column(String(50), nullable=False)  # manual, spec, guide, faq, ticket_solution
    source = Column(String(255), nullable=True)  # file path, URL, etc.
    tags = Column(Text, nullable=True)  # comma-separated
    embedding_status = Column(String(20), default="pending")  # pending, processing, done, error
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(UUID(as_uuid=True), nullable=True)


class KnowledgeChunk(Base):
    __tablename__ = "knowledge_chunks"
    __table_args__ = {"schema": "ai"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    document_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    chunk_index = Column(Integer, nullable=False)
    content = Column(Text, nullable=False)
    embedding = Column(Text, nullable=True)  # JSON array of floats
    tokens = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class SearchLog(Base):
    __tablename__ = "search_logs"
    __table_args__ = {"schema": "ai"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=True)
    query = Column(Text, nullable=False)
    results_count = Column(Integer, default=0)
    top_result_id = Column(UUID(as_uuid=True), nullable=True)
    response_time_ms = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
