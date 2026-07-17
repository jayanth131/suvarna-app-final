import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all fingerprint / face-ID logic and preference persistence.
/// Keys are per-user so multiple accounts on one device work correctly.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // ─── Preference keys ────────────────────────────────────────────────────────

  static String _enabledKey(String username) => 'biometric_enabled_$username';

  // ─── Device capability ──────────────────────────────────────────────────────

  /// Returns true if the device hardware physically supports biometrics,
  /// regardless of whether any fingerprints or faces are currently enrolled.
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      debugPrint('🔍 [BiometricService:isAvailable] Diagnostic Check:');
      debugPrint('   - canCheckBiometrics: $canCheck');
      debugPrint('   - isDeviceSupported: $isSupported');

      // ✅ FIX: Return true if the sensor exists and is accessible.
      // Do not check if 'enrolled' is empty here; let the UI handle empty enrollments.
      final hardwareAvailable = canCheck || isSupported;
      debugPrint('ℹ️ [BiometricService:isAvailable] Hardware physically available: $hardwareAvailable');
      
      return hardwareAvailable;
    } catch (e, stack) {
      debugPrint('❌ [BiometricService:isAvailable] Exception caught: $e');
      debugPrint('$stack');
      return false;
    }
  }

  /// Returns true specifically if a fingerprint sensor is enrolled.
  /// Falls back to true when any biometric is available (covers face-ID phones).
  static Future<bool> hasFingerprint() async {
    try {
      final enrolled = await _auth.getAvailableBiometrics();
      debugPrint('🔍 [BiometricService:hasFingerprint] Available enrolled types: $enrolled');

      if (enrolled.contains(BiometricType.fingerprint)) {
        debugPrint('✅ [BiometricService:hasFingerprint] Explicit fingerprint hardware profile detected.');
        return true;
      }
      
      // On some Android devices the type is reported as `strong` rather than
      // `fingerprint`, so treat any enrolled biometric as acceptable.
      final hasAnyFallback = enrolled.isNotEmpty;
      debugPrint('ℹ️ [BiometricService:hasFingerprint] Fallback check (enrolled.isNotEmpty): $hasAnyFallback');
      return hasAnyFallback;
    } catch (e, stack) {
      debugPrint('❌ [BiometricService:hasFingerprint] Exception caught: $e');
      debugPrint('$stack');
      return false;
    }
  }

  // ─── Authentication ──────────────────────────────────────────────────────────

  /// Triggers the OS biometric prompt.
  /// Returns true on success, false on failure / cancel.
  static Future<bool> authenticate({
    String reason = 'Verify your identity to continue',
  }) async {
    try {
      debugPrint('🚀 [BiometricService:authenticate] Initializing OS prompt Window...');
      debugPrint('   - Reason string sent: "$reason"');
      
      final bool result = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,   // no PIN/pattern fallback inside prompt
          stickyAuth: true,      // keeps prompt alive if app goes background
          sensitiveTransaction: false,
        ),
      );

      debugPrint('🏁 [BiometricService:authenticate] Native prompt closed. Result: $result');
      return result;
    } catch (e, stack) {
      debugPrint('❌ [BiometricService:authenticate] Critical error or cancellation during prompt challenge: $e');
      debugPrint('👉 Reminder: Ensure your MainActivity extends FlutterFragmentActivity!');
      debugPrint('$stack');
      return false;
    }
  }

  // ─── Per-user preference ─────────────────────────────────────────────────────

  /// Persist whether biometric login is enabled for [username].
  static Future<void> setEnabled(String username, {required bool enabled}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _enabledKey(username);
      final success = await prefs.setBool(key, enabled);
      debugPrint('💾 [BiometricService:setEnabled] Persistence write executed.');
      debugPrint('   - Key: $key');
      debugPrint('   - Set Value: $enabled');
      debugPrint('   - Commit Success Status: $success');
    } catch (e) {
      debugPrint('❌ [BiometricService:setEnabled] Failed to save key value pairs to SharedPreferences: $e');
    }
  }

  /// Whether biometric login is currently enabled for [username].
  static Future<bool> isEnabled(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _enabledKey(username);
      final value = prefs.getBool(key) ?? false;
      debugPrint('📖 [BiometricService:isEnabled] Lookup completed for target account.');
      debugPrint('   - Key searched: $key');
      debugPrint('   - Value retrieved: $value');
      return value;
    } catch (e) {
      debugPrint('❌ [BiometricService:isEnabled] Failed reading from SharedPreferences: $e');
      return false;
    }
  }

  /// Remove biometric preference for [username] (e.g. on logout / MPIN reset).
  static Future<void> clearEnabled(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _enabledKey(username);
      final success = await prefs.remove(key);
      debugPrint('🧹 [BiometricService:clearEnabled] Key clear process handled.');
      debugPrint('   - Targeted Key: $key');
      debugPrint('   - Eviction verified: $success');
    } catch (e) {
      debugPrint('❌ [BiometricService:clearEnabled] Failed resetting entry profile: $e');
    }
  }
}