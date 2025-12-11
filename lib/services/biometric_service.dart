import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      // Handle error or return false
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Please authenticate to proceed'}) async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: reason,
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      // Handle error (e.g., user cancelled)
      return false;
    }
  }
}
