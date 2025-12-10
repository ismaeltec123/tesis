import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ml_prediction_service.dart';
import '../viewmodels/event_viewmodel.dart';
import '../models/event_model.dart';
import 'package:intl/intl.dart';

class MLPredictionDialog extends StatefulWidget {
  final String userId;

  const MLPredictionDialog({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<MLPredictionDialog> createState() => _MLPredictionDialogState();
}

class _MLPredictionDialogState extends State<MLPredictionDialog> {
  final MLPredictionService _mlService = MLPredictionService();
  
  bool _isLoading = false;
  bool _isServiceAvailable = false;
  String? _errorMessage;
  Map<String, dynamic>? _modelStatus;
  
  // Estado para el selector de eventos
  EventModel? _selectedEvent;
  List<MLSuggestion>? _suggestions;
  bool _isLoadingSuggestions = false;
  
  @override
  void initState() {
    super.initState();
    _initializeMLService();
  }

  Future<void> _initializeMLService() async {
    setState(() => _isLoading = true);
    
    try {
      final available = await _mlService.isServiceAvailable();
      
      if (!available) {
        setState(() {
          _isServiceAvailable = false;
          _isLoading = false;
          _errorMessage = 'Microservicio ML no disponible en puerto 5000';
        });
        return;
      }

      setState(() => _isServiceAvailable = true);

      try {
        final status = await _mlService.getModelStatus(widget.userId);
        setState(() {
          _modelStatus = status;
          _isLoading = false;
        });

        if (status['model_exists'] != true || status['can_predict'] != true) {
          _trainModelWithCurrentEvents();
        }
      } catch (e) {
        _trainModelWithCurrentEvents();
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isServiceAvailable = false;
        _errorMessage = 'Error conectando con ML Service: $e';
      });
    }
  }

  Future<void> _trainModelWithCurrentEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final viewModel = Provider.of<EventViewModel>(context, listen: false);
      final events = viewModel.events;

      if (events.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No hay eventos para entrenar el modelo';
        });
        return;
      }

      final eventsHistory = events.map((e) {
        // Mapear estados de Flutter a estados de ML Service
        String mlStatus = 'pendiente';
        if (e.status == EventStatus.completado) {
          mlStatus = 'finalizado';
        } else if (e.status == EventStatus.cancelado) {
          mlStatus = 'cancelado';
        } else {
          mlStatus = 'pendiente';
        }

        // Convertir fecha a ISO8601 sin timezone (naive datetime)
        final dateWithoutTz = DateTime(
          e.date.year,
          e.date.month,
          e.date.day,
          e.date.hour,
          e.date.minute,
          e.date.second,
        );

        return {
          'id': e.id,
          'date': dateWithoutTz.toIso8601String(),
          'status': mlStatus,
          'type': e.category ?? 'general',
          'title': e.title,
          if (e.status != EventStatus.completado)
            'reschedule_reason': mlStatus,
        };
      }).toList();

      final result = await _mlService.trainModel(widget.userId, eventsHistory);

      setState(() {
        _isLoading = false;
        _modelStatus = result;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Modelo entrenado con ${events.length} eventos'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error entrenando modelo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.psychology, color: Colors.purple.shade700, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sistema ML de Predicción',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Estado del modelo',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
            const Divider(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !_isServiceAvailable
                      ? _buildErrorState()
                      : _buildStatusView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Error desconocido',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusView() {
    if (_modelStatus == null) {
      return const Center(child: Text('Cargando estado...'));
    }

    final modelExists = _modelStatus!['model_exists'] == true;
    final eventsCount = _modelStatus!['events_in_model'] ?? 0;

    if (!modelExists) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 64, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            const Text('Modelo no entrenado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Se entrenó con $eventsCount eventos'),
          ],
        ),
      );
    }

    // Si hay sugerencias, mostrarlas
    if (_suggestions != null && _suggestions!.isNotEmpty) {
      return _buildSuggestionsView();
    }

    // Selector de evento
    return _buildEventSelector();
  }

  Widget _buildEventSelector() {
    final viewModel = Provider.of<EventViewModel>(context, listen: false);
    final events = viewModel.events;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona un evento para reprogramar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          if (events.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No hay eventos en el calendario'),
              ),
            )
          else
            ...events.take(10).map((event) => _buildEventCard(event)),
          
          const SizedBox(height: 16),
          
          if (_selectedEvent != null && !_isLoadingSuggestions)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _getSuggestions,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Obtener Sugerencias ML'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          
          if (_isLoadingSuggestions)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final isSelected = _selectedEvent?.id == event.id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedEvent = event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? Colors.purple : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.purple.shade700 : Colors.black,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy HH:mm', 'es').format(event.date),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _suggestions = null;
                  _selectedEvent = null;
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sugerencias para: ${_selectedEvent?.title ?? ""}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ..._suggestions!.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            return _buildSuggestionCard(suggestion, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(MLSuggestion suggestion, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'es').format(suggestion.getDateTime()),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${DateFormat('HH:mm').format(suggestion.getDateTime())} (${suggestion.dayName ?? ""})',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(suggestion.confidence),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(suggestion.confidence * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            suggestion.reason,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _applySuggestion(suggestion),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aplicar esta sugerencia'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _getSuggestions() async {
    if (_selectedEvent == null) return;

    setState(() {
      _isLoadingSuggestions = true;
      _errorMessage = null;
    });

    try {
      final viewModel = Provider.of<EventViewModel>(context, listen: false);
      final duration = _selectedEvent!.endTime.difference(_selectedEvent!.date).inMinutes;

      // Preparar el evento incompleto en formato del microservicio
      final dateWithoutTz = DateTime(
        _selectedEvent!.date.year,
        _selectedEvent!.date.month,
        _selectedEvent!.date.day,
        _selectedEvent!.date.hour,
        _selectedEvent!.date.minute,
      );

      // Mapear tipo de evento a los tipos aceptados por ML
      String mlType = 'personal'; // default
      final eventCategory = (_selectedEvent!.category ?? 'general').toLowerCase();
      
      if (eventCategory.contains('estudio') || eventCategory.contains('clase') || 
          eventCategory.contains('tarea') || eventCategory.contains('examen')) {
        mlType = 'estudio';
      } else if (eventCategory.contains('trabajo') || eventCategory.contains('reunion') ||
                 eventCategory.contains('proyecto')) {
        mlType = 'trabajo';
      } else if (eventCategory.contains('ejercicio') || eventCategory.contains('deporte') ||
                 eventCategory.contains('gym') || eventCategory.contains('correr')) {
        mlType = 'ejercicio';
      } else {
        mlType = 'personal';
      }

      final suggestions = await _mlService.getPredictionsForEvent(
        userId: widget.userId,
        incompleteEvent: {
          'id': _selectedEvent!.id,
          'title': _selectedEvent!.title,
          'type': mlType,
          'duration_minutes': duration > 0 ? duration : 60,
          'original_date': dateWithoutTz.toIso8601String(),
        },
      );

      setState(() {
        _suggestions = suggestions;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
        _errorMessage = 'Error obteniendo sugerencias: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _applySuggestion(MLSuggestion suggestion) async {
    if (_selectedEvent == null) return;

    try {
      final viewModel = Provider.of<EventViewModel>(context, listen: false);
      
      // Crear nuevo evento con la fecha sugerida
      final duration = _selectedEvent!.endTime.difference(_selectedEvent!.date);
      final newEvent = _selectedEvent!.copyWith(
        date: suggestion.getDateTime(),
        endTime: suggestion.getDateTime().add(duration),
      );

      await viewModel.updateEvent(newEvent);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Evento reprogramado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error aplicando sugerencia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
