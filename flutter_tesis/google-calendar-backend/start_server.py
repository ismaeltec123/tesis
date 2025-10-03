import sys
import os

# Agregar el directorio actual al PYTHONPATH
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import uvicorn
from app.main import app

if __name__ == "__main__":
    print("🚀 Iniciando Google Calendar Integration API...")
    print("📍 Servidor: http://localhost:8000")
    print("📚 Documentación: http://localhost:8000/docs")
    print("🔄 Endpoints principales:")
    print("   - /api/auth/google (Autenticación)")
    print("   - /api/calendar/events (Gestión de eventos)")
    print("   - /api/sync/full-sync (Sincronización)")
    print("-" * 50)
    
    uvicorn.run(
        app,
        host="localhost",
        port=8000,
        reload=True,
        log_level="info"
    )
