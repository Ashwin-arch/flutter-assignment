import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskMasterApp());
}

// ── Model ──
class Task {
  final String id;
  String title;
  bool isDone;
  final DateTime createdAt;
  String priority; // 'low' | 'medium' | 'high'

  Task({required this.id, required this.title, this.isDone = false, required this.createdAt, this.priority = 'medium'});

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id: j['id'], 
    title: j['title'], 
    isDone: j['is_done'], 
    createdAt: DateTime.parse(j['created_at']), 
    priority: j['priority'] ?? 'medium'
  );
}

class TaskMasterApp extends StatelessWidget {
  const TaskMasterApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TaskMaster',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00D2A0), brightness: Brightness.dark)),
    home: const TaskMasterScreen(),
  );
}

class TaskMasterScreen extends StatefulWidget {
  const TaskMasterScreen({super.key});
  @override
  State<TaskMasterScreen> createState() => _TaskMasterScreenState();
}

class _TaskMasterScreenState extends State<TaskMasterScreen> {
  final List<Task> _tasks = [];
  final TextEditingController _inputController = TextEditingController();
  String _selectedPriority = 'medium';
  String _filter = 'all';
  static const String _baseUrl = 'http://localhost:8001/api/v1/tasks';

  @override
  void initState() { super.initState(); _loadTasks(); }
  @override
  void dispose() { _inputController.dispose(); super.dispose(); }

  Future<void> _loadTasks() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _tasks.clear();
          _tasks.addAll(data.map((e) => Task.fromJson(e)));
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> _addTask(String title) async {
    if (title.trim().isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title.trim(), 'priority': _selectedPriority}),
      );
      if (response.statusCode == 200) {
        _inputController.clear();
        _loadTasks();
      }
    } catch (e) {
       debugPrint('Error adding task: $e');
    }
  }

  Future<void> _toggleTask(String id, bool isDone) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$id?is_done=${!isDone}'),
      );
      if (response.statusCode == 200) {
        _loadTasks();
      }
    } catch (e) {
       debugPrint('Error toggling task: $e');
    }
  }

  Future<void> _deleteTask(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/$id'));
      if (response.statusCode == 200) {
        _loadTasks();
      }
    } catch (e) {
       debugPrint('Error deleting task: $e');
    }
  }

  Future<void> _clearCompleted() async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/clear/completed'));
      if (response.statusCode == 200) {
        _loadTasks();
      }
    } catch (e) {
       debugPrint('Error clearing completed: $e');
    }
  }

  Future<void> _updateTaskTitle(String id, String newTitle) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$id?title=${Uri.encodeComponent(newTitle)}'),
      );
      if (response.statusCode == 200) {
        _loadTasks();
      }
    } catch (e) {
       debugPrint('Error updating task: $e');
    }
  }

  void _showEditDialog(Task task) {
    final c = TextEditingController(text: task.title);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1C2333),
      title: const Text('Edit Task', style: TextStyle(color: Colors.white)),
      content: TextField(controller: c, autofocus: true, style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Task name', hintStyle: TextStyle(color: Colors.white38))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: () { _updateTitle(task.id, c.text.trim()); Navigator.pop(context); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D2A0)),
          child: const Text('Save'),
        ),
      ],
    ));
  }

  void _updateTitle(String id, String title) {
    _updateTaskTitle(id, title);
  }

  List<Task> get _filteredTasks {
    switch (_filter) {
      case 'active': return _tasks.where((t) => !t.isDone).toList();
      case 'done':   return _tasks.where((t) =>  t.isDone).toList();
      default:       return _tasks;
    }
  }

  int get _doneCount => _tasks.where((t) => t.isDone).length;
  double get _progress => _tasks.isEmpty ? 0 : _doneCount / _tasks.length;

  Color _priorityColor(String p) {
    switch (p) {
      case 'high': return const Color(0xFFFF5252);
      case 'low':  return const Color(0xFF69F0AE);
      default:     return const Color(0xFFFFD740);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TaskMaster', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text('$_doneCount of ${_tasks.length} completed', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
        actions: [
          if (_doneCount > 0) TextButton.icon(
            onPressed: _clearCompleted,
            icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: Color(0xFF00D2A0)),
            label: const Text('Clear done', style: TextStyle(color: Color(0xFF00D2A0), fontSize: 12)),
          ),
        ],
      ),
      body: Column(children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00D2A0))),
            ),
          ),
        ),

        // Input row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            // Priority cycle button
            GestureDetector(
              onTap: () {
                final priorities = ['low', 'medium', 'high'];
                setState(() => _selectedPriority = priorities[(priorities.indexOf(_selectedPriority) + 1) % priorities.length]);
              },
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _priorityColor(_selectedPriority).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _priorityColor(_selectedPriority).withOpacity(0.5)),
                ),
                child: Icon(Icons.flag_rounded, color: _priorityColor(_selectedPriority), size: 22),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: Colors.white),
                onSubmitted: _addTask,
                decoration: InputDecoration(
                  hintText: 'Add a new task...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true, fillColor: const Color(0xFF1C2333),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _addTask(_inputController.text),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFF00D2A0), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
              ),
            ),
          ]),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            _buildFilterChip('All',    _tasks.length,                     'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Active', _tasks.where((t) => !t.isDone).length, 'active'),
            const SizedBox(width: 8),
            _buildFilterChip('Done',   _doneCount,                        'done'),
          ]),
        ),

        // Task list
        Expanded(
          child: _filteredTasks.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.task_alt_rounded, size: 64, color: Colors.white12),
                  const SizedBox(height: 16),
                  Text(_filter == 'done' ? 'No completed tasks' : _filter == 'active' ? 'All done! 🎉' : 'Add your first task',
                      style: const TextStyle(color: Colors.white38, fontSize: 16)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: _filteredTasks.length,
                  itemBuilder: (context, i) {
                    final task = _filteredTasks[i];
                    return Dismissible(
                      key: ValueKey(task.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: const Color(0xFFFF5252).withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_rounded, color: Color(0xFFFF5252), size: 28),
                      ),
                      onDismissed: (_) => _deleteTask(task.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: task.isDone ? const Color(0xFF1C2333).withOpacity(0.5) : const Color(0xFF1C2333),
                          borderRadius: BorderRadius.circular(16),
                          border: Border(left: BorderSide(color: _priorityColor(task.priority), width: 4)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: GestureDetector(
                            onTap: () => _toggleTask(task.id, task.isDone),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 26, height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: task.isDone ? const Color(0xFF00D2A0) : Colors.transparent,
                                border: Border.all(color: task.isDone ? const Color(0xFF00D2A0) : Colors.white38, width: 2),
                              ),
                              child: task.isDone ? const Icon(Icons.check_rounded, color: Colors.black, size: 16) : null,
                            ),
                          ),
                          title: Text(task.title, style: TextStyle(
                            color: task.isDone ? Colors.white38 : Colors.white, fontSize: 15, fontWeight: FontWeight.w500,
                            decoration: task.isDone ? TextDecoration.lineThrough : null,
                            decorationColor: Colors.white38,
                          )),
                          subtitle: Text(_timeAgo(task.createdAt), style: const TextStyle(color: Colors.white24, fontSize: 11)),
                          trailing: IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 18), onPressed: () => _showEditDialog(task)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  Widget _buildFilterChip(String label, int count, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00D2A0) : const Color(0xFF1C2333),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$label ($count)', style: TextStyle(color: selected ? Colors.black : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1)   return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)    return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
