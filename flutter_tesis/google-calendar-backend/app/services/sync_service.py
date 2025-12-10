from datetime import datetime, timezone
from typing import List, Dict, Any, Tuple
from app.services.calendar_service import GoogleCalendarService
from app.services.mock_firebase import get_firebase_service

class SyncService:
    def __init__(self):
        self.google_service = GoogleCalendarService()
        self.firebase_service = get_firebase_service()
    
    def full_sync(self) -> Dict[str, Any]:
        """
        Sincronización completa bidireccional:
        1. Importa eventos de Google Calendar a Firebase (con verificación)
        2. Exporta eventos de Firebase a Google Calendar (con verificación)
        """
        try:
            print("🔄 Iniciando sincronización completa...")
            
            # Verificar si hay autenticación con Google
            if not self.google_service.has_valid_credentials():
                print("⚠️  No hay credenciales de Google válidas, usando solo Firebase")
                return {
                    'success': True,
                    'message': 'Sin autenticación Google - usando solo Firebase',
                    'events_synced': 0,
                    'errors': []
                }
            
            # Contadores para el reporte
            imported_count = 0
            exported_count = 0
            skipped_count = 0
            errors = []
            
            # 1. Importar desde Google Calendar a Firebase
            print("📥 Importando eventos desde Google Calendar...")
            google_events = self.google_service.list_events()
            
            for google_event in google_events:
                try:
                    result = self._import_google_event_with_verification(google_event)
                    if result == "imported":
                        imported_count += 1
                    elif result == "skipped":
                        skipped_count += 1
                except Exception as e:
                    error_msg = f"Error importando evento '{google_event.get('summary', 'Sin título')}': {str(e)}"
                    errors.append(error_msg)
                    print(f"❌ {error_msg}")
            
            # 2. Exportar desde Firebase a Google Calendar
            print("📤 Exportando eventos desde Firebase...")
            firebase_events = self.firebase_service.get_all_events()
            
            for firebase_event in firebase_events:
                try:
                    # Solo exportar eventos que no tienen google_event_id
                    if not firebase_event.get('google_event_id'):
                        result = self._export_firebase_event_with_verification(firebase_event)
                        if result == "exported":
                            exported_count += 1
                        elif result == "skipped":
                            skipped_count += 1
                except Exception as e:
                    error_msg = f"Error exportando evento '{firebase_event.get('title', 'Sin título')}': {str(e)}"
                    errors.append(error_msg)
                    print(f"❌ {error_msg}")
            
            # Crear mensaje de resultado
            message = f"Sincronización completa: {imported_count} importados, {exported_count} exportados, {skipped_count} omitidos"
            if errors:
                message += f", {len(errors)} errores"
            
            print(f"✅ {message}")
            
            return {
                "success": True,
                "message": message,
                "events_synced": imported_count + exported_count,
                "imported": imported_count,
                "exported": exported_count,
                "skipped": skipped_count,
                "errors": errors
            }
            
        except Exception as e:
            error_msg = f"Error en sincronización completa: {str(e)}"
            print(f"❌ {error_msg}")
            return {
                "success": False,
                "message": error_msg,
                "events_synced": 0,
                "errors": [error_msg]
            }
    
    def _import_google_event_with_verification(self, google_event: Dict[str, Any]) -> str:
        """
        Importa un evento de Google Calendar a Firebase con verificación.
        PRESERVA las modificaciones locales (tipo de evento, descripciones editadas, etc.)
        Retorna: "imported", "skipped", "updated"
        """
        google_event_id = google_event.get('id')
        if not google_event_id:
            return "skipped"
        
        # 1. Verificar si ya existe en Firebase por Google ID
        existing_event = self.firebase_service.find_event_by_google_id(google_event_id)
        if existing_event:
            # CRÍTICO: Si el evento fue modificado localmente, NO sobrescribir
            if existing_event.get('locally_modified', False):
                print(f"🔒 Evento '{google_event.get('summary')}' modificado localmente - PRESERVANDO cambios del usuario")
                return "skipped"
            
            # Evento ya vinculado - verificar si necesita actualización desde Google
            # SOLO actualizar título y fechas, PRESERVAR tipo y modificaciones locales
            should_update = self._should_update_from_google(existing_event, google_event)
            
            if should_update:
                # Actualizar SOLO campos de fecha/hora desde Google, preservar el resto
                update_data = self._get_safe_google_updates(existing_event, google_event)
                if update_data:
                    firebase_id = existing_event.get('firebase_id')
                    self.firebase_service.update_event(firebase_id, update_data)
                    print(f"🔄 Evento '{google_event.get('summary')}' actualizado desde Google (preservando tipo: {existing_event.get('type')})")
                    return "updated"
            else:
                print(f"⏭️  Evento '{google_event.get('summary', 'Sin título')}' ya sincronizado y al día")
                return "skipped"
        
        # 2. Verificar duplicados por título y fecha (evento creado en Flutter sin Google ID)
        duplicate_event = self._find_duplicate_by_title_and_date(google_event)
        
        if duplicate_event:
            # CASO CRÍTICO: Preservar absolutamente TODOS los datos locales
            # Solo vincular con Google ID y marcar como importado
            original_type = duplicate_event.get('type', 'recreativo')
            original_description = duplicate_event.get('description', '')
            firebase_id = duplicate_event.get('firebase_id')
            
            if firebase_id:
                # Agregar Google ID y marcar como importado, mantener TODO lo demás intacto
                update_data = {
                    'google_event_id': google_event_id,
                    'imported': True
                }
                self.firebase_service.update_event(firebase_id, update_data)
                print(f"🔗 Evento '{duplicate_event.get('title')}' vinculado con Google Calendar")
                print(f"   📌 PRESERVADO: tipo='{original_type}', descripción='{original_description[:50]}'")
                return "skipped"
        
        # 3. Evento completamente nuevo desde Google Calendar
        # Intentar detectar el tipo basado en el nombre del evento
        detected_type = self._detect_event_type_from_title(google_event.get('summary', ''))
        
        # Convertir evento preservando el tipo detectado y marcando como importado
        event_data = self.google_service._convert_from_google_format(
            google_event, 
            preserve_type=detected_type,
            preserve_imported=True
        )
        
        # 4. Crear evento en Firebase
        firebase_id = self.firebase_service.create_event(event_data)
        print(f"✅ Evento '{event_data.get('title')}' importado desde Google Calendar (tipo: {detected_type}, imported: True)")
        
        return "imported"
    
    def _export_firebase_event_with_verification(self, firebase_event: Dict[str, Any]) -> str:
        """
        Exporta un evento de Firebase a Google Calendar con verificación.
        Retorna: "exported", "skipped", "error"
        """
        # 1. Verificar que el evento tenga los datos mínimos requeridos
        if not firebase_event.get('title') or not firebase_event.get('date'):
            print(f"⏭️  Evento incompleto omitido: {firebase_event.get('title', 'Sin título')}")
            return "skipped"
        
        # 2. Verificar si ya existe en Google Calendar (por título y fecha)
        if self._check_google_duplicate_by_title_and_date(firebase_event):
            print(f"⏭️  Evento '{firebase_event.get('title')}' ya existe en Google Calendar")
            return "skipped"
        
        try:
            # 3. Crear evento en Google Calendar
            google_event_id = self.google_service.create_event(firebase_event)
            
            if not google_event_id:
                print(f"❌ No se pudo crear evento '{firebase_event.get('title')}' en Google Calendar")
                return "error"
            
            # 4. Actualizar Firebase con el Google ID
            firebase_id = firebase_event.get('firebase_id')
            if firebase_id:
                success = self.firebase_service.add_google_id_to_event(firebase_id, google_event_id)
                if success:
                    print(f"✅ Evento '{firebase_event.get('title')}' exportado a Google Calendar")
                    return "exported"
                else:
                    print(f"⚠️  Evento creado en Google pero no se pudo actualizar Firebase ID: {firebase_id}")
                    return "exported"
            else:
                print(f"⚠️  Evento '{firebase_event.get('title')}' sin firebase_id, creado en Google pero no vinculado")
                return "exported"
                
        except Exception as e:
            print(f"❌ Error exportando evento '{firebase_event.get('title', 'Sin título')}': {str(e)}")
            import traceback
            traceback.print_exc()
            return "error"
    
    def _find_duplicate_by_title_and_date(self, google_event: Dict[str, Any]) -> Dict[str, Any]:
        """
        Busca un evento duplicado en Firebase con el mismo título y fecha.
        Retorna el evento duplicado o None si no se encuentra.
        """
        try:
            firebase_events = self.firebase_service.get_all_events()
            google_title = google_event.get('summary', '').lower()
            
            # Extraer fecha del evento de Google
            start = google_event.get('start', {})
            google_date = start.get('dateTime') or start.get('date')
            
            if not google_title or not google_date:
                return None
            
            # Convertir fecha a datetime para comparación
            google_datetime = datetime.fromisoformat(google_date.replace('Z', '+00:00'))
            
            for existing_event in firebase_events:
                existing_title = existing_event.get('title', '').lower()
                existing_date = existing_event.get('date')
                
                if existing_title == google_title and existing_date:
                    # Comparar fechas (mismo día)
                    if isinstance(existing_date, str):
                        existing_datetime = datetime.fromisoformat(existing_date.replace('Z', '+00:00'))
                    else:
                        existing_datetime = existing_date
                    
                    if (google_datetime.date() == existing_datetime.date()):
                        return existing_event
            
            return None
            
        except Exception as e:
            print(f"Error buscando duplicados: {e}")
            return None

    def _check_duplicate_by_title_and_date(self, event_data: Dict[str, Any]) -> bool:
        """
        Verifica si ya existe un evento en Firebase con el mismo título y fecha
        """
        return self._find_duplicate_by_title_and_date({'summary': event_data.get('title'), 'start': {'dateTime': event_data.get('date')}}) is not None
    
    def _check_google_duplicate_by_title_and_date(self, firebase_event: Dict[str, Any]) -> bool:
        """
        Verifica si ya existe un evento en Google Calendar con el mismo título y fecha
        """
        try:
            google_events = self.google_service.list_events()
            event_title = firebase_event.get('title', '').lower()
            event_date = firebase_event.get('date')
            
            if not event_title or not event_date:
                return False
            
            # Convertir fecha a datetime para comparación
            if isinstance(event_date, str):
                event_datetime = datetime.fromisoformat(event_date.replace('Z', '+00:00'))
            else:
                event_datetime = event_date
            
            for google_event in google_events:
                google_title = google_event.get('summary', '').lower()
                google_start = google_event.get('start', {})
                google_date = google_start.get('dateTime') or google_start.get('date')
                
                if google_title == event_title and google_date:
                    # Comparar fechas (mismo día)
                    google_datetime = datetime.fromisoformat(google_date.replace('Z', '+00:00'))
                    
                    if (event_datetime.date() == google_datetime.date()):
                        return True
            
            return False
            
        except Exception as e:
            print(f"Error verificando duplicados en Google: {e}")
            return False
    
    def _should_update_from_google(self, firebase_event: Dict[str, Any], google_event: Dict[str, Any]) -> bool:
        """
        Determina si un evento en Firebase necesita actualizarse desde Google Calendar.
        SOLO considera cambios en fechas/horarios, NO en tipo o descripción editada.
        """
        try:
            # Extraer fechas de Google Calendar
            google_start = google_event.get('start', {})
            google_end = google_event.get('end', {})
            google_start_date = google_start.get('dateTime') or google_start.get('date')
            google_end_date = google_end.get('dateTime') or google_end.get('date')
            
            # Extraer fechas de Firebase
            firebase_start_date = firebase_event.get('date')
            firebase_end_date = firebase_event.get('end_time')
            
            if not all([google_start_date, google_end_date, firebase_start_date, firebase_end_date]):
                return False
            
            # Convertir a datetime para comparación (asegurando timezone-aware)
            google_start_dt = datetime.fromisoformat(google_start_date.replace('Z', '+00:00'))
            google_end_dt = datetime.fromisoformat(google_end_date.replace('Z', '+00:00'))
            
            if isinstance(firebase_start_date, str):
                firebase_start_dt = datetime.fromisoformat(firebase_start_date.replace('Z', '+00:00'))
                # Si no tiene timezone, añadir UTC
                if firebase_start_dt.tzinfo is None:
                    firebase_start_dt = firebase_start_dt.replace(tzinfo=timezone.utc)
            else:
                firebase_start_dt = firebase_start_date
                if firebase_start_dt.tzinfo is None:
                    firebase_start_dt = firebase_start_dt.replace(tzinfo=timezone.utc)
                
            if isinstance(firebase_end_date, str):
                firebase_end_dt = datetime.fromisoformat(firebase_end_date.replace('Z', '+00:00'))
                if firebase_end_dt.tzinfo is None:
                    firebase_end_dt = firebase_end_dt.replace(tzinfo=timezone.utc)
            else:
                firebase_end_dt = firebase_end_date
                if firebase_end_dt.tzinfo is None:
                    firebase_end_dt = firebase_end_dt.replace(tzinfo=timezone.utc)
            
            # Verificar si las fechas son diferentes (tolerancia de 1 minuto)
            start_diff = abs((google_start_dt - firebase_start_dt).total_seconds())
            end_diff = abs((google_end_dt - firebase_end_dt).total_seconds())
            
            return start_diff > 60 or end_diff > 60  # Más de 1 minuto de diferencia
            
        except Exception as e:
            print(f"Error comparando fechas para actualización: {e}")
            return False
    
    def _get_safe_google_updates(self, firebase_event: Dict[str, Any], google_event: Dict[str, Any]) -> Dict[str, Any]:
        """
        Obtiene SOLO las actualizaciones seguras desde Google Calendar.
        NUNCA incluye tipo de evento, descripción editada, o recordatorios personalizados.
        SOLO fechas y título si cambió en Google.
        """
        try:
            updates = {}
            
            # 1. Actualizar fechas SOLO si son diferentes
            google_start = google_event.get('start', {})
            google_end = google_event.get('end', {})
            google_start_date = google_start.get('dateTime') or google_start.get('date')
            google_end_date = google_end.get('dateTime') or google_end.get('date')
            
            if google_start_date:
                google_start_dt = datetime.fromisoformat(google_start_date.replace('Z', '+00:00'))
                updates['date'] = google_start_dt.isoformat()
            
            if google_end_date:
                google_end_dt = datetime.fromisoformat(google_end_date.replace('Z', '+00:00'))
                updates['end_time'] = google_end_dt.isoformat()
            
            # 2. Actualizar título SOLO si no ha sido editado localmente
            google_title = google_event.get('summary', '')
            firebase_title = firebase_event.get('title', '')
            
            # Si el título es diferente Y no parece haber sido editado manualmente
            if google_title != firebase_title and google_title:
                # Solo actualizar si el título de Firebase parece ser el original importado
                if not self._seems_manually_edited(firebase_title, google_title):
                    updates['title'] = google_title
            
            # 3. NUNCA actualizar estos campos (preservar modificaciones locales):
            # - type (tipo de evento)
            # - description (si fue editada)
            # - reminder (configuración de recordatorios)
            
            print(f"📝 Actualizaciones seguras para '{firebase_event.get('title')}': {list(updates.keys())}")
            return updates if updates else None
            
        except Exception as e:
            print(f"Error preparando actualizaciones seguras: {e}")
            return None
    
    def _seems_manually_edited(self, firebase_title: str, google_title: str) -> bool:
        """
        Determina si un título parece haber sido editado manualmente.
        Esto previene sobrescribir títulos personalizados.
        """
        if not firebase_title or not google_title:
            return False
        
        # Si el título de Firebase es significativamente diferente, probablemente fue editado
        firebase_lower = firebase_title.lower().strip()
        google_lower = google_title.lower().strip()
        
        # Si tienen palabras completamente diferentes, fue editado manualmente
        firebase_words = set(firebase_lower.split())
        google_words = set(google_lower.split())
        
        # Si menos del 70% de las palabras coinciden, probablemente fue editado
        if len(firebase_words & google_words) / max(len(firebase_words), len(google_words), 1) < 0.7:
            return True
        
        return False
    
    def _detect_event_type_from_title(self, title: str) -> str:
        """
        Detecta automáticamente el tipo de evento basado en palabras clave en el título.
        
        Tipos posibles:
        - obligatorio: Clases institucionales, materias académicas, exámenes, asesorías
        - recreativo: Deportes, entretenimiento, pasatiempos, hobbies
        - estudio: Proyectos personales, tesis, investigación, lectura
        - personal: Citas médicas, trámites personales, asuntos familiares
        """
        if not title:
            return 'recreativo'
        
        title_lower = title.lower()
        
        # Palabras clave para OBLIGATORIO (clases institucionales)
        mandatory_keywords = [
            'matemática', 'matemáticas', 'física', 'química', 'programación',
            'inglés', 'historia', 'geografía', 'biología', 'literatura',
            'clase', 'examen', 'evaluación', 'prueba', 'exposición',
            'presentación', 'asesoría', 'tutoría', 'reunión', 'junta',
            'conferencia', 'seminario', 'capacitación'
        ]
        
        # Palabras clave para RECREATIVO
        recreational_keywords = [
            'yoga', 'gimnasio', 'deporte', 'bailar', 'baile', 'correr',
            'ejercicio', 'entrenamiento', 'partido', 'juego', 'película',
            'cine', 'música', 'concierto', 'fiesta', 'salir', 'paseo',
            'hobby', 'videojuego', 'natación', 'fútbol', 'basquet',
            'cumpleaños', 'celebración', 'descanso', 'relajación'
        ]
        
        # Palabras clave para ESTUDIO (proyectos personales de aprendizaje)
        study_keywords = [
            'proyecto', 'desarrollo', 'software', 'código', 'tesis',
            'investigación', 'laboratorio', 'deadline', 'entrega',
            'lectura', 'leer', 'material', 'complementario', 'estudiar',
            'sprint', 'scrum', 'implementación', 'producción'
        ]
        
        # Palabras clave para PERSONAL
        personal_keywords = [
            'médico', 'doctor', 'dentista', 'cita', 'consulta',
            'trámite', 'banco', 'pago', 'factura', 'impuestos',
            'familia', 'papá', 'mamá', 'hermano', 'hijo',
            'compras', 'supermercado', 'reparación', 'mantenimiento'
        ]
        
        # Verificar palabras clave de obligatorio (prioridad alta)
        for keyword in mandatory_keywords:
            if keyword in title_lower:
                return 'obligatorio'
        
        # Verificar palabras clave de estudio
        for keyword in study_keywords:
            if keyword in title_lower:
                return 'estudio'
        
        # Verificar palabras clave personales
        for keyword in personal_keywords:
            if keyword in title_lower:
                return 'personal'
        
        # Verificar palabras clave recreativas
        for keyword in recreational_keywords:
            if keyword in title_lower:
                return 'recreativo'
        
        # Por defecto: recreativo
        return 'recreativo'
    
    def import_from_google_only(self) -> Dict[str, Any]:
        """
        Importa eventos solo desde Google Calendar a Firebase (sin exportar)
        """
        try:
            print("📥 Importando eventos solo desde Google Calendar...")
            
            imported_count = 0
            skipped_count = 0
            errors = []
            
            google_events = self.google_service.list_events()
            
            for google_event in google_events:
                try:
                    result = self._import_google_event_with_verification(google_event)
                    if result == "imported":
                        imported_count += 1
                    elif result == "skipped":
                        skipped_count += 1
                except Exception as e:
                    error_msg = f"Error importando evento '{google_event.get('summary', 'Sin título')}': {str(e)}"
                    errors.append(error_msg)
                    print(f"❌ {error_msg}")
            
            message = f"Importación completa: {imported_count} importados, {skipped_count} omitidos"
            if errors:
                message += f", {len(errors)} errores"
            
            print(f"✅ {message}")
            
            return {
                "success": True,
                "message": message,
                "events_synced": imported_count,
                "imported": imported_count,
                "skipped": skipped_count,
                "errors": errors
            }
            
        except Exception as e:
            error_msg = f"Error en importación: {str(e)}"
            print(f"❌ {error_msg}")
            return {
                "success": False,
                "message": error_msg,
                "events_synced": 0,
                "errors": [error_msg]
            }