import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase
import enum


class Base(DeclarativeBase):
    pass


class UserRole(str, enum.Enum):
    OWNER = "owner"
    DIRECTOR = "director"
    SALES_MANAGER = "sales_manager"
    PROJECT_MANAGER = "project_manager"
    SERVICE_MANAGER = "service_manager"
    ENGINEER = "engineer"
    WAREHOUSE = "warehouse"
    ACCOUNTANT = "accountant"
    VIEWER = "viewer"


class User(Base):
    __tablename__ = "users"
    __table_args__ = {"schema": "integration"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    username = Column(String(100), unique=True, nullable=False, index=True)
    full_name = Column(String(255), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(SAEnum(UserRole), nullable=False, default=UserRole.VIEWER)
    employee_id = Column(UUID(as_uuid=True), nullable=True)
    is_active = Column(Boolean, default=True)
    mfa_enabled = Column(Boolean, default=False)
    mfa_secret = Column(String(100), nullable=True)
    last_login = Column(DateTime(timezone=True), nullable=True)
    failed_login_attempts = Column(String(10), default="0")
    locked_until = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class AuditLog(Base):
    __tablename__ = "audit_log"
    __table_args__ = {"schema": "audit"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=True, index=True)
    action = Column(String(50), nullable=False)
    entity_type = Column(String(100), nullable=False, index=True)
    entity_id = Column(UUID(as_uuid=True), nullable=True)
    details = Column(String(2000), nullable=True)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(String(500), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
