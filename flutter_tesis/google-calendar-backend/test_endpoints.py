"""
Test simple del endpoint Enhanced AI
"""
import requests
import json
import time

def test_endpoints():
    """Probar endpoints uno por uno"""
    base_url = "http://localhost:8001"
    
    endpoints = [
        "/health",
        "/api/enhanced-ai/system-status",
    ]
    
    for endpoint in endpoints:
        try:
            print(f"\n🔍 Probando: {base_url}{endpoint}")
            response = requests.get(f"{base_url}{endpoint}", timeout=5)
            
            print(f"  Status: {response.status_code}")
            if response.status_code == 200:
                data = response.json()
                print(f"  Response: {json.dumps(data, indent=2)}")
            else:
                print(f"  Error: {response.text}")
                
        except requests.exceptions.ConnectionError:
            print(f"  ❌ No se puede conectar al servidor")
        except Exception as e:
            print(f"  ❌ Error: {e}")
        
        time.sleep(1)

if __name__ == "__main__":
    print("🚀 Probando endpoints Enhanced AI...")
    test_endpoints()