import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../viewmodels/event_viewmodel.dart';
import '../models/event_model.dart';
import '../widgets/ai_organizer_dialog.dart';
import '../widgets/enhanced_ai_dialog.dart';
import 'package:intl/intl.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class CalendarView extends StatefulWidget {
  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> with WidgetsBindingObserver {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Nueva variable para controlar la vista del calendario
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    
    // Cargar eventos y verificar estado de Google Calendar al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<EventViewModel>(context, listen: false);
      viewModel.loadEvents(); // Esto incluye la verificación de estado y sincronización
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Cuando el usuario regresa a la app (ej: después de autenticarse en el navegador)
    if (state == AppLifecycleState.resumed) {
      print('📱 App resumed - haciendo sync rápido...');
      final viewModel = Provider.of<EventViewModel>(context, listen: false);
      viewModel.quickSync(); // Sync rápido para detectar cambios
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtén los eventos del Provider
    final viewModel = Provider.of<EventViewModel>(context);
    final events = viewModel.events;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mi Calendario',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          // Indicador de estado de Google Calendar
          Consumer<EventViewModel>(
            builder: (context, viewModel, child) {
              if (!viewModel.isServerRunning) {
                return IconButton(
                  icon: const Icon(Icons.cloud_off, color: Colors.red),
                  onPressed: () => _showServerStatusDialog(context, viewModel),
                  tooltip: 'Servidor desconectado',
                );
              } else if (!viewModel.isGoogleAuthenticated) {
                return IconButton(
                  icon: const Icon(Icons.sync_disabled, color: Colors.orange),
                  onPressed: () => _showGoogleAuthDialog(context, viewModel),
                  tooltip: 'Google Calendar no autenticado',
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.sync, color: Colors.green),
                  onPressed: () => viewModel.manualSync(),
                  tooltip: 'Sincronizar con Google Calendar',
                );
              }
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.calendar_today, color: Color(0xFF00BCD4)),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de estado de Google Calendar
          Consumer<EventViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return Container(
                  color: Colors.blue[100],
                  padding: const EdgeInsets.all(12),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Sincronizando con Google Calendar...'),
                    ],
                  ),
                );
              } else if (!viewModel.isServerRunning) {
                return Container(
                  color: Colors.red[100],
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Servidor desconectado. Solo modo Firebase.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: () => viewModel.checkStatus(),
                        child: const Text('VERIFICAR'),
                      ),
                    ],
                  ),
                );
              } else if (!viewModel.isGoogleAuthenticated) {
                return Container(
                  color: Colors.orange[100],
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_disabled, color: Colors.orange, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Google Calendar no conectado. Toca para conectar.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showGoogleAuthDialog(context, viewModel),
                        child: const Text('CONECTAR'),
                      ),
                    ],
                  ),
                );
              } else if (viewModel.lastSyncMessage != null) {
                return Container(
                  color: Colors.green[100],
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.sync, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Google Calendar: ${viewModel.lastSyncMessage}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                      TextButton(
                        onPressed: () => viewModel.manualSync(),
                        child: const Text('SINCRONIZAR'),
                      ),
                      IconButton(
                        onPressed: () => viewModel.quickSync(),
                        icon: const Icon(Icons.refresh, color: Colors.green),
                        tooltip: 'Buscar eventos nuevos',
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF00BCD4),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(
                              _focusedDay.year,
                              _focusedDay.month - 1,
                            );
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy', 'es').format(_focusedDay)
                            .toLowerCase()
                            .capitalize(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Botón para cambiar vista
                      IconButton(
                        icon: Icon(
                          _calendarFormat == CalendarFormat.month 
                            ? Icons.view_agenda
                            : Icons.grid_view,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_calendarFormat == CalendarFormat.month) {
                              _calendarFormat = CalendarFormat.week;
                            } else {
                              _calendarFormat = CalendarFormat.month;
                            }
                          });
                        },
                        tooltip: _calendarFormat == CalendarFormat.month 
                          ? 'Vista Detallada'
                          : 'Vista Grid',
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(
                              _focusedDay.year,
                              _focusedDay.month + 1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
                TableCalendar<EventModel>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: const CalendarStyle(
                    defaultTextStyle: TextStyle(color: Colors.white),
                    weekendTextStyle: TextStyle(color: Colors.white70),
                    todayDecoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: TextStyle(color: Color(0xFF00BCD4)),
                    todayTextStyle: TextStyle(color: Colors.white),
                    outsideTextStyle: TextStyle(color: Colors.white60),
                    markerDecoration: BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                  ),
                  headerVisible: false,
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.white70),
                    weekendStyle: TextStyle(color: Colors.white70),
                  ),
                  eventLoader: (day) {
                    return events.where((event) =>
                      isSameDay(event.date, day)).toList();
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      // Si está en vista grid, cambiar a vista detallada al seleccionar día
                      if (_calendarFormat == CalendarFormat.month) {
                        _calendarFormat = CalendarFormat.week;
                      }
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: _calendarFormat == CalendarFormat.month 
              ? _buildGridViewEvents(events)
              : _buildDetailViewEvents(events)
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón Enhanced AI (ML + Groq)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6A1B9A),
                  Color(0xFF4A148C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A1B9A).withOpacity(0.4),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              elevation: 0,
              heroTag: "enhanced_ai",
              child: const Icon(
                Icons.psychology,
                size: 28,
                color: Colors.white,
              ),
              onPressed: () => _showEnhancedAIDialog(context),
            ),
          ),
          // Botón de Organizar con IA (Original)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF9C27B0),
                  Color(0xFF8E24AA),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9C27B0).withOpacity(0.4),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              elevation: 0,
              heroTag: "ai_organizer",
              child: const Icon(
                Icons.auto_awesome,
                size: 28,
                color: Colors.white,
              ),
              onPressed: () => _showAIDialog(context),
            ),
          ),
          // Botón agregar evento
          FloatingActionButton(
            backgroundColor: const Color(0xFF00BCD4),
            elevation: 8,
            heroTag: "add_event",
            child: const Icon(
              Icons.add,
              size: 32,
              color: Colors.white,
            ),
            onPressed: () => _showAddEventDialog(),
          ),
        ],
      ),
    );
  }

  // Vista Grid para cuando el calendario está en formato mensual
  Widget _buildGridViewEvents(List<EventModel> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.event_note,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay eventos este mes',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Toca un día para agregar un evento',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Agrupar eventos por fecha
    Map<DateTime, List<EventModel>> eventsByDate = {};
    for (var event in events) {
      DateTime dateKey = DateTime(event.date.year, event.date.month, event.date.day);
      if (eventsByDate[dateKey] == null) {
        eventsByDate[dateKey] = [];
      }
      eventsByDate[dateKey]!.add(event);
    }

    // Filtrar eventos del mes actual
    List<MapEntry<DateTime, List<EventModel>>> monthEvents = eventsByDate.entries
        .where((entry) => 
            entry.key.year == _focusedDay.year && 
            entry.key.month == _focusedDay.month)
        .toList();

    if (monthEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay eventos este mes',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: monthEvents.length,
      itemBuilder: (context, index) {
        final entry = monthEvents[index];
        final date = entry.key;
        final dayEvents = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha del día
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        DateFormat('EEE dd MMM', 'es').format(date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${dayEvents.length} evento${dayEvents.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Lista compacta de eventos
                ...dayEvents.map((event) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _eventColor(event.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _eventColor(event.type).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _eventColor(event.type),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('HH:mm').format(event.date),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        _eventIcon(event.type),
                        size: 16,
                        color: _eventColor(event.type),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Vista detallada para cuando el calendario está en formato semanal
  Widget _buildDetailViewEvents(List<EventModel> events) {
    final dayEvents = events.where((event) =>
        isSameDay(event.date, _selectedDay ?? DateTime.now())).toList();

    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay eventos para este día',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _eventColor(event.type).withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: _eventColor(event.type).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador de tiempo y tipo
                Container(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(event.date),
                        style: TextStyle(
                          color: _eventColor(_getDisplayType(event)),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('HH:mm').format(event.endTime),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Línea vertical de color
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _eventColor(_getDisplayType(event)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                // Contenido principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y tipo
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          // Badge del tipo de evento más visible
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 4
                            ),
                            decoration: BoxDecoration(
                              color: _eventColor(_getDisplayType(event)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _eventIcon(_getDisplayType(event)),
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getDisplayTypeLabel(event),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Descripción más visible
                      if (event.description.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.description,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.description,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Indicador de Google Calendar mejorado
                      if (event.type == 'importado')
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, 
                            vertical: 4
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_download,
                                size: 14,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Sincronizado con Google Calendar',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Botones de acción
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botón editar
                    GestureDetector(
                      onTap: () => _showEditEventDialog(event),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Botón eliminar
                    GestureDetector(
                      onTap: () => _showDeleteConfirmation(event),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Métodos auxiliares para colores y tipos
  Color _eventColor(String type) {
    switch (type) {
      case 'obligatorio':
        return const Color(0xFFEF4444);
      case 'trabajo':
        return const Color(0xFFDC2626);
      case 'recreativo':
        return const Color(0xFF2563EB);
      case 'personal':
        return const Color(0xFFEA580C);
      case 'importado':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'obligatorio':
        return Icons.assignment_rounded;
      case 'trabajo':
        return Icons.work_rounded;
      case 'recreativo':
        return Icons.sports_esports_rounded;
      case 'personal':
        return Icons.person_rounded;
      case 'importado':
        return Icons.cloud_download_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  String _getDisplayType(EventModel event) {
    return event.type;
  }

  String _getDisplayTypeLabel(EventModel event) {
    switch (event.type) {
      case 'obligatorio':
        return 'Obligatorio';
      case 'trabajo':
        return 'Trabajo';
      case 'recreativo':
        return 'Recreativo';
      case 'personal':
        return 'Personal';
      case 'importado':
        return 'Importado';
      default:
        return 'Evento';
    }
  }

  // Diálogos y funciones auxiliares (mantengo los existentes)
  void _showEnhancedAIDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedAIDialog(
        onEventsCreated: (events) {
          // Manejar eventos creados por AI
          for (var event in events) {
            _addEvent(event);
          }
        },
      ),
    );
  }

  void _showAIDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AIOrganizerDialog(
        selectedDate: _selectedDay ?? DateTime.now(),
        onEventsCreated: (events) {
          // Manejar eventos creados por AI
          for (var event in events) {
            _addEvent(event);
          }
        },
      ),
    );
  }

  void _showServerStatusDialog(BuildContext context, EventViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Servidor Desconectado'),
          ],
        ),
        content: const Text(
          'No se puede conectar con el servidor de sincronización. '
          'La app funcionará solo con Firebase hasta que se restablezca la conexión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.checkStatus();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _showGoogleAuthDialog(BuildContext context, EventViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sync_disabled, color: Colors.orange),
            SizedBox(width: 8),
            Text('Conectar Google Calendar'),
          ],
        ),
        content: const Text(
          '¿Deseas conectar tu cuenta de Google Calendar para sincronizar eventos automáticamente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.checkStatus();
            },
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    _titleController.clear();
    _descController.clear();
    
    DateTime dialogDate = _selectedDay ?? DateTime.now();
    DateTime dialogEndTime = dialogDate.add(const Duration(hours: 1));
    String dialogTitle = '';
    String dialogDescription = '';
    String dialogType = 'obligatorio';
    bool dialogReminder = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Agregar Evento',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Título del evento',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  onChanged: (value) => dialogTitle = value,
                ),
                const SizedBox(height: 16),
                
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  onChanged: (value) => dialogDescription = value,
                ),
                const SizedBox(height: 16),

                // Fecha y hora
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Fecha'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(dialogDate)),
                        leading: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dialogDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              dialogDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                dialogDate.hour,
                                dialogDate.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Hora inicio'),
                        subtitle: Text(DateFormat('HH:mm').format(dialogDate)),
                        leading: const Icon(Icons.access_time),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(dialogDate),
                          );
                          if (time != null) {
                            setState(() {
                              dialogDate = DateTime(
                                dialogDate.year,
                                dialogDate.month,
                                dialogDate.day,
                                time.hour,
                                time.minute,
                              );
                              dialogEndTime = dialogDate.add(const Duration(hours: 1));
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Hora fin'),
                        subtitle: Text(DateFormat('HH:mm').format(dialogEndTime)),
                        leading: const Icon(Icons.access_time_filled),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(dialogEndTime),
                          );
                          if (time != null) {
                            setState(() {
                              dialogEndTime = DateTime(
                                dialogEndTime.year,
                                dialogEndTime.month,
                                dialogEndTime.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Tipo de evento
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tipo de evento:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildEventTypeChip(
                      'obligatorio', 
                      'Obligatorio', 
                      Icons.assignment_rounded,
                      const Color(0xFFEF4444),
                      dialogType, 
                      setState,
                      (value) => dialogType = value
                    ),
                    _buildEventTypeChip(
                      'recreativo', 
                      'Recreativo', 
                      Icons.sports_esports_rounded,
                      const Color(0xFF2563EB),
                      dialogType, 
                      setState,
                      (value) => dialogType = value
                    ),
                    _buildEventTypeChip(
                      'trabajo', 
                      'Trabajo', 
                      Icons.work_rounded,
                      const Color(0xFFDC2626),
                      dialogType, 
                      setState,
                      (value) => dialogType = value
                    ),
                    _buildEventTypeChip(
                      'personal', 
                      'Personal', 
                      Icons.person_rounded,
                      const Color(0xFFEA580C),
                      dialogType, 
                      setState,
                      (value) => dialogType = value
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recordatorio
                CheckboxListTile(
                  title: const Text('Recordatorio'),
                  subtitle: const Text('Recibir notificación 30 minutos antes'),
                  value: dialogReminder,
                  onChanged: (value) {
                    setState(() {
                      dialogReminder = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogTitle.isNotEmpty) {
                  final event = EventModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: dialogTitle,
                    description: dialogDescription,
                    date: dialogDate,
                    endTime: dialogEndTime,
                    type: dialogType,
                    reminder: dialogReminder,
                  );
                  
                  Navigator.pop(context);
                  _addEvent(event);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeChip(
    String value, 
    String label, 
    IconData icon, 
    Color color,
    String currentType,
    StateSetter setState,
    Function(String) onChanged
  ) {
    final isSelected = currentType == value;
    return GestureDetector(
      onTap: () => setState(() => onChanged(value)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addEvent(EventModel event) async {
    final viewModel = Provider.of<EventViewModel>(context, listen: false);
    
    try {
      await viewModel.addEvent(event);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Evento "${event.title}" agregado exitosamente'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Error agregando evento: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showEditEventDialog(EventModel event) {
    DateTime dialogDate = event.date;
    DateTime dialogEndTime = event.endTime;
    String dialogTitle = event.title;
    String dialogDescription = event.description;
    String dialogType = event.type;
    bool dialogReminder = event.reminder;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Editar Evento',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Título del evento',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  controller: TextEditingController(text: dialogTitle),
                  onChanged: (value) => dialogTitle = value,
                ),
                const SizedBox(height: 16),
                
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  controller: TextEditingController(text: dialogDescription),
                  onChanged: (value) => dialogDescription = value,
                ),
                const SizedBox(height: 16),

                // Fecha y hora
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Fecha'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(dialogDate)),
                        leading: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dialogDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              dialogDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                dialogDate.hour,
                                dialogDate.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Hora inicio'),
                        subtitle: Text(DateFormat('HH:mm').format(dialogDate)),
                        leading: const Icon(Icons.access_time),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(dialogDate),
                          );
                          if (time != null) {
                            setState(() {
                              dialogDate = DateTime(
                                dialogDate.year,
                                dialogDate.month,
                                dialogDate.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Hora fin'),
                        subtitle: Text(DateFormat('HH:mm').format(dialogEndTime)),
                        leading: const Icon(Icons.access_time_filled),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(dialogEndTime),
                          );
                          if (time != null) {
                            setState(() {
                              dialogEndTime = DateTime(
                                dialogEndTime.year,
                                dialogEndTime.month,
                                dialogEndTime.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Tipo de evento
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tipo de evento:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildEventTypeChip(
                      'obligatorio', 
                      'Obligatorio', 
                      Icons.assignment_rounded,
                      const Color(0xFFEF4444),
                      dialogType, 
                      setState,
                      (value) => dialogType = value
                    ),
                    _buildEventTypeChip(
                      'recreativo', 
                      'Recreativo', 
                      Icons.sports_esports_rounded,
                      const Color(0xFF2563EB),
                      dialogType, 
                      setState,
                      (value) => dialogType = value
                    ),
                    _buildEventTypeChip(
                      'trabajo', 
                      'Trabajo', 
                      Icons.work_rounded,
                      const Color(0xFFDC2626),
                      dialogType, 
                      setState,
                      (value) => dialogType = value
                    ),
                    _buildEventTypeChip(
                      'personal', 
                      'Personal', 
                      Icons.person_rounded,
                      const Color(0xFFEA580C),
                      dialogType, 
                      setState,
                      (value) => dialogType = value
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recordatorio
                CheckboxListTile(
                  title: const Text('Recordatorio'),
                  subtitle: const Text('Recibir notificación 30 minutos antes'),
                  value: dialogReminder,
                  onChanged: (value) {
                    setState(() {
                      dialogReminder = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogTitle.isNotEmpty) {
                  final updatedEvent = EventModel(
                    id: event.id,
                    title: dialogTitle,
                    description: dialogDescription,
                    date: dialogDate,
                    endTime: dialogEndTime,
                    type: dialogType,
                    reminder: dialogReminder,
                  );
                  
                  Navigator.pop(context);
                  _updateEvent(updatedEvent);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateEvent(EventModel event) async {
    final viewModel = Provider.of<EventViewModel>(context, listen: false);
    
    try {
      await viewModel.updateEvent(event);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Evento "${event.title}" actualizado exitosamente'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Error actualizando evento: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showDeleteConfirmation(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Evento'),
        content: Text('¿Estás seguro que deseas eliminar "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(event);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteEvent(EventModel event) async {
    final viewModel = Provider.of<EventViewModel>(context, listen: false);
    
    try {
      await viewModel.deleteEvent(event.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Evento "${event.title}" eliminado exitosamente'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Error eliminando evento: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}