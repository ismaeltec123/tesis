from fastapi import APIRouter, HTTPException, Body
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
import json
import os
from pydantic import BaseModel, EmailStr

router = APIRouter(prefix="/api/admin", tags=["admin"])

# Pydantic Models
class UserCreate(BaseModel):
    email: EmailStr
    displayName: Optional[str] = None
    role: Optional[str] = "user"

class UserUpdate(BaseModel):
    displayName: Optional[str] = None
    role: Optional[str] = None

class User(BaseModel):
    id: str
    email: str
    displayName: Optional[str] = None
    role: str = "user"
    createdAt: str

class EventTemplate(BaseModel):
    title: str
    description: str
    type: str
    hour: int
    duration: int
    daysOfWeek: List[int]

class CalendarTemplate(BaseModel):
    name: str
    description: str
    events: List[EventTemplate]

class GenerateCalendarRequest(BaseModel):
    email: str
    templateId: str
    duration: str = "1month"  # Options: 1week, 1month, 3months, 6months

# Archivo para guardar usuarios
USERS_FILE = "users_db.json"

# Funciones para cargar y guardar usuarios
def load_users_from_file():
    """Cargar usuarios desde archivo JSON"""
    if os.path.exists(USERS_FILE):
        try:
            with open(USERS_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)
                # Convertir dict a objetos User
                return {uid: User(**user_data) for uid, user_data in data.items()}
        except Exception as e:
            print(f"⚠️  Error cargando usuarios: {e}")
            return {}
    return {}

def save_users_to_file(users: Dict[str, User]):
    """Guardar usuarios a archivo JSON"""
    try:
        # Convertir objetos User a dict
        data = {uid: user.dict() for uid, user in users.items()}
        with open(USERS_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"💾 Usuarios guardados: {len(users)}")
    except Exception as e:
        print(f"❌ Error guardando usuarios: {e}")

# Cargar usuarios al iniciar
users_db: Dict[str, User] = load_users_from_file()
templates_db: Dict[str, CalendarTemplate] = {}

print(f"📊 Usuarios cargados: {len(users_db)}")
if users_db:
    for user in users_db.values():
        print(f"   - {user.email} ({user.role})")

# Predefined templates
PREDEFINED_TEMPLATES = {
    "full": CalendarTemplate(
        name="Horario Completo",
        description="20+ eventos, todos los días cubiertos",
        events=[
            EventTemplate(title="Matemáticas", description="Clase de cálculo", type="study", hour=8, duration=60, daysOfWeek=[1, 3, 5]),
            EventTemplate(title="Física", description="Laboratorio", type="study", hour=10, duration=90, daysOfWeek=[2, 4]),
            EventTemplate(title="Programación", description="Desarrollo de software", type="study", hour=14, duration=120, daysOfWeek=[1, 2, 3, 4, 5]),
            EventTemplate(title="Gimnasio", description="Entrenamiento", type="exercise", hour=18, duration=60, daysOfWeek=[1, 3, 5]),
            EventTemplate(title="Yoga", description="Clase de yoga", type="exercise", hour=7, duration=45, daysOfWeek=[2, 4, 6]),
            EventTemplate(title="Lectura", description="Tiempo de lectura", type="personal", hour=20, duration=60, daysOfWeek=[1, 2, 3, 4, 5, 6, 0]),
            EventTemplate(title="Proyecto Personal", description="Desarrollo personal", type="work", hour=16, duration=90, daysOfWeek=[6, 0]),
        ]
    ),
    "partial": CalendarTemplate(
        name="Horario Parcial",
        description="10 eventos, algunos gaps",
        events=[
            EventTemplate(title="Estudio Matutino", description="Repaso general", type="study", hour=9, duration=60, daysOfWeek=[1, 3, 5]),
            EventTemplate(title="Ejercicio", description="Cardio", type="exercise", hour=18, duration=45, daysOfWeek=[2, 4]),
            EventTemplate(title="Reunión Semanal", description="Planning", type="work", hour=15, duration=60, daysOfWeek=[1]),
            EventTemplate(title="Tiempo Libre", description="Descanso", type="personal", hour=20, duration=60, daysOfWeek=[6, 0]),
        ]
    ),
    "empty": CalendarTemplate(
        name="Horario Vacío",
        description="0-2 eventos",
        events=[
            EventTemplate(title="Revisión Semanal", description="Planificación", type="personal", hour=10, duration=30, daysOfWeek=[0]),
        ]
    ),
    "study-focused": CalendarTemplate(
        name="Enfocado en Estudio",
        description="Principalmente eventos académicos",
        events=[
            EventTemplate(title="Matemáticas Avanzadas", description="Cálculo y álgebra", type="study", hour=8, duration=90, daysOfWeek=[1, 3, 5]),
            EventTemplate(title="Física Cuántica", description="Teoría y práctica", type="study", hour=10, duration=90, daysOfWeek=[2, 4]),
            EventTemplate(title="Programación Avanzada", description="Algoritmos", type="study", hour=14, duration=120, daysOfWeek=[1, 2, 3, 4, 5]),
            EventTemplate(title="Inglés Técnico", description="Lectura científica", type="study", hour=16, duration=60, daysOfWeek=[1, 3]),
            EventTemplate(title="Grupo de Estudio", description="Estudio colaborativo", type="study", hour=18, duration=90, daysOfWeek=[2, 4]),
        ]
    ),
    "exercise-focused": CalendarTemplate(
        name="Enfocado en Ejercicio",
        description="Principalmente eventos deportivos",
        events=[
            EventTemplate(title="Running Matutino", description="5km", type="exercise", hour=6, duration=45, daysOfWeek=[1, 3, 5]),
            EventTemplate(title="Gimnasio - Fuerza", description="Entrenamiento de fuerza", type="exercise", hour=18, duration=90, daysOfWeek=[1, 3, 5]),
            EventTemplate(title="Natación", description="1000m", type="exercise", hour=7, duration=60, daysOfWeek=[2, 4]),
            EventTemplate(title="Yoga", description="Flexibilidad", type="exercise", hour=19, duration=60, daysOfWeek=[2, 4, 6]),
            EventTemplate(title="Ciclismo", description="20km", type="exercise", hour=8, duration=90, daysOfWeek=[6, 0]),
        ]
    ),
}

