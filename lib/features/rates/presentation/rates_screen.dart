import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../rates/data/rate_service.dart';
import '../models/rate_model.dart';
import 'widgets/rate_card.dart';

class RatesScreen extends StatelessWidget {
  const RatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
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
            child: Container(color: const Color(0xFFF5EBDD).withOpacity(0.55)),
          ),
        ),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      headingLevel: 1,
                      label: "Live Rates",
                      excludeSemantics: true,
                      child: Text(
                        "Live Rates",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B2A1F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      headingLevel: 2,
                      label: "Updated today · Market rates",
                      excludeSemantics: true,
                      child: Text(
                        "Updated today · Market rates",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF9E8E7E),
                        ),
                      ),
                    ),
                    
                    
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Rates list — no info banner ──────────────────────
              Expanded(
                child: FutureBuilder<List<RateModel>>(
                  future: RateService.getRates(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFD4AF37),
                        ),
                      );
                    }

                    final rates = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                      itemCount: rates.length,
                      itemBuilder: (context, index) {
                        return RateCard(rate: rates[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
