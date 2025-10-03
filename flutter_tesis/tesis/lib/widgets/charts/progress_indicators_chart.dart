import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressIndicatorsChart extends StatelessWidget {
  final Map<String, dynamic> mlInsights;

  const ProgressIndicatorsChart({Key? key, required this.mlInsights}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productivity = _getSafeDouble(mlInsights['avg_productivity'], 0.7) * 100;
    final completion = _getSafeDouble(mlInsights['completion_rate'], 0.8) * 100;
    final efficiency = _getSafeDouble(mlInsights['efficiency'], 0.75) * 100;
    final focus = _getSafeDouble(mlInsights['focus_score'], 0.65) * 100;

    return _buildProgressChart(productivity, completion, efficiency, focus);
  }

  // Funciones helper para casting seguro
  double _getSafeDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Widget _buildProgressChart(double productivity, double completion, double efficiency, double focus) {

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indicadores de Rendimiento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Indicadores circulares
            Row(
              children: [
                Expanded(
                  child: _buildCircularProgress(
                    'Productividad',
                    productivity,
                    Colors.blue,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildCircularProgress(
                    'Completado',
                    completion,
                    Colors.green,
                    Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildCircularProgress(
                    'Eficiencia',
                    efficiency,
                    Colors.orange,
                    Icons.speed,
                  ),
                ),
                Expanded(
                  child: _buildCircularProgress(
                    'Enfoque',
                    focus,
                    Colors.purple,
                    Icons.center_focus_strong,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Barras de progreso detalladas
            const Text(
              'Objetivos del Mes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildProgressBar('Horas de estudio', 85, Colors.blue, '85/100h'),
            const SizedBox(height: 12),
            _buildProgressBar('Tareas completadas', 92, Colors.green, '23/25'),
            const SizedBox(height: 12),
            _buildProgressBar('Ejercicio semanal', 60, Colors.orange, '3/5 días'),
            const SizedBox(height: 12),
            _buildProgressBar('Proyectos terminados', 75, Colors.purple, '3/4'),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgress(String title, double value, Color color, IconData icon) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 25,
                  startDegreeOffset: -90,
                  sections: [
                    PieChartSectionData(
                      value: value,
                      color: color,
                      radius: 10,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: 100 - value,
                      color: color.withOpacity(0.2),
                      radius: 10,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 2),
                Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(String title, double percentage, Color color, String detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              detail,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${percentage.toInt()}%',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}