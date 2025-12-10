import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../models/event_model.dart';
import 'weekly_goals_card.dart';

class AIOrganizerDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(List<Map<String, dynamic>>) onEventsCreated;
  final List<EventModel> allEvents;

  const AIOrganizerDialog({
    Key? key,
    required this.selectedDate,
    required this.onEventsCreated,
    required this.allEvents,
  }) : super(key: key);

  @override
  _AIOrganizerDialogState createState() => _AIOrganizerDialogState();
}

class _AIOrganizerDialogState extends State<AIOrganizerDialog> {
  final AIService _aiService = AIService();
  
  bool _isLoading = false;
  bool _isAnalyzing = true;
  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _selectedSuggestions = [];
  Map<String, dynamic>? _analysisData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _analyzeSchedule();
  }

  Future<void> _analyzeSchedule() async {
    setState(() {
      _isLoading = true;
      _isAnalyzing = true;
      _errorMessage = '';
    });

    try {
      final result = await _aiService.analyzeSchedule(widget.selectedDate);
      
      if (result['success']) {
        final data = result['data'];
        
        if (data['success']) {
          setState(() {
            _analysisData = data;
            _suggestions = List<Map<String, dynamic>>.from(data['suggestions']);
            _isAnalyzing = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'];
            _isAnalyzing = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error al analizar el horario';
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isAnalyzing = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmSuggestions() async {
    if (_selectedSuggestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una sugerencia')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _aiService.confirmSuggestions(_selectedSuggestions);
      
      if (result['success']) {
        // Notificar que se crearon eventos con la lista de sugerencias
        widget.onEventsCreated(_selectedSuggestions);
        
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      } else {
        setState(() {
          _errorMessage = 'Error al crear eventos';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSuggestion(Map<String, dynamic> suggestion, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedSuggestions.add(suggestion);
      } else {
        _selectedSuggestions.removeWhere((s) => s['title'] == suggestion['title']);
      }
    });
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes} min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}min';
      }
    }
  }

  String _formatTime(String isoString) {
    final dateTime = DateTime.parse(isoString);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'recreativo':
        return Colors.green;
      case 'estudio':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'recreativo':
        return Icons.sports;
      case 'estudio':
        return Icons.school;
      default:
        return Icons.event;
    }
  }

  int _getSelectedDuration(String type) {
    int totalMinutes = 0;
    for (var suggestion in _selectedSuggestions) {
      if (suggestion['type'] == type) {
        totalMinutes += (suggestion['duration'] as int);
      }
    }
    return totalMinutes;
  }

  int _getExistingDuration(String type) {
    if (_analysisData == null) return 0;
    
    if (type == 'estudio') {
      return (_analysisData!['existing_study_time'] ?? 0).toInt();
    } else if (type == 'recreativo') {
      return (_analysisData!['existing_exercise_time'] ?? 0).toInt();
    }
    return 0;
  }

  int _getTotalRecommended(String type) {
    if (_analysisData == null) return 0;
    
    if (type == 'estudio') {
      return (_analysisData!['total_recommended_study'] ?? 
              _analysisData!['recommended_study_time'] ?? 0).toInt();
    } else if (type == 'recreativo') {
      return (_analysisData!['total_recommended_exercise'] ?? 
              _analysisData!['recommended_exercise_time'] ?? 0).toInt();
    }
    return 0;
  }

  Map<String, dynamic>? _getCompletionStatus() {
    if (_analysisData == null) return null;
    
    // Si hay un mensaje del backend, usarlo
    if (_analysisData!.containsKey('message') && _analysisData!['message'] != null) {
      final message = _analysisData!['message'] as String;
      final isComplete = message.contains('Felicitaciones') || message.contains('cumpliste');
      
      return {
        'isComplete': isComplete,
        'message': message,
      };
    }
    
    // Fallback al cálculo local si no hay mensaje del backend
    final totalRecommendedStudy = _getTotalRecommended('estudio');
    final totalRecommendedExercise = _getTotalRecommended('recreativo');
    final existingStudy = _getExistingDuration('estudio');
    final existingExercise = _getExistingDuration('recreativo');
    final selectedStudy = _getSelectedDuration('estudio');
    final selectedExercise = _getSelectedDuration('recreativo');
    
    final totalStudy = existingStudy + selectedStudy;
    final totalExercise = existingExercise + selectedExercise;
    
    final studyComplete = totalStudy >= totalRecommendedStudy;
    final exerciseComplete = totalExercise >= totalRecommendedExercise;
    
    if (studyComplete && exerciseComplete) {
      return {
        'isComplete': true,
        'message': '¡Excelente! Cumples con todas las metas recomendadas 🎉',
      };
    } else if (studyComplete || exerciseComplete) {
      return {
        'isComplete': false,
        'message': 'Buen progreso. Intenta agregar más ${!studyComplete ? "estudio" : "ejercicio"} 💪',
      };
    } else if (_selectedSuggestions.isEmpty) {
      return {
        'isComplete': false,
        'message': 'Selecciona actividades para alcanzar tus metas diarias 📚',
      };
    } else {
      return {
        'isComplete': false,
        'message': 'Vas por buen camino, sigue agregando actividades 💪',
      };
    }
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressMetric({
    required IconData icon,
    required String label,
    required int recommended,
    required int selected,
    required Color color,
  }) {
    final existing = label == 'Estudio' 
        ? _getExistingDuration('estudio') 
        : _getExistingDuration('recreativo');
    final totalRecommended = label == 'Estudio'
        ? _getTotalRecommended('estudio')
        : _getTotalRecommended('recreativo');
    
    final total = existing + selected;
    final actualRecommended = totalRecommended > 0 ? totalRecommended : recommended;
    final percentage = actualRecommended > 0 ? (total / actualRecommended).clamp(0.0, 1.0) : 0.0;
    final isComplete = total >= actualRecommended;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (existing > 0) ...[
                  Text(
                    '${_formatDuration(existing)} ya programado',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  '${_formatDuration(total)} / ${_formatDuration(actualRecommended)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.green : color,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Background bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1.0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!),
                minHeight: 8,
              ),
            ),
            // Existing time bar
            if (existing > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (existing / actualRecommended).clamp(0.0, 1.0),
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color.withValues(alpha: 0.5),
                  ),
                  minHeight: 8,
                ),
              ),
            // Total bar (existing + selected)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? Colors.green : color,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.purple,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Organizar con IA',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Fecha: ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
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
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: _isAnalyzing
                  ? _buildAnalyzingView()
                  : _errorMessage.isNotEmpty
                      ? _buildErrorView()
                      : _buildSuggestionsView(),
            ),

            // Bottom actions
            if (!_isAnalyzing && _errorMessage.isEmpty)
              Container(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedSuggestions.length} sugerencias seleccionadas',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _confirmSuggestions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Crear Eventos'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
          SizedBox(height: 16),
          Text(
            'Analizando tu horario...',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'La IA está buscando espacios libres y generando sugerencias',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _analyzeSchedule,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsView() {
    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay sugerencias disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu horario está muy ocupado o no hay suficiente tiempo libre',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analysis summary with progress indicators
          if (_analysisData != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[50]!, Colors.purple[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple[200]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.purple[700], size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Análisis del día',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Free time
                _buildMetricRow(
                  icon: Icons.event_available,
                  label: 'Tiempo libre total',
                  value: _formatDuration(_analysisData!['total_free_time'].toInt()),
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                
                // Study time with progress
                _buildProgressMetric(
                  icon: Icons.school,
                  label: 'Estudio',
                  recommended: _analysisData!['recommended_study_time'].toInt(),
                  selected: _getSelectedDuration('estudio'),
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                
                // Exercise time with progress
                _buildProgressMetric(
                  icon: Icons.fitness_center,
                  label: 'Ejercicio',
                  recommended: _analysisData!['recommended_exercise_time'].toInt(),
                  selected: _getSelectedDuration('recreativo'),
                  color: Colors.orange,
                ),
                
                // Motivational message
                if (_getCompletionStatus() != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getCompletionStatus()!['isComplete']
                          ? Colors.green[100]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getCompletionStatus()!['isComplete']
                            ? Colors.green[300]!
                            : Colors.orange[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getCompletionStatus()!['isComplete']
                              ? Icons.check_circle
                              : Icons.info,
                          color: _getCompletionStatus()!['isComplete']
                              ? Colors.green[700]
                              : Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getCompletionStatus()!['message'],
                            style: TextStyle(
                              fontSize: 13,
                              color: _getCompletionStatus()!['isComplete']
                                  ? Colors.green[900]
                                  : Colors.orange[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Panel de Metas Semanales
        WeeklyGoalsCard(
          events: widget.allEvents,
          weekStart: _getWeekStart(widget.selectedDate),
          showExercise: false, // Solo mostrar estudio y recreativo
        ),
        const SizedBox(height: 16),

        // Suggestions title
        const Text(
          'Sugerencias de la IA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Suggestions list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              final isSelected = _selectedSuggestions.any(
                (s) => s['title'] == suggestion['title'],
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (bool? value) {
                    _toggleSuggestion(suggestion, value ?? false);
                  },
                  title: Row(
                    children: [
                      Icon(
                        _getTypeIcon(suggestion['type']),
                        color: _getTypeColor(suggestion['type']),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion['title'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatTime(suggestion['suggested_start'])} - ${_formatTime(suggestion['suggested_end'])}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(suggestion['duration']),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (suggestion['question'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          suggestion['question'],
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  activeColor: _getTypeColor(suggestion['type']),
                ),
              );
            },
          ),
      ],
      ),
    );
  }

  /// Obtiene el lunes de la semana de una fecha dada
  DateTime _getWeekStart(DateTime date) {
    int weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }
}
