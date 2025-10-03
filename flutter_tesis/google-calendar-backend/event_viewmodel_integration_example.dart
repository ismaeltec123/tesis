// EJEMPLO DE INTEGRACIÓN CON TU EventViewModel EXISTENTE

import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/google_calendar_api_service.dart'; // El archivo que acabamos de crear
import '../models/event_model.dart';

class EventViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<EventModel> _events = [];
  bool _isLoading = false;
  bool _isGoogleAuthenticated = false;

  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  bool get isGoogleAuthenticated => _isGoogleAuthenticated;

  // Cargar eventos - AHORA CON SINCRONIZACIÓN AUTOMÁTICA
  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Verificar autenticación con Google
      _isGoogleAuthenticated = await GoogleCalendarApiService.isAuthenticated();
      
      // 2. Si está autenticado, sincronizar primero
      if (_isGoogleAuthenticated) {
        print('🔄 Sincronizando con Google Calendar...');
        final syncResult = await GoogleCalendarApiService.fullSync();
        print('✅ Sincronización completada: ${syncResult['message']}');
      }

      // 3. Cargar eventos de Firebase (ahora incluye los sincronizados)
      _events = await _firebaseService.getEvents();
      
    } catch (e) {
      print('Error cargando eventos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Agregar evento - AHORA SE SINCRONIZA AUTOMÁTICAMENTE CON GOOGLE
  Future<void> addEvent(EventModel event) async {
    try {
      if (_isGoogleAuthenticated) {
        // Opción 1: Usar la API que sincroniza automáticamente
        bool success = await GoogleCalendarApiService.createEvent(event);
        if (success) {
          print('✅ Evento creado y sincronizado con Google Calendar');
          // Recargar eventos para obtener el evento con Google ID
          await loadEvents();
        } else {
          throw Exception('Error creando evento en la API');
        }
      } else {
        // Opción 2: Crear solo en Firebase (como antes)
        await _firebaseService.addEvent(event);
        _events.add(event);
        print('📝 Evento creado solo en Firebase (Google no autenticado)');
      }
    } catch (e) {
      print('Error agregando evento: $e');
      rethrow;
    }
    notifyListeners();
  }

  // Actualizar evento
  Future<void> updateEvent(EventModel event) async {
    try {
      if (_isGoogleAuthenticated && event.id.isNotEmpty) {
        // Actualizar a través de la API (sincroniza automáticamente)
        bool success = await GoogleCalendarApiService.updateEvent(event.id, event);
        if (success) {
          await loadEvents(); // Recargar para obtener cambios
        }
      } else {
        // Actualizar solo en Firebase
        await _firebaseService.updateEvent(event);
        final index = _events.indexWhere((e) => e.id == event.id);
        if (index != -1) {
          _events[index] = event;
        }
      }
    } catch (e) {
      print('Error actualizando evento: $e');
      rethrow;
    }
    notifyListeners();
  }

  // Eliminar evento
  Future<void> deleteEvent(String eventId) async {
    try {
      if (_isGoogleAuthenticated) {
        // Eliminar a través de la API (elimina de ambos lugares)
        bool success = await GoogleCalendarApiService.deleteEvent(eventId);
        if (success) {
          _events.removeWhere((event) => event.id == eventId);
        }
      } else {
        // Eliminar solo de Firebase
        await _firebaseService.deleteEvent(eventId);
        _events.removeWhere((event) => event.id == eventId);
      }
    } catch (e) {
      print('Error eliminando evento: $e');
      rethrow;
    }
    notifyListeners();
  }

  // Autenticar con Google Calendar
  Future<String?> authenticateWithGoogle() async {
    try {
      String? authUrl = await GoogleCalendarApiService.getGoogleAuthUrl();
      return authUrl;
    } catch (e) {
      print('Error obteniendo URL de autenticación: $e');
      return null;
    }
  }

  // Sincronizar manualmente con Google Calendar
  Future<void> manualSync() async {
    if (!_isGoogleAuthenticated) {
      print('❌ No autenticado con Google Calendar');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await GoogleCalendarApiService.fullSync();
      print('🔄 Sincronización manual: ${result['message']}');
      
      // Recargar eventos después de sincronizar
      _events = await _firebaseService.getEvents();
      
    } catch (e) {
      print('Error en sincronización manual: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verificar estado de autenticación
  Future<void> checkGoogleAuth() async {
    _isGoogleAuthenticated = await GoogleCalendarApiService.isAuthenticated();
    notifyListeners();
  }
}

// CÓMO USAR EN TU INTERFAZ:

/*
// En tu CalendarView o donde manejes la autenticación:

class CalendarView extends StatefulWidget {
  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  
  @override
  void initState() {
    super.initState();
    // Verificar autenticación al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventViewModel>(context, listen: false).checkGoogleAuth();
    });
  }

  Widget build(BuildContext context) {
    return Consumer<EventViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Calendario'),
            actions: [
              // Botón de sincronización manual
              IconButton(
                icon: Icon(viewModel.isGoogleAuthenticated 
                  ? Icons.sync 
                  : Icons.sync_disabled),
                onPressed: viewModel.isGoogleAuthenticated 
                  ? () => viewModel.manualSync()
                  : () => _showGoogleAuthDialog(context, viewModel),
              ),
            ],
          ),
          body: Column(
            children: [
              // Indicador de estado de Google Calendar
              if (!viewModel.isGoogleAuthenticated)
                Container(
                  color: Colors.orange,
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No conectado a Google Calendar. Toca para conectar.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showGoogleAuthDialog(context, viewModel),
                        child: Text('CONECTAR', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              
              // Tu calendario existente...
              Expanded(
                child: // Tu widget de calendario actual
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGoogleAuthDialog(BuildContext context, EventViewModel viewModel) async {
    String? authUrl = await viewModel.authenticateWithGoogle();
    if (authUrl != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Conectar con Google Calendar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Para sincronizar con Google Calendar:'),
              SizedBox(height: 16),
              Text('1. Copia esta URL y ábrela en tu navegador'),
              SizedBox(height: 8),
              SelectableText(authUrl, style: TextStyle(fontSize: 12)),
              SizedBox(height: 16),
              Text('2. Autoriza la aplicación'),
              Text('3. Cierra este diálogo y recarga la app'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }
}
*/
