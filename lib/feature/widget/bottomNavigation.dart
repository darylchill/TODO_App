import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_todo_app/feature/widget/todo.dart';
import 'package:flutter_todo_app/feature/widget/todoComplete.dart';

import '../../api/google_signin_service.dart';
import '../utils/databaseHelper.dart'; // Import the sign-in logic

class BottomNavigationBarTodo extends ConsumerStatefulWidget {
  const BottomNavigationBarTodo({super.key});

  @override
  ConsumerState<BottomNavigationBarTodo> createState() => _BottomNavigationBarTodoState();
}

class _BottomNavigationBarTodoState extends ConsumerState<BottomNavigationBarTodo> {

  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInBack,
    );
  }

  Future<void> restoreSession(WidgetRef ref) async {
    final databaseHelper =  DatabaseHelper();
    String? savedEmail = await databaseHelper.getUserEmail();

    if (savedEmail != null) {
      ref.read(userProvider.notifier).state = savedEmail; // Save email only
    }
  }


  @override
  void initState() {
    super.initState();
    restoreSession(ref); // ✅ Restore saved session on app launch

  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: user == null
            ? const Text('Sign in to View Todos')
            : Text('Todo List'),
        actions: [
          user == null
              ? IconButton(
            icon: Icon(Icons.login),
            onPressed: () => signIn(ref),
          )
              : IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => signOut(ref),
          ),
        ],
      ),
      body: user == null
          ? Center(
        child: ElevatedButton(
          onPressed: () => signIn(ref),
          child: Text("Sign in with Google"),
        ),
      )
          : PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          TodoWidget(),
          TodoWidgetComplete(),
        ],
      ),
      bottomNavigationBar: user == null
          ? null
          : BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'TODO'),
          BottomNavigationBarItem(icon: Icon(Icons.check), label: 'History'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onNavItemTapped,
      ),
    );
  }
}
