import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static String? token;
  static String? refreshToken;
  static String? userId;
  static String? username;
  static String? gymId;

  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    refreshToken = prefs.getString('refreshToken');
    userId = prefs.getString('userId');
    username = prefs.getString('username');
    gymId = prefs.getString('gymId');
  }

  static Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) await prefs.setString('token', token!);
    if (refreshToken != null) await prefs.setString('refreshToken', refreshToken!);
    if (userId != null) await prefs.setString('userId', userId!);
    if (username != null) await prefs.setString('username', username!);
    if (gymId != null) await prefs.setString('gymId', gymId!);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('username');
    await prefs.remove('gymId');
    token = null;
    refreshToken = null;
    userId = null;
    username = null;
    gymId = null;
  }

  static Future<void> setSession({
    required String? newToken,
    String? newRefreshToken,
    String? newUserId,
    String? newUsername,
    String? newGymId,
  }) async {
    token = newToken;
    refreshToken = newRefreshToken;
    userId = newUserId;
    username = newUsername;
    gymId = newGymId;
    await saveSession();
  }

  static bool get isAuthenticated => token != null && userId != null && token!.isNotEmpty && userId!.isNotEmpty;
}