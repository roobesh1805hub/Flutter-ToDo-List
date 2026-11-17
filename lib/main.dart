import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My To-Do List',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
      ),

      home: const TodoHomePage(),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final List<String> tasks = [];
  final List<bool> completed = [];

  final TextEditingController taskController = TextEditingController();

  bool isLoading = true;
  String selectedFilter = 'All';
  int get completedCount => completed.where((isDone) => isDone).length;

  double get taskProgress =>
      tasks.isEmpty ? 0.0 : completedCount / tasks.length;

  List<int> get filteredTaskIndices {
    return List.generate(tasks.length, (index) => index).where((index) {
      if (selectedFilter == 'Pending') {
        return !completed[index];
      }

      if (selectedFilter == 'Completed') {
        return completed[index];
      }

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();

    final taskData = List.generate(tasks.length, (index) {
      return {'title': tasks[index], 'completed': completed[index]};
    });

    await prefs.setString('todo_tasks', jsonEncode(taskData));
  }

  Future<void> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('todo_tasks');

      if (savedData != null) {
        final decoded = jsonDecode(savedData) as List<dynamic>;

        final loadedTasks = <String>[];
        final loadedCompleted = <bool>[];

        for (final item in decoded) {
          final task = item as Map<String, dynamic>;

          loadedTasks.add(task['title'] as String);
          loadedCompleted.add(task['completed'] as bool);
        }

        if (!mounted) return;

        setState(() {
          tasks
            ..clear()
            ..addAll(loadedTasks);

          completed
            ..clear()
            ..addAll(loadedCompleted);
        });
      }
    } catch (error) {
      debugPrint('Error loading tasks: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void addTask(BuildContext dialogContext) {
    final task = taskController.text.trim();

    if (task.isNotEmpty) {
      setState(() {
        tasks.add(task);
        completed.add(false);
      });

      saveTasks();
      taskController.clear();
      Navigator.pop(dialogContext);
    }
  }

  void deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
      completed.removeAt(index);
    });

    saveTasks();
  }

  void editTask(int index) {
    final editController = TextEditingController(text: tasks[index]);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: TextField(
            controller: editController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Update your task',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedTask = editController.text.trim();

                if (updatedTask.isNotEmpty) {
                  setState(() {
                    tasks[index] = updatedTask;
                  });

                  saveTasks();
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) => editController.dispose());
  }

  void toggleTask(int index, bool value) {
    setState(() {
      completed[index] = value;
    });

    saveTasks();
  }

  void showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            controller: taskController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter your task',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => addTask(dialogContext),
          ),
          actions: [
            TextButton(
              onPressed: () {
                taskController.clear();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => addTask(dialogContext),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My To-Do List'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completedCount of ${tasks.length} tasks completed',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: taskProgress,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 8),
                      Text('${(taskProgress * 100).round()}% completed'),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final filter in ['All', 'Pending', 'Completed'])
                        ChoiceChip(
                          label: Text(filter),
                          selected: selectedFilter == filter,
                          onSelected: (_) {
                            setState(() {
                              selectedFilter = filter;
                            });
                          },
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: tasks.isEmpty
                      ? const Center(
                          child: Text(
                            'No tasks yet. Add your first task!',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredTaskIndices.length,
                          itemBuilder: (context, filteredIndex) {
                            final index = filteredTaskIndices[filteredIndex];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: Checkbox(
                                  value: completed[index],
                                  onChanged: (value) {
                                    toggleTask(index, value ?? false);
                                  },
                                ),
                                title: Text(
                                  tasks[index],
                                  style: TextStyle(
                                    decoration: completed[index]
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Edit task',
                                      onPressed: () => editTask(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Delete task',
                                      onPressed: () => deleteTask(index),
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

      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
