import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para análisis ML de patrones de eventos
/// Predice cuándo es más probable que el usuario falle y sugiere mejores horarios
class MLPatternService {
  static const String baseUrl = 'http://localhost:8001/api/ml';

  /// Analiza patrones de cancelación y no realización de eventos
  /// 
  /// Retorna estadísticas de falla por:
  /// - Día de la semana
  /// - Hora/franja horaria
  /// - Tipo de evento
  /// - Fin de semana vs día de semana
  static Future<Map<String, dynamic>> analyzePatterns({
    String userId = 'estudiante_demo',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analyze-patterns?user_id=$userId'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {'error': 'No hay datos disponibles'};
      } else {
        return {
          'error': 'Error del servidor: ${response.statusCode}',
          'summary': {'total_events': 0, 'failed_events': 0, 'failure_rate': 0.0}
        };
      }
    } catch (e) {
      print('❌ Error en analyzePatterns: $e');
      return {
        'error': 'No se pudo conectar con el servidor ML. Verifica que esté corriendo en http://localhost:8001',
        'summary': {'total_events': 0, 'failed_events': 0, 'failure_rate': 0.0}
      };
    }
  }

  /// Predice el riesgo de falla de un evento específico
  /// 
  /// Params:
  /// - event: Map con datos del evento (id, title, date, endTime, type, status)
  /// 
  /// Retorna:
  /// - risk_score: 0-100 (probabilidad de falla)
  /// - risk_level: BAJO, MEDIO, ALTO
  /// - reasons: Razones del riesgo
  /// - recommendations: Sugerencias para mejorar
  /// - should_reschedule: bool indicando si debería reprogramarse
  static Future<Map<String, dynamic>> predictEventRisk(
    Map<String, dynamic> event, {
    String userId = 'estudiante_demo',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict-risk?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al predecir riesgo: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en predictEventRisk: $e');
      rethrow;
    }
  }

  /// Sugiere mejores horarios para un evento basado en patrones históricos
  /// 
  /// Params:
  /// - event: Map con datos del evento a reprogramar
  /// 
  /// Retorna:
  /// - Lista de sugerencias con día, hora, tasa de falla y razón
  /// - Cada sugerencia incluye: suggested_start, suggested_end, day, time_slot, 
  ///   failure_rate, reason, confidence
  static Future<Map<String, dynamic>> suggestReschedule(
    Map<String, dynamic> event, {
    String userId = 'estudiante_demo',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/suggest-reschedule?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al sugerir reprogramación: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en suggestReschedule: $e');
      rethrow;
    }
  }

  /// Rellena automáticamente eventos con estados de falla para testing
  /// 
  /// Útil para generar datos de prueba y entrenar el modelo ML.
  /// Marca eventos en horarios/días problemáticos como cancelados o no realizados.
  /// 
  /// Params:
  /// - numEvents: Número de eventos a modificar (1-20)
  /// 
  /// Retorna:
  /// - Lista de eventos modificados con razón
  static Future<Map<String, dynamic>> autoFillTestData({
    String userId = 'estudiante_demo',
    int numEvents = 5,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auto-fill-test-data?user_id=$userId&num_events=$numEvents'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al llenar datos de prueba: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en autoFillTestData: $e');
      rethrow;
    }
  }

  /// Obtiene resumen de los "puntos calientes" de falla
  /// 
  /// Retorna días y horarios más problemáticos de forma simplificada.
  static Future<Map<String, dynamic>> getFailureHotspots({
    String userId = 'estudiante_demo',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-failure-hotspots?user_id=$userId'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {'error': 'No hay datos disponibles'};
      } else {
        return {'error': 'Error del servidor: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Error en getFailureHotspots: $e');
      return {'error': 'No se pudo conectar con el servidor'};
    }
  }

  /// Obtiene estadísticas y capacidades del sistema ML
  static Future<Map<String, dynamic>> getMLStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Error al obtener stats: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getMLStats: $e');
      rethrow;
    }
  }

  /// Formatea el nivel de riesgo para mostrar en UI
  static String formatRiskLevel(String level) {
    switch (level.toUpperCase()) {
      case 'ALTO':
        return '🔴 ALTO';
      case 'MEDIO':
        return '🟡 MEDIO';
      case 'BAJO':
        return '🟢 BAJO';
      default:
        return level;
    }
  }

  /// Obtiene color para el nivel de riesgo
  static String getRiskColor(String level) {
    switch (level.toUpperCase()) {
      case 'ALTO':
        return 'red';
      case 'MEDIO':
        return 'orange';
      case 'BAJO':
        return 'green';
      default:
        return 'grey';
    }
  }
}
