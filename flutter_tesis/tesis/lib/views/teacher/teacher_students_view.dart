import 'package:flutter/material.dart';
import '../../models/teacher/teacher_templates.dart';
import '../../models/teacher/teacher_config.dart';
import '../../models/teacher/teacher_models.dart';

class TeacherStudentsView extends StatefulWidget {
  const TeacherStudentsView({super.key});

  @override
  State<TeacherStudentsView> createState() => _TeacherStudentsViewState();
}

class _TeacherStudentsViewState extends State<TeacherStudentsView> {
  String _selectedSubjectId = '';
  String _searchQuery = '';
  List<Student> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    if (!TeacherFeatureFlags.ENABLE_STUDENT_LIST) {
      _filteredStudents = [];
      return;
    }

    final students = StudentListTemplate.getMockStudents();
    setState(() {
      _filteredStudents = students.where((student) {
        final matchesSearch = _searchQuery.isEmpty ||
            student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            student.email.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesSubject = _selectedSubjectId.isEmpty || 
            _getStudentSubjects(student.id).contains(_selectedSubjectId);

        return matchesSearch && matchesSubject;
      }).toList();
    });
  }

  List<String> _getStudentSubjects(String studentId) {
    final subjects = SubjectTemplate.getMockSubjects();
    return subjects.where((s) => s.studentIds.contains(studentId)).map((s) => s.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header con template indicator
            _buildHeader(),
            
            // Filtros
            _buildFilters(),
            
            // Lista de estudiantes
            Expanded(
              child: _buildStudentsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.green[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lista de Estudiantes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (TeacherTemplateConfig.USE_MOCK_STUDENTS)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.science_outlined, size: 12, color: Colors.orange[800]),
                        const SizedBox(width: 4),
                        Text(
                          '🎭 Datos de demostración',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${_filteredStudents.length} estudiantes',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final subjects = SubjectTemplate.getMockSubjects();
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _loadStudents();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _loadStudents();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filtro por materia
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildSubjectFilter('Todas las materias', ''),
                ...subjects.map((subject) => _buildSubjectFilter(subject.name, subject.id)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectFilter(String name, String id) {
    final isSelected = _selectedSubjectId == id;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedSubjectId = selected ? id : '';
          });
          _loadStudents();
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.green[100],
        checkmarkColor: Colors.green[700],
      ),
    );
  }

  Widget _buildStudentsList() {
    if (!TeacherFeatureFlags.ENABLE_STUDENT_LIST) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Funcionalidad deshabilitada'),
          ],
        ),
      );
    }

    if (_filteredStudents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No se encontraron estudiantes'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(Student student) {
    final studentSubjects = _getStudentSubjects(student.id);
    final subjects = SubjectTemplate.getMockSubjects();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: student.isActive ? Colors.green[100] : Colors.grey[200],
          child: Text(
            student.name.split(' ').map((n) => n[0]).take(2).join(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: student.isActive ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                student.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (!student.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Inactivo',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              student.email,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: studentSubjects.map((subjectId) {
                final subject = subjects.firstWhere((s) => s.id == subjectId);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    subject.code,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[700],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showStudentActions(student),
        ),
      ),
    );
  }

  void _showStudentActions(Student student) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Enviar email'),
              onTap: () {
                Navigator.pop(context);
                _sendEmail(student);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Ver detalles'),
              onTap: () {
                Navigator.pop(context);
                _showStudentDetails(student);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendEmail(Student student) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email a ${student.name} - Funcionalidad en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showStudentDetails(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${student.id}'),
            Text('Email: ${student.email}'),
            Text('Estado: ${student.isActive ? 'Activo' : 'Inactivo'}'),
            Text('Inscrito: ${student.enrollmentDate.day}/${student.enrollmentDate.month}/${student.enrollmentDate.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}