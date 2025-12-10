import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

class GoogleCalendarApiService {
  static const String baseUrl = 'http://localhost:8001/api';
  
  // Verificar estado de autenticación con Google Calendar
  static Future<bool> isAuthenticated() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/status'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['authenticated'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error verificando autenticación Google: $e');
      return false;
    }
  }
  
  // Obtener URL de autorización de Google
  static Future<String?> getGoogleAuthUrl() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['auth_url'];
      }
      return null;
    } catch (e) {
      print('Error obteniendo URL de autorización Google: $e');
      return null;
    }
  }
  
  // Autenticación automática con Google (abre navegador automáticamente)
  static Future<bool> authenticateGoogleAuto() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google/auto'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🌐 ${data['message']}');
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error en autenticación automática Google: $e');
      return false;
    }
  }
  
  // Eliminar token de Google (desconectar)
  static Future<bool> removeGoogleToken() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/google-token'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        print('🗑️ Token de Google eliminado');
        return true;
      }
      return false;
    } catch (e) {
      print('Error eliminando token de Google: $e');
      return false;
    }
  }
  
  // Sincronización completa bidireccional
  static Future<Map<String, dynamic>> fullSync() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync/full-sync'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔄 Sincronización completa: ${result['message']}');
        return result;
      } else {
        throw Exception('Error en sincronización: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en sincronización completa: $e');
      return {
        'success': false,
        'message': 'Error en sincronización: $e',
        'events_synced': 0,
        'errors': [e.toString()]
      };
    }
  }
  
  // Obtener todos los eventos desde el backend
  static Future<List<EventModel>> getAllEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/calendar/events'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('📱 Backend response: ${data.length} eventos recibidos');
        final events = data.map((eventJson) {
          print('📅 Procesando evento: ${eventJson['title']} - ${eventJson['date']}');
          return EventModel.fromMap(
            eventJson['id'] ?? '', 
            eventJson
          );
        }).toList();
        print('✅ Eventos parseados exitosamente: ${events.length}');
        return events;
      }
      return [];
    } catch (e) {
      print('Error obteniendo eventos del backend: $e');
      return [];
    }
  }
  
  // Crear evento en ambas plataformas (Firebase + Google Calendar)
  static Future<bool> createEvent(EventModel event) async {
    try {
      final eventData = {
        'title': event.title,
        'description': event.description,
        'date': event.date.toIso8601String(),
        'end_time': event.endTime.toIso8601String(),
        'type': event.type,
        'reminder': event.reminder,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/calendar/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(eventData),
      );
      
      if (response.statusCode == 200) {
        print('✅ Evento creado y sincronizado con Google Calendar');
        return true;
      } else {
        print('❌ Error creando evento: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error creando evento en API: $e');
      return false;
    }
  }
  
  // Actualizar evento en ambas plataformas
  static Future<bool> updateEvent(String eventId, EventModel event) async {
    try {
      final eventData = {
        'title': event.title,
        'description': event.description,
        'date': event.date.toIso8601String(),
        'end_time': event.endTime.toIso8601String(),
        'type': event.type,
        'reminder': event.reminder,
      };
      
      final response = await http.put(
        Uri.parse('$baseUrl/calendar/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(eventData),
      );
      
      if (response.statusCode == 200) {
        print('✅ Evento actualizado en ambas plataformas');
        return true;
      } else {
        print('❌ Error actualizando evento: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error actualizando evento en API: $e');
      return false;
    }
  }
  
  // Eliminar evento de ambas plataformas
  static Future<bool> deleteEvent(String eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/calendar/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        print('✅ Evento eliminado de ambas plataformas');
        return true;
      } else {
        print('❌ Error eliminando evento: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error eliminando evento en API: $e');
      return false;
    }
  }
  
  // Importar solo desde Google Calendar
  static Future<Map<String, dynamic>> importFromGoogle() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync/import-from-google'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('📥 Importación de Google: ${result['message']}');
        return result;
      } else {
        throw Exception('Error importando: ${response.statusCode}');
      }
    } catch (e) {
      print('Error importando de Google Calendar: $e');
      return {
        'success': false,
        'message': 'Error importando: $e',
        'events_synced': 0,
        'errors': [e.toString()]
      };
    }
  }
  
  // Verificar si el servidor backend está funcionando
  static Future<bool> isServerRunning() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8001/health'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Servidor backend no está ejecutándose: $e');
      return false;
    }
  }
}
