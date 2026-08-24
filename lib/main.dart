import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const HelmetStoreApp());
}

class HelmetStoreApp extends StatelessWidget {
  const HelmetStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Helmet Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A237E),
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF1565C0),
          secondary: const Color(0xFF42A5F5),
          surface: const Color(0xFF2A2A2D),
        ),
        fontFamily: 'Roboto',
      ),
      home: AuthService.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
