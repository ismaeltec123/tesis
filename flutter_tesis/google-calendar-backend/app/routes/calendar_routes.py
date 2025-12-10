from fastapi import APIRouter, HTTPException
from typing import List
from datetime import datetime
from app.models.event_models import EventCreate, EventResponse, EventUpdate
from app.services.calendar_service import GoogleCalendarService
from app.services.mock_firebase import get_firebase_service

router = APIRouter(prefix="/calendar", tags=["calendar"])

calendar_service = GoogleCalendarService()
firebase_service = get_firebase_service()

@router.post("/events", response_model=EventResponse)
async def create_event(event: EventCreate):
    """Crea un evento en Google Calendar y Firebase"""
    try:
        # Convertir el evento a diccionario con fechas como strings
        event_data = event.dict()
        
        # Convertir fechas datetime a strings ISO para serialización
        if 'date' in event_data and hasattr(event_data['date'], 'isoformat'):
            event_data['date'] = event_data['date'].isoformat()
        if 'end_time' in event_data and hasattr(event_data['end_time'], 'isoformat'):
            event_data['end_time'] = event_data['end_time'].isoformat()
            
        print(f"🆕 Creando evento desde Flutter: {event_data.get('title')} (tipo: {event_data.get('type')})")
        
        # Crear en Google Calendar
        google_event_id = calendar_service.create_event(event_data)
        
        # Agregar el ID de Google al evento
        event_data['google_event_id'] = google_event_id
        
        # Crear en Firebase
        firebase_id = firebase_service.create_event(event_data)
        
        # Preparar respuesta
        response_data = event_data.copy()
        response_data['id'] = firebase_id
        response_data['firebase_id'] = firebase_id
        
        print(f"✅ Evento creado exitosamente: {event_data.get('title')} (Firebase ID: {firebase_id})")
        
        return EventResponse(**response_data)
        
    except Exception as e:
        print(f"❌ Error al crear evento: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error al crear evento: {str(e)}")

@router.get("/events", response_model=List[EventResponse])
async def get_events():
    """Obtiene todos los eventos de Firebase"""
    try:
        events = firebase_service.get_all_events()
        print(f"🔍 Firebase simulado tiene {len(events)} eventos")
        
        response_events = []
        for i, event in enumerate(events):
            # Generar ID si no existe
            event_id = event.get('firebase_id', f'sim_{i}')
            event['id'] = event_id
            print(f"📅 Procesando evento: {event.get('title', 'Sin título')} (ID: {event_id})")
            response_events.append(EventResponse(**event))
        
        print(f"✅ Devolviendo {len(response_events)} eventos al cliente")
        return response_events
        
    except Exception as e:
        print(f"❌ Error en get_events: {e}")
        raise HTTPException(status_code=500, detail=f"Error al obtener eventos: {str(e)}")

@router.put("/events/{event_id}", response_model=EventResponse)
async def update_event(event_id: str, event_update: EventUpdate):
    """Actualiza un evento en Google Calendar y Firebase, preservando modificaciones locales"""
    try:
        # Obtener el evento actual de Firebase
        events = firebase_service.get_all_events()
        current_event = None
        
        for event in events:
            if event.get('firebase_id') == event_id:
                current_event = event
                break
        
        if not current_event:
            raise HTTPException(status_code=404, detail="Evento no encontrado")
        
        # Preparar datos actualizados
        update_data = event_update.dict(exclude_unset=True)
        
        # DEBUG: Ver qué datos vienen en la actualización
        print(f"🔍 DEBUG - Datos recibidos para actualizar: {update_data}")
        print(f"🔍 DEBUG - Status en update_data: {update_data.get('status', 'NO PRESENTE')}")
        
        # Marcar que este evento ha sido modificado localmente
        update_data['locally_modified'] = True
        update_data['last_modified'] = datetime.now().isoformat()
        
        print(f"🔄 Actualizando evento: {current_event.get('title')} -> {update_data.get('title', 'sin cambio de título')}")
        print(f"📝 Tipo actualizado: {current_event.get('type')} -> {update_data.get('type', 'sin cambio')}")
        print(f"📝 Status actualizado: {current_event.get('status', 'sin status')} -> {update_data.get('status', 'sin cambio')}")
        
        # Actualizar en Google Calendar si tiene ID de Google
        google_event_id = current_event.get('google_event_id')
        if google_event_id:
            try:
                # Combinar datos actuales con actualizaciones
                updated_data = {**current_event, **update_data}
                calendar_service.update_event(google_event_id, updated_data)
                print(f"✅ Evento actualizado en Google Calendar: {google_event_id}")
            except Exception as e:
                print(f"⚠️ Error actualizando en Google Calendar: {e}")
                # Continuar con la actualización en Firebase aunque falle Google
        
        # Actualizar en Firebase (siempre funciona)
        firebase_service.update_event(event_id, update_data)
        print(f"✅ Evento actualizado en Firebase: {event_id}")
        
        # Preparar respuesta
        response_data = {**current_event, **update_data}
        response_data['id'] = event_id
        
        return EventResponse(**response_data)
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error en update_event: {e}")
        raise HTTPException(status_code=500, detail=f"Error al actualizar evento: {str(e)}")

