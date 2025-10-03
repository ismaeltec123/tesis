import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class FirebaseService {
  final _collection = FirebaseFirestore.instance.collection('events');

  Future<List<EventModel>> fetchEvents() async {
    final query = await _collection.get();
    return query.docs.map((doc) => EventModel.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> addEvent(EventModel event) async {
    await _collection.add(event.toMap());
  }

  Future<void> updateEvent(EventModel event) async {
    await _collection.doc(event.id).update(event.toMap());
  }

  Future<void> deleteEvent(String id) async {
    await _collection.doc(id).delete();
  }
}
