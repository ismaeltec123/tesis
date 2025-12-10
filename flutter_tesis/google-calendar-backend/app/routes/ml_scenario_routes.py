"""
Endpoint para generar escenarios de prueba para Machine Learning
"""
from fastapi import APIRouter, HTTPException
from typing import Dict, Any
from datetime import datetime, timedelta
import random
from app.services.mock_firebase import get_firebase_service
from app.services.calendar_service import GoogleCalendarService

router = APIRouter(prefix="/ml", tags=["Machine Learning"])

# Plantilla de horario semanal típico de un profesor universitario
TEMPLATE_SCHEDULE = [
    # Lunes
    {'day': 0, 'hour': 8, 'minute': 0, 'duration': 120, 'title': 'Estructura de Datos - TEO', 'type': 'teoria'},
    {'day': 0, 'hour': 10, 'minute': 0, 'duration': 120, 'title': 'Algoritmos - LAB', 'type': 'laboratorio'},
    {'day': 0, 'hour': 14, 'minute': 0, 'duration': 120, 'title': 'Base de Datos - TEO', 'type': 'teoria'},
    
    # Martes
    {'day': 1, 'hour': 9, 'minute': 0, 'duration': 120, 'title': 'Programación Web - LAB', 'type': 'laboratorio'},
    {'day': 1, 'hour': 15, 'minute': 0, 'duration': 120, 'title': 'Ingeniería de Software - TEO', 'type': 'teoria'},
    {'day': 1, 'hour': 17, 'minute': 0, 'duration': 90, 'title': 'Tutoría Académica', 'type': 'tutoria'},
    
    # Miércoles
    {'day': 2, 'hour': 8, 'minute': 0, 'duration': 120, 'title': 'Estructura de Datos - LAB', 'type': 'laboratorio'},
    {'day': 2, 'hour': 10, 'minute': 0, 'duration': 120, 'title': 'Base de Datos - LAB', 'type': 'laboratorio'},
    {'day': 2, 'hour': 16, 'minute': 0, 'duration': 120, 'title': 'Redes de Computadoras - TEO', 'type': 'teoria'},
    
    # Jueves
    {'day': 3, 'hour': 9, 'minute': 0, 'duration': 120, 'title': 'Algoritmos - TEO', 'type': 'teoria'},
    {'day': 3, 'hour': 14, 'minute': 0, 'duration': 120, 'title': 'Programación Web - TEO', 'type': 'teoria'},
    {'day': 3, 'hour': 20, 'minute': 0, 'duration': 90, 'title': 'Reunión Departamental', 'type': 'reunion'},
    
    # Viernes
    {'day': 4, 'hour': 8, 'minute': 0, 'duration': 120, 'title': 'Ingeniería de Software - LAB', 'type': 'laboratorio'},
    {'day': 4, 'hour': 10, 'minute': 0, 'duration': 120, 'title': 'Redes de Computadoras - LAB', 'type': 'laboratorio'},
    {'day': 4, 'hour': 15, 'minute': 0, 'duration': 90, 'title': 'Evaluación Continua', 'type': 'evaluacion'},
]

