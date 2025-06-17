import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import '../session.dart';
import 'package:face2face_app/config/app_config.dart'; // <-- Añade esto

final backendUrl = API_BASE_URL.replaceAll('/api', ''); // <-- Cambia aquí
const clientIdWeb = '604478234012-b81frmvc1b411j3kaj4luv25oblg6l6t.apps.googleusercontent.com';

final googleSignIn = GoogleSignIn(
  clientId: clientIdWeb,
  scopes: ['email', 'profile'],
);

Future<void> signInWithGoogleWeb({required bool isGym, bool isRegister = false}) async {
  try {
    GoogleSignInAccount? account = googleSignIn.currentUser;
    if (account == null) {
      account = await googleSignIn.signIn();
    }
    if (account == null) throw Exception("Inicio de sesión de Google cancelado.");

    final auth = await account.authentication;
    final String? accessToken = auth.accessToken;
    final String? idToken = auth.idToken;

    if (accessToken == null && idToken == null) {
      throw Exception("No se obtuvo accessToken ni idToken.");
    }

    // Usa accessToken si tu backend lo espera, si no, usa idToken.
    final tokenToSend = accessToken ?? idToken;
    if (tokenToSend == null) throw Exception("No hay token válido para enviar al backend.");

    final endpoint = isRegister
        ? (isGym
            ? '$backendUrl/api/auth/google/register-gym'
            : '$backendUrl/api/auth/google/register')
        : (isGym
            ? '$backendUrl/api/auth/google/flutter-login-gym'
            : '$backendUrl/api/auth/google/flutter-login');

    final res = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'accessToken': tokenToSend}),
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);

      // --- NUEVO: Decodifica el JWT si es necesario para userId y username ---
      String? userId;
      String? username;
      // Intenta obtener del backend primero
      userId = data['user']?['_id'] ?? data['gym']?['_id'];
      username = data['user']?['name'] ?? data['gym']?['name'];
      // Si no viene, decodifica el JWT
      if (userId == null || username == null) {
        try {
          final parts = data['token'].split('.');
          if (parts.length == 3) {
            final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
            final payloadMap = json.decode(payload);
            userId ??= payloadMap['id'] as String?;
            username ??= payloadMap['username'] as String? ?? payloadMap['name'] as String?;
          }
        } catch (e) {
          print("ERROR: Could not decode token to get user data: $e");
        }
      }
      // --- FIN DECODIFICACIÓN ---

      // Establece la sesión global
      await Session.setSession(
        newToken: data['token'],
        newRefreshToken: data['refreshToken'],
        newUserId: userId,
        newUsername: username,
        newGymId: data['gym']?['_id'], // Si aplica para gym
      );

      print("✅ Usuario autenticado y tokens del backend almacenados en Session.");
      print("JWT *ALMACENADO* en Session: ${Session.token}");
      print("Refresh Token *ALMACENADO* en Session: ${Session.refreshToken}");
      print("UserID *ALMACENADO* en Session: ${Session.userId}");
      print("Username *ALMACENADO* en Session: ${Session.username}");
    } else {
      throw Exception("Error del backend: ${res.body}");
    }
  } catch (e) {
    print("❌ Error en signInWithGoogleWeb: $e");
    rethrow;
  }
}

Future<void> logout() async {
  await googleSignIn.signOut();
  Session.clearSession();
}
