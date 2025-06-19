import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../viewmodels/event_viewmodel.dart';
import '../models/event_model.dart';
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

class _CalendarViewState extends State<CalendarView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _type = 'obligatorio';
  bool _reminder = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Home page'),
        actions: [
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
                  calendarFormat: CalendarFormat.week,
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
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: events.isEmpty 
              ? Center(
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
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    if (!isSameDay(event.date, _selectedDay ?? DateTime.now())) {
                      return const SizedBox.shrink();
                    }
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _eventColor(event.type).withOpacity(0.2),
                          child: Icon(_eventIcon(event.type),
                              color: _eventColor(event.type)),
                        ),
                        title: Text(event.title,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(event.description),
                        trailing: Text(
                          DateFormat('HH:mm').format(event.date),
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
        onPressed: () => _showAddDialog(context),
      ),
    );
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'obligatorio':
        return Icons.star;
      case 'estudio':
        return Icons.school;
      case 'recreativo':
        return Icons.sports_esports;
      default:
        return Icons.event;
    }
  }

  Color _eventColor(String type) {
    switch (type) {
      case 'obligatorio':
        return Colors.deepPurple;
      case 'estudio':
        return Colors.green;
      case 'recreativo':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showAddDialog(BuildContext context) {
    // Usar las variables de clase directamente
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
    String dialogType = _type;
    bool dialogReminder = _reminder;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Calendario superior
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                                    onPressed: () {},
                                  ),
                                  Text(
                                    DateFormat('MMMM yyyy', 'es')
                                        .format(selectedDate)
                                        .capitalize(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                            // Mini calendario semanal
                            GridView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1,
                              ),
                              itemCount: 7,
                              itemBuilder: (context, index) {
                                final day = selectedDate.subtract(
                                  Duration(days: selectedDate.weekday - index - 1),
                                );
                                return Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isSameDay(day, selectedDate)
                                        ? Colors.white
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        color: isSameDay(day, selectedDate)
                                            ? Colors.blue
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Formulario
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: 'Nombre del evento',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese un título';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descController,
                              decoration: InputDecoration(
                                hintText: 'Agregar una nota...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            // Selector de fecha y hora
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: startTime,
                                      );
                                      if (time != null) setState(() => startTime = time);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 20),
                                          const SizedBox(width: 8),
                                          Text('Inicio: ${startTime.format(context)}'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: endTime,
                                      );
                                      if (time != null) setState(() => endTime = time);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 20),
                                          const SizedBox(width: 8),
                                          Text('Fin: ${endTime.format(context)}'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Switch para recordatorio actualizado
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Recordarme'),
                                  Switch(
                                    value: dialogReminder,
                                    onChanged: (value) {
                                      setState(() {
                                        dialogReminder = value;
                                      });
                                    },
                                    activeColor: Colors.blue,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Categorías actualizadas
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Obligatorio'),
                                  selected: dialogType == 'obligatorio',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => dialogType = 'obligatorio');
                                    }
                                  },
                                  backgroundColor: Colors.grey[100],
                                  selectedColor: Colors.blue.withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: dialogType == 'obligatorio' ? Colors.blue : Colors.black,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Estudio'),
                                  selected: dialogType == 'estudio',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => dialogType = 'estudio');
                                    }
                                  },
                                  backgroundColor: Colors.grey[100],
                                  selectedColor: Colors.blue.withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: dialogType == 'estudio' ? Colors.blue : Colors.black,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Recreativo'),
                                  selected: dialogType == 'recreativo',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => dialogType = 'recreativo');
                                    }
                                  },
                                  backgroundColor: Colors.grey[100],
                                  selectedColor: Colors.blue.withOpacity(0.2),
                                  labelStyle: TextStyle(
                                    color: dialogType == 'recreativo' ? Colors.blue : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Botón crear evento actualizado
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final newEvent = EventModel(
                                    id: DateTime.now().toString(),
                                    title: _titleController.text,
                                    description: _descController.text,
                                    date: DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      startTime.hour,
                                      startTime.minute,
                                    ),
                                    endTime: DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      endTime.hour,
                                      endTime.minute,
                                    ),
                                    type: dialogType,
                                    reminder: dialogReminder,
                                  );

                                  Provider.of<EventViewModel>(context, listen: false)
                                      .addEvent(newEvent);

                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text(
                                'Crear evento',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}