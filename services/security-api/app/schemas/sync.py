from __future__ import annotations

from typing import Any, Optional

from pydantic import BaseModel, Field


class SyncPullRequest(BaseModel):
    device_id: str
    watermark: Optional[str] = None  # opaque base64 token; None = full sync


class SyncPullChange(BaseModel):
    doctype: str
    name: str
    riad_version: int
    riad_deleted: bool
    riad_deleted_at: Optional[str] = None
    fields: dict[str, Any] = Field(default_factory=dict)
    additive: dict[str, list[dict[str, Any]]] = Field(default_factory=dict)


class SyncPullResponse(BaseModel):
    changes: list[SyncPullChange]
    next_watermark: str


class SyncPushAdditiveRow(BaseModel):
    model_config = {"extra": "allow", "populate_by_name": True}

    uuid: str = Field(alias="_uuid", default="")
    op: str = "add"  # "add" | "delete"


class SyncPushItem(BaseModel):
    doctype: str
    name: str
    op: str  # "upsert" | "delete"
    client_base_version: int
    scalars: dict[str, Any] = Field(default_factory=dict)
    additive: dict[str, list[dict[str, Any]]] = Field(default_factory=dict)


class SyncPushRequest(BaseModel):
    device_id: str
    batch: list[SyncPushItem]


class SyncConflictInfo(BaseModel):
    field: str
    server_value: Any
    client_value: Any
    conflict_id: str


class SyncAdditiveResult(BaseModel):
    added: list[str] = Field(default_factory=list)
    already_present: list[str] = Field(default_factory=list)


class SyncPushItemResult(BaseModel):
    name: str
    status: str  # applied | merged | conflict | tombstoned | ignored_duplicate
    server_version: int
    additive: dict[str, SyncAdditiveResult] = Field(default_factory=dict)
    conflicts: list[SyncConflictInfo] = Field(default_factory=list)


class SyncPushResponse(BaseModel):
    results: list[SyncPushItemResult]


class SyncResolveRequest(BaseModel):
    conflict_id: str
    chosen: str  # "server" | "client"


class SyncResolveResponse(BaseModel):
    conflict_id: str
    status: str
    chosen: str
