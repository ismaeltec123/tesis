import '../models/user_model.dart';

class AuthService {
  // Usuario actual (simulado para demo)
  static UserModel? _currentUser;
  
  // Usuario actual
  UserModel? get currentUser => _currentUser;

  // Datos del usuario actual
  Future<UserModel?> getCurrentUserData() async {
    return _currentUser;
  }

  // Inicializar usuarios de ejemplo (sin Firebase)
  Future<void> initializeExampleUsers() async {
    // Solo inicializar en memoria para demo
    print('✅ Usuarios de ejemplo inicializados en memoria');
  }

  // Login como profesor (sin Firebase)
  Future<UserModel?> loginAsTeacher() async {
    try {
      await initializeExampleUsers();
      
      _currentUser = UserModel(
        id: 'teacher_ejemplo_001',
        name: 'Profesor Ejemplo',
        email: 'profesor.ejemplo@universidad.edu.pe',
        role: 'teacher',
      );
      
      print('✅ Login exitoso como profesor: ${_currentUser!.name}');
      return _currentUser;
    } catch (e) {
      print('Error en login del profesor: $e');
    }
    return null;
  }

  // Login como estudiante (sin Firebase)
  Future<UserModel?> loginAsStudent() async {
    try {
      await initializeExampleUsers();
      
      _currentUser = UserModel(
        id: 'student_117334',
        name: 'Quispe Arias, Ismael',
        email: 'ismael.quispe@estudiante.universidad.edu.pe',
        role: 'student',
        studentCode: '117334',
        specialty: 'Diseño y Desarrollo de Software',
        cycle: '8vo. Ciclo',
      );
      
      print('✅ Login exitoso como estudiante: ${_currentUser!.name}');
      return _currentUser;
    } catch (e) {
      print('Error en login del estudiante: $e');
    }
    return null;
  }

  // Obtener lista de estudiantes (simulado)
  Future<List<UserModel>> getStudents() async {
    try {
      // Lista simulada de estudiantes
      return [
        UserModel(
          id: 'student_117334',
          name: 'Quispe Arias, Ismael',
          email: 'ismael.quispe@estudiante.universidad.edu.pe',
          role: 'student',
          studentCode: '117334',
          specialty: 'Diseño y Desarrollo de Software',
          cycle: '8vo. Ciclo',
        ),
        UserModel(
          id: 'student_example_002',
          name: 'García López, María',
          email: 'maria.garcia@estudiante.universidad.edu.pe',
          role: 'student',
          studentCode: '118245',
          specialty: 'Diseño y Desarrollo de Software',
          cycle: '7mo. Ciclo',
        ),
        UserModel(
          id: 'student_example_003',
          name: 'Rodríguez Pérez, Carlos',
          email: 'carlos.rodriguez@estudiante.universidad.edu.pe',
          role: 'student',
          studentCode: '119876',
          specialty: 'Diseño y Desarrollo de Software',
          cycle: '8vo. Ciclo',
        ),
      ];
    } catch (e) {
      print('Error obteniendo estudiantes: $e');
      return [];
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    print('👋 Usuario desconectado');
  }
}