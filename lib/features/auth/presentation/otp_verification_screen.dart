import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart'; // Required for OrdinalSortKey
import 'package:google_fonts/google_fonts.dart';
import 'mpin_screen.dart';
import '../data/auth_service.dart';
import 'package:flutter/services.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String fullName;
  final String mobile;
  final String password;

  const OtpVerificationScreen({
    super.key,
    required this.fullName,
    required this.mobile,
    required this.password,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;

  // Guards against the focus-listener setState and the onChanged-driven
  // requestFocus() firing in the same frame and racing each other, which
  // is what caused the accessibility highlight to skip a box (jumping
  // straight from box 1 to box 3 instead of stopping on box 2).
  bool _isAdvancing = false;

  String get _otp => _controllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otp.length == 6;

  @override
  void initState() {
    super.initState();
    for (final node in _focusNodes) {
      node.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _onOtpChanged(int index, String value) {
    setState(() {});

    if (value.isNotEmpty && index < 5 && !_isAdvancing) {
      _isAdvancing = true;
      final nextIndex = index + 1;
      // Request focus immediately rather than deferring to
      // addPostFrameCallback — the deferral was letting the focus-node
      // listener's setState land on a stale frame, which is what caused
      // the accessibility highlight to skip over a box.
      _focusNodes[nextIndex].requestFocus();
      _isAdvancing = false;
    }
  }

  void _verifyOtp() async {
    if (!_isOtpComplete) return;

    setState(() => _isLoading = true);

    final otpResponse = await AuthService.verifySignupOtp(
      mobile: widget.mobile,
      otp: _otp,
    );

    if (!otpResponse.success) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(otpResponse.message ?? "Invalid OTP")),
      );
      return;
    }

    final signupResponse = await AuthService.register(
      fullName: widget.fullName,
      mobile: widget.mobile,
      password: widget.password,
    );

    setState(() => _isLoading = false);

    if (!signupResponse.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(signupResponse.message ?? "Signup failed")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MPinScreen(mode: MPinMode.setup, username: widget.mobile),
      ),
    );
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.removeListener(_onFocusChange);
    }
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Widget _buildOtpBox(int index) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controllers[index],
      builder: (context, value, child) {
        final digit = value.text;
        final label = digit.isEmpty
            ? "Input field ${index + 1}"
            : "Input field ${index + 1}, $digit";

        return Semantics(
          label: label,
          textField: true,
          focused: _focusNodes[index].hasFocus,
          excludeSemantics: true,
          sortKey: OrdinalSortKey(index.toDouble()),
          child: SizedBox(
            width: 44,
            height: 54,
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace) {
                  if (_controllers[index].text.isEmpty && index > 0) {
                    _focusNodes[index - 1].requestFocus();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                maxLength: 1,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF5EBDD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
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
          Positioned.fill(
            child: Image.asset(
              "assets/images/showroom_bg.png",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: const Color(0xFFF5EBDD).withValues(alpha: 0.65),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 26,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F3E8).withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        button: true,
                        label: "Back",
                        onTapHint: "activate",
                        excludeSemantics: true,
                        onTap: () => Navigator.pop(context),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 14,
                                  color: Color(0xFF6E665A),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Back",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF6E665A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        "Create Account",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B2A1F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Verify the OTP sent to your phone",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFFA79E91),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, _buildOtpBox),
                      ),
                      const SizedBox(height: 28),
                      Semantics(
                        sortKey: const OrdinalSortKey(6.0),
                        button: true,
                        label: _isLoading
                            ? "Verifying, please wait"
                            : "Verify and Continue",
                        onTapHint: "activate",
                        excludeSemantics: true,
                        onTap: _isOtpComplete && !_isLoading
                            ? _verifyOtp
                            : null,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isOtpComplete && !_isLoading
                                ? _verifyOtp
                                : null,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text("Verify & Continue"),
                          ),
                        ),
                      ),
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