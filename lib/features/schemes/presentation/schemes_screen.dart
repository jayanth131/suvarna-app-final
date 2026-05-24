import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suvarna_jewellers/features/schemes/data/scheme_model.dart';
import 'package:suvarna_jewellers/features/schemes/data/scheme_service.dart';
import 'package:suvarna_jewellers/features/schemes/data/enrolled_scheme_service.dart';
import 'package:suvarna_jewellers/features/schemes/models/enrolled_scheme.dart';
import 'package:suvarna_jewellers/features/schemes/presentation/widgets/scheme_card.dart';
import '../data/payment_service.dart';

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  SchemesScreenState createState() => SchemesScreenState(); 
}

class SchemesScreenState extends State<SchemesScreen> {
  late Future<List<SchemeModel>> _schemesFuture;
  late Future<List<EnrolledScheme>> _enrolledFuture;
  bool _showGold = true;

  @override
  void initState() {
    super.initState();
    _schemesFuture = SchemeService.getSchemes();
    _enrolledFuture = EnrolledSchemeService.getUserSchemes();
  }

  @override
  void dispose() {
    // PaymentService.dispose();
    super.dispose();
  }

  void refreshData() {
    print("[SCHEMES] refreshData called");
    if (!mounted) {
      print("[SCHEMES] Widget not mounted, skipping refresh");
      return;
    }
    try {
      print("[SCHEMES] Invalidating cache and refreshing data");
      EnrolledSchemeService.invalidateCache();
      setState(() {
        _schemesFuture = SchemeService.getSchemes();
        _enrolledFuture =
            EnrolledSchemeService.getUserSchemes(forceRefresh: true);
      });
      print("[SCHEMES] Data refresh completed");
    } catch (e) {
      print("[SCHEMES] Error during refresh: $e");
    }
  }

  Future<void> _refreshData() async => refreshData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                color: const Color(0xFFF5EBDD).withOpacity(0.65),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Fixed header ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      Center(
                        child: Image.asset(
                          "assets/images/suvarna_logo.png",
                          height: 56,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Saving Schemes",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B2A1F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Invest in your golden future",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF7A7267),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Gold / Cash filter ──────────────────────
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE0CC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _buildFilterTab(
                              label: "✦  Gold Schemes",
                              selected: _showGold,
                              onTap: () => setState(() => _showGold = true),
                            ),
                            _buildFilterTab(
                              label: "₹  Cash Schemes",
                              selected: !_showGold,
                              onTap: () => setState(() => _showGold = false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Scheme list ───────────────────────────────────
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: Future.wait([_schemesFuture, _enrolledFuture]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFD4AF37),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Failed to load schemes"),
                        );
                      }

                      final allSchemes =
                      snapshot.data![0] as List<SchemeModel>;
                      final enrolled =
                      snapshot.data![1] as List<EnrolledScheme>;
                      final enrolledIds =
                      enrolled.map((e) => e.name.trim()).toSet();

                      // Filter by isWeightBased
                      final schemes = allSchemes
                          .where((s) =>
                      _showGold ? s.isWeightBased : !s.isWeightBased)
                          .toList();

                      if (schemes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showGold
                                    ? Icons.balance
                                    : Icons.currency_rupee,
                                size: 48,
                                color:
                                const Color(0xFFD4AF37).withOpacity(0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _showGold
                                    ? "No gold schemes available"
                                    : "No cash schemes available",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF7A7267),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: const Color(0xFFD4AF37),
                        onRefresh: _refreshData,
                        child: ListView.builder(
                          padding:
                          const EdgeInsets.fromLTRB(20, 4, 20, 120),
                          physics: const BouncingScrollPhysics(),
                          itemCount: schemes.length,
                          itemBuilder: (context, index) {
                            final scheme = schemes[index];
                            final isEnrolled =
                            enrolledIds.contains(scheme.name.trim());
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: SchemeCard(
                                scheme: scheme,
                                isEnrolled: isEnrolled,
                                onEnroll: () {
                                  PaymentService.startPayment(
                                    context: context,
                                    schemeId: scheme.id,
                                    amount: scheme.monthlyAmount,
                                    onSuccess: refreshData,
                                  );
                                },
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

  Widget _buildFilterTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFD4AF37) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF6E665A),
            ),
          ),
        ),
      ),
    );
  }
}