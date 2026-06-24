from typing import Optional
from pydantic import BaseModel


class MountPointDto(BaseModel):
    point_uuid: str
    type: Optional[str] = None
    label: Optional[str] = None
    geo: Optional[str] = None
    x: Optional[float] = None
    y: Optional[float] = None
    item: Optional[str] = None
    serial_no: Optional[str] = None
    status: Optional[str] = None
    photo: Optional[str] = None
    note: Optional[str] = None


class CableRouteDto(BaseModel):
    route_uuid: str
    from_point: Optional[str] = None
    to_point: Optional[str] = None
    cable_type: Optional[str] = None
    length_m: Optional[float] = None
    path: Optional[list] = None


class MapResponse(BaseModel):
    name: str
    passport: Optional[str] = None
    map_kind: str
    base_plan_media: Optional[str] = None
    approved_by: Optional[str] = None
    approved_at: Optional[str] = None
    mount_points: list[MountPointDto] = []
    cable_routes: list[CableRouteDto] = []


class MapPointRequest(BaseModel):
    point_uuid: str
    type: Optional[str] = None
    label: Optional[str] = None
    geo: Optional[str] = None
    x: Optional[float] = None
    y: Optional[float] = None
    item: Optional[str] = None
    serial_no: Optional[str] = None
    status: Optional[str] = None
    photo: Optional[str] = None
    note: Optional[str] = None


class MapPointResponse(BaseModel):
    point_uuid: str
    status: str


class MapApproveResponse(BaseModel):
    name: str
    approved_by: str
    approved_at: str


class WarehouseSerialDto(BaseModel):
    name: str
    serial_no: str
    item: Optional[str] = None
    item_name: Optional[str] = None
    status: Optional[str] = None
    warehouse: Optional[str] = None


class WarehouseSerialsResponse(BaseModel):
    items: list[WarehouseSerialDto]
    total: int
    page: int
    page_size: int


class WarehouseStockItemDto(BaseModel):
    item_code: str
    item_name: Optional[str] = None
    qty: float = 0
    warehouse: Optional[str] = None


class WarehouseStockResponse(BaseModel):
    items: list[WarehouseStockItemDto]


class WarehouseStockDetailResponse(BaseModel):
    item_code: str
    item_name: Optional[str] = None
    qty: float = 0
    warehouse: Optional[str] = None
    serials: list[WarehouseSerialDto] = []
