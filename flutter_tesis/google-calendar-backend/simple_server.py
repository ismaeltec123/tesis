import sys
import os

# Agregar el directorio actual al PYTHONPATH
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Crear la aplicación FastAPI
app = FastAPI(
    title="Google Calendar Integration API",
    description="API para sincronización entre Flutter/Firebase y Google Calendar",
    version="1.0.0"
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    """Endpoint raíz de la API"""
    return {
        "message": "Google Calendar Integration API",
        "version": "1.0.0",
        "status": "funcionando",
        "endpoints": {
            "auth": "/api/auth",
            "calendar": "/api/calendar", 
            "sync": "/api/sync",
            "docs": "/docs",
            "redoc": "/redoc"
        }
    }

@app.get("/health")
async def health_check():
    """Endpoint de verificación de salud"""
    return {
        "status": "healthy",
        "message": "API funcionando correctamente"
    }

# Importar y registrar rutas solo si no hay errores
try:
    from app.routes.auth_routes import router as auth_router
    app.include_router(auth_router, prefix="/api")
    print("✅ Rutas de autenticación cargadas")
except Exception as e:
    print(f"⚠️  Error cargando rutas de autenticación: {e}")

try:
    from app.routes.calendar_routes import router as calendar_router
    app.include_router(calendar_router, prefix="/api")
    print("✅ Rutas de calendario cargadas")
except Exception as e:
    print(f"⚠️  Error cargando rutas de calendario: {e}")

try:
    from app.routes.sync_routes import router as sync_router
    app.include_router(sync_router, prefix="/api")
    print("✅ Rutas de sincronización cargadas")
except Exception as e:
    print(f"⚠️  Error cargando rutas de sincronización: {e}")

try:
    from app.routes.ai_routes import router as ai_router
    app.include_router(ai_router, prefix="/api")
    print("✅ Rutas de IA cargadas")
except Exception as e:
    print(f"⚠️  Error cargando rutas de IA: {e}")

try:
    from app.routes.ml_routes import router as ml_router
    app.include_router(ml_router, prefix="/api")
    print("✅ Rutas de ML Pattern Analysis cargadas")
except Exception as e:
    print(f"⚠️  Error cargando rutas de ML: {e}")

try:
    from app.routes.ml_scenario_routes import router as ml_scenario_router
    app.include_router(ml_scenario_router, prefix="/api")
    print("✅ Rutas de ML Scenario Generator cargadas")
except Exception as e:
    print(f"⚠️  Error cargando rutas de ML Scenario: {e}")

try:
    from app.routes.ml_history_routes import router as ml_history_router
    app.include_router(ml_history_router, prefix="/api")
    print("✅ Rutas de ML History Generator cargadas")
except Exception as e:
    print(f"⚠️  Error cargando rutas de ML History: {e}")

try:
    from app.routes.schedule_parser_routes import router as schedule_parser_router
    app.include_router(schedule_parser_router, prefix="/api")
    print("✅ Rutas de Schedule Parser cargadas")
except Exception as e:
    print(f"⚠️  Error cargando rutas de Schedule Parser: {e}")

try:
    from app.routes.admin_routes import router as admin_router
    app.include_router(admin_router)
    print("✅ Rutas de Admin cargadas")
except Exception as e:
    print(f"⚠️  Error cargando rutas de Admin: {e}")

if __name__ == "__main__":
    import os
    
    # Configuración para desarrollo y producción
    host = os.getenv("HOST", "localhost")
    port = int(os.getenv("PORT", "8001"))
    debug = os.getenv("DEBUG", "True").lower() == "true"
    
    print("🚀 Iniciando Google Calendar Integration API...")
    print(f"📍 Servidor: http://{host}:{port}")
    print(f"📚 Documentación: http://{host}:{port}/docs")
    print("🔄 Endpoints principales:")
    print("   - /api/auth/google (Autenticación)")
    print("   - /api/calendar/events (Gestión de eventos)")
    print("   - /api/sync/full-sync (Sincronización)")
    print("   - /api/ai/analyze-schedule (Organización IA)")
    print("   - /api/ml/analyze-patterns (Análisis ML de patrones)")
    print("   - /api/schedule-parser/parse-schedule (Importar horarios JPG/PNG)")
    print(f"🌍 Entorno: {'Desarrollo' if debug else 'Producción'}")
    print("-" * 50)
    
    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level="info" if debug else "warning"
    )
