import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
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
    // Verificar si ya existen usuarios
    final usersQuery = await _firestore.collection('users').limit(1).get();
    if (usersQuery.docs.isNotEmpty) {
      return; // Ya hay usuarios, no inicializar
    }

    // Crear profesor ejemplo
    final teacherData = UserModel(
      id: 'teacher_ejemplo_001',
      name: 'Profesor Ejemplo',
      email: 'profesor.ejemplo@universidad.edu.pe',
      role: 'teacher',
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

    print('✅ Usuarios de ejemplo creados');
  }

  // Login como profesor (sin autenticación real, solo para demo)
  Future<UserModel?> loginAsTeacher() async {
    try {
      await initializeExampleUsers();
      final doc = await _firestore.collection('users').doc('teacher_ejemplo_001').get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson(doc.data()!);
        return _currentUser;
      }
    } catch (e) {
      print('Error en login del profesor: $e');
    }
    return null;
  }

  // Login como estudiante (sin autenticación real, solo para demo)
  Future<UserModel?> loginAsStudent() async {
    try {
      await initializeExampleUsers();
      final doc = await _firestore.collection('users').doc('student_117334').get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson(doc.data()!);
        return _currentUser;
      }
    } catch (e) {
      print('Error en login del estudiante: $e');
    }
    return null;
  }

  // Obtener lista de estudiantes (para vista de profesor)
  Future<List<UserModel>> getStudents() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error obteniendo estudiantes: $e');
      return [];
    }
  }

  // Logout (para demo)
  Future<void> logout() async {
    _currentUser = null;
    print('👋 Usuario desconectado');
  }
}