import 'package:flutter/material.dart';
import '../services/event_status_service.dart';

/// Bottom Sheet para cambiar el estado de un evento
/// Diseño similar a Google Calendar
class EventStatusBottomSheet extends StatefulWidget {
  final String eventId;
  final String currentStatus;
  final String eventTitle;
  final VoidCallback onStatusChanged;

  const EventStatusBottomSheet({
    Key? key,
    required this.eventId,
    required this.currentStatus,
    required this.eventTitle,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  State<EventStatusBottomSheet> createState() => _EventStatusBottomSheetState();
}

class _EventStatusBottomSheetState extends State<EventStatusBottomSheet> {
  final _statusService = EventStatusService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Título
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.eventTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  'Estado actual: ${_getStatusLabel(widget.currentStatus)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else
            _buildActionButtons(),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final actions = _getAvailableActions();
    
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionTile(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          color: action['color'] as Color,
          onTap: () => _handleAction(action['action'] as String),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  List<Map<String, dynamic>> _getAvailableActions() {
    final status = widget.currentStatus;
    final actions = <Map<String, dynamic>>[];

    // Marcar como completado (disponible para pendiente y confirmado)
    if (status == 'pendiente' || status == 'confirmado') {
      actions.add({
        'action': 'complete',
        'icon': Icons.check_circle,
        'label': 'Marcar como completado',
        'color': Colors.green,
      });
    }

    // Confirmar asistencia (solo para pendiente)
    if (status == 'pendiente') {
      actions.add({
        'action': 'confirm',
        'icon': Icons.event_available,
        'label': 'Confirmar asistencia',
        'color': Colors.blue,
      });
    }

    // Marcar como no realizado (disponible para confirmado)
    if (status == 'confirmado' || status == 'pendiente') {
      actions.add({
        'action': 'not_done',
        'icon': Icons.cancel_outlined,
        'label': 'No lo realicé',
        'color': Colors.orange,
      });
    }

    // Posponer evento
    if (status == 'pendiente' || status == 'confirmado') {
      actions.add({
        'action': 'postpone',
        'icon': Icons.schedule,
        'label': 'Posponer para después',
        'color': Colors.purple,
      });
    }

    // Cancelar evento
    if (status != 'cancelado' && status != 'completado') {
      actions.add({
        'action': 'cancel',
        'icon': Icons.event_busy,
        'label': 'Cancelar evento',
        'color': Colors.red,
      });
    }

    return actions;
  }

  Future<void> _handleAction(String action) async {
    Navigator.pop(context); // Cerrar bottom sheet

    switch (action) {
      case 'complete':
        await _completeEvent();
        break;
      case 'confirm':
        await _confirmEvent();
        break;
      case 'not_done':
        await _showNotDoneDialog();
        break;
      case 'postpone':
        await _postponeEvent();
        break;
      case 'cancel':
        await _showCancelDialog();
        break;
    }
  }

  Future<void> _completeEvent() async {
    setState(() => _isLoading = true);
    try {
      await _statusService.markAsCompleted(widget.eventId);
      _showSuccessSnackBar('✅ Evento marcado como completado');
      
      // Cerrar el bottom sheet primero
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Luego notificar el cambio
      widget.onStatusChanged();
    } catch (e) {
      _showErrorSnackBar('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmEvent() async {
    setState(() => _isLoading = true);
    try {
      await _statusService.confirmEvent(widget.eventId);
      _showSuccessSnackBar('✅ Asistencia confirmada');
      
      // Cerrar el bottom sheet primero
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Luego notificar el cambio
      widget.onStatusChanged();
    } catch (e) {
      _showErrorSnackBar('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postponeEvent() async {
    setState(() => _isLoading = true);
    try {
      await _statusService.postponeEvent(widget.eventId);
      _showSuccessSnackBar('⏰ Evento pospuesto');
      
      // Cerrar el bottom sheet primero
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Luego notificar el cambio
      widget.onStatusChanged();
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCancelDialog() async {
    print('🔵 DEBUG: Abriendo diálogo de cancelar...');
    
    // Guardar referencia al widget antes del diálogo
    final eventId = widget.eventId;
    final onStatusChangedCallback = widget.onStatusChanged;
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CancelEventDialog(),
    );

    print('🔵 DEBUG: Razón recibida: $reason');
    
    if (reason == null) {
      print('🔵 DEBUG: Cancelación abortada (razón null)');
      return;
    }
    
    // Cerrar el bottom sheet PRIMERO (mientras el context aún existe)
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    
    print('🔵 DEBUG: Iniciando cancelación del evento...');
    
    // Hacer la llamada API después de cerrar
    try {
      await _statusService.cancelEvent(eventId, reason: reason);
      print('🔵 DEBUG: Evento cancelado exitosamente');
      
      // Notificar el cambio
      onStatusChangedCallback();
    } catch (e) {
      print('❌ DEBUG: Error cancelando: $e');
    }
  }

  Future<void> _showNotDoneDialog() async {
    print('🟠 DEBUG: Abriendo diálogo de no realizado...');
    
    // Guardar referencia al widget antes del diálogo
    final eventId = widget.eventId;
    final onStatusChangedCallback = widget.onStatusChanged;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _NotDoneEventDialog(),
    );

    print('🟠 DEBUG: Resultado recibido: $result');
    
    if (result == null) {
      print('🟠 DEBUG: Marcado como no realizado abortado (result null)');
      return;
    }
    
    // Cerrar el bottom sheet PRIMERO (mientras el context aún existe)
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    
    print('🟠 DEBUG: Iniciando marcado como no realizado...');
    
    // Hacer la llamada API después de cerrar
    try {
      await _statusService.markAsNotDone(
        eventId,
        reason: result['reason'],
        mood: result['mood'],
        energyLevel: result['energy_level'],
        stressLevel: result['stress_level'],
        additionalNotes: result['notes'],
      );
      print('🟠 DEBUG: Evento marcado como no realizado exitosamente');
      
      // Notificar el cambio
      onStatusChangedCallback();
    } catch (e) {
      print('❌ DEBUG: Error marcando como no realizado: $e');
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pendiente':
        return 'Pendiente';
      case 'confirmado':
        return 'Confirmado';
      case 'completado':
        return 'Completado';
      case 'no_realizado':
        return 'No realizado';
      case 'cancelado':
        return 'Cancelado';
      case 'postergado':
        return 'Pospuesto';
      default:
        return status;
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

/// Diálogo para cancelar evento
class _CancelEventDialog extends StatefulWidget {
  @override
  State<_CancelEventDialog> createState() => _CancelEventDialogState();
}

class _CancelEventDialogState extends State<_CancelEventDialog> {
  String? _selectedReason;
  final _customReasonController = TextEditingController();

  final _reasons = [
    'Tengo otro compromiso',
    'No me siento bien',
    'Problemas de tiempo',
    'Cambio de planes',
    'Emergencia familiar',
    'Otro motivo',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('¿Por qué cancelas?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._reasons.map((reason) => RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value),
              contentPadding: EdgeInsets.zero,
            )),
            if (_selectedReason == 'Otro motivo') ...[
              SizedBox(height: 8),
              TextField(
                controller: _customReasonController,
                decoration: InputDecoration(
                  labelText: 'Especifica el motivo',
                  border: OutlineInputBorder(),
                  hintText: 'Escribe aquí...',
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _selectedReason == 'Otro motivo'
                ? _customReasonController.text
                : _selectedReason;
            Navigator.pop(context, reason);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Confirmar cancelación'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }
}

/// Diálogo para evento no realizado
class _NotDoneEventDialog extends StatefulWidget {
  @override
  State<_NotDoneEventDialog> createState() => _NotDoneEventDialogState();
}

class _NotDoneEventDialogState extends State<_NotDoneEventDialog> {
  String? _reason;
  String? _mood;
  String? _energyLevel;
  String? _stressLevel;
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('¿Por qué no lo realizaste?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Razón principal', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: Text('Selecciona una razón'),
              value: _reason,
              items: [
                DropdownMenuItem(value: 'olvide_hacerlo', child: Text('Olvidé hacerlo')),
                DropdownMenuItem(value: 'sin_tiempo', child: Text('Sin tiempo')),
                DropdownMenuItem(value: 'cansancio', child: Text('Cansancio')),
                DropdownMenuItem(value: 'falta_motivacion', child: Text('Falta de motivación')),
                DropdownMenuItem(value: 'imprevistos', child: Text('Imprevistos')),
                DropdownMenuItem(value: 'otro', child: Text('Otro')),
              ],
              onChanged: (value) => setState(() => _reason = value),
            ),
            
            SizedBox(height: 16),
            Text('¿Cómo te sentías?', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            
            // Estado de ánimo
            Wrap(
              spacing: 8,
              children: [
                _buildChip('😞 Mal', 'mal', _mood, (v) => setState(() => _mood = v)),
                _buildChip('😐 Regular', 'regular', _mood, (v) => setState(() => _mood = v)),
                _buildChip('😊 Bien', 'bien', _mood, (v) => setState(() => _mood = v)),
                _buildChip('😁 Excelente', 'excelente', _mood, (v) => setState(() => _mood = v)),
              ],
            ),
            
            SizedBox(height: 16),
            Text('Nivel de energía', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              children: [
                _buildChip('🔋 Bajo', 'bajo', _energyLevel, (v) => setState(() => _energyLevel = v)),
                _buildChip('🔋🔋 Medio', 'medio', _energyLevel, (v) => setState(() => _energyLevel = v)),
                _buildChip('🔋🔋🔋 Alto', 'alto', _energyLevel, (v) => setState(() => _energyLevel = v)),
              ],
            ),
            
            SizedBox(height: 16),
            Text('Nivel de estrés', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              children: [
                _buildChip('😌 Bajo', 'bajo', _stressLevel, (v) => setState(() => _stressLevel = v)),
                _buildChip('😰 Medio', 'medio', _stressLevel, (v) => setState(() => _stressLevel = v)),
                _buildChip('😫 Alto', 'alto', _stressLevel, (v) => setState(() => _stressLevel = v)),
              ],
            ),
            
            SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notas adicionales (opcional)',
                border: OutlineInputBorder(),
                hintText: 'Agrega más detalles...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'reason': _reason,
              'mood': _mood,
              'energy_level': _energyLevel,
              'stress_level': _stressLevel,
              'notes': _notesController.text.isEmpty ? null : _notesController.text,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: Text('Confirmar'),
        ),
      ],
    );
  }

  Widget _buildChip(String label, String value, String? groupValue, Function(String?) onSelected) {
    final isSelected = groupValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onSelected(selected ? value : null),
      selectedColor: Colors.blue.withOpacity(0.3),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
