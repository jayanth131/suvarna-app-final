import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import '../../../core/biometric_service.dart';
import '../../../core/session_manager.dart';
import '../data/auth_service.dart';

class FaceIdEnrollmentDialog extends StatefulWidget {
  final String username;
  final VoidCallback onEnrollmentComplete;
  final VoidCallback onSkip;

  const FaceIdEnrollmentDialog({
    super.key,
    required this.username,
    required this.onEnrollmentComplete,
    required this.onSkip,
  });

  @override
  State<FaceIdEnrollmentDialog> createState() => _FaceIdEnrollmentDialogState();
}

class _FaceIdEnrollmentDialogState extends State<FaceIdEnrollmentDialog> {
  bool _isAuthenticating = false;
  String? _error;
  bool _isSuccess = false;

  Future<void> _vibrateError() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      await Vibration.vibrate(duration: 80);
      await Future.delayed(const Duration(milliseconds: 60));
      await Vibration.vibrate(duration: 80);
    } else {
      HapticFeedback.vibrate();
    }
  }

  Future<void> _vibrateSuccess() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      await Vibration.vibrate(duration: 50, amplitude: 100);
      await Future.delayed(const Duration(milliseconds: 50));
      await Vibration.vibrate(duration: 50, amplitude: 100);
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _enrollFaceId() async {
    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final isAuthenticated = await BiometricService.authenticateWithFaceId(
        localizedReason: "Scan your face to set up Face ID",
      );

      if (!mounted) return;

      if (isAuthenticated) {
        // Face ID authenticated successfully, enable it in backend
        _enableFaceIdBackend();
      } else {
        setState(() {
          _error = "Face ID setup cancelled. Try again?";
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Face ID error: ${e.toString()}";
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _enableFaceIdBackend() async {
    try {
      final result = await AuthService.enableFaceIdForUser(
        username: widget.username,
      );

      if (!mounted) return;

      if (result.success) {
        _vibrateSuccess();
        setState(() {
          _isSuccess = true;
          _isAuthenticating = false;
        });

        // Auto close after 1.5 seconds
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          widget.onEnrollmentComplete();
        }
      } else {
        _vibrateError();
        setState(() {
          _error = result.message ?? "Failed to enable Face ID";
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _vibrateError();
      setState(() {
        _error = "Backend error: ${e.toString()}";
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F3E8),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                if (_isSuccess)
                  Container(
                    height: 64,
                    width: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE1F5FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 36,
                    ),
                  )
                else
                  Container(
                    height: 64,
                    width: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9DFCF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.face,
                      color: Color(0xFFB48A2C),
                      size: 36,
                    ),
                  ),

                const SizedBox(height: 20),

                // Title
                Text(
                  _isSuccess ? "Face ID Enabled!" : "Enable Face ID",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B2A1F),
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle/Description
                Text(
                  _isSuccess
                      ? "You can now log in with your face"
                      : "Faster, more secure login\nwith your face recognition",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFFA79E91),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                // Error message
                if (_error != null && !_isSuccess) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Buttons
                if (!_isSuccess)
                  Column(
                    children: [
                      // Enable Face ID Button
                      GestureDetector(
                        onTap: _isAuthenticating ? null : _enrollFaceId,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isAuthenticating
                                ? const Color(0xFFE0D8CC)
                                : const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isAuthenticating
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        const Color(0xFF3B2A1F).withOpacity(0.6),
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.face,
                                        color: Color(0xFFF8F3E8),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Enable Face ID",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF3B2A1F),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Skip Button
                      GestureDetector(
                        onTap: _isAuthenticating ? null : widget.onSkip,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(
                              color: const Color(0xFFD4AF37),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              "Skip for Now",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB48A2C),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  // Success state - close button
                  GestureDetector(
                    onTap: widget.onEnrollmentComplete,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "Continue",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3B2A1F),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
