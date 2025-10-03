"""
Script de inicio para la API de Google Calendar
"""
import sys
import os

# Agregar el directorio actual al path de Python
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

try:
    import uvicorn
    
    if __name__ == "__main__":
        print("🚀 Iniciando Google Calendar Integration API...")
        print("📍 Servidor: http://localhost:8001")
        print("📚 Documentación: http://localhost:8001/docs")
        print("❌ Para detener: Ctrl+C")
        print("=" * 50)
        
        # Usar string import para permitir reload
        uvicorn.run(
            "app.main:app",
            host="localhost",
            port=8001,
            reload=False,  # Desactivamos reload para evitar problemas
            log_level="info"
        )
        
except ImportError as e:
    print(f"❌ Error al importar módulos: {e}")
    print("💡 Asegúrate de que todas las dependencias están instaladas:")
    print("   pip install -r requirements.txt")
except Exception as e:
    print(f"❌ Error al iniciar el servidor: {e}")
    print("💡 Revisa la configuración y los archivos de credenciales")
