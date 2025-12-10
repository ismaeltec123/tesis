"""
Data Validator - Valida requests y verifica suficiencia de datos
"""
from datetime import datetime
from typing import Tuple, Dict

class DataValidator:
    """
    Valida requests y determina si hay suficientes datos para ML
    """
    
    def __init__(self):
        self.MIN_EVENTS = 20
        self.MIN_WEEKS = 2
    
    def validate_training_request(self, data: dict) -> Tuple[bool, str]:
        """
        Valida request de /train
        
        Returns:
            (is_valid: bool, error_message: str)
        """
        # Verificar user_id
        if 'user_id' not in data or not data['user_id']:
            return False, "Campo 'user_id' requerido"
        
        # Verificar events_history
        if 'events_history' not in data:
            return False, "Campo 'events_history' requerido"
        
        if not isinstance(data['events_history'], list):
            return False, "Campo 'events_history' debe ser una lista"
        
        if len(data['events_history']) == 0:
            return False, "events_history no puede estar vacío"
        
        # Validar estructura de eventos
        for i, event in enumerate(data['events_history']):
            is_valid, error = self._validate_event_structure(event)
            if not is_valid:
                return False, f"Evento {i}: {error}"
        
        return True, ""
    
    def validate_prediction_request(self, data: dict) -> Tuple[bool, str]:
        """
        Valida request de /predict
        
        Returns:
            (is_valid: bool, error_message: str)
        """
        # Verificar user_id
        if 'user_id' not in data or not data['user_id']:
            return False, "Campo 'user_id' requerido"
        
        # Verificar incomplete_event
        if 'incomplete_event' not in data:
            return False, "Campo 'incomplete_event' requerido"
        
        incomplete = data['incomplete_event']
        
        # Validar campos del evento incompleto
        required_fields = ['id', 'title', 'type', 'duration_minutes']
        for field in required_fields:
            if field not in incomplete:
                return False, f"Campo '{field}' requerido en incomplete_event"
        
        # Validar duration_minutes
        if not isinstance(incomplete['duration_minutes'], (int, float)):
            return False, "duration_minutes debe ser un número"
        
        if incomplete['duration_minutes'] <= 0:
            return False, "duration_minutes debe ser mayor que 0"
        
        # Validar event type
        valid_types = ['estudio', 'trabajo', 'ejercicio', 'personal']
        if incomplete['type'] not in valid_types:
            return False, f"type debe ser uno de: {', '.join(valid_types)}"
        
        return True, ""
    
    def check_sufficient_data(self, events_history: list) -> Tuple[bool, Dict]:
        """
        Verifica si hay suficientes datos para entrenar Prophet
        
        Returns:
            (has_enough: bool, validation_result: dict)
        """
        events_count = len(events_history)
        
        # Verificar cantidad mínima de eventos
        if events_count < self.MIN_EVENTS:
            days_until_ready = self._estimate_days_until_ready(events_count, 0)
            
            return False, {
                'events_count': events_count,
                'minimum_required_events': self.MIN_EVENTS,
                'weeks_of_data': 0,
                'minimum_required_weeks': self.MIN_WEEKS,
                'days_until_ready': days_until_ready,
                'message': f"Necesitas {self.MIN_EVENTS - events_count} eventos más (tienes {events_count})"
            }
        
        # Calcular rango temporal
        weeks_of_data = self._calculate_weeks_of_data(events_history)
        
        # Verificar mínimo de semanas
        if weeks_of_data < self.MIN_WEEKS:
            days_until_ready = int((self.MIN_WEEKS - weeks_of_data) * 7)
            
            return False, {
                'events_count': events_count,
                'minimum_required_events': self.MIN_EVENTS,
                'weeks_of_data': round(weeks_of_data, 2),
                'minimum_required_weeks': self.MIN_WEEKS,
                'days_until_ready': days_until_ready,
                'message': f"Necesitas {days_until_ready} días más de datos (tienes {round(weeks_of_data, 1)} semanas)"
            }
        
        # Datos suficientes
        return True, {
            'events_count': events_count,
            'minimum_required_events': self.MIN_EVENTS,
            'weeks_of_data': round(weeks_of_data, 2),
            'minimum_required_weeks': self.MIN_WEEKS,
            'days_until_ready': 0,
            'message': f"Datos suficientes: {events_count} eventos en {round(weeks_of_data, 1)} semanas"
        }
    
    def _validate_event_structure(self, event: dict) -> Tuple[bool, str]:
        """Valida que un evento tenga los campos necesarios"""
        required_fields = ['id', 'date', 'status']
        
        for field in required_fields:
            if field not in event:
                return False, f"Campo '{field}' requerido"
        
        # Validar formato de fecha
        try:
            date_str = event['date'].replace('Z', '+00:00')
            datetime.fromisoformat(date_str)
        except:
            return False, f"Formato de fecha inválido: {event['date']}"
        
        # Validar status
        valid_statuses = ['finalizado', 'pendiente', 'cancelado']
        if event['status'].lower() not in valid_statuses:
            return False, f"status debe ser uno de: {', '.join(valid_statuses)}"
        
        return True, ""
    
    def _calculate_weeks_of_data(self, events_history: list) -> float:
        """
        Calcula cuántas semanas de datos hay en el historial
        """
        if len(events_history) < 2:
            return 0.0
        
        try:
            dates = []
            for event in events_history:
                date_str = event['date'].replace('Z', '+00:00')
                dates.append(datetime.fromisoformat(date_str))
            
            if not dates:
                return 0.0
            
            first_date = min(dates)
            last_date = max(dates)
            days_span = (last_date - first_date).days
            
            return days_span / 7.0
            
        except Exception as e:
            print(f"   ⚠️  Error calculating weeks: {e}")
            return 0.0
    
    def _estimate_days_until_ready(self, current_events: int, current_weeks: float) -> int:
        """
        Estima cuántos días faltan para tener datos suficientes
        """
        # Estimar eventos por semana
        if current_weeks > 0:
            events_per_week = current_events / current_weeks
        else:
            events_per_week = 3  # Asumimos 3 eventos por semana
        
        # Calcular eventos faltantes
        events_needed = max(0, self.MIN_EVENTS - current_events)
        
        # Calcular semanas faltantes
        weeks_needed = max(0, self.MIN_WEEKS - current_weeks)
        
        # Estimar días necesarios (el mayor de los dos requisitos)
        days_for_events = int((events_needed / events_per_week) * 7) if events_per_week > 0 else 14
        days_for_weeks = int(weeks_needed * 7)
        
        return max(days_for_events, days_for_weeks)
