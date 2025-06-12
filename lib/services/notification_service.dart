// lib/services/notification_service.dart

import 'dart:convert';
import 'package:face2face_app/config/app_config.dart';
import 'package:face2face_app/screens/combat_chat_screen.dart';
import 'package:face2face_app/session.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Se define fuera de la clase para que Flutter pueda encontrarla
// cuando la app está terminada.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Aquí podrías inicializar Firebase si es necesario para tareas en background,
  // pero para la navegación simple, lo principal es que la app se despierte.
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // GlobalKey estática para poder navegar desde cualquier parte de la app
  // sin necesidad de tener el 'context' de un widget.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Inicializa todo el sistema de notificaciones.
  /// Pide permisos, obtiene el token y configura los manejadores.
  Future<void> initNotifications() async {
    // 1. Pedir permiso al usuario (necesario en iOS y Android 13+).
    await _firebaseMessaging.requestPermission();

    // 2. Obtener el token único del dispositivo.
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      print("===== TOKEN FCM DEL DISPOSITIVO =====");
      print(fcmToken);
      print("====================================");
      // 3. Enviar este token a nuestro backend para guardarlo.
      await _sendTokenToBackend(fcmToken);
    }

    // 4. Configurar los manejadores para cuando lleguen los mensajes.
    _setupMessageHandlers();
  }

  /// Configura los listeners para los diferentes estados de la app.
  void _setupMessageHandlers() {
    // ESTADO 1: App en SEGUNDO PLANO (minimizada)
    // Se activa cuando el usuario pulsa la notificación.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App abierta desde notificación en SEGUNDO PLANO. Data: ${message.data}');
      _handleNotificationNavigation(message.data);
    });

    // ESTADO 2: App TERMINADA
    // Se comprueba si la app fue abierta por una notificación.
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App abierta desde notificación con la app TERMINADA. Data: ${message.data}');
        _handleNotificationNavigation(message.data);
      }
    });

    // ESTADO 3: App en PRIMER PLANO (abierta y visible)
    // Se activa en el momento en que llega la notificación.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notificación recibida en PRIMER PLANO!');
      if (message.notification != null && navigatorKey.currentContext != null) {
        // Mostramos un SnackBar para no interrumpir al usuario.
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.notification!.title ?? 'Nueva notificación', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(message.notification!.body ?? ''),
              ],
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    // Registrar el handler para notificaciones en background/terminada.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Lógica central para decidir a qué pantalla navegar según los datos de la notificación.
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final screen = data['screen'];
    
    // CASO 1: La notificación es sobre un combate (invitación, respuesta, etc.)
    if (screen == '/combats' || screen == 'combat_management') {
      // Usamos una ruta nombrada si la tenemos, o la ruta a la pantalla principal
      // para que el usuario vea la pestaña de combates.
      navigatorKey.currentState?.pushNamed('/home'); 
    
    // CASO 2: La notificación es sobre un nuevo mensaje de chat
    } else if (screen == '/chat') {
      // Extraemos todos los datos que el backend nos envió
      final conversationId = data['conversationId'];
      final opponentId = data['opponentId'];
      final opponentName = data['opponentName'];

      // Obtenemos los datos del usuario actual desde nuestra clase Session
      final currentUserId = Session.userId;
      final currentUsername = Session.username;
      final token = Session.token;

      // Verificamos que tenemos absolutamente todo lo necesario para abrir el chat
      if (conversationId != null && opponentId != null && opponentName != null && 
          currentUserId != null && currentUsername != null && token != null) {
        
        // Usamos el navigatorKey para empujar la nueva pantalla de chat con todos sus argumentos
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => CombatChatScreen(
              conversationId: conversationId,
              userToken: token,
              currentUserId: currentUserId,
              currentUsername: currentUsername,
              opponentId: opponentId,
              opponentName: opponentName,
            ),
          ),
        );
      } else {
        print("Error: Faltan datos en la notificación para poder navegar a la pantalla de chat.");
      }
    }
  }

  /// Envía el token FCM al backend para guardarlo.
  Future<void> _sendTokenToBackend(String fcmToken) async {
    final sessionToken = Session.token;
    if (sessionToken == null) return;

    try {
      final url = Uri.parse('$API_BASE_URL/users/save-fcm-token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
        },
        body: json.encode({'fcmToken': fcmToken}),
      );

      if (response.statusCode == 200) {
        print("Token FCM guardado en el backend correctamente.");
      } else {
        print("Error al guardar el token FCM. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("Excepción al enviar el token FCM al backend: $e");
    }
  }

  // Función para refrescar el token cuando sea necesario
Future<void> refreshFcmToken() async {
  try {
    await _firebaseMessaging.deleteToken(); // Borra el token anterior
    final newToken = await _firebaseMessaging.getToken(); // Obtiene uno nuevo
    if (newToken != null) {
      await _sendTokenToBackend(newToken);
    }
  } catch (e) {
    print("Error al refrescar token FCM: $e");
  }
}
}