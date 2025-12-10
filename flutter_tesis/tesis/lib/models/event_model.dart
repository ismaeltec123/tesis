// Removed unused imports

// Enum para estados de eventos (sincronizado con backend)
enum EventStatus {
  pendiente,
  confirmado,
  completado,
  noRealizado,
  cancelado,
  postergado
}

// Extension para convertir enum a string y viceversa
extension EventStatusExtension on EventStatus {
  String get value {
    switch (this) {
      case EventStatus.pendiente:
        return 'pendiente';
      case EventStatus.confirmado:
        return 'confirmado';
      case EventStatus.completado:
        return 'completado';
      case EventStatus.noRealizado:
        return 'no_realizado';
      case EventStatus.cancelado:
        return 'cancelado';
      case EventStatus.postergado:
        return 'postergado';
    }
  }

  static EventStatus fromString(String status) {
    switch (status) {
      case 'confirmado':
        return EventStatus.confirmado;
      case 'completado':
        return EventStatus.completado;
      case 'no_realizado':
        return EventStatus.noRealizado;
      case 'cancelado':
        return EventStatus.cancelado;
      case 'postergado':
        return EventStatus.postergado;
      default:
        return EventStatus.pendiente;
    }
  }
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime endTime;
  final String type;
  final String? category; // 🆕 Categoría para ML (estudio, ejercicio, etc.)
  final String? location; // 🆕 Ubicación del evento
  final bool reminder;
  final EventStatus status; // 🆕 Estado del evento
  final DateTime? completedAt; // 🆕 Cuándo se completó
  final int? postponedCount; // 🆕 Veces que se ha postergado
  final DateTime? originalDate; // 🆕 Fecha original antes de reprogramar
  final List<Map<String, dynamic>>? statusHistory; // 🆕 Historial de cambios

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.endTime,
    required this.type,
    this.category,
    this.location,
    this.reminder = false,
    this.status = EventStatus.pendiente, // 🆕 Valor por defecto
    this.completedAt,
    this.postponedCount = 0,
    this.originalDate,
    this.statusHistory,
  });

  // Actualizar los métodos fromMap y toMap
  factory EventModel.fromMap(String id, Map<String, dynamic> data) {
    return EventModel(
      id: id,
      title: data['title'],
      description: data['description'],
      date: DateTime.parse(data['date']),
      endTime: DateTime.parse(data['end_time'] ?? data['endTime']),
      type: data['type'],
      category: data['category'],
      location: data['location'],
      reminder: data['reminder'] ?? false,
      status: EventStatusExtension.fromString(data['status'] ?? 'pendiente'),
      completedAt: data['completed_at'] != null ? DateTime.parse(data['completed_at']) : null,
      postponedCount: data['postponed_count'] ?? 0,
      originalDate: data['original_date'] != null ? DateTime.parse(data['original_date']) : null,
      statusHistory: data['status_history'] != null 
          ? List<Map<String, dynamic>>.from(data['status_history'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'type': type,
      'category': category,
      'location': location,
      'reminder': reminder,
      'status': status.value,
      'completed_at': completedAt?.toIso8601String(),
      'postponed_count': postponedCount,
      'original_date': originalDate?.toIso8601String(),
      'status_history': statusHistory,
    };
  }

  // 🆕 Método para copiar con cambios
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? endTime,
    String? type,
    String? category,
    String? location,
    bool? reminder,
    EventStatus? status,
    DateTime? completedAt,
    int? postponedCount,
    DateTime? originalDate,
    List<Map<String, dynamic>>? statusHistory,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      category: category ?? this.category,
      location: location ?? this.location,
      reminder: reminder ?? this.reminder,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      postponedCount: postponedCount ?? this.postponedCount,
      originalDate: originalDate ?? this.originalDate,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }
}
