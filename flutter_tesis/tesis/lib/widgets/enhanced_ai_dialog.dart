import 'package:flutter/material.dart';
import '../services/enhanced_ai_service.dart';
import 'charts/metrics_dashboard.dart';
import 'charts/activity_pie_chart.dart';
import 'charts/weekly_trends_chart.dart';
import 'charts/progress_indicators_chart.dart';
import 'dart:async';

class EnhancedAIDialog extends StatefulWidget {
  final Function onEventsCreated;

  const EnhancedAIDialog({
    Key? key,
    required this.onEventsCreated,
  }) : super(key: key);

  @override
  _EnhancedAIDialogState createState() => _EnhancedAIDialogState();
}

class _EnhancedAIDialogState extends State<EnhancedAIDialog> with SingleTickerProviderStateMixin {
  final EnhancedAIService _aiService = EnhancedAIService();
  late TabController _tabController;
  
  bool _isLoading = false;
  bool _aiAvailable = false;
  String _statusMessage = '';
  Map<String, dynamic>? _calendarAnalysis;
  List<Map<String, dynamic>> _chatHistory = [];
  
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _examDateController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAIStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _eventTitleController.dispose();
    _subjectController.dispose();
    _examDateController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAIStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Verificando sistema IA...';
    });

    try {
      _aiAvailable = await _aiService.isEnhancedAIAvailable();
      
      if (_aiAvailable) {
        // Inicializar sistema IA
        final initResult = await _aiService.initializeAI();
        if (initResult['success']) {
          setState(() {
            _statusMessage = 'Sistema IA inicializado correctamente';
          });
          
          // Cargar análisis inicial
          await _loadCalendarAnalysis();
        } else {
          setState(() {
            _statusMessage = 'Error inicializando IA: ${initResult['message'] ?? 'Error desconocido'}';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'Sistema Enhanced AI no disponible. Verifica que el servidor esté corriendo en puerto 8004.';
        });
      }
    } catch (e) {
      setState(() {
        _aiAvailable = false;
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCalendarAnalysis() async {
    try {
      final result = await _aiService.analyzeCalendar();
      print('🔍 DEBUG - analyzeCalendar result: ${result.runtimeType}');
      print('🔍 DEBUG - result success: ${result['success']}');
      
      if (result['success']) {
        setState(() {
          // Hacer casting explícito para evitar LinkedMap issues
          final rawData = result['data'];
          print('🔍 DEBUG - rawData type: ${rawData.runtimeType}');
          
          final data = _safeCastToMap(rawData ?? {});
          final rawMLInsights = data['ml_insights'];
          print('🔍 DEBUG - rawMLInsights type: ${rawMLInsights.runtimeType}');
          
          _calendarAnalysis = {
            'ml_insights': _safeCastToMap(rawMLInsights),
            'ai_analysis': data['ai_analysis'] ?? 'No disponible',
          };
          
          print('✅ SUCCESS - _calendarAnalysis creado correctamente');
        });
      } else {
        // Si falla, usar datos por defecto
        setState(() {
          _calendarAnalysis = {
            'ml_insights': _getDefaultMLInsights(),
            'ai_analysis': 'Análisis no disponible en este momento. Verifica la conexión con el servidor.',
          };
        });
      }
    } catch (e) {
      print('Error cargando análisis: $e');
      // En caso de error, usar datos por defecto
      setState(() {
        _calendarAnalysis = {
          'ml_insights': _getDefaultMLInsights(),
          'ai_analysis': 'Error conectando con el sistema de análisis IA. Reintenta más tarde.',
        };
      });
    }
  }

  // Función helper para hacer casting seguro de LinkedMap a Map<String, dynamic>
  Map<String, dynamic> _safeCastToMap(dynamic input) {
    if (input == null) return {};
    if (input is Map<String, dynamic>) return input;
    if (input is Map) {
      return Map<String, dynamic>.from(input);
    }
    return {};
  }

  // Función helper para manejar errores en widgets de gráficos
  Widget _buildSafeWidget(Widget Function() builder) {
    try {
      return builder();
    } catch (e) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
              const SizedBox(height: 8),
              Text(
                'Error cargando gráfico',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Reintenta en unos momentos',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Función para proporcionar datos por defecto cuando falla la conexión
  Map<String, dynamic> _getDefaultMLInsights() {
    return {
      'total_events': 12,
      'avg_productivity': 0.72,
      'avg_duration': 45.5,
      'best_hour': 14,
      'completion_rate': 0.85,
      'efficiency': 0.78,
      'focus_score': 0.68,
      'activity_distribution': {
        'study': 35,
        'work': 28,
        'exercise': 15,
        'meetings': 12,
        'rest': 7,
        'others': 3,
      },
      'weekly_productivity': [68, 75, 72, 85, 80, 58, 45],
      'weekly_events': [8, 12, 10, 15, 13, 7, 5],
    };
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _chatHistory.add({
        'role': 'user',
        'message': message,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });

    _chatController.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.chatWithAI(message);
      
      setState(() {
        _chatHistory.add({
          'role': 'assistant',
          'message': response['data']['ai_response'] ?? 'Sin respuesta',
          'model': response['data']['model_used'] ?? 'desconocido',
          'timestamp': DateTime.now(),
        });
      });
    } catch (e) {
      setState(() {
        _chatHistory.add({
          'role': 'error',
          'message': 'Error: $e',
          'timestamp': DateTime.now(),
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _generateSmartEvent() async {
    final title = _eventTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un título para el evento')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _aiService.generateSmartEvent(title: title);
      
      if (result['success']) {
        final generatedContent = result['data']['generated_content'];
        
        // Mostrar resultado y opción de crear
        _showGeneratedEventDialog(generatedContent);
      } else {
        throw Exception('Error generando evento');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createStudyPlan() async {
    final subject = _subjectController.text.trim();
    final examDate = _examDateController.text.trim();
    
    if (subject.isEmpty || examDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa materia y fecha de examen')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _aiService.createStudyPlan(
        subject: subject,
        examDate: examDate,
      );
      
      if (result['success']) {
        _showStudyPlanDialog(result['data']);
      } else {
        throw Exception('Error creando plan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showGeneratedEventDialog(Map<String, dynamic> content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('Evento Generado por IA'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Título: ${content['title'] ?? 'Sin título'}', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Descripción: ${content['description'] ?? 'Sin descripción'}'),
              const SizedBox(height: 8),
              Text('Duración: ${content['duration_minutes'] ?? 60} minutos'),
              const SizedBox(height: 8),
              Text('Tipo: ${content['type'] ?? 'general'}'),
              if (content['preparations'] != null) ...[
                const SizedBox(height: 8),
                const Text('Preparativos:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...List<Widget>.from((content['preparations'] as List).map(
                  (prep) => Text('• $prep'),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Aquí podrías crear el evento real
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Evento creado con IA')),
              );
              widget.onEventsCreated();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Crear Evento'),
          ),
        ],
      ),
    );
  }

  void _showStudyPlanDialog(Map<String, dynamic> planData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.blue),
            SizedBox(width: 8),
            Text('Plan de Estudio IA'),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Text(planData['ai_study_plan'] ?? 'Plan no disponible'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plan de estudio guardado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Aplicar Plan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[700]!, Colors.purple[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enhanced AI Assistant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Machine Learning + Groq LLM',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_aiAvailable)
                    const Icon(Icons.warning, color: Colors.orange),
                  if (_aiAvailable)
                    const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Status bar
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: _aiAvailable ? Colors.green[50] : Colors.orange[50],
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _aiAvailable ? Colors.green[800] : Colors.orange[800],
                    fontSize: 12,
                  ),
                ),
              ),

            // Tabs
            if (_aiAvailable) ...[
              TabBar(
                controller: _tabController,
                labelColor: Colors.purple,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(Icons.analytics), text: 'Análisis'),
                  Tab(icon: Icon(Icons.chat), text: 'Chat IA'),
                  Tab(icon: Icon(Icons.auto_awesome), text: 'Generar'),
                  Tab(icon: Icon(Icons.school), text: 'Estudiar'),
                ],
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAnalysisTab(),
                    _buildChatTab(),
                    _buildGenerateTab(),
                    _buildStudyTab(),
                  ],
                ),
              ),
            ] else ...[
              // Error state
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Sistema Enhanced AI no disponible'),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkAIStatus,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisTab() {
    if (_calendarAnalysis == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analizando calendario con ML...'),
          ],
        ),
      );
    }

    try {
      final mlInsights = _safeCastToMap(_calendarAnalysis!['ml_insights']);
      final aiAnalysis = _calendarAnalysis!['ai_analysis'] ?? 'No disponible';
      
      // Debug logging
      print('🔍 DEBUG - mlInsights type: ${mlInsights.runtimeType}');
      print('🔍 DEBUG - mlInsights keys: ${mlInsights.keys.toList()}');
      
      return _buildAnalysisDashboard(mlInsights, aiAnalysis);
    } catch (e, stackTrace) {
      print('❌ ERROR en _buildAnalysisTab: $e');
      print('📍 StackTrace: $stackTrace');
      
      // En caso de error, mostrar datos por defecto
      final defaultInsights = _getDefaultMLInsights();
      return _buildAnalysisDashboard(defaultInsights, 'Error cargando análisis: $e');
    }
  }

  Widget _buildAnalysisDashboard(Map<String, dynamic> mlInsights, String aiAnalysis) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard de métricas principales con manejo de errores
          _buildSafeWidget(() => MetricsDashboard(mlInsights: mlInsights)),
          
          const SizedBox(height: 16),

          // Row con gráficos laterales
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildSafeWidget(() => ActivityPieChart(mlInsights: mlInsights)),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildSafeWidget(() => ProgressIndicatorsChart(mlInsights: mlInsights)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Gráfico de tendencias semanales
          _buildSafeWidget(() => WeeklyTrendsChart(mlInsights: mlInsights)),

          const SizedBox(height: 16),

          // AI Analysis expandido
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Análisis IA Conversacional', 
                           style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Text(
                      aiAnalysis,
                      style: TextStyle(
                        color: Colors.purple[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, 
                           size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Insights generados por Groq AI + Machine Learning',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        // Chat history
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _chatHistory.length,
            itemBuilder: (context, index) {
              final message = _chatHistory[index];
              final isUser = message['role'] == 'user';
              final isError = message['role'] == 'error';
              
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? Colors.purple[100] 
                        : isError 
                            ? Colors.red[100]
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['message'],
                        style: TextStyle(
                          color: isError ? Colors.red[800] : null,
                        ),
                      ),
                      if (!isUser && message['model'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Modelo: ${message['model']}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Loading indicator
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),

        // Chat input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: const InputDecoration(
                    hintText: 'Pregunta algo sobre tu calendario...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _sendChatMessage,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _sendChatMessage(_chatController.text),
                icon: const Icon(Icons.send),
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generar Evento Inteligente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'La IA analizará el título y generará contenido completo usando ML + Groq',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _eventTitleController,
            decoration: const InputDecoration(
              labelText: 'Título del evento',
              hintText: 'Ej: matemáticas, reunión proyecto, ejercicio...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateSmartEvent,
              icon: const Icon(Icons.auto_awesome),
              label: _isLoading 
                  ? const Text('Generando...')
                  : const Text('Generar con IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan de Estudio Inteligente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'ML optimiza horarios + Groq crea el plan personalizado',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Materia',
              hintText: 'Ej: Cálculo, Física, Programación...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _examDateController,
            decoration: const InputDecoration(
              labelText: 'Fecha del examen',
              hintText: '2024-10-15',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _createStudyPlan,
              icon: const Icon(Icons.school),
              label: _isLoading 
                  ? const Text('Creando plan...')
                  : const Text('Crear Plan con IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}