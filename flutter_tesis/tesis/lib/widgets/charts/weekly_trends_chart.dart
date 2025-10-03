import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyTrendsChart extends StatelessWidget {
  final Map<String, dynamic> mlInsights;

  const WeeklyTrendsChart({Key? key, required this.mlInsights}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildWeeklyChart();
  }

  // Funciones helper para casting seguro
  List<dynamic> _getSafeList(dynamic value, List<dynamic> defaultValue) {
    if (value == null) return defaultValue;
    if (value is List) return value;
    return defaultValue;
  }

  Widget _buildWeeklyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tendencias Semanales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 20,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Colors.grey,
                        strokeWidth: 0.5,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return const FlLine(
                        color: Colors.grey,
                        strokeWidth: 0.5,
                      );
                    },
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
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: bottomTitleWidgets,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        getTitlesWidget: leftTitleWidgets,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xff37434d)),
                  ),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    // Productividad
                    LineChartBarData(
                      spots: _generateProductivitySpots(),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.8),
                          Colors.blue,
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.3),
                            Colors.blue.withOpacity(0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Eventos completados
                    LineChartBarData(
                      spots: _generateEventsSpots(),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.8),
                          Colors.green,
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final flSpot = barSpot;
                          final dayName = _getDayName(flSpot.x.toInt());
                          
                          if (barSpot.barIndex == 0) {
                            return LineTooltipItem(
                              '$dayName\nProductividad: ${flSpot.y.toInt()}%',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          } else {
                            return LineTooltipItem(
                              '$dayName\nEventos: ${flSpot.y.toInt()}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Leyenda
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Productividad %', Colors.blue),
                const SizedBox(width: 20),
                _buildLegendItem('Eventos completados', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  List<FlSpot> _generateProductivitySpots() {
    // Simular datos de productividad semanal
    final weeklyData = _getSafeList(mlInsights['weekly_productivity'], [65, 72, 68, 85, 78, 55, 42]);
    
    return List.generate(7, (index) {
      final productivity = index < weeklyData.length ? weeklyData[index] : (60 + (index * 5) % 30);
      return FlSpot(index.toDouble(), productivity.toDouble());
    });
  }

  List<FlSpot> _generateEventsSpots() {
    // Simular datos de eventos completados
    final weeklyEvents = _getSafeList(mlInsights['weekly_events'], [8, 12, 10, 15, 13, 7, 5]);
    
    return List.generate(7, (index) {
      final events = index < weeklyEvents.length ? weeklyEvents[index] : (5 + (index * 2) % 10);
      // Normalizar a escala de 0-100 para mostrar en el mismo gráfico
      final normalized = (events * 6.5).toDouble(); // Aproximadamente 15 eventos = 100%
      return FlSpot(index.toDouble(), normalized);
    });
  }

  String _getDayName(int dayIndex) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[dayIndex % 7];
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    
    final dayName = _getDayName(value.toInt());
    
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(dayName, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );

    String text;
    if (value == 0) {
      text = '0';
    } else if (value == 20) {
      text = '20';
    } else if (value == 40) {
      text = '40';
    } else if (value == 60) {
      text = '60';
    } else if (value == 80) {
      text = '80';
    } else if (value == 100) {
      text = '100';
    } else {
      return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.left);
  }
}