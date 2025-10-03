"""
Servidor simplificado para Enhanced AI
"""
import sys
import os
import traceback

# Agregar el directorio actual al path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

def main():
    try:
        print("🚀 Iniciando servidor Enhanced AI simplificado...")
        
        # Importar después de configurar el path
        import uvicorn
        from app.main import app
        
        print("✅ Importaciones exitosas")
        print("📍 Servidor: http://localhost:8001")
        print("🤖 Enhanced AI: http://localhost:8001/api/enhanced-ai/system-status")
        print("📚 Documentación: http://localhost:8001/docs")
        print("❌ Para detener: Ctrl+C")
        print("=" * 60)
        
        # Configuración del servidor sin reload
        config = uvicorn.Config(
            app,
            host="localhost",
            port=8001,
            log_level="info",
            reload=False,
            access_log=True
        )
        
        server = uvicorn.Server(config)
        server.run()
        
    except KeyboardInterrupt:
        print("\n✅ Servidor detenido por el usuario")
    except Exception as e:
        print(f"❌ Error: {e}")
        print("🔍 Detalles del error:")
        traceback.print_exc()
        
        # Intentar instalar dependencias faltantes
        print("\n💡 Intentando instalar dependencias...")
        os.system("pip install uvicorn fastapi")

if __name__ == "__main__":
    main()