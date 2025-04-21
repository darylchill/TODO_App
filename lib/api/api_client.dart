import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';

import '../feature/utils/databaseHelper.dart';
import 'google_signin_service.dart';

part 'api_client.g.dart';

@JsonSerializable()
class Todo {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final DateTime dueDate;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.dueDate,
  });

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
  Map<String, dynamic> toJson() => _$TodoToJson(this);
}

// Firestore Instance Provider
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);


final databaseHelperProvider = Provider((ref) => DatabaseHelper());


final userEmailProvider = FutureProvider<String?>((ref) async {
  final dbHelper = DatabaseHelper();
  final email = await dbHelper.getUserEmail();

  debugPrint("🟡 Fetching email from SQLite...");
  debugPrint("🟢 Fetched email from SQLite: $email");

  return email; // This should return a valid email, not null.
});


// Todo List Provider (Real-time Sync for Logged-in User)
final todoListProvider = StreamProvider<List<Todo>>((ref) {
  final user = ref.watch(userProvider);
  final firestore = ref.watch(firestoreProvider);

  if (user == null) return Stream.value([]); // Return empty list if not signed in

  return firestore
      .collection(user)
      .doc('todos')
      .collection('items')
      .snapshots()
      .asyncMap((snapshot) async {
    List<Todo> firebaseTodos =
    snapshot.docs.map((doc) => Todo.fromJson(doc.data())).toList();

    // Save to SQLite for offline support
    for (var todo in firebaseTodos) {
      await DatabaseHelper.insertTodo(todo);
    }

    // Load local todos if Firebase is empty
    if (firebaseTodos.isEmpty) {
      return await DatabaseHelper.getTodos();
    }

    return firebaseTodos;
  });
});

// Provider for Uncompleted Todos
final uncompletedTodoListProvider = StreamProvider<List<Todo>>((ref) {
  final userEmail = ref.watch(userProvider); // Read email from provider

  debugPrint("✅ Using email: $userEmail");
  final firestore = ref.watch(firestoreProvider);

  if (userEmail == null) return Stream.value([]);

  return firestore
      .collection('users')
      .doc(userEmail)
      .collection('todos')
      .where('completed', isEqualTo: false)
      .snapshots()
      .map((snapshot) =>
      snapshot.docs.map((doc) => Todo.fromJson(doc.data())).toList());
});

// Provider for Completed Todos
final completedTodoListProvider = StreamProvider<List<Todo>>((ref) {
  final userEmail = ref.watch(userProvider);
  final firestore = ref.watch(firestoreProvider);

  if (userEmail == null) return Stream.value([]);

  return firestore
      .collection('users')
      .doc(userEmail)
      .collection('todos')
      .where('completed', isEqualTo: true)
      .snapshots()
      .map((snapshot) =>
      snapshot.docs.map((doc) => Todo.fromJson(doc.data())).toList());
});

// Add Todo Provider
final addTodoProvider = Provider((ref) {
  final userEmail = ref.watch(userProvider); // Read email from provider

  debugPrint("✅ Using email: $userEmail");

  final firestore = ref.watch(firestoreProvider);


  return (Todo todo) {
    firestore
        .collection('users')
        .doc(userEmail)
        .collection('todos')
        .doc(todo.id)
        .set(todo.toJson());
  };
});
// Update Todo Completion Status
final updateTodoProvider = Provider((ref) {
  final userEmail = ref.watch(userProvider);
  final firestore = ref.watch(firestoreProvider);

  return (String id, bool completed) {
    if (userEmail == null) return;
    firestore
        .collection('users')
        .doc(userEmail)
        .collection('todos')
        .doc(id)
        .update({'completed': completed});
  };
});

// Complete Todo Provider
final completeTodoProvider = Provider((ref) {
  final userEmail = ref.watch(userProvider);
  final firestore = ref.watch(firestoreProvider);

  return (String id) {
    if (userEmail == null) return;
    firestore
        .collection('users')
        .doc(userEmail)
        .collection('todos')
        .doc(id)
        .update({'completed': true});
  };
});
