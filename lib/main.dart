import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pin_screen.dart';
import 'services/biometric_service.dart';
import 'utils/pin_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isPinSet = await PinManager().isPinSet();
  
  Widget initialRoute = const LoginScreen();

  if (isPinSet) {
    // Try Biometric First
    final bioService = BiometricService();
    if (await bioService.isDeviceSupported()) {
       bool authenticated = await bioService.authenticate(reason: 'Unlock Skaag');
       if (authenticated) {
         initialRoute = const HomeScreen();
       } else {
         initialRoute = const PinScreen(mode: PinMode.unlock);
       }
    } else {
       initialRoute = const PinScreen(mode: PinMode.unlock);
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
