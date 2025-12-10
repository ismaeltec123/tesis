"""
Servicio de Machine Learning para análisis de patrones y hábitos del usuario
Analiza comportamiento histórico para sugerir reprogramaciones inteligentes
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from collections import defaultdict
import statistics

class HabitMLService:
    """
    Analiza patrones de comportamiento del usuario para:
    1. Predecir probabilidad de completar eventos
    2. Identificar mejores horarios por tipo de actividad
    3. Detectar patrones de postergación
    4. Sugerir reprogramaciones inteligentes
    """
    
    def __init__(self):
        self.min_data_points = 5  # Mínimo de eventos para análisis confiable
        
    def analyze_completion_patterns(self, events_history: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Analiza patrones de completación de eventos
        Returns: Estadísticas de completación por tipo, hora, día
        """
        if not events_history:
            return self._default_patterns()
        
        # Agrupar por tipo de evento
        by_type = defaultdict(lambda: {'completed': 0, 'postponed': 0, 'cancelled': 0, 'total': 0})
        by_hour = defaultdict(lambda: {'completed': 0, 'total': 0})
        by_day = defaultdict(lambda: {'completed': 0, 'total': 0})
        
        for event in events_history:
            event_type = event.get('type', 'otro')
            status = event.get('status', 'pendiente')
            
            try:
                event_date = datetime.fromisoformat(str(event.get('date', '')).replace('Z', '+00:00'))
                hour = event_date.hour
                day_of_week = event_date.weekday()  # 0=Lunes, 6=Domingo
            except:
                continue
            
            # Contabilizar por tipo
            by_type[event_type]['total'] += 1
            if status == 'finalizado':
                by_type[event_type]['completed'] += 1
            elif status == 'postergado':
                by_type[event_type]['postponed'] += 1
            elif status == 'cancelado':
                by_type[event_type]['cancelled'] += 1
            
            # Contabilizar por hora
            by_hour[hour]['total'] += 1
            if status == 'finalizado':
                by_hour[hour]['completed'] += 1
            
            # Contabilizar por día
            by_day[day_of_week]['total'] += 1
            if status == 'finalizado':
                by_day[day_of_week]['completed'] += 1
        
        # Calcular tasas de completación
        completion_by_type = {}
        for event_type, stats in by_type.items():
            if stats['total'] > 0:
                completion_by_type[event_type] = {
                    'completion_rate': stats['completed'] / stats['total'],
                    'postpone_rate': stats['postponed'] / stats['total'],
                    'cancel_rate': stats['cancelled'] / stats['total'],
                    'total_events': stats['total']
                }
        
        completion_by_hour = {}
        for hour, stats in by_hour.items():
            if stats['total'] > 0:
                completion_by_hour[hour] = stats['completed'] / stats['total']
        
        completion_by_day = {}
        for day, stats in by_day.items():
            if stats['total'] > 0:
                completion_by_day[day] = stats['completed'] / stats['total']
        
        return {
            'by_type': completion_by_type,
            'by_hour': completion_by_hour,
            'by_day': completion_by_day,
            'total_analyzed': len(events_history),
            'has_enough_data': len(events_history) >= self.min_data_points
        }
    
    def predict_completion_probability(
        self,
        event_type: str,
        proposed_hour: int,
        proposed_day: int,
        patterns: Dict[str, Any]
    ) -> float:
        """
        Predice probabilidad de completar un evento basado en patrones históricos
        Returns: Probabilidad entre 0.0 y 1.0
        """
        if not patterns.get('has_enough_data'):
            return 0.5  # Probabilidad neutral si no hay datos suficientes
        
        # Factores de predicción
        type_factor = 0.5
        hour_factor = 0.5
        day_factor = 0.5
        
        # Factor de tipo de evento
        type_stats = patterns['by_type'].get(event_type, {})
        if type_stats:
            type_factor = type_stats.get('completion_rate', 0.5)
        
        # Factor de hora
        hour_completion = patterns['by_hour'].get(proposed_hour, None)
        if hour_completion is not None:
            hour_factor = hour_completion
        
        # Factor de día
        day_completion = patterns['by_day'].get(proposed_day, None)
        if day_completion is not None:
            day_factor = day_completion
        
        # Promedio ponderado (tipo tiene más peso)
        probability = (type_factor * 0.5) + (hour_factor * 0.3) + (day_factor * 0.2)
        
        return round(probability, 2)
    
    def suggest_best_reschedule_time(
        self,
        event_type: str,
        current_date: datetime,
        patterns: Dict[str, Any],
        blocked_hours: List[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """
        Sugiere mejores momentos para reprogramar basado en patrones
        Returns: Lista de sugerencias ordenadas por probabilidad
        """
        suggestions = []
        
        if not patterns.get('has_enough_data'):
            # Si no hay datos, sugerir horarios genéricos productivos
            return self._default_suggestions(current_date, blocked_hours)
        
        # Obtener mejores horas según historial
        hour_rates = patterns.get('by_hour', {})
        day_rates = patterns.get('by_day', {})
        
        # Generar slots para los próximos 7 días
        for days_ahead in range(1, 8):
            suggested_date = current_date + timedelta(days=days_ahead)
            day_of_week = suggested_date.weekday()
            
            # Probar diferentes horas del día
            for hour in [7, 8, 9, 10, 11, 14, 15, 16, 17, 18, 19, 20]:
                test_datetime = suggested_date.replace(hour=hour, minute=0, second=0)
                
                # Verificar si está bloqueado
                if self._is_time_blocked(test_datetime, blocked_hours):
                    continue
                
                # Calcular probabilidad de completación
                probability = self.predict_completion_probability(
                    event_type, hour, day_of_week, patterns
                )
                
                suggestions.append({
                    'datetime': test_datetime.isoformat(),
                    'hour': hour,
                    'day_of_week': day_of_week,
                    'probability': probability,
                    'confidence': 'alta' if probability > 0.7 else 'media' if probability > 0.5 else 'baja',
                    'reason': self._generate_reason(event_type, hour, day_of_week, probability, patterns)
                })
        
        # Ordenar por probabilidad descendente
        suggestions.sort(key=lambda x: x['probability'], reverse=True)
        
        return suggestions[:5]  # Top 5 sugerencias
    
    def detect_procrastination_patterns(self, events_history: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Detecta patrones de procrastinación del usuario
        """
        if not events_history or len(events_history) < self.min_data_points:
            return {'detected': False, 'message': 'Datos insuficientes'}
        
        postponed_events = [e for e in events_history if e.get('status') == 'postergado']
        total_events = len(events_history)
        postpone_rate = len(postponed_events) / total_events if total_events > 0 else 0
        
        # Analizar tipos de eventos más postergados
        postponed_by_type = defaultdict(int)
        for event in postponed_events:
            event_type = event.get('type', 'otro')
            postponed_by_type[event_type] += 1
        
        # Analizar horarios problemáticos
        postponed_by_hour = defaultdict(int)
        for event in postponed_events:
            try:
                event_date = datetime.fromisoformat(str(event.get('date', '')).replace('Z', '+00:00'))
                postponed_by_hour[event_date.hour] += 1
            except:
                continue
        
        problematic_types = sorted(postponed_by_type.items(), key=lambda x: x[1], reverse=True)[:3]
        problematic_hours = sorted(postponed_by_hour.items(), key=lambda x: x[1], reverse=True)[:3]
        
        return {
            'detected': postpone_rate > 0.3,  # Más del 30% de postergación
            'postpone_rate': round(postpone_rate, 2),
            'total_postponed': len(postponed_events),
            'problematic_event_types': [{'type': t, 'count': c} for t, c in problematic_types],
            'problematic_hours': [{'hour': h, 'count': c} for h, c in problematic_hours],
            'severity': 'alta' if postpone_rate > 0.5 else 'media' if postpone_rate > 0.3 else 'baja',
            'recommendations': self._generate_procrastination_recommendations(postpone_rate, problematic_types)
        }
    
    def calculate_user_consistency_score(self, events_history: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Calcula score de consistencia del usuario (0-100)
        """
        if not events_history or len(events_history) < self.min_data_points:
            return {'score': 50, 'level': 'insuficiente', 'message': 'Necesitas más historial'}
        
        completed = len([e for e in events_history if e.get('status') == 'finalizado'])
        total = len(events_history)
        completion_rate = completed / total if total > 0 else 0
        
        # Calcular varianza de horarios (consistencia)
        event_hours = []
        for event in events_history:
            if event.get('status') == 'finalizado':
                try:
                    event_date = datetime.fromisoformat(str(event.get('date', '')).replace('Z', '+00:00'))
                    event_hours.append(event_date.hour)
                except:
                    continue
        
        hour_variance = statistics.variance(event_hours) if len(event_hours) > 1 else 10
        consistency_factor = max(0, 1 - (hour_variance / 20))  # Menor varianza = mayor consistencia
        
        # Score combinado
        score = int((completion_rate * 0.7 + consistency_factor * 0.3) * 100)
        
        level = 'excelente' if score >= 80 else 'bueno' if score >= 60 else 'regular' if score >= 40 else 'necesita mejorar'
        
        return {
            'score': score,
            'level': level,
            'completion_rate': round(completion_rate, 2),
            'consistency_factor': round(consistency_factor, 2),
            'total_events': total,
            'completed_events': completed,
            'recommendations': self._generate_consistency_recommendations(score, completion_rate)
        }
    
    def _default_patterns(self) -> Dict[str, Any]:
        """Patrones por defecto cuando no hay datos"""
        return {
            'by_type': {},
            'by_hour': {},
            'by_day': {},
            'total_analyzed': 0,
            'has_enough_data': False
        }
    
    def _default_suggestions(self, current_date: datetime, blocked_hours: List = None) -> List[Dict[str, Any]]:
        """Sugerencias genéricas cuando no hay patrones"""
        suggestions = []
        productive_hours = [9, 10, 11, 15, 16, 17]
        
        for days_ahead in [1, 2, 3]:
            for hour in productive_hours[:2]:
                suggested_date = current_date + timedelta(days=days_ahead)
                test_datetime = suggested_date.replace(hour=hour, minute=0)
                
                if not self._is_time_blocked(test_datetime, blocked_hours):
                    suggestions.append({
                        'datetime': test_datetime.isoformat(),
                        'hour': hour,
                        'day_of_week': test_datetime.weekday(),
                        'probability': 0.6,
                        'confidence': 'media',
                        'reason': 'Horario productivo general (sin datos históricos suficientes)'
                    })
        
        return suggestions[:5]
    
    def _is_time_blocked(self, test_time: datetime, blocked_hours: List = None) -> bool:
        """Verifica si un horario está bloqueado"""
        if not blocked_hours:
            return False
        
        for blocked in blocked_hours:
            try:
                blocked_start = datetime.fromisoformat(str(blocked.get('date', '')).replace('Z', '+00:00'))
                blocked_end = datetime.fromisoformat(str(blocked.get('end_time', '')).replace('Z', '+00:00'))
                
                if blocked_start <= test_time < blocked_end:
                    return True
            except:
                continue
        
        return False
    
    def _generate_reason(self, event_type: str, hour: int, day: int, probability: float, patterns: Dict) -> str:
        """Genera explicación de la sugerencia"""
        reasons = []
        
        type_rate = patterns['by_type'].get(event_type, {}).get('completion_rate', 0)
        if type_rate > 0.7:
            reasons.append(f"Alta tasa de éxito en eventos de tipo '{event_type}'")
        
        hour_rate = patterns['by_hour'].get(hour, 0)
        if hour_rate > 0.7:
            reasons.append(f"Horario {hour}:00h con buen historial de completación")
        
        days = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo']
        day_rate = patterns['by_day'].get(day, 0)
        if day_rate > 0.7:
            reasons.append(f"Los {days[day]} sueles ser más productivo")
        
        if not reasons:
            return "Horario sugerido basado en patrones generales"
        
        return " | ".join(reasons)
    
    def _generate_procrastination_recommendations(self, rate: float, problematic_types: List) -> List[str]:
        """Genera recomendaciones para reducir procrastinación"""
        recommendations = []
        
        if rate > 0.5:
            recommendations.append("Considera dividir tareas grandes en subtareas más pequeñas")
            recommendations.append("Usa la técnica Pomodoro (25 min de trabajo, 5 min de descanso)")
        
        if problematic_types:
            top_type = problematic_types[0][0]
            recommendations.append(f"Los eventos de tipo '{top_type}' suelen postergarse - intenta programarlos en tu mejor horario")
        
        recommendations.append("Programa eventos importantes en las mañanas cuando hay más energía")
        
        return recommendations
    
    def _generate_consistency_recommendations(self, score: int, completion_rate: float) -> List[str]:
        """Genera recomendaciones para mejorar consistencia"""
        recommendations = []
        
        if score < 60:
            recommendations.append("Establece rutinas diarias para crear hábitos consistentes")
            recommendations.append("Comienza con metas pequeñas y alcanzables")
        
        if completion_rate < 0.5:
            recommendations.append("Reduce la cantidad de eventos programados - mejor calidad que cantidad")
        
        recommendations.append("Revisa tu calendario al inicio de cada día")
        recommendations.append("Celebra tus logros para mantener la motivación")
        
        return recommendations
