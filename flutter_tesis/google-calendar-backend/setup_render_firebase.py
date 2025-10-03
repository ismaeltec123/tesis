#!/usr/bin/env python3
"""
Script para configurar Firebase en Render
Este script te ayuda a configurar las credenciales de Firebase como variable de entorno en Render
"""

import json
import os

def main():
    """Configura las credenciales de Firebase para Render"""
    
    # Ruta al archivo de credenciales
    firebase_path = "./config/firebase-service-account.json"
    
    if not os.path.exists(firebase_path):
        print(f"❌ No se encontró el archivo de credenciales: {firebase_path}")
        return
    
    try:
        # Leer el archivo de credenciales
        with open(firebase_path, 'r') as f:
            firebase_creds = json.load(f)
        
        # Convertir a JSON compacto (una sola línea)
        firebase_json = json.dumps(firebase_creds, separators=(',', ':'))
        
        print("🔧 Configuración de Firebase para Render")
        print("=" * 50)
        print()
        print("1. Ve a tu dashboard de Render: https://dashboard.render.com")
        print("2. Selecciona tu servicio de backend")
        print("3. Ve a 'Environment' en la configuración")
        print("4. Agrega esta variable de entorno:")
        print()
        print("NOMBRE DE LA VARIABLE:")
        print("FIREBASE_SERVICE_ACCOUNT_JSON")
        print()
        print("VALOR (copia toda esta línea):")
        print("-" * 50)
        print(firebase_json)
        print("-" * 50)
        print()
        print("5. Guarda los cambios y redespliega el servicio")
        print()
        print("✅ Credenciales preparadas para Render")
        print("📋 El valor está listo para copiar y pegar")
        
    except Exception as e:
        print(f"❌ Error al procesar las credenciales: {e}")

if __name__ == "__main__":
    main()
