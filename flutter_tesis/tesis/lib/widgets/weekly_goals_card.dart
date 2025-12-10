import 'package:flutter/material.dart';
import '../models/event_model.dart';

/// Panel de metas semanales (estudio, recreativo, ejercicio)
/// Similar al tracker de actividad de Google Calendar
class WeeklyGoalsCard extends StatelessWidget {
  final List<EventModel> events;
  final DateTime weekStart;
  final bool showExercise;

  const WeeklyGoalsCard({
    Key? key,
    required this.events,
    required this.weekStart,
    this.showExercise = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = _calculateWeeklyStats();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text(
                  'Metas Semanales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  '${_formatWeekRange()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),

            // Estudio: eventos obligatorios (clases) + estudio
            _buildGoalRow(
              icon: Icons.school,
              label: 'Estudio (esta semana)',
              current: stats['estudio']!,
              goal: 30, // Meta: 30 horas de clases/estudio a la semana
              color: Colors.blue,
            ),

            SizedBox(height: 12),

            // Recreativo: actividades de esparcimiento
            _buildGoalRow(
              icon: Icons.sports_esports,
              label: 'Recreativo (esta semana)',
              current: stats['recreativo']!,
              goal: 10, // Meta: 10 horas de actividades recreativas
              color: Colors.green,
            ),

            SizedBox(height: 12),

            // Ejercicio/Personal: actividad física recomendada por OMS
            if (showExercise) ...[
              _buildGoalRow(
                icon: Icons.fitness_center,
                label: 'Ejercicio (esta semana)',
                current: stats['personal']!,
                goal: 7, // Meta: 7 horas de ejercicio (1h diaria, OMS)
                color: Colors.orange,
              ),
              SizedBox(height: 12),
            ],

            // Total
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total programado esta semana',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${stats['total']!.toStringAsFixed(1)} hrs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalRow({
    required IconData icon,
    required String label,
    required double current,
    required double goal,
    required Color color,
  }) {
    final progress = (current / goal).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${current.toStringAsFixed(1)} / ${goal.toInt()} hrs',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 8,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, double> _calculateWeeklyStats() {
    double estudioHours = 0;
    double recreativoHours = 0;
    double personalHours = 0;

    // Filtrar eventos de la semana actual (incluir todos los estados)
    final weekEnd = weekStart.add(Duration(days: 7));
    
    for (var event in events) {
      // Contar TODOS los eventos de la semana (pendientes, confirmados, completados)
      // No filtrar por cancelados o no realizados
      if (event.status != EventStatus.cancelado &&
          event.status != EventStatus.noRealizado &&
          event.date.isAfter(weekStart.subtract(Duration(days: 1))) &&
          event.date.isBefore(weekEnd)) {
        
        // Calcular duración del evento en horas
        final duration = event.endTime.difference(event.date).inMinutes / 60.0;
        
        final eventType = event.type.toLowerCase();
        final eventTitle = event.title.toLowerCase();
        final eventDesc = event.description.toLowerCase();
        
        // Detectar tipo de actividad por contenido
        final isExercise = eventTitle.contains('correr') || 
                          eventTitle.contains('ejercicio') || 
                          eventTitle.contains('gym') || 
                          eventTitle.contains('deporte') ||
                          eventTitle.contains('yoga') ||
                          eventTitle.contains('bailar') ||
                          eventTitle.contains('nadar') ||
                          eventTitle.contains('caminar') ||
                          eventTitle.contains('entrenar') ||
                          eventDesc.contains('ejercicio');
        
        final isRecreativo = eventType == 'recreativo' || 
                            eventType == 'personal' ||
                            isExercise;
        
        // Solo eventos explícitos de estudio cuentan como estudio
        // Eventos obligatorios (clases) NO cuentan como estudio
        final isEstudio = eventType == 'estudio' ||
                         eventType == 'académico';
        
        if (isRecreativo && isExercise) {
          // Si es ejercicio/actividad física, cuenta como personal
          personalHours += duration;
        } else if (isRecreativo) {
          // Recreativo general
          recreativoHours += duration;
        } else if (isEstudio) {
          // Solo estudio explícito
          estudioHours += duration;
        } else {
          // Default: eventos obligatorios y otros NO cuentan para ninguna meta
          // (No se suman a ninguna categoría)
        }
      }
    }

    return {
      'estudio': estudioHours,
      'recreativo': recreativoHours,
      'personal': personalHours,
      'total': estudioHours + recreativoHours + personalHours,
    };
  }

  String _formatWeekRange() {
    final weekEnd = weekStart.add(Duration(days: 6));
    final startStr = '${weekStart.day}/${weekStart.month}';
    final endStr = '${weekEnd.day}/${weekEnd.month}';
    return '$startStr - $endStr';
  }
}
