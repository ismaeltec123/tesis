import 'package:flutter/material.dart';
import '../../models/teacher/teacher_templates.dart';
import '../../models/teacher/teacher_config.dart';
import '../../models/teacher/teacher_models.dart';

class TeacherScheduleView extends StatefulWidget {
  const TeacherScheduleView({super.key});

  @override
  State<TeacherScheduleView> createState() => _TeacherScheduleViewState();
}

class _TeacherScheduleViewState extends State<TeacherScheduleView> {
  String _selectedDay = '';
  
  final List<String> _weekDays = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _getCurrentDay();
  }

  String _getCurrentDay() {
    final now = DateTime.now();
    final weekday = now.weekday;
    if (weekday <= 5) {
      return _weekDays[weekday - 1];
    }
    return 'Lunes'; // Default to Monday for weekends
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Day selector
            _buildDaySelector(),
            
            // Schedule content
            Expanded(
              child: _buildScheduleContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final totalClasses = ClassScheduleTemplate.getMockSchedule().length;
    
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
          const Icon(Icons.schedule, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Horario de Clases',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (TeacherTemplateConfig.USE_MOCK_SCHEDULE)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.science_outlined, size: 12, color: Colors.blue[800]),
                        const SizedBox(width: 4),
                        Text(
                          '🎭 Horarios de demostración',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '$totalClasses clases/semana',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _weekDays.length,
        itemBuilder: (context, index) {
          final day = _weekDays[index];
          final isSelected = day == _selectedDay;
          final daySchedules = ClassScheduleTemplate.getScheduleForDay(day);
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDay = day;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange[500] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.orange[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day.substring(0, 3),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.3) : Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        daySchedules.length.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.orange[700],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleContent() {
    if (!TeacherFeatureFlags.ENABLE_CLASS_SCHEDULE) {
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

    final daySchedules = ClassScheduleTemplate.getScheduleForDay(_selectedDay);
    
    if (daySchedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.free_breakfast, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay clases programadas para $_selectedDay',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: daySchedules.length,
      itemBuilder: (context, index) {
        final schedule = daySchedules[index];
        return _buildScheduleCard(schedule, index);
      },
    );
  }

  Widget _buildScheduleCard(ClassSchedule schedule, int index) {
    final subject = SubjectTemplate.getMockSubjects()
        .firstWhere((s) => s.id == schedule.subjectId);
    
    final colors = [Colors.blue, Colors.green, Colors.purple, Colors.orange];
    final color = colors[index % colors.length];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Time indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${schedule.startTime} - ${schedule.endTime}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Subject name
                    Text(
                      schedule.subjectName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Location and students
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          schedule.classroom,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        if (schedule.building != null) ...[
                          Text(' • ${schedule.building}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                        const Spacer(),
                        Icon(Icons.people, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${subject.studentIds.length}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onSelected: (value) => _handleScheduleAction(value, schedule),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Ver detalles'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'notify',
                    child: ListTile(
                      leading: Icon(Icons.notification_add),
                      title: Text('Enviar aviso'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'students',
                    child: ListTile(
                      leading: Icon(Icons.people),
                      title: Text('Ver estudiantes'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleScheduleAction(String action, ClassSchedule schedule) {
    switch (action) {
      case 'details':
        _showScheduleDetails(schedule);
        break;
      case 'notify':
        _sendClassNotification(schedule);
        break;
      case 'students':
        _showClassStudents(schedule);
        break;
    }
  }

  void _showScheduleDetails(ClassSchedule schedule) {
    final subject = SubjectTemplate.getMockSubjects()
        .firstWhere((s) => s.id == schedule.subjectId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule.subjectName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${subject.code}'),
            Text('Horario: ${schedule.startTime} - ${schedule.endTime}'),
            Text('Aula: ${schedule.classroom}'),
            if (schedule.building != null)
              Text('Edificio: ${schedule.building}'),
            Text('Créditos: ${subject.credits}'),
            Text('Estudiantes: ${subject.studentIds.length}'),
            if (subject.description != null)
              Text('Descripción: ${subject.description}'),
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

  void _sendClassNotification(ClassSchedule schedule) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enviando aviso para ${schedule.subjectName}...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showClassStudents(ClassSchedule schedule) {
    final subject = SubjectTemplate.getMockSubjects()
        .firstWhere((s) => s.id == schedule.subjectId);
    final students = StudentListTemplate.getMockStudents()
        .where((s) => subject.studentIds.contains(s.id))
        .toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Estudiantes - ${schedule.subjectName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(student.name[0]),
                ),
                title: Text(student.name),
                subtitle: Text(student.email),
                dense: true,
              );
            },
          ),
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
}