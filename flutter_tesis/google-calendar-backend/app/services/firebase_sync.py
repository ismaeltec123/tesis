import os
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False

from typing import List, Dict, Any
from config.settings import settings

class FirebaseService:
    def __init__(self):
        self.db = None
        if FIREBASE_AVAILABLE and os.path.exists(settings.FIREBASE_SERVICE_ACCOUNT_PATH):
            self._initialize_firebase()
        else:
            print("⚠️  Firebase no disponible, usando modo simulado")
            # Usar el servicio mock directamente
            from .mock_firebase import MockFirebaseService
            mock_service = MockFirebaseService()
            # Copiar métodos del mock
            for method_name in ['get_all_events', 'create_event', 'update_event', 
                              'delete_event', 'find_event_by_google_id', 'add_google_id_to_event']:
                setattr(self, method_name, getattr(mock_service, method_name))
    
    def _initialize_firebase(self):
        """Inicializa Firebase Admin SDK"""
        try:
            if not firebase_admin._apps:
                if os.path.exists(settings.FIREBASE_SERVICE_ACCOUNT_PATH):
                    cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
                    firebase_admin.initialize_app(cred)
                else:
                    # Usar credenciales por defecto si no hay archivo de servicio
                    firebase_admin.initialize_app()
            
            self.db = firestore.client()
            
        except Exception as e:
            print(f"Error al inicializar Firebase: {e}")
            raise
    
    def get_all_events(self) -> List[Dict[str, Any]]:
        """Obtiene todos los eventos de Firestore"""
        try:
            events_ref = self.db.collection('events')
            docs = events_ref.stream()
            
            events = []
            for doc in docs:
                event_data = doc.to_dict()
                event_data['firebase_id'] = doc.id
                events.append(event_data)
            
            return events
            
        except Exception as e:
            print(f"Error al obtener eventos de Firebase: {e}")
            return []
    
    def create_event(self, event_data: Dict[str, Any]) -> str:
        """Crea un evento en Firestore"""
        try:
            events_ref = self.db.collection('events')
            doc_ref = events_ref.add(event_data)
            return doc_ref[1].id  # Retorna el ID del documento
            
        except Exception as e:
            print(f"Error al crear evento en Firebase: {e}")
            raise
    
    def update_event(self, firebase_id: str, event_data: Dict[str, Any]) -> bool:
        """Actualiza un evento en Firestore"""
        try:
            doc_ref = self.db.collection('events').document(firebase_id)
            doc_ref.update(event_data)
            return True
            
        except Exception as e:
            print(f"Error al actualizar evento en Firebase: {e}")
            return False
    
    def delete_event(self, firebase_id: str) -> bool:
        """Elimina un evento de Firestore"""
        try:
            doc_ref = self.db.collection('events').document(firebase_id)
            doc_ref.delete()
            return True
            
        except Exception as e:
            print(f"Error al eliminar evento de Firebase: {e}")
            return False
    
    def find_event_by_google_id(self, google_event_id: str) -> Dict[str, Any]:
        """Busca un evento por su ID de Google Calendar"""
        try:
            events_ref = self.db.collection('events')
            query = events_ref.where('google_event_id', '==', google_event_id)
            docs = list(query.stream())
            
            if docs:
                doc = docs[0]
                event_data = doc.to_dict()
                event_data['firebase_id'] = doc.id
                return event_data
            
            return None
            
        except Exception as e:
            print(f"Error al buscar evento por Google ID: {e}")
            return None
    
    def add_google_id_to_event(self, firebase_id: str, google_event_id: str) -> bool:
        """Agrega el ID de Google Calendar a un evento existente"""
        try:
            doc_ref = self.db.collection('events').document(firebase_id)
            doc_ref.update({'google_event_id': google_event_id})
            return True
            
        except Exception as e:
            print(f"Error al agregar Google ID al evento: {e}")
            return False
