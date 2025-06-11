import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

Future<void> writeStorage(String key, String value) async {
  if (kIsWeb) {
    html.window.localStorage[key] = value;
  }
}

Future<String?> readStorage(String key) async {
  if (kIsWeb) {
    return html.window.localStorage[key];
  }
  return null;
}

Future<void> clearStorage(String key) async {
  if (kIsWeb) {
    html.window.localStorage.remove(key);
  }
}

class Session {
  static String? token;
  static String? refreshToken;
  static String? userId;
  static String? username;

  static void setSession({
    String? newToken,
    String? newRefreshToken,
    String? newUserId,
    String? newUsername,
  }) {
    token = newToken;
    refreshToken = newRefreshToken ?? refreshToken;
    userId = newUserId;
    username = newUsername;
    if (newToken != null) writeStorage('token', newToken); else clearStorage('token');
    if (newRefreshToken != null) writeStorage('refreshToken', newRefreshToken); else clearStorage('refreshToken');
    if (newUserId != null) writeStorage('userId', newUserId); else clearStorage('userId');
    if (newUsername != null) writeStorage('username', newUsername); else clearStorage('username');
  }

  static void clearSession() {
    token = null;
    refreshToken = null;
    userId = null;
    username = null;
    clearStorage('token');
    clearStorage('refreshToken');
    clearStorage('userId');
    clearStorage('username');
  }

  static Future<void> loadSession() async {
    token = await readStorage('token');
    refreshToken = await readStorage('refreshToken');
    userId = await readStorage('userId');
    username = await readStorage('username');
  }
}
