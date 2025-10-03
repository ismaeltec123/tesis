import '../models/event_model.dart';

class ScheduleService {
  
  // Horario del estudiante Quispe Arias, Ismael (Código 117334)
  static List<EventModel> generateStudentSchedule() {
    List<EventModel> events = [];
    
    // Fecha de inicio: Lunes 6 de octubre de 2025
    DateTime startDate = DateTime(2025, 10, 6);
    
    // Generar eventos para 16 semanas (1 semestre)
    for (int week = 0; week < 16; week++) {
      DateTime currentWeek = startDate.add(Duration(days: week * 7));
      
      // LUNES
      // 08:00 - 09:40 C43266 Sistema de negocios inteligentes con BI
      events.add(_createWeeklyEvent(
        currentWeek, // Lunes
        '08:00',
        '09:40',
        'C43266',
        'Sistema de negocios inteligentes con BI',
        '410',
        week
      ));
      
      // MARTES  
      // 04:20 - 07:40 C35076 Seminario de desarrollo web integral semanal
      events.add(_createWeeklyEvent(
        currentWeek.add(Duration(days: 1)), // Martes
        '16:20',
        '19:40',
        'C35076',
        'Seminario de desarrollo web integral',
        '1205',
        week
      ));

      // MIÉRCOLES
      // 06:50 - 08:30 C43245 Gestión de servicio de software síncrona 12
      events.add(_createWeeklyEvent(
        currentWeek.add(Duration(days: 2)), // Miércoles
        '18:50',
        '20:30',
        'C43245',
        'Gestión de servicio de software',
        'Síncrona 12',
        week
      ));

      // 06:00 - 07:40 C37305 Metodologías ágiles de desarrollo de software semanal
      events.add(_createWeeklyEvent(
        currentWeek.add(Duration(days: 2)), // Miércoles  
        '18:00',
        '19:40',
        'C37305',
        'Metodologías ágiles de desarrollo de software',
        '1006',
        week
      ));

      // JUEVES
      // 05:10 - 06:00 C43296 Desarrollo de sistemas de información web semanal  
      events.add(_createWeeklyEvent(
        currentWeek.add(Duration(days: 3)), // Jueves
        '17:10',
        '18:00',
        'C43296',
        'Desarrollo de sistemas de información web',
        '1506',
        week
      ));

      // 04:20 - 06:00 C43245 Gestión de servicio de software semanal
      events.add(_createWeeklyEvent(
        currentWeek.add(Duration(days: 3)), // Jueves
        '16:20',
        '18:00',
        'C43245',
        'Gestión de servicio de software',
        '1384',
        week
      ));

      // 06:00 - 07:40 C43296 Desarrollo de sistemas de información web semanal
      events.add(_createWeeklyEvent(
        currentWeek.add(Duration(days: 3)), // Jueves
        '18:00',
        '19:40',
        'C43296',
        'Desarrollo de sistemas de información web',
        'Síncrona 3',
        week
      ));

      // VIERNES
      // 08:30 - 10:10 G62030 Sociedad y desarrollo sostenible semanal
      events.add(_createWeeklyEvent(
        currentWeek.add(Duration(days: 4)), // Viernes
        '08:30',
        '10:10',
        'G62030',
        'Sociedad y desarrollo sostenible',
        'Síncrona 1',
        week
      ));

      // SÁBADO
      // 09:00 - 09:40 C43245 Gestión de servicio de software semanal
      events.add(_createWeeklyEvent(
        currentWeek.add(Duration(days: 5)), // Sábado
        '09:00',
        '09:40',
        'C43245',
        'Gestión de servicio de software',
        '418',
        week
      ));

      // 09:40 - 12:10 C43245 Gestión de servicio de software semanal  
      events.add(_createWeeklyEvent(
        currentWeek.add(Duration(days: 5)), // Sábado
        '09:40',
        '12:10',
        'C43245',
        'Gestión de servicio de software',
        '418',
        week
      ));

      // 14:40 - 15:19 C43246 Integración de sistemas empresariales avanzado semanal
      events.add(_createWeeklyEvent(
        currentWeek.add(Duration(days: 5)), // Sábado
        '14:40',
        '15:19',
        'C43246',
        'Integración de sistemas empresariales avanzado',
        'Síncrona 18',
        week
      ));
    }
    
    return events;
  }
  