@router.post("/generate-scenario")
async def generate_ml_scenario(request: Dict[str, Any]) -> Dict[str, Any]:
    """
    Genera un escenario completo ML vinculado a Google Calendar:
    1. HISTORIAL: 4 semanas PASADAS con estados variados
    2. FUTURO: 2 semanas ADELANTE con estado 'pendiente'
    3. Crea eventos en Google Calendar Y Firebase
    """
    try:
        user_email = request.get('email')
        if not user_email:
            raise HTTPException(
                status_code=400,
                detail="Se requiere el email del usuario"
            )
        
        history_weeks = request.get('history_weeks', 4)
        future_weeks = request.get('future_weeks', 2)
        
        firebase = get_firebase_service()
        google_calendar = GoogleCalendarService()
        
        # Verificar que el usuario tenga token de Google
        print(f"🔍 Verificando credenciales de Google Calendar...")
        if not google_calendar.has_valid_credentials():
            print(f"❌ No hay credenciales válidas de Google Calendar")
            raise HTTPException(
                status_code=401,
                detail="Debes autenticarte primero con Google Calendar en /api/auth/google"
            )
        
        print(f"✅ Credenciales válidas encontradas")
        print(f"🎯 Generando escenario ML para: {user_email}")
        
        # Limpiar eventos antiguos del usuario
        all_events = firebase.get_all_events()
        user_events = [e for e in all_events if e.get('email') == user_email or e.get('user_id') == user_email]
        
        print(f"🗑️  Limpiando {len(user_events)} eventos antiguos del usuario...")
        for event in user_events:
            # Eliminar de Firebase
            firebase.delete_event(event['id'])
            # Eliminar de Google Calendar si tiene google_event_id
            if event.get('google_event_id'):
                try:
                    google_calendar.delete_event(event['google_event_id'])
                    print(f"🗑️  Eliminado de Google: {event.get('title')}")
                except Exception as e:
                    print(f"⚠️  No se pudo eliminar de Google: {e}")
        
        generated_events = []
        by_status = {}
        google_created = 0
        google_errors = []
        
        status_distribution = [
            ('completado', 0.60),
            ('no_realizado', 0.20),
            ('postergado', 0.10),
            ('cancelado', 0.10)
        ]
        
        # ==========================================
        # PARTE 1: GENERAR HISTORIAL (PASADO)
        # ==========================================
        print(f"📚 Generando HISTORIAL: {history_weeks} semanas atrás...")
        
        for week in range(history_weeks):
            week_start = datetime.now() - timedelta(weeks=(history_weeks - week))
            week_start = week_start.replace(hour=0, minute=0, second=0, microsecond=0)
            days_to_monday = week_start.weekday()
            week_start = week_start - timedelta(days=days_to_monday)
            
            for template in TEMPLATE_SCHEDULE:
                event_date = week_start + timedelta(days=template['day'])
                event_date = event_date.replace(hour=template['hour'], minute=template['minute'])
                
                # Asignar estado con patrones realistas
                assigned_status = _assign_realistic_status(template, status_distribution)
                
                # Crear en Google Calendar
                google_event_data = {
                    'summary': f"{template['title']} [{assigned_status.upper()}]",
                    'start': {'dateTime': event_date.isoformat(), 'timeZone': 'America/Lima'},
                    'end': {'dateTime': (event_date + timedelta(minutes=template['duration'])).isoformat(), 'timeZone': 'America/Lima'},
                    'description': f"Evento histórico ML - Estado: {assigned_status}",
                    'colorId': _get_google_color_by_status(assigned_status)
                }
                
                try:
                    google_event_id = google_calendar.create_event(google_event_data)
                    google_created += 1
                    print(f"✅ Google: {template['title']} - {assigned_status}")
                except Exception as e:
                    error_msg = f"{template['title']}: {str(e)}"
                    google_errors.append(error_msg)
                    print(f"❌ ERROR Google Calendar: {error_msg}")
                    google_event_id = None
                
                # Crear en Firebase
                event_id = f"ml_hist_{user_email.split('@')[0]}_{week}_{template['day']}_{template['hour']}"
                
                new_event = {
                    'id': event_id,
                    'title': template['title'],
                    'date': event_date.isoformat(),
                    'duration_minutes': template['duration'],
                    'event_type': template['type'],
                    'status': assigned_status,
                    'email': user_email,
                    'user_id': user_email,
                    'google_event_id': google_event_id,
                    'created_at': datetime.now().isoformat(),
                    'category': 'history',
                    'color': _get_color_by_status(assigned_status)
                }
                
                firebase.create_event(new_event)
                generated_events.append(new_event)
                by_status[assigned_status] = by_status.get(assigned_status, 0) + 1
        
        # ==========================================
        # PARTE 2: GENERAR CALENDARIO FUTURO
        # ==========================================
        print(f"📅 Generando CALENDARIO FUTURO: {future_weeks} semanas adelante...")
        
        for week in range(future_weeks):
            week_start = datetime.now() + timedelta(weeks=week)
            week_start = week_start.replace(hour=0, minute=0, second=0, microsecond=0)
            days_to_monday = week_start.weekday()
            week_start = week_start - timedelta(days=days_to_monday)
            
            for template in TEMPLATE_SCHEDULE:
                event_date = week_start + timedelta(days=template['day'])
                event_date = event_date.replace(hour=template['hour'], minute=template['minute'])
                
                assigned_status = 'pendiente'
                
                # Crear en Google Calendar
                google_event_data = {
                    'summary': template['title'],
                    'start': {'dateTime': event_date.isoformat(), 'timeZone': 'America/Lima'},
                    'end': {'dateTime': (event_date + timedelta(minutes=template['duration'])).isoformat(), 'timeZone': 'America/Lima'},
                    'description': f"Evento futuro ML - Pendiente de realizar",
                    'colorId': '9'  # Azul para pendientes
                }
                
                try:
                    google_event_id = google_calendar.create_event(google_event_data)
                    google_created += 1
                    print(f"✅ Google: {template['title']} - pendiente")
                except Exception as e:
                    error_msg = f"{template['title']}: {str(e)}"
                    google_errors.append(error_msg)
                    print(f"❌ ERROR Google Calendar: {error_msg}")
                    google_event_id = None
                
                # Crear en Firebase
                event_id = f"ml_fut_{user_email.split('@')[0]}_{week}_{template['day']}_{template['hour']}"
                
                new_event = {
                    'id': event_id,
                    'title': template['title'],
                    'date': event_date.isoformat(),
                    'end_time': (event_date + timedelta(minutes=template['duration'])).isoformat(),
                    'duration_minutes': template['duration'],
                    'event_type': template['type'],
                    'status': assigned_status,
                    'email': user_email,
                    'user_id': user_email,
                    'google_event_id': google_event_id,
                    'created_at': datetime.now().isoformat(),
                    'category': 'future',
                    'color': _get_color_by_status(assigned_status)
                }
                
                firebase.create_event(new_event)
                generated_events.append(new_event)
                by_status[assigned_status] = by_status.get(assigned_status, 0) + 1
        
        # Estadísticas
        history_events = [e for e in generated_events if e['category'] == 'history']
        future_events = [e for e in generated_events if e['category'] == 'future']
        
        print(f"✅ Escenario completo creado")
        print(f"   📚 Historial: {len(history_events)} eventos")
        print(f"   📅 Futuro: {len(future_events)} eventos")
        print(f"   🔗 Google Calendar: {google_created}/{len(generated_events)} eventos sincronizados")
        
        if google_errors:
            print(f"⚠️  {len(google_errors)} errores en Google Calendar:")
            for error in google_errors[:5]:  # Mostrar solo los primeros 5
                print(f"   - {error}")
        
        result = {
            'success': True,
            'message': f'Escenario ML vinculado a Google Calendar: {google_created}/{len(generated_events)} eventos',
            'total_events': len(generated_events),
            'google_calendar_synced': google_created,
            'google_calendar_errors': len(google_errors),
            'history': {'weeks': history_weeks, 'events': len(history_events)},
            'future': {'weeks': future_weeks, 'events': len(future_events)},
            'by_status': by_status,
            'email': user_email
        }
        
        if google_errors and google_created == 0:
            result['warning'] = f"No se pudo crear ningún evento en Google Calendar. Primer error: {google_errors[0]}"
        
        return result
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

