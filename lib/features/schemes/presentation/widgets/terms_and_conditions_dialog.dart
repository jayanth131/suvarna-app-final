import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart'; // Added for TextInputFormatter
import 'package:google_fonts/google_fonts.dart';
import 'terms_and_conditions_data.dart';

class TermsAndConditionsDialog extends StatefulWidget {
  // ── UPDATED ──────────────────────────────────────────
  // onAccept now carries the collected enrollment details
  // back to the caller instead of firing with no data.
  final void Function({
    required String nomineeName,
    required String nomineeRelation,
    required String nomineePhone,
    String? nomineeAddress,
    String? yourAddress,
  }) onAccept;
  // ─────────────────────────────────────────────────────

  const TermsAndConditionsDialog({super.key, required this.onAccept});

  @override
  State<TermsAndConditionsDialog> createState() =>
      _TermsAndConditionsDialogState();
}

class _TermsAndConditionsDialogState extends State<TermsAndConditionsDialog> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  bool _hasReachedBottom = false;
  bool _requiredDetailsEntered = false;

  // Controllers for the form fields
  final TextEditingController _nomineeNameController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nomineeAddressController = TextEditingController();
  final TextEditingController _yourAddressController = TextEditingController();

  bool _isChecked = false;

  bool get _canAgree => _hasReachedBottom && _requiredDetailsEntered;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);
    _nomineeNameController.addListener(_handleRequiredDetailsChanged);
    _relationController.addListener(_handleRequiredDetailsChanged);
    _phoneController.addListener(_handleRequiredDetailsChanged);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    // The bottom-scroll requirement starts only AFTER the required
    // nominee details have been entered.
    if (!_requiredDetailsEntered) {
      if (_hasReachedBottom && mounted) {
        setState(() {
          _hasReachedBottom = false;
          _isChecked = false;
        });
      }
      return;
    }

    final position = _scrollController.position;
    final reachedBottom =
        position.pixels >= (position.maxScrollExtent - 24);

    if (reachedBottom != _hasReachedBottom && mounted) {
      setState(() {
        _hasReachedBottom = reachedBottom;

        if (!_canAgree) {
          _isChecked = false;
        }
      });
    }
  }

  void _handleRequiredDetailsChanged() {
    final valid =
        _nomineeNameController.text.trim().isNotEmpty &&
        _relationController.text.trim().isNotEmpty &&
        _phoneController.text.trim().length == 10;

    if (valid != _requiredDetailsEntered && mounted) {
      setState(() {
        final wasValid = _requiredDetailsEntered;
        _requiredDetailsEntered = valid;

        // When the required details become valid, start a NEW scroll
        // requirement. This prevents a scroll done before entering the
        // details from unlocking the agreement checkbox.
        if (!wasValid && valid) {
          _hasReachedBottom = false;
          _isChecked = false;
        }

        // If the required details become invalid again, lock agreement.
        if (!valid) {
          _hasReachedBottom = false;
          _isChecked = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();

    _nomineeNameController.removeListener(_handleRequiredDetailsChanged);
    _relationController.removeListener(_handleRequiredDetailsChanged);
    _phoneController.removeListener(_handleRequiredDetailsChanged);
    _nomineeNameController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    _nomineeAddressController.dispose();
    _yourAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    final horizontalInset = screenWidth < 360 ? 12.0 : 20.0;
    final dialogMaxWidth = screenWidth >= 600 ? 520.0 : screenWidth;
    final dialogMaxHeight = screenHeight * 0.88;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogMaxWidth,
          maxHeight: dialogMaxHeight,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F0E4),
            borderRadius: BorderRadius.circular(20),
          ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Header ──────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    Expanded(
                      child: Text(
                        "Terms & Conditions",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: screenWidth < 360 ? 18 : 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Semantics(
                      label: 'Close dialog',
                      button: true,
                      onTapHint: 'Closes the terms and conditions screen',
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable Content (T&C + Form) ──────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(screenWidth < 360 ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── UPDATED ──────────────────────────────────
                      // Terms & Conditions content, point-wise.
                      // Previously this was one long Text widget wrapped
                      // in a single Semantics label, which forced
                      // TalkBack to read (or skip) the entire T&C as one
                      // block. Each clause now gets its own Semantics
                      // node via _TermsSectionView, so a screen-reader
                      // user can swipe point-by-point instead.
                      Semantics(
                        header: true,
                        child: Text(
                          kTermsSchemeName,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3B2A1F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        label: '$kTermsAddress. $kTermsGstin',
                        child: Text(
                          '$kTermsAddress\n$kTermsGstin',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF3B2A1F).withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final section in termsAndConditionsSections)
                        _TermsSectionView(section: section),
                      // ─────────────────────────────────────────────
                      const SizedBox(height: 32),

                      const Divider(color: Color(0xFFD4AF37), thickness: 1),
                      const SizedBox(height: 24),

                      // Form Section Title
                      Semantics(
                        header: true,
                        child: Text(
                          "Enrollment Details",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3B2A1F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nominee Name Field
                      _buildTextField(
                        controller: _nomineeNameController,
                        label: "Nominee Name",
                        semanticsLabel: "Enter the full name of the nominee",
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nominee name is required';
                          }
                          return null;
                        },
                      ),

                      // Relation Field
                      _buildTextField(
                        controller: _relationController,
                        label: "Relation",
                        semanticsLabel: "Enter your relationship with the nominee",
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Relation is required';
                          }
                          return null;
                        },
                      ),

                      // Phone Number Field
                      _buildTextField(
                        controller: _phoneController,
                        label: "Phone Number",
                        semanticsLabel: "Enter the nominee's 10-digit phone number",
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly, // Only allows numbers
                          LengthLimitingTextInputFormatter(10),   // Limits to 10 digits
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          if (value.trim().length != 10) {
                            return 'Enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),

                      // Nominee Address Field (Optional)
                      _buildTextField(
                        controller: _nomineeAddressController,
                        label: "Nominee Address",
                        semanticsLabel: "Enter the nominee's address. This field is optional",
                        isOptional: true,
                        maxLines: 2,
                      ),

                      // Your Address Field (Optional)
                      _buildTextField(
                        controller: _yourAddressController,
                        label: "Your Address",
                        semanticsLabel: "Enter your personal address. This field is optional",
                        isOptional: true,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Agreement Status + Checkbox ────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  screenWidth < 360 ? 16 : 20,
                  8,
                  screenWidth < 360 ? 16 : 20,
                  6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_hasReachedBottom)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Semantics(
                          liveRegion: true,
                          label: _requiredDetailsEntered
                              ? "Scroll down to continue"
                              : "Enter nominee name, relation, and phone number first",
                          child: Text(
                            _requiredDetailsEntered
                                ? "Scroll down"
                                : "Enter nominee details",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7A7267),
                            ),
                          ),
                        ),
                      ),

                    MergeSemantics(
                      child: Semantics(
                        checked: _isChecked,
                        enabled: _canAgree,
                        button: true,
                        label: _canAgree
                            ? "I agree to the Terms and Conditions"
                            : "Agreement checkbox disabled",
                        onTapHint: _canAgree
                            ? "Toggle agreement to Terms and Conditions"
                            : _requiredDetailsEntered
                                ? "Scroll down completely to enable agreement"
                                : "Complete nominee name, relation, and phone number first",
                        child: InkWell(
                          onTap: _canAgree
                              ? () {
                                  setState(() {
                                    _isChecked = !_isChecked;
                                  });
                                }
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _isChecked,
                                  onChanged: _canAgree
                                      ? (value) {
                                          setState(() {
                                            _isChecked = value ?? false;
                                          });
                                        }
                                      : null,
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth < 360 ? 12 : 13,
                                    color: _canAgree
                                        ? const Color(0xFF3B2A1F)
                                        : const Color(0xFF3B2A1F)
                                            .withOpacity(0.45),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Buttons ──────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  screenWidth < 360 ? 16 : 20,
                  10,
                  screenWidth < 360 ? 16 : 20,
                  screenWidth < 360 ? 14 : 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: "Cancel enrollment",
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
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Cancel",
                              maxLines: 1,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                              fontWeight: FontWeight.w600,
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: (_canAgree && _isChecked)
                            ? "Accept and Enroll"
                            : "Accept and Enroll, disabled until required details are completed and terms are agreed to",
                        child: ElevatedButton(
                          // ── UPDATED ──────────────────────────────
                          // Validates the form, then forwards the
                          // collected values through widget.onAccept
                          // instead of firing a bare VoidCallback.
                          onPressed: (_canAgree && _isChecked)
                              ? () {
                                  if (_formKey.currentState!.validate()) {
                                    Navigator.of(context).pop();
                                    widget.onAccept(
                                      nomineeName:
                                          _nomineeNameController.text.trim(),
                                      nomineeRelation:
                                          _relationController.text.trim(),
                                      nomineePhone:
                                          _phoneController.text.trim(),
                                      nomineeAddress:
                                          _nomineeAddressController.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : _nomineeAddressController.text
                                                  .trim(),
                                      yourAddress: _yourAddressController.text
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : _yourAddressController.text
                                              .trim(),
                                    );
                                  } else {
                                    SemanticsService.announce(
                                      "Please correct the errors in the form",
                                      TextDirection.ltr,
                                    );
                                  }
                                }
                              : null,
                          // ─────────────────────────────────────────
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            disabledBackgroundColor: Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Accept & Enroll",
                              maxLines: 1,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                              fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
        ),
      ),
    );
  }

  // Helper method to build consistent input fields with accessibility
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String semanticsLabel,
    bool isOptional = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters, // Added to restrict input
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Semantics(
        label: semanticsLabel,
        textField: true,
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters, // Applied here
          maxLines: maxLines,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF3B2A1F),
          ),
          decoration: InputDecoration(
            labelText: isOptional ? '$label (Optional)' : label,
            labelStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF3B2A1F).withOpacity(0.6),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: const Color(0xFFD4AF37).withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: const Color(0xFFD4AF37).withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFD4AF37),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            errorStyle: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.redAccent,
            ),
          ),
          validator: validator,
        ),
      ),
    );
  }
}

