import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/mpin_screen.dart';
import '../core/session_manager.dart';

class AuthChoiceScreen extends StatefulWidget {
  const AuthChoiceScreen({super.key});

  @override
  State<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends State<AuthChoiceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _hasPreviousSession = false;
  String? _lastPhone;
  String? _lastName;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _checkPreviousSession();
    _warmupBackend(); // fires immediately — warms server before user types
  }

  // Wakes up Vercel cold start — best effort, never blocks UI
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

  Future<void> _checkPreviousSession() async {
    final hasPrev = await SessionManager.hasPreviousSession();
    final lastPhone = await SessionManager.getLastPhone();
    final lastName = await SessionManager.getUserName();

    if (mounted) {
      setState(() {
        _hasPreviousSession = hasPrev;
        _lastPhone = lastPhone;
        _lastName = lastName;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loginWithMpin() {
    if (_lastPhone == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MPinScreen(mode: MPinMode.verify, username: _lastPhone!),
      ),
    );
  }

  void _loginWithPhone() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _onSignUp() {
    Navigator.pushNamed(context, '/signup');
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
            child: Container(color: const Color(0xFFF5EBDD).withOpacity(0.85)),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 96,
                        width: 96,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.85),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "assets/images/suvarna_logo.png",
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Semantics(
                        header: true,
                        headingLevel: 1,
                        child: Text(
                          "Suvarna Jewellers",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3E2C1C),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Build your golden future",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: 280,
                        child: Column(
                          children: [
                            if (_hasPreviousSession && _lastPhone != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFD4AF37,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Welcome back",
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: const Color(0xFF9E8E7E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _lastName ?? _lastPhone!,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF3B2A1F),
                                      ),
                                    ),
                                    Text(
                                      "+91 $_lastPhone",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF9E8E7E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _loginWithMpin,
                                  icon: const Icon(
                                    Icons.lock_outline,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    "Login with MPIN",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4AF37),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 6,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _loginWithPhone,
                                  icon: const Icon(
                                    Icons.phone_outlined,
                                    size: 18,
                                    color: Color(0xFF3E2C1C),
                                  ),
                                  label: const Text(
                                    "Login with Password",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3E2C1C),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(
                                      0.9,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFFD4AF37),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              Semantics(
                                button:
                                    true, // This tells the screen reader it is a clickable button
                                child: GestureDetector(
                                  onTap: _onSignUp,
                                  child: Text(
                                    "New user? Sign Up",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFFB48A2C),
                                      decoration: TextDecoration.underline,
                                      decorationColor: const Color(0xFFB48A2C),
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loginWithPhone,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4AF37),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 6,
                                  ),
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _onSignUp,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(
                                      0.9,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFFD4AF37),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3E2C1C),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
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
