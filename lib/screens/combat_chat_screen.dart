// lib/screens/combat_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:face2face_app/services/chat_service.dart'; //
import 'package:face2face_app/models/chat_message.dart'; //
import 'package:face2face_app/models/chat_conversation_preview.dart'; // Para PaginatedMessagesResponse
import 'dart:async';

class CombatChatScreen extends StatefulWidget {
  // Parámetros actualizados
  final String conversationId; // Anteriormente podría haber sido 'combatId'
  final String userToken;
  final String currentUserId;
  final String currentUsername;
  final String opponentId;
  final String opponentName;

  const CombatChatScreen({
    super.key,
    required this.conversationId,
    required this.userToken,
    required this.currentUserId,
    required this.currentUsername,
    required this.opponentId,
    required this.opponentName,
  });

  @override
  State<CombatChatScreen> createState() => _CombatChatScreenState();
}

class _CombatChatScreenState extends State<CombatChatScreen> {
  final ChatService _chatService = ChatService(); //
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = []; //
  
  bool _isLoadingHistory = true;
  bool _opponentIsTyping = false;
  // opponentUsername se obtiene de widget.opponentName
  // String _opponentUsername = "Oponente"; // Ya no es necesario, usamos widget.opponentName

  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _messageController.addListener(_handleTyping);
  }

  Future<void> _initializeChat() async {
    // 1. Conectar y escuchar eventos de socket
    _chatService.connectAndListen(
      widget.userToken,
      widget.conversationId, // Usar el nuevo conversationId
      widget.currentUserId,
    );

    // 2. Suscribirse a los streams del servicio
    _chatService.onNewMessage.listen(_handleNewMessage);
    _chatService.onChatNotification.listen(_handleChatNotification);
    _chatService.onOpponentTyping.listen(_handleOpponentTyping);

    // 3. Cargar historial de mensajes
    await _loadMessageHistory();
  }

  Future<void> _loadMessageHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true;
    });
    try {
      final PaginatedMessagesResponse historyResponse = await _chatService.getMessageHistory(widget.conversationId, widget.currentUserId);
      if (mounted) {
        setState(() {
          _messages.clear(); // Limpiar mensajes existentes antes de cargar el historial
          _messages.addAll(historyResponse.messages);
          _isLoadingHistory = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: false));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: ${e.toString()}')),
        );
      }
    }
  }

  void _handleNewMessage(ChatMessage message) {
    if (mounted && message.conversationId == widget.conversationId) { // Asegurarse que el mensaje es de esta conversación
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    }
  }

  void _handleChatNotification(Map<String, dynamic> notification) {
     if (mounted) {
        final message = notification['message'] ?? 'Notificación desconocida';
        final type = notification['type'] ?? 'info';
        // Solo mostrar SnackBar si la notificación es relevante para esta conversación
        // o si es un error general de conexión.
        if (notification['conversationId'] == widget.conversationId || type == 'error') {
            Color backgroundColor = Colors.blueGrey;
            if (type == 'error') backgroundColor = Colors.redAccent;
            if (type == 'success') backgroundColor = Colors.green;

            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(message),
                backgroundColor: backgroundColor,
            ),
            );
        }
        // Ya no necesitamos actualizar _opponentUsername desde aquí, se pasa por widget.opponentName
      }
  }

  void _handleOpponentTyping(Map<String, dynamic> typingData) {
    if (mounted && typingData['conversationId'] == widget.conversationId) {
        if (typingData['userId'] != widget.currentUserId) { // Solo reaccionar si es el oponente
          setState(() {
            _opponentIsTyping = typingData['isTyping'] ?? false;
            // Ya no actualizamos _opponentUsername aquí, se usa widget.opponentName
          });
        }
      }
  }


  void _handleTyping() {
    if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();
    _chatService.sendTypingStatus(true); // El servicio ya conoce conversationId

    _typingTimer = Timer(const Duration(seconds: 2), () {
      _chatService.sendTypingStatus(false);
    });
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      _chatService.sendMessage(_messageController.text); // El servicio ya conoce conversationId
      
      // Optimistic UI update (opcional, pero mejora la UX)
      // final optimisticMessage = ChatMessage(
      //   conversationId: widget.conversationId,
      //   senderId: widget.currentUserId,
      //   senderUsername: widget.currentUsername,
      //   message: _messageController.text,
      //   timestamp: DateTime.now(),
      //   isMe: true,
      // );
      // setState(() {
      //   _messages.add(optimisticMessage);
      // });
      // _scrollToBottom();

      _messageController.clear();
      if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();
      _chatService.sendTypingStatus(false);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (animated) {
        _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        );
    } else {
        _scrollController.jumpTo(maxScroll);
    }
  }

  @override
  void dispose() {
    print("CombatChatScreen: Dispose anomenat per conversationId ${widget.conversationId}");
    _chatService.sendTypingStatus(false); // Notificar que ya no está escribiendo
    _typingTimer?.cancel();
    _messageController.removeListener(_handleTyping);
    _messageController.dispose();
    _scrollController.dispose();
    // Importante: Desconectar o indicar al servicio que ya no estamos en esta sala/conversación
    _chatService.leaveCurrentChatRoomAndDisconnect(); 
    // Si ChatService es un singleton o se reutiliza, no llames a _chatService.dispose() aquí,
    // sino un método que limpie la conexión/listeners para ESTA conversación específica.
    // He añadido leaveCurrentChatRoomAndDisconnect() al ChatService.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.opponentName), // Usar el nombre del oponente pasado como parámetro
            if (_opponentIsTyping)
              const Text(
                'Escribiendo...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator(color: Colors.red))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Inicia la conversación con ${widget.opponentName}.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        )
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
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

  Widget _buildMessageBubble(ChatMessage message) { //
    bool isMe = message.isMe; // Asume que ChatMessage tiene esta propiedad
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.red.shade700 : Colors.grey[800],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4), // Estilo WhatsApp
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16), // Estilo WhatsApp
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Para que la burbuja se ajuste al contenido
          children: [
            // No mostramos el nombre del remitente si es un chat 1 a 1, es implícito.
            // Si fuera grupal, sí se mostraría el message.senderUsername para los mensajes de otros.
            // if (!isMe)
            //   Padding(
            //     padding: const EdgeInsets.only(bottom: 4.0),
            //     child: Text(
            //       message.senderUsername ?? widget.opponentName, // Fallback al nombre del oponente
            //       style: TextStyle(
            //         fontWeight: FontWeight.bold,
            //         fontSize: 12,
            //         color: isMe ? Colors.white.withOpacity(0.9) : Colors.red.shade200,
            //       ),
            //     ),
            //   ),
            Text(
              message.message, //
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 5),
            Text(
              // Formatear la hora de forma más legible
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}', //
              style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        // border: Border(top: BorderSide(color: Colors.grey[700]!))
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5, // Permitir varias líneas
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.red,
            borderRadius: BorderRadius.circular(25),
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: _sendMessage,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(Icons.send, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}