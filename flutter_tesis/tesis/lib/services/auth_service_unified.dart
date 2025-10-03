import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/app_config.dart';
import '../services/notification_service_local.dart';

class AuthServiceUnified {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Usuario actual (simulado para demo)
  static UserModel? _currentUser;
  
  // Usuario actual
  UserModel? get currentUser => _currentUser;

  // Datos del usuario actual
  Future<UserModel?> getCurrentUserData() async {
    return _currentUser;
  }

  // Inicializar usuarios de ejemplo
  Future<void> initializeExampleUsers() async {
    if (AppConfig.useLocalMode) {
      // Modo local - solo en memoria
      print('✅ Usuarios de ejemplo inicializados en memoria (modo local)');
      // Agregar notificaciones de ejemplo
      NotificationService.addExampleNotifications();
    } else {
      // Modo Firestore - verificar si ya existen usuarios
      try {
        final usersQuery = await _firestore.collection('users').limit(1).get();
        if (usersQuery.docs.isNotEmpty) {
          print('✅ Usuarios ya existen en Firestore');
          return; // Ya hay usuarios, no inicializar
        }

        // Crear profesor ejemplo
        final teacherData = UserModel(
          id: 'teacher_ejemplo_001',
          name: 'Profesor Ejemplo',
          email: 'profesor.ejemplo@universidad.edu.pe',
          role: 'teacher',
          courses: [
            'Fundamentos de Programación',
            'Programación Orientada a Objetos', 
            'Desarrollo de Aplicaciones Web',
            'Base de Datos',
            'Ingeniería de Requerimientos y Diseño de Software',
            'Desarrollo de Aplicaciones Empresariales Avanzado'
          ],
          sections: ['5C24A', '5C24B', '5C24C'],
        );

        await _firestore.collection('users').doc('teacher_ejemplo_001').set(teacherData.toJson());

        // Crear estudiante ejemplo
        final studentData = UserModel(
          id: 'student_117334',
          name: 'Quispe Arias, Ismael',
          email: 'ismael.quispe@estudiante.universidad.edu.pe',
          role: 'student',
          studentCode: '117334',
          specialty: 'Diseño y Desarrollo de Software',
          cycle: '8vo. Ciclo',
        );

        await _firestore.collection('users').doc('student_117334').set(studentData.toJson());

        print('✅ Usuarios de ejemplo creados en Firestore');
      } catch (e) {
        print('❌ Error inicializando usuarios en Firestore: $e');
        // Fallback a modo local si falla Firestore
        AppConfig.setLocalMode(true);
      }
    }
  }

  // Login como profesor
  Future<UserModel?> loginAsTeacher() async {
    try {
      await initializeExampleUsers();
      
      if (AppConfig.useLocalMode) {
        // Modo local
        _currentUser = UserModel(
          id: 'teacher_ejemplo_001',
          name: 'Profesor Ejemplo',
          email: 'profesor.ejemplo@universidad.edu.pe',
          role: 'teacher',
          courses: [
            'Fundamentos de Programación',
            'Programación Orientada a Objetos', 
            'Desarrollo de Aplicaciones Web',
            'Base de Datos',
            'Ingeniería de Requerimientos y Diseño de Software',
            'Desarrollo de Aplicaciones Empresariales Avanzado'
          ],
          sections: ['5C24A', '5C24B', '5C24C'],
        );
      } else {
        // Modo Firestore
        final doc = await _firestore.collection('users').doc('teacher_ejemplo_001').get();
        if (doc.exists) {
          _currentUser = UserModel.fromJson(doc.data()!);
        } else {
          throw Exception('Usuario profesor no encontrado en Firestore');
        }
      }
      
      if (_currentUser != null) {
        print('✅ Login exitoso como profesor: ${_currentUser!.name} (${AppConfig.useLocalMode ? 'Local' : 'Firestore'})');
      }
      
      return _currentUser;
    } catch (e) {
      print('❌ Error en login del profesor: $e');
      return null;
    }
  }

  // Login como estudiante
  Future<UserModel?> loginAsStudent() async {
    try {
      await initializeExampleUsers();
      
      if (AppConfig.useLocalMode) {
        // Modo local
        _currentUser = UserModel(
          id: 'student_117334',
          name: 'Quispe Arias, Ismael',
          email: 'ismael.quispe@estudiante.universidad.edu.pe',
          role: 'student',
          studentCode: '117334',
          specialty: 'Diseño y Desarrollo de Software',
          cycle: '8vo. Ciclo',
        );
      } else {
        // Modo Firestore
        final doc = await _firestore.collection('users').doc('student_117334').get();
        if (doc.exists) {
          _currentUser = UserModel.fromJson(doc.data()!);
        } else {
          throw Exception('Usuario estudiante no encontrado en Firestore');
        }
      }
      
      if (_currentUser != null) {
        print('✅ Login exitoso como estudiante: ${_currentUser!.name} (${AppConfig.useLocalMode ? 'Local' : 'Firestore'})');
      }
      
      return _currentUser;
    } catch (e) {
      print('❌ Error en login del estudiante: $e');
      return null;
    }
  }

  // Obtener lista de estudiantes
  Future<List<UserModel>> getStudents() async {
    try {
      if (AppConfig.useLocalMode) {
        // Lista simulada de estudiantes (modo local)
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
      } else {
        // Modo Firestore
        final querySnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'student')
            .get();

        return querySnapshot.docs
            .map((doc) => UserModel.fromJson(doc.data()))
            .toList();
      }
    } catch (e) {
      print('❌ Error obteniendo estudiantes: $e');
      return [];
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    print('👋 Usuario desconectado (${AppConfig.useLocalMode ? 'Local' : 'Firestore'})');
  }
}