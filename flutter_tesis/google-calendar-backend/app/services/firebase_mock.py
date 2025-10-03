"""
Versión simplificada del servicio Firebase para pruebas
Este archivo simula Firebase cuando no tienes las credenciales configuradas
"""

class FirebaseService:
    def __init__(self):
        self.events = []  # Lista en memoria para pruebas
        print("⚠️  Firebase simulado - usando almacenamiento en memoria")
    
    def get_all_events(self):
        """Obtiene todos los eventos (simulado)"""
        return self.events
    
    def create_event(self, event_data):
        """Crea un evento (simulado)"""
        import uuid
        event_id = str(uuid.uuid4())
        event_data['firebase_id'] = event_id
        self.events.append(event_data)
        print(f"✅ Evento simulado creado: {event_data.get('title')}")
        return event_id
    
    def update_event(self, firebase_id, event_data):
        """Actualiza un evento (simulado)"""
        for i, event in enumerate(self.events):
            if event.get('firebase_id') == firebase_id:
                self.events[i].update(event_data)
                print(f"✅ Evento simulado actualizado: {event_data.get('title', 'Sin título')}")
                return True
        return False
    
    def delete_event(self, firebase_id):
        """Elimina un evento (simulado)"""
        original_count = len(self.events)
        self.events = [e for e in self.events if e.get('firebase_id') != firebase_id]
        success = len(self.events) < original_count
        if success:
            print(f"✅ Evento simulado eliminado")
        return success
    
    def find_event_by_google_id(self, google_event_id):
        """Busca un evento por Google ID (simulado)"""
        for event in self.events:
            if event.get('google_event_id') == google_event_id:
                return event
        return None
    
    def add_google_id_to_event(self, firebase_id, google_event_id):
        """Agrega Google ID a un evento (simulado)"""
        for event in self.events:
            if event.get('firebase_id') == firebase_id:
                event['google_event_id'] = google_event_id
                print(f"✅ Google ID agregado al evento simulado")
                return True
        return False
