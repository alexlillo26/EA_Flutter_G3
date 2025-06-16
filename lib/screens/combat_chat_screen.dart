// lib/screens/combat_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:face2face_app/services/chat_service.dart'; //
import 'package:face2face_app/models/chat_message.dart'; //
import 'package:face2face_app/models/chat_conversation_preview.dart'; // Para PaginatedMessagesResponse
import 'dart:async';
import 'package:intl/intl.dart'; // Añade esto para formatear horas

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

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    if (now.difference(timestamp).inDays == 0) {
      // Hoy: solo hora:minuto
      return DateFormat('HH:mm').format(timestamp);
    } else if (now.difference(timestamp).inDays == 1) {
      // Ayer
      return 'Ayer ${DateFormat('HH:mm').format(timestamp)}';
    } else if (now.year == timestamp.year) {
      // Este año
      return DateFormat('d MMM HH:mm', 'es').format(timestamp);
    } else {
      // Otro año
      return DateFormat('d MMM yyyy HH:mm', 'es').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.black,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.shade900,
              child: Icon(Icons.sports_mma, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.opponentName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  if (_opponentIsTyping)
                    const Text(
                      'Escribiendo...',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white70),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/boxing_bg.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.78),
          child: Column(
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
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final bool showDateHeader = index == 0 ||
                                  !_isSameDay(_messages[index - 1].timestamp, message.timestamp);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (showDateHeader)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade900.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _formatDateHeader(message.timestamp),
                                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  _buildMessageBubble(message),
                                ],
                              );
                            },
                          ),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(now, date)) return "Hoy";
    if (_isSameDay(now.subtract(const Duration(days: 1)), date)) return "Ayer";
    return DateFormat('d MMM yyyy', 'es').format(date);
  }

  Widget _buildMessageBubble(ChatMessage message) {
    bool isMe = message.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: EdgeInsets.only(
          top: 2,
          bottom: 8,
          left: isMe ? 40 : 8,
          right: isMe ? 8 : 40,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.red.shade700 : Colors.grey[850]?.withOpacity(0.92),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(6),
            bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe ? Colors.red.withOpacity(0.13) : Colors.black.withOpacity(0.13),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
          border: Border.all(
            color: isMe ? Colors.redAccent.withOpacity(0.4) : Colors.white10,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.message,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                ),
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.check, size: 13, color: Colors.white.withOpacity(0.7)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        border: const Border(top: BorderSide(color: Colors.red, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[900]?.withOpacity(0.95),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
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
                padding: EdgeInsets.all(13.0),
                child: Icon(Icons.send, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}