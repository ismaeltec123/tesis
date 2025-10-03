"""
Servicio de organización con IA para generar eventos de estudio y recreativos
basado en horarios libres y recomendaciones de salud
"""
from datetime import datetime, timedelta
from typing import List, Dict, Any, Tuple
import random

class AIOrganizer:
    def __init__(self):
        # Recomendaciones basadas en estudios de salud y productividad
        self.health_recommendations = {
            'study': {
                'daily_hours': 1.5,  # 1-2 horas de estudio efectivo al día
                'session_duration': [45, 60, 90],  # Sesiones de 45min a 1.5h
                'break_between': 15,  # 15 min de descanso entre sesiones
                'preferred_times': [(9, 12), (14, 17), (19, 22)]  # Horarios óptimos
            },
            'exercise': {
                'daily_hours': 1,  # 1 hora de ejercicio al día (WHO recommendation)
                'session_duration': [30, 45, 60],  # 30min a 1h por sesión
                'preferred_times': [(6, 8), (17, 19)]  # Mañana o tarde
            }
        }
        
        # Sugerencias de actividades recreativas/deportivas
        self.exercise_activities = [
            {'name': 'Manejar bicicleta', 'duration': 45, 'question': '¿Te gusta manejar bicicleta?'},
            {'name': 'Salir a correr', 'duration': 30, 'question': '¿Te gusta correr?'},
            {'name': 'Caminar en el parque', 'duration': 30, 'question': '¿Te gusta caminar?'},
            {'name': 'Hacer yoga', 'duration': 45, 'question': '¿Te interesa hacer yoga?'},
            {'name': 'Ir al gimnasio', 'duration': 60, 'question': '¿Tienes acceso a un gimnasio?'},
            {'name': 'Nadar', 'duration': 45, 'question': '¿Te gusta nadar?'},
            {'name': 'Bailar', 'duration': 60, 'question': '¿Te gusta bailar?'},
            {'name': 'Entrenar en casa', 'duration': 30, 'question': '¿Prefieres entrenar en casa?'}
        ]
        
        # Sugerencias de actividades de estudio
        self.study_activities = [
            {'name': 'Estudiar materias principales', 'duration': 90},
            {'name': 'Revisar apuntes', 'duration': 45},
            {'name': 'Hacer ejercicios prácticos', 'duration': 60},
            {'name': 'Leer material complementario', 'duration': 60},
            {'name': 'Preparar presentaciones', 'duration': 90},
            {'name': 'Investigar proyecto de tesis', 'duration': 120},
            {'name': 'Estudiar para exámenes', 'duration': 90}
        ]
    
    def analyze_schedule(self, events: List[Dict[str, Any]], target_date: datetime) -> Dict[str, Any]:
        """
        Analiza el horario de un día específico para encontrar espacios libres
        """
        # Filtrar eventos del día objetivo
        day_events = []
        for event in events:
            try:
                # Manejar diferentes formatos de fecha
                date_str = event['date']
                end_str = event['end_time']
                
                # Normalizar formato de fecha
                if 'Z' in date_str:
                    date_str = date_str.replace('Z', '+00:00')
                if 'Z' in end_str:
                    end_str = end_str.replace('Z', '+00:00')
                
                event_date = datetime.fromisoformat(date_str)
                end_time = datetime.fromisoformat(end_str)
                
                # Normalizar timezone si es necesario
                if event_date.tzinfo is None:
                    from datetime import timezone as tz
                    event_date = event_date.replace(tzinfo=tz.utc)
                if end_time.tzinfo is None:
                    from datetime import timezone as tz
                    end_time = end_time.replace(tzinfo=tz.utc)
                
                if event_date.date() == target_date.date():
                    day_events.append({
                        'start': event_date,
                        'end': end_time,
                        'title': event['title']
                    })
            except (ValueError, KeyError) as e:
                print(f"⚠️  Error procesando evento {event.get('title', 'Sin título')}: {e}")
                continue
        
        # Ordenar eventos por hora de inicio
        day_events.sort(key=lambda x: x['start'])
        
        # Definir horario de trabajo (6 AM a 11 PM)
        # Normalizar timezone - usar el timezone del primer evento o UTC si no hay eventos
        if day_events:
            timezone = day_events[0]['start'].tzinfo
        else:
            from datetime import timezone as tz
            timezone = tz.utc
        
        # Asegurar que target_date tenga timezone
        if target_date.tzinfo is None:
            target_date = target_date.replace(tzinfo=timezone)
        
        day_start = target_date.replace(hour=6, minute=0, second=0, microsecond=0)
        day_end = target_date.replace(hour=23, minute=0, second=0, microsecond=0)
        
        # Encontrar espacios libres
        free_slots = []
        current_time = day_start
        
        for event in day_events:
            if current_time < event['start']:
                # Hay un espacio libre antes de este evento
                duration = (event['start'] - current_time).total_seconds() / 60  # minutos
                if duration >= 30:  # Solo considerar espacios de al menos 30 min
                    free_slots.append({
                        'start': current_time,
                        'end': event['start'],
                        'duration': int(duration)
                    })
            current_time = max(current_time, event['end'])
        
        # Verificar si hay espacio libre al final del día
        if current_time < day_end:
            duration = (day_end - current_time).total_seconds() / 60
            if duration >= 30:
                free_slots.append({
                    'start': current_time,
                    'end': day_end,
                    'duration': int(duration)
                })
        
        return {
            'target_date': target_date,
            'existing_events': day_events,
            'free_slots': free_slots,
            'total_free_time': sum(slot['duration'] for slot in free_slots)
        }
    
    def generate_suggestions(self, schedule_analysis: Dict[str, Any]) -> Dict[str, Any]:
        """
        Genera sugerencias de eventos basadas en el análisis del horario
        """
        free_slots = schedule_analysis['free_slots']
        total_free_time = schedule_analysis['total_free_time']
        
        if total_free_time < 60:  # Menos de 1 hora libre
            return {
                'success': False,
                'message': 'No hay suficiente tiempo libre para organizar actividades (mínimo 1 hora)',
                'suggestions': []
            }
        
        # Calcular tiempo disponible para cada tipo de actividad
        recommended_study_time = min(self.health_recommendations['study']['daily_hours'] * 60, 
                                   total_free_time * 0.6)  # 60% para estudio máximo
        recommended_exercise_time = min(self.health_recommendations['exercise']['daily_hours'] * 60, 
                                      total_free_time * 0.4)  # 40% para ejercicio máximo
        
        suggestions = []
        
        # Generar sugerencias de ejercicio
        exercise_suggestions = self._generate_exercise_suggestions(
            free_slots, recommended_exercise_time
        )
        suggestions.extend(exercise_suggestions)
        
        # Generar sugerencias de estudio
        study_suggestions = self._generate_study_suggestions(
            free_slots, recommended_study_time
        )
        suggestions.extend(study_suggestions)
        
        return {
            'success': True,
            'analysis': schedule_analysis,
            'total_free_time': total_free_time,
            'recommended_study_time': recommended_study_time,
            'recommended_exercise_time': recommended_exercise_time,
            'suggestions': suggestions
        }
    
    def _generate_exercise_suggestions(self, free_slots: List[Dict], target_minutes: float) -> List[Dict]:
        """
        Genera sugerencias específicas de ejercicio
        """
        suggestions = []
        remaining_time = target_minutes
        
        # Encontrar slots adecuados para ejercicio (preferentemente mañana o tarde)
        suitable_slots = []
        for slot in free_slots:
            hour = slot['start'].hour
            if ((6 <= hour <= 8) or (17 <= hour <= 19)) and slot['duration'] >= 30:
                suitable_slots.append(slot)
        
        # Si no hay slots en horarios preferidos, usar cualquier slot disponible
        if not suitable_slots:
            suitable_slots = [slot for slot in free_slots if slot['duration'] >= 30]
        
        # Seleccionar actividades de ejercicio
        used_activities = []
        for slot in suitable_slots:
            if remaining_time <= 0:
                break
                
            # Elegir actividad que no se haya usado y que quepa en el slot
            available_activities = [
                act for act in self.exercise_activities 
                if act not in used_activities and act['duration'] <= slot['duration']
            ]
            
            if available_activities:
                activity = random.choice(available_activities)
                used_activities.append(activity)
                
                # Calcular horarios
                start_time = slot['start']
                end_time = start_time + timedelta(minutes=activity['duration'])
                
                suggestions.append({
                    'type': 'recreativo',
                    'category': 'exercise',
                    'title': activity['name'],
                    'duration': activity['duration'],
                    'question': activity['question'],
                    'suggested_start': start_time,
                    'suggested_end': end_time,
                    'slot': slot,
                    'priority': 'high' if remaining_time >= activity['duration'] else 'medium'
                })
                
                remaining_time -= activity['duration']
        
        return suggestions
    
    def _generate_study_suggestions(self, free_slots: List[Dict], target_minutes: float) -> List[Dict]:
        """
        Genera sugerencias específicas de estudio
        """
        suggestions = []
        remaining_time = target_minutes
        
        # Encontrar slots adecuados para estudio (preferentemente horarios de alta concentración)
        suitable_slots = []
        for slot in free_slots:
            hour = slot['start'].hour
            if ((9 <= hour <= 12) or (14 <= hour <= 17) or (19 <= hour <= 22)) and slot['duration'] >= 45:
                suitable_slots.append(slot)
        
        # Si no hay slots en horarios preferidos, usar slots de al menos 45 min
        if not suitable_slots:
            suitable_slots = [slot for slot in free_slots if slot['duration'] >= 45]
        
        # Ordenar slots por horario preferido
        suitable_slots.sort(key=lambda x: x['start'].hour)
        
        # Seleccionar actividades de estudio
        used_activities = []
        for slot in suitable_slots:
            if remaining_time <= 0:
                break
            
            # Elegir duración óptima para el slot
            possible_durations = [d for d in self.health_recommendations['study']['session_duration'] 
                                if d <= slot['duration']]
            
            if possible_durations:
                duration = max(possible_durations)  # Usar la duración más larga posible
                
                # Elegir actividad de estudio
                available_activities = [
                    act for act in self.study_activities 
                    if act not in used_activities
                ]
                
                if available_activities:
                    activity = random.choice(available_activities)
                    used_activities.append(activity)
                    
                    # Usar la duración sugerida de la actividad o la óptima del slot
                    final_duration = min(activity['duration'], duration)
                    
                    # Calcular horarios
                    start_time = slot['start']
                    end_time = start_time + timedelta(minutes=final_duration)
                    
                    suggestions.append({
                        'type': 'estudio',
                        'category': 'study',
                        'title': activity['name'],
                        'duration': final_duration,
                        'suggested_start': start_time,
                        'suggested_end': end_time,
                        'slot': slot,
                        'priority': 'high' if remaining_time >= final_duration else 'medium'
                    })
                    
                    remaining_time -= final_duration
        
        return suggestions
    
    def create_ai_events(self, confirmed_suggestions: List[Dict]) -> List[Dict[str, Any]]:
        """
        Convierte las sugerencias confirmadas en eventos para crear
        """
        events_to_create = []
        
        for suggestion in confirmed_suggestions:
            try:
                # Manejar fechas que pueden ser strings o datetime objects
                start_time = suggestion['suggested_start']
                end_time = suggestion['suggested_end']
                
                if isinstance(start_time, str):
                    start_time = datetime.fromisoformat(start_time.replace('Z', '+00:00'))
                if isinstance(end_time, str):
                    end_time = datetime.fromisoformat(end_time.replace('Z', '+00:00'))
                
                event_data = {
                    'title': suggestion['title'],
                    'description': f"Evento generado por IA - {suggestion['category']}",
                    'date': start_time.isoformat(),
                    'end_time': end_time.isoformat(),
                    'type': suggestion['type'],
                    'reminder': True,  # Activar recordatorios para eventos de IA
                    'ai_generated': True  # Marcar como generado por IA
                }
                events_to_create.append(event_data)
            except (ValueError, KeyError) as e:
                print(f"⚠️  Error creando evento de IA {suggestion.get('title', 'Sin título')}: {e}")
                continue
        
        return events_to_create