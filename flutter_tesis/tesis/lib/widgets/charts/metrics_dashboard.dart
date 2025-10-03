import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MetricsDashboard extends StatelessWidget {
  final Map<String, dynamic> mlInsights;

  const MetricsDashboard({Key? key, required this.mlInsights}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Datos con valores por defecto seguros
    final totalEvents = _getSafeInt(mlInsights['total_events'], 0);
    final avgProductivity = _getSafeDouble(mlInsights['avg_productivity'], 0.7) * 100;
    final avgDuration = _getSafeDouble(mlInsights['avg_duration'], 45.0);
    final bestHour = _getSafeInt(mlInsights['best_hour'], 10);

    return _buildDashboard(totalEvents, avgProductivity, avgDuration, bestHour);
  }

  // Funciones helper para casting seguro
  int _getSafeInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  double _getSafeDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Widget _buildDashboard(int totalEvents, double avgProductivity, double avgDuration, int bestHour) {

    return Column(
      children: [
        // Métricas principales
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Eventos',
                totalEvents.toString(),
                Icons.event,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Productividad',
                '${avgProductivity.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Duración Prom',
                '${avgDuration.toStringAsFixed(0)}min',
                Icons.timer,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Mejor Hora',
                '${bestHour}:00h',
                Icons.access_time,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Gráfico de barras de productividad
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productividad por Hora',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey,
                          tooltipHorizontalAlignment: FLHorizontalAlignment.right,
                          tooltipMargin: -10,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            String hour = '${(group.x.toInt() + 8)}:00';
                            return BarTooltipItem(
                              '$hour\n${rod.toY.round()}%',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
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
                            getTitlesWidget: getTitles,
                            reservedSize: 38,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 25,
                            getTitlesWidget: leftTitleWidgets,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      barGroups: _generateBarData(bestHour),
                      gridData: const FlGridData(show: false),
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarData(int bestHour) {
    return List.generate(12, (i) {
      final hour = i + 8; // De 8AM a 8PM
      final isBestHour = hour == bestHour;
      final productivity = isBestHour ? 85.0 : (50 + (i % 3) * 15).toDouble();
      
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: productivity,
            color: isBestHour ? Colors.green : Colors.blue[300],
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    final hour = (value.toInt() + 8) % 24;
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: Text('${hour}h', style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    return Text('${value.toInt()}%', style: style, textAlign: TextAlign.left);
  }
}