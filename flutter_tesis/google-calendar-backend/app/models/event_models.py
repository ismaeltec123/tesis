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
    status: Optional[str] = None  # Estado del evento
    completed_at: Optional[str] = None  # Cuándo se completó
    postponed_count: Optional[int] = None  # Veces postergado
    cancellation_reason: Optional[str] = None  # Razón de cancelación
    # Campos ML para "No lo realicé"
    reason: Optional[str] = None
    mood: Optional[str] = None
    energy_level: Optional[str] = None
    stress_level: Optional[str] = None
    weather_condition: Optional[str] = None
    location: Optional[str] = None
    conflicting_events: Optional[bool] = None
    sleep_quality: Optional[str] = None
    importance_rating: Optional[int] = None
    difficulty_rating: Optional[int] = None
    time_since_last_meal: Optional[int] = None
    additional_notes: Optional[str] = None

class EventResponse(EventBase):
    id: str
    google_event_id: Optional[str] = None
    firebase_id: Optional[str] = None
    status: Optional[str] = "pendiente"  # Estado del evento
    completed_at: Optional[str] = None
    postponed_count: Optional[int] = 0
    
    class Config:
        orm_mode = True

class SyncResponse(BaseModel):
    success: bool
    message: str
    events_synced: int
    errors: list = []
