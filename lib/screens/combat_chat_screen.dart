import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import 'dart:async';

class CombatChatScreen extends StatefulWidget {
  final String combatId;
  final String userToken;
  final String currentUserId;
  final String currentUsername;

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
  String _opponentUsername = "Oponente";

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

        if (message.contains("se ha unido") && notification.containsKey('username')) {
          _opponentUsername = notification['username'];
        }
      }
    });

    _chatService.typingStream.listen((typingData) {
      if (mounted) {
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
    _chatService.sendTypingStatus(widget.combatId, true);

    _typingTimer = Timer(const Duration(seconds: 2), () {
      _chatService.sendTypingStatus(widget.combatId, false);
    });
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      _chatService.sendMessage(widget.combatId, _messageController.text);
      _messageController.clear();
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
    _chatService.sendTypingStatus(widget.combatId, false);
    _typingTimer?.cancel();
    _messageController.removeListener(_handleTyping);
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_opponentUsername),
            if (_opponentIsTyping)
              const Text(
                'Escribiendo...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        backgroundColor: Colors.red,
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
          color: isMe ? Colors.blueAccent : Colors.grey[800],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: isMe ? Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isMe ? 'Tú' : (message.senderUsername ?? 'Oponente'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.message,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 10, color: Colors.white54),
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
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.red,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}