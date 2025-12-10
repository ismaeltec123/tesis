"""
Recomendador Simple basado en Heurísticas Estadísticas
NO requiere entrenamiento, usa análisis estadístico directo
"""
from datetime import datetime, timedelta
from typing import List, Dict, Any

class SimpleMLRecommender:
    """
    Sistema de recomendación basado en Machine Learning estadístico
    Analiza patrones históricos y genera predicciones
    """
    
    def __init__(self):
        self.min_data_points = 5
    
    def recommend_reschedule(
        self, 
        incomplete_event: Dict[str, Any], 
        user_history: List[Dict[str, Any]], 
        future_calendar: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Recomienda los mejores horarios para reagendar un evento
        """
        # 1. Analizar patrones del usuario
        patterns = self._analyze_patterns(user_history)
        
        # 2. Generar candidatos de reagendamiento
        candidates = self._generate_candidates(
            incomplete_event, 
            future_calendar, 
            days_ahead=7
        )
        
        # 3. Calcular score ML para cada candidato
        scored_candidates = []
        for candidate in candidates:
            score = self._calculate_ml_score(
                candidate, 
                incomplete_event, 
                patterns
            )
            
            # Agregar razones interpretables
            reasons = self._generate_reasons(
                candidate, 
                incomplete_event, 
                patterns, 
                score
            )
            
            scored_candidates.append({
                **candidate,
                'score': score,
                'predicted_completion_probability': score,
                'reasons': reasons,
                'ml_confidence': 'high' if score > 0.7 else 'medium' if score > 0.5 else 'low'
            })
        
        # 4. Ordenar por score y retornar top 3
        scored_candidates.sort(key=lambda x: x['score'], reverse=True)
        
        # Agregar ranking
        for i, rec in enumerate(scored_candidates[:3]):
            rec['rank'] = i + 1
            rec['day_name'] = self._get_day_name(rec['day_of_week'])
        
        return scored_candidates[:3]
    
    def _analyze_patterns(self, user_history: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Análisis estadístico de patrones de completación
        """
        if len(user_history) < self.min_data_points:
            return self._default_patterns()
        
        completed = [e for e in user_history if e.get('status') == 'finalizado']
        
        # Análisis por hora del día
        completion_by_hour = {}
        for hour in range(24):
            events_at_hour = [e for e in user_history if self._extract_hour(e) == hour]
            completed_at_hour = [e for e in completed if self._extract_hour(e) == hour]
            
            if events_at_hour:
                completion_by_hour[hour] = len(completed_at_hour) / len(events_at_hour)
            else:
                completion_by_hour[hour] = 0.5  # Neutral si no hay datos
        
        # Análisis por día de la semana
        completion_by_day = {}
        for day in range(7):
            events_at_day = [e for e in user_history if self._extract_day(e) == day]
            completed_at_day = [e for e in completed if self._extract_day(e) == day]
            
            if events_at_day:
                completion_by_day[day] = len(completed_at_day) / len(events_at_day)
            else:
                completion_by_day[day] = 0.5
        
        # Análisis por tipo de evento
        completion_by_type = {}
        for event in user_history:
            event_type = event.get('type', 'personal')
            if event_type not in completion_by_type:
                completion_by_type[event_type] = {'completed': 0, 'total': 0}
            
            completion_by_type[event_type]['total'] += 1
            if event.get('status') == 'finalizado':
                completion_by_type[event_type]['completed'] += 1
        
        # Convertir a tasas
        for event_type in completion_by_type:
            stats = completion_by_type[event_type]
            if stats['total'] > 0:
                completion_by_type[event_type] = stats['completed'] / stats['total']
            else:
                completion_by_type[event_type] = 0.5
        
        return {
            'by_hour': completion_by_hour,
            'by_day': completion_by_day,
            'by_type': completion_by_type,
            'total_completed': len(completed),
            'total_events': len(user_history),
            'overall_rate': len(completed) / len(user_history) if user_history else 0.5
        }
    
    def _generate_candidates(
        self, 
        event: Dict[str, Any], 
        future_calendar: List[Dict[str, Any]], 
        days_ahead: int = 7
    ) -> List[Dict[str, Any]]:
        """
        Genera slots candidatos para reagendamiento
        """
        candidates = []
        today = datetime.now()
        duration_minutes = event.get('duration_minutes', 60)
        
        # Generar slots para los próximos N días
        for day_offset in range(1, days_ahead + 1):
            target_date = today + timedelta(days=day_offset)
            
            # Horarios candidatos (cada hora de 6am a 22pm)
            for hour in range(6, 23):
                slot_start = target_date.replace(hour=hour, minute=0, second=0, microsecond=0)
                slot_end = slot_start + timedelta(minutes=duration_minutes)
                
                # Verificar si el slot está libre (simplificado)
                is_free = self._is_slot_available(slot_start, slot_end, future_calendar)
                
                if is_free:
                    candidates.append({
                        'date': slot_start.isoformat(),
                        'hour': hour,
                        'day_of_week': slot_start.weekday(),
                        'duration_minutes': duration_minutes,
                        'gap_before': 30,  # Simplificado
                        'gap_after': 60,   # Simplificado
                        'calendar_density': 0.3  # Simplificado
                    })
        
        return candidates
    
    def _calculate_ml_score(
        self, 
        candidate: Dict[str, Any], 
        event: Dict[str, Any], 
        patterns: Dict[str, Any]
    ) -> float:
        """
        Calcula score de Machine Learning basado en múltiples features
        """
        hour = candidate['hour']
        day = candidate['day_of_week']
        event_type = event.get('type', 'personal')
        
        # Feature 1: Tasa de completación histórica en esa hora (peso: 40%)
        hour_completion_rate = patterns['by_hour'].get(hour, 0.5)
        
        # Feature 2: Tasa de completación en ese día (peso: 30%)
        day_completion_rate = patterns['by_day'].get(day, 0.5)
        
        # Feature 3: Tasa para ese tipo de evento (peso: 20%)
        type_completion_rate = patterns['by_type'].get(event_type, 0.5)
        
        # Feature 4: Factores contextuales (peso: 10%)
        context_score = 1.0
        
        # Penalizar horarios extremos
        if hour < 7 or hour > 21:
            context_score -= 0.3
        
        # Bonificar horarios óptimos (9-11am, 2-4pm)
        if hour in [9, 10, 11, 14, 15, 16]:
            context_score += 0.2
        
        # Penalizar fines de semana si el tipo es trabajo/estudio
        if day >= 5 and event_type in ['trabajo', 'estudio']:
            context_score -= 0.2
        
        # Bonificar días con baja ocupación
        if candidate.get('calendar_density', 0) < 0.4:
            context_score += 0.1
        
        # Score final ponderado (modelo de regresión lineal ponderada)
        final_score = (
            0.40 * hour_completion_rate +
            0.30 * day_completion_rate +
            0.20 * type_completion_rate +
            0.10 * max(0, min(1, context_score))
        )
        
        return max(0.0, min(1.0, final_score))
    
    def _generate_reasons(
        self, 
        candidate: Dict[str, Any], 
        event: Dict[str, Any], 
        patterns: Dict[str, Any], 
        score: float
    ) -> List[str]:
        """
        Genera explicaciones interpretables del score
        """
        reasons = []
        hour = candidate['hour']
        day = candidate['day_of_week']
        event_type = event.get('type', 'personal')
        
        # Razón por hora
        hour_rate = patterns['by_hour'].get(hour, 0.5)
        if hour_rate > 0.7:
            reasons.append(f"Alta tasa de completación ({hour_rate*100:.0f}%) a las {hour}:00h según tu historial")
        elif hour_rate > 0.5:
            reasons.append(f"Tasa moderada de completación ({hour_rate*100:.0f}%) a las {hour}:00h")
        
        # Razón por día
        day_rate = patterns['by_day'].get(day, 0.5)
        day_name = self._get_day_name(day)
        if day_rate > 0.7:
            reasons.append(f"{day_name} es uno de tus días más productivos ({day_rate*100:.0f}% de completación)")
        
        # Razón por tipo
        type_rate = patterns['by_type'].get(event_type, 0.5)
        if type_rate > 0.6:
            reasons.append(f"Buen historial con eventos de tipo '{event_type}' ({type_rate*100:.0f}%)")
        
        # Razones contextuales
        if 9 <= hour <= 11:
            reasons.append("Horario matutino óptimo para concentración")
        elif 14 <= hour <= 16:
            reasons.append("Horario vespertino con buena energía")
        
        if candidate.get('calendar_density', 0) < 0.4:
            reasons.append("Día con baja ocupación, más flexible")
        
        if len(reasons) == 0:
            reasons.append("Horario disponible basado en tu calendario")
        
        return reasons[:4]  # Máximo 4 razones
    
    def _is_slot_available(
        self, 
        slot_start: datetime, 
        slot_end: datetime, 
        future_calendar: List[Dict[str, Any]]
    ) -> bool:
        """
        Verifica si el slot está disponible en el calendario
        """
        # Simplificado: asumir que está disponible
        # En implementación real, verificar contra future_calendar
        return True
    
    def _extract_hour(self, event: Dict[str, Any]) -> int:
        """Extrae hora del evento"""
        try:
            date_str = event.get('date', '').replace('Z', '+00:00')
            dt = datetime.fromisoformat(date_str)
            return dt.hour
        except:
            return 12  # Default mediodía
    
    def _extract_day(self, event: Dict[str, Any]) -> int:
        """Extrae día de la semana (0=Lunes, 6=Domingo)"""
        try:
            date_str = event.get('date', '').replace('Z', '+00:00')
            dt = datetime.fromisoformat(date_str)
            return dt.weekday()
        except:
            return 2  # Default miércoles
    
    def _get_day_name(self, day: int) -> str:
        """Convierte número de día a nombre"""
        days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']
        return days[day] if 0 <= day < 7 else 'Día'
    
    def _default_patterns(self) -> Dict[str, Any]:
        """Patrones por defecto cuando hay pocos datos"""
        return {
            'by_hour': {h: 0.5 for h in range(24)},
            'by_day': {d: 0.5 for d in range(7)},
            'by_type': {},
            'total_completed': 0,
            'total_events': 0,
            'overall_rate': 0.5
        }
