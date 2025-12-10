import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/teacher/teacher_models.dart';
import '../models/teacher/teacher_templates.dart';
import '../config/app_config.dart';

class TeacherScheduleService {
  static const String _importedSchedulesKey = 'teacher_imported_schedules';
  static const String _hasImportedSchedulesKey = 'teacher_has_imported_schedules';
  
  // Singleton pattern
  static final TeacherScheduleService _instance = TeacherScheduleService._internal();
  factory TeacherScheduleService() => _instance;
  TeacherScheduleService._internal();

  /// Obtiene todos los horarios (importados o templates)
  Future<List<ClassSchedule>> getAllSchedules() async {
    if (await hasImportedSchedules()) {
      return await getImportedSchedules();
    } else {
      return ClassScheduleTemplate.getMockSchedule();
    }
  }

  /// Obtiene horarios para un día específico
  Future<List<ClassSchedule>> getScheduleForDay(String dayOfWeek) async {
    final allSchedules = await getAllSchedules();
    return allSchedules
        .where((schedule) => schedule.dayOfWeek == dayOfWeek)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Verifica si hay horarios importados
  Future<bool> hasImportedSchedules() async {
    try {
      // Siempre usar modo local para evitar errores de Firestore
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasImportedSchedulesKey) ?? false;
    } catch (e) {
      print('❌ Error verificando horarios importados: $e');
      return false;
    }
  }

  /// Guarda horarios importados
  Future<void> saveImportedSchedules(List<Map<String, dynamic>> schedules, {
    String? teacherId,
    String? section,
    String? note,
  }) async {
    try {
      // Siempre usar modo local para evitar errores de Firestore
      print('💾 Guardando horarios en modo local...');
      await _saveSchedulesLocally(schedules, teacherId: teacherId, section: section, note: note);
    } catch (e) {
      print('❌ Error guardando horarios: $e');
      throw e;
    }
  }

  /// Obtiene horarios importados
  Future<List<ClassSchedule>> getImportedSchedules() async {
    try {
      if (AppConfig.useLocalMode) {
        return await _getSchedulesLocally();
      } else {
        // Siempre usar modo local para evitar errores de Firestore
        print('🔄 Usando modo local para obtener schedules');
        return await _getSchedulesLocally();
      }
    } catch (e) {
      print('❌ Error obteniendo schedules, usando modo local: $e');
      // Si hay cualquier error, obtener localmente como respaldo
      return await _getSchedulesLocally();
    }
  }

