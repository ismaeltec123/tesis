from datetime import datetime
from typing import Optional
from pydantic import BaseModel

class EventBase(BaseModel):
    title: str
    description: str
    date: datetime
    end_time: datetime
    type: str = "obligatorio"
    reminder: bool = False

class EventCreate(EventBase):
    pass

class EventUpdate(EventBase):
    title: Optional[str] = None
    description: Optional[str] = None
    date: Optional[datetime] = None
    end_time: Optional[datetime] = None
    type: Optional[str] = None
    reminder: Optional[bool] = None

class EventResponse(EventBase):
    id: str
    google_event_id: Optional[str] = None
    firebase_id: Optional[str] = None
    
    class Config:
        orm_mode = True

class SyncResponse(BaseModel):
    success: bool
    message: str
    events_synced: int
    errors: list = []
