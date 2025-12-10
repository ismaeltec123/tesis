"""
Script para limpiar TODOS los eventos de Google Calendar y Firebase
"""
import json
from app.services.calendar_service import GoogleCalendarService

def cleanup_all():
    print("🧹 Limpiando todos los eventos...")
    
    # 1. Limpiar Google Calendar
    try:
        google_cal = GoogleCalendarService()
        if google_cal.has_valid_credentials():
            events = google_cal.get_events()
            print(f"📅 Eventos en Google Calendar: {len(events)}")
            
            for event in events:
                try:
                    google_cal.delete_event(event['id'])
                    print(f"✅ Eliminado: {event.get('summary', 'Sin título')}")
                except Exception as e:
                    print(f"❌ Error eliminando {event['id']}: {e}")
            
            print(f"✅ Google Calendar limpio")
        else:
            print("⚠️  No hay credenciales de Google Calendar")
    except Exception as e:
        print(f"❌ Error limpiando Google Calendar: {e}")
    
    # 2. Limpiar Firebase (temp_events.json)
    try:
        with open('temp_events.json', 'w', encoding='utf-8') as f:
            json.dump({"events": []}, f, indent=2)
        print("✅ Firebase (temp_events.json) limpio")
    except Exception as e:
        print(f"❌ Error limpiando Firebase: {e}")
    
    print("\n✅ Limpieza completada. Ahora puedes importar tu horario de nuevo.")

if __name__ == "__main__":
    cleanup_all()
