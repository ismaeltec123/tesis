import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para gestionar estados de eventos
/// Similar a Google Calendar con opciones: completar, cancelar, confirmar, etc.
class EventStatusService {
  final String baseUrl = 'http://localhost:8001/api';

  /// Cancela un evento con razón opcional
  Future<Map<String, dynamic>> cancelEvent(
    String eventId, {
    String? reason,
  }) async {
    try {
      print('🔵 Cancelando evento con ID: $eventId');
      print('🔵 Razón: $reason');

      final response = await http.put(
        Uri.parse('$baseUrl/calendar/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'cancelado',
          if (reason != null) 'cancellation_reason': reason,
        }),
      );

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error cancelando evento: $e');
      throw Exception('Error cancelando evento: $e');
    }
  }

  /// Confirma asistencia a un evento
  Future<Map<String, dynamic>> confirmEvent(String eventId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/calendar/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'confirmado',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error confirmando evento: $e');
    }
  }

  /// Marca evento como no realizado con contexto para ML
  Future<Map<String, dynamic>> markAsNotDone(
    String eventId, {
    String? reason,
    String? energyLevel,
    String? mood,
    String? stressLevel,
    String? weatherCondition,
    String? location,
    bool? conflictingEvents,
    String? sleepQuality,
    int? importanceRating,
    int? difficultyRating,
    int? timeSinceLastMeal,
    String? additionalNotes,
  }) async {
    try {
      final body = <String, dynamic>{
        'status': 'no_realizado',
      };
      
      if (reason != null) body['reason'] = reason;
      if (energyLevel != null) body['energy_level'] = energyLevel;
      if (mood != null) body['mood'] = mood;
      if (stressLevel != null) body['stress_level'] = stressLevel;
      if (weatherCondition != null) body['weather_condition'] = weatherCondition;
      if (location != null) body['location'] = location;
      if (conflictingEvents != null) body['conflicting_events'] = conflictingEvents;
      if (sleepQuality != null) body['sleep_quality'] = sleepQuality;
      if (importanceRating != null) body['importance_rating'] = importanceRating;
      if (difficultyRating != null) body['difficulty_rating'] = difficultyRating;
      if (timeSinceLastMeal != null) body['time_since_last_meal'] = timeSinceLastMeal;
      if (additionalNotes != null) body['additional_notes'] = additionalNotes;

      final response = await http.put(
        Uri.parse('$baseUrl/calendar/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error marcando como no realizado: $e');
    }
  }

  /// Marca evento como completado
  Future<Map<String, dynamic>> markAsCompleted(String eventId) async {
    try {
      print('🟢 Marcando como completado evento con ID: $eventId');
      
      final response = await http.put(
        Uri.parse('$baseUrl/calendar/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'completado',
          'completed_at': DateTime.now().toIso8601String(),
        }),
      );

      print('🟢 Response status: ${response.statusCode}');
      print('🟢 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error marcando como completado: $e');
      throw Exception('Error marcando como completado: $e');
    }
  }

  /// Marca evento como postergado
  Future<Map<String, dynamic>> postponeEvent(String eventId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/calendar/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'postergado',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error postergando evento: $e');
    }
  }
}
