from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import HTMLResponse
from app.auth.google_oauth import GoogleAuthService
from app.services.calendar_service import GoogleCalendarService

router = APIRouter(prefix="/auth", tags=["authentication"])

auth_service = GoogleAuthService()

@router.get("/google")
async def login_google():
    """Inicia el proceso de autenticación con Google (método antiguo)"""
    try:
        auth_url, state = auth_service.get_authorization_url()
        return {
            "auth_url": auth_url,
            "state": state,
            "message": "Visita la URL para autorizar la aplicación"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al generar URL de autorización: {str(e)}")

@router.post("/google/auto")
async def login_google_auto():
    """Inicia autenticación automática abriendo el navegador"""
    try:
        result = auth_service.initiate_auto_auth()
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al iniciar autenticación: {str(e)}")

@router.get("/callback", response_class=HTMLResponse)
async def auth_callback(code: str = Query(...)):
    """Maneja el callback de autorización de Google"""
    try:
        credentials = auth_service.get_credentials_from_code(code)
        
        # Verificar que las credenciales funcionan
        calendar_service = GoogleCalendarService()
        service = calendar_service.get_service()
        
        # Página de éxito bonita
        success_html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Autenticación Exitosa</title>
            <style>
                body {
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                }
                .success-card {
                    background: white;
                    padding: 40px;
                    border-radius: 15px;
                    box-shadow: 0 10px 40px rgba(0,0,0,0.2);
                    text-align: center;
                    max-width: 500px;
                }
                .checkmark {
                    width: 80px;
                    height: 80px;
                    border-radius: 50%;
                    display: block;
                    stroke-width: 2;
                    stroke: #4CAF50;
                    stroke-miterlimit: 10;
                    margin: 10px auto;
                    box-shadow: inset 0px 0px 0px #4CAF50;
                    animation: fill .4s ease-in-out .4s forwards, scale .3s ease-in-out .9s both;
                }
                .checkmark__circle {
                    stroke-dasharray: 166;
                    stroke-dashoffset: 166;
                    stroke-width: 2;
                    stroke-miterlimit: 10;
                    stroke: #4CAF50;
                    fill: none;
                    animation: stroke 0.6s cubic-bezier(0.65, 0, 0.45, 1) forwards;
                }
                .checkmark__check {
                    transform-origin: 50% 50%;
                    stroke-dasharray: 48;
                    stroke-dashoffset: 48;
                    animation: stroke 0.3s cubic-bezier(0.65, 0, 0.45, 1) 0.8s forwards;
                }
                @keyframes stroke {
                    100% { stroke-dashoffset: 0; }
                }
                @keyframes scale {
                    0%, 100% { transform: none; }
                    50% { transform: scale3d(1.1, 1.1, 1); }
                }
                @keyframes fill {
                    100% { box-shadow: inset 0px 0px 0px 30px #4CAF50; }
                }
                h1 {
                    color: #333;
                    margin: 20px 0 10px 0;
                }
                p {
                    color: #666;
                    font-size: 16px;
                    margin: 10px 0;
                }
                .close-btn {
                    margin-top: 30px;
                    padding: 12px 30px;
                    background: #667eea;
                    color: white;
                    border: none;
                    border-radius: 25px;
                    font-size: 16px;
                    cursor: pointer;
                    transition: background 0.3s;
                }
                .close-btn:hover {
                    background: #764ba2;
                }
            </style>
        </head>
        <body>
            <div class="success-card">
                <svg class="checkmark" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 52 52">
                    <circle class="checkmark__circle" cx="26" cy="26" r="25" fill="none"/>
                    <path class="checkmark__check" fill="none" d="M14.1 27.2l7.1 7.2 16.7-16.8"/>
                </svg>
                <h1>¡Autenticación Exitosa! ✅</h1>
                <p>Tu cuenta de Google Calendar ha sido conectada correctamente.</p>
                <p>Ya puedes cerrar esta ventana y volver al panel de administración.</p>
                <button class="close-btn" onclick="window.close()">Cerrar Ventana</button>
            </div>
        </body>
        </html>
        """
        return success_html
        
    except Exception as e:
        error_html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Error de Autenticación</title>
            <style>
                body {{
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                }}
                .error-card {{
                    background: white;
                    padding: 40px;
                    border-radius: 15px;
                    box-shadow: 0 10px 40px rgba(0,0,0,0.2);
                    text-align: center;
                    max-width: 500px;
                }}
                h1 {{
                    color: #f5576c;
                    margin: 20px 0 10px 0;
                }}
                p {{
                    color: #666;
                    font-size: 16px;
                    margin: 10px 0;
                }}
                .error-icon {{
                    font-size: 60px;
                    margin: 20px 0;
                }}
                .retry-btn {{
                    margin-top: 30px;
                    padding: 12px 30px;
                    background: #f5576c;
                    color: white;
                    border: none;
                    border-radius: 25px;
                    font-size: 16px;
                    cursor: pointer;
                    transition: background 0.3s;
                }}
                .retry-btn:hover {{
                    background: #f093fb;
                }}
            </style>
        </head>
        <body>
            <div class="error-card">
                <div class="error-icon">❌</div>
                <h1>Error de Autenticación</h1>
                <p>{str(e)}</p>
                <p>Por favor, intenta nuevamente desde el panel de administración.</p>
                <button class="retry-btn" onclick="window.close()">Cerrar Ventana</button>
            </div>
        </body>
        </html>
        """
        return error_html

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
