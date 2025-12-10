"""
Rutas para el sistema ML de análisis de patrones de eventos.
Predice cuándo es más probable que un usuario falle y sugiere mejores horarios.
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, Dict, Any
import sys
import os

# Agregar path para importar ml_pattern_analyzer
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))

from ml_pattern_analyzer import (
    analyze_user_patterns,
    predict_event_risk,
    get_reschedule_suggestions,
    auto_fill_failure_data,
    EventPatternAnalyzer
)

router = APIRouter(tags=["ML Pattern Analysis"])

@router.get("/ml/analyze-patterns")
async def analyze_patterns(
    user_id: str = Query(default='estudiante_demo', description="ID del usuario")
):
    """
    Analiza patrones de cancelación y no realización de eventos del usuario.
    
    Retorna:
    - Estadísticas de falla por día de la semana
    - Estadísticas de falla por hora/franja horaria
    - Estadísticas de falla por tipo de evento
    - Peores y mejores días/horarios
    - Lista de eventos fallidos recientes
    """
    try:
        result = analyze_user_patterns(user_id)
        return {
            "success": True,
            "data": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error analizando patrones: {str(e)}")


@router.post("/ml/predict-risk")
async def predict_risk(
    event: Dict[str, Any],
    user_id: str = Query(default='estudiante_demo', description="ID del usuario")
):
    """
    Predice el riesgo de falla de un evento específico basado en patrones históricos.
    
    Body:
    - event: Dict con información del evento (id, title, date, endTime, type, etc.)
    
    Retorna:
    - risk_score: 0-100 (probabilidad de falla)
    - risk_level: BAJO, MEDIO, ALTO
    - reasons: Razones del riesgo
    - recommendations: Sugerencias para mejorar
    """
    try:
        result = predict_event_risk(event, user_id)
        return {
            "success": True,
            "data": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error prediciendo riesgo: {str(e)}")


@router.post("/ml/suggest-reschedule")
async def suggest_reschedule(
    event: Dict[str, Any],
    user_id: str = Query(default='estudiante_demo', description="ID del usuario")
):
    """
    Sugiere mejores horarios para un evento basado en patrones de éxito del usuario.
    
    Body:
    - event: Dict con información del evento a reprogramar
    
    Retorna:
    - Lista de sugerencias con día, hora, tasa de falla y razón
    """
    try:
        result = get_reschedule_suggestions(event, user_id)
        return {
            "success": True,
            "data": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generando sugerencias: {str(e)}")


@router.post("/ml/auto-fill-test-data")
async def auto_fill_test(
    user_id: str = Query(default='estudiante_demo', description="ID del usuario"),
    num_events: int = Query(default=5, ge=1, le=20, description="Número de eventos a modificar")
):
    """
    Rellena automáticamente eventos pendientes con estados de falla para testing ML.
    
    Marca eventos en horarios/días problemáticos como cancelados o no realizados.
    Útil para generar datos de prueba y entrenar el modelo.
    
    Query params:
    - user_id: ID del usuario
    - num_events: Número de eventos a modificar (1-20)
    
    Retorna:
    - Lista de eventos modificados con razón
    """
    try:
        result = auto_fill_failure_data(user_id, num_events)
        return {
            "success": True,
            "data": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error rellenando datos de prueba: {str(e)}")


@router.get("/ml/get-failure-hotspots")
async def get_failure_hotspots(
    user_id: str = Query(default='estudiante_demo', description="ID del usuario")
):
    """
    Obtiene los "puntos calientes" de falla: días y horarios más problemáticos.
    
    Retorna resumen simplificado enfocado en los peores patrones.
    """
    try:
        patterns = analyze_user_patterns(user_id)
        
        if 'error' in patterns:
            return {
                "success": False,
                "error": patterns['error']
            }
        
        # Extraer solo lo más importante
        hotspots = {
            'summary': patterns['summary'],
            'worst_days': patterns['worst_patterns']['days'],
            'worst_time_slots': patterns['worst_patterns']['time_slots'],
            'best_days': patterns['best_patterns']['days'],
            'best_time_slots': patterns['best_patterns']['time_slots'],
            'weekend_vs_weekday': patterns['weekend_vs_weekday']
        }
        
        return {
            "success": True,
            "data": hotspots
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error obteniendo hotspots: {str(e)}")


@router.get("/ml/stats")
async def get_ml_stats():
    """
    Retorna estadísticas y capacidades del sistema ML.
    """
    return {
        "success": True,
        "data": {
            "name": "Event Pattern Analyzer",
            "version": "1.0.0",
            "capabilities": [
                "Análisis de patrones de cancelación",
                "Predicción de riesgo de eventos",
                "Sugerencias de reprogramación inteligente",
                "Identificación de horarios problemáticos",
                "Análisis por día de semana, hora y tipo de evento"
            ],
            "features_analyzed": [
                "day_of_week",
                "hour",
                "time_slot",
                "event_type",
                "duration",
                "is_weekend"
            ],
            "status_tracked": [
                "pendiente",
                "confirmado",
                "completado",
                "no_realizado",
                "cancelado",
                "postergado"
            ]
        }
    }
