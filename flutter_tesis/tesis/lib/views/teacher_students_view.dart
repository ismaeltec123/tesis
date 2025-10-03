import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../models/user_model.dart';

class TeacherStudentsView extends StatefulWidget {
  @override
  State<TeacherStudentsView> createState() => _TeacherStudentsViewState();
}

class _TeacherStudentsViewState extends State<TeacherStudentsView> {
  List<UserModel> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => isLoading = true);
    
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      students = await authViewModel.getStudents();
    } catch (e) {
      print('Error cargando estudiantes: $e');
    }
    
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mis Estudiantes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? _buildEmptyState()
              : _buildStudentsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay estudiantes registrados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los estudiantes aparecerán aquí cuando se registren',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(UserModel student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar del estudiante
                CircleAvatar(
                  backgroundColor: const Color(0xFF00BCD4),
                  radius: 24,
                  child: Text(
                    student.name.split(' ').map((e) => e[0]).take(2).join(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Información del estudiante
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${student.studentCode}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón de notificación
                IconButton(
                  onPressed: () => _showSendNotificationDialog(student),
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue,
                  ),
                  tooltip: 'Enviar notificación',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Detalles adicionales
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.email, 'Email', student.email),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.school, 'Especialidad', student.specialty ?? 'No especificada'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.grade, 'Ciclo', student.cycle ?? 'No especificado'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStudentDetails(student),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver Detalles'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSendNotificationDialog(student),
                    icon: const Icon(Icons.notifications),
                    label: const Text('Notificar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  void _showStudentDetails(UserModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${student.studentCode}'),
            const SizedBox(height: 8),
            Text('Email: ${student.email}'),
            const SizedBox(height: 8),
            Text('Especialidad: ${student.specialty ?? "No especificada"}'),
            const SizedBox(height: 8),
            Text('Ciclo: ${student.cycle ?? "No especificado"}'),
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

  void _showSendNotificationDialog(UserModel student) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'general';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Enviar notificación a ${student.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.message),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de notificación',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'event', child: Text('Evento')),
                    DropdownMenuItem(value: 'reminder', child: Text('Recordatorio')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            Consumer2<AuthViewModel, NotificationViewModel>(
              builder: (context, authViewModel, notificationViewModel, child) {
                return ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && 
                        messageController.text.isNotEmpty &&
                        authViewModel.currentUser != null) {
                      
                      try {
                        await notificationViewModel.sendNotification(
                          title: titleController.text,
                          message: messageController.text,
                          fromUser: authViewModel.currentUser!,
                          toUserId: student.id,
                          type: selectedType,
                        );
                        
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Notificación enviada a ${student.name}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error enviando notificación: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enviar'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}