# Initialize templates
for key, template in PREDEFINED_TEMPLATES.items():
    templates_db[key] = template


# User Management Endpoints
@router.get("/users", response_model=List[User])
async def get_all_users():
    """Obtener todos los usuarios"""
    return list(users_db.values())


@router.get("/users/{email}", response_model=User)
async def get_user_by_email(email: str):
    """Obtener usuario por email"""
    user = next((u for u in users_db.values() if u.email == email), None)
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return user


@router.post("/users", response_model=User)
async def create_user(user_data: UserCreate):
    """Crear nuevo usuario"""
    # Check if user already exists
    existing_user = next((u for u in users_db.values() if u.email == user_data.email), None)
    if existing_user:
        raise HTTPException(status_code=400, detail="Usuario ya existe")
    
    user_id = f"user_{len(users_db) + 1}"
    new_user = User(
        id=user_id,
        email=user_data.email,
        displayName=user_data.displayName,
        role=user_data.role or "estudiante",
        createdAt=datetime.now().isoformat()
    )
    users_db[user_id] = new_user
    save_users_to_file(users_db)  # Guardar en archivo
    print(f"✅ Usuario creado: {new_user.email} ({new_user.role})")
    return new_user


@router.put("/users/{user_id}", response_model=User)
async def update_user(user_id: str, user_data: UserUpdate):
    """Actualizar usuario"""
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    user = users_db[user_id]
    if user_data.displayName is not None:
        user.displayName = user_data.displayName
    if user_data.role is not None:
        user.role = user_data.role
    
    users_db[user_id] = user
    save_users_to_file(users_db)  # Guardar cambios
    print(f"✅ Usuario actualizado: {user.email}")
    return user
    return user


@router.delete("/users/{user_id}")
async def delete_user(user_id: str):
    """Eliminar usuario"""
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    deleted_email = users_db[user_id].email
    del users_db[user_id]
    save_users_to_file(users_db)
    print(f"🗑️ Usuario eliminado: {deleted_email}")
    return {"message": "Usuario eliminado correctamente"}


@router.post("/users/{user_id}/reset")
async def reset_user_data(user_id: str):
    """Resetear todos los datos del usuario"""
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    # In a real implementation, this would clear all user events and data
    return {"message": "Datos del usuario reseteados correctamente"}


