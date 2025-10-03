#!/usr/bin/env python3
"""
Script para iniciar el servidor Enhanced AI en puerto 8001
"""
import uvicorn
from app.main import app

if __name__ == "__main__":
    print("🚀 Iniciando Enhanced AI Server...")
    print("📊 Machine Learning + 🤖 Groq LLM")
    print("🌐 http://localhost:8001")
    print("📖 Docs: http://localhost:8001/docs")
    print("🤖 Enhanced AI: http://localhost:8001/api/enhanced-ai/system-status")
    print()
    
    uvicorn.run(
        app,
        host="localhost",
        port=8001,
        reload=True,
        log_level="info"
    )