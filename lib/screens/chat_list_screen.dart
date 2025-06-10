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
      print("ChatListScreen: Cargando conversaciones...");
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Chats'),
        backgroundColor: Colors.red.shade800,
        elevation: 1,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage("assets/images/boxing_bg.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.88), BlendMode.darken),
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            _loadConversations();
          },
          color: Colors.red,
          backgroundColor: Colors.grey[900],
          child: FutureBuilder<PaginatedConversationsResponse>(
            future: _conversationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print("ChatListScreen: FutureBuilder esperando...");
                return const Center(child: CircularProgressIndicator(color: Colors.red));
              } else if (snapshot.hasError) {
                print("ChatListScreen: FutureBuilder con error: ${snapshot.error}");
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
                print("ChatListScreen: FutureBuilder sin datos o conversaciones vacías.");
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
              print("ChatListScreen: FutureBuilder con datos. Número de conversaciones: ${conversations.length}");

              return ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.grey[800],
                  height: 0.5,
                  indent: 82, // Ajustado para el avatar + padding
                ),
                itemBuilder: (context, index) {
                  final convo = conversations[index];
                  final opponent = convo.otherParticipant;

                  // --- LOGS DE DIAGNÓSTICO POR ITEM ---
                  print("ChatListScreen ITEM[$index] - Convo ID: ${convo.id}");
                  if (opponent != null) {
                    print("ChatListScreen ITEM[$index] - Opponent: ID=${opponent.id}, Name='${opponent.name}', Pic='${opponent.profilePicture}'");
                  } else {
                    print("ChatListScreen ITEM[$index] - Opponent: NULL");
                  }
                  // --- FIN LOGS DE DIAGNÓSTICO ---

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // --- LOGS DE DIAGNÓSTICO EN TAP ---
                        print("ChatListScreen TAPPED - Convo ID: ${convo.id}");
                        print("ChatListScreen TAPPED - Opponent: ID=${opponent?.id}, Name='${opponent?.name}'");
                        print("ChatListScreen TAPPED - Session: tokenIsPresent=${Session.token != null}, userId=${Session.userId}, username=${Session.username}");
                        // --- FIN LOGS DE DIAGNÓSTICO ---

                        // Condición de navegación más robusta
                        if (opponent != null &&
                            opponent.id.isNotEmpty && // Asegurar que el ID del oponente no esté vacío
                            opponent.name.isNotEmpty && // Asegurar que el nombre del oponente no esté vacío
                            Session.token != null &&
                            Session.userId != null &&
                            Session.username != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CombatChatScreen(
                                conversationId: convo.id,
                                userToken: Session.token!,
                                currentUserId: Session.userId!,
                                currentUsername: Session.username!,
                                opponentId: opponent.id,
                                opponentName: opponent.name, // Pasamos el nombre que tenemos
                              ),
                            ),
                          ).then((_) {
                            _loadConversations();
                          });
                        } else {
                          String missingDataReason = "No se pudo abrir el chat. Faltan datos: ";
                          if (opponent == null) {
                            missingDataReason += "Info del oponente no recibida. ";
                          } else {
                            if (opponent.id.isEmpty) missingDataReason += "ID del oponente vacío. ";
                            if (opponent.name.isEmpty) missingDataReason += "Nombre del oponente vacío. ";
                          }
                          if (Session.token == null) missingDataReason += "Token de sesión nulo. ";
                          if (Session.userId == null) missingDataReason += "ID de usuario de sesión nulo. ";
                          if (Session.username == null) missingDataReason += "Nombre de usuario de sesión nulo. ";
                          
                          print("ChatListScreen - NAVIGATE FAILED: $missingDataReason");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(missingDataReason, style: TextStyle(fontSize: 12)), duration: Duration(seconds: 3)),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0), // Aumentado padding vertical
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30, // Ligeramente más grande
                              backgroundColor: Colors.red.shade400,
                              backgroundImage: (opponent?.profilePicture != null && opponent!.profilePicture!.isNotEmpty)
                                  ? NetworkImage(opponent.profilePicture!)
                                  : null,
                              child: (opponent?.profilePicture == null || opponent!.profilePicture!.isEmpty)
                                  ? Text(
                                      // Usar el nombre del oponente para la inicial, o '?' si el oponente o su nombre es null/vacío
                                      (opponent?.name.isNotEmpty == true) ? opponent!.name[0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16), // Más espacio
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    // Usar el nombre del oponente, o "Usuario Desconocido" como fallback
                                    opponent?.name ?? 'Usuario Desconocido',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17.5, // Un poco más grande
                                      fontWeight: FontWeight.w500, // Ligeramente menos bold que antes
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    convo.lastMessage?.message ?? 'No hay mensajes.',
                                    style: TextStyle(
                                      color: convo.lastMessage != null ? Colors.white.withOpacity(0.75) : Colors.white.withOpacity(0.5),
                                      fontSize: 14.5,
                                      // fontWeight: convo.unreadCount > 0 ? FontWeight.bold : FontWeight.normal, // Para mensajes no leídos
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column( // Para alinear el timestamp y el contador de no leídos (futuro)
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  convo.lastMessage != null
                                      ? _formatTimestamp(convo.lastMessage!.createdAt)
                                      : _formatTimestamp(convo.updatedAt),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.65),
                                    fontSize: 12.5,
                                  ),
                                ),
                                // SizedBox(height: 4), // Espacio para el contador de no leídos
                                // if (convo.unreadCount > 0)
                                //   Container(
                                //     padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                //     decoration: BoxDecoration(
                                //       color: Colors.red.shade600,
                                //       borderRadius: BorderRadius.circular(10)
                                //     ),
                                //     child: Text(
                                //       convo.unreadCount.toString(),
                                //       style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                                //     ),
                                //   )
                              ],
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
      ),
    );
  }
}