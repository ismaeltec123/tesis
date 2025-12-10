"""
Rutas para el servicio Enhanced AI (ML + Groq)
"""
from fastapi import APIRouter, HTTPException
from datetime import datetime
from typing import List, Dict, Any
from pydantic import BaseModel

from ..services.enhanced_ai_service import EnhancedAIService
from ..services.mock_firebase import MockFirebaseService

router = APIRouter(prefix="/enhanced-ai", tags=["Enhanced AI"])

# Endpoint de prueba simple
@router.get("/test")
async def test_endpoint():
    """Endpoint de prueba simple"""
    return {"status": "ok", "message": "Enhanced AI router is working"}

# Modelos Pydantic
class ChatRequest(BaseModel):
    message: str
    include_calendar_context: bool = True

class GenerateEventRequest(BaseModel):
    title: str
    hour: int = 10
    day_of_week: int = 1
    duration: int = 60
    context: str = ""

class StudyPlanRequest(BaseModel):
    subject: str
    exam_date: str
    include_optimization: bool = True

class CalendarAnalysisRequest(BaseModel):
    days_to_analyze: int = 30

# Inicializar servicios
enhanced_ai = EnhancedAIService()
firebase_service = MockFirebaseService()

@router.post("/initialize")
async def initialize_ai_system():
    """
    Inicializa el sistema ML+IA con datos del usuario
    """
    try:
        print("🚀 Inicializando sistema Enhanced AI...")
        
        # Obtener datos históricos
        all_events = firebase_service.get_all_events()
        print(f"📚 Obtenidos {len(all_events) if all_events else 0} eventos para entrenamiento")
        
        # Inicializar sistema
        enhanced_ai.initialize_with_data(all_events or [])
        
        # Verificar estado
        status = enhanced_ai.get_system_status()
        
        return {
            "success": True,
            "message": "Sistema Enhanced AI inicializado correctamente",
            "events_processed": len(all_events) if all_events else 0,
            "system_status": status
        }
        
    except Exception as e:
        print(f"❌ Error inicializando Enhanced AI: {e}")
        raise HTTPException(status_code=500, detail=f"Error initializing Enhanced AI: {str(e)}")

@router.post("/analyze-calendar")
async def analyze_calendar(request: CalendarAnalysisRequest):
    """
    Análisis completo del calendario usando ML + Groq
    """
    try:
        print(f"📊 Analizando calendario (últimos {request.days_to_analyze} días)...")
        
        # Obtener eventos
        all_events = firebase_service.get_all_events()
        
        if not all_events:
            return {
                "success": False,
                "message": "No hay eventos para analizar"
            }
        
        # Análisis completo ML + IA
        analysis_result = enhanced_ai.analyze_user_calendar(all_events)
        
        return {
            "success": True,
            "data": analysis_result
        }
        
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"❌ Error en análisis de calendario: {error_details}")
        raise HTTPException(status_code=500, detail=f"Error analyzing calendar: {str(e)}")

@router.post("/chat")
async def chat_with_ai(request: ChatRequest):
    """
    Chat conversacional con IA que incluye contexto del calendario
    """
    try:
        print(f"💬 Chat IA: '{request.message}'")
        
        # Obtener contexto del calendario si se solicita
        calendar_context = None
        if request.include_calendar_context:
            all_events = firebase_service.get_all_events()
            calendar_context = all_events[-10:] if all_events else []  # Últimos 10 eventos
        
        # Chat con IA
        chat_result = enhanced_ai.chat_with_ai(request.message, calendar_context)
        
        return {
            "success": True,
            "data": chat_result
        }
        
    except Exception as e:
        print(f"❌ Error en chat IA: {e}")
        raise HTTPException(status_code=500, detail=f"Error in AI chat: {str(e)}")

@router.post("/generate-event")
async def generate_smart_event(request: GenerateEventRequest):
    """
    Genera contenido inteligente para un evento usando ML + Groq
    """
    try:
        print(f"✨ Generando evento inteligente: '{request.title}'")
        
        # Preparar datos del evento parcial
        partial_event = {
            "title": request.title,
            "hour": request.hour,
            "day_of_week": request.day_of_week,
            "duration": request.duration,
            "context": request.context
        }
        
        # Obtener historial para contexto ML
        user_history = firebase_service.get_all_events()
        
        # Generar contenido inteligente
        generation_result = enhanced_ai.generate_smart_event(partial_event, user_history)
        
        return {
            "success": True,
            "data": generation_result
        }
        
    except Exception as e:
        print(f"❌ Error generando evento: {e}")
        raise HTTPException(status_code=500, detail=f"Error generating event: {str(e)}")

