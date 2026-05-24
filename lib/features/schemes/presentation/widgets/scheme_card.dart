import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suvarna_jewellers/features/schemes/data/scheme_model.dart';
import 'package:suvarna_jewellers/features/schemes/presentation/widgets/terms_and_conditions_dialog.dart';

class SchemeCard extends StatelessWidget {
  final SchemeModel scheme;
  final VoidCallback onEnroll;
  final bool isEnrolled;

  const SchemeCard({
    super.key,
    required this.scheme,
    required this.onEnroll,
    required this.isEnrolled,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF6F0E4).withOpacity(0.97),
          border: Border.all(
            color: const Color(0xFFD4AF37),
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 3,
              width: double.infinity,
              color: const Color(0xFFD4AF37),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Column(
                children: [
                  Text(
                    scheme.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B2A1F),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 14),

                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "₹${scheme.monthlyAmount}",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                        TextSpan(
                          text: "/month",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF7A7267),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      const Icon(
                        Icons.check,
                        size: 16,
                        color: Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${scheme.durationMonths} monthly installments",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF5E564A),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Get Maturity Value: ₹${scheme.maturityAmount}",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF5E564A),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isEnrolled
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) =>
                                    TermsAndConditionsDialog(
                                  onAccept: onEnroll,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEnrolled
                            ? Colors.grey.shade400
                            : const Color(0xFFD4AF37),
                        disabledBackgroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(
                        isEnrolled ? "Already Enrolled" : "Enroll Now",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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