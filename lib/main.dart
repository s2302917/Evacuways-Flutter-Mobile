import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'controllers/auth_controller.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/main_shell.dart';
import 'screens/chat_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/discovery_screen.dart';

void main() {
  HttpOverrides.global =
      MyHttpOverrides(); // Allow bad SSL certificates globally
  runApp(const EvacuWaysApp());
}

class EvacuWaysApp extends StatelessWidget {
  const EvacuWaysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EvacuWays',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5F7A),
          primary: const Color(0xFF1A5F7A),
          error: const Color(0xFFD32F2F),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFE8EAED),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A5F7A), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/password-reset': (context) => const PasswordResetScreen(),
        '/home': (context) => const MainShell(),
        '/sos': (context) => const SOSScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/discovery': (context) => const DiscoveryScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: args['otherUserId'],
              receiverType: args['receiverType'] ?? 'user',
              name: args['name'] ?? 'Unknown',
              subtitle: args['subtitle'] ?? 'Active',
              color: args['color'] ?? const Color(0xFF1A5F7A),
            ),
          );
        }
        return null;
      },
    );
  }
}
