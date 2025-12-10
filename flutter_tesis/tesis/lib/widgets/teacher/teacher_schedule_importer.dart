import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import '../../services/teacher_schedule_service.dart';

class TeacherScheduleImporter extends StatefulWidget {
  final String teacherId;
  final String backendUrl;
  
  const TeacherScheduleImporter({
    Key? key,
    this.teacherId = 'teacher_ejemplo_001',
    this.backendUrl = 'http://localhost:8001', // Puerto del backend
  }) : super(key: key);

  @override
  State<TeacherScheduleImporter> createState() => _TeacherScheduleImporterState();
}

class _TeacherScheduleImporterState extends State<TeacherScheduleImporter> {
  Uint8List? _imageBytes;
  String? _fileName;
  bool _processing = false;
  String _section = '5C24A';
  final List<String> _sections = ['Todas', '5C24A', '5C24B', '5C24C'];
  final TextEditingController _noteController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
        allowedExtensions: null,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      
      // Validar tamaño de archivo (max 10MB)
      if (file.size > 10 * 1024 * 1024) {
        _showSnack('El archivo es demasiado grande. Máximo 10MB.');
        return;
      }

      setState(() {
        _imageBytes = file.bytes;
        _fileName = file.name;
      });
      
      _showSnack('Imagen seleccionada: ${file.name}');
    } catch (e) {
      _showSnack('Error al seleccionar archivo: $e');
    }
  }

  Future<void> _parseAndImportSchedule() async {
    if (_imageBytes == null) {
      _showSnack('Seleccione primero una imagen.');
      return;
    }

    setState(() => _processing = true);

    try {
      // Primero probar conectividad básica
      try {
        final testUri = Uri.parse('${widget.backendUrl}');
        final testResponse = await http.get(testUri);
        print('🔍 Test de conectividad: ${testResponse.statusCode}');
      } catch (e) {
        print('❌ Error de conectividad: $e');
        _showSnack('Error de conexión al servidor: $e');
        setState(() => _processing = false);
        return;
      }

      // Crear la petición multipart
      final uri = Uri.parse('${widget.backendUrl}/api/schedule-parser/parse-schedule');
      print('🔗 URL del endpoint: ${uri.toString()}');
      final request = http.MultipartRequest('POST', uri);
      
      // Agregar headers
      request.headers['Accept'] = 'application/json';
      
      // Agregar campos
      request.fields['teacher_id'] = widget.teacherId;
      request.fields['section'] = _section == 'Todas' ? '' : _section;
      request.fields['note'] = _noteController.text.trim();
      // REMOVIDO: week_type - ahora importamos TODAS las semanas
      
      // Agregar archivo con content type explícito
      String contentType = 'image/png';
      if (_fileName != null) {
        if (_fileName!.toLowerCase().endsWith('.jpg') || _fileName!.toLowerCase().endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        } else if (_fileName!.toLowerCase().endsWith('.png')) {
          contentType = 'image/png';
        }
      }
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', 
          _imageBytes!, 
          filename: _fileName ?? 'schedule.png',
          contentType: http_parser.MediaType.parse(contentType),
        )
      );

      // Enviar petición
      print('🚀 Enviando imagen al backend: ${uri.toString()}');
      print('📋 Campos enviados: ${request.fields}');
      print('📦 Archivos enviados: ${request.files.length}');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Respuesta del servidor: ${response.statusCode}');
      print('📄 Headers de respuesta: ${response.headers}');
      print('📝 Cuerpo de respuesta: ${response.body}');

      if (response.statusCode != 200) {
        String errorMsg = 'Error del servidor: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorJson = jsonDecode(response.body);
            errorMsg += ' - ${errorJson['detail'] ?? errorJson['message'] ?? response.reasonPhrase}';
          } catch (e) {
            errorMsg += ' - ${response.reasonPhrase}';
          }
        }
        _showSnack(errorMsg);
        setState(() => _processing = false);
        return;
      }

      // Procesar respuesta
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final List<dynamic> schedules = responseBody['schedules'] ?? [];

      print('🔍 Debug - Horarios recibidos del backend:');
      print('📊 Total horarios: ${schedules.length}');
      for (int i = 0; i < schedules.length; i++) {
        print('📋 Horario $i: ${schedules[i]}');
      }

      if (schedules.isEmpty) {
        _showSnack('No se detectaron clases en la imagen.');
        setState(() => _processing = false);
        return;
      }

      // Guardar horarios en Firestore o localmente según configuración
      await _saveSchedulesToStorage(schedules);

      // Limpiar UI
      setState(() {
        _imageBytes = null;
        _fileName = null;
        _noteController.clear();
        _section = '5C24A';
      });

      _showSnack('✅ Horario importado correctamente (${schedules.length} clases)');
      
      // Cerrar el diálogo si está en uno
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

    } catch (e) {
      print('❌ Error procesando horario: $e');
      _showSnack('Error al procesar: $e');
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<void> _saveSchedulesToStorage(List<dynamic> schedules) async {
    // Convertir a formato del servicio
    final List<Map<String, dynamic>> scheduleMaps = schedules
        .map((schedule) => Map<String, dynamic>.from(schedule))
        .toList();
    
    // Usar el servicio de horarios del profesor
    final teacherScheduleService = TeacherScheduleService();
    await teacherScheduleService.saveImportedSchedules(
      scheduleMaps,
      teacherId: widget.teacherId,
      section: _section == 'Todas' ? null : _section,
      note: _noteController.text.trim(),
    );
    
    print('💾 Guardado ${schedules.length} horarios usando TeacherScheduleService');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: message.startsWith('✅') 
          ? Colors.green 
          : message.startsWith('❌') 
            ? Colors.red 
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Importar Horario desde Imagen',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text(
              'Sube una imagen JPG/PNG de tu horario y se importará automáticamente',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botones de acción
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _processing ? null : _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Seleccionar Imagen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _processing ? null : _parseAndImportSchedule,
                  icon: _processing 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.smart_toy),
                  label: Text(_processing ? 'Procesando...' : 'Importar Horario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_imageBytes != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _imageBytes = null;
                        _fileName = null;
                        _noteController.clear();
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar'),
                  ),

              ],
            ),
            
            const SizedBox(height: 20),
            
            // Configuración
            Row(
              children: [
                // Selector de sección
                const Text(
                  'Sección:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _section,
                  items: _sections.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  )).toList(),
                  onChanged: (value) => setState(() => _section = value ?? _section),
                ),
                
                const SizedBox(width: 20),
                
                // Campo de nota
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                      hintText: 'Ej: Horario 2025-2',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Información del archivo
            if (_fileName != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.image, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Archivo: $_fileName',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Preview de imagen o placeholder
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.contain,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay imagen seleccionada',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Formatos soportados: JPG, PNG',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
            ),
            
            const SizedBox(height: 16),
            
            // Nota informativa
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La imagen se procesa automáticamente y NO se guarda en la base de datos. '
                      'Solo se extraen y guardan los horarios detectados.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}