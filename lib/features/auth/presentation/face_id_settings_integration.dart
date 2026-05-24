import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/session_manager.dart';
import 'face_id_settings_screen.dart';

/// 
/// FACE ID SETTINGS INTEGRATION GUIDE
/// 
/// This file shows how to add Face ID Settings to your Profile/Settings screen.
/// 
/// Add this ListTile to your profile screen's settings list:
/// 
/// Example usage in Profile Screen:
/// ```
/// ListTile(
///   leading: const Icon(Icons.face),
///   title: Text("Face ID"),
///   subtitle: Text("Manage Face ID settings"),
///   trailing: const Icon(Icons.arrow_forward),
///   onTap: () {
///     Navigator.push(
///       context,
///       MaterialPageRoute(
///         builder: (_) => FaceIdSettingsScreen(
///           username: _currentUsername, // Get from SessionManager
///         ),
///       ),
///     );
///   },
/// )
/// ```
///

class FaceIdSettingsIntegration {
  /// Get the Face ID Settings List Tile to add to your Profile/Settings Screen
  static Widget getFaceIdSettingsTile({
    required BuildContext context,
    required String username,
  }) {
    return FutureBuilder<bool>(
      future: SessionManager.isFaceIdEnabled(username),
      builder: (context, snapshot) {
        final isFaceIdEnabled = snapshot.data ?? false;

        return ListTile(
          leading: const Icon(
            Icons.face,
            color: Color(0xFFB48A2C),
            size: 24,
          ),
          title: Text(
            "Face ID",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3B2A1F),
            ),
          ),
          subtitle: Text(
            isFaceIdEnabled ? "Enabled" : "Disabled",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isFaceIdEnabled
                  ? Colors.green
                  : const Color(0xFFA79E91),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFaceIdEnabled ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFFB48A2C),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FaceIdSettingsScreen(
                  username: username,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Example: How to add this to your Profile Screen
/// 
/// In your profile_screen.dart:
/// 
/// ```dart
/// Column(
///   children: [
///     // ... other settings tiles ...
///     
///     const Divider(),
///     
///     Text(
///       "Security",
///       style: GoogleFonts.poppins(
///         fontSize: 12,
///         fontWeight: FontWeight.w600,
///         color: const Color(0xFFB48A2C),
///       ),
///     ),
///     const SizedBox(height: 12),
///     
///     // Add Face ID Settings Tile
///     FaceIdSettingsIntegration.getFaceIdSettingsTile(
///       context: context,
///       username: widget.username,
///     ),
///     
///     ListTile(
///       leading: const Icon(Icons.lock),
///       title: Text("Change MPIN"),
///       trailing: const Icon(Icons.arrow_forward_ios),
///       onTap: () {
///         // Navigate to change MPIN screen
///       },
///     ),
///     
///     // ... more settings ...
///   ],
/// )
/// ```
