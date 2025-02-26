import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_todo_app/feature/utils/permissions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'feature/utils/alarm.dart';
import 'feature/widget/bottomNavigation.dart';
import 'firebase_options.dart';


main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AlarmUtil.initialize();
  runApp(ProviderScope(child: TodoApp()));

  await PermissionUtil.requestPermissions([
    Permission.notification,
  ]);

}




class TodoApp extends StatelessWidget{
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BottomNavigationBarTodo(),
    );
  }

}
