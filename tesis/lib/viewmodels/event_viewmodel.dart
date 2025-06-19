import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';

class EventViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<EventModel> _events = [];

  List<EventModel> get events => _events;

  Future<void> loadEvents() async {
    try {
      _events = await _firebaseService.fetchEvents();
      notifyListeners();
    } catch (e) {
      print('Error loading events: $e');
      _events = [];
      notifyListeners();
    }
  }

  Future<void> addEvent(EventModel event) async {
    await _firebaseService.addEvent(event);
    await loadEvents();
  }

  Future<void> updateEvent(EventModel event) async {
    await _firebaseService.updateEvent(event);
    await loadEvents();
  }

  Future<void> deleteEvent(String id) async {
    await _firebaseService.deleteEvent(id);
    await loadEvents();
  }
}
