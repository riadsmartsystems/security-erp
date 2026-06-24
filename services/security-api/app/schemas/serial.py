from typing import Optional
from pydantic import BaseModel


class SerialScanRequest(BaseModel):
    serial_no: str
    item: Optional[str] = None
    visit_uuid: Optional[str] = None


class SerialScanResponse(BaseModel):
    serial_no: str
    created: bool
    linked_item: Optional[str] = None
