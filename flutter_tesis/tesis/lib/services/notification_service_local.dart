import '../models/notification_model.dart';
import '../models/user_model.dart';

class NotificationService {
  // Lista local de notificaciones (simulado)
  static List<NotificationModel> _notifications = [];

  // Enviar notificación (simulado)
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

      _notifications.add(notification);

      print('✅ Notificación enviada: $title');
    } catch (e) {
      print('❌ Error enviando notificación: $e');
      throw e;
    }
  }

  // Obtener notificaciones de un usuario
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      return _notifications
          .where((notification) => notification.toUserId == userId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('❌ Error obteniendo notificaciones: $e');
      return [];
    }
  }

  // Stream de notificaciones en tiempo real (simulado)
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return Stream.periodic(const Duration(seconds: 1), (count) {
      return _notifications
          .where((notification) => notification.toUserId == userId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // Marcar notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    } catch (e) {
      print('❌ Error marcando notificación como leída: $e');
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead(String userId) async {
    try {
      for (int i = 0; i < _notifications.length; i++) {
        if (_notifications[i].toUserId == userId && !_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
    } catch (e) {
      print('❌ Error marcando todas las notificaciones como leídas: $e');
    }
  }

  // Contar notificaciones no leídas
  Future<int> getUnreadCount(String userId) async {
    try {
      return _notifications
          .where((notification) => 
              notification.toUserId == userId && !notification.isRead)
          .length;
    } catch (e) {
      print('❌ Error contando notificaciones no leídas: $e');
      return 0;
    }
  }

  // Eliminar notificación
  Future<void> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((notification) => notification.id == notificationId);
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

    _notifications.addAll(exampleNotifications);
    print('📝 Notificaciones de ejemplo agregadas');
  }
}