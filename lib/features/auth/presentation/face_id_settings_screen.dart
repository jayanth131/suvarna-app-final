import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import '../../../core/biometric_service.dart';
import '../../../core/session_manager.dart';
import '../data/auth_service.dart';

class FaceIdSettingsScreen extends StatefulWidget {
  final String username;

  const FaceIdSettingsScreen({
    super.key,
    required this.username,
  });

  @override
  State<FaceIdSettingsScreen> createState() => _FaceIdSettingsScreenState();
}

class _FaceIdSettingsScreenState extends State<FaceIdSettingsScreen> {
  bool _isFaceIdEnabled = false;
  bool _isFaceIdAvailable = false;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeFaceIdStatus();
  }

  Future<void> _initializeFaceIdStatus() async {
    try {
      final isFaceIdAvailable =
          await BiometricService.isFaceIdAvailable();
      final isFaceIdEnabled =
          await SessionManager.isFaceIdEnabled(widget.username);

      setState(() {
        _isFaceIdAvailable = isFaceIdAvailable;
        _isFaceIdEnabled = isFaceIdEnabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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

  Future<void> _updateFaceId() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final isAuthenticated = await BiometricService.authenticateWithFaceId(
        localizedReason: "Update your Face ID",
      );

      if (!mounted) return;

      if (isAuthenticated) {
        // Face ID authenticated, update backend
        _updateFaceIdBackend();
      } else {
        setState(() {
          _isProcessing = false;
          _error = "Face ID update cancelled";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Face ID error: ${e.toString()}";
        _isProcessing = false;
      });
    }
  }

  Future<void> _updateFaceIdBackend() async {
    try {
      final result = await AuthService.enableFaceIdForUser(
        username: widget.username,
      );

      if (!mounted) return;

      if (result.success) {
        _vibrateSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Face ID updated successfully",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      } else {
        _vibrateError();
        setState(() {
          _error = result.message ?? "Failed to update Face ID";
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _vibrateError();
      setState(() {
        _error = "Backend error: ${e.toString()}";
        _isProcessing = false;
      });
    }
  }

  Future<void> _enableFaceId() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final isAuthenticated = await BiometricService.authenticateWithFaceId(
        localizedReason: "Enable Face ID for your account",
      );

      if (!mounted) return;

      if (isAuthenticated) {
        _enableFaceIdBackend();
      } else {
        setState(() {
          _isProcessing = false;
          _error = "Face ID setup cancelled";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Face ID error: ${e.toString()}";
        _isProcessing = false;
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
          _isFaceIdEnabled = true;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Face ID enabled successfully",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _vibrateError();
        setState(() {
          _error = result.message ?? "Failed to enable Face ID";
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _vibrateError();
      setState(() {
        _error = "Backend error: ${e.toString()}";
        _isProcessing = false;
      });
    }
  }

  void _showDisableFaceIdDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F3E8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_outlined,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Disable Face ID?",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B2A1F),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "You'll need to use your MPIN to log in",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFFA79E91),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFD4AF37),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB48A2C),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _disableFaceId();
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "Disable",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _disableFaceId() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await AuthService.disableFaceIdForUser(
        username: widget.username,
      );

      if (!mounted) return;

      if (result.success) {
        _vibrateSuccess();
        setState(() {
          _isFaceIdEnabled = false;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Face ID disabled",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _vibrateError();
        setState(() {
          _error = result.message ?? "Failed to disable Face ID";
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _vibrateError();
      setState(() {
        _error = "Backend error: ${e.toString()}";
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F3E8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3B2A1F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Face ID Settings",
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3B2A1F),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFFD4AF37).withOpacity(0.7),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isFaceIdEnabled
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isFaceIdEnabled
                            ? Colors.green.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isFaceIdEnabled ? Icons.check_circle : Icons.info,
                          color: _isFaceIdEnabled ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isFaceIdEnabled
                                    ? "Face ID Enabled"
                                    : "Face ID Disabled",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _isFaceIdEnabled
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isFaceIdEnabled
                                    ? "You can use Face ID to log in"
                                    : "Enable Face ID for faster login",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFFA79E91),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Device Support
                  Text(
                    "Device Support",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB48A2C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isFaceIdAvailable
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _isFaceIdAvailable
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isFaceIdAvailable
                              ? "Face ID available on this device"
                              : "Face ID not available on this device",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF3B2A1F),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Error Message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  if (_isFaceIdAvailable)
                    Column(
                      children: [
                        if (_isFaceIdEnabled) ...[
                          // Update Face ID Button
                          GestureDetector(
                            onTap: _isProcessing ? null : _updateFaceId,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: _isProcessing
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
                                child: _isProcessing
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            const Color(0xFF3B2A1F)
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        "Update Face ID",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF3B2A1F),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Disable Face ID Button
                          GestureDetector(
                            onTap: _isProcessing
                                ? null
                                : _showDisableFaceIdDialog,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.5),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  "Disable Face ID",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          // Enable Face ID Button
                          GestureDetector(
                            onTap: _isProcessing ? null : _enableFaceId,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: _isProcessing
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
                                child: _isProcessing
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            const Color(0xFF3B2A1F)
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                        ],
                      ],
                    ),

                  const SizedBox(height: 32),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "About Face ID",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3B2A1F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "• Faster and more convenient login\n• Secure biometric authentication\n• You can still use MPIN anytime\n• Your Face ID data never leaves your device",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFFA79E91),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
