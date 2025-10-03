import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/notification_service_unified.dart';

class NotificationViewModel with ChangeNotifier {
  final NotificationServiceUnified _notificationService = NotificationServiceUnified();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  
  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  
  // Cargar notificaciones de un usuario
  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _notifications = await _notificationService.getUserNotifications(userId);
      _unreadCount = await _notificationService.getUnreadCount(userId);
    } catch (e) {
      print('❌ Error cargando notificaciones: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Enviar notificación
  Future<void> sendNotification({
    required String title,
    required String message,
    required UserModel fromUser,
    required String toUserId,
    String type = 'general',
  }) async {
    try {
      await _notificationService.sendNotification(
        title: title,
        message: message,
        fromUser: fromUser,
        toUserId: toUserId,
        type: type,
      );
      
      print('✅ Notificación enviada exitosamente');
    } catch (e) {
      print('❌ Error enviando notificación: $e');
      throw e;
    }
  }
  
  // Marcar notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      // Actualizar localmente
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error marcando notificación como leída: $e');
    }
  }
  
  // Marcar todas como leídas
  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);
      
      // Actualizar localmente
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('❌ Error marcando todas las notificaciones como leídas: $e');
    }
  }
  
  // Eliminar notificación
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      // Actualizar localmente
      _notifications.removeWhere((n) => n.id == notificationId);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (e) {
      print('❌ Error eliminando notificación: $e');
    }
  }
  
  // Stream de notificaciones en tiempo real
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _notificationService.getUserNotificationsStream(userId);
  }
  
  // Limpiar notificaciones (al hacer logout)
  void clearNotifications() {
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }
}