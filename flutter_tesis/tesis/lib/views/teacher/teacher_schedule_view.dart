import 'package:flutter/material.dart';
import '../../models/teacher/teacher_templates.dart';
import '../../models/teacher/teacher_config.dart';
import '../../models/teacher/teacher_models.dart';
import '../../widgets/teacher/teacher_schedule_importer.dart';
import '../../services/teacher_schedule_service.dart';

class TeacherScheduleView extends StatefulWidget {
  const TeacherScheduleView({super.key});

  @override
  State<TeacherScheduleView> createState() => _TeacherScheduleViewState();
}

class _TeacherScheduleViewState extends State<TeacherScheduleView> {
  String _selectedDay = '';
  String _selectedWeekType = 'par'; // NUEVO: filtro de semana
  final TeacherScheduleService _scheduleService = TeacherScheduleService();
  bool _hasImportedSchedules = false;
  List<ClassSchedule> _allSchedules = [];
  bool _isLoading = true;
  
  final List<String> _weekDays = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _getCurrentDay();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    
    try {
      _hasImportedSchedules = await _scheduleService.hasImportedSchedules();
      _allSchedules = await _scheduleService.getAllSchedules();
    } catch (e) {
      print('Error loading schedules: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getCurrentDay() {
    final now = DateTime.now();
    final weekday = now.weekday;
    if (weekday <= 5) {
      return _weekDays[weekday - 1];
    }
    return 'Lunes'; // Default to Monday for weekends
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: const TeacherScheduleImporter(
            teacherId: 'teacher_ejemplo_001',
            backendUrl: 'http://localhost:8001',
          ),
        ),
      ),
    ).then((_) {
      // Refrescar la vista después de importar
      _loadSchedules();
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
            
            // Day selector
            _buildDaySelector(),
            
            // NUEVO: Week type selector (Par/Impar)
            _buildWeekTypeSelector(),
            
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
    final totalClasses = _allSchedules.length;
    
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
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _hasImportedSchedules ? Colors.green[100] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _hasImportedSchedules ? Icons.cloud_done : Icons.science_outlined, 
                        size: 12, 
                        color: _hasImportedSchedules ? Colors.green[800] : Colors.blue[800]
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _hasImportedSchedules ? '📋 Horarios importados' : '🎭 Horarios de demostración',
                        style: TextStyle(
                          fontSize: 10,
                          color: _hasImportedSchedules ? Colors.green[800] : Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalClasses clases/semana',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasImportedSchedules) ...[
                    ElevatedButton.icon(
                      onPressed: _showExportToCalendarDialog,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text(
                        'Exportar',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _showClearSchedulesDialog,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text(
                        'Limpiar',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _showImportDialog,
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: Text(
                      _hasImportedSchedules ? 'Reimportar' : 'Importar Horario',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ],
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
          final daySchedules = _allSchedules
              .where((schedule) => schedule.dayOfWeek == day)
              .toList();
          
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

  Widget _buildWeekTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_view_week, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            'Tipo de semana:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                _buildWeekTypeButton('par', '📅 Semana Par'),
                const SizedBox(width: 8),
                _buildWeekTypeButton('impar', '📅 Semana Impar'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTypeButton(String weekType, String label) {
    final isSelected = _selectedWeekType == weekType;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedWeekType = weekType;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange[500] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.orange[700]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

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

    final daySchedules = _allSchedules
        .where((schedule) => 
          schedule.dayOfWeek == _selectedDay &&
          (schedule.weekType == _selectedWeekType || schedule.weekType == null || schedule.weekType == '')
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
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
            if (!_hasImportedSchedules) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showImportDialog,
                icon: const Icon(Icons.upload_file),
                label: const Text('Importar Horario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
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
        .firstWhere((s) => s.id == schedule.subjectId, orElse: () => Subject(
          id: 'unknown',
          name: schedule.subjectName,
          code: 'N/A',
          credits: 0,
          studentIds: [],
          semester: '2025-2',
        ));
    
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
                        if (_hasImportedSchedules) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Importado',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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
                        if (subject.studentIds.isNotEmpty) ...[
                          Icon(Icons.people, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${subject.studentIds.length}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ] else if (_hasImportedSchedules) ...[
                          Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Sin estudiantes',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
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
                  if (subject.studentIds.isNotEmpty)
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
        .firstWhere((s) => s.id == schedule.subjectId, orElse: () => Subject(
          id: 'unknown',
          name: schedule.subjectName,
          code: 'N/A',
          credits: 0,
          studentIds: [],
          semester: '2025-2',
        ));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule.subjectName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subject.code != 'N/A')
              Text('Código: ${subject.code}'),
            Text('Horario: ${schedule.startTime} - ${schedule.endTime}'),
            Text('Día: ${schedule.dayOfWeek}'),
            Text('Aula: ${schedule.classroom}'),
            if (schedule.building != null)
              Text('Edificio: ${schedule.building}'),
            if (subject.credits > 0)
              Text('Créditos: ${subject.credits}'),
            Text('Estudiantes: ${subject.studentIds.length}'),
            if (subject.description != null)
              Text('Descripción: ${subject.description}'),
            if (_hasImportedSchedules) ...[
              const Divider(),
              Row(
                children: [
                  Icon(Icons.cloud_done, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Horario importado desde imagen',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
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
        .firstWhere((s) => s.id == schedule.subjectId, orElse: () => Subject(
          id: 'unknown',
          name: schedule.subjectName,
          code: 'N/A',
          credits: 0,
          studentIds: [],
          semester: '2025-2',
        ));
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
          child: students.isEmpty 
            ? const Center(
                child: Text('No hay estudiantes registrados para esta materia'),
              )
            : ListView.builder(
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

  void _showExportToCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('Exportar al Calendario'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas exportar todos los horarios (${_allSchedules.length} clases) al calendario principal?'),
            const SizedBox(height: 16),
            const Text(
              'Esto creará eventos recurrentes en tu calendario personal.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final nav = Navigator.of(context);
              final scaffold = ScaffoldMessenger.of(context);
              
              nav.pop(); // Cerrar diálogo de confirmación
              
              // Mostrar indicador de carga
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Exportando al calendario...'),
                    ],
                  ),
                ),
              );
              
              try {
                await _scheduleService.exportToCalendar();
                nav.pop(); // Cerrar diálogo de carga
                
                scaffold.showSnackBar(
                  const SnackBar(
                    content: Text('✅ Horarios exportados al calendario exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                nav.pop(); // Cerrar diálogo de carga
                
                scaffold.showSnackBar(
                  SnackBar(
                    content: Text('❌ Error al exportar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('Exportar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearSchedulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Limpiar Horarios'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que deseas eliminar todos los horarios importados (${_allSchedules.length} clases)?'),
            const SizedBox(height: 16),
            const Text(
              'Esta acción no se puede deshacer. Se mostrarán nuevamente los horarios de demostración.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                print('🧹 Iniciando limpieza de horarios...');
                await _scheduleService.clearImportedSchedules();
                print('🔄 Recargando horarios después de limpiar...');
                await _loadSchedules(); // Recargar datos
                print('✅ Horarios recargados después de limpiar');
                
                // Forzar actualización del estado
                if (mounted) {
                  setState(() {
                    // Trigger rebuild
                  });
                }
                
                // Mostrar mensaje sin usar ScaffoldMessenger para evitar errores de widget lifecycle
                print('✅ Horarios eliminados correctamente');
              } catch (e) {
                print('❌ Error limpiando horarios: $e');
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}