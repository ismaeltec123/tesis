import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/teacher/teacher_templates.dart';
import '../../models/teacher/teacher_config.dart';

class TeacherMetricsCards extends StatelessWidget {
  const TeacherMetricsCards({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = SubjectTemplate.getMockSubjects();
    final students = StudentListTemplate.getMockStudents();
    final schedules = ClassScheduleTemplate.getMockSchedule();
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Materias',
          subjects.length.toString(),
          Icons.book,
          Colors.blue,
          'Activas este semestre',
        ),
        _buildMetricCard(
          'Estudiantes',
          students.where((s) => s.isActive).length.toString(),
          Icons.people,
          Colors.green,
          'Total activos',
        ),
        _buildMetricCard(
          'Clases/Semana',
          schedules.length.toString(),
          Icons.schedule,
          Colors.orange,
          'Horas académicas',
        ),
        _buildMetricCard(
          'Carga Laboral',
          '${_calculateWorkload()}%',
          Icons.work,
          Colors.purple,
          'Del tiempo disponible',
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateWorkload() {
    final schedules = ClassScheduleTemplate.getMockSchedule();
    // Simular cálculo: cada clase = 2 horas, máximo 40 horas/semana
    final totalHours = schedules.length * 2;
    final percentage = ((totalHours / 40) * 100).round();
    return percentage.clamp(0, 100);
  }
}

class TeacherProductivityCharts extends StatelessWidget {
  const TeacherProductivityCharts({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gráfico de distribución semanal
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Distribución de Clases por Día',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 4,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: _getWeekDayTitles,
                            reservedSize: 38,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: _getLeftTitles,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _generateWeeklyData(),
                      gridData: const FlGridData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Gráfico de carga por materia
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Distribución por Materia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: _generateSubjectData(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _generateWeeklyData() {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'];
    final schedules = ClassScheduleTemplate.getMockSchedule();
    
    return List.generate(5, (index) {
      final dayName = days[index];
      final daySchedules = schedules.where((s) => s.dayOfWeek.startsWith(dayName)).length;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: daySchedules.toDouble(),
            color: Colors.blue[400],
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  List<PieChartSectionData> _generateSubjectData() {
    final subjects = SubjectTemplate.getMockSubjects();
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    
    return subjects.asMap().entries.map((entry) {
      final index = entry.key;
      final subject = entry.value;
      final schedules = ClassScheduleTemplate.getScheduleForSubject(subject.id);
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: schedules.length.toDouble(),
        title: '${schedules.length}h',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _getWeekDayTitles(double value, TitleMeta meta) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'];
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        days[value.toInt()],
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _getLeftTitles(double value, TitleMeta meta) {
    return Text(
      value.toInt().toString(),
      style: const TextStyle(fontSize: 10),
    );
  }
}

class TeacherActivitySummary extends StatelessWidget {
  const TeacherActivitySummary({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = SubjectTemplate.getMockSubjects();
    final notifications = TeacherNotificationTemplate.getMockNotifications();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Resumen de Actividades',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Próximas clases
            _buildActivitySection(
              'Próximas Clases',
              Icons.schedule,
              Colors.blue,
              _getUpcomingClasses(),
            ),
            
            const SizedBox(height: 16),
            
            // Avisos recientes
            _buildActivitySection(
              'Avisos Enviados',
              Icons.notifications,
              Colors.orange,
              notifications.map((n) => '${n.title} - ${n.type.toUpperCase()}').toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Materias activas
            _buildActivitySection(
              'Materias Activas',
              Icons.book,
              Colors.green,
              subjects.map((s) => '${s.name} (${s.studentIds.length} estudiantes)').toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection(
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.take(3).map((item) => Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        )),
        if (items.length > 3)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              '... y ${items.length - 3} más',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  List<String> _getUpcomingClasses() {
    final schedules = ClassScheduleTemplate.getMockSchedule();
    final today = DateTime.now().weekday;
    final todayName = _getDayName(today);
    
    final todaySchedules = schedules
        .where((s) => s.dayOfWeek == todayName)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return todaySchedules.map((s) => 
      '${s.subjectName} - ${s.startTime} (${s.classroom})'
    ).toList();
  }

  String _getDayName(int weekday) {
    const days = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[weekday];
  }
}