import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/event_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import 'calendar_view.dart';
import 'notifications_view.dart';
import 'teacher/teacher_main_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Generar horario del estudiante al iniciar (solo para estudiantes)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
      
      if (authViewModel.isStudent) {
        // Verificar si ya existen eventos del horario
        await eventViewModel.loadEvents();
        
        // Si no hay eventos (primera vez), generar el horario
        if (eventViewModel.events.isEmpty) {
          await eventViewModel.generateStudentSchedule();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (authViewModel.currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authViewModel.currentUser!;
        
        // Si es profesor, mostrar vista de profesor
        if (user.role == 'teacher') {
          return const TeacherMainScreen();
        }

        // Vista de estudiante
        final studentScreens = [
          CalendarView(),
          NotificationsView(),
          const Center(child: Text('Materiales\n(Próximamente)')),
          const Center(child: Text('Notas\n(Próximamente)')),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, ${user.name.split(' ')[0]}'),
                if (user.studentCode != null)
                  Text(
                    'Código: ${user.studentCode}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
              ],
            ),
            actions: [
              // Contador de notificaciones
              Consumer<NotificationViewModel>(
                builder: (context, notificationViewModel, child) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications),
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 1; // Ir a notificaciones
                          });
                        },
                      ),
                      if (notificationViewModel.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${notificationViewModel.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              // Menú de usuario
              PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: const Color(0xFF00BCD4),
                  radius: 16,
                  child: Text(
                    user.name.split(' ').map((e) => e[0]).take(2).join(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      _showProfile();
                      break;
                    case 'logout':
                      _logout();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Mi Perfil'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: studentScreens[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.white,
            elevation: 0,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: 'Calendario',
              ),
              NavigationDestination(
                icon: Consumer<NotificationViewModel>(
                  builder: (context, notificationViewModel, child) {
                    return Stack(
                      children: [
                        const Icon(Icons.notifications_outlined),
                        if (notificationViewModel.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                selectedIcon: const Icon(Icons.notifications),
                label: 'Notificaciones',
              ),
              const NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: 'Materiales',
              ),
              const NavigationDestination(
                icon: Icon(Icons.grade_outlined),
                selectedIcon: Icon(Icons.grade),
                label: 'Notas',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProfile() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.currentUser!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mi Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${user.name}'),
            const SizedBox(height: 8),
            Text('Código: ${user.studentCode}'),
            const SizedBox(height: 8),
            Text('Email: ${user.email}'),
            const SizedBox(height: 8),
            Text('Especialidad: ${user.specialty}'),
            const SizedBox(height: 8),
            Text('Ciclo: ${user.cycle}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
              await authViewModel.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}