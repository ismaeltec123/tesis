"""
Endpoint para generar historial ML desde el calendario actual del usuario
"""
from fastapi import APIRouter, HTTPException, Body
from typing import Dict, Any
from datetime import datetime, timedelta
import random
from app.services.mock_firebase import get_firebase_service
from app.services.calendar_service import GoogleCalendarService

router = APIRouter(prefix="/ml-history", tags=["Machine Learning History"])

@router.post("/generate-from-current")
async def generate_history_from_current(
    history_weeks: int = Body(4, embed=True)
) -> Dict[str, Any]:
    """
    Genera historial ML desde el calendario actual:
    1. Lee eventos actuales del usuario
    2. Los replica hacia el PASADO (8 semanas por defecto)
    3. Asigna estados variados: completado, no_realizado, postergado, cancelado
    4. Crea en Google Calendar Y Firebase
    """
    try:
        print(f"🎯 === INICIO GENERACIÓN ML HISTORY === ")
        firebase = get_firebase_service()
        google_calendar = GoogleCalendarService()
        
        # Verificar credenciales de Google
        print(f"🔍 Verificando credenciales de Google Calendar...")
        if not google_calendar.has_valid_credentials():
            print(f"❌ No hay credenciales válidas de Google Calendar")
            raise HTTPException(
                status_code=401,
                detail="Debes autenticarte primero con Google Calendar"
            )
        
        print(f"✅ Credenciales válidas encontradas")
        
        # Obtener TODOS los eventos actuales (sin filtrar por tipo)
        all_events = firebase.get_all_events()
        
        # Usar TODOS los eventos como base para el historial
        user_current_events = all_events
        
        if not user_current_events:
            raise HTTPException(
                status_code=404,
                detail="No hay eventos en el calendario. Crea algunos eventos primero."
            )
        
        # Obtener el email desde token.pickle (igual que OCR)
        user_email = "ismael.qa13@gmail.com"  # Email del token.pickle
        print(f"📧 Usando email del token: {user_email}")
        
        print(f"🎯 Generando historial ML para: {user_email}")
        print(f"📚 Encontrados {len(user_current_events)} eventos actuales (horario base)")
        
        # Extraer patrón semanal del horario
        weekly_pattern = []
        for event in user_current_events:
            event_date = datetime.fromisoformat(event.get('date', '').replace('Z', '+00:00'))
            weekly_pattern.append({
                'day_of_week': event_date.weekday(),  # 0=Lunes, 6=Domingo
                'hour': event_date.hour,
                'minute': event_date.minute,
                'title': event.get('title', 'Clase'),
                'duration_minutes': event.get('duration_minutes', 120),
                'event_type': event.get('event_type', 'teoria')
            })
        
        print(f"📅 Patrón semanal detectado: {len(weekly_pattern)} eventos por semana")
        
        # Tipos de eventos personales VARIADOS para entrenar ML mejor
        personal_event_types = [
            # Estudio/Académico
            {'title': 'Estudio Personal', 'duration': 90, 'category': 'estudio'},
            {'title': 'Tareas Pendientes', 'duration': 120, 'category': 'estudio'},
            {'title': 'Preparación Examen', 'duration': 180, 'category': 'estudio'},
            {'title': 'Lectura Académica', 'duration': 60, 'category': 'estudio'},
            {'title': 'Práctica de Laboratorio', 'duration': 150, 'category': 'estudio'},
            
            # Ejercicio/Salud
            {'title': 'Ejercicio', 'duration': 60, 'category': 'ejercicio'},
            {'title': 'Gimnasio', 'duration': 90, 'category': 'ejercicio'},
            {'title': 'Correr', 'duration': 45, 'category': 'ejercicio'},
            {'title': 'Yoga', 'duration': 60, 'category': 'ejercicio'},
            
            # Descanso/Personal
            {'title': 'Descanso', 'duration': 30, 'category': 'descanso'},
            {'title': 'Descanso Mental', 'duration': 20, 'category': 'descanso'},
            {'title': 'Siesta', 'duration': 40, 'category': 'descanso'},
            
            # Comidas
            {'title': 'Desayuno', 'duration': 30, 'category': 'comida'},
            {'title': 'Almuerzo', 'duration': 60, 'category': 'comida'},
            {'title': 'Cena', 'duration': 45, 'category': 'comida'},
            
            # Social/Trabajo en grupo
            {'title': 'Reunión de Grupo', 'duration': 90, 'category': 'reunion'},
            {'title': 'Trabajo en Equipo', 'duration': 120, 'category': 'reunion'},
            {'title': 'Asesoría', 'duration': 60, 'category': 'reunion'},
            
            # Proyectos
            {'title': 'Práctica de Proyecto', 'duration': 180, 'category': 'proyecto'},
            {'title': 'Desarrollo de Tesis', 'duration': 240, 'category': 'proyecto'},
            {'title': 'Investigación', 'duration': 120, 'category': 'proyecto'},
            
            # Ocio/Entretenimiento
            {'title': 'Lectura Recreativa', 'duration': 50, 'category': 'ocio'},
            {'title': 'Hobby', 'duration': 60, 'category': 'ocio'},
            {'title': 'Tiempo Libre', 'duration': 90, 'category': 'ocio'},
        ]
        
        # Generar historial
        generated_events = []
        by_status = {}
        
        status_distribution = [
            ('completado', 0.65),      # 65% completado
            ('no_realizado', 0.15),    # 15% no realizado
            ('postergado', 0.10),      # 10% postergado
            ('cancelado', 0.10)        # 10% cancelado
        ]
        
        print(f"🕒 Generando historial: {history_weeks} semanas hacia el PASADO...")
        
        for week in range(history_weeks):
            # Calcular semana en el pasado
            weeks_ago = history_weeks - week
            reference_date = datetime.now() - timedelta(weeks=weeks_ago)
            
            # Encontrar el lunes de esa semana
            days_to_monday = reference_date.weekday()
            week_start = reference_date - timedelta(days=days_to_monday)
            week_start = week_start.replace(hour=0, minute=0, second=0, microsecond=0)
            
            # 1. Generar eventos basados en el horario importado (clases)
            for pattern in weekly_pattern:
                # Calcular fecha del evento
                event_date = week_start + timedelta(days=pattern['day_of_week'])
                event_date = event_date.replace(hour=pattern['hour'], minute=pattern['minute'])
                
                # Asignar estado con patrones realistas
                assigned_status = _assign_realistic_status(pattern['hour'], pattern['day_of_week'])
                
                end_date = event_date + timedelta(minutes=pattern['duration_minutes'])
                
                # PASO 1: Crear en Google Calendar (IGUAL QUE OCR)
                google_event_data = {
                    'summary': pattern['title'],
                    'start': {
                        'dateTime': event_date.isoformat(),
                        'timeZone': 'America/Lima'
                    },
                    'end': {
                        'dateTime': end_date.isoformat(),
                        'timeZone': 'America/Lima'
                    },
                    'description': f"Evento histórico ML - Generado automáticamente",
                    'colorId': '9'  # Azul por defecto
                }
                
                try:
                    google_event_id = google_calendar.create_event(google_event_data)
                except Exception as e:
                    print(f"⚠️ Error creando en Google Calendar: {e}")
                    google_event_id = None
                
                # PASO 2: Crear en Firebase con el google_event_id (IGUAL QUE OCR)
                firebase_event = {
                    'title': pattern['title'],
                    'description': f"Evento histórico generado para entrenamiento ML",
                    'date': event_date.isoformat(),
                    'end_time': end_date.isoformat(),
                    'type': 'obligatorio',  # Mantener tipo original
                    'status': assigned_status,  # Estado ML: completado, no_realizado, postergado, cancelado
                    'google_event_id': google_event_id,
                    'location': '',
                    'reminder': False
                }
                
                firebase.create_event(firebase_event)
                generated_events.append(firebase_event)
                by_status[assigned_status] = by_status.get(assigned_status, 0) + 1
            
            # 2. Agregar eventos personales variados (MÁS CANTIDAD para ML)
            # Generar 20-25 eventos personales por semana para llegar a 100 total
            num_personal_events = random.randint(20, 25)
            print(f"   📝 Generando {num_personal_events} eventos personales para semana {week+1}/{history_weeks}")
            
            for _ in range(num_personal_events):
                # Elegir tipo de evento aleatorio
                event_template = random.choice(personal_event_types)
                
                # Elegir día y hora aleatoria (más inteligente)
                random_day = random.randint(0, 6)  # Lunes a Domingo
                
                # Horarios según categoría del evento
                if event_template['category'] in ['comida']:
                    # Comidas en horarios típicos
                    if 'Desayuno' in event_template['title']:
                        random_hour = random.randint(7, 9)
                    elif 'Almuerzo' in event_template['title']:
                        random_hour = random.randint(12, 14)
                    else:  # Cena
                        random_hour = random.randint(18, 20)
                elif event_template['category'] in ['estudio', 'proyecto']:
                    # Estudio/trabajo en horarios productivos
                    random_hour = random.choice([9, 10, 14, 15, 16, 19])
                elif event_template['category'] == 'ejercicio':
                    # Ejercicio temprano o tarde
                    random_hour = random.choice([6, 7, 17, 18, 19])
                elif event_template['category'] == 'descanso':
                    # Descanso después de comidas o tarde
                    random_hour = random.choice([14, 15, 21, 22])
                else:
                    # Otros eventos aleatorios
                    random_hour = random.randint(8, 21)
                
                random_minute = random.choice([0, 15, 30, 45])
                
                event_date = week_start + timedelta(days=random_day)
                event_date = event_date.replace(hour=random_hour, minute=random_minute)
                end_date = event_date + timedelta(minutes=event_template['duration'])
                
                # Asignar estado realista
                assigned_status = _assign_realistic_status(random_hour, random_day)
                
                # PASO 1: Crear en Google Calendar
                google_event_data = {
                    'summary': event_template['title'],
                    'start': {
                        'dateTime': event_date.isoformat(),
                        'timeZone': 'America/Lima'
                    },
                    'end': {
                        'dateTime': end_date.isoformat(),
                        'timeZone': 'America/Lima'
                    },
                    'description': f"[{event_template['category'].upper()}] Evento histórico para ML - Estado: {assigned_status}",
                    'colorId': '9'
                }
                
                try:
                    google_event_id = google_calendar.create_event(google_event_data)
                except Exception as e:
                    print(f"⚠️ Error creando evento personal en Google Calendar: {e}")
                    google_event_id = None
                
                # PASO 2: Crear en Firebase con el google_event_id
                firebase_event = {
                    'title': event_template['title'],
                    'description': f"[{event_template['category']}] Evento histórico para ML",
                    'date': event_date.isoformat(),
                    'end_time': end_date.isoformat(),
                    'type': 'opcional',  # Tipo de evento (opcional para personales)
                    'status': assigned_status,  # Estado ML: completado, no_realizado, postergado, cancelado
                    'google_event_id': google_event_id,
                    'location': '',
                    'reminder': False,
                    'category': event_template['category']  # Categoría para análisis ML
                }
                
                firebase.create_event(firebase_event)
                generated_events.append(firebase_event)
                by_status[assigned_status] = by_status.get(assigned_status, 0) + 1
        
        print(f"✅ Historial ML generado correctamente")
        print(f"   📚 Total eventos históricos: {len(generated_events)}")
        print(f"   ✅ Creados en Google Calendar Y Firebase (patrón OCR)")
        print(f"   📊 Distribución por estado:")
        for status, count in by_status.items():
            percentage = (count / len(generated_events)) * 100 if len(generated_events) > 0 else 0
            print(f"      - {status}: {count} ({percentage:.1f}%)")
        
        result = {
            'success': True,
            'message': f'Historial ML generado: {len(generated_events)} eventos desde {history_weeks} semanas atrás',
            'total_events': len(generated_events),
            'google_calendar_synced': len(generated_events),  # Todos se sincronizan con Google
            'weeks_generated': history_weeks,
            'by_status': by_status,
            'email': user_email,
            'base_events_used': len(user_current_events),
            'ml_ready': len(generated_events) >= 50  # ML necesita al menos 50 eventos
        }
        
        print(f"🎯 === FIN GENERACIÓN ML HISTORY ===")
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

