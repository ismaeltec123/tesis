"""
Rutas para el parser de horarios (importación de imágenes JPG/PNG)
"""
from fastapi import APIRouter, UploadFile, File, HTTPException
from typing import Dict, Any, List
import httpx
import base64
import os
from datetime import datetime, timedelta
from app.services.mock_firebase import get_firebase_service
from app.services.calendar_service import GoogleCalendarService

router = APIRouter(prefix="/schedule-parser", tags=["Schedule Parser"])

# URL del servicio OCR (local)
OCR_SERVICE_URL = os.getenv("OCR_SERVICE_URL", "http://localhost:8002")

@router.post("/parse-schedule")
async def parse_schedule_image(file: UploadFile = File(...)) -> Dict[str, Any]:
    """
    Procesa una imagen de horario usando el servicio OCR local
    """
    try:
        print(f"📸 Recibiendo imagen: {file.filename}")
        
        # Leer el contenido del archivo
        image_bytes = await file.read()
        
        # Codificar a base64
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')
        
        print(f"🔄 Enviando imagen al servicio OCR en {OCR_SERVICE_URL}")
        
        # Enviar al servicio OCR
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{OCR_SERVICE_URL}/process-image",
                files={"image": (file.filename, image_bytes, file.content_type)}
            )
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=500,
                    detail=f"Error del servicio OCR: {response.status_code}"
                )
            
            result = response.json()
            
            # El OCR devuelve 'clases' dentro de 'data'
            clases_detectadas = result.get('data', {}).get('clases', [])
            eventos_calendario = result.get('calendar', {}).get('eventos', [])
            
            print(f"✅ Horario procesado exitosamente")
            print(f"📊 {len(clases_detectadas)} clases detectadas")
            print(f"📅 {len(eventos_calendario)} eventos de calendario generados")
            
            # Transformar a formato esperado por Flutter (schedules)
            schedules = []
            for clase in clases_detectadas:
                schedule = {
                    "day": clase.get("dia"),
                    "week_type": clase.get("semana"),  # "Impar" o "Par"
                    "start_time": clase.get("hora_inicio"),
                    "end_time": clase.get("hora_fin"),
                    "course": clase.get("curso"),
                    "section": clase.get("seccion"),
                    "classroom": clase.get("aula"),
                    "subgroup": clase.get("subgrupo"),
                    "teacher": result.get('data', {}).get('docente', '')
                }
                schedules.append(schedule)
            
            print(f"📋 Convertidos {len(schedules)} schedules para Flutter")
            
            return {
                "success": True,
                "schedules": schedules,  # Formato esperado por Flutter
                "calendar": result.get("calendar"),
                "data": result.get("data"),
                "message": f"Horario procesado: {len(clases_detectadas)} clases detectadas"
            }
            
    except httpx.TimeoutException:
        raise HTTPException(
            status_code=504,
            detail="Timeout al procesar la imagen. El servicio OCR no responde."
        )
    except Exception as e:
        print(f"❌ Error al procesar horario: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al procesar el horario: {str(e)}"
        )

@router.get("/health")
async def health_check():
    """Verifica el estado del servicio OCR"""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{OCR_SERVICE_URL}/")
            return {
                "status": "healthy",
                "ocr_service": "connected",
                "ocr_url": OCR_SERVICE_URL
            }
    except Exception as e:
        return {
            "status": "degraded",
            "ocr_service": "disconnected",
            "ocr_url": OCR_SERVICE_URL,
            "error": str(e)
        }
