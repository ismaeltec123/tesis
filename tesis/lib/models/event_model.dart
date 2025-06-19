import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime endTime;
  final String type;
  final bool reminder; // Nuevo campo

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.endTime,
    required this.type,
    this.reminder = false, // Valor por defecto
  });

  // Actualizar los métodos fromMap y toMap
  factory EventModel.fromMap(String id, Map<String, dynamic> data) {
    return EventModel(
      id: id,
      title: data['title'],
      description: data['description'],
      date: DateTime.parse(data['date']),
      endTime: DateTime.parse(data['endTime']),
      type: data['type'],
      reminder: data['reminder'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type,
      'reminder': reminder,
    };
  }
}
