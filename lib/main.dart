import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:login/admin_dashboard.dart';
import 'package:login/admin_login.dart';
import 'package:login/login_screen.dart';
import 'package:login/sign_up.dart';
import 'package:login/student_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Portal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/student-dashboard': (context) => const StudentDashboard(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin-dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}
