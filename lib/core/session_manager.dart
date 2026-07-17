import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'current_username';
  static const String _keyToken = 'token';
  static const String _keyUserId = 'user_id';
  static const String _keyLastPhone = 'last_phone';
  static const String _keyLastName = 'last_name';

  // =========================
  // TOKEN MANAGEMENT
  // =========================

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }

  // =========================
  // USER ID MANAGEMENT
  // =========================

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  // =========================
  // USER NAME MANAGEMENT
  // =========================

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastName, name);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastName);
  }

  // =========================
  // LOGIN SESSION MANAGEMENT
  // =========================

  static Future<void> saveLoginSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUsername, username);
    // Persists across logout so we know last logged-in phone
    await prefs.setString(_keyLastPhone, username);
  }
// =========================
  // FULL WIPE (ACCOUNT DELETION)
  // =========================

  // Completely clears all data saved in SharedPreferences.
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
  }

  // clearSession clears ONLY active login state
  // token + userId + lastPhone + lastName are intentionally kept
  // so MPIN login can reuse the existing token without a new API call
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Only clear the active login flags
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyUsername);

    // DO NOT remove these — MPIN login depends on them surviving logout:
    // _keyToken      → reused by all APIs after MPIN login
    // _keyUserId     → reused for payment and scheme calls
    // _keyLastPhone  → shown on AuthChoiceScreen welcome back card
    // _keyLastName   → shown on AuthChoiceScreen welcome back card
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // Returns phone of last logged-in user — survives logout
  static Future<String?> getLastPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastPhone);
  }

  // True if someone has logged in before on this device
  static Future<bool> hasPreviousSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastPhone) != null;
  }

  // =========================
  // MPIN MANAGEMENT (PER USER)
  // =========================

  static Future<void> saveMpin(String username, String mpin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mpin_$username', mpin);
  }

  static Future<String?> getMpin(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('mpin_$username');
  }

  static Future<void> clearUserMpin(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mpin_$username');
  }
}