"""
Sistema ML para análisis de patrones de cancelación y no realización de eventos.
Predice cuándo es más probable que un usuario falle en sus eventos y sugiere mejores horarios.
"""

import numpy as np
from datetime import datetime, timedelta
from collections import defaultdict
import json
import os
from typing import List, Dict, Any, Tuple

class EventPatternAnalyzer:
    """
    Analizador ML que aprende patrones de eventos no realizados/cancelados
    para predecir y sugerir mejores horarios.
    """
    
    def __init__(self):
        # Usar Firebase simulado (archivo JSON)
        self.firebase_file = os.path.join(os.path.dirname(__file__), 'temp_events.json')
        
        # Mapeo de días de la semana
        self.DAYS = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']
        
        # Franjas horarias (cada 2 horas)
        self.TIME_SLOTS = [
            '06:00-08:00', '08:00-10:00', '10:00-12:00', 
            '12:00-14:00', '14:00-16:00', '16:00-18:00', 
            '18:00-20:00', '20:00-22:00', '22:00-00:00'
        ]
    
    def _load_events_from_file(self, user_id: str = 'estudiante_demo') -> List[Dict[str, Any]]:
        """Carga eventos desde archivo JSON simulado"""
        try:
            if not os.path.exists(self.firebase_file):
                return []
            
            with open(self.firebase_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Extraer eventos del usuario
            if 'users' in data and user_id in data['users']:
                user_data = data['users'][user_id]
                if 'events' in user_data:
                    return list(user_data['events'].values())
            
            return []
        except Exception as e:
            print(f"Error cargando eventos: {e}")
            return []
    
    def _save_events_to_file(self, user_id: str, events: List[Dict[str, Any]]):
        """Guarda eventos actualizados en archivo JSON"""
        try:
            # Cargar datos actuales
            data = {}
            if os.path.exists(self.firebase_file):
                with open(self.firebase_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
            
            # Actualizar eventos
            if 'users' not in data:
                data['users'] = {}
            if user_id not in data['users']:
                data['users'][user_id] = {}
            if 'events' not in data['users'][user_id]:
                data['users'][user_id]['events'] = {}
            
            # Convertir lista a dict por ID
            for event in events:
                event_id = event.get('id', str(datetime.now().timestamp()))
                data['users'][user_id]['events'][event_id] = event
            
            # Guardar
            with open(self.firebase_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
        
        except Exception as e:
            print(f"Error guardando eventos: {e}")
    
    def get_time_slot(self, hour: int) -> str:
        """Obtiene la franja horaria de una hora específica"""
        for i in range(0, 18, 2):
            if hour >= i+6 and hour < i+8:
                return self.TIME_SLOTS[i//2]
        return self.TIME_SLOTS[-1]
    
    def extract_features(self, event: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extrae características relevantes de un evento para el análisis ML.
        """
        date = event['date']
        if isinstance(date, str):
            date = datetime.fromisoformat(date.replace('Z', '+00:00'))
        
        # Características extraídas
        features = {
            'day_of_week': date.weekday(),  # 0=Lunes, 6=Domingo
            'day_name': self.DAYS[date.weekday()],
            'hour': date.hour,
            'time_slot': self.get_time_slot(date.hour),
            'month': date.month,
            'is_weekend': date.weekday() >= 5,
            'event_type': event.get('type', 'personal'),
            'status': event.get('status', 'pendiente'),
            'duration_minutes': self._calculate_duration(event),
            'event_id': event.get('id', ''),
            'title': event.get('title', ''),
        }
        
        return features
    
    def _calculate_duration(self, event: Dict[str, Any]) -> int:
        """Calcula la duración del evento en minutos"""
        try:
            start = event['date']
            end = event.get('endTime', event.get('end_time'))
            
            if isinstance(start, str):
                start = datetime.fromisoformat(start.replace('Z', '+00:00'))
            if isinstance(end, str):
                end = datetime.fromisoformat(end.replace('Z', '+00:00'))
            
            duration = (end - start).total_seconds() / 60
            return int(duration)
        except:
            return 60  # Default 1 hora
    
    def analyze_failure_patterns(self, user_id: str = 'estudiante_demo') -> Dict[str, Any]:
        """
        Analiza todos los eventos del usuario y encuentra patrones de falla.
        
        Returns:
            Dict con estadísticas de falla por día, hora, tipo de evento, etc.
        """
        # Obtener todos los eventos del usuario desde archivo JSON
        events_list = self._load_events_from_file(user_id)
        
        if not events_list:
            return {
                'error': 'No hay eventos para analizar',
                'total_events': 0
            }
        
        # Inicializar contadores
        total_events = 0
        failed_events = 0
        
        # Estadísticas por dimensión
        stats_by_day = defaultdict(lambda: {'total': 0, 'failed': 0})
        stats_by_hour = defaultdict(lambda: {'total': 0, 'failed': 0})
        stats_by_time_slot = defaultdict(lambda: {'total': 0, 'failed': 0})
        stats_by_type = defaultdict(lambda: {'total': 0, 'failed': 0})
        stats_by_weekend = {'weekday': {'total': 0, 'failed': 0}, 'weekend': {'total': 0, 'failed': 0}}
        
        failed_events_list = []
        
        # Analizar cada evento
        for event in events_list:
            try:
                features = self.extract_features(event)
            except Exception as e:
                print(f"Error procesando evento {event.get('id')}: {e}")
                continue
            
            total_events += 1
            
            # Determinar si el evento falló
            status = features['status']
            is_failed = status in ['no_realizado', 'cancelado']
            
            if is_failed:
                failed_events += 1
                failed_events_list.append({
                    'id': features['event_id'],
                    'title': features['title'],
                    'day': features['day_name'],
                    'hour': features['hour'],
                    'time_slot': features['time_slot'],
                    'type': features['event_type'],
                    'status': status
                })
            
            # Actualizar estadísticas
            day_name = features['day_name']
            stats_by_day[day_name]['total'] += 1
            if is_failed:
                stats_by_day[day_name]['failed'] += 1
            
            hour = features['hour']
            stats_by_hour[hour]['total'] += 1
            if is_failed:
                stats_by_hour[hour]['failed'] += 1
            
            time_slot = features['time_slot']
            stats_by_time_slot[time_slot]['total'] += 1
            if is_failed:
                stats_by_time_slot[time_slot]['failed'] += 1
            
            event_type = features['event_type']
            stats_by_type[event_type]['total'] += 1
            if is_failed:
                stats_by_type[event_type]['failed'] += 1
            
            weekend_key = 'weekend' if features['is_weekend'] else 'weekday'
            stats_by_weekend[weekend_key]['total'] += 1
            if is_failed:
                stats_by_weekend[weekend_key]['failed'] += 1
        
        # Calcular tasas de falla
        failure_rate = (failed_events / total_events * 100) if total_events > 0 else 0
        
        # Calcular tasas por día
        day_failure_rates = {}
        for day, stats in stats_by_day.items():
            rate = (stats['failed'] / stats['total'] * 100) if stats['total'] > 0 else 0
            day_failure_rates[day] = {
                'total': stats['total'],
                'failed': stats['failed'],
                'rate': round(rate, 2)
            }
        
        # Calcular tasas por hora
        hour_failure_rates = {}
        for hour, stats in stats_by_hour.items():
            rate = (stats['failed'] / stats['total'] * 100) if stats['total'] > 0 else 0
            hour_failure_rates[f"{hour:02d}:00"] = {
                'total': stats['total'],
                'failed': stats['failed'],
                'rate': round(rate, 2)
            }
        
        # Calcular tasas por franja horaria
        time_slot_failure_rates = {}
        for slot, stats in stats_by_time_slot.items():
            rate = (stats['failed'] / stats['total'] * 100) if stats['total'] > 0 else 0
            time_slot_failure_rates[slot] = {
                'total': stats['total'],
                'failed': stats['failed'],
                'rate': round(rate, 2)
            }
        
        # Calcular tasas por tipo
        type_failure_rates = {}
        for event_type, stats in stats_by_type.items():
            rate = (stats['failed'] / stats['total'] * 100) if stats['total'] > 0 else 0
            type_failure_rates[event_type] = {
                'total': stats['total'],
                'failed': stats['failed'],
                'rate': round(rate, 2)
            }
        
        # Encontrar los peores días y horas
        worst_days = sorted(day_failure_rates.items(), key=lambda x: x[1]['rate'], reverse=True)[:3]
        worst_time_slots = sorted(time_slot_failure_rates.items(), key=lambda x: x[1]['rate'], reverse=True)[:3]
        
        # Encontrar los mejores días y horas (con menos fallas)
        best_days = sorted(day_failure_rates.items(), key=lambda x: x[1]['rate'])[:3]
        best_time_slots = sorted(time_slot_failure_rates.items(), key=lambda x: x[1]['rate'])[:3]
        
        return {
            'summary': {
                'total_events': total_events,
                'failed_events': failed_events,
                'failure_rate': round(failure_rate, 2),
                'analysis_date': datetime.now().isoformat()
            },
            'failure_by_day': day_failure_rates,
            'failure_by_hour': hour_failure_rates,
            'failure_by_time_slot': time_slot_failure_rates,
            'failure_by_type': type_failure_rates,
            'weekend_vs_weekday': {
                'weekday_rate': round((stats_by_weekend['weekday']['failed'] / stats_by_weekend['weekday']['total'] * 100) if stats_by_weekend['weekday']['total'] > 0 else 0, 2),
                'weekend_rate': round((stats_by_weekend['weekend']['failed'] / stats_by_weekend['weekend']['total'] * 100) if stats_by_weekend['weekend']['total'] > 0 else 0, 2)
            },
            'worst_patterns': {
                'days': [{'day': day, 'rate': data['rate'], 'failed': data['failed']} for day, data in worst_days],
                'time_slots': [{'slot': slot, 'rate': data['rate'], 'failed': data['failed']} for slot, data in worst_time_slots]
            },
            'best_patterns': {
                'days': [{'day': day, 'rate': data['rate'], 'failed': data['failed']} for day, data in best_days],
                'time_slots': [{'slot': slot, 'rate': data['rate'], 'failed': data['failed']} for slot, data in best_time_slots]
            },
            'failed_events': failed_events_list[:20]  # Máximo 20 para no saturar
        }
    
    def predict_failure_risk(self, event: Dict[str, Any], patterns: Dict[str, Any]) -> Dict[str, Any]:
        """
        Predice el riesgo de falla de un evento basado en patrones históricos.
        
        Returns:
            Dict con riesgo (0-100), razones y recomendaciones
        """
        features = self.extract_features(event)
        
        # Obtener tasas de falla para este evento
        day_rate = patterns['failure_by_day'].get(features['day_name'], {}).get('rate', 0)
        time_slot_rate = patterns['failure_by_time_slot'].get(features['time_slot'], {}).get('rate', 0)
        type_rate = patterns['failure_by_type'].get(features['event_type'], {}).get('rate', 0)
        
        # Calcular riesgo ponderado
        risk_score = (day_rate * 0.4 + time_slot_rate * 0.4 + type_rate * 0.2)
        
        # Clasificar riesgo
        if risk_score >= 60:
            risk_level = 'ALTO'
            color = 'red'
        elif risk_score >= 30:
            risk_level = 'MEDIO'
            color = 'orange'
        else:
            risk_level = 'BAJO'
            color = 'green'
        
        # Generar razones
        reasons = []
        if day_rate > 30:
            reasons.append(f"Los {features['day_name']}s tienen {day_rate}% de falla")
        if time_slot_rate > 30:
            reasons.append(f"La franja {features['time_slot']} tiene {time_slot_rate}% de falla")
        if type_rate > 30:
            reasons.append(f"Eventos de tipo '{features['event_type']}' tienen {type_rate}% de falla")
        
        # Generar recomendaciones
        recommendations = []
        best_days = patterns['best_patterns']['days']
        best_slots = patterns['best_patterns']['time_slots']
        
        if risk_score > 30 and best_days:
            recommendations.append(f"Mejor día: {best_days[0]['day']} ({best_days[0]['rate']}% falla)")
        if risk_score > 30 and best_slots:
            recommendations.append(f"Mejor horario: {best_slots[0]['slot']} ({best_slots[0]['rate']}% falla)")
        
        return {
            'event_id': features['event_id'],
            'event_title': features['title'],
            'risk_score': round(risk_score, 2),
            'risk_level': risk_level,
            'risk_color': color,
            'current_schedule': {
                'day': features['day_name'],
                'time_slot': features['time_slot'],
                'hour': f"{features['hour']:02d}:00"
            },
            'reasons': reasons,
            'recommendations': recommendations,
            'should_reschedule': risk_score > 50
        }
    
    def suggest_better_schedule(self, event: Dict[str, Any], patterns: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Sugiere mejores horarios para un evento basado en patrones históricos.
        
        Returns:
            Lista de sugerencias con día, hora y razón
        """
        features = self.extract_features(event)
        current_date = event['date']
        if isinstance(current_date, str):
            current_date = datetime.fromisoformat(current_date.replace('Z', '+00:00'))
        
        suggestions = []
        
        # Obtener mejores días y horarios
        best_days = patterns['best_patterns']['days']
        best_slots = patterns['best_patterns']['time_slots']
        
        # Generar sugerencias combinando mejores días y horarios
        for day_info in best_days[:2]:  # Top 2 días
            day_name = day_info['day']
            day_index = self.DAYS.index(day_name)
            
            for slot_info in best_slots[:2]:  # Top 2 horarios
                slot = slot_info['slot']
                start_hour = int(slot.split(':')[0])
                
                # Calcular la próxima fecha para ese día
                days_ahead = (day_index - current_date.weekday()) % 7
                if days_ahead == 0:
                    days_ahead = 7  # Próxima semana
                
                suggested_date = current_date + timedelta(days=days_ahead)
                suggested_date = suggested_date.replace(hour=start_hour, minute=0, second=0, microsecond=0)
                
                # Calcular fecha de fin
                duration = features['duration_minutes']
                suggested_end = suggested_date + timedelta(minutes=duration)
                
                suggestions.append({
                    'suggested_start': suggested_date.isoformat(),
                    'suggested_end': suggested_end.isoformat(),
                    'day': day_name,
                    'time_slot': slot,
                    'hour': f"{start_hour:02d}:00",
                    'failure_rate': round((day_info['rate'] + slot_info['rate']) / 2, 2),
                    'reason': f"Combina {day_name} ({day_info['rate']}% falla) con horario {slot} ({slot_info['rate']}% falla)",
                    'confidence': round(100 - ((day_info['rate'] + slot_info['rate']) / 2), 2)
                })
        
        # Ordenar por tasa de falla (menor es mejor)
        suggestions.sort(key=lambda x: x['failure_rate'])
        
        return suggestions[:5]  # Top 5 sugerencias
    
    def auto_fill_test_data(self, user_id: str = 'estudiante_demo', num_events: int = 5) -> Dict[str, Any]:
        """
        Rellena automáticamente eventos pendientes con estados de falla para testing.
        Marca eventos en horarios/días problemáticos como cancelados o no realizados.
        
        Returns:
            Dict con resumen de eventos modificados
        """
        # Primero analizar patrones actuales (si existen)
        patterns = self.analyze_failure_patterns(user_id)
        
        # Si no hay patrones previos, continuar de todas formas (es para generar datos iniciales)
        worst_days = []
        worst_slots = []
        
        if 'error' not in patterns:
            # Obtener peores días y horarios desde patrones existentes
            worst_days = [p['day'] for p in patterns['worst_patterns']['days']]
            worst_slots = [p['slot'] for p in patterns['worst_patterns']['time_slots']]
        
        # Obtener eventos desde archivo JSON
        # Tomar cualquier evento que no esté ya cancelado o no realizado
        all_events = self._load_events_from_file(user_id)
        available_events = [e for e in all_events 
                           if e.get('status') not in ['cancelado', 'no_realizado']]
        
        print(f"📊 Total eventos: {len(all_events)}, Disponibles para modificar: {len(available_events)}")
        
        modified_events = []
        count = 0
        
        for event in available_events:
            if count >= num_events:
                break
            
            try:
                features = self.extract_features(event)
                
                # Verificar si el evento está en horario/día problemático
                is_bad_day = features['day_name'] in worst_days if worst_days else False
                is_bad_slot = features['time_slot'] in worst_slots if worst_slots else False
                
                # Si no hay patrones previos, modificar cualquier evento
                # Si hay patrones, solo modificar los que coinciden con horarios malos
                should_modify = (is_bad_day or is_bad_slot) if (worst_days or worst_slots) else True
                
                if should_modify:
                    # Decidir estado (60% cancelado, 40% no realizado)
                    new_status = 'cancelado' if count % 5 < 3 else 'no_realizado'
                    
                    old_status = event.get('status', 'desconocido')
                    
                    # Actualizar estado del evento
                    event['status'] = new_status
                    event['updated_at'] = datetime.now().isoformat()
                    
                    print(f"✏️  Modificando: {event.get('title', 'Sin título')} - {old_status} → {new_status}")
                    modified_events.append({
                        'id': event.get('id', ''),
                        'title': event.get('title', 'Sin título'),
                        'day': features['day_name'],
                        'time_slot': features['time_slot'],
                        'old_status': old_status,
                        'new_status': new_status,
                        'reason': f"Evento en {features['day_name']} - {features['time_slot']}" + 
                                 (f" (horario problemático)" if (is_bad_day or is_bad_slot) else " (seleccionado para prueba)")
                    })
                    
                    count += 1
            
            except Exception as e:
                print(f"Error modificando evento {event.get('id')}: {e}")
                continue
        
        # Guardar eventos actualizados
        if modified_events:
            self._save_events_to_file(user_id, all_events)
        
        return {
            'success': True,
            'modified_count': count,
            'requested': num_events,
            'modified_events': modified_events,
            'message': f"Se marcaron {count} eventos como cancelados/no realizados para análisis ML"
        }


def analyze_user_patterns(user_id: str = 'estudiante_demo') -> Dict[str, Any]:
    """
    Función principal para analizar patrones de un usuario.
    """
    analyzer = EventPatternAnalyzer()
    return analyzer.analyze_failure_patterns(user_id)


def predict_event_risk(event: Dict[str, Any], user_id: str = 'estudiante_demo') -> Dict[str, Any]:
    """
    Predice el riesgo de falla de un evento específico.
    """
    analyzer = EventPatternAnalyzer()
    patterns = analyzer.analyze_failure_patterns(user_id)
    
    if 'error' in patterns:
        return patterns
    
    return analyzer.predict_failure_risk(event, patterns)


def get_reschedule_suggestions(event: Dict[str, Any], user_id: str = 'estudiante_demo') -> Dict[str, Any]:
    """
    Obtiene sugerencias de reprogramación para un evento.
    """
    analyzer = EventPatternAnalyzer()
    patterns = analyzer.analyze_failure_patterns(user_id)
    
    if 'error' in patterns:
        return patterns
    
    suggestions = analyzer.suggest_better_schedule(event, patterns)
    
    return {
        'event_id': event.get('id', ''),
        'event_title': event.get('title', ''),
        'current_schedule': {
            'date': event['date'] if isinstance(event['date'], str) else event['date'].isoformat(),
            'day': analyzer.DAYS[datetime.fromisoformat(event['date'].replace('Z', '+00:00') if isinstance(event['date'], str) else event['date'].isoformat()).weekday()],
        },
        'suggestions': suggestions,
        'patterns_summary': {
            'total_events': patterns['summary']['total_events'],
            'failure_rate': patterns['summary']['failure_rate']
        }
    }


def auto_fill_failure_data(user_id: str = 'estudiante_demo', num_events: int = 5) -> Dict[str, Any]:
    """
    Rellena automáticamente eventos de prueba con estados de falla.
    """
    analyzer = EventPatternAnalyzer()
    return analyzer.auto_fill_test_data(user_id, num_events)
