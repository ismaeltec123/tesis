"""
Rutas para el servicio de organización con IA
"""
from fastapi import APIRouter, HTTPException
from datetime import datetime, timedelta
from typing import List, Dict, Any
from pydantic import BaseModel

from ..services.ai_organizer import AIOrganizer
from ..services.mock_firebase import MockFirebaseService

router = APIRouter(prefix="/ai", tags=["AI Organizer"])

# Modelos Pydantic
class AnalyzeScheduleRequest(BaseModel):
    date: str  # ISO format date to analyze

class ConfirmSuggestionsRequest(BaseModel):
    confirmed_suggestions: List[Dict[str, Any]]

class UserPreferencesRequest(BaseModel):
    exercise_preferences: List[str]  # Activities user likes
    study_preferences: List[str]     # Study topics user prefers
    preferred_exercise_duration: int # Minutes
    preferred_study_duration: int    # Minutes

# Inicializar servicios
ai_organizer = AIOrganizer()
firebase_service = MockFirebaseService()

@router.post("/analyze-schedule")
async def analyze_schedule(request: AnalyzeScheduleRequest):
    """
    Analiza el horario de un día específico y genera sugerencias de IA
    """
    try:
        print(f"🤖 Analizando horario para fecha: {request.date}")
        
        # Parsear la fecha objetivo - manejar diferentes formatos
        date_str = request.date
        if 'Z' in date_str:
            date_str = date_str.replace('Z', '+00:00')
        
        target_date = datetime.fromisoformat(date_str)
        print(f"🎯 Fecha objetivo procesada: {target_date}")
        
        # Obtener todos los eventos
        all_events = firebase_service.get_all_events()
        print(f"📚 Obtenidos {len(all_events) if all_events else 0} eventos totales")
        
        # Analizar el horario
        schedule_analysis = ai_organizer.analyze_schedule(all_events, target_date)
        print(f"📊 Análisis completado: {len(schedule_analysis.get('free_slots', []))} espacios libres")
        
        # Generar sugerencias
        suggestions_result = ai_organizer.generate_suggestions(schedule_analysis)
        print(f"💡 Generadas {len(suggestions_result.get('suggestions', []))} sugerencias")
        
        return {
            "success": True,
            "data": suggestions_result
        }
        
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"❌ Error en análisis de IA: {error_details}")
        raise HTTPException(status_code=500, detail=f"Error analyzing schedule: {str(e)}")

@router.post("/confirm-suggestions")
async def confirm_suggestions(request: ConfirmSuggestionsRequest):
    """
    Confirma las sugerencias seleccionadas por el usuario y crea los eventos
    """
    try:
        # Convertir sugerencias a eventos
        events_to_create = ai_organizer.create_ai_events(request.confirmed_suggestions)
        
        # Crear los eventos en Firebase
        created_events = []
        for event_data in events_to_create:
            created_event = firebase_service.create_event(event_data)
            created_events.append(created_event)
        
        return {
            "success": True,
            "message": f"Se crearon {len(created_events)} eventos con IA",
            "events": created_events
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating AI events: {str(e)}")

@router.get("/exercise-activities")
async def get_exercise_activities():
    """
    Obtiene la lista de actividades de ejercicio disponibles
    """
    return {
        "success": True,
        "activities": ai_organizer.exercise_activities
    }

@router.get("/study-activities")
async def get_study_activities():
    """
    Obtiene la lista de actividades de estudio disponibles
    """
    return {
        "success": True,
        "activities": ai_organizer.study_activities
    }

@router.get("/health-recommendations")
async def get_health_recommendations():
    """
    Obtiene las recomendaciones de salud y productividad
    """
    return {
        "success": True,
        "recommendations": ai_organizer.health_recommendations
    }