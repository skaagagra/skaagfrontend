import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import 'home_screen.dart';
import 'pin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum LoginStep { enterPhone, confirmPhone }

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();

  final _nameController = TextEditingController();
  final _confirmPhoneController = TextEditingController();
  LoginStep _step = LoginStep.enterPhone;
  bool _isLoading = false;

  Future<void> _handleNext() async {
    if (_step == LoginStep.enterPhone) {
      if (_phoneController.text.length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid phone number')));
        return;
      }
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name')));
        return;
      }
      setState(() => _step = LoginStep.confirmPhone);
    } else {
      // Confirm Step
      if (_phoneController.text != _confirmPhoneController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone numbers do not match')));
        return;
      }
      
      await _performLoginAndSetupPin();
    }
  }

  Future<void> _performLoginAndSetupPin() async {
    setState(() => _isLoading = true);

    try {
      await ApiService().login(_phoneController.text, _nameController.text);
      
      if (!mounted) return;
      
      // Check for Biometric Support
      final bioService = BiometricService();
      if (await bioService.isDeviceSupported()) {
         // Ask to enable biometric
         bool authenticated = await bioService.authenticate(reason: 'Authenticate to enable biometric login');
         if (authenticated) {
            // Biometric enabled implicitly by successfully authenticating once
            // In a real app, you might save a flag like 'biometric_enabled' in SharedPreferences
         }
      }

      if (!mounted) return;
      // Navigate to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Skaag',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 48),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _step == LoginStep.enterPhone 
                    ? _buildPhoneInput() 
                    : _buildConfirmInput(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _step == LoginStep.enterPhone ? 'CONTINUE' : 'VERIFY & SETUP PIN',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                  ),
                ),
                if (_step == LoginStep.confirmPhone)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      onPressed: () => setState(() => _step = LoginStep.enterPhone),
                      child: Text('Edit Phone Number', style: GoogleFonts.outfit(color: Colors.white70)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      key: const ValueKey('phoneInput'),
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Enter Phone Number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildConfirmInput() {
    return Column(
      key: const ValueKey('confirmInput'),
      children: [
        Text(
          'Confirm your number to secure your account',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPhoneController,
          label: 'Re-enter Phone Number',
          icon: Icons.check_circle_outline,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
