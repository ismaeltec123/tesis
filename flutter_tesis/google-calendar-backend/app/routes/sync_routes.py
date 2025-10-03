from fastapi import APIRouter, HTTPException
from app.models.event_models import SyncResponse
from app.services.sync_service import SyncService

router = APIRouter(prefix="/sync", tags=["synchronization"])

sync_service = SyncService()

@router.post("/import-from-google", response_model=SyncResponse)
async def import_events_from_google():
    """Importa todos los eventos de Google Calendar a Firebase con verificación de duplicados"""
    try:
        result = sync_service.import_from_google_only()
        
        return SyncResponse(
            success=result.get('success', False),
            message=result.get('message', 'Error desconocido'),
            events_synced=result.get('events_synced', 0),
            errors=result.get('errors', [])
        )
        
    except Exception as e:
        return SyncResponse(
            success=False,
            message=f"Error en la importación: {str(e)}",
            events_synced=0,
            errors=[str(e)]
        )

@router.post("/full-sync", response_model=SyncResponse)
async def full_synchronization():
    """Realiza una sincronización completa bidireccional con verificación de duplicados"""
    try:
        result = sync_service.full_sync()
        
        return SyncResponse(
            success=result.get('success', False),
            message=result.get('message', 'Error desconocido'),
            events_synced=result.get('events_synced', 0),
            errors=result.get('errors', [])
        )
        
    except Exception as e:
        return SyncResponse(
            success=False,
            message=f"Error en la sincronización completa: {str(e)}",
            events_synced=0,
            errors=[str(e)]
        )
