import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../services/update_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 0. Check for updates
    await UpdateService().checkForUpdates(context);

    // 1. Check Login
    final apiService = ApiService();
    final bool isLoggedIn = await apiService.isLoggedIn();

    if (!isLoggedIn) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    // 2. Fetch Data (Parallel)
    try {
      final results = await Future.wait([
        apiService.getProfile(),
        apiService.getWalletBalance(),
        apiService.getTransactions(),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final wallet = results[1] as Map<String, dynamic>;
      final transactions = results[2] as List<dynamic>;

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              preloadedProfile: profile,
              preloadedWallet: wallet,
              preloadedTransactions: transactions,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error loading initial data: $e");
      // Fallback to Home (it will try to fetch again or show error) or Login
      if (mounted) {
         Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_dark_mode.png',
              height: 100,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
