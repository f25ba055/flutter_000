import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, 
    DeviceOrientation.portraitDown, 
  ]);
  runApp(const MaterialApp(
    home: TodoHomePage(),
  ));
}

enum Priority { low, medium, high, ultrahigh }

extension PriorityExtension on Priority {
  String get label {
    switch (this) {
      case Priority.low:
        return '低';
      case Priority.medium:
        return '中';
      case Priority.high:
        return '高';
      case Priority.ultrahigh:
        return '最重要';
    }
  }

  Color get color {
    switch (this) {
      case Priority.low:
        return Colors.lightBlue;
      case Priority.medium:
        return Colors.green;
      case Priority.high:
        return Colors.orange;
      case Priority.ultrahigh:
        return Colors.red;
    }
  }
}

class TodoItem {
  String text;
  bool completed;
  Priority priority;
  DateTime createdAt;
  TimeOfDay? taskTime;

  TodoItem(
    this.text, {
    this.completed = false,
    this.priority = Priority.low,
    DateTime? createdAt,
    this.taskTime,
  }) : createdAt = createdAt ?? DateTime.now();
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});
  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final List<TodoItem> _todos = [];
  final TextEditingController _controller = TextEditingController();
  bool _showCompleted = true;

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _todos.add(TodoItem(text));
      _controller.clear();
    });
  }

  void _toggleTodo(int index) {
    setState(() {
      _todos[index].completed = !_todos[index].completed;
    });
  }

  void _editTodoDialog(int index) {
    final editController = TextEditingController(text: _todos[index].text);
    Priority currentPriority = _todos[index].priority;
    TimeOfDay? selectedTime = _todos[index].taskTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('タスクの編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editController,
                decoration: const InputDecoration(labelText: 'タスク名'),
              ),
              const SizedBox(height: 10),
              DropdownButton<Priority>(
                value: currentPriority,
                items: Priority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      currentPriority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedTime = picked;
                    });
                  }
                },
                child: Text(selectedTime != null
                    ? '時刻: ${selectedTime!.format(context)}'
                    : '時間を設定'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _todos[index].text = editController.text.trim();
                  _todos[index].priority = currentPriority;
                  _todos[index].taskTime = selectedTime;
                });
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedTodos = _showCompleted
        ? _todos
        : _todos.where((todo) => !todo.completed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TODOアプリ'),
        actions: [
          Row(
            children: [
              const Text('完了を表示'),
              Switch(
                value: _showCompleted,
                onChanged: (val) => setState(() => _showCompleted = val),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'タスクを追加',
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTodo,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: displayedTodos.length,
              itemBuilder: (context, index) {
                final todo = displayedTodos[index];
                final originalIndex = _todos.indexOf(todo);

                return Dismissible(
                  key: Key(todo.text + todo.createdAt.toIso8601String()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() {
                      _todos.removeAt(originalIndex);
                    });
                  },
                  child: ListTile(
                    onTap: () => _editTodoDialog(originalIndex),
                    leading: Checkbox(
                      value: todo.completed,
                      onChanged: (_) => _toggleTodo(originalIndex),
                    ),
                    title: Text(
                      todo.text,
                      style: TextStyle(
                        decoration: todo.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: todo.priority.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '作成日: ${todo.createdAt.toLocal().toString().split('.')[0]}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (todo.taskTime != null)
                          Text(
                            '予定時刻: ${todo.taskTime!.format(context)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