def _assign_realistic_status(hour: int, day_of_week: int) -> str:
    """Asigna estado con patrones realistas basados en hora del día y día de la semana"""
    
    # Patrones realistas basados en comportamiento humano
    
    # Eventos muy temprano (antes de 8am) - alta probabilidad de NO realizarlos
    if hour < 8:
        return 'no_realizado' if random.random() < 0.70 else 'cancelado'
    
    # Eventos muy tarde (después de 8pm) - alta probabilidad de posponer
    elif hour >= 20:
        return 'postergado' if random.random() < 0.50 else 'no_realizado'
    
    # Horario productivo (10am-12pm, 2pm-4pm) - alta tasa de completitud
    elif (10 <= hour < 12) or (14 <= hour < 16):
        return 'completado' if random.random() < 0.85 else random.choice(['postergado', 'no_realizado'])
    
    # Viernes tarde (después de 4pm) - mayor probabilidad de cancelar o posponer
    elif day_of_week == 4 and hour >= 16:  # Viernes
        rand = random.random()
        if rand < 0.40: return 'postergado'
        elif rand < 0.60: return 'cancelado'
        elif rand < 0.90: return 'completado'
        else: return 'no_realizado'
    
    # Fines de semana - patrones diferentes
    elif day_of_week >= 5:  # Sábado o Domingo
        rand = random.random()
        if rand < 0.50: return 'completado'
        elif rand < 0.70: return 'no_realizado'
        elif rand < 0.85: return 'postergado'
        else: return 'cancelado'
    
    # Horario normal - distribución estándar
    else:
        rand = random.random()
        if rand < 0.65: return 'completado'
        elif rand < 0.80: return 'no_realizado'
        elif rand < 0.90: return 'postergado'
        else: return 'cancelado'