@router.delete("/events/{event_id}")
async def delete_event(event_id: str):
    """Elimina un evento de Google Calendar y Firebase"""
    try:
        # Obtener el evento actual de Firebase
        events = firebase_service.get_all_events()
        current_event = None
        
        for event in events:
            if event.get('firebase_id') == event_id:
                current_event = event
                break
        
        if not current_event:
            raise HTTPException(status_code=404, detail="Evento no encontrado")
        
        # Eliminar de Google Calendar si tiene ID de Google
        google_event_id = current_event.get('google_event_id')
        if google_event_id:
            calendar_service.delete_event(google_event_id)
        
        # Eliminar de Firebase
        firebase_service.delete_event(event_id)
        
        return {
            "success": True,
            "message": "Evento eliminado exitosamente"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al eliminar evento: {str(e)}")


@router.post("/events/batch")
async def create_events_batch(payload: dict):
    """Crea múltiples eventos en Google Calendar y Firebase"""
    try:
        events_data = payload.get('events', [])
        
        if not events_data:
            raise HTTPException(status_code=400, detail="No se proporcionaron eventos")
        
        print(f"📦 Creando {len(events_data)} eventos en batch...")
        
        created_events = []
        errors = []
        
        for idx, event_data in enumerate(events_data):
            try:
                # Marcar como obligatorio si viene de importación de horarios
                if 'type' not in event_data:
                    event_data['type'] = 'obligatorio'
                
                # Crear en Google Calendar
                google_event_id = calendar_service.create_event(event_data)
                
                # Convertir al formato interno para Firebase
                start_datetime = event_data.get('start', {}).get('dateTime')
                end_datetime = event_data.get('end', {}).get('dateTime')
                
                # Crear objeto para Firebase con formato correcto
                firebase_event = {
                    'title': event_data.get('summary', 'Clase'),
                    'description': event_data.get('description', ''),
                    'date': start_datetime,
                    'end_time': end_datetime,
                    'type': event_data['type'],
                    'google_event_id': google_event_id,
                    'location': event_data.get('location', ''),
                    'reminder': False
                }
                
                # Crear en Firebase
                firebase_id = firebase_service.create_event(firebase_event)
                
                created_events.append({
                    'index': idx,
                    'firebase_id': firebase_id,
                    'google_event_id': google_event_id,
                    'title': firebase_event.get('title')
                })
                
                print(f"✅ Evento {idx + 1}/{len(events_data)} creado: {event_data.get('title')}")
                
            except Exception as e:
                error_msg = f"Error en evento {idx + 1}: {str(e)}"
                print(f"❌ {error_msg}")
                errors.append({
                    'index': idx,
                    'error': error_msg,
                    'event': event_data.get('summary', 'Sin título')
                })
        
        print(f"✅ Batch completado: {len(created_events)} creados, {len(errors)} errores")
        
        return {
            "success": True,
            "created_count": len(created_events),
            "error_count": len(errors),
            "created_events": created_events,
            "errors": errors if errors else None
        }
        
    except Exception as e:
        print(f"❌ Error en batch creation: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error al crear eventos: {str(e)}")

