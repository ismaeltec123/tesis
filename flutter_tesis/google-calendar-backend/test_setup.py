"""
Script de prueba para verificar la configuración de la API
"""

import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def test_imports():
    """Prueba que todas las dependencias se pueden importar"""
    try:
        import fastapi
        import uvicorn
        import google.oauth2.credentials
        import firebase_admin
        import pydantic
        print("✅ Todas las dependencias se importaron correctamente")
        return True
    except ImportError as e:
        print(f"❌ Error al importar dependencias: {e}")
        return False

def test_config_files():
    """Verifica que los archivos de configuración existen"""
    config_path = os.path.join(os.path.dirname(__file__), "..", "config")
    
    credentials_file = os.path.join(config_path, "credentials.json")
    firebase_file = os.path.join(config_path, "firebase-service-account.json")
    
    if os.path.exists(credentials_file):
        print("✅ Archivo de credenciales de Google encontrado")
    else:
        print("⚠️  Archivo de credenciales de Google NO encontrado")
        print(f"   Debe estar en: {credentials_file}")
    
    if os.path.exists(firebase_file):
        print("✅ Archivo de credenciales de Firebase encontrado")
    else:
        print("⚠️  Archivo de credenciales de Firebase NO encontrado")
        print(f"   Debe estar en: {firebase_file}")

def test_env_file():
    """Verifica el archivo .env"""
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    
    if os.path.exists(env_path):
        print("✅ Archivo .env encontrado")
        
        # Leer variables importantes
        try:
            from dotenv import load_dotenv
            load_dotenv(env_path)
            
            client_id = os.getenv("GOOGLE_CLIENT_ID")
            if client_id and client_id != "your_google_client_id_here":
                print("✅ GOOGLE_CLIENT_ID configurado")
            else:
                print("⚠️  GOOGLE_CLIENT_ID no configurado en .env")
                
        except Exception as e:
            print(f"⚠️  Error al leer .env: {e}")
    else:
        print("⚠️  Archivo .env NO encontrado")

def main():
    print("🔍 Verificando configuración de Google Calendar Integration API...")
    print("=" * 60)
    
    test_imports()
    print()
    
    test_config_files()
    print()
    
    test_env_file()
    print()
    
    print("=" * 60)
    print("📋 Para completar la configuración:")
    print("1. Configura las credenciales de Google Cloud Console")
    print("2. Configura las credenciales de Firebase")
    print("3. Actualiza el archivo .env con tus datos")
    print("4. Ejecuta: python -m app.main")
    print()
    print("📚 Documentación completa en README.md")

if __name__ == "__main__":
    main()
