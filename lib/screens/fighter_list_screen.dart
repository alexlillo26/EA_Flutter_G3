import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:face2face_app/config/app_config.dart';
import 'package:face2face_app/session.dart';
import 'package:face2face_app/models/fighter_model.dart';
import 'package:face2face_app/screens/combat_chat_screen.dart';
import 'package:face2face_app/screens/create_combat_screen.dart';
// Si tienes una pantalla para ver el perfil de otro usuario, impórtala aquí
// import 'view_profile_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fightersFuture = _fetchFilteredFighters();
  }

  Future<List<Fighter>> _fetchFilteredFighters() async {
    final token = Session.token;
    if (token == null) {
      // Es buena idea manejar este caso, quizás mostrando un mensaje al usuario
      // o redirigiendo al login si la sesión es estrictamente necesaria aquí.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de autenticación. Por favor, inicia sesión de nuevo.')),
      );
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

    final url = Uri.parse('$API_BASE_URL/users/search').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    print('Buscando boxeadores con URL: $url'); // Útil para depuración

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
        return usersData.map((data) => Fighter.fromJson(data)).toList();
      } else {
        print('Respuesta no exitosa o sin clave "users": ${response.body}');
        throw Exception(
            'Error en la respuesta del API de búsqueda: ${responseBody['message'] ?? 'Formato inesperado'}');
      }
    } else {
      print('Error al buscar boxeadores: ${response.statusCode} - ${response.body}');
      throw Exception(
          'Error al cargar los peleadores (código: ${response.statusCode})');
    }
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
            'assets/images/boxing_bg.jpg',
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
                          if (fighter.id == Session.userId) {
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
                                    fighter.name,
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
                                        fighter.city,
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
                                        'Peso: ${fighter.weight}',
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
                                        onPressed: () {
                                          if (Session.userId != null &&
                                              Session.username != null &&
                                              Session.token != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CombatChatScreen(
                                                  combatId: fighter.id, // Usando el ID del boxeador como ID de sala de chat temporalmente
                                                  userToken: Session.token!,
                                                  currentUserId: Session.userId!,
                                                  currentUsername: Session.username!,
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Error: Datos de sesión incompletos para el chat.')),
                                            );
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
                                          // TODO: Implementar navegación a la pantalla de ver perfil del boxeador
                                          // Necesitarás una pantalla que acepte un userId
                                          // y muestre el perfil de ese usuario.
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Ver perfil de ${fighter.name} (pendiente).')),
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
                                          if (Session.userId != null && Session.username != null) { // Verifica también Session.username
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CreateCombatScreen(
                                                  // Pasa los IDs, no los nombres, si tu backend espera IDs
                                                  creatorId: Session.userId!, // Asume que creator es el ID del usuario actual
                                                  creatorName: fighter.id, 
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