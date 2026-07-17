import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:suvarna_jewellers/core/session_manager.dart';
import 'package:suvarna_jewellers/features/profile/presentation/screens/contact_screen.dart';
import 'package:suvarna_jewellers/features/profile/presentation/widgets/profile_menu_tile.dart';
import 'package:suvarna_jewellers/screens/auth_choice_screen.dart';
import 'package:suvarna_jewellers/features/profile/presentation/screens/coupons_screen.dart';
import 'package:suvarna_jewellers/features/profile/presentation/screens/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  // final int openCount;
  final Function(int)? onNavigate;

  const ProfileScreen({super.key, this.onNavigate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? mobile;
  String? fullName;
  bool _isLogoutDialogVisible = false;
  bool _isDeleteDialogVisible = false;
  bool _isDeletingAccount = false;

  // FIX (Issue 3 - Dialog accessibility):
  // FocusNodes used to move screen-reader/keyboard focus INTO each dialog
  // the moment it opens, so TalkBack/VoiceOver starts reading from the
  // dialog instead of leaving focus on whatever was behind it.
  final FocusNode _logoutDialogFocusNode = FocusNode(
    debugLabel: 'logoutDialog',
  );
  final FocusNode _deleteDialogFocusNode = FocusNode(
    debugLabel: 'deleteDialog',
  );

  // FIX (TalkBack jumping straight to Cancel): a plain FocusNode on a Text
  // widget only moves *keyboard* focus — Text has no semantics config that
  // reports isFocusable, so the accessibility (TalkBack) cursor ignored it
  // and Android auto-focused the first actionable control (Cancel) instead.
  // Semantics(focusable: true, focused: true) is the correct API for
  // programmatically placing accessibility focus on non-interactive text.
  bool _logoutTitleFocused = false;
  bool _deleteTitleFocused = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _logoutDialogFocusNode.dispose();
    _deleteDialogFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final username = await SessionManager.getUsername();
    final name = await SessionManager.getUserName();

    if (mounted) {
      setState(() {
        mobile = username ?? "";
        fullName = (name != null && name.trim().isNotEmpty)
            ? name
            : (username ?? "Customer");
      });
    }
  }

  // FIX: announces only that a dialog box has opened (not its full content —
  // TalkBack would otherwise speak the whole message before the user can
  // even swipe). The actual accessibility-focus move onto the title happens
  // via the `focused: true` flag set in _triggerInAppLogoutDialog /
  // _triggerDeleteAccountDialog below.
  void _announceDialogOpened() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.announce("Dialog box opened.", TextDirection.ltr);
    });
  }

  void _triggerInAppLogoutDialog() {
    setState(() {
      _isLogoutDialogVisible = true;
      _logoutTitleFocused = true;
    });
    _announceDialogOpened();
  }

  void _triggerDeleteAccountDialog() {
    setState(() {
      _isDeleteDialogVisible = true;
      _deleteTitleFocused = true;
    });
    _announceDialogOpened();
  }

  void _cancelLogout() {
    setState(() {
      _isLogoutDialogVisible = false;
      _logoutTitleFocused = false;
    });
  }

  void _cancelDelete() {
    setState(() {
      _isDeleteDialogVisible = false;
      _deleteTitleFocused = false;
    });
  }

  Future<void> _confirmLogout() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
      (route) => false,
    );
  }

  Future<void> _performAccountDeletion() async {
    setState(() {
      _isDeletingAccount = true;
    });

    try {
      final response = await http.delete(
        Uri.parse('https://suvarnagold-16e5.vercel.app/api/customers/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': mobile}),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 🚨 THE FIX: Use clearAllData() instead of clearSession()
        // to ensure the cache is completely emptied for this device.
        await SessionManager.clearAllData();

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _isDeletingAccount = false;
          _isDeleteDialogVisible = false;
          _deleteTitleFocused = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to delete account. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeletingAccount = false;
        _isDeleteDialogVisible = false;
        _deleteTitleFocused = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network error. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    if (mobile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_isLogoutDialogVisible) {
          setState(() => _isLogoutDialogVisible = false);
          return;
        }
        if (_isDeleteDialogVisible) {
          setState(() => _isDeleteDialogVisible = false);
          return;
        }

        if (widget.onNavigate != null) {
          widget.onNavigate!(0);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background
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

            // Main content
            // FIX (Issue 3): Hide the page content from the accessibility
            // tree while a dialog is open so screen readers can't navigate
            // "behind" the dialog into background controls.
            ExcludeSemantics(
              excluding: _isLogoutDialogVisible || _isDeleteDialogVisible,
              child: SafeArea(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Image.asset(
                          "assets/images/suvarna_logo.png",
                          height: 50,
                        ),
                        const SizedBox(height: 8),

                        // Page Title
                        // FIX (Issue 1): "My Profile" exposed as a Level 1 heading.
                        Semantics(
                          header: true,
                          headingLevel: 1,
                          label: "My Profile",
                          excludeSemantics: true,
                          child: const Text(
                            "My Profile",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // User Profile Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1E8DA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 28,
                                backgroundColor: Color(0xFFE6D7C3),
                                child: Icon(
                                  Icons.person,
                                  color: Color(0xFFB78628),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName ?? "Customer",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "+91 $mobile",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Navigation Menu Tiles
                        // NOTE: No "Notifications" tile exists in this file today.
                        // If/when it's added here, wrap it the same way as the
                        // two tiles below (Semantics: button + header, level 2).
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1E8DA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              // FIX (Issue 1 & 2): "My Coupons" exposed as a
                              // Level 2 heading AND announced as a button.
                              Semantics(
                                button: true,
                                header: true,

                                child: ProfileMenuTile(
                                  icon: Icons.card_giftcard,
                                  title: "My Coupons",
                                  subtitle: "View your earned reward coupons",
                                  onTap: () =>
                                      _push(context, const CouponsScreen()),
                                ),
                              ),

                              // FIX (Issue 1 & 2): "Contact Us" exposed as a
                              // Level 2 heading AND announced as a button.
                              Semantics(
                                button: true,
                                header: true,
                                child: ProfileMenuTile(
                                  icon: Icons.notifications,
                                  title: "Notifications",
                                  subtitle: "Scheme payment reminders",
                                  onTap: () => _push(
                                    context,
                                    const NotificationsScreen(),
                                  ),
                                ),
                              ),
                              Semantics(
                                button: true,
                                header: true,

                                child: ProfileMenuTile(
                                  icon: Icons.message,
                                  title: "Contact Us",
                                  subtitle: "Get in touch with showroom",
                                  onTap: () =>
                                      _push(context, const ContactScreen()),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Delete Account Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              minimumSize: const Size(double.infinity, 50),
                              side: BorderSide(color: Colors.red.shade200),
                              backgroundColor: Colors.red.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _triggerDeleteAccountDialog,
                            icon: Icon(
                              Icons.delete_forever,
                              color: Colors.red.shade700,
                            ),
                            label: Text(
                              "Delete Account",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Logout Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF1E8DA),
                              foregroundColor: Colors.red,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _triggerInAppLogoutDialog,
                            icon: const Icon(Icons.logout),
                            label: const Text("Logout"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Logout Dialog Overlay
            if (_isLogoutDialogVisible)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    // FIX (Issue 3): Scope this whole overlay as its own
                    // accessibility "route" so a screen reader treats it as
                    // an isolated dialog box (matching native dialog
                    // behaviour) instead of just another chunk of the page.
                    child: Semantics(
                      container: true,
                      explicitChildNodes: true,
                      scopesRoute: true,
                      namesRoute: true,
                      // label: "Logout dialog",
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F0E4),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              header: true,
                              focusable: true,
                              focused: _logoutTitleFocused,
                              label: "Logout",
                              excludeSemantics: true,
                              child: Text(
                                "Logout",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3B2A1F),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "Are you sure you want to logout?",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: const Color(0xFF6E665A),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  // Kept focusable for normal tab/swipe
                                  // traversal order; initial accessibility
                                  // focus now lands on the title above.
                                  child: Focus(
                                    focusNode: _logoutDialogFocusNode,
                                    child: OutlinedButton(
                                      onPressed: _cancelLogout,
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFF9E8E7E),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child: Text(
                                        "Cancel",
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF3B2A1F),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _confirmLogout,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade400,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Text(
                                      "Logout",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Delete Account Dialog Overlay
            if (_isDeleteDialogVisible)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  child: Center(
                    // FIX (Issue 3): Same dialog-scope treatment as the
                    // logout dialog above.
                    child: Semantics(
                      container: true,
                      explicitChildNodes: true,
                      scopesRoute: true,
                      namesRoute: true,
                      // label: "Delete Account dialog",
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.88,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Warning Icon
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.delete_forever,
                                color: Colors.red.shade600,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Semantics(
                              header: true,
                              focusable: true,
                              focused: _deleteTitleFocused,
                              label: "Delete Account",
                              excludeSemantics: true,
                              child: Text(
                                "Delete Account",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Warning message block
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "⚠️ This action cannot be undone",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Your account and all associated data will be permanently deleted. You will not be able to recover your purchase history, coupons, or profile information.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF6E665A),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Action Buttons
                            if (_isDeletingAccount)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: CircularProgressIndicator(
                                  color: Color(0xFFB78628),
                                ),
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    // Kept focusable for normal tab/swipe
                                    // traversal order; initial accessibility
                                    // focus now lands on the title above.
                                    child: Focus(
                                      focusNode: _deleteDialogFocusNode,
                                      child: OutlinedButton(
                                        onPressed: _cancelDelete,
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFF9E8E7E),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        child: Text(
                                          "Cancel",
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF3B2A1F),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _performAccountDeletion,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade600,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        elevation: 2,
                                      ),
                                      child: Text(
                                        "Delete",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
