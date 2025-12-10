"""
Servicio temporal de Firebase que funciona sin conexión real
para pruebas de Google Calendar
"""
from typing import List, Dict, Any
from datetime import datetime
import json
import os

class MockFirebaseService:
    """Servicio de Firebase simulado para pruebas"""
    
    def __init__(self):
        # Usar archivo temporal para simular base de datos en el directorio raíz del proyecto
        self.data_file = os.path.abspath("temp_events.json")
        self._ensure_data_file()
        print(f"🔥 Usando Firebase simulado - archivo: {self.data_file}")
    
    def _ensure_data_file(self):
        """Asegura que existe el archivo de datos temporal"""
        if not os.path.exists(self.data_file):
            with open(self.data_file, 'w') as f:
                json.dump({"events": []}, f)
    
    def _load_data(self):
        """Carga datos del archivo temporal"""
        try:
            with open(self.data_file, 'r') as f:
                return json.load(f)
        except:
            return {"events": []}
    
    def _save_data(self, data):
        """Guarda datos al archivo temporal"""
        with open(self.data_file, 'w') as f:
            json.dump(data, f, indent=2)
    
    def get_all_events(self) -> List[Dict[str, Any]]:
        """Obtiene todos los eventos"""
        try:
            data = self._load_data()
            events = data.get("events", [])
            
            print(f"📄 Cargando desde archivo: {self.data_file}")
            print(f"📊 Total eventos en archivo: {len(events)}")
            
            # Agregar firebase_id a cada evento
            for i, event in enumerate(events):
                if 'firebase_id' not in event:
                    event['firebase_id'] = f"temp_id_{i}"
            
            return events
        except Exception as e:
            print(f"❌ Error cargando eventos: {e}")
            return []
    
    def create_event(self, event_data: Dict[str, Any]) -> str:
        """Crea un evento (CON deduplicación)"""
        try:
            data = self._load_data()
            
            # Convertir datetime a string antes de guardar
            serializable_data = {}
            for key, value in event_data.items():
                if isinstance(value, datetime):
                    serializable_data[key] = value.isoformat()
                else:
                    serializable_data[key] = value
            
            # DEDUPLICACIÓN: Verificar si ya existe un evento idéntico
            existing_events = data.get("events", [])
            for existing in existing_events:
                if (existing.get('title') == serializable_data.get('title') and
                    existing.get('date') == serializable_data.get('date') and
                    existing.get('end_time') == serializable_data.get('end_time')):
                    print(f"⚠️  Evento duplicado detectado, omitiendo: {serializable_data.get('title')}")
                    return existing.get('firebase_id', 'existing_id')
            
            # Generar ID único
            event_id = f"temp_id_{datetime.now().timestamp()}"
            serializable_data['firebase_id'] = event_id
            serializable_data['created_at'] = datetime.now().isoformat()
            
            data["events"].append(serializable_data)
            self._save_data(data)
            
            print(f"✅ Evento creado (simulado): {serializable_data.get('title', 'Sin título')}")
            return event_id
            
        except Exception as e:
            print(f"❌ Error creando evento: {e}")
            raise
    
    def update_event(self, firebase_id: str, event_data: Dict[str, Any]) -> bool:
        """Actualiza un evento"""
        try:
            data = self._load_data()
            events = data.get("events", [])
            
            for i, event in enumerate(events):
                if event.get('firebase_id') == firebase_id:
                    # Convertir datetime a string antes de actualizar
                    serializable_data = {}
                    for key, value in event_data.items():
                        if isinstance(value, datetime):
                            serializable_data[key] = value.isoformat()
                        else:
                            serializable_data[key] = value
                    
                    # Actualizar evento
                    events[i].update(serializable_data)
                    events[i]['updated_at'] = datetime.now().isoformat()
                    self._save_data(data)
                    print(f"✅ Evento actualizado (simulado): {firebase_id}")
                    return True
            
            print(f"❌ Evento no encontrado: {firebase_id}")
            return False
            
        except Exception as e:
            print(f"Error actualizando evento: {e}")
            return False
    
    def delete_event(self, firebase_id: str) -> bool:
        """Elimina un evento"""
        try:
            data = self._load_data()
            events = data.get("events", [])
            
            original_count = len(events)
            events = [e for e in events if e.get('firebase_id') != firebase_id]
            
            if len(events) < original_count:
                data["events"] = events
                self._save_data(data)
                print(f"✅ Evento eliminado (simulado): {firebase_id}")
                return True
            else:
                print(f"❌ Evento no encontrado para eliminar: {firebase_id}")
                return False
                
        except Exception as e:
            print(f"Error eliminando evento: {e}")
            return False
    
    def find_event_by_google_id(self, google_event_id: str) -> Dict[str, Any]:
        """Busca un evento por su ID de Google Calendar"""
        try:
            events = self.get_all_events()
            
            for event in events:
                if event.get('google_event_id') == google_event_id:
                    return event
            
            return None
            
        except Exception as e:
            print(f"Error buscando evento por Google ID: {e}")
            return None
    
    def add_google_id_to_event(self, firebase_id: str, google_event_id: str) -> bool:
        """Agrega el ID de Google Calendar a un evento existente"""
        try:
            return self.update_event(firebase_id, {'google_event_id': google_event_id})
        except Exception as e:
            print(f"Error agregando Google ID: {e}")
            return False

# Instancia singleton compartida
_mock_firebase_instance = None

# Función para obtener el servicio correcto
def get_firebase_service():
    """Retorna el servicio de Firebase (real o simulado)"""
    global _mock_firebase_instance
    
    # FORZAR USO DE MOCK (evitar quota exceeded de Firebase real)
    if _mock_firebase_instance is None:
        print(f"🔥 Usando modo Firebase simulado (archivo local)")
        _mock_firebase_instance = MockFirebaseService()
    else:
        print(f"🔄 Reutilizando instancia de Firebase simulado")
    return _mock_firebase_instance
