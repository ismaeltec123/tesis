// Templates con datos simulados para funcionalidades removibles
import 'teacher_models.dart';
import 'teacher_config.dart';

class StudentListTemplate {
  static List<Student> getMockStudents() {
    if (!TeacherTemplateConfig.USE_MOCK_STUDENTS) return [];
    
    final List<String> firstNames = [
      'Ana', 'Carlos', 'María', 'Diego', 'Lucía', 'Andrés', 'Sofía', 'Miguel',
      'Valentina', 'Santiago', 'Isabella', 'Sebastián', 'Camila', 'Alejandro',
      'Gabriela', 'Daniel', 'Natalia', 'Fernando', 'Paulina', 'Ricardo',
      'Andrea', 'José', 'Laura', 'David', 'Carolina'
    ];
    
    final List<String> lastNames = [
      'García', 'López', 'Martínez', 'González', 'Rodríguez', 'Fernández',
      'Sánchez', 'Ramírez', 'Torres', 'Flores', 'Rivera', 'Gómez',
      'Díaz', 'Morales', 'Jiménez', 'Herrera', 'Medina', 'Castro',
      'Ortega', 'Rubio', 'Marín', 'Iglesias', 'Santos', 'Guerrero', 'Cano'
    ];

    return List.generate(TeacherTemplateConfig.MOCK_STUDENTS_COUNT, (index) {
      final firstName = firstNames[index % firstNames.length];
      final lastName = lastNames[index % lastNames.length];
      final id = (index + 1).toString().padLeft(3, '0');
      
      return Student(
        id: id,
        name: '$firstName $lastName',
        email: '${firstName.toLowerCase()}.${lastName.toLowerCase()}@universidad.edu.co',
        enrollmentDate: DateTime.now().subtract(Duration(days: index * 10 + 30)),
        isActive: index < 23, // 2 estudiantes inactivos para variedad
      );
    });
  }
  
  static Student? getStudentById(String id) {
    final students = getMockStudents();
    try {
      return students.firstWhere((student) => student.id == id);
    } catch (e) {
      return null;
    }
  }
}

class SubjectTemplate {
  static List<Subject> getMockSubjects() {
    if (!TeacherTemplateConfig.USE_MOCK_SCHEDULE) return [];
    
    final subjects = [
      Subject(
        id: 'FUND_PROG',
        name: 'Fundamentos de Programación',
        code: 'C24 1ero F-L',
        description: 'Fundamentos básicos de programación y lógica computacional',
        credits: 4,
        studentIds: StudentListTemplate.getMockStudents().take(22).map((s) => s.id).toList(),
        semester: '2025-2',
      ),
      Subject(
        id: 'PROG_OO',
        name: 'Programación Orientada a Objetos',
        code: 'C24 2do A-L',
        description: 'Conceptos avanzados de programación orientada a objetos',
        credits: 4,
        studentIds: StudentListTemplate.getMockStudents().skip(2).take(24).map((s) => s.id).toList(),
        semester: '2025-2',
      ),
      Subject(
        id: 'DEV_WEB',
        name: 'Desarrollo de Aplicaciones Web',
        code: 'C24 4to C-L',
        description: 'Desarrollo de aplicaciones web modernas con tecnologías actuales',
        credits: 4,
        studentIds: StudentListTemplate.getMockStudents().skip(4).take(20).map((s) => s.id).toList(),
        semester: '2025-2',
      ),
      Subject(
        id: 'BASE_DATOS',
        name: 'Base de Datos',
        code: 'C24 2do A-L',
        description: 'Diseño e implementación de bases de datos relacionales',
        credits: 4,
        studentIds: StudentListTemplate.getMockStudents().skip(6).take(23).map((s) => s.id).toList(),
        semester: '2025-2',
      ),
      Subject(
        id: 'ING_REQ',
        name: 'Ingeniería de Requerimientos y Diseño de Software',
        code: 'C24 2do A-L',
        description: 'Metodologías para el análisis de requerimientos y diseño de software',
        credits: 3,
        studentIds: StudentListTemplate.getMockStudents().skip(8).take(21).map((s) => s.id).toList(),
        semester: '2025-2',
      ),
      Subject(
        id: 'DEV_EMPRESARIAL',
        name: 'Desarrollo de Aplicaciones Empresariales Avanzado',
        code: 'C24 6to A-L',
        description: 'Desarrollo de sistemas empresariales complejos y escalables',
        credits: 4,
        studentIds: StudentListTemplate.getMockStudents().skip(10).take(19).map((s) => s.id).toList(),
        semester: '2025-2',
      ),
    ];

    return subjects.take(TeacherTemplateConfig.MOCK_SUBJECTS_COUNT).toList();
  }
}

