import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service_unified.dart';
import '../services/schedule_service.dart';
import '../services/notification_service_unified.dart';

class AuthViewModel with ChangeNotifier {
  final AuthServiceUnified _authService = AuthServiceUnified();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  
  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isTeacher => _currentUser?.role == 'teacher';
  bool get isStudent => _currentUser?.role == 'student';
  
  // Constructor
  AuthViewModel() {
    _checkCurrentUser();
  }
  
  // Verificar si hay un usuario actual
  Future<void> _checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentUser = await _authService.getCurrentUserData();
    } catch (e) {
      print('Error verificando usuario actual: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Login como estudiante
  Future<void> loginAsStudent() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentUser = await _authService.loginAsStudent();
      
      if (_currentUser != null) {
        print('✅ Login exitoso como estudiante: ${_currentUser!.name}');
        
        // Generar horario automáticamente para el estudiante
        await _generateStudentSchedule();
      }
    } catch (e) {
      print('❌ Error en login de estudiante: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Login como profesor
  Future<void> loginAsTeacher() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentUser = await _authService.loginAsTeacher();
      
      if (_currentUser != null) {
        print('✅ Login exitoso como profesor: ${_currentUser!.name}');
      }
    } catch (e) {
      print('❌ Error en login de profesor: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Generar horario del estudiante automáticamente
  Future<void> _generateStudentSchedule() async {
    try {
      final scheduleEvents = ScheduleService.generateStudentSchedule();
      print('📅 Generando ${scheduleEvents.length} eventos del horario estudiantil...');
      
      // Agregar notificaciones de ejemplo solo en modo local
      NotificationServiceUnified.addExampleNotifications();
      
      print('✅ Horario del estudiante generado correctamente');
    } catch (e) {
      print('❌ Error generando horario del estudiante: $e');
    }
  }
  
  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.logout();
      _currentUser = null;
      print('👋 Logout exitoso');
    } catch (e) {
      print('❌ Error en logout: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Obtener lista de estudiantes (solo para profesores)
  Future<List<UserModel>> getStudents() async {
    if (!isTeacher) {
      throw Exception('Solo los profesores pueden ver la lista de estudiantes');
    }
    
    try {
      return await _authService.getStudents();
    } catch (e) {
      print('❌ Error obteniendo estudiantes: $e');
      return [];
    }
  }
}