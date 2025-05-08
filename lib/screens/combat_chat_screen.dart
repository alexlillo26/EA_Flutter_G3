// screens/combat_chat_screen.dart
import 'package:flutter/material.dart';
import '../services/chat_service.dart'; // Ajusta la ruta
import '../models/chat_message.dart'; // Ajusta la ruta
import 'dart:async'; // Para Timer

class CombatChatScreen extends StatefulWidget {
  final String combatId;
  final String userToken; // Debes obtener esto de tu sistema de autenticación
  final String currentUserId; // Y esto también
  final String currentUsername; // Opcional, para mostrar tu nombre de usuario

  const CombatChatScreen({
    Key? key,
    required this.combatId,
    required this.userToken,
    required this.currentUserId,
    required this.currentUsername,
  }) : super(key: key);

  @override
  State<CombatChatScreen> createState() => _CombatChatScreenState();
}

class _CombatChatScreenState extends State<CombatChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _opponentIsTyping = false;
  String _opponentUsername = "Oponente"; // Placeholder

  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _chatService.connectAndListen(
      widget.userToken,
      widget.combatId,
      widget.currentUserId,
    );

    _chatService.messageStream.listen((message) {
      if (mounted) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
    });

    _chatService.notificationStream.listen((notification) {
      if (mounted) {
        // Mostrar SnackBar o algún tipo de alerta
        final message = notification['message'] ?? 'Notificación desconocida';
        final type = notification['type'] ?? 'info';
        Color backgroundColor = Colors.blue;
        if (type == 'error') backgroundColor = Colors.red;
        if (type == 'success') backgroundColor = Colors.green;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
          ),
        );
        // Si la notificación es sobre alguien uniéndose y tiene nombre de usuario
        if (message.contains("se ha unido") && notification.containsKey('username')) {
             _opponentUsername = notification['username']; // Actualiza si es necesario
        }
      }
    });

    _chatService.typingStream.listen((typingData) {
      if (mounted) {
        // Asegurarse que no es el propio usuario
        if (typingData['userId'] != widget.currentUserId) {
          setState(() {
            _opponentIsTyping = typingData['isTyping'] ?? false;
            if (typingData.containsKey('username') && typingData['username'] != null) {
                _opponentUsername = typingData['username'];
            }
          });
        }
      }
    });

    _messageController.addListener(_handleTyping);
  }

  void _handleTyping() {
    if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();
    _chatService.sendTypingStatus(widget.combatId, true); // Informar que está escribiendo

    _typingTimer = Timer(const Duration(seconds: 2), () {
      _chatService.sendTypingStatus(widget.combatId, false); // Dejó de escribir después de un tiempo
    });
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      _chatService.sendMessage(widget.combatId, _messageController.text);
      // Opcional: Añadir localmente de inmediato para una UI más rápida
      // Aunque es mejor esperar la confirmación del servidor (receive_combat_message)
      // para asegurar que el mensaje se envió y tiene timestamp del servidor.
      _messageController.clear();
      // Si enviaste un mensaje, ya no estás escribiendo.
      if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();
      _chatService.sendTypingStatus(widget.combatId, false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _chatService.sendTypingStatus(widget.combatId, false); // Asegurar que se envía false al salir
    _typingTimer?.cancel();
    _messageController.removeListener(_handleTyping);
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.dispose(); // MUY IMPORTANTE desconectar el socket
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat del Combate ${widget.combatId.substring(0,6)}...'), // Acortar ID si es largo
            if (_opponentIsTyping)
              Text(
                '$_opponentUsername está escribiendo...',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    bool isMe = message.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColorLight : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isMe ? widget.currentUsername : (message.senderUsername ?? 'Oponente'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isMe ? Colors.black54 : Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(message.message, style: TextStyle(color: isMe ? Colors.black87 : Colors.black)),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 10, color: isMe ? Colors.black54 : Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}