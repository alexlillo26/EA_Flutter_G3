// models/chat_message.dart
class ChatMessage {
  final String combatId;
  final String senderId;
  final String? senderUsername;
  final String message;
  final DateTime timestamp;
  final bool isMe; // Para UI, para saber si el mensaje es del usuario actual

  ChatMessage({
    required this.combatId,
    required this.senderId,
    this.senderUsername,
    required this.message,
    required this.timestamp,
    required this.isMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      combatId: json['combatId'],
      senderId: json['senderId'],
      senderUsername: json['senderUsername'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isMe: json['senderId'] == currentUserId,
    );
  }
}