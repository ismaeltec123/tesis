import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationsView extends StatefulWidget {
  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  void initState() {
    super.initState();
    
    // Cargar notificaciones al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final notificationViewModel = Provider.of<NotificationViewModel>(context, listen: false);
      
      if (authViewModel.currentUser != null) {
        notificationViewModel.loadNotifications(authViewModel.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          Consumer2<AuthViewModel, NotificationViewModel>(
            builder: (context, authViewModel, notificationViewModel, child) {
              if (notificationViewModel.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () {
                    if (authViewModel.currentUser != null) {
                      notificationViewModel.markAllAsRead(authViewModel.currentUser!.id);
                    }
                  },
                  icon: const Icon(Icons.mark_email_read),
                  label: const Text('Marcar todas'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer2<AuthViewModel, NotificationViewModel>(
        builder: (context, authViewModel, notificationViewModel, child) {
          if (notificationViewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (notificationViewModel.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las notificaciones de tus profesores aparecerán aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notificationViewModel.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationViewModel.notifications[index];
              return _buildNotificationCard(notification, notificationViewModel);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationModel notification, 
    NotificationViewModel notificationViewModel
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead 
            ? Colors.grey.shade200 
            : Colors.blue.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead 
                    ? FontWeight.w500 
                    : FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  'De: ${notification.fromUserName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          if (!notification.isRead) {
            notificationViewModel.markAsRead(notification.id);
          }
        },
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
          itemBuilder: (context) => [
            if (!notification.isRead)
              PopupMenuItem(
                value: 'mark_read',
                child: const Row(
                  children: [
                    Icon(Icons.mark_email_read, size: 20),
                    SizedBox(width: 8),
                    Text('Marcar como leída'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'mark_read':
                notificationViewModel.markAsRead(notification.id);
                break;
              case 'delete':
                _showDeleteConfirmation(notification, notificationViewModel);
                break;
            }
          },
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'event':
        return Colors.green;
      case 'reminder':
        return Colors.orange;
      case 'general':
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'reminder':
        return Icons.notifications_active;
      case 'general':
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  void _showDeleteConfirmation(
    NotificationModel notification, 
    NotificationViewModel notificationViewModel
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Notificación'),
        content: const Text('¿Estás seguro que deseas eliminar esta notificación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              notificationViewModel.deleteNotification(notification.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}