@router.post("/create-study-plan")
async def create_intelligent_study_plan(request: StudyPlanRequest):
    """
    Crea un plan de estudio inteligente optimizado con ML
    """
    try:
        print(f"📚 Creando plan de estudio: {request.subject} -> {request.exam_date}")
        
        # Obtener calendario actual para optimización
        current_events = firebase_service.get_all_events()
        
        # Crear plan inteligente
        study_plan = enhanced_ai.create_intelligent_study_plan(
            request.subject,
            request.exam_date,
            current_events or []
        )
        
        return {
            "success": True,
            "data": study_plan
        }
        
    except Exception as e:
        print(f"❌ Error creando plan de estudio: {e}")
        raise HTTPException(status_code=500, detail=f"Error creating study plan: {str(e)}")

@router.get("/predict-optimization")
async def predict_schedule_optimization():
    """
    Predice optimizaciones para el horario actual usando ML
    """
    try:
        print("🔮 Prediciendo optimizaciones de horario...")
        
        # Obtener eventos de la semana actual
        all_events = firebase_service.get_all_events()
        
        # Filtrar eventos recientes (simulado - en realidad sería por fecha)
        recent_events = all_events[-20:] if all_events else []
        
        # Predicción ML
        optimization = enhanced_ai.predict_schedule_optimization(recent_events)
        
        return {
            "success": True,
            "data": optimization
        }
        
    except Exception as e:
        print(f"❌ Error en predicción: {e}")
        raise HTTPException(status_code=500, detail=f"Error predicting optimization: {str(e)}")

@router.get("/system-status")
async def get_system_status():
    """
    Obtiene el estado del sistema Enhanced AI
    """
    try:
        status = enhanced_ai.get_system_status()
        
        return {
            "success": True,
            "system_status": status,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        print(f"❌ Error obteniendo estado: {e}")
        raise HTTPException(status_code=500, detail=f"Error getting system status: {str(e)}")

@router.post("/demo-data")
async def create_demo_data():
    """
    Crea datos de demostración para probar el sistema ML+IA
    """
    try:
        print("🎭 Creando datos de demostración...")
        
        # Eventos de demo para entrenar ML
        demo_events = [
            {
                "title": "Estudiar matemáticas",
                "description": "Sesión de cálculo integral",
                "date": "2024-09-30T09:00:00",
                "end_time": "2024-09-30T10:30:00",
                "type": "estudio"
            },
            {
                "title": "Reunión proyecto tesis",
                "description": "Revisión de avances con tutor",
                "date": "2024-09-30T14:00:00",
                "end_time": "2024-09-30T15:00:00",
                "type": "trabajo"
            },
            {
                "title": "Ejercicio gimnasio",
                "description": "Rutina de fuerza",
                "date": "2024-09-30T18:00:00",
                "end_time": "2024-09-30T19:00:00",
                "type": "ejercicio"
            },
            {
                "title": "Estudiar física",
                "description": "Mecánica cuántica",
                "date": "2024-10-01T10:00:00",
                "end_time": "2024-10-01T11:30:00",
                "type": "estudio"
            },
            {
                "title": "Correr en parque",
                "description": "Cardio 5km",
                "date": "2024-10-01T07:00:00",
                "end_time": "2024-10-01T08:00:00",
                "type": "ejercicio"
            }
        ]
        
        # Crear eventos de demo
        created_events = []
        for event_data in demo_events:
            try:
                created_event = firebase_service.create_event(event_data)
                created_events.append(created_event)
            except Exception as e:
                print(f"⚠️ Error creando evento demo: {e}")
        
        # Re-inicializar IA con nuevos datos
        all_events = firebase_service.get_all_events()
        enhanced_ai.initialize_with_data(all_events)
        
        return {
            "success": True,
            "message": f"Creados {len(created_events)} eventos de demostración",
            "events_created": len(created_events),
            "total_events": len(all_events),
            "ai_retrained": True
        }
        
    except Exception as e:
        print(f"❌ Error creando datos demo: {e}")
        raise HTTPException(status_code=500, detail=f"Error creating demo data: {str(e)}")