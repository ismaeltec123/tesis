// Modelos para la funcionalidad de profesor

class Student {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final DateTime enrollmentDate;
  final bool isActive;

  Student({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.enrollmentDate,
    this.isActive = true,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      enrollmentDate: DateTime.parse(json['enrollment_date'] ?? DateTime.now().toIso8601String()),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'enrollment_date': enrollmentDate.toIso8601String(),
      'is_active': isActive,
    };
  }
}

class Subject {
  final String id;
  final String name;
  final String code;
  final String? description;
  final int credits;
  final List<String> studentIds;
  final String semester;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.credits,
    required this.studentIds,
    required this.semester,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
      credits: json['credits'] ?? 0,
      studentIds: List<String>.from(json['student_ids'] ?? []),
      semester: json['semester'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'credits': credits,
      'student_ids': studentIds,
      'semester': semester,
    };
  }
}

class ClassSchedule {
  final String id;
  final String subjectId;
  final String subjectName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String classroom;
  final String? building;

  ClassSchedule({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.classroom,
    this.building,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['id'] ?? '',
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject_name'] ?? '',
      dayOfWeek: json['day_of_week'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      classroom: json['classroom'] ?? '',
      building: json['building'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'classroom': classroom,
      'building': building,
    };
  }
}

class TeacherNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'info', 'warning', 'urgent'
  final List<String> recipientIds;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final bool isSent;

  TeacherNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.recipientIds,
    required this.createdAt,
    this.scheduledFor,
    this.isSent = false,
  });

  factory TeacherNotification.fromJson(Map<String, dynamic> json) {
    return TeacherNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      recipientIds: List<String>.from(json['recipient_ids'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      scheduledFor: json['scheduled_for'] != null ? DateTime.parse(json['scheduled_for']) : null,
      isSent: json['is_sent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'recipient_ids': recipientIds,
      'created_at': createdAt.toIso8601String(),
      'scheduled_for': scheduledFor?.toIso8601String(),
      'is_sent': isSent,
    };
  }
}