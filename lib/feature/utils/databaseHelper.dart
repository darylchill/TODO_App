import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../api/api_client.dart';


class DatabaseHelper {
  static Database? _database;
  static const String _dbName = "todos.db";
  static const String _userTable = "user";

  /// Get Database Instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    return await _initDB();
  }

  /// Initialize Database
  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE todos (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            completed INTEGER NOT NULL,
            dueDate TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE user (
            id TEXT PRIMARY KEY,
            email TEXT NOT NULL
          )
        ''');
      },
    );
  }

   Future<void> saveUserEmail(String email) async {
    final db = await database;
    await db.insert(_userTable, {'email': email},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

   Future<String?> getUserEmail() async {
    final db = await database;
    final result = await db.query(_userTable);
    if (result.isNotEmpty) {
      return result.first['email'] as String?;
    }
    return null;
  }

   Future<void> clearUserEmail() async {
    final db = await database;
    await db.delete(_userTable);
  }


  /// **Insert a Todo**
  static Future<void> insertTodo(Todo todo) async {
    final db = await database;
    await db.insert(
      'todos',
      {
        'id': todo.id,
        'title': todo.title,
        'completed': todo.completed ? 1 : 0,
        'dueDate': todo.dueDate.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// **Retrieve All Todos**
  static Future<List<Todo>> getTodos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('todos');

    return maps.map((map) => Todo(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      completed: map['completed'] == 1,
      dueDate: DateTime.parse(map['dueDate']),
    )).toList();
  }

  /// **Update Todo Completion Status**
  static Future<void> updateTodo(String id, bool completed) async {
    final db = await database;
    await db.update(
      'todos',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
