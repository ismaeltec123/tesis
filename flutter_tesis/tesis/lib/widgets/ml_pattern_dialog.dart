import 'package:flutter/material.dart';
import '../services/ml_pattern_service.dart';
import '../models/event_model.dart';
import 'package:intl/intl.dart';

/// Diálogo para mostrar análisis ML de patrones de eventos
/// y buscar/predecir fallas en la programación del usuario
class MLPatternAnalysisDialog extends StatefulWidget {
  final List<EventModel> allEvents;

  const MLPatternAnalysisDialog({
    Key? key,
    required this.allEvents,
  }) : super(key: key);

  @override
  State<MLPatternAnalysisDialog> createState() => _MLPatternAnalysisDialogState();
}

class _MLPatternAnalysisDialogState extends State<MLPatternAnalysisDialog> {
  bool _isLoading = true;
  bool _isGeneratingTestData = false;
  Map<String, dynamic>? _patterns;
  Map<String, dynamic>? _hotspots;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatterns();
  }

  Future<void> _loadPatterns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Cargar análisis de patrones
      final patterns = await MLPatternService.analyzePatterns();
      final hotspots = await MLPatternService.getFailureHotspots();

      setState(() {
        _patterns = patterns;
        _hotspots = hotspots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar análisis: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateTestData() async {
    setState(() {
      _isGeneratingTestData = true;
    });

    try {
      final result = await MLPatternService.autoFillTestData(numEvents: 5);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Datos de prueba generados'),
          backgroundColor: Colors.green,
        ),
      );

      // Recargar análisis
      await _loadPatterns();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingTestData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple[700], size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Análisis ML de Patrones',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Predice cuándo es más probable que falles',
                        style: TextStyle(
                          fontSize: 13,
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
            const Divider(height: 24),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingView()
                  : _errorMessage != null
                      ? _buildErrorView()
                      : _buildAnalysisView(),
            ),

            // Bottom actions
            const Divider(height: 24),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _isGeneratingTestData ? null : _generateTestData,
                  icon: _isGeneratingTestData
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.science),
                  label: const Text('Generar Datos de Prueba'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
          SizedBox(height: 16),
          Text('Analizando patrones de eventos...'),
          SizedBox(height: 8),
          Text(
            'Esto puede tomar unos segundos',
            style: TextStyle(fontSize: 12, color: Colors.grey),
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
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Error desconocido',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPatterns,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisView() {
    if (_patterns == null || _hotspots == null) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    // Verificar si hay error en los datos
    if (_patterns!.containsKey('error')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 64, color: Colors.orange[300]),
            const SizedBox(height: 16),
            Text(
              _patterns!['error'],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.orange),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifica que el backend esté corriendo en:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'http://localhost:8001',
              style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPatterns,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final summary = _patterns!['summary'] as Map<String, dynamic>?;
    if (summary == null) {
      return const Center(child: Text('Error: datos de resumen no disponibles'));
    }

    final totalEvents = summary['total_events'] as int? ?? 0;
    final failedEvents = summary['failed_events'] as int? ?? 0;
    final failureRate = (summary['failure_rate'] as num?)?.toDouble() ?? 0.0;

    // Si no hay eventos suficientes
    if (totalEvents < 5) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No hay suficientes eventos para analizar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Se necesitan al menos 5 eventos con estados',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateTestData,
              icon: const Icon(Icons.science),
              label: const Text('Generar Datos de Prueba'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen general
          _buildSummaryCard(totalEvents, failedEvents, failureRate),
          const SizedBox(height: 16),

          // Peores días
          _buildWorstDaysCard(),
          const SizedBox(height: 16),

          // Peores horarios
          _buildWorstTimeSlotsCard(),
          const SizedBox(height: 16),

          // Mejores alternativas
          _buildBestAlternativesCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int total, int failed, double rate) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Resumen General',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Eventos',
                    total.toString(),
                    Colors.blue,
                    Icons.event,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Eventos Fallidos',
                    failed.toString(),
                    Colors.red,
                    Icons.cancel,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Tasa de Falla',
                    '${rate.toStringAsFixed(1)}%',
                    rate > 30 ? Colors.red : Colors.green,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildWorstDaysCard() {
    if (_hotspots == null || !_hotspots!.containsKey('worst_days')) {
      return const SizedBox.shrink();
    }
    
    final worstDays = _hotspots!['worst_days'] as List? ?? [];

    return Card(
      elevation: 2,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                const SizedBox(width: 8),
                const Text(
                  'Peores Días de la Semana',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...worstDays.map((day) => _buildDayItem(
                  day['day'],
                  day['rate'].toDouble(),
                  day['failed'],
                  isWorst: true,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildWorstTimeSlotsCard() {
    if (_hotspots == null || !_hotspots!.containsKey('worst_time_slots')) {
      return const SizedBox.shrink();
    }
    
    final worstSlots = _hotspots!['worst_time_slots'] as List? ?? [];

    return Card(
      elevation: 2,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'Peores Horarios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...worstSlots.map((slot) => _buildTimeSlotItem(
                  slot['slot'],
                  slot['rate'].toDouble(),
                  slot['failed'],
                  isWorst: true,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBestAlternativesCard() {
    if (_hotspots == null || !_hotspots!.containsKey('best_days') || !_hotspots!.containsKey('best_time_slots')) {
      return const SizedBox.shrink();
    }
    
    final bestDays = _hotspots!['best_days'] as List? ?? [];
    final bestSlots = _hotspots!['best_time_slots'] as List? ?? [];

    return Card(
      elevation: 2,
      color: Colors.green[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Mejores Alternativas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Días con mayor éxito:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...bestDays.map((day) => _buildDayItem(
                  day['day'],
                  day['rate'].toDouble(),
                  day['failed'],
                  isWorst: false,
                )),
            const SizedBox(height: 16),
            const Text(
              'Horarios con mayor éxito:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...bestSlots.map((slot) => _buildTimeSlotItem(
                  slot['slot'],
                  slot['rate'].toDouble(),
                  slot['failed'],
                  isWorst: false,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDayItem(String day, double rate, int failed, {required bool isWorst}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isWorst ? Icons.close : Icons.check,
            color: isWorst ? Colors.red : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isWorst ? Colors.red[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${rate.toStringAsFixed(1)}% falla',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isWorst ? Colors.red[900] : Colors.green[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotItem(String slot, double rate, int failed, {required bool isWorst}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: isWorst ? Colors.orange[700] : Colors.green[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              slot,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isWorst ? Colors.orange[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${rate.toStringAsFixed(1)}% falla',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isWorst ? Colors.orange[900] : Colors.green[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
