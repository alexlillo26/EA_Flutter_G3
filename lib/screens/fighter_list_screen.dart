import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/fighter_model.dart';
import 'combat_chat_screen.dart'; // ✅ Importa la pantalla de chat
import 'create_combat_screen.dart'; // ✅ Importa la pantalla de crear combate
import 'login_screen.dart'; // ✅ Para usar Session.token
import 'package:face2face_app/config/app_config.dart';
import 'package:face2face_app/session.dart';
import 'package:face2face_app/models/fighter_model.dart';
import 'package:face2face_app/screens/combat_chat_screen.dart';
import 'package:face2face_app/screens/create_combat_screen.dart';
import 'package:face2face_app/services/chat_service.dart'; // <--- IMPORTACIÓN AÑADIDA
import 'package:face2face_app/screens/profile_screen.dart'; 
import 'package:face2face_app/screens/fighter_profile_screen.dart';


class FighterListScreen extends StatefulWidget {
  final String? selectedWeight;
  final String? city;

  const FighterListScreen({
    super.key,
    required this.selectedWeight,
    required this.city,
  });

  @override
  State<FighterListScreen> createState() => _FighterListScreenState();
}

class _FighterListScreenState extends State<FighterListScreen> {
  late Future<List<Fighter>> _fightersFuture;
  final ChatService _chatService = ChatService(); // <--- INSTANCIA DE CHATSERVICE AÑADIDA

  @override
  void initState() {
    super.initState();
    _fightersFuture = _fetchFilteredFighters();
  }

  Future<List<Fighter>> _fetchFilteredFighters() async {
    final token = Session.token; //
    if (token == null) {
      // Es buena idea manejar este caso, quizás mostrando un mensaje al usuario
      // o redirigiendo al login si la sesión es estrictamente necesaria aquí.
      // Comprobación de 'mounted' antes de usar ScaffoldMessenger si esto puede ser llamado antes de que el widget esté completamente inicializado.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de autenticación. Por favor, inicia sesión de nuevo.')),
        );
      }
      throw Exception('Usuario no autenticado');
    }

    Map<String, String> queryParams = {};

    if (widget.selectedWeight != null &&
        widget.selectedWeight!.isNotEmpty &&
        widget.selectedWeight != 'Cualquiera') { // Asumiendo que 'Cualquiera' es un valor para no filtrar por peso
      queryParams['weight'] = widget.selectedWeight!;
    }
    if (widget.city != null && widget.city!.isNotEmpty) {
      queryParams['city'] = widget.city!;
    }

    final url = Uri.parse('$API_BASE_URL/users/search').replace( //
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    // print('Buscando boxeadores con URL: $url'); // Útil para depuración

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (responseBody['success'] == true && responseBody['users'] != null) {
        final List<dynamic> usersData = responseBody['users'];
        return usersData.map((data) => Fighter.fromJson(data)).toList(); //
      } else {
        // print('Respuesta no exitosa o sin clave "users": ${response.body}');
        throw Exception(
            'Error en la respuesta del API de búsqueda: ${responseBody['message'] ?? 'Formato inesperado'}');
      }
    } else {
      // print('Error al buscar boxeadores: ${response.statusCode} - ${response.body}');
      throw Exception(
          'Error al cargar los peleadores (código: ${response.statusCode})');
    }
  }
  // ...existing code...

