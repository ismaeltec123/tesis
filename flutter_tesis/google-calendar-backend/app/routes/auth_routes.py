from fastapi import APIRouter, HTTPException, Query
from app.auth.google_oauth import GoogleAuthService
from app.services.calendar_service import GoogleCalendarService

router = APIRouter(prefix="/auth", tags=["authentication"])

auth_service = GoogleAuthService()

@router.get("/google")
async def login_google():
    """Inicia el proceso de autenticación con Google"""
    try:
        auth_url, state = auth_service.get_authorization_url()
        return {
            "auth_url": auth_url,
            "state": state,
            "message": "Visita la URL para autorizar la aplicación"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al generar URL de autorización: {str(e)}")

@router.get("/callback")
async def auth_callback(code: str = Query(...)):
    """Maneja el callback de autorización de Google"""
    try:
        credentials = auth_service.get_credentials_from_code(code)
        
        # Verificar que las credenciales funcionan
        calendar_service = GoogleCalendarService()
        service = calendar_service.get_service()
        
        return {
            "success": True,
            "message": "Autenticación exitosa con Google Calendar",
            "access_token": credentials.token if credentials else None
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error en la autenticación: {str(e)}")

@router.get("/status")
async def auth_status():
    """Verifica el estado de la autenticación"""
    try:
        credentials = auth_service.get_stored_credentials()
        if credentials and credentials.valid:
            return {
                "authenticated": True,
                "message": "Usuario autenticado correctamente"
            }
        else:
            return {
                "authenticated": False,
                "message": "Usuario no autenticado o credenciales expiradas"
            }
    except Exception as e:
        return {
            "authenticated": False,
            "message": f"Error al verificar autenticación: {str(e)}"
        }

@router.post("/revoke")
async def revoke_auth():
    """Revoca la autenticación de Google"""
    try:
        auth_service.revoke_credentials()
        return {
            "success": True,
            "message": "Autenticación revocada exitosamente"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al revocar autenticación: {str(e)}")
