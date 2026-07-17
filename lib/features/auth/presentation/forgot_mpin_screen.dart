import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart'; // Required for keyboard events
import 'package:google_fonts/google_fonts.dart';
import '../data/auth_service.dart';
import 'mpin_screen.dart';

class ForgotMpinScreen extends StatefulWidget {
  const ForgotMpinScreen({super.key});

  @override
  State<ForgotMpinScreen> createState() => _ForgotMpinScreenState();
}

class _ForgotMpinScreenState extends State<ForgotMpinScreen> {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _otpSent = false;
  bool _isLoading = false;
  String? _error;
  bool _isAdvancing = false;

  String get _otp => _otpControllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    for (final node in _otpFocusNodes) {
      node.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  // Helper to announce standard errors (like invalid mobile or account not found)
  void _announceError(String message) {
    setState(() => _error = message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.announce(message, TextDirection.ltr);
    });
  }

  // Helper to announce OTP-specific errors and reset focus
  void _announceOtpErrorAndResetFocus(String message) {
    setState(() {
      _error = message;
      for (final c in _otpControllers) {
        c.clear();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.announce(message, TextDirection.ltr);
      FocusScope.of(context).requestFocus(_otpFocusNodes[0]);
    });
  }

  void _sendOtp() async {
    final phone = _phoneController.text.trim();

    // Mobile Validation with TalkBack announcements
    if (phone.isEmpty) {
      _announceError("Mobile number is required. Please enter your number.");
      return;
    }

    if (phone.length != 10) {
      _announceError("Invalid format. Please enter exactly 10 digits.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService.sendForgotMpinOtp(mobile: phone);

    setState(() => _isLoading = false);

    if (!result.success) {
      // Announces backend errors (e.g., "Account not found")
      _announceError(result.message ?? "Failed to send OTP");
      return;
    }

    setState(() => _otpSent = true);

    // Announce transition and move focus to OTP field 1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.announce(
        "OTP sent. Enter number 1.",
        TextDirection.ltr,
      );
      FocusScope.of(context).requestFocus(_otpFocusNodes[0]);
    });
  }

  void _verifyOtp() async {
    if (_otp.length != 6) {
      _announceOtpErrorAndResetFocus(
        "Enter complete 6-digit OTP. You are missing "
        "${6 - _otp.length} ${6 - _otp.length == 1 ? 'digit' : 'digits'}.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService.verifyForgotMpinOtp(
      mobile: _phoneController.text.trim(),
      otp: _otp,
    );

    setState(() => _isLoading = false);

    if (!result.success) {
      _announceOtpErrorAndResetFocus(result.message ?? "Invalid OTP");
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MPinScreen(
          mode: MPinMode.forgotReset,
          username: _phoneController.text.trim(),
        ),
      ),
    );
  }

  // Integrated focus advancing logic
  void _onOtpChanged(int index, String value) {
    setState(() {});

    if (value.isNotEmpty && index < 5 && !_isAdvancing) {
      _isAdvancing = true;
      final nextIndex = index + 1;
      _otpFocusNodes[nextIndex].requestFocus();
      _isAdvancing = false;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final node in _otpFocusNodes) {
      node.removeListener(_onFocusChange);
    }
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // Advanced OTP Box Builder
  Widget _buildOtpBox(int index) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _otpControllers[index],
      builder: (context, value, child) {
        final digit = value.text;
        final label = digit.isEmpty
            ? "Input field ${index + 1}"
            : "Input field ${index + 1}, $digit";

        return Semantics(
          label: label,
          textField: true,
          focused: _otpFocusNodes[index].hasFocus,
          excludeSemantics: true,
          sortKey: OrdinalSortKey(index.toDouble()),
          child: SizedBox(
            width: 44,
            height: 54,
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace) {
                  if (_otpControllers[index].text.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                maxLength: 1,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF5EBDD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: const Color(0xFFD4AF37).withOpacity(0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: const Color(0xFFD4AF37).withOpacity(0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Color(0xFFD4AF37),
                      width: 1.5,
                    ),
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B2A1F),
                ),
                onChanged: (val) => _onOtpChanged(index, val),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              "assets/images/showroom_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          // Blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: const Color(0xFFF5EBDD).withOpacity(0.70),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F0E4),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      Semantics(
                        label: 'Back',
                        button: true,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 16,
                            color: Color(0xFF7A7267),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title
                      Center(
                        child: Column(
                          children: [
                            Container(
                              height: 52,
                              width: 52,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE9DFCF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_reset,
                                color: Color(0xFFB48A2C),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Semantics(
                              header: true,
                              headingLevel: 1,
                              label: "Reset MPIN",
                              excludeSemantics: true,
                              child: Text(
                                "Reset MPIN",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3B2A1F),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _otpSent
                                  ? "Enter the OTP sent to your phone"
                                  : "Enter your registered mobile number",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF8E8578),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Phone input
                      if (!_otpSent)
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EBDD),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              Text(
                                "+91",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF6E665A),
                                ),
                              ),
                              Container(
                                height: 28,
                                width: 1,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                color: const Color(0xFFD4AF37).withOpacity(0.5),
                              ),
                              Expanded(
                                child: Semantics(
                                  label: "Mobile number",
                                  textField: true,
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "10-digit number",
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: const Color(0xFFB8B0A4),
                                      ),
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF6E665A),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                            ],
                          ),
                        ),

                      // OTP input
                      if (_otpSent)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, _buildOtpBox),
                        ),

                      // Error
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : _otpSent
                                  ? _verifyOtp
                                  : _sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            disabledBackgroundColor:
                                const Color(0xFFD4AF37).withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _otpSent ? "Verify OTP" : "Send OTP",
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      // Change number option
                      if (_otpSent) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Semantics(
                            button: true,
                            label: "Change phone number",
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _otpSent = false;
                                  _error = null;
                                  for (final c in _otpControllers) {
                                    c.clear();
                                  }
                                });
                                // Announce focus returned to phone field
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  SemanticsService.announce(
                                      "Changed number. Enter new number.",
                                      TextDirection.ltr);
                                });
                              },
                              child: Text(
                                "Change number",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFFB48A2C),
                                  decoration: TextDecoration.underline,
                                  decorationColor: const Color(0xFFB48A2C),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}