  /// Elimina todos los horarios importados
  Future<void> clearImportedSchedules() async {
    try {
      // Siempre usar modo local para evitar errores de Firestore
      print('🧹 Limpiando horarios en modo local...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_importedSchedulesKey);
      await prefs.setBool(_hasImportedSchedulesKey, false);
      print('✅ Horarios locales limpiados');
    } catch (e) {
      print('❌ Error limpiando horarios: $e');
      throw e;
    }
  }

  /// Guarda horarios localmente
  Future<void> _saveSchedulesLocally(List<Map<String, dynamic>> schedules, {
    String? teacherId,
    String? section,
    String? note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    print('🔍 Debug TeacherScheduleService - Guardando horarios:');
    print('📊 Total horarios a guardar: ${schedules.length}');
    
    final List<Map<String, dynamic>> schedulesToSave = schedules.map((scheduleData) {
      print('📋 Procesando horario: $scheduleData');
      
      // Preservar TODOS los campos originales del OCR
      final processedSchedule = Map<String, dynamic>.from(scheduleData);
      
      // Agregar campos estándar si no existen
      processedSchedule['id'] = scheduleData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      processedSchedule['subject_id'] = scheduleData['subject_id'] ?? scheduleData['course'] ?? '';
      processedSchedule['subject_name'] = scheduleData['subject_name'] ?? scheduleData['course'] ?? 'Sin nombre';
      processedSchedule['day_of_week'] = scheduleData['day_of_week'] ?? scheduleData['day'] ?? '';
      processedSchedule['start_time'] = scheduleData['start_time'] ?? '';
      processedSchedule['end_time'] = scheduleData['end_time'] ?? '';
      processedSchedule['classroom'] = scheduleData['classroom'] ?? '';
      processedSchedule['teacher_id'] = teacherId;
      processedSchedule['section'] = section;
      processedSchedule['note'] = note;
      processedSchedule['imported_at'] = DateTime.now().toIso8601String();
      
      print('✅ Horario procesado con ${processedSchedule.keys.length} campos');
      return processedSchedule;
    }).toList();

    await prefs.setString(_importedSchedulesKey, json.encode(schedulesToSave));
    await prefs.setBool(_hasImportedSchedulesKey, true);
    
    print('💾 Horarios guardados en SharedPreferences');
  }

  /// Guarda horarios en Firestore
  Future<void> _saveSchedulesToFirestore(List<Map<String, dynamic>> schedules, {
    String? teacherId,
    String? section,
    String? note,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('teacher_schedules');

      // Primero limpiar horarios anteriores del mismo profesor
      if (teacherId != null) {
        final existingSchedules = await collection
            .where('teacher_id', isEqualTo: teacherId)
            .get();
        
        for (final doc in existingSchedules.docs) {
          batch.delete(doc.reference);
        }
      }

      // Agregar nuevos horarios
      for (final scheduleData in schedules) {
        final docRef = collection.doc();
        final classSchedule = ClassSchedule(
          id: docRef.id,
          subjectId: scheduleData['subject_id'] ?? '',
          subjectName: scheduleData['subject_name'] ?? 'Sin nombre',
          dayOfWeek: scheduleData['day_of_week'] ?? '',
          startTime: scheduleData['start_time'] ?? '',
          endTime: scheduleData['end_time'] ?? '',
          classroom: scheduleData['classroom'] ?? '',
          building: scheduleData['building'],
        );

        batch.set(docRef, {
          ...classSchedule.toJson(),
          'teacher_id': teacherId,
          'section': section,
          'imported_at': FieldValue.serverTimestamp(),
          'note': note,
          'code': scheduleData['code'] ?? '',
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error saving schedules to Firestore: $e');
      throw e;
    }
  }

  /// Obtiene horarios localmente
  Future<List<ClassSchedule>> _getSchedulesLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final schedulesJson = prefs.getString(_importedSchedulesKey);
    
    print('🔍 Debug _getSchedulesLocally:');
    print('📄 SchedulesJson encontrado: ${schedulesJson != null}');
    
    if (schedulesJson == null) {
      print('❌ No hay horarios guardados en SharedPreferences');
      return [];
    }
    
    try {
      final List<dynamic> schedulesList = json.decode(schedulesJson);
      print('📊 Total horarios en storage: ${schedulesList.length}');
      
      final result = schedulesList.map((data) {
        final Map<String, dynamic> scheduleMap = Map<String, dynamic>.from(data);
        print('📋 Cargando horario: $scheduleMap');
        
        final schedule = ClassSchedule(
          id: scheduleMap['id'] ?? '',
          subjectId: scheduleMap['subject_id'] ?? '',
          subjectName: scheduleMap['subject_name'] ?? 'Sin nombre',
          dayOfWeek: scheduleMap['day_of_week'] ?? '',
          startTime: scheduleMap['start_time'] ?? '',
          endTime: scheduleMap['end_time'] ?? '',
          classroom: scheduleMap['classroom'] ?? '',
          building: scheduleMap['building'],
        );
        
        print('✅ ClassSchedule creado: ${schedule.toJson()}');
        return schedule;
      }).toList();
      
      print('🎯 Retornando ${result.length} horarios');
      return result;
    } catch (e) {
      print('❌ Error parsing local schedules: $e');
      return [];
    }
  }

  /// Obtiene horarios de Firestore
  Future<List<ClassSchedule>> _getSchedulesFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('teacher_schedules')
          .orderBy('day_of_week')
          .orderBy('start_time')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ClassSchedule(
          id: doc.id,
          subjectId: data['subject_id'] ?? '',
          subjectName: data['subject_name'] ?? 'Sin nombre',
          dayOfWeek: data['day_of_week'] ?? '',
          startTime: data['start_time'] ?? '',
          endTime: data['end_time'] ?? '',
          classroom: data['classroom'] ?? '',
          building: data['building'],
        );
      }).toList();
    } catch (e) {
      print('Error getting schedules from Firestore: $e');
      return [];
    }
  }

