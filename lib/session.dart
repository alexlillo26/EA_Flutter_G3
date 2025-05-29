// lib/session.dart
class Session {
  static String? token;
  static String? refreshToken;
  static String? userId;    // Para ID de boxeador/usuario
  static String? username;  // Para nombre de usuario o nombre de gimnasio
  static String? gymId;     // Para ID de gimnasio
  // static String? accountType; // Puedes añadirlo si quieres guardar el tipo explícitamente

  static void clear() {
    token = null;
    refreshToken = null;
    userId = null;
    username = null;
    gymId = null;
    // accountType = null;
  }
}