import 'package:flutter/material.dart';

/// Chip visual del estado del evento (similar a Google Calendar)
class EventStatusChip extends StatelessWidget {
  final String status;
  final bool compact;

  const EventStatusChip({
    Key? key,
    required this.status,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    if (compact) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: config['color'],
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (config['color'] as Color).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config['icon'] as IconData,
            size: 14,
            color: config['color'],
          ),
          SizedBox(width: 4),
          Text(
            config['label'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: config['color'],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return {
          'icon': Icons.schedule,
          'label': 'Pendiente',
          'color': Colors.grey,
        };
      case 'confirmado':
        return {
          'icon': Icons.check_circle_outline,
          'label': 'Confirmado',
          'color': Colors.blue,
        };
      case 'completado':
        return {
          'icon': Icons.check_circle,
          'label': 'Completado',
          'color': Colors.green,
        };
      case 'no_realizado':
        return {
          'icon': Icons.cancel,
          'label': 'No realizado',
          'color': Colors.orange,
        };
      case 'cancelado':
        return {
          'icon': Icons.event_busy,
          'label': 'Cancelado',
          'color': Colors.red,
        };
      case 'postergado':
        return {
          'icon': Icons.update,
          'label': 'Pospuesto',
          'color': Colors.purple,
        };
      default:
        return {
          'icon': Icons.help_outline,
          'label': status,
          'color': Colors.grey,
        };
    }
  }
}
