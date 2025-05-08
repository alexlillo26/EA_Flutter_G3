// services/chat_service.dart
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_message.dart'; // Ajusta la ruta si es necesario

class ChatService {
  IO.Socket? _socket;
  // Asegúrate de que esta URL sea accesible desde tu emulador/dispositivo.
  // Para emulador Android, si el servidor corre en localhost:9000, usa 10.0.2.2:9000
  // Para web o desktop local, si el servidor corre en localhost:9000, usa localhost:9000
  // Para un servidor desplegado, usa su URL pública.
  final String _serverUrl = "http://localhost:9000"; // CAMBIA ESTO SEGÚN SEA NECESARIO (tu LOCAL_PORT)

  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageController.stream;

  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  String? _currentUserId; // Necesitarás saber el ID del usuario actual

  void connectAndListen(String token, String combatId, String currentUserId) {
    _currentUserId = currentUserId;

    if (_socket != null && _socket!.connected) {
      print("Ya conectado y escuchando. Uniéndose al chat del combate...");
      joinCombatChat(combatId); // Si ya está conectado, solo necesita unirse a la sala
      return;
    }
    
    _socket = IO.io(
        _serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket']) // Opcional: fuerza websockets
            .disableAutoConnect() // Conectar manualmente
            .setAuth({'token': token}) // AQUÍ SE ENVÍA EL TOKEN
            .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Conectado al servidor de chat: ${_socket!.id}');
      joinCombatChat(combatId); // Unirse a la sala del combate después de conectar
      _setupEventListeners();
    });

    _socket!.onDisconnect((_) {
      print('Desconectado del servidor de chat');
      _notificationController.add({'type': 'error', 'message': 'Desconectado del chat'});
    });

    _socket!.onConnectError((data) {
      print('Error de conexión al chat: $data');
      _notificationController.add({'type': 'error', 'message': 'Error al conectar al chat: $data'});
    });

    _socket!.onError((data) {
      print('Error de socket: $data');
       _notificationController.add({'type': 'error', 'message': 'Error de socket: $data'});
    });
  }

  void _setupEventListeners() {
    if (_currentUserId == null) {
      print("Error: currentUserId no está configurado para los listeners.");
      return;
    }
    // Escuchar mensajes entrantes
    _socket!.on('receive_combat_message', (data) {
      print('Mensaje recibido: $data');
      if (data is Map<String, dynamic>) {
         try {
            final message = ChatMessage.fromJson(data, _currentUserId!);
            _messageController.add(message);
         } catch (e) {
            print("Error al parsear mensaje: $e");
         }
      }
    });

    // Escuchar notificaciones del chat
    _socket!.on('combat_chat_notification', (data) {
      print('Notificación de chat: $data');
      if (data is Map<String, dynamic>) {
          _notificationController.add(data);
      }
    });

    // Escuchar cuando el oponente está escribiendo
    _socket!.on('opponent_typing', (data) {
      print('Oponente escribiendo: $data');
       if (data is Map<String, dynamic>) {
          // Solo mostrar si no es el usuario actual quien escribe
          if(data['userId'] != _currentUserId) {
            _typingController.add(data);
          }
      }
    });

    // Escuchar errores específicos del chat del servidor
    _socket!.on('combat_chat_error', (data) {
        print('Error de chat del servidor: $data');
        if (data is Map<String, dynamic> && data.containsKey('message')) {
             _notificationController.add({'type': 'error', 'message': data['message']});
        } else {
             _notificationController.add({'type': 'error', 'message': 'Error desconocido del chat'});
        }
    });
  }

  void joinCombatChat(String combatId) {
    if (_socket != null && _socket!.connected) {
      print('Uniéndose al chat del combate: $combatId');
      _socket!.emit('join_combat_chat', {'combatId': combatId});
    } else {
      print('Socket no conectado. No se puede unir al chat.');
    }
  }

  void sendMessage(String combatId, String message) {
    if (message.trim().isEmpty) return;
    if (_socket != null && _socket!.connected) {
      print('Enviando mensaje: $message al combate: $combatId');
      _socket!.emit('send_combat_message', {
        'combatId': combatId,
        'message': message,
      });
    } else {
      print('Socket no conectado. No se puede enviar mensaje.');
      _notificationController.add({'type': 'error', 'message': 'No conectado. No se pudo enviar el mensaje.'});
    }
  }

  void sendTypingStatus(String combatId, bool isTyping) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing_in_combat', {
        'combatId': combatId,
        'isTyping': isTyping,
      });
    }
  }

  void dispose() {
    print("Disposing ChatService, disconnecting socket...");
    _socket?.dispose(); // Esto debería desconectar y remover listeners.
    _messageController.close();
    _notificationController.close();
    _typingController.close();
  }
}