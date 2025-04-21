import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';

class TodoWidgetComplete extends ConsumerWidget{
  const TodoWidgetComplete({super.key});


  @override
  Widget build(BuildContext context,WidgetRef ref) {


    Color getRandomLightColor() {
      final Random random = Random();
      return Color.fromARGB(
        255,
        200 + random.nextInt(56),  // R (200-255)
        200 + random.nextInt(56),  // G (200-255)
        200 + random.nextInt(56),  // B (200-255)
      );
    }

    final todoListAsyncCompleted = ref.watch(completedTodoListProvider);

    // TODO: implement build
    return Scaffold(
      body: todoListAsyncCompleted.when(
        data: (todos) {
          Widget widget;
          todos.isNotEmpty
              ? widget = ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return Dismissible(
                  key: Key(todo.id),
                  background: Container(color: Colors.red),
                  onDismissed: (direction) => ref.read(completeTodoProvider)(todo.id),
                  confirmDismiss: (direction) {
                    return showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Removed this Todo"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text("Remove"),
                            ),
                          ],
                        );
                      },
                    );


                  },
                  child: Card(
                    color: getRandomLightColor(),  // Apply light background color // Random color
                    child: ListTile(
                      title: Text("${todo.title} - ${todo.description}"),
                      subtitle: Text(
                          "Due: ${todo.dueDate.toLocal().year}-${todo.dueDate.toLocal().month.toString().padLeft(2, '0')}-${todo.dueDate.toLocal().day.toString().padLeft(2, '0')} "
                              "${(todo.dueDate.toLocal().hour % 12 == 0 ? 12 : todo.dueDate.toLocal().hour % 12)}:${todo.dueDate.toLocal().minute.toString().padLeft(2, '0')} "
                              "${todo.dueDate.toLocal().hour >= 12 ? 'PM' : 'AM'}"
                      ),
                    ),
                  ));
            },
          )
              : widget = Center(child: Text("Empty"));
          return widget;

        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text("Error: $error")),
      ),
    );
  }

}