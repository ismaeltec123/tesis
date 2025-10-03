import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIOrganizerDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function onEventsCreated;

  const AIOrganizerDialog({
    Key? key,
    required this.selectedDate,
    required this.onEventsCreated,
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
        // Notificar que se crearon eventos
        widget.onEventsCreated();
        
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Analysis summary
        if (_analysisData != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Análisis del día',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tiempo libre total: ${_formatDuration(_analysisData!['total_free_time'].toInt())}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Estudio recomendado: ${_formatDuration(_analysisData!['recommended_study_time'].toInt())}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Ejercicio recomendado: ${_formatDuration(_analysisData!['recommended_exercise_time'].toInt())}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

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
        Expanded(
          child: ListView.builder(
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
        ),
      ],
    );
  }
}