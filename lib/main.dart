import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pin_screen.dart';
import 'services/biometric_service.dart';
import 'services/fcm_service.dart';
import 'utils/pin_manager.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await FcmService().initialize();
  } catch (e) {
    print("Firebase init failed (expected on Web/Windows without config): $e");
  }

  final bool isLoggedIn = await ApiService().isLoggedIn();
  Widget initialRoute = const LoginScreen();

  if (isLoggedIn) {
     final bioService = BiometricService();
     // Authenticate using Biometric or Device PIN
     bool authenticated = await bioService.authenticate(reason: 'Unlock Skaag');
     
     if (authenticated) {
       initialRoute = const HomeScreen();
     } else {
       // If authentication fails (e.g. user cancels), what do we do?
       // For now, we allows them to retry or fallback to login if strictly needed,
       // but typically we just show the auth prompt.
       // Here we might just stay on a "Locked" screen or retry.
       // Let's assume if they fail device auth, they can't enter.
       // But to be safe, let's keep it as HomeScreen if they persist past the prompt? 
       // No, security means NO access.
       // Simply re-prompting or showing a locked screen is better.
       // For simplicity of this task: If auth fails, we show Login (or a Lock Screen).
       // User asked "just ask for biometric ... and just logged in".
       
       // FORCE Authentication loop or exit?
       // Using PinScreen as a fallback locker if device auth fails/unavailable logic isn't fully there.
       // Let's trust device auth returns true. If false, maybe they cancelled.
       // We will exit or show login.
       initialRoute = const LoginScreen(); 
     }
  }
  
  runApp(SkaagApp(initialRoute: initialRoute));
}

class SkaagApp extends StatelessWidget {
  final Widget initialRoute;

  const SkaagApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skaag',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: initialRoute,
    );
  }
}
