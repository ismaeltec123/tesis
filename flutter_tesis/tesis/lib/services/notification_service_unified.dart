import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../config/app_config.dart';

class NotificationServiceUnified {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Lista local de notificaciones para modo offline
  static List<NotificationModel> _localNotifications = [];

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

      if (AppConfig.useLocalMode) {
        // Modo local
        _localNotifications.add(notification);
        print('✅ Notificación enviada (local): $title');
      } else {
        // Modo Firestore
        await _firestore
            .collection('notifications')
            .doc(notification.id)
            .set(notification.toJson());
        print('✅ Notificación enviada (Firestore): $title');
      }
    } catch (e) {
      print('❌ Error enviando notificación: $e');
      throw e;
    }
  }

  // Obtener notificaciones de un usuario
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      if (AppConfig.useLocalMode) {
        // Modo local
        return _localNotifications
            .where((notification) => notification.toUserId == userId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        // Modo Firestore
        final querySnapshot = await _firestore
            .collection('notifications')
            .where('toUserId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

        return querySnapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data()))
            .toList();
      }
    } catch (e) {
      print('❌ Error obteniendo notificaciones: $e');
      return [];
    }
  }

  // Stream de notificaciones en tiempo real
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    if (AppConfig.useLocalMode) {
      // Modo local - simular stream
      return Stream.periodic(const Duration(seconds: 1), (count) {
        return _localNotifications
            .where((notification) => notification.toUserId == userId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } else {
      // Modo Firestore - stream real
      return _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromJson(doc.data()))
              .toList());
    }
  }

  // Marcar notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      if (AppConfig.useLocalMode) {
        // Modo local
        final index = _localNotifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _localNotifications[index] = _localNotifications[index].copyWith(isRead: true);
        }
      } else {
        // Modo Firestore
        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      }
    } catch (e) {
      print('❌ Error marcando notificación como leída: $e');
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead(String userId) async {
    try {
      if (AppConfig.useLocalMode) {
        // Modo local
        for (int i = 0; i < _localNotifications.length; i++) {
          if (_localNotifications[i].toUserId == userId && !_localNotifications[i].isRead) {
            _localNotifications[i] = _localNotifications[i].copyWith(isRead: true);
          }
        }
      } else {
        // Modo Firestore
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
      }
    } catch (e) {
      print('❌ Error marcando todas las notificaciones como leídas: $e');
    }
  }

  // Contar notificaciones no leídas
  Future<int> getUnreadCount(String userId) async {
    try {
      if (AppConfig.useLocalMode) {
        // Modo local
        return _localNotifications
            .where((notification) => 
                notification.toUserId == userId && !notification.isRead)
            .length;
      } else {
        // Modo Firestore
        final querySnapshot = await _firestore
            .collection('notifications')
            .where('toUserId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();

        return querySnapshot.docs.length;
      }
    } catch (e) {
      print('❌ Error contando notificaciones no leídas: $e');
      return 0;
    }
  }

  // Eliminar notificación
  Future<void> deleteNotification(String notificationId) async {
    try {
      if (AppConfig.useLocalMode) {
        // Modo local
        _localNotifications.removeWhere((notification) => notification.id == notificationId);
      } else {
        // Modo Firestore
        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .delete();
      }
    } catch (e) {
      print('❌ Error eliminando notificación: $e');
    }
  }

  // Agregar notificaciones de ejemplo para demo
  static void addExampleNotifications() {
    final exampleNotifications = [
      NotificationModel(
        id: 'notif_001',
        title: 'Bienvenido al Sistema',
        message: 'Hola Ismael, bienvenido al sistema académico. Aquí podrás ver tu horario, recibir notificaciones y mucho más.',
        fromUserId: 'teacher_ejemplo_001',
        fromUserName: 'Profesor Ejemplo',
        toUserId: 'student_117334',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        type: 'general',
      ),
      NotificationModel(
        id: 'notif_002',
        title: 'Recordatorio de Clase',
        message: 'Te recordamos que mañana tienes clase de C43266 - Sistema de negocios inteligentes con BI a las 08:00 AM.',
        fromUserId: 'teacher_ejemplo_001',
        fromUserName: 'Profesor Ejemplo',
        toUserId: 'student_117334',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'reminder',
      ),
      NotificationModel(
        id: 'notif_003',
        title: 'Nueva Tarea Asignada',
        message: 'Se ha asignado una nueva tarea para el curso C43245 - Gestión de servicio de software. Fecha de entrega: 15 de octubre.',
        fromUserId: 'teacher_ejemplo_001',
        fromUserName: 'Profesor Ejemplo',
        toUserId: 'student_117334',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        type: 'event',
      ),
    ];

    _localNotifications.addAll(exampleNotifications);
    print('📝 Notificaciones de ejemplo agregadas (local)');
  }
}