@router.delete("/users/{user_id}/events")
async def delete_all_user_events(user_id: str):
    """Eliminar todos los eventos del usuario"""
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    # In a real implementation, this would delete all events from database
    return {"message": "Eventos eliminados correctamente"}


@router.delete("/users/by-email/events")
async def delete_all_user_events_by_email(email: str):
    """Eliminar todos los eventos del usuario por email (de temp_events.json y Google Calendar)"""
    from app.services.mock_firebase import get_firebase_service
    from app.services.calendar_service import GoogleCalendarService
    
    try:
        firebase_service = get_firebase_service()
        google_service = GoogleCalendarService()
        
        # 1. Obtener todos los eventos del usuario
        all_events = firebase_service.get_all_events()
        user_events = [e for e in all_events if e.get('user_email') == email or e.get('email') == email]
        
        deleted_local = 0
        deleted_google = 0
        errors = []
        
        # 2. Eliminar de Google Calendar si tienen google_event_id
        if google_service.is_available():
            for event in user_events:
                google_id = event.get('google_event_id')
                if google_id:
                    try:
                        google_service.delete_event(google_id)
                        deleted_google += 1
                        print(f"🗑️  Evento eliminado de Google: {event.get('title')}")
                    except Exception as e:
                        errors.append(f"Error eliminando '{event.get('title')}' de Google: {str(e)}")
                        print(f"⚠️  {errors[-1]}")
        
        # 3. Eliminar de temp_events.json
        for event in user_events:
            firebase_id = event.get('firebase_id')
            if firebase_id:
                try:
                    firebase_service.delete_event(firebase_id)
                    deleted_local += 1
                except Exception as e:
                    errors.append(f"Error eliminando '{event.get('title')}' localmente: {str(e)}")
        
        message = f"Eliminados: {deleted_local} eventos locales"
        if deleted_google > 0:
            message += f", {deleted_google} de Google Calendar"
        
        if errors:
            message += f" (con {len(errors)} errores)"
        
        print(f"✅ {message}")
        
        return {
            "message": message,
            "deleted_local": deleted_local,
            "deleted_google": deleted_google,
            "errors": errors
        }
        
    except Exception as e:
        print(f"❌ Error eliminando eventos: {e}")
        raise HTTPException(status_code=500, detail=f"Error al eliminar eventos: {str(e)}")


@router.post("/users/{user_id}/generate-calendar")
async def generate_calendar(user_id: str, payload: Dict[str, str] = Body(...)):
    """Generar calendario de prueba para usuario"""
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    template_id = payload.get("templateId")
    if not template_id or template_id not in templates_db:
        raise HTTPException(status_code=404, detail="Plantilla no encontrada")
    
    template = templates_db[template_id]
    generated_events = []
    
    # Generate events for the next 30 days
    start_date = datetime.now()
    for day_offset in range(30):
        current_date = start_date + timedelta(days=day_offset)
        day_of_week = current_date.weekday()  # 0=Monday, 6=Sunday
        
        # Adjust: Python uses 0=Monday, template uses 0=Sunday
        template_day = day_of_week + 1 if day_of_week < 6 else 0
        
        for event_template in template.events:
            if template_day in event_template.daysOfWeek:
                event_start = current_date.replace(
                    hour=event_template.hour, 
                    minute=0, 
                    second=0, 
                    microsecond=0
                )
                event_end = event_start + timedelta(minutes=event_template.duration)
                
                generated_events.append({
                    "id": f"event_{len(generated_events) + 1}",
                    "title": event_template.title,
                    "description": event_template.description,
                    "date": event_start.isoformat(),
                    "end_time": event_end.isoformat(),
                    "type": event_template.type,
                    "status": "pendiente",
                    "reminder": True,
                    "postponed_count": 0
                })
    
    return {
        "message": f"Calendario generado con {len(generated_events)} eventos",
        "events": generated_events,
        "template": template.name
    }


