class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' o 'teacher'
  final String? studentCode; // Solo para estudiantes
  final String? specialty; // Especialidad del estudiante
  final String? cycle; // Ciclo del estudiante
  final List<String>? courses; // Cursos que enseña el profesor
  final List<String>? sections; // Secciones que enseña el profesor
  
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentCode,
    this.specialty,
    this.cycle,
    this.courses,
    this.sections,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      studentCode: json['studentCode'],
      specialty: json['specialty'],
      cycle: json['cycle'],
      courses: json['courses'] != null ? List<String>.from(json['courses']) : null,
      sections: json['sections'] != null ? List<String>.from(json['sections']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'studentCode': studentCode,
      'specialty': specialty,
      'cycle': cycle,
      'courses': courses,
      'sections': sections,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? studentCode,
    String? specialty,
    String? cycle,
    List<String>? courses,
    List<String>? sections,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      studentCode: studentCode ?? this.studentCode,
      specialty: specialty ?? this.specialty,
      cycle: cycle ?? this.cycle,
      courses: courses ?? this.courses,
      sections: sections ?? this.sections,
    );
  }
}