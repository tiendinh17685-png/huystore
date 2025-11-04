import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/widgets/login_screen.dart';

class HomeScreen extends StatelessWidget {
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _logout(context),
          child: const Text("Logout"),
        ),
      ),
    );
  }
}
