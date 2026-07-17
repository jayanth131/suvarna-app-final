import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  // FocusNodes to programmatically move focus to first invalid field
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _messageFocus = FocusNode();

  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _announceError(String message) {
    // Programmatically announce validation errors to TalkBack
    SemanticsService.announce(message, TextDirection.ltr);
  }

  Future<void> _sendMessage() async {
    setState(() => _error = null);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final message = _messageController.text.trim();

    // Just announce the error — don't move TalkBack focus to the field
    if (name.isEmpty) {
      setState(() => _error = "Full Name is required.");
      _announceError(_error!);
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = "Email is required.");
      _announceError(_error!);
      return;
    }
    if (phone.isEmpty) {
      setState(() => _error = "Phone Number is required.");
      _announceError(_error!);
      return;
    }
    if (message.isEmpty) {
      setState(() => _error = "Message is required.");
      _announceError(_error!);
      return;
    }

    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      setState(() => _error = "Enter a valid 10-digit phone number.");
      _announceError(_error!);
      return;
    }

    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse(
          "https://suvarna-jewellers-customer-backend.vercel.app/api/contact",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "phone": phone,
          "message": message,
        }),
      );

      if (response.statusCode == 200) {
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _messageController.clear();

        if (!mounted) return;

        _announceError("Message sent successfully");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ExcludeSemantics(
              child: Text(
                "Message sent successfully!",
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
            backgroundColor: const Color(0xFFD4AF37),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _error = "Failed to send. Please try again.");
        _announceError(_error!);
      }
    } catch (e) {
      setState(() => _error = "Network error. Please try again.");
      _announceError(_error!);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: const Color(0xFFF5EBDD).withOpacity(0.55),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header — inside the scroll view, so it scrolls with content ──
                  Row(
                    children: [
                      Semantics(
                        sortKey: const OrdinalSortKey(1),
                        button: true,
                        label: "Back",
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: Color(0xFF7A7267),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Semantics(
                        // 'header' is kept for backwards compatibility in some cases,
                        // but 'headingLevel' is what modern Flutter uses under the hood.
                        header: true,
                        headingLevel:
                            1, // Marks this as an H1 equivalent for Screen Readers & Web

                        child: Text(
                          "My Coupons",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3B2A1F),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // NOTE: Back button placed after heading in the semantics
                  // tree via sortKey below, while keeping its usual visual
                  // position via a Stack/Row reorder if needed.
                  // Simplest consistent fix: give the back icon a higher
                  // sortKey than the heading so TalkBack visits it second,
                  // regardless of paint order.
                  const SizedBox(height: 24),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F0E4).withOpacity(0.97),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      children: [
                        _infoRow(
                          Icons.email_outlined,
                          "Email",
                          "suvarnajewellers12@gmail.com",
                        ),
                        const SizedBox(height: 16),
                        _infoRow(
                          Icons.location_on_outlined,
                          "Address",
                          "Suvarna Jewellers Showroom\nD.No. 13-1-12, Main Road, Near YSR Statue, New Gajuwaka\nVisakhapatnam, Andhra Pradesh – 530026",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F0E4).withOpacity(0.97),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            "Send us a message",
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3B2A1F),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const SizedBox(height: 12),
                        _inputField(
                          label: "Full Name",
                          hint: "Enter your full name",
                          controller: _nameController,
                          focusNode: _nameFocus,
                          required: true,
                          autofillHints: const [AutofillHints.name],
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          label: "Email",
                          hint: "Enter your email address",
                          controller: _emailController,
                          focusNode: _emailFocus,
                          required: true,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          label: "Phone Number",
                          hint: "Enter your 10-digit phone number",
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          required: true,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          digitByDigit: true,
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          label: "Message",
                          hint: "Type your message",
                          controller: _messageController,
                          focusNode: _messageFocus,
                          required: true,
                          maxLines: 4,
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],

                        SizedBox(
                          width: double.infinity,
                          child: Semantics(
                            button: true,
                            enabled: !_isSending,
                            excludeSemantics: true, // <-- ADDED THIS LINE
                            label: _isSending
                                ? "Sending message"
                                : "Send Message",
                            child: ElevatedButton(
                              onPressed: _isSending ? null : _sendMessage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4AF37),
                                disabledBackgroundColor: const Color(
                                  0xFFD4AF37,
                                ).withOpacity(0.6),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: _isSending
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      "Send Message",
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String subtitle) {
    return Semantics(
      label: "$title: $subtitle",
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFD4AF37), size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF9E8E7E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3B2A1F),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Text field with a persistent visible label above it (placeholder
  /// text remains only as supplementary hint text inside the field),
  /// and announces "Required" state to TalkBack.
  Widget _inputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<String>? autofillHints,
    bool digitByDigit = false,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final rawText = controller.text;
        final spokenValue = rawText.isEmpty
            ? null
            : (digitByDigit ? rawText.split('').join(' ') : rawText);

        final semanticLabel = required ? "$label, Required" : label;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visible label above the field. Excluded from semantics
            // since it's fully represented in the Semantics node below.
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6E665A),
                        ),
                      ),
                      if (required)
                        TextSpan(
                          text: " *",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Semantics(
              label: semanticLabel,
              value: spokenValue,
              hint: "Double tap to enter",
              textField: true,
              focused: focusNode.hasFocus,
              enabled: true,
              // Single accessibility node: the real TextField's own
              // semantics are excluded so TalkBack only ever sees the
              // label/value we control above — no second, conflicting
              // node to land on.
              child: ExcludeSemantics(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  autofillHints: autofillHints,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF3B2A1F),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFFB8B0A4),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5EBDD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFD4AF37),
                        width: 1.2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