def _assign_realistic_status(template: dict, distribution: list) -> str:
    """Asigna estado con patrones realistas"""
    hour = template['hour']
    
    # Patrones realistas
    if hour < 8:
        return 'no_realizado' if random.random() < 0.75 else 'cancelado'
    elif hour >= 20:
        return 'no_realizado' if random.random() < 0.65 else 'postergado'
    elif 10 <= hour < 12:
        return 'completado' if random.random() < 0.90 else 'postergado'
    elif 14 <= hour < 16:
        return 'completado' if random.random() < 0.75 else 'no_realizado'
    elif template['day'] == 4 and hour >= 15:
        return random.choice(['postergado', 'cancelado']) if random.random() < 0.40 else 'completado'
    
    # Distribución normal
    rand = random.random()
    cumulative = 0
    for status, prob in distribution:
        cumulative += prob
        if rand <= cumulative:
            return status
    return 'completado'

def _get_color_by_status(status: str) -> str:
    """Color para Flutter"""
    return {
        'completado': '#4caf50',
        'no_realizado': '#f44336',
        'postergado': '#ff9800',
        'cancelado': '#9e9e9e',
        'pendiente': '#2196f3'
    }.get(status, '#2196f3')

def _get_google_color_by_status(status: str) -> str:
    """Color ID para Google Calendar"""
    return {
        'completado': '10',    # Verde
        'no_realizado': '11',  # Rojo
        'postergado': '5',     # Amarillo
        'cancelado': '8',      # Gris
        'pendiente': '9'       # Azul
    }.get(status, '9')

