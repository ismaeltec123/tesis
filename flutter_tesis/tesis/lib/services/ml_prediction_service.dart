import 'dart:convert';
import 'package:http/http.dart' as http;

class MLPredictionService {
  static const String baseUrl = 'http://localhost:5000';

  /// Verifica si el microservicio ML está disponible
  Future<bool> isServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      print('❌ ML Service no disponible: $e');
      return false;
    }
  }

  /// Entrena el modelo ML con el historial de eventos del usuario
  Future<Map<String, dynamic>> trainModel(String userId, List<Map<String, dynamic>> eventsHistory) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/train'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'events_history': eventsHistory,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error entrenando modelo: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en trainModel: $e');
      rethrow;
    }
  }

  /// Obtiene 3 sugerencias de horarios óptimos para un evento
  Future<List<MLSuggestion>> getPredictionsForEvent({
    required String userId,
    required Map<String, dynamic> incompleteEvent,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'incomplete_event': incompleteEvent,
        }),
      );

      print('📊 ML Response Status: ${response.statusCode}');
      print('📊 ML Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // El ML retorna 'recommendations' no 'suggestions'
        final recommendationsList = data['recommendations'] ?? data['suggestions'];
        
        if (recommendationsList == null) {
          throw Exception('ML retornó null en recommendations/suggestions. Response: ${response.body}');
        }
        
        final suggestions = (recommendationsList as List)
            .map((s) => MLSuggestion.fromJson(s))
            .toList();
        return suggestions;
      } else {
        throw Exception('Error obteniendo predicciones: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getPredictionsForEvent: $e');
      rethrow;
    }
  }

  /// Obtiene 3 sugerencias de horarios óptimos para un evento (MÉTODO ANTIGUO - DEPRECADO)
  Future<List<MLSuggestion>> getPredictions({
    required String userId,
    required String eventTitle,
    required String eventType,
    required int durationHours,
    List<int>? preferredDays, // 0=Lunes, 6=Domingo
    int earliestHour = 8,
    int latestHour = 22,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'event': {
            'title': eventTitle,
            'type': eventType,
            'duration_hours': durationHours,
          },
          'preferences': {
            'preferred_days': preferredDays ?? [0, 1, 2, 3, 4], // Lunes a Viernes por defecto
            'time_range': {
              'earliest_hour': earliestHour,
              'latest_hour': latestHour,
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = (data['suggestions'] as List)
            .map((s) => MLSuggestion.fromJson(s))
            .toList();
        return suggestions;
      } else {
        throw Exception('Error obteniendo predicciones: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getPredictions: $e');
      rethrow;
    }
  }

  /// Verifica el estado del modelo para un usuario
  Future<Map<String, dynamic>> getModelStatus(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status/$userId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error obteniendo estado del modelo');
      }
    } catch (e) {
      print('❌ Error en getModelStatus: $e');
      rethrow;
    }
  }
}

/// Modelo de sugerencia ML
class MLSuggestion {
  final String suggestedDate;
  final int suggestedHour;
  final double confidence;
  final String reason;
  final String? dayName;

  MLSuggestion({
    required this.suggestedDate,
    required this.suggestedHour,
    required this.confidence,
    required this.reason,
    this.dayName,
  });

  factory MLSuggestion.fromJson(Map<String, dynamic> json) {
    return MLSuggestion(
      suggestedDate: json['date'] ?? json['suggested_date'] ?? '',
      suggestedHour: json['hour'] ?? json['suggested_hour'] ?? 9,
      confidence: (json['completion_probability'] ?? json['confidence'] ?? 0.5) as double,
      reason: (json['reasons'] is List) 
          ? (json['reasons'] as List).join('\n') 
          : (json['reason'] ?? 'Sin razón especificada'),
      dayName: json['day_name'],
    );
  }

  /// Obtiene la fecha y hora completa como DateTime
  DateTime getDateTime() {
    final date = DateTime.parse(suggestedDate);
    return DateTime(date.year, date.month, date.day, suggestedHour);
  }

  /// Formatea la confianza como porcentaje
  String getConfidencePercentage() {
    return '${(confidence * 100).toStringAsFixed(1)}%';
  }
}
