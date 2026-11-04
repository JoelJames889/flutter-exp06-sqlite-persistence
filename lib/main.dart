import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScholarDeskApp());
}

/// Root Application Widget - Glassmorphic Dark Edition
class ScholarDeskApp extends StatelessWidget {
  const ScholarDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScholarDesk - SQLite Student Records',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090D16),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF06B6D4), // Matrix Cyan
          secondary: Color(0xFF10B981), // Neon Emerald
          surface: Color(0xFF111827),
        ),
      ),
      home: const StudentManagerScreen(),
    );
  }
}

/// Student Entity Model
class Student {
  final int? id;
  final String rollNo;
  final String name;
  final String email;
  final String department;
  final double gpa;
  final String createdAt;

  const Student({
    this.id,
    required this.rollNo,
    required this.name,
    required this.email,
    required this.department,
    required this.gpa,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roll_no': rollNo,
      'name': name,
      'email': email,
      'department': department,
      'gpa': gpa,
      'created_at': createdAt,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      rollNo: map['roll_no'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      department: map['department'] as String,
      gpa: (map['gpa'] as num).toDouble(),
      createdAt: map['created_at'] as String,
    );
  }
}

/// SQLite Database Helper Singleton
class DatabaseHelper {
  static const _databaseName = "students_records.db";
  static const _databaseVersion = 1;
  static const tableStudents = "students";

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableStudents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roll_no TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        department TEXT NOT NULL,
        gpa REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Initial Seed Records
    await db.insert(tableStudents, {
      'roll_no': 'CS202401',
      'name': 'Aarav Sharma',
      'email': 'aarav.cs@university.edu',
      'department': 'Computer Science',
      'gpa': 9.4,
      'created_at': '2024-08-15',
    });

    await db.insert(tableStudents, {
      'roll_no': 'EC202405',
      'name': 'Priya Patel',
      'email': 'priya.ec@university.edu',
      'department': 'Electronics',
      'gpa': 8.8,
      'created_at': '2024-08-16',
    });

    await db.insert(tableStudents, {
      'roll_no': 'ME202412',
      'name': 'Rohan Nair',
      'email': 'rohan.me@university.edu',
      'department': 'Mechanical',
      'gpa': 7.9,
      'created_at': '2024-08-17',
    });
  }

  Future<int> insertStudent(Student student) async {
    final db = await database;
    return await db.insert(
      tableStudents,
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableStudents,
      orderBy: 'id DESC',
    );
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<List<Student>> searchStudents(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableStudents,
      where: 'name LIKE ? OR roll_no LIKE ? OR department LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'id DESC',
    );
    return maps.map((m) => Student.fromMap(m)).toList();
  }
}

/// Main Student Management UI Screen
class StudentManagerScreen extends StatefulWidget {
  const StudentManagerScreen({super.key});

  @override
  State<StudentManagerScreen> createState() => _StudentManagerScreenState();
}

class _StudentManagerScreenState extends State<StudentManagerScreen> {
  final _searchController = TextEditingController();
  List<Student> _studentList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshStudentList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshStudentList([String query = '']) async {
    setState(() => _isLoading = true);
    final data = query.isEmpty
        ? await DatabaseHelper.instance.getAllStudents()
        : await DatabaseHelper.instance.searchStudents(query);

    setState(() {
      _studentList = data;
      _isLoading = false;
    });
  }

