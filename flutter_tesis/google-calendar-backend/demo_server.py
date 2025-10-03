#!/usr/bin/env python3
"""
Servidor de prueba Enhanced AI (ML + Groq)
"""
import sys
import os

# Agregar el directorio actual al path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    import uvicorn
    from app.main import app
    
    if __name__ == "__main__":
        print("🚀 Enhanced AI Server Starting...")
        print("📊 Machine Learning + 🤖 Groq LLM")
        print("🌐 Server: http://localhost:8004")
        print("📖 API Docs: http://localhost:8004/docs")
        print("🔧 Enhanced AI: http://localhost:8004/api/enhanced-ai/")
        print()
        
        uvicorn.run(
            app,
            host="localhost", 
            port=8004,
            reload=True,
            log_level="info"
        )
        
except ImportError as e:
    print(f"❌ Error: {e}")
    print("📦 Instala dependencias: pip install -r requirements.txt")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error iniciando servidor: {e}")
    sys.exit(1)