from pydantic import BaseModel, Field


class MediaUploadResponse(BaseModel):
    client_uuid: str
    drive_file_id: str
    size_bytes: int


class TranscriptionManualRequest(BaseModel):
    text: str = Field(..., min_length=1)


class TranscriptionResponse(BaseModel):
    status: str
