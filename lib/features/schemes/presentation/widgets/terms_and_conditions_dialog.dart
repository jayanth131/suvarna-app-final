import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsDialog extends StatefulWidget {
  final VoidCallback onAccept;

  const TermsAndConditionsDialog({
    super.key,
    required this.onAccept,
  });

  @override
  State<TermsAndConditionsDialog> createState() =>
      _TermsAndConditionsDialogState();
}

class _TermsAndConditionsDialogState extends State<TermsAndConditionsDialog> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF6F0E4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFD4AF37),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Terms & Conditions",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // ── T&C Content ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _termsAndConditionsContent,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF3B2A1F),
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),

            // ── Checkbox ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _isChecked,
                      onChanged: (value) {
                        setState(() {
                          _isChecked = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFFD4AF37),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "I agree to the Terms & Conditions",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF3B2A1F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Buttons ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFD4AF37),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isChecked
                          ? () {
                              Navigator.of(context).pop();
                              widget.onAccept();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        disabledBackgroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Accept & Enroll",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
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

  static const String _termsAndConditionsContent = '''Eligibility

Users must provide accurate personal details during registration. Suvarna Jewellers reserves the right to suspend accounts containing false information.

Savings Schemes

• Customers may enroll in available gold or cash savings schemes.
• Monthly installment amounts and durations are fixed according to the selected scheme.
• Failure to pay installments on time may affect benefits associated with the scheme.
• Duplicate enrollment into the same scheme may not be permitted.

Payments

• All payments are securely processed through authorized payment gateways.
• Customers are responsible for verifying payment details before confirmation.
• Suvarna Jewellers shall not be liable for failed transactions caused by banking or network issues.

Gold Rate & Valuation

• Gold rates displayed in the application are subject to daily market fluctuations.
• Final valuation will be based on prevailing rates at the showroom during redemption or purchase.

Refund & Cancellation

• Payments once made are generally non-refundable.
• Refund requests, if applicable, shall be processed according to company policy.
• Cancellation charges may apply for discontinued schemes.

Exchange & Buyback Policy

• Exchange or buyback of jewellery is subject to prevailing company policies.
• Gold content will be evaluated based on purity and applicable deductions.
• Damaged or altered products may not qualify for exchange.

User Responsibilities

• Users are responsible for maintaining confidentiality of their account credentials and MPIN.
• Sharing OTPs, passwords, or MPINs with others is strictly discouraged.
• Any unauthorized activity should be reported immediately.

Notifications & OTP Services

• The application may send OTPs, reminders, and notifications for authentication and scheme updates.
• Users consent to receive SMS and app notifications related to their account activities.

Privacy & Data Usage

• User information is collected solely for authentication, payments, and customer service purposes.
• Suvarna Jewellers does not sell personal customer information to third parties.

Limitation of Liability

Suvarna Jewellers shall not be held responsible for losses caused due to:

• Internet or server interruptions
• Unauthorized account access caused by user negligence
• Third-party payment gateway failures
• Temporary application downtime or maintenance

Intellectual Property

All logos, designs, application content, branding, and visuals are the property of Suvarna Jewellers and may not be copied or reused without permission.

Modifications to Terms

Suvarna Jewellers reserves the right to modify these Terms & Conditions at any time without prior notice.

Jurisdiction

Any disputes arising from the use of this application or website shall be subject to the jurisdiction of courts in Andhra Pradesh, India.

Contact Information

Suvarna Jewellers
D.No. 13-1-12, Main Road, Near YSR Statue,
New Gajuwaka, Visakhapatnam - 530026,
Andhra Pradesh, India.

Email: suvarnajewellers12@gmail.com

© 2026 Suvarna Jewellers. All Rights Reserved.''';
}
