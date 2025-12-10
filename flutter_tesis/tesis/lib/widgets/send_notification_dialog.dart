import 'package:flutter/material.dart';
import '../services/notification_api_service.dart';

class SendNotificationDialog extends StatefulWidget {
  final NotificationApiService? notificationService;

  const SendNotificationDialog({
    Key? key,
    this.notificationService,
  }) : super(key: key);

  @override
  State<SendNotificationDialog> createState() => _SendNotificationDialogState();
}

class _SendNotificationDialogState extends State<SendNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _selectedType = 'general';
  bool _isSending = false;
  
  late NotificationApiService _notificationService;

  final Map<String, Map<String, dynamic>> _notificationTypes = {
    'general': {'icon': Icons.notifications, 'color': Colors.purple, 'label': 'General'},
    'schedule': {'icon': Icons.calendar_today, 'color': Colors.green, 'label': 'Horario'},
    'reminder': {'icon': Icons.alarm, 'color': Colors.orange, 'label': 'Recordatorio'},
    'alert': {'icon': Icons.warning, 'color': Colors.red, 'label': 'Alerta'},
    'info': {'icon': Icons.info, 'color': Colors.blue, 'label': 'Información'},
  };

  @override
  void initState() {
    super.initState();
    _notificationService = widget.notificationService ?? NotificationApiService();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final success = await _notificationService.sendNotification(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        notificationType: _selectedType,
      );

      if (!mounted) return;

      if (success) {
        _showSuccessSnackbar();
        Navigator.of(context).pop(true);
      } else {
        _showErrorSnackbar('No se pudo enviar la notificación');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('✅ Notificación enviada a ismael.quispe@tecsup.edu.pe')),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.email,
                          color: Colors.purple.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enviar Notificación',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'A: ismael.quispe@tecsup.edu.pe',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Notification Type Selector
                  const Text(
                    'Tipo de Notificación',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _notificationTypes.length,
                      itemBuilder: (context, index) {
                        final type = _notificationTypes.keys.elementAt(index);
                        final config = _notificationTypes[type]!;
                        final isSelected = _selectedType == type;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            onTap: () => setState(() => _selectedType = type),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 90,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? config['color'].withOpacity(0.1)
                                    : Colors.grey.shade100,
                                border: Border.all(
                                  color: isSelected 
                                      ? config['color']
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    config['icon'],
                                    color: isSelected 
                                        ? config['color']
                                        : Colors.grey.shade600,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    config['label'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                      color: isSelected 
                                          ? config['color']
                                          : Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Título *',
                      hintText: 'Ej: Recordatorio de Clase',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa un título';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Message Field
                  TextFormField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Mensaje *',
                      hintText: 'Escribe tu mensaje aquí...',
                      prefixIcon: const Icon(Icons.message),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa un mensaje';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Send Button
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendNotification,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isSending ? 'Enviando...' : 'Enviar Notificación',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _notificationTypes[_selectedType]!['color'],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Test Button
                  OutlinedButton.icon(
                    onPressed: _isSending ? null : _sendTestEmail,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Enviar Email de Prueba'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendTestEmail() async {
    setState(() => _isSending = true);

    try {
      final success = await _notificationService.sendTestNotification();

      if (!mounted) return;

      if (success) {
        _showSuccessSnackbar();
      } else {
        _showErrorSnackbar('No se pudo enviar el email de prueba');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}
