import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ActivityPieChart extends StatefulWidget {
  final Map<String, dynamic> mlInsights;

  const ActivityPieChart({Key? key, required this.mlInsights}) : super(key: key);

  @override
  State<ActivityPieChart> createState() => _ActivityPieChartState();
}

class _ActivityPieChartState extends State<ActivityPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final activityTypes = _safeCastToMap(widget.mlInsights['activity_distribution']);
    
    return _buildChart(activityTypes);
  }

  // Funciones helper para casting seguro
  Map<String, dynamic> _safeCastToMap(dynamic input) {
    if (input == null) return {};
    if (input is Map<String, dynamic>) return input;
    if (input is Map) {
      return Map<String, dynamic>.from(input);
    }
    return {};
  }

  Widget _buildChart(Map<String, dynamic> activityTypes) {
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución de Actividades',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 0,
                        centerSpaceRadius: 50,
                        sections: _generateSections(activityTypes),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildLegend(activityTypes),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections(Map<String, dynamic> data) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    final activities = [
      {'name': 'Estudio', 'value': data['study'] ?? 35, 'color': colors[0]},
      {'name': 'Trabajo', 'value': data['work'] ?? 25, 'color': colors[1]},
      {'name': 'Ejercicio', 'value': data['exercise'] ?? 15, 'color': colors[2]},
      {'name': 'Reuniones', 'value': data['meetings'] ?? 12, 'color': colors[3]},
      {'name': 'Descanso', 'value': data['rest'] ?? 8, 'color': colors[4]},
      {'name': 'Otros', 'value': data['others'] ?? 5, 'color': colors[5]},
    ];

    return activities.asMap().entries.map((entry) {
      final index = entry.key;
      final activity = entry.value;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? 65.0 : 55.0;
      
      return PieChartSectionData(
        color: activity['color'],
        value: activity['value'].toDouble(),
        title: '${activity['value']}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched 
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                activity['name'],
                style: TextStyle(
                  fontSize: 10,
                  color: activity['color'],
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  List<Widget> _buildLegend(Map<String, dynamic> data) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    final activities = [
      {'name': 'Estudio', 'value': data['study'] ?? 35, 'color': colors[0]},
      {'name': 'Trabajo', 'value': data['work'] ?? 25, 'color': colors[1]},
      {'name': 'Ejercicio', 'value': data['exercise'] ?? 15, 'color': colors[2]},
      {'name': 'Reuniones', 'value': data['meetings'] ?? 12, 'color': colors[3]},
      {'name': 'Descanso', 'value': data['rest'] ?? 8, 'color': colors[4]},
      {'name': 'Otros', 'value': data['others'] ?? 5, 'color': colors[5]},
    ];

    return activities.map((activity) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: activity['color'],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                activity['name'],
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Text(
              '${activity['value']}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}