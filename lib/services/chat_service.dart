// lib/services/chat_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:face2face_app/config/app_config.dart'; //
import 'package:face2face_app/session.dart'; //
import '../models/chat_message.dart'; //
import '../models/chat_conversation_preview.dart'; // El nuevo modelo que acabamos de crear

class ChatService {
  IO.Socket? _socket;
  // La constante API_BASE_URL ya viene de app_config.dart
  // pero Socket.IO se conecta al servidor base, no necesariamente al prefijo /api
  // Ajusta esta URL base para Socket.IO si es diferente de tu API_BASE_URL para HTTP.
  // Por ejemplo, si tu API_BASE_URL es "http://localhost:9000/api",
  // la URL del socket sería "http://localhost:9000"
  final String SOCKET_SERVER_URL = API_BASE_URL.replaceAll('/api', ''); // Ajusta esto si es necesario


  // Streams para la UI
  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get onNewMessage => _messageController.stream;

  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onChatNotification => _notificationController.stream;

  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onOpponentTyping => _typingController.stream;

  String? _currentUserId;
  String? _currentConversationId; // Para saber a qué sala unirse/enviar mensajes

  // --- MÉTODOS HTTP ---

  Future<String> initiateChatSession(String opponentId) async {
    final token = Session.token; //
    if (token == null) {
      throw Exception('Usuario no autenticado.');
    }

    final url = Uri.parse('$API_BASE_URL/chat/conversations/initiate'); //
    print('Initiating chat session with $opponentId at $url');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'opponentId': opponentId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = json.decode(response.body);
      if (responseBody['conversationId'] != null) {
        return responseBody['conversationId'];
      } else {
        throw Exception('No se recibió conversationId del servidor.');
      }
    } else {
      print('Error al iniciar sesión de chat: ${response.statusCode} - ${response.body}');
      final errorBody = json.decode(response.body);
      throw Exception('Error al iniciar chat: ${errorBody['message'] ?? 'Error desconocido'}');
    }
  }

  Future<PaginatedConversationsResponse> getMyConversations({int page = 1, int limit = 20}) async {
    final token = Session.token; //
    if (token == null) {
      throw Exception('Usuario no autenticado.');
    }
    final url = Uri.parse('$API_BASE_URL/chat/conversations?page=$page&limit=$limit'); //
    print('Fetching conversations from: $url');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      return PaginatedConversationsResponse.fromJson(responseBody);
    } else {
      print('Error al obtener conversaciones: ${response.statusCode} - ${response.body}');
      final errorBody = json.decode(response.body);
      throw Exception('Error al obtener conversaciones: ${errorBody['message'] ?? 'Error desconocido'}');
    }
  }

  Future<PaginatedMessagesResponse> getMessageHistory(String conversationId, String currentUserId, {int page = 1, int limit = 30}) async {
    final token = Session.token; //
    if (token == null) {
      throw Exception('Usuario no autenticado.');
    }
    final url = Uri.parse('$API_BASE_URL/chat/conversations/$conversationId/messages?page=$page&limit=$limit'); //
    print('Fetching message history for $conversationId from: $url');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      // Pasamos currentUserId para que ChatMessage.fromJson pueda setear 'isMe'
      return PaginatedMessagesResponse.fromJson(responseBody, currentUserId);
    } else {
      print('Error al obtener historial de mensajes: ${response.statusCode} - ${response.body}');
      final errorBody = json.decode(response.body);
      throw Exception('Error al obtener historial: ${errorBody['message'] ?? 'Error desconocido'}');
    }
  }


  // --- MÉTODOS DE SOCKET.IO ---

  void connectAndListen(String token, String conversationId, String currentUserId) {
    _currentUserId = currentUserId;
    _currentConversationId = conversationId; // Guardamos el ID de la conversación actual

    if (_socket != null && _socket!.connected && _socket?.query == 'conversationId=$_currentConversationId') {
      print("ChatService: Ya conectado y en la sala correcta.");
      // No es necesario volver a unirse si ya está conectado a la misma sala,
      // a menos que tu lógica de backend requiera un 'join' explícito por nueva instancia de pantalla.
      // Si el socket es persistente a través de la app y solo cambia de sala, entonces sí.
      // Aquí asumimos que al llamar a connectAndListen, queremos asegurar estar en la sala correcta.
      // _joinChatRoom(); // Podrías llamar a _joinChatRoom aquí si es necesario re-unirse o confirmar.
      return;
    }

    // Desconectar si ya existe un socket para evitar múltiples conexiones
    if (_socket != null) {
        print("ChatService: Desconectando socket existente antes de reconectar.");
        _socket!.dispose();
        _socket = null;
    }
    
    print("ChatService: Conectando a $SOCKET_SERVER_URL para conversación $conversationId");
    _socket = IO.io(
        SOCKET_SERVER_URL, // URL base del servidor de Socket.IO
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            // Opcional: Podrías pasar conversationId aquí si tu auth del socket lo necesita
            // .setQuery({'conversationId': conversationId}) 
            .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      print('ChatService: Conectado al servidor de Socket.IO: ${_socket!.id}');
      _joinChatRoom(); // Unirse a la sala específica después de conectar
      _setupEventListeners();
    });

    _socket!.onDisconnect((reason) {
      print('ChatService: Desconectado del servidor de Socket.IO. Razón: $reason');
      _notificationController.add({'type': 'error', 'message': 'Desconectado del chat: $reason'});
    });

    _socket!.onConnectError((data) {
      print('ChatService: Error de conexión al Socket.IO: $data');
      _notificationController.add({'type': 'error', 'message': 'Error al conectar al chat: $data'});
    });

    _socket!.onError((data) {
      print('ChatService: Error de Socket.IO: $data');
       _notificationController.add({'type': 'error', 'message': 'Error de socket: $data'});
    });
  }

  void _setupEventListeners() {
    if (_currentUserId == null) {
      print("ChatService Error: currentUserId no está configurado para los listeners del socket.");
      return;
    }

    // Escuchar nuevos mensajes
    _socket!.on('new_message', (data) { // Evento actualizado
      print('ChatService: Nuevo mensaje recibido: $data');
      if (data is Map<String, dynamic>) {
         try {
            // Asegúrate que ChatMessage.fromJson use el currentUserId para setear 'isMe'
            final message = ChatMessage.fromJson(data, _currentUserId!); //
            _messageController.add(message);
         } catch (e) {
            print("ChatService: Error al parsear mensaje entrante: $e");
         }
      }
    });

    // Escuchar notificaciones del chat
    _socket!.on('chat_notification', (data) { // Evento actualizado
      print('ChatService: Notificación de chat recibida: $data');
      if (data is Map<String, dynamic>) {
          _notificationController.add(data);
      }
    });

    // Escuchar cuando el oponente está escribiendo
    _socket!.on('opponent_typing', (data) { // Evento actualizado
      print('ChatService: Oponente escribiendo: $data');
       if (data is Map<String, dynamic>) {
          if(data['userId'] != _currentUserId) { // No mostrar si soy yo quien escribe
            _typingController.add(data);
          }
      }
    });

    // Escuchar errores específicos del chat enviados por el servidor
    _socket!.on('chat_error', (data) { // Evento actualizado
        print('ChatService: Error de chat del servidor: $data');
        if (data is Map<String, dynamic> && data.containsKey('message')) {
             _notificationController.add({'type': 'error', 'message': data['message']});
        } else {
             _notificationController.add({'type': 'error', 'message': 'Error desconocido del servidor de chat'});
        }
    });
  }

  void _joinChatRoom() {
    if (_socket != null && _socket!.connected && _currentConversationId != null) {
      print('ChatService: Uniéndose a la sala de chat: $_currentConversationId');
      _socket!.emit('join_chat_room', {'conversationId': _currentConversationId}); // Evento actualizado
    } else {
      print('ChatService: Socket no conectado o conversationId nulo. No se puede unir a la sala.');
      _notificationController.add({'type': 'error', 'message': 'No conectado. No se pudo unir a la sala.'});
    }
  }

  void sendMessage(String messageText) {
    if (messageText.trim().isEmpty) return;
    if (_socket != null && _socket!.connected && _currentConversationId != null) {
      print('ChatService: Enviando mensaje "$messageText" a la conversación: $_currentConversationId');
      _socket!.emit('send_message', { // Evento actualizado
        'conversationId': _currentConversationId,
        'message': messageText.trim(),
      });
    } else {
      print('ChatService: Socket no conectado o conversationId nulo. No se puede enviar mensaje.');
      _notificationController.add({'type': 'error', 'message': 'No conectado. No se pudo enviar el mensaje.'});
    }
  }

  void sendTypingStatus(bool isTyping) {
    if (_socket != null && _socket!.connected && _currentConversationId != null) {
      final event = isTyping ? 'typing_started' : 'typing_stopped'; // Eventos actualizados
      _socket!.emit(event, {
        'conversationId': _currentConversationId,
        // 'isTyping' ya no es necesario como booleano si los eventos son separados
      });
    }
  }
  
  // Método para cambiar de conversación o desconectar específicamente
  void leaveCurrentChatRoomAndDisconnect() {
    if (_socket != null) {
        print("ChatService: Saliendo de la sala y desconectando socket...");
        if (_currentConversationId != null) {
            // Opcional: Emitir un evento 'leave_chat_room' si el backend lo maneja para limpieza
            // _socket!.emit('leave_chat_room', {'conversationId': _currentConversationId});
        }
        _socket!.dispose(); // Desconecta y remueve listeners
        _socket = null;
        _currentConversationId = null;
        _currentUserId = null; // Limpiar también el userId actual del servicio
    }
  }

  void dispose() { // Este dispose general puede ser llamado cuando el servicio ya no se necesite en absoluto
    print("ChatService: Disposing general del servicio, cerrando streams y socket...");
    leaveCurrentChatRoomAndDisconnect(); // Asegura que el socket se desconecte
    _messageController.close();
    _notificationController.close();
    _typingController.close();
  }
}