Future<bool> _isFollowing(String userId) async {
  final response = await http.get(
    Uri.parse('$API_BASE_URL/followers/check/$userId'),
    headers: {
      'Authorization': 'Bearer ${Session.token}',
      'Content-Type': 'application/json',
    },
  );
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['following'] == true;
  }
  return false;
}

  Future<void> _toggleFollow(String userId, bool currentlyFollowing) async {
    if (currentlyFollowing) {
      await http.delete(
        Uri.parse('$API_BASE_URL/followers/unfollow/$userId'),
        headers: {
          'Authorization': 'Bearer ${Session.token}',
          'Content-Type': 'application/json',
        },
      );
    } else {
      await http.post(
        Uri.parse('$API_BASE_URL/followers/follow/$userId'),
        headers: {
          'Authorization': 'Bearer ${Session.token}',
          'Content-Type': 'application/json',
        },
      );
    }
    setState(() {}); // Refresca el widget para actualizar el botón
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de Búsqueda'),
        backgroundColor: Colors.red,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/boxing_bg.jpg', //
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.7)),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withOpacity(0.8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Filtros: ${widget.city?.isNotEmpty == true ? widget.city : "Cualquier ciudad"}, ${widget.selectedWeight?.isNotEmpty == true && widget.selectedWeight != "Cualquiera" ? widget.selectedWeight : "Cualquier peso"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Regresa a la pantalla de filtros (HomeScreen)
                      },
                      child: const Text('Editar Filtros', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Fighter>>(
                  future: _fightersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.red));
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('Error: ${snapshot.error}',
                                style: const TextStyle(color: Colors.white70)),
                          ));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No se encontraron boxeadores con esos criterios.',
                              style: TextStyle(color: Colors.white)));
                    } else {
                      final fighters = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: fighters.length,
                        itemBuilder: (context, index) {
                          final fighter = fighters[index];
                          // Evitar mostrar el propio usuario en la lista si es el caso
                          if (fighter.id == Session.userId) { //
                            return const SizedBox.shrink(); // No mostrarse a uno mismo
                          }
                          return Card(
                            color: Colors.grey[850]?.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fighter.name, //
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_city,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        fighter.city, //
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.scale, // Icono para peso
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Peso: ${fighter.weight}', //
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap( // Usar Wrap para que los botones se ajusten si no caben
                                    spacing: 8.0, // Espacio horizontal entre botones
                                    runSpacing: 8.0, // Espacio vertical si hay varias líneas
                                    alignment: WrapAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: () async { // <--- MODIFICADO PARA SER ASYNC
                                          if (Session.userId != null && //
                                              Session.username != null && //
                                              Session.token != null) { //
                                            
                                            // --- INICIO DE NUEVA LÓGICA ---
                                            try {
                                              // Opcional: Mostrar un indicador de carga o feedback
                                              // if (mounted) {
                                              //   ScaffoldMessenger.of(context).showSnackBar(
                                              //     const SnackBar(content: Text('Iniciando chat...'), duration: Duration(seconds: 1)),
                                              //   );
                                              // }

                                              final String conversationId = await _chatService.initiateChatSession(fighter.id); // fighter.id es el opponentId
                                              
                                              if (mounted) { // Verificar si el widget sigue montado
                                                // ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Quitar el SnackBar si se usó
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        CombatChatScreen( //
                                                      // Se asume que CombatChatScreen será modificado para aceptar estos parámetros
                                                      conversationId: conversationId, 
                                                      userToken: Session.token!, //
                                                      currentUserId: Session.userId!, //
                                                      currentUsername: Session.username!, //
                                                      opponentId: fighter.id,    
                                                      opponentName: fighter.name, //
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                               if (mounted) {
                                                 // ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Quitar si se usó
                                                 ScaffoldMessenger.of(context).showSnackBar(
                                                   SnackBar(content: Text('Error al iniciar chat: ${e.toString()}')),
                                                 );
                                               }
                                            }
                                            // --- FIN DE NUEVA LÓGICA ---

                                          } else {
                                            if (mounted) { // Asegurar que el widget está montado para mostrar SnackBar
                                               ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                    content: Text('Error: Datos de sesión incompletos para el chat.')),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.mail_outline,
                                            color: Colors.white, size: 18),
                                        label: const Text(
                                          'Mensaje',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                        ),
                                       onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => FighterProfileScreen(fighter: fighter),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.person_outline,
                                            color: Colors.white, size: 18),
                                        label: const Text(
                                          'Ver Perfil',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: () {
                                          if (Session.userId != null && Session.username != null) { //
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CreateCombatScreen( //
                                                  // Pasa los IDs, no los nombres, si tu backend espera IDs
                                                  creatorId: Session.userId!, // Asume que creator es el ID del usuario actual
                                                  creatorName: Session.username!, // <--- CORRECCIÓN APLICADA AQUÍ
                                                  opponentId: fighter.id, 
                                                  opponentName: fighter.name, // Nombre del oponente
                                                ),  
                                              ),
                                            );
                                          } else {
                                             ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Error: Datos de sesión incompletos para crear un combate.')),
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                            Icons.sports_kabaddi_outlined, // Icono de combate/desafío
                                            color: Colors.white, size: 18),
                                        label: const Text(
                                          'Desafiar', // Cambiado de "Crear Combate" a "Desafiar"
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: () {
                                          if (fighter.boxingVideo != null && fighter.boxingVideo!.isNotEmpty) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                contentPadding: EdgeInsets.zero,
                                                content: SizedBox(
                                                  width: 320,
                                                  height: 180,
                                                  child: VideoPlayerWidget(videoUrl: fighter.boxingVideo!),
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Este boxeador no tiene video subido.')),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
                                        label: const Text(
                                          'Ver video',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      FutureBuilder<bool>(
                                        future: _isFollowing(fighter.id),
                                        builder: (context, snapshot) {
                                          final isFollowing = snapshot.data ?? false;
                                          return ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isFollowing ? Colors.grey : Colors.green,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            icon: Icon(
                                              isFollowing ? Icons.check : Icons.person_add,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            label: Text(
                                              isFollowing ? 'Siguiendo' : 'Seguir',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                            onPressed: () async {
                                              await _toggleFollow(fighter.id, isFollowing);
                                            },
                                          );
                                        },
                                      ),
                                      // Botón para seguir/seguir al boxeador
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}