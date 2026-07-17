import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suvarna_jewellers/features/schemes/data/enrolled_scheme_service.dart';
import 'package:suvarna_jewellers/features/schemes/models/enrolled_scheme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Exclude background from semantics so TalkBack ignores it
          Positioned.fill(
            child: ExcludeSemantics(
              child: Image.asset(
                "assets/images/showroom_bg.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: ExcludeSemantics(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: const Color(0xFFF5EBDD).withOpacity(0.55),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      // Semantic label and button trait added here
                      Semantics(
                        label: "Back",
                        button: true,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: Color(0xFF7A7267),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Semantic header trait added here
                      Semantics(
                        header: true,
                        headingLevel:1,
                        child: Text(
                          "Notifications",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3B2A1F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Content ──────────────────────────────────────
                Expanded(
                  child: FutureBuilder<List<EnrolledScheme>>(
                    future: EnrolledSchemeService.getUserSchemes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFD4AF37),
                          ),
                        );
                      }

                      final schemes = snapshot.data!;
                      final notifications = _buildNotifications(schemes);

                      if (notifications.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) =>
                            _buildNotificationCard(notifications[index]),
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

  List<Map<String, dynamic>> _buildNotifications(
      List<EnrolledScheme> schemes) {
    final today = DateTime.now();
    final List<Map<String, dynamic>> result = [];

    for (final scheme in schemes) {
      if (scheme.nextDueDate == "Completed") continue;

      final parts = scheme.nextDueDate.split("-");
      if (parts.length != 3) continue;

      final dueDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );

      final diff = dueDate
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;

      if (diff > 5) continue;

      String message;
      IconData icon;
      Color iconColor;

      if (diff < 0) {
        message = "${scheme.name} payment is overdue. Visit the showroom.";
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.redAccent;
      } else if (diff == 0) {
        message = "${scheme.name} payment is due today.";
        icon = Icons.notifications_active;
        iconColor = const Color(0xFFB48A2C);
      } else if (diff == 1) {
        message = "${scheme.name} payment is due tomorrow.";
        icon = Icons.notifications;
        iconColor = const Color(0xFFB48A2C);
      } else {
        message = "${scheme.name} payment due in $diff days.";
        icon = Icons.notifications_outlined;
        iconColor = const Color(0xFFB48A2C);
      }

      result.add({
        "title": "Scheme Reminder",
        "message": message,
        "icon": icon,
        "iconColor": iconColor,
        "urgency": diff,
      });
    }

    // Sort: overdue first, then nearest due
    result.sort((a, b) =>
        (a["urgency"] as int).compareTo(b["urgency"] as int));

    return result;
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    final isOverdue = (n["urgency"] as int) < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0E4).withOpacity(0.97),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOverdue
              ? Colors.redAccent.withOpacity(0.3)
              : const Color(0xFFD4AF37).withOpacity(0.4),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: isOverdue
                  ? Colors.redAccent.withOpacity(0.1)
                  : const Color(0xFFD4AF37).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              n["icon"] as IconData,
              color: n["iconColor"] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n["title"] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B2A1F),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  n["message"] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF6E665A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 56,
            color: const Color(0xFFD4AF37).withOpacity(0.35),
          ),
          const SizedBox(height: 14),
          Text(
            "No notifications right now",
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF8E8578),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "We'll remind you before your next payment",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFFB8B0A4),
            ),
          ),
        ],
      ),
    );
  }
}