import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String baseUrl = 'http://localhost:8001/api/ai';

  // Analizar horario y obtener sugerencias de IA
  Future<Map<String, dynamic>> analyzeSchedule(DateTime targetDate) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze-schedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': targetDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al analizar horario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Confirmar sugerencias seleccionadas
  Future<Map<String, dynamic>> confirmSuggestions(List<Map<String, dynamic>> confirmedSuggestions) async {
    try {
      // Convertir las sugerencias para el backend
      final suggestionsForBackend = confirmedSuggestions.map((suggestion) => {
        'title': suggestion['title'],
        'duration': suggestion['duration'],
        'type': suggestion['type'],
        'suggested_start': suggestion['suggested_start'],
        'suggested_end': suggestion['suggested_end'],
        'category': suggestion['category'],
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/confirm-suggestions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'confirmed_suggestions': suggestionsForBackend,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al confirmar sugerencias: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener actividades de ejercicio disponibles
  Future<List<Map<String, dynamic>>> getExerciseActivities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exercise-activities'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['activities']);
      } else {
        throw Exception('Error al obtener actividades: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener actividades de estudio disponibles
  Future<List<Map<String, dynamic>>> getStudyActivities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/study-activities'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['activities']);
      } else {
        throw Exception('Error al obtener actividades: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener recomendaciones de salud
  Future<Map<String, dynamic>> getHealthRecommendations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health-recommendations'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['recommendations'];
      } else {
        throw Exception('Error al obtener recomendaciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}