class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final DateTime createdAt;
  final bool isRead;
  final String type; // 'general', 'event', 'reminder'
  
  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.createdAt,
    this.isRead = false,
    required this.type,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      fromUserName: json['fromUserName'] ?? '',
      toUserId: json['toUserId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      type: json['type'] ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'type': type,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? fromUserId,
    String? fromUserName,
    String? toUserId,
    DateTime? createdAt,
    bool? isRead,
    String? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserId: toUserId ?? this.toUserId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}