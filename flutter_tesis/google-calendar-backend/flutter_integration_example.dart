import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

class GoogleCalendarApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  
  // Verificar estado de autenticación
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
      print('Error verificando autenticación: $e');
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
      print('Error obteniendo URL de autorización: $e');
      return null;
    }
  }
  
  // Sincronización completa (importar de Google + sincronizar a Google)
  static Future<Map<String, dynamic>> fullSync() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync/full-sync'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
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
  
  // Crear evento (se sincroniza automáticamente con Google Calendar)
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
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error creando evento: $e');
      return false;
    }
  }
  
  // Actualizar evento
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
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error actualizando evento: $e');
      return false;
    }
  }
  
  // Eliminar evento
  static Future<bool> deleteEvent(String eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/calendar/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error eliminando evento: $e');
      return false;
    }
  }
  
  // Importar eventos solo de Google Calendar
  static Future<Map<String, dynamic>> importFromGoogle() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync/import-from-google'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error importando: ${response.statusCode}');
      }
    } catch (e) {
      print('Error importando de Google: $e');
      return {
        'success': false,
        'message': 'Error importando: $e',
        'events_synced': 0,
        'errors': [e.toString()]
      };
    }
  }
}
