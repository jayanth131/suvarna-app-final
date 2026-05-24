import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/session_manager.dart';
import 'auth_models.dart';

class AuthService {
  static const String baseUrl =
      "https://suvarna-jewellers-customer-backend.vercel.app/api/auth";

  /// Helper method to safely decode JSON responses
  static Map<String, dynamic> _safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (e) {
      print('JSON decode error: $e');
      print('Response body: $body');
      return {"message": "Server error - invalid response"};
    }
  }

  static Future<AuthResponse> sendSignupOtp({
    required String mobile,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": mobile}),
      ).timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse(success: true);
      }

      return AuthResponse(
        success: false,
        message: data["message"] ?? "OTP send failed",
      );
    } catch (e) {
      return AuthResponse(success: false, message: e.toString());
    }
  }

  static Future<AuthResponse> verifySignupOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": mobile, "otp": otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse(success: true);
      }

      return AuthResponse(
        success: false,
        message: data["message"] ?? "Invalid OTP",
      );
    } catch (e) {
      return AuthResponse(success: false, message: e.toString());
    }
  }

  static Future<AuthResponse> register({
    required String fullName,
    required String mobile,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": fullName,
          "phone": mobile,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final token = data["token"];
        final user = data["user"];

        if (token != null) {
          await SessionManager.saveToken(token);
          await SessionManager.saveLoginSession(mobile);

          if (user != null && user["id"] != null) {
            await SessionManager.saveUserId(user["id"].toString());
          }
        }

        final userName = user?["name"]?.toString() ?? "";
        if (userName.isNotEmpty) {
          await SessionManager.saveUserName(userName);
        }

        return AuthResponse(success: true, username: mobile);
      }

      return AuthResponse(
        success: false,
        message: data["message"] ?? "Signup failed",
      );
    } catch (e) {
      return AuthResponse(success: false, message: e.toString());
    }
  }

  static Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": identifier,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data["token"];
        final user = data["user"];

        if (token != null) {
          await SessionManager.saveToken(token);
          await SessionManager.saveLoginSession(identifier);

          if (user != null && user["id"] != null) {
            await SessionManager.saveUserId(user["id"].toString());
          }
        }

        final userName = user?["name"]?.toString() ?? "";
        if (userName.isNotEmpty) {
          await SessionManager.saveUserName(userName);
        }

        final bool mpinExists = data["mpinExists"] ?? false;

        return AuthResponse(
          success: true,
          username: identifier,
          mpinExists: mpinExists,
        );
      }

      return AuthResponse(
        success: false,
        message: data["message"] ?? "Login failed",
      );
    } catch (e) {
      return AuthResponse(success: false, message: e.toString());
    }
  }

  static Future<AuthResponse> sendForgotPasswordOtp({
    required String mobile,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": mobile,
          "purpose": "forgot_password",
        }),
      ).timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse(success: true);
      }

      return AuthResponse(
        success: false,
        message: data["message"] ?? "OTP send failed",
      );
    } catch (e) {
      return AuthResponse(success: false, message: e.toString());
    }
  }

  static Future<AuthResponse> verifyForgotPasswordOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": mobile,
          "otp": otp,
          "purpose": "forgot_password",
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["type"] == "success") {
        return AuthResponse(success: true);
      }

      return AuthResponse(
        success: false,
        message: data["message"] ?? "Invalid OTP",
      );
    } catch (e) {
      return AuthResponse(success: false, message: e.toString());
    }
  }

  static Future<AuthResponse> resetPassword({
    required String mobile,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": mobile,
          "otp": otp,
          "newPassword": newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse(success: true);
      }

      return AuthResponse(
        success: false,
        message: data["message"] ?? "Reset failed",
      );
    } catch (e) {
      return AuthResponse(success: false, message: e.toString());
    }
  }

  static Future<AuthResponse> setMpin({
    required String username,
    required String mpin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/set-mpin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": username,
          "mpin": mpin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await SessionManager.saveMpin(username, mpin);
        return AuthResponse(success: true);
      }

      return AuthResponse(
        success: false,
        message: data["message"] ?? "MPIN save failed",
      );
    } catch (e) {
      return AuthResponse(success: false, message: e.toString());
    }
  }

  static Future<AuthResponse> verifyLoginOtp({
    required String otp,
  }) async {
    return AuthResponse(success: true);
  }

  // ── FIXED: now reads token + userId from verify-mpin response ──────────
  // Previously: only checked statusCode == 200, never saved token
  // Now: saves token + userId + loginSession exactly like login() does
  // This is why MPIN login showed empty data — no token = all API calls failed
  static Future<AuthResponse> verifyMpin({
    required String username,
    required String mpin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/verify-mpin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": username,
          "mpin": mpin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save token if backend returns one (same as login flow)
        final token = data["token"];
        final user = data["user"];

        if (token != null) {
          await SessionManager.saveToken(token);
          await SessionManager.saveLoginSession(username);

          if (user != null && user["id"] != null) {
            await SessionManager.saveUserId(user["id"].toString());
          }

          // Save name in case it wasn't saved before (e.g. fresh install)
          final userName = user?["name"]?.toString() ?? "";
          if (userName.isNotEmpty) {
            await SessionManager.saveUserName(userName);
          }
        } else {
          // Backend doesn't return token from verify-mpin —
          // the existing token in SessionManager is still valid (7d expiry)
          // just refresh the login session timestamp
          await SessionManager.saveLoginSession(username);
        }

        return AuthResponse(success: true);
      }

      return AuthResponse(
        success: false,
        message: data["message"] ?? "Incorrect MPIN",
      );
    } catch (e) {
      return AuthResponse(success: false, message: e.toString());
    }
  }

  static Future<AuthResponse> sendForgotMpinOtp({
    required String mobile,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": mobile,
          "purpose": "forgot_mpin",
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse(success: true);
      }

      return AuthResponse(
        success: false,
        message: data["message"] ?? "OTP send failed",
      );
    } catch (e) {
      return AuthResponse(success: false, message: e.toString());
    }
  }

  static Future<AuthResponse> verifyForgotMpinOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": mobile,
          "otp": otp,
          "purpose": "forgot_mpin",
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse(success: true);
      }

      return AuthResponse(
        success: false,
        message: data["message"] ?? "Invalid OTP",
      );
    } catch (e) {
      return AuthResponse(success: false, message: e.toString());
    }
  }

  static Future<AuthResponse> resetMpin({
    required String mobile,
    required String mpin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/reset-mpin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": mobile,
          "mpin": mpin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await SessionManager.saveMpin(mobile, mpin);
        return AuthResponse(success: true);
      }

      return AuthResponse(
        success: false,
        message: data["message"] ?? "MPIN reset failed",
      );
    } catch (e) {
      return AuthResponse(success: false, message: e.toString());
    }
  }
}