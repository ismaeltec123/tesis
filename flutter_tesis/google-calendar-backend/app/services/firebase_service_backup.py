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
            with open(self.data_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except:
            return {"events": []}
    
    def _save_data(self, data):
        """Guarda datos al archivo temporal"""
        with open(self.data_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    
    def get_all_events(self) -> List[Dict[str, Any]]:
        """Obtiene todos los eventos"""
        try:
            data = self._load_data()
            events = data.get("events", [])
            
            print(f"📄 Cargando desde archivo: {self.data_file}")
            print(f"📊 Total eventos en archivo: {len(events)}")
            
            # Agregar campos faltantes en eventos existentes
            modified = False
            for i, event in enumerate(events):
                # Agregar firebase_id si no existe
                if 'firebase_id' not in event or not event['firebase_id']:
                    import hashlib
                    event_str = f"{event.get('title', '')}_{event.get('date', '')}_{i}"
                    event_hash = hashlib.md5(event_str.encode()).hexdigest()[:12]
                    event['firebase_id'] = f"event_{event_hash}"
                    print(f"⚠️  Evento sin ID, asignando: {event['firebase_id']}")
                    modified = True
                
                # Agregar campo 'imported' si no existe (basado en google_event_id)
                if 'imported' not in event:
                    event['imported'] = bool(event.get('google_event_id'))
                    modified = True
                
                # Agregar campo 'status' si no existe
                if 'status' not in event:
                    # Determinar estado basado en la fecha del evento
                    event_date_str = event.get('date')
                    if event_date_str:
                        try:
                            from datetime import datetime
                            if isinstance(event_date_str, str):
                                event_date = datetime.fromisoformat(event_date_str.replace('Z', ''))
                            else:
                                event_date = event_date_str
                            
                            now = datetime.now()
                            # Si el evento ya pasó, marcarlo como no_realizado
                            if event_date < now:
                                event['status'] = 'no_realizado'
                            else:
                                event['status'] = 'pendiente'
                        except:
                            event['status'] = 'pendiente'
                    else:
                        event['status'] = 'pendiente'
                    modified = True
                
                # Convertir tipos antiguos a los nuevos tipos válidos
                old_type = event.get('type', 'recreativo')
                if old_type == 'importado':
                    event['type'] = 'recreativo'
                    modified = True
                elif old_type == 'trabajo':
                    # Convertir "trabajo" a "estudio"
                    event['type'] = 'estudio'
                    modified = True
                
                # Validar que el tipo sea uno de los 4 válidos
                valid_types = ['obligatorio', 'recreativo', 'estudio', 'personal']
                if event.get('type') not in valid_types:
                    event['type'] = 'recreativo'
                    modified = True
                
                # Validar que el estado sea válido
                valid_statuses = ['pendiente', 'completado', 'no_realizado', 'postergado', 'cancelado', 'confirmado']
                if event.get('status') not in valid_statuses:
                    event['status'] = 'pendiente'
                    modified = True
                
                # Agregar campos nuevos si no existen
                if 'confirmed' not in event:
                    event['confirmed'] = False
                    modified = True
                
                if 'cancellation_reason' not in event:
                    event['cancellation_reason'] = None
                    modified = True
                
                if 'non_completion_reason' not in event:
                    event['non_completion_reason'] = None
                    modified = True
            
            # Si modificamos eventos, guardar el archivo
            if modified:
                self._save_data(data)
                print(f"💾 Campos actualizados guardados en archivo")
            
            return events
        except Exception as e:
            print(f"❌ Error cargando eventos: {e}")
            return []
    
    def create_event(self, event_data: Dict[str, Any]) -> str:
        """Crea un evento"""
        try:
            data = self._load_data()
            
            # Generar ID único
            event_id = f"temp_id_{datetime.now().timestamp()}"
            
            # Convertir datetime a string antes de guardar
            serializable_data = {}
            for key, value in event_data.items():
                if isinstance(value, datetime):
                    serializable_data[key] = value.isoformat()
                else:
                    serializable_data[key] = value
            
            serializable_data['firebase_id'] = event_id
            serializable_data['created_at'] = datetime.now().isoformat()
            
            # Asegurar que tenga el campo 'imported'
            if 'imported' not in serializable_data:
                serializable_data['imported'] = False
            
            # Asegurar que tenga el campo 'status'
            if 'status' not in serializable_data:
                serializable_data['status'] = 'pendiente'
            
            data["events"].append(serializable_data)
            self._save_data(data)
            
            print(f"✅ Evento creado (simulado): {serializable_data.get('title', 'Sin título')}")
            print(f"📁 Guardado en: {self.data_file}")
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
    
    def get_event_by_id(self, event_id: str) -> Dict[str, Any]:
        """Obtiene un evento por su firebase_id"""
        try:
            events = self.get_all_events()
            
            for event in events:
                if event.get('firebase_id') == event_id:
                    return event
            
            print(f"❌ Evento no encontrado con ID: {event_id}")
            return None
            
        except Exception as e:
            print(f"Error obteniendo evento por ID: {e}")
            return None

# Instancia singleton compartida
_mock_firebase_instance = None

# Función para obtener el servicio correcto
def get_firebase_service():
    """Retorna el servicio de Firebase (real o simulado)"""
    global _mock_firebase_instance
    
    try:
        # Intentar usar Firebase real
        from app.services.firebase_sync import FirebaseService
        return FirebaseService()
    except Exception as e:
        # Si falla, usar versión simulada (singleton)
        if _mock_firebase_instance is None:
            print(f"⚠️  Firebase no disponible, usando modo simulado")
            _mock_firebase_instance = MockFirebaseService()
        else:
            print(f"🔄 Reutilizando instancia de Firebase simulado")
        return _mock_firebase_instance
