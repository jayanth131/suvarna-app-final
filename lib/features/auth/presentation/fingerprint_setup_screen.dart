import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../screens/home_screen.dart';
import '../data/biometric_service.dart';

/// Shown once after MPIN setup.
/// User can enable fingerprint login or skip — both lead to HomeScreen.
class FingerprintSetupScreen extends StatefulWidget {
  final String username;

  const FingerprintSetupScreen({super.key, required this.username});

  @override
  State<FingerprintSetupScreen> createState() => _FingerprintSetupScreenState();
}

class _FingerprintSetupScreenState extends State<FingerprintSetupScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _isHardwareEnrolled =
      true; // Tracks if fingerprints exist in OS settings
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Run hardware analysis immediately upon landing on screen
    _checkHardwareEnrollment();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Evaluates whether the phone has saved biometric scanner profiles.
  Future<void> _checkHardwareEnrollment() async {
    debugPrint(
      '⚙️ [FingerprintSetupUI] Initializing hardware registration pre-check...',
    );
    final hasFingerprintProfiles = await BiometricService.hasFingerprint();

    debugPrint(
      '⚙️ [FingerprintSetupUI] Device has registered finger profiles: $hasFingerprintProfiles',
    );

    if (!mounted) return;
    setState(() {
      _isHardwareEnrolled = hasFingerprintProfiles;
    });
  }

  /// Directs the user out of the app straight to their Android/iOS security configurations
  Future<void> _openSystemSecuritySettings() async {
    debugPrint(
      '🎟️ [FingerprintSetupUI] Redirecting user to system biometric security dashboard...',
    );
    try {
      const MethodChannel platform = MethodChannel(
        'plugins.flutter.io/local_auth',
      );
      // Request platform channel engine to switch tasks to native security settings
      await platform.invokeMethod('openSettings');
    } catch (e) {
      debugPrint(
        '❌ [FingerprintSetupUI] Failed to automatically route to system settings panel: $e',
      );
      // Fallback fallback if channel fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open settings automatically. Please open your phone Settings -> Security to add a fingerprint.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF3B2A1F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleEnable() async {
    debugPrint(
      '🔘 [FingerprintSetupUI] "Enable Fingerprint" interaction detected.',
    );
    setState(() => _loading = true);

    // Re-verify enrollment runtime state before attempting challenge
    final stillEnrolled = await BiometricService.hasFingerprint();

    if (!mounted) return;

    if (!stillEnrolled) {
      debugPrint(
        '⚠️ [FingerprintSetupUI] Authentication aborted: Enrolled fingerprint profiles missing.',
      );
      setState(() {
        _loading = false;
        _isHardwareEnrolled = false;
      });
      return;
    }

    debugPrint(
      '🔒 [FingerprintSetupUI] Requesting OS biometric modal challenge...',
    );
    final success = await BiometricService.authenticate(
      reason: 'Touch the sensor to enable fingerprint login',
    );

    debugPrint(
      '🏁 [FingerprintSetupUI] OS biometric evaluation finished. Success outcome: $success',
    );

    if (!mounted) return;

    if (success) {
      debugPrint(
        '💾 [FingerprintSetupUI] Persisting user biometric flag preference to true for: ${widget.username}',
      );
      await BiometricService.setEnabled(widget.username, enabled: true);
      _goHome();
    } else {
      debugPrint(
        '❌ [FingerprintSetupUI] Identity verification challenge rejected or dismissed.',
      );
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fingerprint not recognised. You can try again or enable it later in settings.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF3B2A1F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleSkip() {
    debugPrint(
      '⏭️ [FingerprintSetupUI] User explicitly skipped biometric registration link step.',
    );
    BiometricService.setEnabled(widget.username, enabled: false);
    _goHome();
  }

  void _goHome() {
    debugPrint(
      '🚀 [FingerprintSetupUI] Routing user forward into Dashboard layout views.',
    );
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3E8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // ── Logo ──────────────────────────────────────────────────────
              Image.asset('assets/images/suvarna_logo.png', height: 60),

              const Spacer(),

              // ── Pulsing fingerprint icon ──────────────────────────────────
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE9DFCF),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isHardwareEnrolled
                                    ? const Color(0xFFD4AF37)
                                    : Colors.redAccent)
                                .withOpacity(0.25),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isHardwareEnrolled
                        ? Icons.fingerprint
                        : Icons.lock_open_outlined, // Changed here
                    size: 64,
                    color: _isHardwareEnrolled
                        ? const Color(0xFFB48A2C)
                        : Colors.redAccent,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Headline ──────────────────────────────────────────────────
              Text(
                _isHardwareEnrolled
                    ? 'Enable Fingerprint Login'
                    : 'No Fingerprint Setup Found',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B2A1F),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                _isHardwareEnrolled
                    ? 'Log in instantly next time — no MPIN needed.\nYour fingerprint never leaves this device.'
                    : 'Your device supports biometrics, but no fingerprints are registered in your phone settings.\nSet it up now to get started.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFFA79E91),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // ── Action Button (Dynamic based on hardware setup state) ──────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : (_isHardwareEnrolled
                            ? _handleEnable
                            : _openSystemSecuritySettings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isHardwareEnrolled
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFF3B2A1F),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(
                      0xFFD4AF37,
                    ).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isHardwareEnrolled
                              ? 'Enable Fingerprint'
                              : 'Open Phone Settings',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Skip button ───────────────────────────────────────────────
              TextButton(
                onPressed: _loading ? null : _handleSkip,
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFFA79E91),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
