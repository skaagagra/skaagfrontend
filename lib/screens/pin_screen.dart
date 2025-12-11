import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/pin_manager.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

enum PinMode { setup, unlock, verify }

class PinScreen extends StatefulWidget {
  final PinMode mode;
  final VoidCallback? onSuccess;

  const PinScreen({super.key, required this.mode, this.onSuccess});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _currentPin = '';
  String _confirmPin = '';
  String _message = '';
  bool _isConfirming = false; // For setup mode

  @override
  void initState() {
    super.initState();
    _updateMessage();
  }

  void _updateMessage() {
    setState(() {
      if (widget.mode == PinMode.unlock) {
        _message = 'Enter PIN to Unlock';
      } else if (widget.mode == PinMode.verify) {
        _message = 'Enter PIN to Verify';
      } else {
        _message = _isConfirming ? 'Confirm PIN' : 'Create PIN';
      }
    });
  }

  void _onDigitPress(String digit) {
    if (_currentPin.length < 4) {
      setState(() {
        _currentPin += digit;
      });

      if (_currentPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onDelete() {
    if (_currentPin.isNotEmpty) {
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      });
    }
  }

  Future<void> _handlePinComplete() async {
    final pinManager = PinManager();

    if (widget.mode == PinMode.unlock || widget.mode == PinMode.verify) {
      bool isValid = await pinManager.verifyPin(_currentPin);
      if (isValid) {
        if (widget.mode == PinMode.unlock) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
           if (widget.onSuccess != null) widget.onSuccess!();
           if (!mounted) return;
           Navigator.pop(context, true); // Return true for verification
        }
      } else {
        setState(() {
          _message = 'Incorrect PIN. Try again.';
          _currentPin = '';
        });
      }
    } else if (widget.mode == PinMode.setup) {
      if (_isConfirming) {
        if (_currentPin == _confirmPin) {
          await pinManager.savePin(_currentPin);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
          );
        } else {
          setState(() {
            _message = 'PINs do not match. Try again.';
            _isConfirming = false;
            _currentPin = '';
            _confirmPin = '';
          });
        }
      } else {
        setState(() {
          _confirmPin = _currentPin;
          _currentPin = '';
          _isConfirming = true;
          _message = 'Confirm PIN';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Skaag Security',
              style: GoogleFonts.outfit(
                color: Colors.blueAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _message,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _currentPin.length
                        ? Colors.blueAccent
                        : Colors.white.withOpacity(0.2),
                  ),
                );
              }),
            ),
            const SizedBox(height: 60),
            Expanded(
              child: _buildKeypad(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: 12, // 0-9, Backspace, Empty
      itemBuilder: (context, index) {
        if (index == 9) return const SizedBox.shrink(); // Empty bottom-left
        if (index == 11) {
          return IconButton(
            onPressed: _onDelete,
            icon: const Icon(Icons.backspace_outlined, color: Colors.white),
          );
        }
        
        String digit = index == 10 ? '0' : '${index + 1}';
        
        return GestureDetector(
          onTap: () => _onDigitPress(digit),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            alignment: Alignment.center,
            child: Text(
              digit,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
