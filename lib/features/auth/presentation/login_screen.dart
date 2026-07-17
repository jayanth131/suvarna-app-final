import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../data/auth_service.dart';
import '../../../screens/home_screen.dart';
import 'mpin_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Dedicated FocusNode for the mobile number field so we can drive its
  // custom accessibility Semantics reactively (see _buildIdentifierField).
  final FocusNode _identifierFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _warmupBackend(); // backup warmup in case user navigated directly here
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    super.dispose();
  }

  // Backup warmup — fires when login screen opens
  Future<void> _warmupBackend() async {
    try {
      await http
          .get(
            Uri.parse(
              "https://suvarna-jewellers-customer-backend.vercel.app/api/health",
            ),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  void _announceError(String message) {
    // Programmatically announce validation/login errors to TalkBack
    SemanticsService.announce(message, TextDirection.ltr);
  }

  void _submit() async {
    setState(() => _error = null);

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty) {
      setState(() => _error = "Enter your mobile number");
      _announceError(_error!);
      return;
    }

    if (identifier.length != 10) {
      setState(() => _error = "Enter valid 10-digit mobile number");
      _announceError(_error!);
      return;
    }

    if (password.length < 6) {
      setState(() => _error = "Enter your password");
      _announceError(_error!);
      return;
    }

    setState(() => _isLoading = true);

    final response = await AuthService.login(
      identifier: identifier,
      password: password,
    );

    setState(() => _isLoading = false);

    if (!response.success) {
      setState(() => _error = response.message);
      _announceError(_error!);
      return;
    }

    final String username = _identifierController.text.trim();

    // Navigate immediately — no extra waiting
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MPinScreen(
          mode: response.mpinExists ? MPinMode.verify : MPinMode.setup,
          username: username,
        ),
      ),
      (route) => false,
    );
  }

  /// Mobile number field with digit-by-digit TalkBack reading.
  ///
  /// WHY: TalkBack normally reads a 10-digit number as one long number
  /// ("nine billion, eight hundred..."), which is hard to verify by ear.
  /// The fix is to control exactly what TalkBack announces as the field's
  /// `value`: a version of the digits with a space between each one
  /// ("9 8 7 6 5 4 3 2 1 0"). A space between characters is what makes
  /// TalkBack switch to reading them individually.
  ///
  /// This is built the same reliable way as the Suvarna contact form
  /// fix: one manually-controlled Semantics node (label + spoken value),
  /// reactive via AnimatedBuilder so it updates on every keystroke and
  /// focus change, with the real TextField's own semantics excluded so
  /// there's only a single, unambiguous accessibility node for TalkBack
  /// to land on (whether reached by tap or by swipe).
  Widget _buildIdentifierField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedBuilder(
        animation: Listenable.merge([_identifierController, _identifierFocus]),
        builder: (context, _) {
          final digits = _identifierController.text.trim();
          final spokenValue = digits.isEmpty
              ? null
              : digits.split('').join(' ');

          return Semantics(
            label: "Mobile Number",
            value: spokenValue,
            hint: "Double tap to enter your 10 digit mobile number",
            textField: true,
            focused: _identifierFocus.hasFocus,
            enabled: true,
            child: ExcludeSemantics(
              child: Container(
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
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: const Color(0xFFD4AF37).withOpacity(0.5),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _identifierController,
                        focusNode: _identifierFocus,
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
                    const SizedBox(width: 14),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF5EBDD),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter password",
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
            Semantics(
              // Dynamically changes the announcement based on the current state
              label: _obscurePassword ? 'Show password' : 'Hide password',
              button: true,
              child: GestureDetector(
                onTap: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF6E665A),
                ),
              ),
            ),
          ],
        ),
      ),
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
                      Semantics(
                        label: 'Back',
                        button: true,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 16,
                            color: Color(0xFF7A7267),
                            // No need for semanticLabel here if the Semantics widget handles it
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: Column(
                          children: [
                            Semantics(
                              header:true,
                              headingLevel: 1,
                              child: Text(
                                "Welcome Back",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3B2A1F),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Login to your account",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF8E8578),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildIdentifierField(),
                      _buildPasswordField(),

                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
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
                              : const Text(
                                  "Continue",
                                  style: TextStyle(fontSize: 15),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // FIX (Issue: "Forgot Password" not announced as a
                      // button) — GestureDetector alone has no semantic
                      // role, so TalkBack read it as plain static text.
                      // Wrapping it in Semantics(button: true, ...) makes
                      // it announce as "Forgot Password, Button".
                      Center(
                        child: Semantics(
                          button: true,
                          label: "Forgot Password",
                          excludeSemantics: true,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Forgot Password?",
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
