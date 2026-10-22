import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suvarna_jewellers/features/schemes/data/scheme_model.dart';
import 'package:suvarna_jewellers/features/schemes/presentation/widgets/terms_and_conditions_dialog.dart';

class SchemeCard extends StatefulWidget {
  final SchemeModel scheme;

  final void Function({
    required double selectedAmount,
    required String nomineeName,
    required String nomineeRelation,
    required String nomineePhone,
    String? nomineeAddress,
    String? yourAddress,
  }) onEnroll;

  final bool isEnrolled;

  const SchemeCard({
    super.key,
    required this.scheme,
    required this.onEnroll,
    required this.isEnrolled,
  });

  @override
  State<SchemeCard> createState() => _SchemeCardState();
}

class _SchemeCardState extends State<SchemeCard> {
  static const List<int> _amountOptions = [
    1000,
    2000,
    5000,
    7000,
    10000,
    15000,
    20000,
    25000,
    30000,
    40000,
    50000,
    75000,
    100000,
    125000,
    150000,
    175000,
    200000,
  ];

  int? _selectedAmount;

  String _formatAmount(int amount) {
    final value = amount.toString();
    if (value.length <= 3) return value;

    final lastThree = value.substring(value.length - 3);
    final remaining = value.substring(0, value.length - 3);
    final buffer = StringBuffer();

    for (int i = 0; i < remaining.length; i++) {
      if (i != 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }

    return '${buffer.toString()},$lastThree';
  }

  IconData get _typeIcon {
    if (widget.scheme.isSilver) return Icons.circle_outlined;
    if (widget.scheme.isGold) return Icons.balance;
    return Icons.currency_rupee;
  }

  String get _rateNote {
    switch (widget.scheme.rateType) {
      case 'GOLD_22K':
        return 'Every successful installment locks gold grams using that day\'s live 22K gold rate.';
      case 'GOLD_18K':
        return 'Every successful installment locks gold grams using that day\'s live 18K gold rate.';
      case 'SILVER':
        return 'Every successful installment locks silver grams using that day\'s live silver rate.';
      case 'CASH':
      default:
        return 'Your selected monthly installment remains fixed for the complete scheme.';
    }
  }

  void _handleEnroll() {
    if (widget.isEnrolled) return;

    if (_selectedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select your monthly installment amount.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF3B2A1F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return TermsAndConditionsDialog(
          onAccept: ({
            required nomineeName,
            required nomineeRelation,
            required nomineePhone,
            nomineeAddress,
            yourAddress,
          }) {
            widget.onEnroll(
              selectedAmount: _selectedAmount!.toDouble(),
              nomineeName: nomineeName,
              nomineeRelation: nomineeRelation,
              nomineePhone: nomineePhone,
              nomineeAddress: nomineeAddress,
              yourAddress: yourAddress,
            );
          },
        );
      },
    );
  }

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.scheme.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B2A1F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.scheme.typeLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B6914),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.scheme.durationMonths} monthly installments',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF5E564A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _typeIcon,
                        size: 18,
                        color: const Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _rateNote,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            height: 1.5,
                            color: const Color(0xFF5E564A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.event_busy_outlined,
                        size: 18,
                        color: Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'If a previous month is missed, the next online installment is blocked until the missed month is cleared at the store.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            height: 1.45,
                            color: const Color(0xFF5E564A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Choose Monthly Amount',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B2A1F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedAmount,
                    isExpanded: true,
                    hint: Text(
                      'Select installment amount',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF8A8176),
                      ),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.75),
                      prefixIcon: const Icon(
                        Icons.currency_rupee,
                        size: 20,
                        color: Color(0xFFD4AF37),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: const Color(0xFFD4AF37).withOpacity(0.45),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFD4AF37),
                          width: 1.4,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFFD4AF37),
                    ),
                    items: _amountOptions.map((amount) {
                      return DropdownMenuItem<int>(
                        value: amount,
                        child: Text(
                          '₹${_formatAmount(amount)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF3B2A1F),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: widget.isEnrolled
                        ? null
                        : (value) {
                            setState(() {
                              _selectedAmount = value;
                            });
                          },
                  ),
                  if (_selectedAmount != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.09),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withOpacity(0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your Monthly Installment',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF7A7267),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${_formatAmount(_selectedAmount!)}',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          widget.isEnrolled || _selectedAmount == null
                              ? null
                              : _handleEnroll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        disabledBackgroundColor: widget.isEnrolled
                            ? Colors.grey.shade400
                            : const Color(0xFFD4AF37).withOpacity(0.35),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.isEnrolled
                            ? 'Already Enrolled'
                            : _selectedAmount == null
                                ? 'Select Amount to Enroll'
                                : 'Enroll with ₹${_formatAmount(_selectedAmount!)}',
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
}
