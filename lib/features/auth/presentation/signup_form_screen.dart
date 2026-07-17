import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp_verification_screen.dart';
import '../data/auth_service.dart';

class SignUpFormScreen extends StatefulWidget {
  const SignUpFormScreen({super.key});

  @override
  State<SignUpFormScreen> createState() => _SignUpFormScreenState();
}

class _SignUpFormScreenState extends State<SignUpFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileController   = TextEditingController();
  final TextEditingController _passwordController  = TextEditingController();

  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _mobileFocus   = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _continueFocus = FocusNode();

  final GlobalKey _fullNameKey = GlobalKey();
  final GlobalKey _mobileKey   = GlobalKey();
  final GlobalKey _passwordKey = GlobalKey();

  String? _errorField; // 'fullName' | 'mobile' | 'password'
  int _errorRequestId = 0;

  // Tracks the mobile field's last known TEXT (not selection) so we can
  // rebuild its Semantics node only when the digits actually change —
  // not on every cursor move. TextEditingController notifies listeners
  // for selection-only changes too; if we rebuilt on those as well, the
  // Semantics value would get re-read on every swipe and stack a second
  // announcement on top of the one we fire manually for the crossed
  // digit. This guard is what keeps swipe-navigation to a single,
  // clean announcement.
  String _lastMobileText = '';

  // Guards the manual per-character announce fired during cursor swipe
  // against Android occasionally delivering the same cursor-move action
  // twice for one swipe — only the call that still owns the latest
  // token after a short delay is allowed to actually speak.
  int _cursorMoveToken = 0;

  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool _isLoading       = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _lastMobileText = _mobileController.text;
    _mobileController.addListener(_onMobileControllerChanged);
  }

  void _onMobileControllerChanged() {
    if (_mobileController.text != _lastMobileText) {
      _lastMobileText = _mobileController.text;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _fullNameFocus.dispose();
    _mobileFocus.dispose();
    _passwordFocus.dispose();
    _continueFocus.dispose();
    _fullNameController.dispose();
    _mobileController.removeListener(_onMobileControllerChanged);
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Focus + announce helper (validation-error flow only) ───────────────
  // This is a single, deliberate one-shot announcement triggered by
  // tapping "Continue" — it is NOT related to per-character swipe
  // navigation, so a manual announce here is correct and safe.
  void _focusField({
    required String fieldName,
    required FocusNode node,
    required GlobalKey key,
    required String announcement,
  }) {
    final int requestId = ++_errorRequestId;

    setState(() => _errorField = fieldName);

    FocusScope.of(context).requestFocus(node);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || requestId != _errorRequestId) return;

      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      }

      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted || requestId != _errorRequestId) return;
        SemanticsService.announce(announcement, TextDirection.ltr);
      });
    });
  }

  void _clearError(String fieldName) {
    if (_errorField == fieldName) {
      _errorRequestId++;
      setState(() => _errorField = null);
    }
  }

  // ── Error label builders ─────────────────────────────────────────────────
  // NOTE: These now ONLY produce the error-state label. The normal
  // (non-error) label, current value, cursor position, and per-character
  // swipe-reading are all left to Flutter's built-in TextFormField
  // semantics — which already does this correctly and natively, including
  // correctly masking password characters when obscured. We stopped
  // overriding/excluding that native behavior because doing so is what
  // broke cursor movement and caused duplicate/garbled announcements.
  String _fullNameErrorLabel() => "Error. Full Name is required.";

  String _mobileLabel(String currentText, {required bool isError}) {
    final trimmed = currentText.trim();
    if (isError) {
      if (trimmed.isEmpty) {
        return "Error. Mobile number is required.";
      }
      final digits = trimmed.split('').join(', ');
      return "Error. Mobile number must be exactly 10 digits. "
          "You entered ${trimmed.length} digits: $digits. retry";
    }
    return "Mobile Number, Required";
  }

  String _mobileErrorLabel(String currentText) {
    final trimmed = currentText.trim();
    if (trimmed.isEmpty) {
      return "Error. Mobile number is required.";
    }
    return "Error. Mobile number must be exactly 10 digits. "
        "You entered ${trimmed.length} digits.";
  }

  String _passwordErrorLabel(int currentLength) {
    if (currentLength == 0) {
      return "Error. Password is required.";
    }
    return "Error. Password must be at least 6 characters. "
        "You entered $currentLength characters.";
  }

  // ── Validation ────────────────────────────────────────────────────────────
  void _validateAndProceed() async {
    setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);

    if (!_formKey.currentState!.validate()) {
      if (_fullNameController.text.trim().isEmpty) {
        _focusField(
          fieldName:    'fullName',
          node:         _fullNameFocus,
          key:          _fullNameKey,
          announcement: _fullNameErrorLabel(),
        );
        return;
      }

      final mobile = _mobileController.text.trim();
      if (mobile.length != 10) {
        _focusField(
          fieldName:    'mobile',
          node:         _mobileFocus,
          key:          _mobileKey,
          announcement: _mobileErrorLabel(_mobileController.text),
        );
        return;
      }

      if (_passwordController.text.length < 6) {
        _focusField(
          fieldName:    'password',
          node:         _passwordFocus,
          key:          _passwordKey,
          announcement: _passwordErrorLabel(_passwordController.text.length),
        );
        return;
      }

      return;
    }

    setState(() {
      _errorField = null;
      _isLoading  = true;
    });

    final response = await AuthService.sendSignupOtp(
      mobile: _mobileController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? "Something went wrong")),
      );
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          SemanticsService.announce(
            response.message ?? "Something went wrong",
            TextDirection.ltr,
          );
        }
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          fullName: _fullNameController.text.trim(),
          mobile:   _mobileController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
            child: Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  margin: const EdgeInsets.only(top: 24, bottom: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F0E4),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.30),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autoValidateMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Back button ──────────────────────────────────
                        Semantics(
                          button: true,
                          label: "Back",
                          onTapHint: "activate",
                          excludeSemantics: true,
                          onTap: () => Navigator.pop(context),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 14,
                                  color: Color(0xFF7A7267),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Back",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF7A7267),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        Center(
                          child: Column(
                            children: [
                              // headingLevel lets TalkBack's "Headings"
                              // navigation control jump straight here.
                              Semantics(
                                header: true,
                                headingLevel: 1,
                                child: Text(
                                  "Create Account",
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF3B2A1F),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Fill in your details to get started",
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: const Color(0xFFA79E91),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── Full Name ────────────────────────────────────
                        _buildLabel("Full Name"),
                        const SizedBox(height: 6),
                        _buildFullNameField(),
                        const SizedBox(height: 14),

                        // ── Mobile Number ────────────────────────────────
                        _buildLabel("Mobile Number"),
                        const SizedBox(height: 6),
                        _buildMobileField(),
                        const SizedBox(height: 14),

                        // ── Password ─────────────────────────────────────
                        _buildLabel("Password"),
                        const SizedBox(height: 6),
                        _buildPasswordField(),

                        const SizedBox(height: 26),
                        _buildContinueButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Label widget ──────────────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return ExcludeSemantics(
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF6E665A),
        ),
      ),
    );
  }

  // ── Full Name field ──────────────────────────────────────────────────────
  // No excludeSemantics, no manual value/cursor handling. The
  // TextFormField's own semantics already provides correct cursor
  // tracking, character-by-character reading, and value announcement.
  // Wrapping in MergeSemantics folds our error label into that same native
  // node (one TalkBack stop, not two) instead of replacing it.
  Widget _buildFullNameField() {
    final isError = _errorField == 'fullName';

    return MergeSemantics(
      child: Semantics(
        label: isError ? _fullNameErrorLabel() : "Full Name, Required", // CHANGED: was `null`
        child: TextFormField(
          key: _fullNameKey,
          controller: _fullNameController,
          focusNode: _fullNameFocus,
          onChanged: (_) => _clearError('fullName'),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF3B2A1F),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Full Name is required.";
            }
            return null;
          },
          decoration: _inputDecoration("Enter your full name"),
        ),
      ),
    );
  }

  // ── Mobile field ──────────────────────────────────────────────────────────
  // SpellOutStringAttribute is applied over the REAL text (no space-joined
  // string) so TalkBack spells digits one by one without announcing "space".
  // excludeSemantics is removed and the TextFormField is wrapped in its own
  // MergeSemantics so the field's native cursor-move actions
  // (moveCursorForwardByCharacter / moveCursorBackwardByCharacter) survive —
  // those are what let TalkBack's "characters" swipe control step through
  // digits one at a time instead of re-reading the whole value on every swipe.
  Widget _buildMobileField() {
  return ValueListenableBuilder<TextEditingValue>(
    valueListenable: _mobileController,
    builder: (context, value, child) {
      final currentText = value.text;
      final isError = _errorField == 'mobile';
      final label = _mobileLabel(currentText, isError: isError);

      final valueAttributes = currentText.isEmpty
          ? <StringAttribute>[]
          : [
              SpellOutStringAttribute(
                range: TextRange(start: 0, end: currentText.length),
              ),
            ];

      // CHANGED: MergeSemantics now wraps the outer Semantics + TextFormField
      // together, instead of wrapping only the TextFormField. MergeSemantics
      // can only merge nodes that are its own descendants — with the old
      // nesting, the outer Semantics node (holding attributedValue) and the
      // inner TextFormField's native node were siblings-in-ancestry, not
      // merged, so TalkBack landed on the plain native node and skipped the
      // spelled-out value. Wrapping both in one MergeSemantics collapses them
      // into a single node: attributedValue drives what's spoken, and the
      // TextFormField's native cursor-move actions still work for per-digit
      // swipe navigation.
      return MergeSemantics(
        child: Semantics(
          label: label,
          hint: "number pad",
          attributedValue: AttributedString(
            currentText,
            attributes: valueAttributes,
          ),
          textField: true,
          onTap: () {
            _clearError('mobile');
            FocusScope.of(context).requestFocus(_mobileFocus);
          },
          child: TextFormField(
            key: _mobileKey,
            controller: _mobileController,
            focusNode: _mobileFocus,
            keyboardType: TextInputType.number,
            maxLength: 10,
            onChanged: (_) => _clearError('mobile'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF3B2A1F),
            ),
            validator: (val) {
              if (val == null || val.trim().length != 10) {
                return "Mobile number must be exactly 10 digits.";
              }
              return null;
            },
            decoration: _inputDecoration("10-digit number").copyWith(
              counterText: "",
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "+91",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF3B2A1F),
                      ),
                    ),
                    Container(
                      height: 22,
                      width: 1,
                      margin: const EdgeInsets.only(left: 14),
                      color: const Color(0xFFD4AF37).withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
  // ── Password field ────────────────────────────────────────────────────────
  // obscureText:true already tells Flutter's own semantics to mask the
  // reported value/character stream (SemanticsFlag.isObscured) — that
  // masking is native and correct, so nothing further is needed to stop
  // the password itself from being spoken. The show/hide IconButton is a
  // completely separate Semantics node (its own excludeSemantics scope)
  // with only its own "Show/Hide password" label — it was never actually
  // reading the password itself; it only appeared to because the old
  // manual `value: currentText` on the field ignored obscureText.
  Widget _buildPasswordField() {
    final isError = _errorField == 'password';

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        MergeSemantics(
          child: Semantics(
            label: isError
                ? _passwordErrorLabel(_passwordController.text.length)
                : "Password, Required", // CHANGED: was `null`
            child: TextFormField(
              key: _passwordKey,
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              onChanged: (_) => _clearError('password'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF3B2A1F),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return "Password must be at least 6 characters.";
                }
                return null;
              },
              decoration: _inputDecoration(
                "Min 6 characters",
                suffixIcon: const SizedBox(width: 44, height: 44),
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          child: Semantics(
            button: true,
            label: _obscurePassword ? "Show password" : "Hide password",
            onTapHint: "activate",
            excludeSemantics: true,
            child: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFFB48A2C),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }
  // ── Input decoration ──────────────────────────────────────────────────────
  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: const Color(0xFFB8B0A4),
      ),
      filled: true,
      fillColor: const Color(0xFFF5EBDD),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: const Color(0xFFD4AF37).withOpacity(0.4),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: const Color(0xFFD4AF37).withOpacity(0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: Color(0xFFD4AF37),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  // ── Continue button ───────────────────────────────────────────────────────
  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Focus(
        focusNode: _continueFocus,
        child: Semantics(
          button: true,
          label: _isLoading ? "Loading, please wait" : "Continue",
          onTapHint: "activate",
          excludeSemantics: true,
          onTap: _isLoading ? null : _validateAndProceed,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _validateAndProceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              disabledBackgroundColor:
                  const Color(0xFFD4AF37).withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    "Continue",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}