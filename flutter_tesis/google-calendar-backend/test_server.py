#!/usr/bin/env python3
"""
Script de prueba para verificar que el servidor Google Calendar API funciona correctamente
"""

import sys
import os
import json
import requests
import time

# Agregar el directorio actual al PYTHONPATH
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_server_health():
    """Prueba que el servidor esté funcionando"""
    try:
        response = requests.get('http://localhost:8000/health', timeout=5)
        if response.status_code == 200:
            print("✅ Servidor funcionando correctamente")
            return True
        else:
            print(f"❌ Error del servidor: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ No se puede conectar al servidor. ¿Está ejecutándose?")
        return False
    except Exception as e:
        print(f"❌ Error inesperado: {e}")
        return False

def test_endpoints():
    """Prueba los endpoints principales"""
    base_url = 'http://localhost:8000/api'
    
    endpoints_to_test = [
        ('/auth/status', 'GET'),
        ('/auth/google', 'GET'),
    ]
    
    print("\n🔍 Probando endpoints...")
    
    for endpoint, method in endpoints_to_test:
        try:
            url = base_url + endpoint
            if method == 'GET':
                response = requests.get(url, timeout=5)
            
            print(f"  {method} {endpoint}: {response.status_code}")
            
            if response.status_code == 200:
                try:
                    data = response.json()
                    if endpoint == '/auth/status':
                        auth_status = data.get('authenticated', False)
                        print(f"    🔐 Autenticado: {'Sí' if auth_status else 'No'}")
                    elif endpoint == '/auth/google':
                        auth_url = data.get('auth_url', '')
                        if auth_url:
                            print(f"    🔗 URL de autorización generada correctamente")
                        else:
                            print(f"    ❌ No se generó URL de autorización")
                except:
                    print(f"    ⚠️  Respuesta no es JSON válido")
            
        except Exception as e:
            print(f"  ❌ Error en {endpoint}: {e}")

def test_dependencies():
    """Verifica que las dependencias estén instaladas"""
    print("🔍 Verificando dependencias...")
    
    dependencies = [
        'fastapi',
        'uvicorn',
        'google.oauth2',
        'googleapiclient',
        'firebase_admin',
        'pydantic'
    ]
    
    missing = []
    
    for dep in dependencies:
        try:
            __import__(dep)
            print(f"  ✅ {dep}")
        except ImportError:
            print(f"  ❌ {dep} - NO INSTALADO")
            missing.append(dep)
    
    if missing:
        print(f"\n❌ Dependencias faltantes: {', '.join(missing)}")
        print("Ejecuta: pip install -r requirements.txt")
        return False
    else:
        print("✅ Todas las dependencias están instaladas")
        return True

def test_config_files():
    """Verifica que los archivos de configuración existan"""
    print("\n🔍 Verificando archivos de configuración...")
    
    files_to_check = [
        ('.env', 'Variables de entorno'),
        ('config/credentials.json', 'Credenciales de Google'),
        ('config/firebase-service-account.json', 'Credenciales de Firebase'),
    ]
    
    all_present = True
    
    for file_path, description in files_to_check:
        if os.path.exists(file_path):
            print(f"  ✅ {description}: {file_path}")
        else:
            print(f"  ⚠️  {description}: {file_path} - NO ENCONTRADO")
            if 'credentials' in file_path:
                all_present = False
    
    if not all_present:
        print("\n⚠️  Algunos archivos de configuración no están presentes.")
        print("Consulta SETUP_INSTRUCTIONS.md para obtenerlos.")
    
    return all_present

def main():
    """Función principal de pruebas"""
    print("🚀 PROBANDO GOOGLE CALENDAR INTEGRATION API")
    print("=" * 50)
    
    # Verificar dependencias
    deps_ok = test_dependencies()
    if not deps_ok:
        print("\n❌ No se pueden ejecutar más pruebas sin las dependencias.")
        return
    
    # Verificar archivos de configuración
    config_ok = test_config_files()
    
    # Probar servidor
    print("\n🔍 Verificando servidor...")
    server_ok = test_server_health()
    
    if server_ok:
        test_endpoints()
        
        print("\n" + "=" * 50)
        print("✅ SERVIDOR FUNCIONANDO CORRECTAMENTE")
        
        if not config_ok:
            print("\n⚠️  NOTA: Para funcionalidad completa, configura:")
            print("  1. Credenciales de Google (config/credentials.json)")
            print("  2. Credenciales de Firebase (config/firebase-service-account.json)")
            print("  3. Variables de entorno (.env)")
            print("\nConsulta SETUP_INSTRUCTIONS.md para más detalles.")
        
        print("\n🌐 Accede a:")
        print("  - API: http://localhost:8000")
        print("  - Documentación: http://localhost:8000/docs")
        print("  - Estado de salud: http://localhost:8000/health")
        
    else:
        print("\n❌ SERVIDOR NO ESTÁ FUNCIONANDO")
        print("Para iniciar el servidor, ejecuta: python start_server.py")

if __name__ == "__main__":
    main()
