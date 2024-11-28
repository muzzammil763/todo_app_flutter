import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const DevTodoApp());
}

class DevTodoApp extends StatelessWidget {
  const DevTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class Todo {
  final String id;
  String text;
  String category;
  String priority;
  bool completed;
  final DateTime timestamp;
  DateTime? lastEdited; // Add this field

  Todo({
    required this.id,
    required this.text,
    required this.category,
    required this.priority,
    this.completed = false,
    required this.timestamp,
    this.lastEdited,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'category': category,
        'priority': priority,
        'completed': completed,
        'timestamp': timestamp.toIso8601String(),
        'lastEdited': lastEdited?.toIso8601String(),
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'],
        text: json['text'],
        category: json['category'],
        priority: json['priority'],
        completed: json['completed'],
        timestamp: DateTime.parse(json['timestamp']),
        lastEdited: json['lastEdited'] != null
            ? DateTime.parse(json['lastEdited'])
            : null,
      );

  String formatDateTime(DateTime dateTime) {
    // String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    int hour12 = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    hour12 = hour12 == 0 ? 12 : hour12;

    return '${hour12.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')} '
        '(${dateTime.day.toString().padLeft(2, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.year})';
  }

  String getFormattedTimestamp() {
    String timeStr = formatDateTime(lastEdited ?? timestamp);
    if (lastEdited != null) {
      timeStr += ' // Edited';
    }
    return timeStr;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _todoController = TextEditingController();
  late AnimationController _listItemController;

  final Set<String> categories = {
    'feature',
    'bug',
    'refactor',
    'docs',
    'testing'
  };
  String selectedCategory = 'feature';
  String selectedPriority = 'low';
  List<Todo> todos = [];
  bool showCustomCategory = false;
  final TextEditingController _customCategoryController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _listItemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosJson = prefs.getString('todos');
    if (todosJson != null) {
      final List<dynamic> decoded = json.decode(todosJson);
      setState(() {
        todos = decoded.map((item) => Todo.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedTodos = json.encode(
      todos.map((todo) => todo.toJson()).toList(),
    );
    await prefs.setString('todos', encodedTodos);
  }

  void _addTodo() {
    if (_todoController.text.trim().isEmpty) return;

    final String category = showCustomCategory
        ? _customCategoryController.text.trim().toLowerCase()
        : selectedCategory;

    if (showCustomCategory && category.isNotEmpty) {
      categories.add(category);
    }

    setState(() {
      todos.insert(
          0,
          Todo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: _todoController.text,
            category: category,
            priority: selectedPriority,
            timestamp: DateTime.now(),
          ));
      _todoController.clear();
      _customCategoryController.clear();
      showCustomCategory = false;
      selectedCategory = 'feature';
    });

    _saveTodos();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return const Color(0xFFD55A32);
      case 'medium':
        return const Color(0xFFC5A94A);
      default:
        return const Color(0xFF6AA948);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        '/**',
                        style: TextStyle(
                          color: Color(0xFF858585),
                          fontSize: 24,
                          fontFamily: 'consolas',
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Dev Todo App in Flutter',
                          style: TextStyle(
                            color: Color(0xFF569CD6),
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            fontFamily: 'consolas',
                          )),
                      SizedBox(width: 8),
                      Text(
                        '*/',
                        style: TextStyle(
                          color: Color(0xFF858585),
                          fontSize: 24,
                          fontFamily: 'consolas',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          cursorColor: const Color(0xFF569CD6),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'consolas',
                          ),
                          controller: _todoController,
                          decoration: InputDecoration(
                            hintText: 'New task... (Press Enter to add)',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontFamily: 'consolas',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide:
                                  const BorderSide(color: Color(0xFF858585)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide:
                                  const BorderSide(color: Color(0xFF858585)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide:
                                  const BorderSide(color: Color(0xFF569CD6)),
                            ),
                          ),
                          onSubmitted: (_) => _addTodo(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StyledDropdown(
                        value: selectedCategory,
                        items: [...categories, 'custom'],
                        onChanged: (String? value) {
                          setState(() {
                            selectedCategory = value!;
                            showCustomCategory = value == 'custom';
                          });
                        },
                        hintText: 'Category',
                      ),
                      if (showCustomCategory) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            cursorColor: const Color(0xFF569CD6),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'consolas',
                            ),
                            controller: _customCategoryController,
                            decoration: InputDecoration(
                              hintText: 'Custom category',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontFamily: 'consolas',
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide:
                                    const BorderSide(color: Color(0xFF858585)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide:
                                    const BorderSide(color: Color(0xFF858585)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide:
                                    const BorderSide(color: Color(0xFF569CD6)),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      StyledDropdown(
                        value: selectedPriority,
                        items: const ['low', 'medium', 'high', 'urgent'],
                        onChanged: (String? value) {
                          setState(() {
                            selectedPriority = value!;
                          });
                        },
                        hintText: 'Priority',
                      ),
                      const SizedBox(width: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _addTodo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF569CD6).withOpacity(0.8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                elevation: 0,
                              ).copyWith(
                                elevation:
                                    WidgetStateProperty.resolveWith<double>(
                                  (Set<WidgetState> states) {
                                    if (states.contains(WidgetState.hovered)) {
                                      return 4;
                                    }
                                    return 0;
                                  },
                                ),
                              ),
                              child: const Text(
                                'Add Task',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'consolas',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        todos.isEmpty ? _buildEmptyState() : _buildTodoList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildStatsPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '// No todos found',
                style: TextStyle(
                  color: Color(0xFF858585),
                  fontFamily: 'consolas',
                  fontSize: 20,
                ),
              ),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'const ',
                      style: TextStyle(
                        color: Color(0xFF569CD6),
                        fontFamily: 'consolas',
                        fontSize: 18,
                      ),
                    ),
                    TextSpan(
                      text: 'developer',
                      style: TextStyle(
                        color: Color(0xFFD4D4D4),
                        fontFamily: 'consolas',
                        fontSize: 18,
                      ),
                    ),
                    TextSpan(
                      text: ' = {',
                      style: TextStyle(
                        color: Color(0xFF858585),
                        fontFamily: 'consolas',
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: '  status: ',
                        style: TextStyle(
                          color: Color(0xFF858585), // Grey color
                          fontFamily: 'consolas',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '"relaxing",',
                        style: TextStyle(
                          color: Color(0xFFCE9178),
                          fontFamily: 'consolas',
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: '  todos: ',
                        style: TextStyle(
                          color: Color(0xFFCE9178),
                          fontFamily: 'consolas',
                          fontSize: 18,
                        ),
                      ),
                      TextSpan(
                        text: '[],',
                        style: TextStyle(
                          color: Color(0xFF4EC9B0),
                          fontFamily: 'consolas',
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: '  coffee: ',
                        style: TextStyle(
                          color: Color(0xFF858585), // Grey color
                          fontFamily: 'consolas',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '"needed"',
                        style: TextStyle(
                          color: Color(0xFFCE9178),
                          fontFamily: 'consolas',
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                '};',
                style: TextStyle(
                  color: Color(0xFF858585),
                  fontFamily: 'consolas',
                  fontSize: 18,
                ),
              ),
              const Text(
                '// Add your first task above! ☝️',
                style: TextStyle(
                  color: Color(0xFF858585),
                  fontFamily: 'consolas',
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoList() {
    final sortedTodos = List<Todo>.from(todos)
      ..sort((a, b) {
        final aTime = a.lastEdited ?? a.timestamp;
        final bTime = b.lastEdited ?? b.timestamp;
        final priorityOrder = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
        final priorityCompare =
            priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
        if (priorityCompare == 0) {
          return bTime.compareTo(aTime);
        }

        return priorityCompare;
      });

    return ListView.builder(
      itemCount: sortedTodos.length,
      itemBuilder: (context, index) {
        final todo = sortedTodos[index];
        return MouseRegion(
          onEnter: (_) => _listItemController.forward(),
          onExit: (_) => _listItemController.reverse(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            transform: Matrix4.translationValues(
              0,
              0,
              0,
            )..translate(5),
            child: Card(
              shadowColor: _getPriorityColor(todo.priority),
              elevation: 2,
              margin: const EdgeInsets.only(right: 12, left: 4, bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: todo.completed
                      ? Colors.green
                      : _getPriorityColor(todo.priority),
                  width: 1,
                ),
              ),
              child: ListTile(
                tileColor: const Color(0xFF1E1E1E),
                focusColor: Colors.transparent,
                title: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 2),
                  child: Text(
                    todo.text,
                    style: TextStyle(
                      decorationThickness: 2.5,
                      decoration:
                          todo.completed ? TextDecoration.lineThrough : null,
                      decorationColor: todo.completed ? Colors.green : null,
                      color: todo.completed
                          ? const Color(0xFF858585)
                          : const Color(0xFFD4D4D4),
                      fontFamily: 'consolas',
                    ),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 2),
                  child: Text(
                    todo.getFormattedTimestamp(),
                    style: TextStyle(
                      decorationThickness: 2.5,
                      decoration:
                          todo.completed ? TextDecoration.lineThrough : null,
                      decorationColor: todo.completed ? Colors.green : null,
                      color: const Color(0xFF858585),
                      fontFamily: 'consolas',
                    ),
                  ),
                ),
                trailing: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (todo.completed)
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            "Marked As Completed",
                            style: TextStyle(
                              color: Color(0xFF4EC9B0),
                              fontFamily: 'consolas',
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.done,
                                color: Colors.green,
                              ),
                              Icon(
                                Icons.done,
                                color: Colors.green,
                              ),
                            ],
                          )
                        ],
                      ),
                    const SizedBox(width: 24),
                    StyledDropdown(
                      value: todo.category,
                      items: [...categories],
                      onChanged: todo.completed
                          ? null // Disable dropdown if completed
                          : (value) {
                              setState(() {
                                todo.category = value!;
                                todo.lastEdited = DateTime.now();
                                _saveTodos();
                              });
                            },
                      hintText: 'Category',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      color: todo.completed
                          ? Colors.grey.withOpacity(0.5)
                          : Colors.grey,
                      onPressed: todo.completed ? null : () => _editTodo(todo),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.amber,
                      onPressed: () {
                        setState(() {
                          todos.remove(todo);
                          _saveTodos();
                        });
                      },
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    todo.completed = !todo.completed;
                    _saveTodos();
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsPanel() {
    final total = todos.length;
    final completed = todos.where((todo) => todo.completed).length;
    final pending = total - completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '/* Statistics */',
            style: TextStyle(
              color: Color(0xFF858585),
              fontFamily: 'consolas',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Total Tasks: $total',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'consolas',
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Completed: $completed',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'consolas',
              letterSpacing: 1.5,
            ),
          ),
          Text(
            'Pending: $pending',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'consolas',
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '/* By Category */',
            style: TextStyle(
              color: Color(0xFF858585),
              fontFamily: 'consolas',
            ),
          ),
          const SizedBox(height: 8),
          ..._buildCategoryStats(),
          const SizedBox(height: 16),
          const Text(
            '/* By Priority */',
            style: TextStyle(
              color: Color(0xFF858585),
              fontFamily: 'consolas',
            ),
          ),
          const SizedBox(height: 8),
          ..._buildPriorityStats(),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryStats() {
    final categoryCount = <String, int>{};
    for (final todo in todos) {
      categoryCount[todo.category] = (categoryCount[todo.category] ?? 0) + 1;
    }
    return categoryCount.entries
        .map((e) => Text(
              '${e.key}: ${e.value}',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'consolas',
                letterSpacing: 1.5,
              ),
            ))
        .toList();
  }

  List<Widget> _buildPriorityStats() {
    final priorityCount = <String, int>{};
    for (final todo in todos) {
      priorityCount[todo.priority] = (priorityCount[todo.priority] ?? 0) + 1;
    }
    return priorityCount.entries
        .map((e) => Text(
              '${e.key}: ${e.value}',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'consolas',
                letterSpacing: 1.5,
              ),
            ))
        .toList();
  }

  void _editTodo(Todo todo) {
    final TextEditingController textController =
        TextEditingController(text: todo.text);
    String editCategory = todo.category;
    String editPriority = todo.priority;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252526),
        title: const Text(
          'Edit Todo',
          style: TextStyle(
            fontFamily: 'consolas',
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'consolas',
              ),
              cursorColor: const Color(0xFF569CD6),
              controller: textController,
              decoration: InputDecoration(
                  labelText: 'Task',
                  labelStyle: const TextStyle(
                    fontFamily: "consolas",
                    color: Colors.white,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF858585)),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF858585)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF858585)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF569CD6)),
                  )),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                StyledDropdown(
                  value: editCategory,
                  items: [...categories],
                  onChanged: (value) => setState(() => editCategory = value!),
                  hintText: 'Category',
                ),
                const SizedBox(width: 8),
                StyledDropdown(
                  value: editPriority,
                  items: const ['low', 'medium', 'high', 'urgent'],
                  onChanged: (value) => setState(
                    () => editPriority = value!,
                  ),
                  hintText: 'Priority',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: const Color(0xFF569CD6).withOpacity(0.8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                todo.text = textController.text;
                todo.category = editCategory;
                todo.priority = editPriority;
                todo.lastEdited = DateTime.now();
              });
              _saveTodos();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF569CD6).withOpacity(0.8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _todoController.dispose();
    _customCategoryController.dispose();
    _listItemController.dispose();
    super.dispose();
  }
}

class StyledDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final Function(String?)? onChanged;
  final String hintText;

  const StyledDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onChanged == null;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: isDisabled
                ? const Color(0xFF858585).withOpacity(0.5)
                : const Color(0xFF858585)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          focusColor: Colors.transparent,
          value: value,
          hint: Text(hintText),
          dropdownColor: const Color(0xFF252526),
          icon: Icon(Icons.arrow_drop_down,
              color: isDisabled
                  ? const Color(0xFF858585).withOpacity(0.5)
                  : const Color(0xFF858585)),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item == 'custom' ? '+ Custom' : item,
                style: TextStyle(
                  color: isDisabled
                      ? const Color(0xFFD4D4D4).withOpacity(0.5)
                      : const Color(0xFFD4D4D4),
                  fontFamily: 'consolas',
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