class ClassScheduleTemplate {
  static List<ClassSchedule> getMockSchedule() {
    if (!TeacherTemplateConfig.USE_MOCK_SCHEDULE) return [];
    
    final subjects = SubjectTemplate.getMockSubjects();
    final schedules = <ClassSchedule>[];
    
    // Horarios predefinidos
    final timeSlots = [
      {'start': '08:00', 'end': '10:00'},
      {'start': '10:00', 'end': '12:00'},
      {'start': '14:00', 'end': '16:00'},
      {'start': '16:00', 'end': '18:00'},
    ];
    
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    final buildings = ['Edificio A', 'Edificio B', 'Laboratorio'];
    final classrooms = ['101', '102', '201', '202', 'Lab 1', 'Lab 2'];
    
    int scheduleIndex = 0;
    
    for (final subject in subjects) {
      // Cada materia tiene 2 clases por semana
      for (int i = 0; i < 2; i++) {
        final dayIndex = (scheduleIndex + i) % days.length;
        final timeIndex = (scheduleIndex ~/ 2 + i) % timeSlots.length;
        final classroomIndex = (scheduleIndex + i) % classrooms.length;
        
        schedules.add(ClassSchedule(
          id: '${subject.id}_${i + 1}',
          subjectId: subject.id,
          subjectName: subject.name,
          dayOfWeek: days[dayIndex],
          startTime: timeSlots[timeIndex]['start']!,
          endTime: timeSlots[timeIndex]['end']!,
          classroom: classrooms[classroomIndex],
          building: classroomIndex >= 4 ? buildings[2] : buildings[classroomIndex % 2],
        ));
      }
      scheduleIndex++;
    }
    
    return schedules;
  }
  
  static List<ClassSchedule> getScheduleForDay(String dayOfWeek) {
    return getMockSchedule()
        .where((schedule) => schedule.dayOfWeek == dayOfWeek)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  static List<ClassSchedule> getScheduleForSubject(String subjectId) {
    return getMockSchedule()
        .where((schedule) => schedule.subjectId == subjectId)
        .toList();
  }
}

class TeacherNotificationTemplate {
  static List<TeacherNotification> getMockNotifications() {
    return [
      TeacherNotification(
        id: 'not001',
        title: 'Clase Cancelada - Desarrollo de Aplicaciones Web',
        message: 'La clase de hoy ha sido cancelada debido a inconvenientes técnicos. Se reprogramará para el próximo viernes.',
        type: 'warning',
        recipientIds: SubjectTemplate.getMockSubjects().first.studentIds,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isSent: true,
      ),
      TeacherNotification(
        id: 'not002',
        title: 'Recordatorio - Examen Base de Datos',
        message: 'Recuerden que el examen de Base de Datos será el próximo martes. Repasen los temas de normalización y SQL.',
        type: 'info',
        recipientIds: SubjectTemplate.getMockSubjects().skip(1).first.studentIds,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isSent: true,
      ),
      TeacherNotification(
        id: 'not003',
        title: 'Urgente - Cambio de Aula',
        message: 'La clase de Fundamentos de Programación se trasladó al Lab 2. Por favor confirmen recepción.',
        type: 'urgent',
        recipientIds: SubjectTemplate.getMockSubjects().skip(2).first.studentIds,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isSent: false,
      ),
    ];
  }
}