  /// Obtiene información adicional de un horario importado
  Future<Map<String, dynamic>?> getScheduleMetadata() async {
    if (AppConfig.useLocalMode) {
      final prefs = await SharedPreferences.getInstance();
      final schedulesJson = prefs.getString(_importedSchedulesKey);
      
      if (schedulesJson != null) {
        try {
          final List<dynamic> schedulesList = json.decode(schedulesJson);
          if (schedulesList.isNotEmpty) {
            final firstSchedule = Map<String, dynamic>.from(schedulesList.first);
            return {
              'imported_at': firstSchedule['imported_at'],
              'teacher_id': firstSchedule['teacher_id'],
              'section': firstSchedule['section'],
              'note': firstSchedule['note'],
              'total_schedules': schedulesList.length,
            };
          }
        } catch (e) {
          print('Error parsing schedule metadata: $e');
        }
      }
    } else {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('teacher_schedules')
            .limit(1)
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          final totalSnapshot = await FirebaseFirestore.instance
              .collection('teacher_schedules')
              .get();
          
          return {
            'imported_at': data['imported_at'],
            'teacher_id': data['teacher_id'],
            'section': data['section'],
            'note': data['note'],
            'total_schedules': totalSnapshot.docs.length,
          };
        }
      } catch (e) {
        print('Error getting schedule metadata from Firestore: $e');
      }
    }
    
    return null;
  }

  /// Exporta horarios al calendario principal (Google Calendar)
  Future<void> exportToCalendar() async {
    try {
      print('📅 Iniciando exportación a Google Calendar...');
      
      // Obtener horarios guardados de SharedPreferences (con datos completos del OCR)
      final prefs = await SharedPreferences.getInstance();
      final schedulesJson = prefs.getString(_importedSchedulesKey);
      
      if (schedulesJson == null) {
        throw Exception('No hay horarios para exportar');
      }
      
      final List<dynamic> schedulesList = json.decode(schedulesJson);
      print('📊 Total horarios a exportar: ${schedulesList.length}');
      
      // Separar por semana Par/Impar
      final imparSchedules = schedulesList
          .where((s) => (s['week_type'] ?? '').toString().toLowerCase().contains('impar'))
          .toList();
      final parSchedules = schedulesList
          .where((s) => (s['week_type'] ?? '').toString().toLowerCase().contains('par'))
          .toList();
      
      print('📋 Horarios Impar: ${imparSchedules.length}');
      print('📋 Horarios Par: ${parSchedules.length}');
      
      // Obtener fecha de inicio (lunes de la semana actual)
      final now = DateTime.now();
      DateTime startDate = now;
      
      // Encontrar el lunes de esta semana
      while (startDate.weekday != DateTime.monday) {
        startDate = startDate.subtract(const Duration(days: 1));
      }
      
      print('📆 Fecha de inicio: ${startDate.toString().split(' ')[0]}');
      
      // Mapeo de días español a número de día de la semana
      final Map<String, int> dayMap = {
        'Lunes': DateTime.monday,
        'Martes': DateTime.tuesday,
        'Miércoles': DateTime.wednesday,
        'Miercoles': DateTime.wednesday, // Sin tilde
        'Jueves': DateTime.thursday,
        'Viernes': DateTime.friday,
        'Sábado': DateTime.saturday,
        'Sabado': DateTime.saturday, // Sin tilde
        'Domingo': DateTime.sunday,
      };
      
      // Crear eventos para 4 semanas: Impar, Par, Impar, Par
      final List<Map<String, dynamic>> eventsToCreate = [];
      
      for (int weekNumber = 0; weekNumber < 4; weekNumber++) {
        final isImparWeek = weekNumber % 2 == 0; // Semana 0 y 2 son Impar
        final schedulesToUse = isImparWeek ? imparSchedules : parSchedules;
        final weekLabel = isImparWeek ? 'Impar' : 'Par';
        
        print('\n📅 Procesando Semana ${weekNumber + 1} ($weekLabel)');
        
        for (final schedule in schedulesToUse) {
          final day = schedule['day'] ?? schedule['day_of_week'] ?? '';
          final dayNumber = dayMap[day];
          
          if (dayNumber == null) {
            print('⚠️ Día no reconocido: $day');
            continue;
          }
          
          // Calcular fecha específica
          final daysToAdd = (weekNumber * 7) + (dayNumber - DateTime.monday);
          final eventDate = startDate.add(Duration(days: daysToAdd));
          
          // Parsear horarios
          final startTime = schedule['start_time'] ?? '';
          final endTime = schedule['end_time'] ?? '';
          
          if (startTime.isEmpty || endTime.isEmpty) {
            print('⚠️ Horarios inválidos para: $schedule');
            continue;
          }
          
          // Convertir "07:10" a DateTime
          final startParts = startTime.split(':');
          final endParts = endTime.split(':');
          
          final startDateTime = DateTime(
            eventDate.year,
            eventDate.month,
            eventDate.day,
            int.parse(startParts[0]),
            int.parse(startParts[1]),
          );
          
          final endDateTime = DateTime(
            eventDate.year,
            eventDate.month,
            eventDate.day,
            int.parse(endParts[0]),
            int.parse(endParts[1]),
          );
          
          // Obtener nomenclatura del evento (si existe) o crear una
          final course = schedule['course'] ?? schedule['subject_name'] ?? 'Clase';
          final classroom = schedule['classroom'] ?? '';
          final section = schedule['section'] ?? '';
          final subgroup = schedule['subgroup'] ?? '';
          final teacher = schedule['teacher'] ?? '';
          
          // Formato: "TAL[TB2][4D1O(A-B) Lun]-P.PERALTA-DiayRendelMotDié"
          // O usar nomenclatura si ya existe
          String eventTitle = schedule['nomenclatura'] ?? schedule['nomenclature'] ?? 
            '$course - $classroom - $section';
          
          final eventData = {
            'summary': eventTitle,
            'location': classroom,
            'description': 'Sección: $section\nDocente: $teacher\nSubgrupo: $subgroup\nSemana: $weekLabel',
            'start': {
              'dateTime': startDateTime.toIso8601String(),
              'timeZone': 'America/Lima',
            },
            'end': {
              'dateTime': endDateTime.toIso8601String(),
              'timeZone': 'America/Lima',
            },
            'colorId': '9', // Azul para clases
          };
          
          eventsToCreate.add(eventData);
          print('✅ Evento creado: $eventTitle - ${eventDate.toString().split(' ')[0]} $startTime-$endTime');
        }
      }
      
      print('📊 Total eventos a crear: ${eventsToCreate.length}');
      
      // Marcar todos los eventos como tipo "obligatorio"
      for (var event in eventsToCreate) {
        event['type'] = 'obligatorio';
      }
      
      // Enviar eventos al backend para crear en Google Calendar
      if (eventsToCreate.isNotEmpty) {
        await _sendEventsToBackend(eventsToCreate);
      }
      
      print('✅ Exportación completada exitosamente');
    } catch (e) {
      print('❌ Error exportando al calendario: $e');
      throw e;
    }
  }
  
  /// Envía eventos al backend para crear en Google Calendar
  Future<void> _sendEventsToBackend(List<Map<String, dynamic>> events) async {
    try {
      print('🚀 Enviando ${events.length} eventos al backend...');
      
      final url = Uri.parse('http://localhost:8001/api/calendar/events/batch');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'events': events}),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        print('✅ Eventos creados exitosamente: ${result['created_count'] ?? events.length}');
      } else {
        throw Exception('Error del servidor: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error enviando eventos al backend: $e');
      throw e;
    }
  }

  /// Obtiene estadísticas del horario actual
  Future<Map<String, dynamic>> getScheduleStats() async {
    final schedules = await getAllSchedules();
    final Map<String, int> dayCount = {};
    final Map<String, List<String>> timeSlots = {};
    
    for (final schedule in schedules) {
      // Contar por día
      dayCount[schedule.dayOfWeek] = (dayCount[schedule.dayOfWeek] ?? 0) + 1;
      
      // Recopilar horarios
      if (!timeSlots.containsKey(schedule.dayOfWeek)) {
        timeSlots[schedule.dayOfWeek] = [];
      }
      timeSlots[schedule.dayOfWeek]!.add('${schedule.startTime}-${schedule.endTime}');
    }
    
    return {
      'total_classes': schedules.length,
      'day_count': dayCount,
      'time_slots': timeSlots,
      'has_imported': await hasImportedSchedules(),
      'metadata': await getScheduleMetadata(),
    };
  }
}