  static EventModel _createWeeklyEvent(
    DateTime date,
    String startTime,
    String endTime, 
    String courseCode,
    String courseName,
    String room,
    int week
  ) {
    // Parsear hora de inicio
    List<String> startParts = startTime.split(':');
    DateTime startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(startParts[0]),
      int.parse(startParts[1])
    );
    
    // Parsear hora de fin
    List<String> endParts = endTime.split(':');
    DateTime endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(endParts[0]),
      int.parse(endParts[1])
    );
    
    return EventModel(
      id: '${courseCode}_${date.millisecondsSinceEpoch}_$week',
      title: '$courseCode - $courseName',
      description: 'Aula: $room\nCódigo: $courseCode\nEstudiante: Quispe Arias, Ismael (117334)\nEspecialidad: Diseño y Desarrollo de Software\nCiclo: 8vo.',
      date: startDateTime,
      endTime: endDateTime,
      type: 'obligatorio',
      reminder: true,
    );
  }
  
  // Obtener resumen del horario
  static Map<String, dynamic> getScheduleSummary() {
    return {
      'student': {
        'name': 'Quispe Arias, Ismael',
        'code': '117334',
        'specialty': 'Diseño y Desarrollo de Software',
        'cycle': '8vo. Ciclo'
      },
      'courses': [
        {
          'code': 'C39312',
          'name': 'CONSULTORÍA Y DESARROLLO PROFESIONAL',
          'professor': 'CAMPOVERDE GUERRERO, MARCOS NOEL',
          'section': 'C24 - 6 - C'
        },
        {
          'code': 'C43295',
          'name': 'DESARROLLO DE APLICACIONES EMPRESARIALES AVANZADO',
          'professor': 'TORRES CRUZ, HUGO FELIPE', 
          'section': 'C24 - 5 - C'
        },
        {
          'code': 'C37385',
          'name': 'EMPRENDIMIENTO',
          'professor': 'DULANTO FLORES, TOMAS TEOBALDO YOSIMAR',
          'section': 'C24 - 6 - C'
        },
        {
          'code': 'C43478',
          'name': 'EXPERIENCIAS FORMATIVAS EN SITUACIONES REALES DE TRABAJO 6',
          'professor': '',
          'section': 'C24 - 6 - C'
        },
        {
          'code': 'C43245',
          'name': 'GESTIÓN DE SERVICIO DE SOFTWARE',
          'professor': 'MONTOYA SALDAÑA, SILVIA MARIANA',
          'section': 'C24 - 6 - C'
        },
        {
          'code': 'C43246',
          'name': 'INTEGRACIÓN DE SISTEMAS EMPRESARIALES AVANZADO',
          'professor': 'ESTRADA DONAYRE, PERCY',
          'section': 'C24 - 6 - C'
        },
        {
          'code': 'C43296',
          'name': 'INTELIGENCIA DE NEGOCIOS',
          'professor': 'ALVAREZ CHANCASANAMPA, JURGEN',
          'section': 'C24 - 6 - C'
        },
        {
          'code': 'G62030',
          'name': 'SOCIEDAD Y DESARROLLO SOSTENIBLE',
          'professor': 'CASTILLO VARGAS, CARLOS ALBERTO',
          'section': 'C24 - 6 - C'
        },
        {
          'code': 'C35076',
          'name': 'START UP VENTURE PROJECT',
          'professor': 'GHIRI RICSE, MANUEL FERNANDO',
          'section': ''
        },
        {
          'code': 'C84479',
          'name': 'TUTORÍA 6',
          'professor': 'MONTOYA SALDAÑA, SILVIA MARIANA',
          'section': 'C24 - 6 - C'
        }
      ]
    };
  }
}