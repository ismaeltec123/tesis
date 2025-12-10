import 'package:flutter/material.dart';
import '../../models/teacher/teacher_templates.dart';
import '../../models/teacher/teacher_config.dart';
import '../../models/teacher/teacher_models.dart';
import '../../widgets/send_notification_dialog.dart';

class TeacherNotificationsView extends StatefulWidget {
  const TeacherNotificationsView({super.key});

  @override
  State<TeacherNotificationsView> createState() => _TeacherNotificationsViewState();
}

class _TeacherNotificationsViewState extends State<TeacherNotificationsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TeacherNotification> _notifications = [];
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedType = 'info';
  String _selectedSubject = '';
  String _selectedSection = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = TeacherNotificationTemplate.getMockNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: Colors.orange[700],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.orange[700],
              tabs: const [
                Tab(text: 'Historial', icon: Icon(Icons.history)),
                Tab(text: 'Nuevo Aviso', icon: Icon(Icons.add_alert)),
              ],
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryTab(),
                  _buildCreateNotificationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEmailNotificationDialog,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.email),
        label: const Text('Email Directo'),
        tooltip: 'Enviar email a ismael.quispe@tecsup.edu.pe',
      ),
    );
  }

  void _openEmailNotificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SendNotificationDialog(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[700]!, Colors.orange[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Centro de Avisos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Comunicación con estudiantes',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_notifications.length} avisos',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (!TeacherFeatureFlags.ENABLE_NOTIFICATIONS) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Funcionalidad deshabilitada'),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay avisos enviados'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(TeacherNotification notification) {
    Color typeColor;
    IconData typeIcon;
    
    switch (notification.type) {
      case 'urgent':
        typeColor = Colors.red;
        typeIcon = Icons.priority_high;
        break;
      case 'warning':
        typeColor = Colors.orange;
        typeIcon = Icons.warning;
        break;
      default:
        typeColor = Colors.blue;
        typeIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: typeColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(typeIcon, color: typeColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              notification.message,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Footer
            Row(
              children: [
                Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${notification.recipientIds.length} destinatarios',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(
                  notification.isSent ? Icons.check_circle : Icons.schedule,
                  size: 16,
                  color: notification.isSent ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  notification.isSent ? 'Enviado' : 'Programado',
                  style: TextStyle(
                    fontSize: 12,
                    color: notification.isSent ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDate(notification.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateNotificationTab() {
    if (!TeacherFeatureFlags.ENABLE_NOTIFICATIONS) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Funcionalidad deshabilitada'),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crear Nuevo Aviso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Type selector
                  const Text('Tipo de aviso:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTypeChip('Información', 'info', Colors.blue, Icons.info),
                      _buildTypeChip('Advertencia', 'warning', Colors.orange, Icons.warning),
                      _buildTypeChip('Urgente', 'urgent', Colors.red, Icons.priority_high),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Secciones del profesor
                  const Text('Sección:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSection.isEmpty ? null : _selectedSection,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Seleccionar sección...',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'all_sections',
                        child: Text('Todas las secciones'),
                      ),
                      const DropdownMenuItem(
                        value: '5C24A',
                        child: Text('5C24A (22 estudiantes)'),
                      ),
                      const DropdownMenuItem(
                        value: '5C24B',
                        child: Text('5C24B (24 estudiantes)'),
                      ),
                      const DropdownMenuItem(
                        value: '5C24C',
                        child: Text('5C24C (20 estudiantes)'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSection = value ?? '';
                      });
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Cursos del profesor
                  const Text('Curso:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSubject.isEmpty ? null : _selectedSubject,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Seleccionar curso...',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'all_courses',
                        child: Text('Todos los cursos'),
                      ),
                      const DropdownMenuItem(
                        value: 'fund_prog',
                        child: Text('Fundamentos de Programación'),
                      ),
                      const DropdownMenuItem(
                        value: 'prog_oo',
                        child: Text('Programación Orientada a Objetos'),
                      ),
                      const DropdownMenuItem(
                        value: 'dev_web',
                        child: Text('Desarrollo de Aplicaciones Web'),
                      ),
                      const DropdownMenuItem(
                        value: 'base_datos',
                        child: Text('Base de Datos'),
                      ),
                      const DropdownMenuItem(
                        value: 'ing_req',
                        child: Text('Ingeniería de Requerimientos y Diseño de Software'),
                      ),
                      const DropdownMenuItem(
                        value: 'dev_empresarial',
                        child: Text('Desarrollo de Aplicaciones Empresariales Avanzado'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value ?? '';
                      });
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Title
                  const Text('Título:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ej: Clase cancelada, Recordatorio de examen...',
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Message
                  const Text('Mensaje:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Escriba el mensaje aquí...',
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _canSendNotification() ? _sendNotification : null,
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar Aviso'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Quick templates
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plantillas Rápidas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTemplateChip('Clase cancelada', 'warning'),
                      _buildTemplateChip('Recordatorio examen', 'info'),
                      _buildTemplateChip('Cambio de aula', 'urgent'),
                      _buildTemplateChip('Material disponible', 'info'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, Color color, IconData icon) {
    final isSelected = _selectedType == value;
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        child: FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
          onSelected: (selected) {
            setState(() {
              _selectedType = value;
            });
          },
          backgroundColor: Colors.grey[100],
          selectedColor: color.withOpacity(0.2),
          checkmarkColor: color,
        ),
      ),
    );
  }

  Widget _buildTemplateChip(String template, String type) {
    return ActionChip(
      label: Text(template),
      onPressed: () => _applyTemplate(template, type),
      backgroundColor: Colors.grey[100],
    );
  }

  void _applyTemplate(String template, String type) {
    setState(() {
      _selectedType = type;
      _titleController.text = template;
      
      switch (template) {
        case 'Clase cancelada':
          _messageController.text = 'La clase de hoy ha sido cancelada. Se informará nueva fecha oportunamente.';
          break;
        case 'Recordatorio examen':
          _messageController.text = 'Recordatorio: El examen está programado para la próxima semana. Revisen el material de estudio.';
          break;
        case 'Cambio de aula':
          _messageController.text = 'Atención: La clase se ha trasladado a otra aula. Revisar información actualizada.';
          break;
        case 'Material disponible':
          _messageController.text = 'Nuevo material de estudio disponible. Pueden descargarlo desde la plataforma.';
          break;
      }
    });
  }

  bool _canSendNotification() {
    return _titleController.text.isNotEmpty &&
           _messageController.text.isNotEmpty &&
           _selectedSection.isNotEmpty &&
           _selectedSubject.isNotEmpty;
  }

  void _sendNotification() {
    if (!_canSendNotification()) return;
    
    // Simulate sending notification
    final newNotification = TeacherNotification(
      id: 'not_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text,
      message: _messageController.text,
      type: _selectedType,
      recipientIds: _getRecipientIds(),
      createdAt: DateTime.now(),
      isSent: true,
    );
    
    setState(() {
      _notifications.insert(0, newNotification);
      _titleController.clear();
      _messageController.clear();
      _selectedSubject = '';
      _selectedSection = '';
      _selectedType = 'info';
    });
    
    // Switch to history tab
    _tabController.animateTo(0);
    
    String sectionText = _selectedSection == 'all_sections' ? 'todas las secciones' : _selectedSection;
    String courseText = _selectedSubject == 'all_courses' ? 'todos los cursos' : _getCourseDisplayName(_selectedSubject);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Aviso enviado a ${newNotification.recipientIds.length} estudiantes de $sectionText - $courseText'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<String> _getRecipientIds() {
    // Simulación de estudiantes por sección
    Map<String, List<String>> studentsBySection = {
      '5C24A': List.generate(22, (i) => 'student_${5240 + i}'),
      '5C24B': List.generate(24, (i) => 'student_${5264 + i}'),
      '5C24C': List.generate(20, (i) => 'student_${5288 + i}'),
    };

    if (_selectedSection == 'all_sections') {
      // Todos los estudiantes de todas las secciones
      return studentsBySection.values.expand((list) => list).toList();
    } else if (studentsBySection.containsKey(_selectedSection)) {
      // Estudiantes de la sección específica
      return studentsBySection[_selectedSection] ?? [];
    }
    
    return [];
  }

  String _getCourseDisplayName(String courseId) {
    Map<String, String> courseNames = {
      'fund_prog': 'Fundamentos de Programación',
      'prog_oo': 'Programación Orientada a Objetos',
      'dev_web': 'Desarrollo de Aplicaciones Web',
      'base_datos': 'Base de Datos',
      'ing_req': 'Ingeniería de Requerimientos y Diseño de Software',
      'dev_empresarial': 'Desarrollo de Aplicaciones Empresariales Avanzado',
      'all_courses': 'todos los cursos',
    };
    return courseNames[courseId] ?? courseId;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d atrás';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h atrás';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m atrás';
    } else {
      return 'Ahora';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}