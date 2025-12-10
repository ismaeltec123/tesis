"""
Script de prueba para el Microservicio ML
Demuestra el flujo completo de predicción
"""
import requests
import json
from datetime import datetime

ML_SERVICE_URL = "http://localhost:5000"

def print_section(title):
    print("\n" + "=" * 60)
    print(f"  {title}")
    print("=" * 60)

def test_health():
    """Verificar que el servicio esté activo"""
    print_section("1. HEALTH CHECK")
    
    response = requests.get(f"{ML_SERVICE_URL}/health")
    data = response.json()
    
    print(f"✅ Estado: {data['status']}")
    print(f"✅ Servicio: {data['service']}")
    print(f"✅ Modelo entrenado: {data['model_trained']}")
    print(f"✅ Puerto: {data['port']}")
    
    return data['model_trained']

def test_predict(title, duration):
    """Obtener 3 sugerencias de horarios para un evento"""
    print_section(f"2. PREDICCIÓN: {title}")
    
    payload = {
        "title": title,
        "duration_minutes": duration,
        "preferred_days": [0, 1, 2, 3, 4],  # Lunes a Viernes
        "constraints": {
            "earliest_hour": 8,
            "latest_hour": 22
        }
    }
    
    print(f"📝 Evento: {title}")
    print(f"⏱️  Duración: {duration} minutos")
    print(f"📅 Días preferidos: Lunes a Viernes")
    print(f"⏰ Restricción horaria: 8:00 - 22:00")
    print("\n🤖 Consultando al ML...")
    
    response = requests.post(f"{ML_SERVICE_URL}/predict", json=payload)
    
    if response.status_code == 200:
        data = response.json()
        suggestions = data['suggestions']
        
        print(f"\n✅ {len(suggestions)} SUGERENCIAS GENERADAS:\n")
        
        for i, sugg in enumerate(suggestions, 1):
            date_obj = datetime.fromisoformat(sugg['date'])
            end_obj = datetime.fromisoformat(sugg['end_time'])
            
            print(f"OPCIÓN {i}:")
            print(f"  📅 Día: {sugg['day_name']}")
            print(f"  📅 Fecha: {date_obj.strftime('%d/%m/%Y')}")
            print(f"  🕐 Hora: {date_obj.strftime('%H:%M')} - {end_obj.strftime('%H:%M')}")
            print(f"  📊 Confianza: {sugg['confidence'] * 100:.0f}%")
            print(f"  💡 Razón: {sugg['reason']}")
            print()
        
        return suggestions
    else:
        print(f"❌ Error: {response.json()}")
        return []

def test_analyze_conflict(suggestion, title):
    """Analizar conflictos para una sugerencia específica"""
    print_section(f"3. ANÁLISIS DE CONFLICTOS")
    
    payload = {
        "date": suggestion['date'],
        "end_time": suggestion['end_time'],
        "title": title
    }
    
    date_obj = datetime.fromisoformat(suggestion['date'])
    print(f"📝 Analizando: {title}")
    print(f"📅 {suggestion['day_name']} {date_obj.strftime('%d/%m/%Y %H:%M')}")
    print("\n🤖 Analizando conflictos...")
    
    response = requests.post(f"{ML_SERVICE_URL}/analyze-conflicts", json=payload)
    
    if response.status_code == 200:
        data = response.json()
        
        print(f"\n✅ ANÁLISIS COMPLETADO:\n")
        print(f"  ⚠️  Tiene conflicto: {'SÍ' if data['has_conflict'] else 'NO'}")
        print(f"  📊 Score de conflicto: {data['conflict_score'] * 100:.0f}%")
        print(f"  📈 Score de productividad: {data['productivity_score'] * 100:.0f}%")
        
        if data['warnings']:
            print(f"\n  ⚠️  ADVERTENCIAS:")
            for warning in data['warnings']:
                print(f"     - {warning}")
        
        if data['recommendations']:
            print(f"\n  ✅ RECOMENDACIONES:")
            for rec in data['recommendations']:
                print(f"     - {rec}")
    else:
        print(f"❌ Error: {response.json()}")

def main():
    print("\n" + "=" * 60)
    print("  🤖 DEMO: MICROSERVICIO ML - PREDICTOR DE CALENDARIO")
    print("=" * 60)
    print("\nFlujo:")
    print("1. Health check del microservicio")
    print("2. Solicitar 3 sugerencias de horario")
    print("3. Analizar la mejor sugerencia")
    print("4. En tu sistema: Elegir una sugerencia y crear evento automático")
    
    try:
        # 1. Verificar que el servicio esté activo
        is_trained = test_health()
        
        if not is_trained:
            print("\n❌ El modelo no está entrenado. Ejecuta primero el microservicio.")
            return
        
        # 2. Obtener predicciones para diferentes tipos de eventos
        
        # Ejemplo 1: Estudio
        print("\n" + "🎯" * 30)
        suggestions = test_predict("Estudiar Matemáticas", 90)
        
        if suggestions:
            # 3. Analizar la mejor sugerencia
            best_suggestion = suggestions[0]
            test_analyze_conflict(best_suggestion, "Estudiar Matemáticas")
        
        # Ejemplo 2: Ejercicio
        print("\n" + "🎯" * 30)
        suggestions2 = test_predict("Gimnasio", 60)
        
        if suggestions2:
            test_analyze_conflict(suggestions2[0], "Gimnasio")
        
        # Resumen final
        print_section("🎉 DEMO COMPLETADA")
        print("""
✅ El microservicio ML está funcionando correctamente

📋 PRÓXIMOS PASOS EN TU SISTEMA DE CALENDARIO:

1. Usuario solicita crear evento "Estudiar Física"
2. Sistema llama a POST /predict con título y duración
3. Muestra las 3 sugerencias al usuario
4. Usuario elige la opción 2
5. Sistema crea el evento automáticamente en esa fecha/hora
6. ¡Evento optimizado con ML creado!

🔗 INTEGRACIÓN:
- Backend: http://localhost:8001
- ML Service: http://localhost:5000
- OCR Service: http://localhost:8002
        """)
        
    except requests.exceptions.ConnectionError:
        print("\n❌ No se puede conectar al microservicio ML.")
        print("   Asegúrate de que esté corriendo en http://localhost:5000")
        print("   Ejecuta: python ml_microservice.py")

if __name__ == "__main__":
    main()
