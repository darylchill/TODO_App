import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_todo_app/feature/utils/alarm.dart';
import 'package:flutter_todo_app/feature/utils/databaseHelper.dart';

import '../../api/api_client.dart';
import '../../api/google_signin_service.dart';

class TodoWidget extends ConsumerStatefulWidget {
  const TodoWidget({super.key});

  @override
  _TodoWidgetState createState() => _TodoWidgetState();
}

class _TodoWidgetState extends ConsumerState<TodoWidget> {
  late Future<String?> userEmailFuture;

  @override
  void initState() {
    super.initState();
    userEmailFuture = DatabaseHelper().getUserEmail();
  }



  void _showAddTodoDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Todo"),
          content: Wrap(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: "Enter todo"),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(hintText: "Enter Description"),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (!mounted) return;

                final title = titleController.text.trim();
                final description = descriptionController.text.trim();
                if (title.isEmpty) return;

                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );

               
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime == null) return;

                String id = FirebaseFirestore.instance.collection('todos').doc().id;
                int alarmId = utf8.encode(id).reduce((a, b) => a + b) % 1000000;

                DateTime finalDateTime = DateTime(
                  pickedDate!.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );

                final newTodo = Todo(
                  id: id,
                  title: title,
                  description: description,
                  completed: false,
                  dueDate: finalDateTime,
                );

                ref.read(addTodoProvider)(newTodo);
                AlarmUtil.setTodoAlarm(alarmId, finalDateTime, title, title);

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todoListAsync = ref.watch(uncompletedTodoListProvider);

    return FutureBuilder<String?>(
      future: userEmailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userEmail = snapshot.data;
        if (userEmail == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sign in to View Todos')),
            body: Center(
              child: ElevatedButton(
                onPressed: () => signIn(ref),
                child: const Text("Sign in with Google"),
              ),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(userProvider.notifier).state = userEmail;
        });

        return Scaffold(
          body: todoListAsync.when(
            data: (todos) => todos.isNotEmpty
                ? ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return Dismissible(
                  key: Key(todo.id),
                  background: Container(color: Colors.red),
                  onDismissed: (_) => ref.read(completeTodoProvider)(todo.id),
                  confirmDismiss: (_) async => await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Remove this Todo?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Remove"),
                        ),
                      ],
                    ),
                  ),
                  child: Card(
                    color: getRandomLightColor(),
                    child: ListTile(
                      title: Text("${todo.title} - ${todo.description}"),
                      subtitle: Text(
                          "Due: ${formatDateTime(todo.dueDate)}"
                      ),
                    ),
                  ),
                );
              },
            )
                : const Center(child: Text("Empty")),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text("Error: $error")),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddTodoDialog(context, ref),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

  Color getRandomLightColor() {
    final Random random = Random();
    return Color.fromARGB(
      255,
      200 + random.nextInt(56), // R (200-255)
      200 + random.nextInt(56), // G (200-255)
      200 + random.nextInt(56), // B (200-255)
    );
  }

String formatDateTime(DateTime dateTime) {
  return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} "
      "${(dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12)}:${dateTime.minute.toString().padLeft(2, '0')} "
      "${dateTime.hour >= 12 ? 'PM' : 'AM'}";
}
