import 'package:flutter/material.dart';
import '../../widgets/enhanced_ai_dialog.dart';
import '../../widgets/teacher/teacher_dashboard_widgets.dart';
import '../../models/teacher/teacher_config.dart';

class TeacherDashboardView extends StatefulWidget {
  const TeacherDashboardView({super.key});

  @override
  State<TeacherDashboardView> createState() => _TeacherDashboardViewState();
}

class _TeacherDashboardViewState extends State<TeacherDashboardView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Métricas principales
              const TeacherMetricsCards(),
              const SizedBox(height: 24),

              // Gráficos de productividad docente
              const TeacherProductivityCharts(),
              const SizedBox(height: 24),

              // Resumen de actividades
              const TeacherActivitySummary(),
              const SizedBox(height: 24),

              // Accesos rápidos
              _buildQuickActions(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEnhancedAI,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.psychology),
        label: const Text('IA Docente'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(
              Icons.school,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenido, Profesor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dashboard Académico - ${_getCurrentSemester()}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                if (TeacherTemplateConfig.USE_MOCK_STUDENTS || 
                    TeacherTemplateConfig.USE_MOCK_SCHEDULE) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 14,
                          color: Colors.orange[800],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Datos de demostración',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildQuickActionCard(
              'Nueva Clase',
              Icons.add_circle_outline,
              Colors.green,
              () => _createNewClass(),
            ),
            _buildQuickActionCard(
              'Enviar Aviso',
              Icons.notification_add_outlined,
              Colors.orange,
              () => _sendNotification(),
              enabled: TeacherFeatureFlags.ENABLE_NOTIFICATIONS,
            ),
            _buildQuickActionCard(
              'Ver Estudiantes',
              Icons.people_outline,
              Colors.blue,
              () => _viewStudents(),
              enabled: TeacherFeatureFlags.ENABLE_STUDENT_LIST,
            ),
            _buildQuickActionCard(
              'Generar Reporte',
              Icons.assessment_outlined,
              Colors.purple,
              () => _generateReport(),
              enabled: TeacherFeatureFlags.ENABLE_REPORTS,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return Card(
      elevation: enabled ? 2 : 1,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: enabled ? null : Colors.grey[100],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled ? color : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: enabled ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
              if (!enabled)
                Icon(
                  Icons.lock_outline,
                  color: Colors.grey[400],
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentSemester() {
    final now = DateTime.now();
    final year = now.year;
    final semester = now.month <= 6 ? 1 : 2;
    return '$year-$semester';
  }

  void _openEnhancedAI() {
    showDialog(
      context: context,
      builder: (context) => EnhancedAIDialog(
        onEventsCreated: () {
          // Refresh dashboard if needed
          setState(() {});
        },
      ),
    );
  }

  void _createNewClass() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _sendNotification() {
    if (!TeacherFeatureFlags.ENABLE_NOTIFICATIONS) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ir a la pestaña de Avisos para enviar notificaciones'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _viewStudents() {
    if (!TeacherFeatureFlags.ENABLE_STUDENT_LIST) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ir a la pestaña de Estudiantes para ver la lista'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _generateReport() {
    if (!TeacherFeatureFlags.ENABLE_REPORTS) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generando reporte de dashboard...'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}