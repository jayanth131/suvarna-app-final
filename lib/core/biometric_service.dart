import 'package:local_auth/local_auth.dart';
import 'dart:io' show Platform;

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometric authentication
  static Future<bool> canAuthenticateWithBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('Error checking biometric capability: $e');
      return false;
    }
  }

  /// Get list of available biometrics on device
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      return availableBiometrics;
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometrics (Face ID, Touch ID, Fingerprint)
  static Future<bool> authenticateWithBiometrics({
    required String localizedReason,
    bool isSensitiveTransaction = false,
  }) async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          sensitiveTransaction: isSensitiveTransaction,
        ),
      );
      return isAuthenticated;
    } catch (e) {
      print('Error during biometric authentication: $e');
      return false;
    }
  }

  /// Stop ongoing authentication
  static Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      print('Error stopping authentication: $e');
    }
  }
}
