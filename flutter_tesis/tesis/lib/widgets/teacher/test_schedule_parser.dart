import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TestScheduleParser extends StatefulWidget {
  @override
  _TestScheduleParserState createState() => _TestScheduleParserState();
}

class _TestScheduleParserState extends State<TestScheduleParser> {
  String _result = '';
  bool _loading = false;

  Future<void> _testConnection() async {
    setState(() {
      _loading = true;
      _result = 'Probando conexión...';
    });

    try {
      // Test básico de conectividad
      final testUri = Uri.parse('http://localhost:8001');
      final testResponse = await http.get(testUri);
      
      setState(() {
        _result = 'Conectividad OK: ${testResponse.statusCode}\n';
        _result += 'Respuesta: ${testResponse.body}\n\n';
      });

      // Test del endpoint de test
      final testParserUri = Uri.parse('http://localhost:8001/api/schedule-parser/test-parser');
      final testParserResponse = await http.get(testParserUri);
      
      setState(() {
        _result += 'Test Parser: ${testParserResponse.statusCode}\n';
        _result += 'Respuesta: ${testParserResponse.body}';
      });

    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Schedule Parser')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _testConnection,
              child: Text(_loading ? 'Probando...' : 'Probar Conexión'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}