# Plantilla de horario semanal típico de un profesor universitario
TEMPLATE_SCHEDULE = [
    # Lunes
    {'day': 0, 'hour': 8, 'minute': 0, 'duration': 120, 'title': 'Estructura de Datos - TEO', 'type': 'teoria'},
    {'day': 0, 'hour': 10, 'minute': 0, 'duration': 120, 'title': 'Algoritmos - LAB', 'type': 'laboratorio'},
    {'day': 0, 'hour': 14, 'minute': 0, 'duration': 120, 'title': 'Base de Datos - TEO', 'type': 'teoria'},
    
    # Martes
    {'day': 1, 'hour': 9, 'minute': 0, 'duration': 120, 'title': 'Programación Web - LAB', 'type': 'laboratorio'},
    {'day': 1, 'hour': 15, 'minute': 0, 'duration': 120, 'title': 'Ingeniería de Software - TEO', 'type': 'teoria'},
    {'day': 1, 'hour': 17, 'minute': 0, 'duration': 90, 'title': 'Tutoría Académica', 'type': 'tutoria'},
    
    # Miércoles
    {'day': 2, 'hour': 8, 'minute': 0, 'duration': 120, 'title': 'Estructura de Datos - LAB', 'type': 'laboratorio'},
    {'day': 2, 'hour': 10, 'minute': 0, 'duration': 120, 'title': 'Base de Datos - LAB', 'type': 'laboratorio'},
    {'day': 2, 'hour': 16, 'minute': 0, 'duration': 120, 'title': 'Redes de Computadoras - TEO', 'type': 'teoria'},
    
    # Jueves
    {'day': 3, 'hour': 9, 'minute': 0, 'duration': 120, 'title': 'Algoritmos - TEO', 'type': 'teoria'},
    {'day': 3, 'hour': 14, 'minute': 0, 'duration': 120, 'title': 'Programación Web - TEO', 'type': 'teoria'},
    {'day': 3, 'hour': 20, 'minute': 0, 'duration': 90, 'title': 'Reunión Departamental', 'type': 'reunion'},
    
    # Viernes
    {'day': 4, 'hour': 8, 'minute': 0, 'duration': 120, 'title': 'Ingeniería de Software - LAB', 'type': 'laboratorio'},
    {'day': 4, 'hour': 10, 'minute': 0, 'duration': 120, 'title': 'Redes de Computadoras - LAB', 'type': 'laboratorio'},
    {'day': 4, 'hour': 15, 'minute': 0, 'duration': 90, 'title': 'Evaluación Continua', 'type': 'evaluacion'},
]