// ── UPDATED ────────────────────────────────────────────────────────
// Point-wise rendering of a TermsSection, styled to match the rest of
// this dialog (Poppins/Playfair, brand gold/brown palette) instead of
// the plain Material defaults used in the standalone screen version.
// Each clause is its own MergeSemantics node with a numbered label
// ("Point 2 of 5: ...") so TalkBack announces one clause per swipe
// instead of the whole section at once.
class _TermsSectionView extends StatelessWidget {
  final TermsSection section;

  const _TermsSectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: Semantics(
              header: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  section.title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B2A1F),
                  ),
                ),
              ),
            ),
          ),
          for (var i = 0; i < section.points.length; i++)
            _TermsPointView(
              index: i,
              total: section.points.length,
              text: section.points[i],
            ),
          if (section.tables != null)
            for (final table in section.tables!) _TermsTableView(table: table),
        ],
      ),
    );
  }
}

class _TermsPointView extends StatelessWidget {
  final int index;
  final int total;
  final String text;

  const _TermsPointView({
    required this.index,
    required this.total,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label: 'Point ${index + 1} of $total. $text',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•  ',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFFD4AF37),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF3B2A1F),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Renders a table as "label: value" rows instead of a visual grid —
// cell-by-cell traversal is disorienting under TalkBack, whereas a
// labeled row reads naturally in one pass.
class _TermsTableView extends StatelessWidget {
  final TermsTable table;

  const _TermsTableView({required this.table});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 8, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < table.rows.length; i++)
            MergeSemantics(
              child: Semantics(
                label:
                    'Row ${i + 1} of ${table.rows.length}. ${table.rows[i].label}: ${table.rows[i].value}',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        table.rows[i].label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B2A1F),
                        ),
                      ),
                      Text(
                        table.rows[i].value,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF3B2A1F).withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}