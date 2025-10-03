from datetime import datetime, timezone
from typing import List, Dict, Any
from googleapiclient.errors import HttpError
from app.auth.google_oauth import GoogleAuthService
from app.models.event_models import EventResponse

class GoogleCalendarService:
    def __init__(self):
        self.auth_service = GoogleAuthService()
        
    def get_service(self):
        """Obtiene el servicio de Google Calendar"""
        return self.auth_service.get_calendar_service()
    
    def list_events(self, max_results: int = 250) -> List[Dict[str, Any]]:
        """Obtiene todos los eventos del calendario principal"""
        try:
            service = self.get_service()
            
            # Obtener eventos desde hace 30 días hasta 1 año en el futuro
            now = datetime.now(timezone.utc)
            time_min = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)  # Primer día del mes actual
            
            events_result = service.events().list(
                calendarId='primary',
                timeMin=time_min.isoformat(),
                maxResults=max_results,
                singleEvents=True,
                orderBy='startTime'
            ).execute()
            
            events = events_result.get('items', [])
            return events
            
        except HttpError as error:
            print(f'Error al obtener eventos de Google Calendar: {error}')
            return []
    
    def create_event(self, event_data: Dict[str, Any]) -> str:
        """Crea un evento en Google Calendar"""
        try:
            service = self.get_service()
            
            # Convertir el formato del evento para Google Calendar
            google_event = self._convert_to_google_format(event_data)
            
            event = service.events().insert(
                calendarId='primary',
                body=google_event
            ).execute()
            
            return event.get('id')
            
        except HttpError as error:
            print(f'Error al crear evento en Google Calendar: {error}')
            raise Exception(f'No se pudo crear el evento: {error}')
    
    def update_event(self, google_event_id: str, event_data: Dict[str, Any]) -> bool:
        """Actualiza un evento en Google Calendar"""
        try:
            service = self.get_service()
            
            # Obtener el evento actual
            event = service.events().get(
                calendarId='primary',
                eventId=google_event_id
            ).execute()
            
            # Actualizar con los nuevos datos
            updated_event = self._convert_to_google_format(event_data)
            
            service.events().update(
                calendarId='primary',
                eventId=google_event_id,
                body=updated_event
            ).execute()
            
            return True
            
        except HttpError as error:
            print(f'Error al actualizar evento en Google Calendar: {error}')
            return False
    
    def delete_event(self, google_event_id: str) -> bool:
        """Elimina un evento de Google Calendar"""
        try:
            service = self.get_service()
            
            service.events().delete(
                calendarId='primary',
                eventId=google_event_id
            ).execute()
            
            return True
            
        except HttpError as error:
            print(f'Error al eliminar evento de Google Calendar: {error}')
            return False
    
    def _convert_to_google_format(self, event_data: Dict[str, Any]) -> Dict[str, Any]:
        """Convierte el formato de evento interno al formato de Google Calendar"""
        
        # Extraer fechas
        start_time = event_data.get('date')
        end_time = event_data.get('end_time')
        
        if isinstance(start_time, str):
            start_time = datetime.fromisoformat(start_time.replace('Z', '+00:00'))
        if isinstance(end_time, str):
            end_time = datetime.fromisoformat(end_time.replace('Z', '+00:00'))
        
        google_event = {
            'summary': event_data.get('title', ''),
            'description': event_data.get('description', ''),
            'start': {
                'dateTime': start_time.isoformat(),
                'timeZone': 'America/Mexico_City',
            },
            'end': {
                'dateTime': end_time.isoformat(),
                'timeZone': 'America/Mexico_City',
            },
        }
        
        # Agregar recordatorio si está habilitado
        if event_data.get('reminder', False):
            google_event['reminders'] = {
                'useDefault': False,
                'overrides': [
                    {'method': 'popup', 'minutes': 30},
                    {'method': 'email', 'minutes': 60},
                ],
            }
        
        return google_event
    
    def _convert_from_google_format(self, google_event: Dict[str, Any]) -> Dict[str, Any]:
        """Convierte el formato de Google Calendar al formato interno"""
        
        # Extraer fechas de inicio y fin
        start = google_event.get('start', {})
        end = google_event.get('end', {})
        
        start_time = start.get('dateTime') or start.get('date')
        end_time = end.get('dateTime') or end.get('date')
        
        if start_time:
            start_time = datetime.fromisoformat(start_time.replace('Z', '+00:00'))
        if end_time:
            end_time = datetime.fromisoformat(end_time.replace('Z', '+00:00'))
        
        return {
            'title': google_event.get('summary', 'Sin título'),
            'description': google_event.get('description', ''),
            'date': start_time.isoformat() if start_time else None,
            'end_time': end_time.isoformat() if end_time else None,
            'type': 'importado',  # Marcar como importado de Google
            'reminder': bool(google_event.get('reminders', {}).get('overrides')),
            'google_event_id': google_event.get('id')
        }
