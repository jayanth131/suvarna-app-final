import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:suvarna_jewellers/features/schemes/data/scheme_model.dart';
import 'package:suvarna_jewellers/features/schemes/data/scheme_service.dart';
import 'package:suvarna_jewellers/features/schemes/data/enrolled_scheme_service.dart';
import 'package:suvarna_jewellers/features/schemes/models/enrolled_scheme.dart';
import 'package:suvarna_jewellers/features/schemes/presentation/widgets/scheme_card.dart';

import '../data/payment_service.dart';

// ============================================================
// SCHEME FILTER
// ============================================================

enum _SchemeFilter {
  gold,
  silver,
  cash,
}

// ============================================================
// SCREEN
// ============================================================

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({
    super.key,
  });

  @override
  SchemesScreenState createState() =>
      SchemesScreenState();
}

// ============================================================
// STATE
// ============================================================

class SchemesScreenState
    extends State<SchemesScreen> {
  late Future<List<SchemeModel>>
      _schemesFuture;

  late Future<List<EnrolledScheme>>
      _enrolledFuture;

  _SchemeFilter _filter =
      _SchemeFilter.gold;

  // ------------------------------------------------------------
  // Prevent multiple enrollment/payment starts from very fast taps.
  // ------------------------------------------------------------

  final Set<String>
      _processingSchemeIds =
      <String>{};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadInitialData();
  }

  void _loadInitialData() {
    _schemesFuture =
        SchemeService.getSchemes();

    _enrolledFuture =
        EnrolledSchemeService
            .getUserSchemes();
  }

  // ============================================================
  // REFRESH DATA
  // ============================================================

  void refreshData() {
    if (!mounted) {
      return;
    }

    // Clear both caches so changes made from admin/backend
    // are reflected immediately after a successful payment/enrollment.
    SchemeService.invalidateCache();
    EnrolledSchemeService.invalidateCache();

    setState(() {
      _schemesFuture =
          SchemeService.getSchemes(
        forceRefresh: true,
      );

      _enrolledFuture =
          EnrolledSchemeService
              .getUserSchemes(
        forceRefresh: true,
      );
    });
  }

  Future<void> _refreshData() async {
    // Pull-to-refresh must bypass both caches.
    SchemeService.invalidateCache();
    EnrolledSchemeService.invalidateCache();

    final schemesFuture =
        SchemeService.getSchemes(
      forceRefresh: true,
    );

    final enrolledFuture =
        EnrolledSchemeService
            .getUserSchemes(
      forceRefresh: true,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _schemesFuture =
          schemesFuture;

      _enrolledFuture =
          enrolledFuture;
    });

    try {
      await Future.wait([
        schemesFuture,
        enrolledFuture,
      ]);
    } catch (e) {
      debugPrint(
        '[SCHEMES] Refresh failed: $e',
      );
    }
  }

  // ============================================================
  // FILTERING
  // ============================================================

  bool _matchesFilter(
    SchemeModel scheme,
  ) {
    switch (_filter) {
      // --------------------------------------------------------
      // GOLD
      //
      // Includes:
      // GOLD_22K
      // GOLD_18K
      // --------------------------------------------------------

      case _SchemeFilter.gold:
        return scheme.isGold;

      // --------------------------------------------------------
      // SILVER
      // --------------------------------------------------------

      case _SchemeFilter.silver:
        return scheme.isSilver;

      // --------------------------------------------------------
      // CASH
      // --------------------------------------------------------

      case _SchemeFilter.cash:
        return scheme.isCash;
    }
  }

  // ============================================================
  // FILTER LABEL
  // ============================================================

  String get _emptyMessage {
    switch (_filter) {
      case _SchemeFilter.gold:
        return 'No gold schemes available';

      case _SchemeFilter.silver:
        return 'No silver schemes available';

      case _SchemeFilter.cash:
        return 'No cash schemes available';
    }
  }

  // ============================================================
  // FILTER ICON
  // ============================================================

  IconData get _emptyIcon {
    switch (_filter) {
      case _SchemeFilter.gold:
        return Icons.balance;

      case _SchemeFilter.silver:
        return Icons.circle_outlined;

      case _SchemeFilter.cash:
        return Icons.currency_rupee;
    }
  }

  // ============================================================
  // FILTER DESCRIPTION
  // ============================================================

  String get _filterDescription {
    switch (_filter) {
      case _SchemeFilter.gold:
        return 'Save using live 22K or 18K gold rates';

      case _SchemeFilter.silver:
        return 'Accumulate silver grams using the live silver rate';

      case _SchemeFilter.cash:
        return 'Save a fixed monthly cash amount';
    }
  }

  // ============================================================
  // START ENROLLMENT
  // ============================================================

  Future<void> _startEnrollment({
    required SchemeModel scheme,
    required double selectedAmount,
    required String nomineeName,
    required String nomineeRelation,
    required String nomineePhone,
    String? nomineeAddress,
    String? yourAddress,
  }) async {
    // ----------------------------------------------------------
    // Prevent accidental double taps.
    // ----------------------------------------------------------

    if (_processingSchemeIds
        .contains(scheme.id)) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _processingSchemeIds
          .add(scheme.id);
    });

    debugPrint(
      '[SCHEMES] ========================================',
    );

    debugPrint(
      '[SCHEMES] Starting enrollment',
    );

    debugPrint(
      '[SCHEMES] Scheme ID       : ${scheme.id}',
    );

    debugPrint(
      '[SCHEMES] Scheme Name     : ${scheme.name}',
    );

    debugPrint(
      '[SCHEMES] Rate Type       : ${scheme.rateType}',
    );

    debugPrint(
      '[SCHEMES] Selected Amount : ₹$selectedAmount',
    );

    debugPrint(
      '[SCHEMES] ========================================',
    );

    try {
      await PaymentService.startPayment(
        context: context,

        schemeId:
            scheme.id,

        // ------------------------------------------------------
        // Customer-selected amount.
        //
        // First enrollment:
        // backend validates and stores this amount.
        //
        // Future months:
        // backend ignores Flutter amount and uses the saved
        // CustomerScheme.installmentAmount.
        // ------------------------------------------------------

        amount:
            selectedAmount,

        // ------------------------------------------------------
        // After successful verify:
        //
        // refresh available schemes
        // refresh enrolled schemes
        // ------------------------------------------------------

        onSuccess: () {
          EnrolledSchemeService
              .invalidateCache();

          refreshData();
        },

        customerAddress:
            yourAddress,

        nomineeName:
            nomineeName,

        nomineeRelation:
            nomineeRelation,

        nomineePhone:
            nomineePhone,

        nomineeAddress:
            nomineeAddress,
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[SCHEMES] Enrollment error: $e',
      );

      debugPrint(
        '[SCHEMES] Stack: $stackTrace',
      );

      if (mounted) {
        ScaffoldMessenger
            .of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Unable to start enrollment: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingSchemeIds
              .remove(scheme.id);
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.transparent,

      body: Stack(
        children: [
          // ====================================================
          // BACKGROUND
          // ====================================================

          Positioned.fill(
            child: Image.asset(
              'assets/images/showroom_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter:
                  ImageFilter.blur(
                sigmaX: 8,
                sigmaY: 8,
              ),
              child: Container(
                color:
                    const Color(
                  0xFFF5EBDD,
                ).withOpacity(
                  0.65,
                ),
              ),
            ),
          ),

          // ====================================================
          // CONTENT
          // ====================================================

          SafeArea(
            child: Column(
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Padding(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    20,
                    20,
                    20,
                    0,
                  ),

                  child: Column(
                    children: [
                      // --------------------------------------------
                      // LOGO
                      // --------------------------------------------

                      Center(
                        child: Image.asset(
                          'assets/images/suvarna_logo.png',
                          height: 56,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // --------------------------------------------
                      // TITLE
                      // --------------------------------------------

                      Semantics(
                        header: true,
                        child: Text(
                          'Saving Schemes',

                          style: GoogleFonts
                              .playfairDisplay(
                            fontSize: 28,

                            fontWeight:
                                FontWeight
                                    .w700,

                            color:
                                const Color(
                              0xFF3B2A1F,
                            ),
                          ),

                          textAlign:
                              TextAlign
                                  .center,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        'Invest in gold, silver or cash savings',

                        style:
                            GoogleFonts
                                .poppins(
                          fontSize: 13,

                          color:
                              const Color(
                            0xFF7A7267,
                          ),
                        ),

                        textAlign:
                            TextAlign
                                .center,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // GOLD / SILVER / CASH FILTER
                      // ==================================================

                      Container(
                        padding:
                            const EdgeInsets
                                .all(4),

                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFEDE0CC,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),

                        child: Row(
                          children: [
                            // ------------------------------------------
                            // GOLD
                            // ------------------------------------------

                            _buildFilterTab(
                              label:
                                  '✦ Gold',

                              semanticLabel:
                                  'Gold schemes',

                              selected:
                                  _filter ==
                                      _SchemeFilter
                                          .gold,

                              onTap: () {
                                setState(
                                  () {
                                    _filter =
                                        _SchemeFilter
                                            .gold;
                                  },
                                );
                              },
                            ),

                            // ------------------------------------------
                            // SILVER
                            // ------------------------------------------

                            _buildFilterTab(
                              label:
                                  '◯ Silver',

                              semanticLabel:
                                  'Silver schemes',

                              selected:
                                  _filter ==
                                      _SchemeFilter
                                          .silver,

                              onTap: () {
                                setState(
                                  () {
                                    _filter =
                                        _SchemeFilter
                                            .silver;
                                  },
                                );
                              },
                            ),

                            // ------------------------------------------
                            // CASH
                            // ------------------------------------------

                            _buildFilterTab(
                              label:
                                  '₹ Cash',

                              semanticLabel:
                                  'Cash schemes',

                              selected:
                                  _filter ==
                                      _SchemeFilter
                                          .cash,

                              onTap: () {
                                setState(
                                  () {
                                    _filter =
                                        _SchemeFilter
                                            .cash;
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // --------------------------------------------
                      // FILTER EXPLANATION
                      // --------------------------------------------

                      AnimatedSwitcher(
                        duration:
                            const Duration(
                          milliseconds:
                              180,
                        ),

                        child: Text(
                          _filterDescription,

                          key: ValueKey(
                            _filter,
                          ),

                          textAlign:
                              TextAlign
                                  .center,

                          style:
                              GoogleFonts
                                  .poppins(
                            fontSize: 11.5,

                            color:
                                const Color(
                              0xFF8A8176,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // DATA
                // ==================================================

                Expanded(
                  child:
                      FutureBuilder<
                          List<dynamic>>(
                    future:
                        Future.wait([
                      _schemesFuture,
                      _enrolledFuture,
                    ]),

                    builder:
                        (
                      context,
                      snapshot,
                    ) {
                      // ============================================
                      // LOADING
                      // ============================================

                      if (snapshot
                                  .connectionState ==
                              ConnectionState
                                  .waiting &&
                          !snapshot
                              .hasData) {
                        return const Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                Color(
                              0xFFD4AF37,
                            ),
                          ),
                        );
                      }

                      // ============================================
                      // ERROR
                      // ============================================

                      if (snapshot
                          .hasError) {
                        debugPrint(
                          '[SCHEMES] Load error: ${snapshot.error}',
                        );

                        return RefreshIndicator(
                          color:
                              const Color(
                            0xFFD4AF37,
                          ),

                          onRefresh:
                              _refreshData,

                          child:
                              ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),

                            children: [
                              const SizedBox(
                                height:
                                    120,
                              ),

                              Icon(
                                Icons
                                    .error_outline,

                                size: 48,

                                color:
                                    const Color(
                                  0xFFD4AF37,
                                ).withOpacity(
                                  0.5,
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              Center(
                                child:
                                    Text(
                                  'Failed to load schemes',

                                  style:
                                      GoogleFonts
                                          .poppins(
                                    color:
                                        const Color(
                                      0xFF7A7267,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              Center(
                                child:
                                    Text(
                                  'Pull down to retry',

                                  style:
                                      GoogleFonts
                                          .poppins(
                                    fontSize:
                                        12,

                                    color:
                                        const Color(
                                      0xFFB0A697,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // ============================================
                      // SAFETY
                      // ============================================

                      if (!snapshot
                              .hasData ||
                          snapshot
                                  .data ==
                              null ||
                          snapshot
                                  .data!
                                  .length <
                              2) {
                        return const Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                Color(
                              0xFFD4AF37,
                            ),
                          ),
                        );
                      }

                      // ============================================
                      // AVAILABLE SCHEMES
                      // ============================================

                      final allSchemes =
                          snapshot.data![
                                  0]
                              as List<
                                  SchemeModel>;

                      // ============================================
                      // CUSTOMER ENROLLMENTS
                      // ============================================

                      final enrolled =
                          snapshot.data![
                                  1]
                              as List<
                                  EnrolledScheme>;

                      // ------------------------------------------------
                      // IMPORTANT:
                      //
                      // Use schemeId.
                      //
                      // Never compare scheme names because two different
                      // schemes can have similar names.
                      // ------------------------------------------------

                      final enrolledIds =
                          enrolled
                              .map(
                                (e) =>
                                    e.schemeId,
                              )
                              .where(
                                (id) =>
                                    id
                                        .isNotEmpty,
                              )
                              .toSet();

                      // ============================================
                      // CURRENT FILTER
                      // ============================================

                      final schemes =
                          allSchemes
                              .where(
                                _matchesFilter,
                              )
                              .toList();

                      // ============================================
                      // EMPTY
                      // ============================================

                      if (schemes
                          .isEmpty) {
                        return RefreshIndicator(
                          color:
                              const Color(
                            0xFFD4AF37,
                          ),

                          onRefresh:
                              _refreshData,

                          child:
                              ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),

                            children: [
                              const SizedBox(
                                height:
                                    100,
                              ),

                              Icon(
                                _emptyIcon,

                                size: 48,

                                color:
                                    const Color(
                                  0xFFD4AF37,
                                ).withOpacity(
                                  0.4,
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              Center(
                                child:
                                    Text(
                                  _emptyMessage,

                                  style:
                                      GoogleFonts
                                          .poppins(
                                    color:
                                        const Color(
                                      0xFF7A7267,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // ============================================
                      // SCHEME LIST
                      // ============================================

                      return RefreshIndicator(
                        color:
                            const Color(
                          0xFFD4AF37,
                        ),

                        onRefresh:
                            _refreshData,

                        child:
                            ListView
                                .builder(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            20,
                            4,
                            20,
                            120,
                          ),

                          physics:
                              const AlwaysScrollableScrollPhysics(
                            parent:
                                BouncingScrollPhysics(),
                          ),

                          itemCount:
                              schemes
                                  .length,

                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            final scheme =
                                schemes[
                                    index];

                            final isEnrolled =
                                enrolledIds
                                    .contains(
                              scheme.id,
                            );

                            final isProcessing =
                                _processingSchemeIds
                                    .contains(
                              scheme.id,
                            );

                            return Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                bottom:
                                    20,
                              ),

                              child:
                                  Stack(
                                children: [
                                  SchemeCard(
                                    scheme:
                                        scheme,

                                    isEnrolled:
                                        isEnrolled,

                                    // ==================================
                                    // ENROLL
                                    // ==================================

                                    onEnroll:
                                        ({
                                      required double
                                          selectedAmount,
                                      required String
                                          nomineeName,
                                      required String
                                          nomineeRelation,
                                      required String
                                          nomineePhone,
                                      String?
                                          nomineeAddress,
                                      String?
                                          yourAddress,
                                    }) {
                                      _startEnrollment(
                                        scheme:
                                            scheme,

                                        selectedAmount:
                                            selectedAmount,

                                        nomineeName:
                                            nomineeName,

                                        nomineeRelation:
                                            nomineeRelation,

                                        nomineePhone:
                                            nomineePhone,

                                        nomineeAddress:
                                            nomineeAddress,

                                        yourAddress:
                                            yourAddress,
                                      );
                                    },
                                  ),

                                  // ==================================
                                  // PAYMENT START OVERLAY
                                  // ==================================

                                  if (isProcessing)
                                    Positioned
                                        .fill(
                                      child:
                                          Container(
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              Colors
                                                  .white
                                                  .withOpacity(
                                            0.55,
                                          ),

                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            22,
                                          ),
                                        ),

                                        child:
                                            const Center(
                                          child:
                                              CircularProgressIndicator(
                                            color:
                                                Color(
                                              0xFFD4AF37,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER TAB
  // ============================================================

  Widget _buildFilterTab({
    required String label,
    required String semanticLabel,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Semantics(
        button: true,

        selected:
            selected,

        label:
            semanticLabel,

        child:
            GestureDetector(
          behavior:
              HitTestBehavior
                  .opaque,

          onTap:
              onTap,

          child:
              AnimatedContainer(
            duration:
                const Duration(
              milliseconds:
                  200,
            ),

            padding:
                const EdgeInsets
                    .symmetric(
              vertical: 10,
              horizontal: 2,
            ),

            decoration:
                BoxDecoration(
              color: selected
                  ? const Color(
                      0xFFD4AF37,
                    )
                  : Colors
                      .transparent,

              borderRadius:
                  BorderRadius
                      .circular(
                10,
              ),
            ),

            child:
                Text(
              label,

              textAlign:
                  TextAlign
                      .center,

              maxLines: 1,

              overflow:
                  TextOverflow
                      .ellipsis,

              style:
                  GoogleFonts
                      .poppins(
                fontSize: 12,

                fontWeight:
                    FontWeight
                        .w600,

                color: selected
                    ? Colors.white
                    : const Color(
                        0xFF6E665A,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}