import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/habit_ml_service.dart';
import '../viewmodels/event_viewmodel.dart';
import 'package:intl/intl.dart';

class PreEventNotificationDialog extends StatefulWidget {
  final EventModel event;
  final EventViewModel eventViewModel;
  final Function() onConfirm;
  final Function() onSkip;
  final Function(EventModel) onReschedule;

  const PreEventNotificationDialog({
    Key? key,
    required this.event,
    required this.eventViewModel,
    required this.onConfirm,
    required this.onSkip,
    required this.onReschedule,
  }) : super(key: key);

  @override
  _PreEventNotificationDialogState createState() => _PreEventNotificationDialogState();
}

class _PreEventNotificationDialogState extends State<PreEventNotificationDialog> {
  final HabitMLService _habitML = HabitMLService();
  
  bool _isLoading = false;
  bool _showRescheduleOptions = false;
  List<Map<String, dynamic>> _rescheduleSuggestions = [];

  @override
  Widget build(BuildContext context) {
    final timeUntilEvent = widget.event.date.difference(DateTime.now());
    final minutesUntil = timeUntilEvent.inMinutes;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.cyan.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.access_time, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    '¡Tu evento está por comenzar!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'En $minutesUntil minutos',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Event details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventInfo(),
                  const SizedBox(height: 20),
                  
                  if (!_showRescheduleOptions) ...[
                    Text(
                      '¿Vas a realizar esta actividad?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                  ] else ...[
                    _buildRescheduleOptions(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.event.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.event.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.event.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.cyan.shade600),
              const SizedBox(width: 8),
              Text(
                DateFormat('HH:mm').format(widget.event.date),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.label, size: 16, color: Colors.cyan.shade600),
              const SizedBox(width: 8),
              Text(
                widget.event.type,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botón SÍ
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleConfirm,
            icon: const Icon(Icons.check_circle),
            label: const Text('Sí, voy a hacerlo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Botón REPROGRAMAR
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleRescheduleRequest,
            icon: const Icon(Icons.schedule),
            label: const Text('Quiero reprogramarlo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Botón NO
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleSkip,
            icon: const Icon(Icons.cancel),
            label: const Text('No puedo hacerlo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade600),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRescheduleOptions() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_rescheduleSuggestions.isEmpty) {
      return const Center(
        child: Text('No se encontraron sugerencias'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _showRescheduleOptions = false;
                });
              },
            ),
            const Text(
              'Mejores momentos para reprogramar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        ..._rescheduleSuggestions.take(3).map((suggestion) {
          return _buildSuggestionCard(suggestion);
        }).toList(),
      ],
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final datetime = DateTime.parse(suggestion['datetime']);
    final probability = (suggestion['probability'] * 100).toInt();
    final confidence = suggestion['confidence'];
    final reason = suggestion['reason'];

    Color confidenceColor = confidence == 'alta' 
        ? Colors.green 
        : confidence == 'media' 
            ? Colors.orange 
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleRescheduleToTime(datetime),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE d, HH:mm', 'es').format(datetime),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: confidenceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: confidenceColor),
                    ),
                    child: Text(
                      '$probability% probabilidad',
                      style: TextStyle(
                        color: confidenceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reason,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    
    try {
      // Actualizar estado a "en_progreso"
      await _habitML.updateEventStatus(
        eventId: widget.event.id,
        newStatus: 'en_progreso',
      );
      
      Navigator.of(context).pop();
      widget.onConfirm();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Excelente! Evento marcado como en progreso'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSkip() async {
    setState(() => _isLoading = true);
    
    try {
      // Actualizar estado a "cancelado"
      await _habitML.updateEventStatus(
        eventId: widget.event.id,
        newStatus: 'cancelado',
      );
      
      Navigator.of(context).pop();
      widget.onSkip();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento cancelado. Intenta programar uno similar pronto'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRescheduleRequest() async {
    setState(() {
      _isLoading = true;
      _showRescheduleOptions = true;
    });
    
    try {
      // Obtener sugerencias de reprogramación
      final result = await _habitML.suggestReschedule(
        eventId: widget.event.id,
        eventType: widget.event.type,
        currentDatetime: widget.event.date.toIso8601String(),
      );
      
      setState(() {
        _rescheduleSuggestions = List<Map<String, dynamic>>.from(
          result['suggestions'] ?? []
        );
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error obteniendo sugerencias: $e')),
      );
      setState(() {
        _isLoading = false;
        _showRescheduleOptions = false;
      });
    }
  }

  Future<void> _handleRescheduleToTime(DateTime newTime) async {
    setState(() => _isLoading = true);
    
    try {
      // Actualizar estado a "postergado"
      await _habitML.updateEventStatus(
        eventId: widget.event.id,
        newStatus: 'postergado',
      );
      
      // Calcular nueva endTime manteniendo la duración
      final duration = widget.event.endTime.difference(widget.event.date);
      final newEndTime = newTime.add(duration);
      
      // Crear evento actualizado
      final updatedEvent = widget.event.copyWith(
        date: newTime,
        endTime: newEndTime,
        originalDate: widget.event.originalDate ?? widget.event.date,
        postponedCount: (widget.event.postponedCount ?? 0) + 1,
      );
      
      // Actualizar en calendario usando el viewmodel
      await widget.eventViewModel.updateEvent(updatedEvent);
      
      Navigator.of(context).pop();
      widget.onReschedule(updatedEvent);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Evento reprogramado para ${DateFormat('EEEE d, HH:mm', 'es').format(newTime)}'
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reprogramando: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
