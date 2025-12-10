"""
Script de prueba para el microservicio ML
"""
import requests
import json
from datetime import datetime, timedelta

# URL del servicio
BASE_URL = "http://localhost:5000"

def test_health():
    """Test del health check"""
    print("\n📊 Testing /health endpoint...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))

def test_reschedule_with_few_data():
    """Test con pocos datos (usa heurísticas)"""
    print("\n📊 Testing /reschedule with few data points...")
    
    # Generar historial pequeño
    user_history = []
    base_date = datetime.now() - timedelta(days=10)
    
    for i in range(8):
        event_date = base_date + timedelta(days=i)
        status = "finalizado" if event_date.hour < 18 else "pendiente"
        
        user_history.append({
            "date": event_date.isoformat() + "Z",
            "status": status,
            "type": "estudio",
            "title": f"Evento {i+1}"
        })
    
    payload = {
        "user_id": "test_user_1",
        "event": {
            "id": "evt_test_1",
            "title": "Estudiar Machine Learning",
            "type": "estudio",
            "duration_minutes": 90,
            "original_date": datetime.now().isoformat() + "Z"
        },
        "user_history": user_history,
        "future_calendar": []
    }
    
    response = requests.post(f"{BASE_URL}/reschedule", json=payload)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"\nML Method: {result['ml_method']}")
        print(f"Confidence: {result['confidence']}")
        print(f"Data Points: {result['data_points_used']}")
        print(f"\nTop 3 Recommendations:")
        for rec in result['recommendations']:
            print(f"\n  Rank {rec['rank']}: {rec['day_name']} at {rec['hour']}:00")
            print(f"  Score: {rec['score']:.2f}")
            print(f"  Reasons:")
            for reason in rec['reasons']:
                print(f"    - {reason}")
    else:
        print(response.text)

def test_reschedule_with_enough_data():
    """Test con suficientes datos (usa Prophet)"""
    print("\n📊 Testing /reschedule with enough data for Prophet...")
    
    # Generar historial grande
    user_history = []
    base_date = datetime.now() - timedelta(days=30)
    
    for i in range(50):
        event_date = base_date + timedelta(days=i//2, hours=(i%24))
        
        # Simular patrón: más productivo en mañanas de días laborales
        hour = event_date.hour
        day_of_week = event_date.weekday()
        
        if day_of_week < 5 and 9 <= hour <= 17:
            status = "finalizado" if i % 3 != 0 else "pendiente"
        else:
            status = "finalizado" if i % 4 == 0 else "pendiente"
        
        user_history.append({
            "date": event_date.isoformat() + "Z",
            "status": status,
            "type": "estudio" if i % 2 == 0 else "trabajo",
            "title": f"Evento {i+1}"
        })
    
    payload = {
        "user_id": "test_user_2",
        "event": {
            "id": "evt_test_2",
            "title": "Preparar Presentación",
            "type": "trabajo",
            "duration_minutes": 120,
            "original_date": datetime.now().isoformat() + "Z"
        },
        "user_history": user_history,
        "future_calendar": []
    }
    
    response = requests.post(f"{BASE_URL}/reschedule", json=payload)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"\nML Method: {result['ml_method']}")
        print(f"Confidence: {result['confidence']}")
        print(f"Data Points: {result['data_points_used']}")
        print(f"\nTop 3 Recommendations:")
        for rec in result['recommendations']:
            print(f"\n  Rank {rec['rank']}: {rec['day_name']} at {rec['hour']}:00")
            print(f"  Score: {rec['score']:.2f}")
            print(f"  Prophet Prediction: {rec.get('prophet_prediction', 'N/A')}")
            print(f"  Reasons:")
            for reason in rec['reasons']:
                print(f"    - {reason}")
    else:
        print(response.text)

def test_analyze():
    """Test del endpoint de análisis"""
    print("\n📊 Testing /analyze endpoint...")
    
    user_history = []
    base_date = datetime.now() - timedelta(days=20)
    
    for i in range(30):
        event_date = base_date + timedelta(days=i//2, hours=(i%18 + 6))
        status = "finalizado" if i % 2 == 0 else "pendiente"
        
        user_history.append({
            "date": event_date.isoformat() + "Z",
            "status": status,
            "type": "estudio"
        })
    
    payload = {
        "user_id": "test_user_3",
        "user_history": user_history
    }
    
    response = requests.post(f"{BASE_URL}/analyze", json=payload)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"\nData Points: {result['data_points']}")
        print(f"\nOverall Completion Rate: {result['insights']['overall_completion_rate']*100:.1f}%")
        
        print(f"\nBest Hours:")
        for hour_info in result['insights']['best_hours']:
            print(f"  {hour_info['time']}: {hour_info['completion_rate']*100:.0f}%")
        
        print(f"\nBest Days:")
        for day_info in result['insights']['best_days']:
            print(f"  {day_info['name']}: {day_info['completion_rate']*100:.0f}%")
    else:
        print(response.text)

if __name__ == "__main__":
    print("🤖 ML Rescheduling Service - Test Suite")
    print("=" * 50)
    
    try:
        # Test 1: Health check
        test_health()
        
        # Test 2: Pocos datos (heurísticas)
        test_reschedule_with_few_data()
        
        # Test 3: Suficientes datos (Prophet)
        test_reschedule_with_enough_data()
        
        # Test 4: Análisis de patrones
        test_analyze()
        
        print("\n" + "=" * 50)
        print("✅ All tests completed!")
        
    except requests.exceptions.ConnectionError:
        print("\n❌ Error: Could not connect to ML service.")
        print("Make sure the service is running: python app.py")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
