import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:suvarna_jewellers/core/session_manager.dart';
import 'package:suvarna_jewellers/screens/auth_choice_screen.dart';

import 'package:suvarna_jewellers/features/schemes/models/enrolled_scheme.dart';
import 'package:suvarna_jewellers/features/schemes/data/enrolled_scheme_service.dart';
import 'package:suvarna_jewellers/features/schemes/presentation/schemes_screen.dart';

import 'package:suvarna_jewellers/features/products/presentation/products_screen.dart';
import 'package:suvarna_jewellers/features/rates/presentation/rates_screen.dart';
import 'package:suvarna_jewellers/features/profile/presentation/profile_screen.dart';
import 'package:suvarna_jewellers/features/schemes/data/payment_service.dart';
import 'package:suvarna_jewellers/core/notification_service.dart';
import 'package:flutter/services.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _showGold = true; // filter for home schemes tab
  Future<List<EnrolledScheme>>? _schemesFuture;

  final GlobalKey<SchemesScreenState> _schemesKey =
      GlobalKey<SchemesScreenState>();

  @override
  void initState() {
    super.initState();
    EnrolledSchemeService.invalidateCache();
    _schemesFuture = EnrolledSchemeService.getUserSchemes();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.checkAndNotifyDueDates();
    });
  }

  void refreshSchemes() {
    if (!mounted) return;
    setState(() {
      _schemesFuture = EnrolledSchemeService.getUserSchemes(forceRefresh: true);
    });
    _schemesKey.currentState?.refreshData();
  }

  void _onLogout() async {
    await SessionManager.clearSession();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
      (route) => false,
    );
  }

  void _openSchemeDetails(EnrolledScheme scheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6F0E4),
      barrierLabel: "Close", // Fixes TalkBack "scrim" issue
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _buildBottomSheet(scheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // Already on Home tab — ask before exiting
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFFF6F0E4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              "Exit App",
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B2A1F),
              ),
            ),
            content: Text(
              "Are you sure you want to exit?",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6E665A),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  "Stay",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9E8E7E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Exit",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
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
                  color: const Color(0xFFF5EBDD).withOpacity(0.55),
                ),
              ),
            ),
            SafeArea(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomeContent(),
                  ProductsScreen(),
                  SchemesScreen(key: _schemesKey),
                  RatesScreen(),
                  const ProfileScreen(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHomeContent() {
    return FutureBuilder<List<EnrolledScheme>>(
      future: _schemesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
          );
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }

        final List<EnrolledScheme> allSchemes = snapshot.data ?? [];

        // Filter schemes based on selected tab
        final List<EnrolledScheme> schemes = allSchemes
            .where((s) => _showGold ? s.isWeightBased : !s.isWeightBased)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fixed Header (never scrolls) ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset("assets/images/suvarna_logo.png", height: 44),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            headingLevel: 1,
                            child: Text(
                              "Suvarna Jewellers",
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E2118),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  FutureBuilder<String?>(
                    future: SessionManager.getUserName(),
                    builder: (context, snapshot) {
                      final username = snapshot.data ?? "Member";

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            headingLevel: 2,
                            child: Text(
                              "Hello, $username",
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E2118),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Section label
                  Row(
                    children: [
                      Semantics(
                        headingLevel: 3,
                        header: true,
                        child: Text(
                          "Your Schemes",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E2118),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 1.5,
                        width: 40,
                        color: const Color(0xFFD4AF37),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Gold / Cash Native Filter Tabs ─────────────────────
                  DefaultTabController(
                    length: 2,
                    initialIndex: _showGold ? 0 : 1, // Keeps tab active state in sync
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE0CC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        onTap: (index) {
                          setState(() {
                            _showGold = index == 0;
                          });
                        },
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent, // Hides native underline
                        indicator: BoxDecoration(
                          color: const Color(0xFFD4AF37), 
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: Colors.white, // Active text color
                        unselectedLabelColor: const Color(0xFF6E665A), // Inactive text color
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(
                            height: 38,
                            text: "✦  Gold Schemes",
                          ),
                          Tab(
                            height: 38,
                            text: "₹  Cash Schemes",
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Scrollable Content ────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFD4AF37),
                onRefresh: () async {
                  EnrolledSchemeService.invalidateCache();
                  refreshSchemes();
                },
                child: schemes.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [_buildEmptyState()],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        itemCount: schemes.length,
                        itemBuilder: (context, index) {
                          return _buildSchemeCard(schemes[index]);
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              _showGold ? Icons.balance : Icons.currency_rupee,
              size: 52,
              color: const Color(0xFFD4AF37).withOpacity(0.4),
            ),
            const SizedBox(height: 14),
            Text(
              _showGold
                  ? "No gold schemes enrolled yet"
                  : "No cash schemes enrolled yet",
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

  Widget _buildSchemeCard(EnrolledScheme scheme) {
    double progress = scheme.totalMonths > 0
        ? scheme.monthsPaid / scheme.totalMonths
        : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // ── Scheme Card ───────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openSchemeDetails(scheme),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F0E4).withOpacity(0.97),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD4AF37), width: 0.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          scheme.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3B2A1F),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${scheme.monthsPaid}/${scheme.totalMonths} paid",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB48A2C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹${scheme.amountPaid} paid",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF6E665A),
                        ),
                      ),
                      Text(
                        "₹${scheme.amountBalance} remaining",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF9E8E7E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE7DBC9),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFB48A2C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "Tap to pay →",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFFB48A2C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Wallet Card ───────────────────────────────────────
          const SizedBox(height: 8),
          _buildWalletCard(scheme),
        ],
      ),
    );
  }

  Widget _buildWalletCard(EnrolledScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E2118), Color(0xFF4A3728)],
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
                  scheme.isWeightBased
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
                      scheme.isWeightBased ? "Gold Accumulated" : "Cash Saved",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFFD4AF37).withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scheme.isWeightBased
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
                  scheme.isWeightBased ? "Gold" : "Cash",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
              ),
            ],
          ),

          if (scheme.isWeightBased && scheme.lastPaymentGrams > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    "This month: +${scheme.lastPaymentGrams.toStringAsFixed(3)} g",
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

  Widget _buildBottomSheet(EnrolledScheme scheme) {
    // --- Helper to strictly parse DD-MM-YYYY from your API ---
    DateTime? parseDate(String dateStr) {
      try {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]), // Year
            int.parse(parts[1]), // Month
            int.parse(parts[0]), // Day
          );
        }
      } catch (e) {
        debugPrint("Date parsing error: $e");
      }
      return null;
    }

    // --- Date Logic Evaluation ---
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    
    DateTime? lastPayment = parseDate(scheme.lastPaymentDate);
    DateTime? nextDue = parseDate(scheme.nextDueDate);

    bool isPaidThisMonth = false;
    bool isMissed = false;

    // 1. Check if the user already paid in the current calendar month
    if (lastPayment != null) {
      isPaidThisMonth = (lastPayment.year == today.year && lastPayment.month == today.month);
    }

    // 2. If not paid this month, check if today is PAST the next due date
    if (!isPaidThisMonth && nextDue != null) {
      if (today.isAfter(nextDue)) {
        isMissed = true;
      }
    }

    // 3. Determine Final Button State
    bool isCompleted = scheme.monthsPaid >= scheme.totalMonths;
    bool isButtonDisabled = isCompleted || isPaidThisMonth || isMissed;

    String buttonText = "Pay Now — ₹${scheme.monthlyAmount}/month";
    if (isCompleted) {
      buttonText = "Completed";
    } else if (isPaidThisMonth) {
      buttonText = "Paid for this month";
    } else if (isMissed) {
      buttonText = "Date crossed. Visit Suvarna Jewellers store in order to pay for this month.";
    }
    // -----------------------------

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            scheme.name,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          _detailItem("Total Scheme Amount", "₹${scheme.totalAmount}"),
          _detailItem("Amount Paid", "₹${scheme.amountPaid}"),
          _detailItem("Balance Amount", "₹${scheme.amountBalance}"),
          _detailItem(
            "Months Completed",
            "${scheme.monthsPaid} of ${scheme.totalMonths}",
          ),
          _detailItem("Last Payment Date", scheme.lastPaymentDate),
          _detailItem("Next Due Date", scheme.nextDueDate),
          if (scheme.isWeightBased)
            _detailItem(
              "Gold Accumulated",
              "${scheme.accumulatedGrams.toStringAsFixed(3)} g",
            ),
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: isButtonDisabled
                ? null
                : () {
                    Navigator.pop(context);
                    PaymentService.startPayment(
                      context: context,
                      schemeId: scheme.schemeId,
                      amount: scheme.monthlyAmount,
                      onSuccess: () {
                        EnrolledSchemeService.invalidateCache();
                        refreshSchemes(); 
                      },
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isButtonDisabled
                  ? Colors.grey.shade400
                  : const Color(0xFFD4AF37),
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
              minimumSize: const Size(double.infinity, 52),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              buttonText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      selectedItemColor: const Color(0xFFD4AF37),
      unselectedItemColor: const Color(0xFF7A7267),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: "Products",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description),
          label: "Schemes",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: "Rates"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}