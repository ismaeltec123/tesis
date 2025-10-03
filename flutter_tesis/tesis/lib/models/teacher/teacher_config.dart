// Configuración de funcionalidades para la vista de profesor
class TeacherFeatureFlags {
  // Templates removibles
  static const bool ENABLE_STUDENT_LIST = true;    // 🎭 Template
  static const bool ENABLE_CLASS_SCHEDULE = true;  // 🎭 Template
  
  // Funcionalidades reales
  static const bool ENABLE_NOTIFICATIONS = true;   // ✅ Real
  static const bool ENABLE_DASHBOARDS = true;      // ✅ Real
  static const bool ENABLE_AI_TEACHER = true;      // ✅ Real
  static const bool ENABLE_REPORTS = true;         // ✅ Real
}

// Configuración de templates
class TeacherTemplateConfig {
  static const bool USE_MOCK_STUDENTS = true;
  static const bool USE_MOCK_SCHEDULE = true;
  static const int MOCK_STUDENTS_COUNT = 25;
  static const int MOCK_SUBJECTS_COUNT = 6;
}