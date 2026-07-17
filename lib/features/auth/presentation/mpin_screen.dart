import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import '../../../screens/home_screen.dart';
import '../data/auth_service.dart';
import '../data/biometric_service.dart';
import '../../../core/session_manager.dart';
import 'forgot_mpin_screen.dart';

enum MPinMode { setup, verify, forgotReset }

class MPinScreen extends StatefulWidget {
  final MPinMode mode;
  final String username;

  const MPinScreen({super.key, required this.mode, required this.username});

  @override
  State<MPinScreen> createState() => _MPinScreenState();
}

class _MPinScreenState extends State<MPinScreen> {
  static const int maxLength = 4;

  String _mpin = '';
  String _confirmMpin = '';
  bool _isConfirmStep = false;
  String? _error;

  // FocusNode for the title so TalkBack lands here after biometric resolves.
  final FocusNode _titleFocusNode = FocusNode(debugLabel: 'title');
  final FocusNode _mpinFocusNode = FocusNode();

  // ACCESSIBILITY: every key gets its own FocusNode.
  final Map<String, FocusNode> _keyFocusNodes = {
    for (final k in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'del'])
      k: FocusNode(debugLabel: 'key_$k'),
  };

  FocusNode get _keypadOneFocusNode => _keyFocusNodes['1']!;

  @override
  void initState() {
    super.initState();
    if (widget.mode == MPinMode.verify && !Platform.isIOS) {
      _checkAndRunBiometrics();
    }
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _mpinFocusNode.dispose();
    for (final node in _keyFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  // ─── Biometric helpers ──────────────────────────────────────────────────────

  Future<void> _checkAndRunBiometrics() async {
    final hardwareSupported = await BiometricService.isAvailable();
    final hasEnrolledFingers = await BiometricService.hasFingerprint();

    debugPrint(
      '🔍 [MPinScreen] Hardware: $hardwareSupported, Enrolled: $hasEnrolledFingers',
    );

    if (!mounted) return;

    if (hardwareSupported && hasEnrolledFingers) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _triggerBiometric();
    } else if (hardwareSupported && !hasEnrolledFingers) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext ctx) => _buildEnrollmentDialog(ctx),
        ).then((_) {
          if (mounted) _revealScreenAfterBiometric();
        });
      }
    } else {
      _revealScreenAfterBiometric();
    }
  }

  Widget _buildEnrollmentDialog(BuildContext ctx) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF8F3E8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Fingerprint Disabled',
        style: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF3B2A1F),
        ),
      ),
      content: Text(
        'Your device supports fingerprint login, but no fingerprints are registered.\n\nPlease go to your device Settings to set up a fingerprint for faster login.',
        style: GoogleFonts.poppins(
          color: const Color(0xFF6E665A),
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: const Color(0xFFA79E91)),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            debugPrint('⚙️ Opening device security settings...');
            const MethodChannel intentChannel = MethodChannel(
              'suvarna_jewellers/system_intent',
            );
            try {
              await intentChannel.invokeMethod('openSecuritySettings');
            } catch (e) {
              debugPrint('❌ Native intent failed: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Could not launch settings automatically. Please open Settings → Security to add a fingerprint.',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    backgroundColor: const Color(0xFF3B2A1F),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Setup Fingerprint',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _triggerBiometric() async {
    final success = await BiometricService.authenticate(
      reason: 'Use your fingerprint to log in',
    );
    if (!mounted) return;
    if (success) {
      await SessionManager.saveLoginSession(widget.username);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _revealScreenAfterBiometric();
    }
  }

  void _revealScreenAfterBiometric() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        FocusScope.of(context).requestFocus(_titleFocusNode);
      });
    });
  }

  // ─── Getters & Haptics ───────────────────────────────────────────────────

  String get _currentValue => _isConfirmStep ? _confirmMpin : _mpin;

  Future<void> _vibrateDigit() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      Vibration.vibrate(duration: 40, amplitude: 80);
    } else {
      HapticFeedback.mediumImpact();
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

  Future<void> _vibrateDelete() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      Vibration.vibrate(duration: 25, amplitude: 50);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _triggerError(String errorMessage) {
    _vibrateError();

    setState(() {
      _error = errorMessage;
      _mpin = '';
      _confirmMpin = '';
      _isConfirmStep = false;
    });

    SemanticsService.announce(errorMessage, TextDirection.ltr);

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _moveFocusToDigitOne();
    });
  }

  void _moveFocusToDigitOne() {
    FocusManager.instance.primaryFocus?.unfocus();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_keypadOneFocusNode);
    });
  }

  void _handleDigit(String digit) {
    if (_currentValue.length >= maxLength) return;

    _vibrateDigit();

    setState(() {
      _error = null;
      if (_isConfirmStep) {
        _confirmMpin += digit;
      } else {
        _mpin += digit;
      }
    });

    if (_currentValue.length < maxLength) {
      // FIX: Force digit-by-digit reading with commas
      final spokenMpin = _currentValue.split('').join(', ');
      SemanticsService.announce(
        "$digit entered. Current MPIN is: $spokenMpin.",
        TextDirection.ltr,
      );
    }

    if (_currentValue.length == maxLength) {
      // FIX: Force digit-by-digit reading with commas
      final spokenMpin = _currentValue.split('').join(', ');
      SemanticsService.announce(
        "$digit entered. MPIN complete: $spokenMpin. Processing.",
        TextDirection.ltr,
      );

      Future.delayed(const Duration(milliseconds: 80), () {
        _processCompletion();
      });
    }
  }

  void _handleDelete() {
    _vibrateDelete();
    setState(() {
      _error = null;
      if (_isConfirmStep && _confirmMpin.isNotEmpty) {
        _confirmMpin = _confirmMpin.substring(0, _confirmMpin.length - 1);
      } else if (!_isConfirmStep && _mpin.isNotEmpty) {
        _mpin = _mpin.substring(0, _mpin.length - 1);
      }
    });

    if (_currentValue.isEmpty) {
      SemanticsService.announce(
        "Deleted. MPIN is now empty.",
        TextDirection.ltr,
      );
    } else {
      // FIX: Force digit-by-digit reading with commas
      final spokenMpin = _currentValue.split('').join(', ');
      SemanticsService.announce(
        "Deleted. Current MPIN is: $spokenMpin.",
        TextDirection.ltr,
      );
    }
  }

  void _processCompletion() {
    if (widget.mode == MPinMode.verify) {
      _onComplete(_currentValue);
      return;
    }

    if (!_isConfirmStep) {
      setState(() => _isConfirmStep = true);

      FocusScope.of(context).unfocus();
      SemanticsService.announce(
        "Confirm MPIN. Please re-enter your MPIN.",
        TextDirection.ltr,
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _mpinFocusNode.requestFocus();
      });
      return;
    }

    if (_mpin == _confirmMpin) {
      _onComplete(_mpin);
    } else {
      _triggerError("MPIN mismatch. Please create it again.");
    }
  }

  void _onComplete(String mpin) async {
    if (widget.mode == MPinMode.setup || widget.mode == MPinMode.forgotReset) {
      final result = widget.mode == MPinMode.forgotReset
          ? await AuthService.resetMpin(mobile: widget.username, mpin: mpin)
          : await AuthService.setMpin(username: widget.username, mpin: mpin);

      if (!result.success) {
        _triggerError(result.message ?? "Failed to save MPIN. Try again.");
        return;
      }

      await SessionManager.saveLoginSession(widget.username);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }

    if (widget.mode == MPinMode.verify) {
      final result = await AuthService.verifyMpin(
        username: widget.username,
        mpin: mpin,
      );

      if (!result.success) {
        _triggerError(result.message ?? "Incorrect MPIN entered. Try again.");
        return;
      }

      await SessionManager.saveLoginSession(widget.username);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSetup =
        widget.mode == MPinMode.setup || widget.mode == MPinMode.forgotReset;

    // FIX: Simplified label, removing manual string concatenations
    String semanticFieldLabel = isSetup
        ? (_isConfirmStep ? "Confirm MPIN" : "Create MPIN")
        : "Enter MPIN";

    if (_error != null) {
      semanticFieldLabel = "Error: $_error. $semanticFieldLabel";
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8F3E8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  Image.asset("assets/images/suvarna_logo.png", height: 70),

                  const SizedBox(height: 24),

                  Container(
                    height: 48,
                    width: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9DFCF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFFB48A2C),
                      size: 22,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Focus(
                    focusNode: _titleFocusNode,
                    child: ListenableBuilder(
                      listenable: _titleFocusNode,
                      builder: (context, _) => Semantics(
                        header: true,
                        focusable: true,
                        focused: _titleFocusNode.hasFocus,
                        label: isSetup
                            ? (_isConfirmStep ? "Confirm MPIN" : "Create MPIN")
                            : "Enter MPIN",
                        excludeSemantics: true,
                        child: Text(
                          isSetup
                              ? (_isConfirmStep
                                  ? "Confirm MPIN"
                                  : "Create MPIN")
                              : "Enter MPIN",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3B2A1F),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    isSetup
                        ? (_isConfirmStep
                            ? "Re-enter your MPIN to confirm"
                            : "Set a 4-digit MPIN for quick access")
                        : "Enter your 4-digit MPIN to continue",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFFA79E91),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Focus(
                    focusNode: _mpinFocusNode,
                    child: ListenableBuilder(
                      listenable: _mpinFocusNode,
                      builder: (context, _) {
                        // FIX: Add commas to force TalkBack to read digit-by-digit natively
                        final spelledOutValue = _currentValue.split('').join(', ');

                        return Semantics(
                          focusable: true,
                          focused: _mpinFocusNode.hasFocus,
                          textField: true,
                          value: spelledOutValue,
                          
                          excludeSemantics: true,
                          label: semanticFieldLabel,
                          child: GestureDetector(
                            onTap: () => _mpinFocusNode.requestFocus(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                maxLength,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  height: 14,
                                  width: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index < _currentValue.length
                                        ? const Color(0xFFD4AF37)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    ExcludeSemantics(
                      child: Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemBuilder: (context, index) {
                        final keys = [
                          '1', '2', '3',
                          '4', '5', '6',
                          '7', '8', '9',
                          '',  '0', 'del',
                        ];
                        final key = keys[index];

                        if (key.isEmpty) return const SizedBox();

                        if (key == 'del') {
                          return _buildKey(
                            icon: Icons.backspace_outlined,
                            onTap: _handleDelete,
                            isDelete: true,
                            focusNode: _keyFocusNodes['del']!,
                          );
                        }

                        return _buildKey(
                          label: key,
                          onTap: () => _handleDigit(key),
                          focusNode: _keyFocusNodes[key]!,
                        );
                      },
                    ),
                  ),

                  if (widget.mode == MPinMode.verify) ...[
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotMpinScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Forgot MPIN?",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFFB48A2C),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKey({
    String? label,
    IconData? icon,
    required VoidCallback onTap,
    bool isDelete = false,
    required FocusNode focusNode,
  }) {
    final semanticLabel = isDelete
        ? "Backspace, double tap to delete"
        : "Digit ${label ?? ''}, double tap to enter";

    return Focus(
      focusNode: focusNode,
      child: ListenableBuilder(
        listenable: focusNode,
        builder: (context, _) {
          return Semantics(
            button: true,
            focusable: true,
            focused: focusNode.hasFocus,
            label: semanticLabel,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () {
                focusNode.requestFocus();
                onTap();
              },
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: isDelete
                      ? const Color(0xFFE0D8CC)
                      : const Color(0xFFF1E8DA),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: icon != null
                      ? Icon(icon, color: const Color(0xFF6E665A))
                      : Text(
                          label!,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3B2A1F),
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}