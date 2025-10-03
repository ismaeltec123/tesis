#!/usr/bin/env python3
"""
Script para verificar que todos los archivos de la integración están presentes
"""

import os

def check_file_exists(file_path, description):
    """Verifica si un archivo existe"""
    if os.path.exists(file_path):
        print(f"✅ {description}: {file_path}")
        return True
    else:
        print(f"❌ {description}: {file_path} - NO ENCONTRADO")
        return False

def main():
    print("🔍 VERIFICANDO INTEGRACIÓN FLUTTER + GOOGLE CALENDAR")
    print("=" * 60)
    
    # Directorio base del proyecto Flutter
    flutter_base = "c:/sdk/tesis/flutter_tesis/tesis"
    
    # Archivos principales de Flutter
    flutter_files = [
        ("lib/main.dart", "Archivo principal de Flutter"),
        ("lib/models/event_model.dart", "Modelo de eventos"),
        ("lib/services/firebase_service.dart", "Servicio Firebase original"),
        ("lib/services/google_calendar_api_service.dart", "Servicio API Google Calendar"),
        ("lib/viewmodels/event_viewmodel.dart", "ViewModel integrado"),
        ("lib/views/calendar_view.dart", "Vista del calendario"),
        ("lib/views/main_screen.dart", "Pantalla principal"),
        ("pubspec.yaml", "Dependencias Flutter"),
    ]
    
    print("\n📱 ARCHIVOS FLUTTER:")
    flutter_ok = True
    for file_path, description in flutter_files:
        full_path = os.path.join(flutter_base, file_path)
        if not check_file_exists(full_path, description):
            flutter_ok = False
    
    # Directorio base del backend Python
    backend_base = "c:/sdk/tesis/flutter_tesis/google-calendar-backend"
    
    # Archivos del backend Python
    backend_files = [
        ("simple_server.py", "Servidor Python"),
        ("app/main.py", "API FastAPI principal"),
        ("app/services/google_calendar_api_service.py", "Servicio Google Calendar"),
        ("app/services/mock_firebase.py", "Servicio Firebase simulado"),
        ("app/routes/auth_routes.py", "Rutas de autenticación"),
        ("app/routes/calendar_routes.py", "Rutas de calendario"),
        ("app/routes/sync_routes.py", "Rutas de sincronización"),
        ("config/credentials.json", "Credenciales Google"),
        ("config/firebase-service-account.json", "Credenciales Firebase"),
        (".env", "Variables de entorno"),
        ("requirements.txt", "Dependencias Python"),
    ]
    
    print("\n🐍 ARCHIVOS BACKEND PYTHON:")
    backend_ok = True
    for file_path, description in backend_files:
        full_path = os.path.join(backend_base, file_path)
        if not check_file_exists(full_path, description):
            backend_ok = False
    
    # Verificar contenido importante
    print("\n🔍 VERIFICANDO CONTENIDO:")
    
    # Verificar pubspec.yaml
    pubspec_path = os.path.join(flutter_base, "pubspec.yaml")
    if os.path.exists(pubspec_path):
        with open(pubspec_path, 'r') as f:
            content = f.read()
            if 'http:' in content:
                print("✅ Dependencia 'http' presente en pubspec.yaml")
            else:
                print("❌ Dependencia 'http' NO encontrada en pubspec.yaml")
                flutter_ok = False
    
    # Verificar .env
    env_path = os.path.join(backend_base, ".env")
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            content = f.read()
            if 'GOOGLE_CLIENT_ID=' in content and 'GOOGLE_CLIENT_SECRET=' in content:
                print("✅ Credenciales Google configuradas en .env")
            else:
                print("❌ Credenciales Google NO configuradas en .env")
                backend_ok = False
    
    print("\n" + "=" * 60)
    if flutter_ok and backend_ok:
        print("🎉 ¡TODOS LOS ARCHIVOS ESTÁN PRESENTES!")
        print("\n📋 PRÓXIMOS PASOS:")
        print("1. Ejecutar: flutter pub get (en el directorio Flutter)")
        print("2. Iniciar backend: python simple_server.py")
        print("3. Ejecutar app Flutter")
        print("4. Autenticar con Google Calendar")
    else:
        print("❌ FALTAN ALGUNOS ARCHIVOS")
        if not flutter_ok:
            print("⚠️  Problema en archivos Flutter")
        if not backend_ok:
            print("⚠️  Problema en archivos Backend")

if __name__ == "__main__":
    main()
