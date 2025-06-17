// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:face2face_app/services/chat_service.dart';
import 'package:face2face_app/models/chat_conversation_preview.dart';
import 'package:face2face_app/screens/combat_chat_screen.dart';
import 'package:face2face_app/session.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  Future<PaginatedConversationsResponse>? _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    if (mounted) {
      setState(() {
        _conversationsFuture = _chatService.getMyConversations();
      });
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return DateFormat.Hm().format(timestamp);
    } else if (messageDate == yesterday) {
      return 'Ayer';
    } else if (now.difference(timestamp).inDays < 7) {
      return DateFormat.E().format(timestamp);
    } else {
      return DateFormat.yMd().format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Imagen de fondo opacada
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/boxing_bg.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: Colors.black.withOpacity(0.72),
          ),
        ),
        Column(
          children: [
            // Título "Chats" con padding superior para no solaparse con el AppBar global
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 18, // Espacio para status bar y margen
                left: 18,
                right: 18,
                bottom: 12,
              ),
              color: Colors.black.withOpacity(0.32),
              child: Row(
                children: [
                  const Text(
                    'Chats',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: _loadConversations,
                    tooltip: 'Recargar',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Lista de chats
            Expanded(
              child: FutureBuilder<PaginatedConversationsResponse>(
                future: _conversationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.red));
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.redAccent.shade100, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar tus chats: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                              onPressed: _loadConversations,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
                            )
                          ],
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.conversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(height: 20),
                          Text(
                            'Aún no tienes conversaciones.',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Busca boxeadores para iniciar un chat.',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text('Recargar', style: TextStyle(color: Colors.white)),
                            onPressed: _loadConversations,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400.withOpacity(0.8)),
                          )
                        ],
                      ),
                    );
                  }

                  final paginatedResponse = snapshot.data!;
                  final conversations = paginatedResponse.conversations;

                  return ListView.separated(
                    padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 18),
                    itemCount: conversations.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.white12,
                      height: 0,
                      thickness: 1,
                      indent: 80,
                    ),
                    itemBuilder: (context, index) {
                      final convo = conversations[index];
                      final opponent = convo.otherParticipant;
                      // Solo cuenta como no leídos los mensajes del otro usuario
                      final bool hasUnread = (convo.unreadCount ?? 0) > 0;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (opponent != null &&
                                opponent.id.isNotEmpty &&
                                opponent.name.isNotEmpty &&
                                Session.token != null &&
                                Session.userId != null &&
                                Session.username != null) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CombatChatScreen(
                                    conversationId: convo.id,
                                    userToken: Session.token!,
                                    currentUserId: Session.userId!,
                                    currentUsername: Session.username!,
                                    opponentId: opponent.id,
                                    opponentName: opponent.name,
                                  ),
                                ),
                              );
                              _loadConversations();
                            } else {
                              String missingDataReason = "No se pudo abrir el chat. Faltan datos.";
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(missingDataReason, style: TextStyle(fontSize: 12)), duration: Duration(seconds: 3)),
                              );
                            }
                          },
                          child: Container(
                            color: Colors.grey[900]?.withOpacity(0.93),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.black,
                                      backgroundImage: (opponent?.profilePicture != null && opponent!.profilePicture!.isNotEmpty)
                                          ? NetworkImage(opponent.profilePicture!)
                                          : null,
                                      child: (opponent?.profilePicture == null || opponent!.profilePicture!.isEmpty)
                                          ? Text(
                                              (opponent?.name.isNotEmpty == true) ? opponent!.name[0].toUpperCase() : '?',
                                              style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                                            )
                                          : null,
                                    ),
                                    if (hasUnread)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.black, width: 1),
                                          ),
                                          child: Text(
                                            '${convo.unreadCount}',
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              opponent?.name ?? 'Usuario Desconocido',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (convo.lastMessage?.createdAt != null)
                                            Text(
                                              _formatTimestamp(convo.lastMessage!.createdAt),
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.55),
                                                fontSize: 13,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        convo.lastMessage?.message ?? 'No hay mensajes.',
                                        style: TextStyle(
                                          color: hasUnread
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.7),
                                          fontSize: 15,
                                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}