  void _showAddStudentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddStudentForm(
        onStudentAdded: () {
          _refreshStudentList(_searchController.text.trim());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _studentList.length;
    final avgGpa = totalCount > 0
        ? (_studentList.map((s) => s.gpa).reduce((a, b) => a + b) / totalCount)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        children: [
          // Ambient Neon Orbs
          Positioned(
            top: -70,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06B6D4).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF06B6D4).withOpacity(0.4),
                              ),
                            ),
                            child: const Icon(Icons.storage_rounded,
                                color: Color(0xFF06B6D4), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ScholarDesk SQLite',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF06B6D4),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Exp 6: Local Relational DB',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Reload Button
                      InkWell(
                        onTap: () => _refreshStudentList(_searchController.text.trim()),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: const Icon(Icons.refresh_rounded,
                              color: Colors.white70, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Glass Statistics Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF06B6D4).withOpacity(0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildGlassStat(
                              'SQLite Records',
                              '$totalCount',
                              Icons.folder_shared_rounded,
                              const Color(0xFF06B6D4),
                            ),
                            Container(
                              height: 32,
                              width: 1,
                              color: Colors.white.withOpacity(0.12),
                            ),
                            _buildGlassStat(
                              'Cohort GPA',
                              avgGpa.toStringAsFixed(2),
                              Icons.grade_rounded,
                              const Color(0xFF10B981),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Glass Search Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _refreshStudentList(val.trim()),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by Roll No, Name or Dept...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 12.5,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF06B6D4), size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: Colors.white54, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _refreshStudentList();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: Color(0xFF06B6D4), width: 1.5),
                      ),
                    ),
                  ),
                ),

                // Students List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
                        )
                      : _studentList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 48, color: Colors.white.withOpacity(0.2)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No SQLite Records Found',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap "+ Add Student" to insert an entry',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(18, 4, 18, 90),
                              itemCount: _studentList.length,
                              itemBuilder: (context, index) {
                                final student = _studentList[index];
                                return _buildStudentCard(student);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06B6D4).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          onPressed: _showAddStudentSheet,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add Student',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildGlassStat(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 17, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55), fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildStudentCard(Student student) {
    final isHigh = student.gpa >= 8.5;
    final isMid = student.gpa >= 7.0;
    final gpaColor = isHigh
        ? const Color(0xFF10B981)
        : (isMid ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF06B6D4).withOpacity(0.15),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0] : 'S',
                    style: const TextStyle(
                      color: Color(0xFF06B6D4),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              student.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06B6D4).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF06B6D4).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              student.rollNo,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        student.email,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.department,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF06B6D4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: gpaColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: gpaColor.withOpacity(0.35)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'GPA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        student.gpa.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: gpaColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Create Operation Form: Add Student to SQLite
class AddStudentForm extends StatefulWidget {
  final VoidCallback onStudentAdded;

  const AddStudentForm({super.key, required this.onStudentAdded});

  @override
  State<AddStudentForm> createState() => _AddStudentFormState();
}

class _AddStudentFormState extends State<AddStudentForm> {
  final _formKey = GlobalKey<FormState>();
  final _rollController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _gpaController = TextEditingController();

  String _department = 'Computer Science';
  final List<String> _departments = [
    'Computer Science',
    'Electronics',
    'Mechanical',
    'Civil Engineering',
    'Information Technology',
    'Biotechnology',
  ];

  @override
  void dispose() {
    _rollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  Future<void> _submitStudent() async {
    if (_formKey.currentState!.validate()) {
      final student = Student(
        rollNo: _rollController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        department: _department,
        gpa: double.parse(_gpaController.text.trim()),
        createdAt: DateTime.now().toIso8601String().substring(0, 10),
      );

      await DatabaseHelper.instance.insertStudent(student);
      widget.onStudentAdded();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF111827).withOpacity(0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Insert SQLite Record',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _rollController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _sheetDecoration('Roll Number *', Icons.badge_rounded, 'e.g. CS202422'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Roll No required' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _sheetDecoration('Full Name *', Icons.person_rounded, 'e.g. Ananya Sen'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _sheetDecoration('University Email *', Icons.email_rounded, 'e.g. ananya@univ.edu'),
                  validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: _department,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _sheetDecoration('Department', Icons.school_rounded, ''),
                  items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _department = val);
                  },
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _gpaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _sheetDecoration('GPA (0.0 - 10.0) *', Icons.grade_rounded, 'e.g. 9.1'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'GPA required';
                    final n = double.tryParse(v.trim());
                    if (n == null || n < 0 || n > 10) return 'GPA must be between 0.0 and 10.0';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _submitStudent,
                      child: const Text('Execute INSERT Statement',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _sheetDecoration(String label, IconData icon, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF06B6D4), size: 18),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
      ),
      errorStyle: const TextStyle(color: Color(0xFFF87171), fontSize: 11),
    );
  }
}