@router.post("/generate-scenario")
async def generate_ml_scenario(request: Dict[str, Any]) -> Dict[str, Any]:
    """
    Genera un escenario completo de prueba para ML DESDE CERO:
    1. Crea HISTORIAL: 4 semanas en el PASADO con estados variados
    2. Crea FUTURO: 2 semanas en el FUTURO con estado 'pendiente'
    3. Simula comportamiento real para entrenar el ML
    """
    try:
        user_id = request.get('user_id', 'test_user_ml')
        user_email = request.get('email', 'ismael.qa13@gmail.com')
        history_weeks = request.get('history_weeks', 4)  # Semanas de historial
        future_weeks = request.get('future_weeks', 2)     # Semanas futuras
        
        firebase = get_firebase_service()
        
        # Limpiar eventos antiguos del usuario
        all_events = firebase.get_all_events()
        user_events = [e for e in all_events if e.get('user_id') == user_id or e.get('email') == user_email]
        
        print(f"🗑️  Limpiando {len(user_events)} eventos antiguos...")
        for event in user_events:
            firebase.delete_event(event['id'])
        
        generated_events = []
        by_status = {}
        
        # ==========================================
        # PARTE 1: GENERAR HISTORIAL (PASADO)
        # ==========================================
        print(f"📚 Generando HISTORIAL: {history_weeks} semanas en el pasado...")
        
        status_distribution = [
            ('completado', 0.60),      # 60% completados
            ('no_realizado', 0.20),    # 20% no realizados  
            ('postergado', 0.10),      # 10% postergados
            ('cancelado', 0.10)        # 10% cancelados
        ]
        
        for week in range(history_weeks):
            # Calcular fecha base (semanas ATRÁS desde hoy)
            week_start = datetime.now() - timedelta(weeks=(history_weeks - week))
            week_start = week_start.replace(hour=0, minute=0, second=0, microsecond=0)
            
            # Ajustar al lunes de esa semana
            days_to_monday = week_start.weekday()
            week_start = week_start - timedelta(days=days_to_monday)
            
            for template in TEMPLATE_SCHEDULE:
                # Calcular fecha y hora específica
                event_date = week_start + timedelta(days=template['day'])
                event_date = event_date.replace(
                    hour=template['hour'],
                    minute=template['minute']
                )
                
                # Asignar estado basado en distribución
                rand = random.random()
                cumulative = 0
                assigned_status = 'completado'
                
                for status, prob in status_distribution:
                    cumulative += prob
                    if rand <= cumulative:
                        assigned_status = status
                        break
                
                # Simular patrones realistas de comportamiento:
                hour = template['hour']
                
                # - Eventos muy temprano (antes de 8am) → alta probabilidad no_realizado
                if hour < 8:
                    if random.random() < 0.75:
                        assigned_status = 'no_realizado'
                
                # - Eventos muy tarde (después de 8pm) → alta probabilidad no_realizado
                elif hour >= 20:
                    if random.random() < 0.65:
                        assigned_status = 'no_realizado'
                
                # - Eventos 10am-12pm → alta probabilidad completado (horario productivo)
                elif 10 <= hour < 12:
                    if random.random() < 0.90:
                        assigned_status = 'completado'
                
                # - Eventos 2pm-4pm → buena probabilidad completado
                elif 14 <= hour < 16:
                    if random.random() < 0.75:
                        assigned_status = 'completado'
                
                # - Viernes tarde → mayor probabilidad de postergado/cancelado
                if template['day'] == 4 and hour >= 15:
                    if random.random() < 0.40:
                        assigned_status = random.choice(['postergado', 'cancelado'])
                
                # Crear evento HISTÓRICO
                event_id = f"ml_history_{user_id}_{week}_{template['day']}_{template['hour']}_{random.randint(1000, 9999)}"
                
                new_event = {
                    'id': event_id,
                    'title': template['title'],
                    'date': event_date.isoformat(),
                    'duration_minutes': template['duration'],
                    'event_type': template['type'],
                    'status': assigned_status,
                    'user_id': user_id,
                    'email': user_email,
                    'created_at': datetime.now().isoformat(),
                    'week_number': week + 1,
                    'category': 'history',
                    'day_name': ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'][template['day']],
                    'color': _get_color_by_status(assigned_status)
                }
                
                firebase.create_event(new_event)
                generated_events.append(new_event)
                by_status[assigned_status] = by_status.get(assigned_status, 0) + 1
        
        # ==========================================
        # PARTE 2: GENERAR CALENDARIO FUTURO
        # ==========================================
        print(f"📅 Generando CALENDARIO FUTURO: {future_weeks} semanas adelante...")
        
        for week in range(future_weeks):
            # Calcular fecha base (semanas ADELANTE desde hoy)
            week_start = datetime.now() + timedelta(weeks=week)
            week_start = week_start.replace(hour=0, minute=0, second=0, microsecond=0)
            
            # Ajustar al lunes de esa semana
            days_to_monday = week_start.weekday()
            week_start = week_start - timedelta(days=days_to_monday)
            
            for template in TEMPLATE_SCHEDULE:
                # Calcular fecha y hora específica
                event_date = week_start + timedelta(days=template['day'])
                event_date = event_date.replace(
                    hour=template['hour'],
                    minute=template['minute']
                )
                
                # TODOS los eventos futuros son 'pendiente'
                assigned_status = 'pendiente'
                
                # Crear evento FUTURO
                event_id = f"ml_future_{user_id}_{week}_{template['day']}_{template['hour']}_{random.randint(1000, 9999)}"
                
                new_event = {
                    'id': event_id,
                    'title': template['title'],
                    'date': event_date.isoformat(),
                    'end_time': (event_date + timedelta(minutes=template['duration'])).isoformat(),
                    'duration_minutes': template['duration'],
                    'event_type': template['type'],
                    'status': assigned_status,
                    'user_id': user_id,
                    'email': user_email,
                    'created_at': datetime.now().isoformat(),
                    'week_number': week + 1,
                    'category': 'future',
                    'day_name': ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'][template['day']],
                    'color': _get_color_by_status(assigned_status)
                }
                
                firebase.create_event(new_event)
                generated_events.append(new_event)
                by_status[assigned_status] = by_status.get(assigned_status, 0) + 1
        
        # Calcular estadísticas
        history_events = [e for e in generated_events if e['category'] == 'history']
        future_events = [e for e in generated_events if e['category'] == 'future']
        
        total_events = len(generated_events)
        print(f"✅ Generados {total_events} eventos totales")
        print(f"   📚 Historial: {len(history_events)} eventos ({history_weeks} semanas)")
        print(f"   📅 Futuro: {len(future_events)} eventos ({future_weeks} semanas)")
        print(f"   📊 Por estado:")
        for status, count in by_status.items():
            percentage = (count / total_events) * 100
            print(f"      - {status}: {count} ({percentage:.1f}%)")
        
        return {
            'success': True,
            'message': f'Escenario ML completo generado: {total_events} eventos',
            'total_events': total_events,
            'history': {
                'weeks': history_weeks,
                'events': len(history_events)
            },
            'future': {
                'weeks': future_weeks,
                'events': len(future_events)
            },
            'events_per_week': len(TEMPLATE_SCHEDULE),
            'by_status': by_status,
            'user_id': user_id,
            'email': user_email
        }
        
    except Exception as e:
        print(f"❌ Error generando escenario: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Error al generar escenario: {str(e)}"
        )

def _get_color_by_status(status: str) -> str:
    """Retorna color según estado"""
    colors = {
        'completado': '#4caf50',
        'no_realizado': '#f44336',
        'postergado': '#ff9800',
        'cancelado': '#9e9e9e',
        'pendiente': '#2196f3'
    }
    return colors.get(status, '#2196f3')