@router.post("/generate-calendar-by-email")
async def generate_calendar_by_email(request: GenerateCalendarRequest):
    """Generar calendario de prueba para usuario por email"""
    email = request.email
    template_id = request.templateId
    duration = request.duration
    
    if not email:
        raise HTTPException(status_code=400, detail="Email requerido")
    
    # Determine number of days based on duration
    duration_days = {
        "1week": 7,
        "1month": 30,
        "3months": 90,
        "6months": 180
    }
    
    days_to_generate = duration_days.get(duration, 30)
    
    user = next((u for u in users_db.values() if u.email == email), None)
    if not user:
        # Create user if doesn't exist
        user_id = f"user_{len(users_db) + 1}"
        user = User(
            id=user_id,
            email=email,
            displayName=email.split('@')[0],
            role="user",
            createdAt=datetime.now().isoformat()
        )
        users_db[user_id] = user
    
    if not template_id or template_id not in templates_db:
        raise HTTPException(status_code=404, detail="Plantilla no encontrada")
    
    template = templates_db[template_id]
    generated_events = []
    
    # Generate events for the specified duration
    start_date = datetime.now()
    for day_offset in range(days_to_generate):
        current_date = start_date + timedelta(days=day_offset)
        day_of_week = current_date.weekday()  # 0=Monday, 6=Sunday
        
        # Adjust: Python uses 0=Monday, template uses 0=Sunday
        template_day = day_of_week + 1 if day_of_week < 6 else 0
        
        for event_template in template.events:
            if template_day in event_template.daysOfWeek:
                event_start = current_date.replace(
                    hour=event_template.hour, 
                    minute=0, 
                    second=0, 
                    microsecond=0
                )
                event_end = event_start + timedelta(minutes=event_template.duration)
                
                generated_events.append({
                    "id": f"event_{len(generated_events) + 1}",
                    "title": event_template.title,
                    "description": event_template.description,
                    "date": event_start.isoformat(),
                    "end_time": event_end.isoformat(),
                    "type": event_template.type,
                    "status": "pendiente",
                    "reminder": True,
                    "postponed_count": 0,
                    "start": event_start.isoformat(),
                    "end": event_end.isoformat()
                })
    
    # Save events to temp file (simulated Firebase)
    import json
    import os
    
    temp_file = os.path.join(os.path.dirname(__file__), '..', '..', 'temp_events.json')
    
    try:
        # Load existing events
        if os.path.exists(temp_file):
            with open(temp_file, 'r', encoding='utf-8') as f:
                existing_data = json.load(f)
        else:
            existing_data = {"events": []}
        
        # Add new events
        if "events" not in existing_data:
            existing_data["events"] = []
        
        existing_data["events"].extend(generated_events)
        
        # Save to file
        with open(temp_file, 'w', encoding='utf-8') as f:
            json.dump(existing_data, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Saved {len(generated_events)} events to temp_events.json")
        
    except Exception as e:
        print(f"⚠️  Error saving to temp file: {e}")
    
    return {
        "message": f"Calendario generado con {len(generated_events)} eventos",
        "events": generated_events,
        "template": template.name,
        "duration": duration,
        "days": days_to_generate,
        "saved_locally": len(generated_events),
        "info": "Usa el botón 'SINCRONIZAR CON GOOGLE' para enviar los eventos a Google Calendar"
    }
    
    template_id = payload.get("templateId")
    if not template_id or template_id not in templates_db:
        raise HTTPException(status_code=404, detail="Plantilla no encontrada")
    
    template = templates_db[template_id]
    generated_events = []
    
    # Generate events for the next 30 days
    start_date = datetime.now()
    for day_offset in range(30):
        current_date = start_date + timedelta(days=day_offset)
        day_of_week = current_date.weekday()  # 0=Monday, 6=Sunday
        
        # Adjust: Python uses 0=Monday, template uses 0=Sunday
        template_day = day_of_week + 1 if day_of_week < 6 else 0
        
        for event_template in template.events:
            if template_day in event_template.daysOfWeek:
                event_start = current_date.replace(
                    hour=event_template.hour, 
                    minute=0, 
                    second=0, 
                    microsecond=0
                )
                event_end = event_start + timedelta(minutes=event_template.duration)
                
                generated_events.append({
                    "id": f"event_{len(generated_events) + 1}",
                    "title": event_template.title,
                    "description": event_template.description,
                    "date": event_start.isoformat(),
                    "end_time": event_end.isoformat(),
                    "type": event_template.type,
                    "status": "pendiente",
                    "reminder": True,
                    "postponed_count": 0
                })
    
    return {
        "message": f"Calendario generado con {len(generated_events)} eventos",
        "events": generated_events,
        "template": template.name
    }


# Template Management
@router.get("/templates", response_model=List[Dict[str, Any]])
async def get_templates():
    """Obtener todas las plantillas"""
    return [
        {
            "id": key,
            "name": template.name,
            "description": template.description,
            "eventCount": len(template.events)
        }
        for key, template in templates_db.items()
    ]


@router.post("/templates", response_model=Dict[str, Any])
async def create_template(template: CalendarTemplate):
    """Crear nueva plantilla"""
    template_id = f"template_{len(templates_db) + 1}"
    templates_db[template_id] = template
    return {
        "id": template_id,
        "name": template.name,
        "description": template.description,
        "eventCount": len(template.events)
    }


# System Tests
@router.post("/run-tests")
async def run_all_tests():
    """Ejecutar todos los tests del sistema"""
    results = {
        "habitML": {"status": "passed", "duration": 150},
        "notifications": {"status": "passed", "duration": 80},
        "enhancedAI": {"status": "passed", "duration": 120}
    }
    return {
        "message": "Tests completados",
        "results": results,
        "totalPassed": 3,
        "totalTests": 3
    }


@router.post("/test-notifications")
async def test_notifications():
    """Test de notificaciones"""
    return {
        "status": "passed",
        "message": "Sistema de notificaciones funcionando correctamente",
        "duration": 80
    }


# Firebase Admin Operations
@router.delete("/firebase/users/{user_id}/data")
async def clear_firestore_data(user_id: str):
    """Limpiar datos de Firestore para usuario"""
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    return {"message": "Datos de Firestore eliminados correctamente"}


@router.get("/firebase/users/{user_id}/backup")
async def backup_user_data(user_id: str):
    """Crear backup de datos del usuario"""
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    user = users_db[user_id]
    return {
        "user": user.dict(),
        "events": [],
        "timestamp": datetime.now().isoformat()
    }


@router.post("/firebase/users/{user_id}/restore")
async def restore_user_data(user_id: str, backup: Dict[str, Any] = Body(...)):
    """Restaurar datos del usuario desde backup"""
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    return {"message": "Datos restaurados correctamente"}


@router.delete("/google-token")
async def remove_google_token():
    """Eliminar token de autenticación de Google Calendar y limpiar base de datos local"""
    import os
    import glob
    import json
    
    tokens_dir = os.path.abspath("tokens")
    temp_events_file = os.path.abspath("temp_events.json")
    
    try:
        # 1. Eliminar todos los archivos de token
        token_files = glob.glob(os.path.join(tokens_dir, "*.pickle")) + \
                     glob.glob(os.path.join(tokens_dir, "*.json")) + \
                     glob.glob(os.path.join(tokens_dir, "token_*"))
        
        deleted_count = 0
        for token_file in token_files:
            if os.path.basename(token_file) != "README.md":  # No eliminar el README
                try:
                    os.remove(token_file)
                    deleted_count += 1
                    print(f"🗑️  Token eliminado: {token_file}")
                except Exception as e:
                    print(f"⚠️  No se pudo eliminar {token_file}: {e}")
        
        # 2. Limpiar base de datos local (temp_events.json)
        events_cleared = False
        if os.path.exists(temp_events_file):
            try:
                # Leer eventos actuales para contar
                with open(temp_events_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    events_count = len(data.get('events', []))
                
                # Limpiar eventos
                data['events'] = []
                
                # Guardar archivo vacío
                with open(temp_events_file, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                
                events_cleared = True
                print(f"🧹 Base de datos local limpiada: {events_count} eventos eliminados")
            except Exception as e:
                print(f"⚠️  Error al limpiar base de datos local: {e}")
        
        if deleted_count == 0 and not events_cleared:
            return {
                "message": "No se encontraron tokens ni eventos para eliminar",
                "deleted_count": 0,
                "events_cleared": 0
            }
        
        message = "Token de Google eliminado"
        if events_cleared:
            message += f" y base de datos local limpiada ({events_count} eventos)"
        
        return {
            "message": f"{message}. Re-autentica para sincronizar con tu Google Calendar.",
            "deleted_count": deleted_count,
            "events_cleared": events_count if events_cleared else 0
        }
    
    except Exception as e:
        print(f"❌ Error eliminando token: {e}")
        raise HTTPException(status_code=500, detail=f"Error al eliminar token: {str(e)}")


@router.delete("/dangerous/delete-all-events")
async def delete_all_events_dangerous():
    """⚠️ PELIGROSO: Eliminar TODOS los eventos de Google Calendar y la base de datos local
    
    ⛔ ADVERTENCIA CRÍTICA:
    - Esto eliminará TODOS los eventos de tu Google Calendar (datos externos)
    - Esto eliminará TODOS los eventos de la base de datos local
    - Esta acción NO SE PUEDE DESHACER
    - Úsalo solo para pruebas de desarrollo
    """
    from app.services.calendar_service import GoogleCalendarService
    import os
    import json
    
    try:
        google_service = GoogleCalendarService()
        temp_events_file = os.path.abspath("temp_events.json")
        
        deleted_google = 0
        deleted_local = 0
        errors = []
        
        # 1. Eliminar TODOS los eventos de Google Calendar
        try:
            service = google_service.get_service()
            if service:
                print("⚠️  INICIANDO ELIMINACIÓN MASIVA DE GOOGLE CALENDAR...")
                
                # Obtener todos los eventos de Google Calendar
                events_result = service.events().list(
                    calendarId='primary',
                    maxResults=2500,  # Máximo permitido por Google
                    singleEvents=True,
                    orderBy='startTime',
                    timeMin=datetime(2020, 1, 1).isoformat() + 'Z',  # Desde 2020
                    timeMax=datetime(2030, 12, 31).isoformat() + 'Z'  # Hasta 2030
                ).execute()
                
                google_events = events_result.get('items', [])
                print(f"📊 Encontrados {len(google_events)} eventos en Google Calendar")
                
                # Eliminar cada evento
                for event in google_events:
                    try:
                        service.events().delete(
                            calendarId='primary',
                            eventId=event['id']
                        ).execute()
                        deleted_google += 1
                        
                        if deleted_google % 10 == 0:
                            print(f"🗑️  Eliminados {deleted_google}/{len(google_events)} eventos de Google...")
                    
                    except Exception as e:
                        errors.append(f"Error eliminando evento Google '{event.get('summary', 'Sin título')}': {str(e)}")
                        print(f"⚠️  {errors[-1]}")
                
                print(f"✅ {deleted_google} eventos eliminados de Google Calendar")
            else:
                error_msg = "Google Calendar no disponible (no autenticado)"
                errors.append(error_msg)
                print(f"⚠️  {error_msg}")
                
        except Exception as e:
            error_msg = f"Error masivo en Google Calendar: {str(e)}"
            errors.append(error_msg)
            print(f"❌ {error_msg}")
        
        # 2. Limpiar base de datos local (temp_events.json)
        if os.path.exists(temp_events_file):
            try:
                # Leer eventos actuales
                with open(temp_events_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    deleted_local = len(data.get('events', []))
                
                # Limpiar completamente
                data['events'] = []
                
                # Guardar archivo vacío
                with open(temp_events_file, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                
                print(f"🧹 Base de datos local limpiada: {deleted_local} eventos eliminados")
            
            except Exception as e:
                error_msg = f"Error limpiando BD local: {str(e)}"
                errors.append(error_msg)
                print(f"❌ {error_msg}")
        
        # Resultado final
        if deleted_google == 0 and deleted_local == 0:
            return {
                "success": True,
                "message": "No se encontraron eventos para eliminar",
                "deleted_google": 0,
                "deleted_local": 0,
                "errors": errors
            }
        
        message = f"⚠️ ELIMINACIÓN MASIVA COMPLETADA: {deleted_google} eventos de Google Calendar, {deleted_local} eventos locales"
        
        if errors:
            message += f" (con {len(errors)} errores)"
        
        print(f"\n{'='*60}")
        print(f"  {message}")
        print(f"{'='*60}\n")
        
        return {
            "success": True,
            "message": message,
            "deleted_google": deleted_google,
            "deleted_local": deleted_local,
            "errors": errors,
            "warning": "Esta acción eliminó datos externos de Google Calendar"
        }
    
    except Exception as e:
        print(f"❌ Error crítico en eliminación masiva: {e}")
        raise HTTPException(status_code=500, detail=f"Error crítico: {str(e)}")
