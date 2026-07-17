import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/coupon_service.dart';
import '../../models/coupon_model.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  int _selectedTab = 0;
  List<CouponModel> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    final data = await CouponService.getMyCoupons();
    if (mounted) {
      setState(() {
        _coupons = data;
        _isLoading = false;
      });
    }
  }

  List<CouponModel> get _activeCoupons =>
      _coupons.where((c) => c.isCompleted && !c.isUsed).toList();

  List<CouponModel> get _usedCoupons =>
      _coupons.where((c) => c.isUsed).toList();

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
            // Wrapped the column in DefaultTabController
            child: DefaultTabController(
              length: 2,
              initialIndex: _selectedTab,
              child: Column(
                children: [
                  // ── Header ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Semantics(
                            button: true,
                            label: "Back",
                            excludeSemantics: true,
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 18,
                              color: Color(0xFF7A7267),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Cleaned up hardcoded heading text and used native headingLevel
                        Semantics(
                          header: true,
                          headingLevel: 1,
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
                  ),

                  const SizedBox(height: 16),

                  // ── Native Segmented Toggle (TabBar) ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.all(4), // Mirrors your old margin
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE0CC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        onTap: (index) {
                          setState(() {
                            _selectedTab = index;
                          });
                        },
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF6E665A),
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        tabs: const [
                          Tab(text: "Active"),
                          Tab(text: "Redeemed"),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Content ──────────────────────────────────────
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFD4AF37),
                            ),
                          )
                        : _selectedTab == 0
                            ? _buildCouponList(_activeCoupons, isActive: true)
                            : _buildCouponList(_usedCoupons, isActive: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponList(List<CouponModel> coupons, {required bool isActive}) {
    if (coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.card_giftcard : Icons.history,
              size: 52,
              color: const Color(0xFFD4AF37).withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              isActive ? "No active coupons yet" : "No redeemed coupons yet",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF8E8578),
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 6),
              Text(
                "Complete a scheme to earn a coupon",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFFB8B0A4),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: coupons.length,
      itemBuilder: (context, index) =>
          _buildCouponCard(coupons[index], isActive: isActive),
    );
  }

  Widget _buildCouponCard(CouponModel coupon, {required bool isActive}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0E4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? const Color(0xFFD4AF37).withOpacity(0.5)
              : Colors.grey.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        coupon.schemeName,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
                        color: isActive
                            ? const Color(0xFFD4AF37).withOpacity(0.15)
                            : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? "Active" : "Redeemed",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFFB48A2C)
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Value display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE0CC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: coupon.isWeightBased
                      ? _buildWeightValue(coupon)
                      : _buildCashValue(coupon),
                ),

                const SizedBox(height: 12),

                // ── Scheme summary chips — Wrap prevents overflow ──
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildInfoChip(
                      Icons.calendar_today_outlined,
                      "${coupon.durationMonths} months",
                    ),
                    _buildInfoChip(
                      Icons.currency_rupee,
                      "₹${coupon.monthlyAmount.toInt()}/mo",
                    ),
                    _buildInfoChip(
                      Icons.payments_outlined,
                      "₹${coupon.totalPaid.toInt()} paid",
                    ),
                  ],
                ),

                if (coupon.isUsed && coupon.usedAt != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Redeemed on ${_formatDate(coupon.usedAt!)}",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Dashed divider + coupon code (active only)
          if (isActive) ...[
            _buildDashedDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Coupon Code",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF8E8578),
                        ),
                      ),
                      Text(
                        coupon.code,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB48A2C),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: coupon.code));

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: ExcludeSemantics(
                            child: Text(
                              "Coupon code copied!",
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                          backgroundColor: const Color(0xFFD4AF37),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Semantics(
                      button: true,
                      label: "Copy",
                      hint: "double tap to copy the coupon code",
                      excludeSemantics: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.copy,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Copy",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
          ],
        ],
      ),
    );
  }

  Widget _buildWeightValue(CouponModel coupon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.balance, size: 18, color: Color(0xFFB48A2C)),
        const SizedBox(width: 8),
        Text(
          "${coupon.accumulatedGrams.toStringAsFixed(3)} g",
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3B2A1F),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "gold accumulated",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF8E8578),
          ),
        ),
      ],
    );
  }

  Widget _buildCashValue(CouponModel coupon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "₹",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFB48A2C),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            "${coupon.totalCashValue.toInt()}",
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3B2A1F),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "redeemable value",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF8E8578),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EBDD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF8E8578)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF6E665A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              height: 1,
              color: index.isEven
                  ? const Color(0xFFD4AF37).withOpacity(0.4)
                  : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }
}
