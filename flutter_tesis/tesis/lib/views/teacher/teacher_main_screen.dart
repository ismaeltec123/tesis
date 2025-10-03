import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../calendar_view.dart';
import '../teacher_students_view.dart';
import 'teacher_dashboard_view.dart';
import 'teacher_schedule_view.dart';
import 'teacher_notifications_view.dart';
import '../../models/teacher/teacher_config.dart';

class TeacherMainScreen extends StatefulWidget {
  const TeacherMainScreen({super.key});

  @override
  State<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  int _selectedIndex = 0;

  // Lista de pantallas con configuración condicional
  List<Widget> get _screens {
    final screens = <Widget>[
      CalendarView(), // Calendario (heredado de estudiante)
      const TeacherDashboardView(), // Dashboard de profesor
    ];

    // Agregar funcionalidades opcionales basadas en feature flags
    if (TeacherFeatureFlags.ENABLE_STUDENT_LIST) {
      screens.add(TeacherStudentsView());
    }

    if (TeacherFeatureFlags.ENABLE_CLASS_SCHEDULE) {
      screens.add(const TeacherScheduleView());
    }

    if (TeacherFeatureFlags.ENABLE_NOTIFICATIONS) {
      screens.add(const TeacherNotificationsView());
    }

    return screens;
  }

  // Lista de destinos de navegación con configuración condicional
  List<NavigationDestination> get _destinations {
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.calendar_today_outlined),
        selectedIcon: Icon(Icons.calendar_today),
        label: 'Calendario',
      ),
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
    ];

    // Agregar destinos opcionales
    if (TeacherFeatureFlags.ENABLE_STUDENT_LIST) {
      destinations.add(
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Estudiantes${TeacherTemplateConfig.USE_MOCK_STUDENTS ? ' 🎭' : ''}',
        ),
      );
    }

    if (TeacherFeatureFlags.ENABLE_CLASS_SCHEDULE) {
      destinations.add(
        NavigationDestination(
          icon: Icon(Icons.schedule_outlined),
          selectedIcon: Icon(Icons.schedule),
          label: 'Horarios${TeacherTemplateConfig.USE_MOCK_SCHEDULE ? ' 🎭' : ''}',
        ),
      );
    }

    if (TeacherFeatureFlags.ENABLE_NOTIFICATIONS) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: 'Avisos',
        ),
      );
    }

    return destinations;
  }

  @override
  Widget build(BuildContext context) {
    final currentScreens = _screens;
    final currentDestinations = _destinations;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.school,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            const Text(
              'Vista Profesor',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // Indicador de modo template
            if (TeacherTemplateConfig.USE_MOCK_STUDENTS || 
                TeacherTemplateConfig.USE_MOCK_SCHEDULE)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: Colors.orange[800],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Modo Demo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  _showSettings();
                  break;
                case 'switch_student':
                  _switchToStudentView();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Configuración'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'switch_student',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Vista Estudiante'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: currentScreens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 0,
        destinations: currentDestinations,
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.blue),
            SizedBox(width: 8),
            Text('Configuración de Profesor'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Funcionalidades Activas:'),
            const SizedBox(height: 12),
            _buildFeatureStatus('Dashboard Docente', TeacherFeatureFlags.ENABLE_DASHBOARDS),
            _buildFeatureStatus('Lista Estudiantes', TeacherFeatureFlags.ENABLE_STUDENT_LIST, isTemplate: TeacherTemplateConfig.USE_MOCK_STUDENTS),
            _buildFeatureStatus('Horarios de Clase', TeacherFeatureFlags.ENABLE_CLASS_SCHEDULE, isTemplate: TeacherTemplateConfig.USE_MOCK_SCHEDULE),
            _buildFeatureStatus('Sistema de Avisos', TeacherFeatureFlags.ENABLE_NOTIFICATIONS),
            _buildFeatureStatus('IA Docente', TeacherFeatureFlags.ENABLE_AI_TEACHER),
            _buildFeatureStatus('Reportes', TeacherFeatureFlags.ENABLE_REPORTS),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureStatus(String feature, bool isEnabled, {bool isTemplate = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.cancel,
            color: isEnabled ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (isTemplate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🎭 Demo',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange[800],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _switchToStudentView() {
    // Cambiar a vista de estudiante mediante logout y relogin
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar a Vista Estudiante'),
        content: const Text('¿Deseas cambiar a la vista de estudiante?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authViewModel.logout();
              await authViewModel.loginAsStudent();
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }
}