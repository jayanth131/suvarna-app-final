import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:suvarna_jewellers/core/session_manager.dart';
import 'package:suvarna_jewellers/core/notification_service.dart';

import 'package:suvarna_jewellers/screens/auth_choice_screen.dart';

import 'package:suvarna_jewellers/features/schemes/models/enrolled_scheme.dart';
import 'package:suvarna_jewellers/features/schemes/data/enrolled_scheme_service.dart';
import 'package:suvarna_jewellers/features/schemes/data/payment_service.dart';
import 'package:suvarna_jewellers/features/schemes/presentation/schemes_screen.dart';

import 'package:suvarna_jewellers/features/products/presentation/products_screen.dart';
import 'package:suvarna_jewellers/features/rates/presentation/rates_screen.dart';
import 'package:suvarna_jewellers/features/profile/presentation/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  String _schemeFilter = "GOLD";

  Future<List<EnrolledScheme>>? _schemesFuture;

  final GlobalKey<SchemesScreenState> _schemesKey =
      GlobalKey<SchemesScreenState>();

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    EnrolledSchemeService.invalidateCache();

    _schemesFuture =
        EnrolledSchemeService.getUserSchemes();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.checkAndNotifyDueDates();
    });
  }

  // ============================================================
  // REFRESH SCHEMES
  // ============================================================

  void refreshSchemes() {
    if (!mounted) return;

    setState(() {
      _schemesFuture =
          EnrolledSchemeService.getUserSchemes(
        forceRefresh: true,
      );
    });

    _schemesKey.currentState?.refreshData();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void _onLogout() async {
    await SessionManager.clearSession();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthChoiceScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // OPEN SCHEME DETAILS
  // ============================================================

  void _openSchemeDetails(
    EnrolledScheme scheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(
        0xFFF6F0E4,
      ),

      // Accessibility
      barrierLabel: "Close",

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (_) => _buildBottomSheet(
        scheme,
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (didPop, result) async {
        if (didPop) return;

        // If user is not on Home,
        // first return to Home.
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });

          return;
        }

        // Already on Home tab.
        final confirm =
            await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              backgroundColor:
                  const Color(0xFFF6F0E4),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20),
              ),
              title: Text(
                "Exit App",
                style:
                    GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      const Color(0xFF3B2A1F),
                ),
              ),
              content: Text(
                "Are you sure you want to exit?",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color:
                      const Color(0xFF6E665A),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      ctx,
                      false,
                    );
                  },
                  child: Text(
                    "Stay",
                    style:
                        GoogleFonts.poppins(
                      color: const Color(
                        0xFF9E8E7E,
                      ),
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      ctx,
                      true,
                    );
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFD4AF37,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  child: Text(
                    "Exit",
                    style:
                        GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            // ====================================================
            // BACKGROUND
            // ====================================================

            Positioned.fill(
              child: Image.asset(
                "assets/images/showroom_bg.png",
                fit: BoxFit.cover,
              ),
            ),

            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 4,
                  sigmaY: 4,
                ),
                child: Container(
                  color: const Color(
                    0xFFF5EBDD,
                  ).withOpacity(0.55),
                ),
              ),
            ),

            // ====================================================
            // PAGE CONTENT
            // ====================================================

            SafeArea(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomeContent(),

                  ProductsScreen(),

                  SchemesScreen(
                    key: _schemesKey,
                  ),

                  RatesScreen(),

                  const ProfileScreen(),
                ],
              ),
            ),
          ],
        ),

        bottomNavigationBar:
            _buildBottomNav(),
      ),
    );
  }

  // ============================================================
  // HOME CONTENT
  // ============================================================

  Widget _buildHomeContent() {
    return FutureBuilder<
        List<EnrolledScheme>>(
      future: _schemesFuture,
      builder: (context, snapshot) {
        // --------------------------------------------------------
        // LOADING
        // --------------------------------------------------------

        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child:
                CircularProgressIndicator(
              color: Color(
                0xFFD4AF37,
              ),
            ),
          );
        }

        // --------------------------------------------------------
        // ERROR
        // --------------------------------------------------------

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Something went wrong",
            ),
          );
        }

        // --------------------------------------------------------
        // SCHEMES
        // --------------------------------------------------------

        final List<EnrolledScheme>
            allSchemes =
            snapshot.data ?? [];

        final List<EnrolledScheme>
            schemes =
            allSchemes.where((scheme) {
          switch (_schemeFilter) {
            case "SILVER":
              return scheme.isSilver;
            case "CASH":
              return scheme.isCash;
            case "GOLD":
            default:
              return scheme.isGold;
          }
        }).toList();

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // FIXED HEADER
            // ==================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                0,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  // ------------------------------------------------
                  // BRAND
                  // ------------------------------------------------

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .center,
                    children: [
                      Image.asset(
                        "assets/images/suvarna_logo.png",
                        height: 44,
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          // Accessibility preserved.
                          Semantics(
                            header: true,
                            headingLevel: 1,
                            child: Text(
                              "Suvarna Jewellers",
                              style:
                                  GoogleFonts
                                      .playfairDisplay(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight
                                        .w700,
                                color:
                                    const Color(
                                  0xFF2E2118,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ------------------------------------------------
                  // USER GREETING
                  // ------------------------------------------------

                  FutureBuilder<String?>(
                    future:
                        SessionManager
                            .getUserName(),
                    builder:
                        (
                      context,
                      snapshot,
                    ) {
                      final username =
                          snapshot.data ??
                              "Member";

                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          // Accessibility preserved.
                          Semantics(
                            headingLevel: 2,
                            child: Text(
                              "Hello, $username",
                              style:
                                  GoogleFonts
                                      .playfairDisplay(
                                fontSize: 26,
                                fontWeight:
                                    FontWeight
                                        .w700,
                                color:
                                    const Color(
                                  0xFF2E2118,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // ------------------------------------------------
                  // YOUR SCHEMES TITLE
                  // ------------------------------------------------

                  Row(
                    children: [
                      // Accessibility preserved.
                      Semantics(
                        headingLevel: 3,
                        header: true,
                        child: Text(
                          "Your Schemes",
                          style:
                              GoogleFonts
                                  .playfairDisplay(
                            fontSize: 20,
                            fontWeight:
                                FontWeight
                                    .w700,
                            color:
                                const Color(
                              0xFF2E2118,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Container(
                        height: 1.5,
                        width: 40,
                        color: const Color(
                          0xFFD4AF37,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ------------------------------------------------
                  // GOLD / CASH FILTER
                  // ------------------------------------------------

                  DefaultTabController(
                    length: 3,
                    initialIndex:
                        _schemeFilter == "GOLD"
                            ? 0
                            : _schemeFilter == "SILVER"
                                ? 1
                                : 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE0CC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        onTap: (index) {
                          setState(() {
                            _schemeFilter =
                                index == 0
                                    ? "GOLD"
                                    : index == 1
                                        ? "SILVER"
                                        : "CASH";
                          });
                        },
                        indicatorSize:
                            TabBarIndicatorSize.tab,
                        dividerColor:
                            Colors.transparent,
                        indicator: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor:
                            const Color(0xFF6E665A),
                        labelStyle:
                            GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle:
                            GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(
                            height: 38,
                            text: "✦ Gold",
                          ),
                          Tab(
                            height: 38,
                            text: "◯ Silver",
                          ),
                          Tab(
                            height: 38,
                            text: "₹ Cash",
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),
                ],
              ),
            ),

            // ==================================================
            // SCROLLABLE SCHEMES
            // ==================================================

            Expanded(
              child: RefreshIndicator(
                color: const Color(
                  0xFFD4AF37,
                ),
                onRefresh: () async {
                  EnrolledSchemeService
                      .invalidateCache();

                  refreshSchemes();
                },

                // ------------------------------------------------
                // ASSUME NO ENROLLED SCHEMES
                //
                // If API returns an empty list, this empty state
                // is shown automatically.
                // ------------------------------------------------

                child: schemes.isEmpty
                    ? ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: [
                          _buildEmptyState(),
                        ],
                      )
                    : ListView.builder(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          20,
                          0,
                          20,
                          120,
                        ),
                        itemCount:
                            schemes.length,
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          return _buildSchemeCard(
                            schemes[index],
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final IconData icon =
        _schemeFilter == "GOLD"
            ? Icons.balance
            : _schemeFilter == "SILVER"
                ? Icons.circle_outlined
                : Icons.currency_rupee;

    final String message =
        _schemeFilter == "GOLD"
            ? "No gold schemes enrolled yet"
            : _schemeFilter == "SILVER"
                ? "No silver schemes enrolled yet"
                : "No cash schemes enrolled yet";

    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 52,
              color: const Color(0xFFD4AF37).withOpacity(0.4),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF7A6A58),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Go to Schemes tab to get started",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFFB8B0A4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ENROLLED SCHEME CARD
  // ============================================================

  Widget _buildSchemeCard(
    EnrolledScheme scheme,
  ) {
    double progress =
        scheme.totalMonths > 0
            ? scheme.monthsPaid /
                scheme.totalMonths
            : 0;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),
      child: Column(
        children: [
          // ------------------------------------------------------
          // SCHEME CARD
          // ------------------------------------------------------

          InkWell(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            onTap: () =>
                _openSchemeDetails(
              scheme,
            ),
            child: Container(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFF6F0E4,
                ).withOpacity(0.97),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
                border: Border.all(
                  color: const Color(
                    0xFFD4AF37,
                  ),
                  width: 0.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                      0.05,
                    ),
                    blurRadius: 10,
                    offset:
                        const Offset(
                      0,
                      6,
                    ),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          scheme.name,
                          style:
                              GoogleFonts
                                  .playfairDisplay(
                            fontSize: 17,
                            fontWeight:
                                FontWeight
                                    .w600,
                            color:
                                const Color(
                              0xFF3B2A1F,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFD4AF37,
                          ).withOpacity(
                            0.12,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child: Text(
                          "${scheme.monthsPaid}/${scheme.totalMonths} paid",
                          style:
                              GoogleFonts
                                  .poppins(
                            fontSize: 11,
                            fontWeight:
                                FontWeight
                                    .w600,
                            color:
                                const Color(
                              0xFFB48A2C,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Text(
                        "₹${scheme.amountPaid} paid",
                        style:
                            GoogleFonts
                                .poppins(
                          fontSize: 13,
                          color:
                              const Color(
                            0xFF6E665A,
                          ),
                        ),
                      ),
                      Text(
                        "₹${scheme.amountBalance} remaining",
                        style:
                            GoogleFonts
                                .poppins(
                          fontSize: 12,
                          color:
                              const Color(
                            0xFF9E8E7E,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  ClipRRect(
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                    child:
                        LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor:
                          const Color(
                        0xFFE7DBC9,
                      ),
                      valueColor:
                          const AlwaysStoppedAnimation(
                        Color(
                          0xFFB48A2C,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      Text(
                        scheme.hasMissedInstallments
                            ? "Missed payment — store required"
                            : scheme.canPayOnline
                                ? "Tap to pay →"
                                : scheme.isCompleted
                                    ? "Completed"
                                    : "View details",
                        style:
                            GoogleFonts
                                .poppins(
                          fontSize: 11,
                          color:
                              const Color(
                            0xFFB48A2C,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ------------------------------------------------------
          // WALLET
          // ------------------------------------------------------

          const SizedBox(
            height: 8,
          ),

          _buildWalletCard(
            scheme,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WALLET CARD
  // ============================================================

  Widget _buildWalletCard(
    EnrolledScheme scheme,
  ) {
    final bool isMetal = scheme.isMetal;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E2118),
            Color(0xFF4A3728),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMetal
                      ? Icons.scale_outlined
                      : Icons.account_balance_wallet_outlined,
                  color: const Color(0xFFD4AF37),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheme.accumulatedLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFFD4AF37).withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMetal
                          ? "${scheme.accumulatedGrams.toStringAsFixed(3)} g"
                          : "₹${scheme.amountPaid}",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  scheme.assetLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
              ),
            ],
          ),
          if (isMetal && scheme.lastPaymentGrams > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_upward,
                    size: 13,
                    color: Color(0xFFD4AF37),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Last payment: +${scheme.lastPaymentGrams.toStringAsFixed(3)} g",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFFD4AF37).withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SCHEME DETAILS BOTTOM SHEET
  // ============================================================

  Widget _buildBottomSheet(
  EnrolledScheme scheme,
) {
  final bool isButtonDisabled =
      !scheme.canPayOnline;

  String buttonText =
      "Pay Now — ₹${scheme.installmentAmount}";

  if (scheme.isCompleted) {
    buttonText = "Completed";
  } else if (scheme.scheduleMissing) {
    buttonText =
        "Installment schedule missing. Contact the store.";
  } else if (scheme.hasMissedInstallments) {
    buttonText =
        scheme.missedInstallmentCount == 1
            ? "1 missed installment — visit store to clear"
            : "${scheme.missedInstallmentCount} missed installments — visit store to clear";
  } else if (scheme.isPaidThisMonth) {
    buttonText =
        "Paid for this month";
  } else if (!scheme.isNextInstallmentDue) {
    buttonText =
        "Next installment is not due yet";
  }

  final mediaQuery =
      MediaQuery.of(context);

  return SafeArea(
    top: false,
    child: Padding(
      // Keeps the bottom sheet safe when keyboard / navigation
      // insets are present.
      padding: EdgeInsets.only(
        bottom:
            mediaQuery.viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // Prevent the bottom sheet from becoming taller
          // than the available screen.
          maxHeight:
              mediaQuery.size.height *
                  0.90,
        ),
        child: Material(
          color:
              const Color(0xFFF8F2E7),
          borderRadius:
              const BorderRadius.vertical(
            top:
                Radius.circular(28),
          ),
          clipBehavior:
              Clip.antiAlias,
          child: Column(
            children: [
              // ================================================
              // DRAG HANDLE
              // ================================================

              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 12,
                ),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey[400],
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              ),

              // ================================================
              // SCROLLABLE CONTENT
              // ================================================

              Expanded(
                child:
                    SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    22,
                    16,
                    22,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      // ========================================
                      // TITLE
                      // ========================================

                      Text(
                        scheme.name,
                        textAlign:
                            TextAlign.center,
                        style: GoogleFonts
                            .playfairDisplay(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        scheme.assetLabel,
                        textAlign:
                            TextAlign.center,
                        style:
                            GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              const Color(
                            0xFFB48A2C,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // ========================================
                      // DETAILS
                      // ========================================

                      _detailItem(
                        "Monthly Installment",
                        "₹${scheme.installmentAmount}",
                      ),

                      _detailItem(
                        "Total Scheme Amount",
                        "₹${scheme.totalAmount}",
                      ),

                      _detailItem(
                        "Amount Paid",
                        "₹${scheme.amountPaid}",
                      ),

                      _detailItem(
                        "Balance Amount",
                        "₹${scheme.amountBalance}",
                      ),

                      _detailItem(
                        "Months Completed",
                        "${scheme.monthsPaid} of ${scheme.totalMonths}",
                      ),

                      _detailItem(
                        "Last Payment Date",
                        scheme
                                .lastPaymentDate
                                .isEmpty
                            ? "-"
                            : scheme
                                .lastPaymentDate,
                      ),

                      _detailItem(
                        "Next Due Date",
                        scheme.nextDueDate
                                .isEmpty
                            ? "-"
                            : scheme
                                .nextDueDate,
                      ),

                      if (scheme
                              .nextInstallmentNumber !=
                          null)
                        _detailItem(
                          "Next Installment",
                          "#${scheme.nextInstallmentNumber}",
                        ),

                      if (scheme
                          .hasMissedInstallments)
                        _detailItem(
                          "Missed Installments",
                          "${scheme.missedInstallmentCount}",
                        ),

                      if (scheme.isMetal)
                        _detailItem(
                          scheme.isSilver
                              ? "Silver Accumulated"
                              : "Gold Accumulated",
                          "${scheme.accumulatedGrams.toStringAsFixed(3)} g",
                        ),

                      // ========================================
                      // MISSED INSTALLMENT WARNING
                      // ========================================

                      if (scheme
                          .hasMissedInstallments) ...[
                        const SizedBox(
                          height: 12,
                        ),

                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(
                            12,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.orange
                                .withOpacity(
                              0.08,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            border:
                                Border.all(
                              color: Colors
                                  .orange
                                  .withOpacity(
                                0.25,
                              ),
                            ),
                          ),
                          child: Text(
                            "Previous installment is missed. Please visit the store to clear it.",
                            textAlign:
                                TextAlign
                                    .center,
                            style: GoogleFonts
                                .poppins(
                              fontSize: 12,
                              height: 1.45,
                              color:
                                  const Color(
                                0xFF6E665A,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 24,
                      ),

                      // ========================================
                      // PAYMENT BUTTON
                      // ========================================

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton(
                          onPressed:
                              isButtonDisabled
                                  ? null
                                  : () {
                                      Navigator.pop(
                                        context,
                                      );

                                      PaymentService
                                          .startPayment(
                                        context:
                                            context,
                                        schemeId:
                                            scheme
                                                .schemeId,
                                        amount:
                                            scheme
                                                .installmentAmount,
                                        onSuccess:
                                            () {
                                          EnrolledSchemeService
                                              .invalidateCache();

                                          refreshSchemes();
                                        },
                                      );
                                    },
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xFFD4AF37,
                            ),
                            disabledBackgroundColor:
                                Colors.grey
                                    .shade300,
                            disabledForegroundColor:
                                Colors.grey
                                    .shade600,
                            minimumSize:
                                const Size(
                              double.infinity,
                              52,
                            ),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  16,
                              vertical:
                                  12,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),
                            ),
                          ),
                          child:
                              Text(
                            buttonText,
                            textAlign:
                                TextAlign
                                    .center,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w600,
                              fontSize:
                                  14,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
  // ============================================================
  // DETAIL ITEM
  // ============================================================

  Widget _detailItem(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets
              .symmetric(
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  GoogleFonts.poppins(
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  GoogleFonts.poppins(
                fontWeight:
                    FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex:
          _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex =
              index;
        });
      },
      selectedItemColor:
          const Color(
        0xFFD4AF37,
      ),
      unselectedItemColor:
          const Color(
        0xFF7A7267,
      ),
      type:
          BottomNavigationBarType
              .fixed,
      items: const [
        BottomNavigationBarItem(
          icon:
              Icon(Icons.home),
          label:
              "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.shopping_bag,
          ),
          label:
              "Products",
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.description,
          ),
          label:
              "Schemes",
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.trending_up,
          ),
          label:
              "Rates",
        ),
        BottomNavigationBarItem(
          icon:
              Icon(Icons.person),
          label:
              "Profile",
        ),
      ],
    );
  }
}