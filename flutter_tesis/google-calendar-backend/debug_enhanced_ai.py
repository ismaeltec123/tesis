"""
Script de debug para probar Enhanced AI
"""
import sys
import os

# Agregar el directorio actual al path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

def test_imports():
    """Probar que todas las importaciones funcionan"""
    try:
        print("🔍 Probando importaciones...")
        
        from app.main import app
        print("✅ app.main importado correctamente")
        
        from app.routes.enhanced_ai_routes import router
        print("✅ enhanced_ai_routes importado correctamente")
        
        from app.services.enhanced_ai_service import EnhancedAIService
        print("✅ EnhancedAIService importado correctamente")
        
        # Verificar rutas
        print("\n🔍 Rutas disponibles:")
        for route in app.routes:
            if hasattr(route, 'path'):
                print(f"  {route.path}")
        
        print("\n🔍 Rutas Enhanced AI:")
        for route in app.routes:
            if hasattr(route, 'path') and 'enhanced-ai' in route.path:
                methods = getattr(route, 'methods', ['UNKNOWN'])
                print(f"  ✅ {list(methods)} {route.path}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error en importaciones: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_service():
    """Probar que el servicio Enhanced AI funciona"""
    try:
        print("\n🤖 Probando servicio Enhanced AI...")
        from app.services.enhanced_ai_service import EnhancedAIService
        
        service = EnhancedAIService()
        status = service.get_system_status()
        
        print(f"✅ Estado del sistema: {status}")
        return True
        
    except Exception as e:
        print(f"❌ Error en servicio: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("🚀 Iniciando debug de Enhanced AI...")
    print("=" * 50)
    
    if test_imports() and test_service():
        print("\n✅ Todas las pruebas pasaron!")
        print("El servidor debería funcionar correctamente.")
    else:
        print("\n❌ Hay problemas que necesitan ser arreglados.")