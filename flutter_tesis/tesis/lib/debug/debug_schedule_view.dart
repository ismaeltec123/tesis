import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DebugScheduleView extends StatefulWidget {
  const DebugScheduleView({super.key});

  @override
  State<DebugScheduleView> createState() => _DebugScheduleViewState();
}

class _DebugScheduleViewState extends State<DebugScheduleView> {
  String _debugInfo = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedulesJson = prefs.getString('teacher_imported_schedules');
      final hasSchedules = prefs.getBool('teacher_has_imported_schedules') ?? false;
      
      String info = '🔍 Debug Information:\n\n';
      info += '📋 Has imported schedules: $hasSchedules\n';
      info += '📄 Schedules JSON exists: ${schedulesJson != null}\n';
      
      if (schedulesJson != null) {
        info += '📏 JSON length: ${schedulesJson.length} characters\n';
        try {
          final List<dynamic> schedules = json.decode(schedulesJson);
          info += '📊 Total schedules: ${schedules.length}\n\n';
          
          for (int i = 0; i < schedules.length; i++) {
            final schedule = schedules[i];
            info += '📅 Schedule ${i + 1}:\n';
            info += '  - Name: ${schedule['subject_name']}\n';
            info += '  - Day: ${schedule['day_of_week']}\n';
            info += '  - Time: ${schedule['start_time']} - ${schedule['end_time']}\n';
            info += '  - Room: ${schedule['classroom']}\n';
            info += '  - Building: ${schedule['building']}\n\n';
          }
        } catch (e) {
          info += '❌ Error parsing JSON: $e\n';
        }
      } else {
        info += '❌ No schedules found in SharedPreferences\n';
      }
      
      setState(() {
        _debugInfo = info;
      });
    } catch (e) {
      setState(() {
        _debugInfo = '❌ Error loading debug info: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Schedules'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _loadDebugInfo,
              child: const Text('Refresh Debug Info'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}