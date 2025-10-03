// Servicio Flutter para comunicación con Enhanced AI (ML + Groq)
import 'dart:convert';
import 'package:http/http.dart' as http;

class EnhancedAIService {
  static const String baseUrl = 'http://localhost:8001/api/enhanced-ai';

  // Inicializar sistema ML+IA
  Future<Map<String, dynamic>> initializeAI() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/initialize'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error inicializando IA: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Análisis completo del calendario con ML + Groq
  Future<Map<String, dynamic>> analyzeCalendar({int daysToAnalyze = 30}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze-calendar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'days_to_analyze': daysToAnalyze,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error analizando calendario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Chat con IA que incluye contexto del calendario
  Future<Map<String, dynamic>> chatWithAI(String message, {bool includeContext = true}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'include_calendar_context': includeContext,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error en chat IA: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Generar evento inteligente con ML + Groq
  Future<Map<String, dynamic>> generateSmartEvent({
    required String title,
    int hour = 10,
    int dayOfWeek = 1,
    int duration = 60,
    String context = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate-event'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'hour': hour,
          'day_of_week': dayOfWeek,
          'duration': duration,
          'context': context,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error generando evento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear plan de estudio inteligente
  Future<Map<String, dynamic>> createStudyPlan({
    required String subject,
    required String examDate,
    bool includeOptimization = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-study-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subject': subject,
          'exam_date': examDate,
          'include_optimization': includeOptimization,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error creando plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Predecir optimizaciones de horario
  Future<Map<String, dynamic>> predictOptimization() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/predict-optimization'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error prediciendo optimización: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener estado del sistema
  Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/system-status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error obteniendo estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear datos de demostración
  Future<Map<String, dynamic>> createDemoData() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/demo-data'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error creando datos demo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Verificar si el servicio Enhanced AI está disponible
  Future<bool> isEnhancedAIAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/system-status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}