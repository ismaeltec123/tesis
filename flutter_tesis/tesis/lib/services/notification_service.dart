import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Enviar notificación
  Future<void> sendNotification({
    required String title,
    required String message,
    required UserModel fromUser,
    required String toUserId,
    String type = 'general',
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        fromUserId: fromUser.id,
        fromUserName: fromUser.name,
        toUserId: toUserId,
        createdAt: DateTime.now(),
        type: type,
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toJson());

      print('✅ Notificación enviada: $title');
    } catch (e) {
      print('❌ Error enviando notificación: $e');
      throw e;
    }
  }

  // Obtener notificaciones de un usuario
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo notificaciones: $e');
      return [];
    }
  }

  // Stream de notificaciones en tiempo real
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data()))
            .toList());
  }

  // Marcar notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marcando notificación como leída: $e');
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('❌ Error marcando todas las notificaciones como leídas: $e');
    }
  }

  // Contar notificaciones no leídas
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('❌ Error contando notificaciones no leídas: $e');
      return 0;
    }
  }

  // Eliminar notificación
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('❌ Error eliminando notificación: $e');
    }
  }
}