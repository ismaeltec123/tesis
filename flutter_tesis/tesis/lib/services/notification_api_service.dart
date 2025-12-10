import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationApiService {
  final String baseUrl;

  NotificationApiService({this.baseUrl = 'http://localhost:8001'});

  /// Send a custom notification email
  Future<bool> sendNotification({
    required String title,
    required String message,
    String notificationType = 'general',
    String? recipient,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'message': message,
          'notification_type': notificationType,
          if (recipient != null) 'recipient': recipient,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  /// Send test notification
  Future<bool> sendTestNotification() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/test'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending test notification: $e');
      return false;
    }
  }

  /// Send schedule imported notification
  Future<bool> notifyScheduleImported({
    required int totalClasses,
    String details = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/schedule-imported?total_classes=$totalClasses&details=${Uri.encodeComponent(details)}'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending schedule notification: $e');
      return false;
    }
  }

  /// Send reminder notification
  Future<bool> sendReminder({
    required String eventTitle,
    required String eventTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/reminder?event_title=${Uri.encodeComponent(eventTitle)}&event_time=${Uri.encodeComponent(eventTime)}'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending reminder: $e');
      return false;
    }
  }

  /// Send sync status notification
  Future<bool> notifySyncStatus({
    required String syncStatus,
    String details = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/sync-status?sync_status=${Uri.encodeComponent(syncStatus)}&details=${Uri.encodeComponent(details)}'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending sync notification: $e');
      return false;
    }
  }
}
