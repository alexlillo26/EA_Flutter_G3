// lib/models/chat_conversation_preview.dart
import 'package:face2face_app/models/chat_message.dart'; // Asumiendo que ChatMessage tiene un factory fromJson para lastMessage

class OtherParticipant {
  final String id;
  final String name;
  final String? profilePicture;

  OtherParticipant({
    required this.id,
    required this.name,
    this.profilePicture,
  });

  factory OtherParticipant.fromJson(Map<String, dynamic> json) {
    return OtherParticipant(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Usuario Desconocido',
      profilePicture: json['profilePicture'],
    );
  }
}

class LastMessagePreview {
  final String id;
  final String message;
  final String senderId;
  final String senderUsername;
  final DateTime createdAt;

  LastMessagePreview({
    required this.id,
    required this.message,
    required this.senderId,
    required this.senderUsername,
    required this.createdAt,
  });

  factory LastMessagePreview.fromJson(Map<String, dynamic> json) {
    return LastMessagePreview(
      id: json['_id'] ?? '',
      message: json['message'] ?? '',
      senderId: json['senderId'] ?? '',
      senderUsername: json['senderUsername'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ChatConversationPreview {
  final String id; // Conversation ID
  final OtherParticipant? otherParticipant;
  final LastMessagePreview? lastMessage;
  final DateTime updatedAt;
  final int unreadCount;

  ChatConversationPreview({
    required this.id,
    this.otherParticipant,
    this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  factory ChatConversationPreview.fromJson(Map<String, dynamic> json) {
    return ChatConversationPreview(
      id: json['_id'] ?? '',
      otherParticipant: json['otherParticipant'] != null
          ? OtherParticipant.fromJson(json['otherParticipant'])
          : null,
      lastMessage: json['lastMessage'] != null
          ? LastMessagePreview.fromJson(json['lastMessage'])
          : null,
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

// Modelo para la respuesta paginada de getMyConversations
class PaginatedConversationsResponse {
  final List<ChatConversationPreview> conversations;
  final int totalConversations;
  final int totalPages;
  final int currentPage;

  PaginatedConversationsResponse({
    required this.conversations,
    required this.totalConversations,
    required this.totalPages,
    required this.currentPage,
  });

  factory PaginatedConversationsResponse.fromJson(Map<String, dynamic> json) {
    var conversationsList = json['conversations'] as List? ?? [];
    List<ChatConversationPreview> conversations = conversationsList
        .map((i) => ChatConversationPreview.fromJson(i))
        .toList();

    return PaginatedConversationsResponse(
      conversations: conversations,
      totalConversations: json['totalConversations'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
    );
  }
}

// Modelo para la respuesta paginada de getMessageHistory
// Asumiendo que tu ChatMessage (lib/models/chat_message.dart) ya tiene un factory fromJson
class PaginatedMessagesResponse {
  final List<ChatMessage> messages;
  final int totalMessages;
  final int totalPages;
  final int currentPage;

  PaginatedMessagesResponse({
    required this.messages,
    required this.totalMessages,
    required this.totalPages,
    required this.currentPage,
  });

  factory PaginatedMessagesResponse.fromJson(Map<String, dynamic> json, String currentUserId) {
    var messagesList = json['messages'] as List? ?? [];
    // Usamos el factory de tu ChatMessage existente, pasándole el currentUserId
    List<ChatMessage> messages = messagesList
        .map((i) => ChatMessage.fromJson(i, currentUserId))
        .toList();

    return PaginatedMessagesResponse(
      messages: messages,
      totalMessages: json['totalMessages'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
    );
  }
}