// lib/models/chat_message.dart
class ChatMessage {
  final String conversationId; // CAMBIADO de combatId
  final String senderId;
  final String? senderUsername; // Ya es nulable, lo cual está bien
  final String message;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.conversationId, // CAMBIADO de combatId
    required this.senderId,
    this.senderUsername,
    required this.message,
    required this.timestamp,
    required this.isMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    // El JSON del socket ahora envía 'conversationId'.
    // Leemos 'conversationId' del JSON. Si por alguna razón viniera 'combatId' (ej. de datos antiguos),
    // podríamos añadir un fallback, pero para los nuevos mensajes será 'conversationId'.
    String convId = json['conversationId'] as String? ?? 
                    json['combatId'] as String? ?? // Fallback por si acaso
                    ''; // Fallback final a string vacío si ninguno está presente

    String sendId = json['senderId'] as String? ?? 'unknown_sender';
    String msgText = json['message'] as String? ?? '';

    // CORRECCIÓN: Soporta tanto 'timestamp' como 'createdAt' y asegura formato correcto
    String? tsString = json['timestamp'] as String? ?? json['createdAt'] as String?;
    DateTime ts;
    if (tsString != null && tsString.isNotEmpty) {
      try {
        ts = DateTime.parse(tsString).toLocal();
      } catch (_) {
        ts = DateTime.now();
      }
    } else {
      ts = DateTime.now();
    }

    return ChatMessage(
      conversationId: convId, // Usar el ID de conversación del JSON
      senderId: sendId,
      senderUsername: json['senderUsername'] as String?, // Se mantiene como String?
      message: msgText,
      timestamp: ts,
      isMe: sendId == currentUserId,
    );
  }
}