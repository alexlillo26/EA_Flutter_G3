import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/fighter_model.dart';
import 'combat_chat_screen.dart'; // ✅ Importa la pantalla de chat
import 'create_combat_screen.dart'; // ✅ Importa la pantalla de crear combate
import '../session.dart'; 
import 'package:face2face_app/config/app_config.dart';

class FighterListScreen extends StatefulWidget {
  final String selectedWeight;
  final String city;

  const FighterListScreen({
    super.key,
    required this.selectedWeight,
    required this.city,
  });

  @override
  _FighterListScreenState createState() => _FighterListScreenState();
}

class _FighterListScreenState extends State<FighterListScreen> {
  late Future<List<Fighter>> _fightersFuture;

  @override
  void initState() {
    super.initState();
    _fightersFuture = fetchFightersByWeight(widget.selectedWeight);
  }

  Future<List<Fighter>> fetchFightersByWeight(String weight) async {
    final response = await http.get(
        Uri.parse('$API_BASE_URL/users?page=1&pageSize=50'),      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Session.token}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['users'];
      final fighters = data.map((json) => Fighter.fromJson(json)).toList();

      return fighters
          .where((f) =>
              f.weight == weight &&
              f.city.toLowerCase().contains(widget.city.toLowerCase()))
          .toList();
    } else {
      throw Exception('Error al cargar los peleadores');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/boxing_bg.jpg', // Imagen tenue de fondo
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.7)), // Opacidad negra
          Column(
            children: [
              // Barra superior con resumen del filtro
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withOpacity(0.8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Resultados para: ${widget.city}, ${widget.selectedWeight}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Regresa a la pantalla de filtros
                      },
                      child: const Text('Editar Filtros'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Fighter>>(
                  future: _fightersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No se encontraron peleadores.'));
                    } else {
                      final fighters = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: fighters.length,
                        itemBuilder: (context, index) {
                          final fighter = fighters[index];
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_city, color: Colors.white70, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        fighter.city,
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.scale, color: Colors.white70, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Peso: ${fighter.weight}',
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Botón de mensaje
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: () {
                                          if (Session.userId != null &&
                                              Session.username != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CombatChatScreen(
                                                  combatId: fighter.id,
                                                  userToken: Session.token!,
                                                  currentUserId: Session.userId!,
                                                  currentUsername: Session.username!,
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Error: Datos incompletos para iniciar el chat.')),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.mail, color: Colors.white),
                                        label: const Text(
                                          'Mensaje',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Botón de ver perfil
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: () {
                                          // Aquí puedes implementar la funcionalidad de "Ver Perfil"
                                        },
                                        icon: const Icon(Icons.person, color: Colors.white),
                                        label: const Text(
                                          'Ver Perfil',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Botón de crear combate
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CreateCombatScreen(
                                                creator: Session.username ?? 'Creador',
                                                opponent: fighter.name,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.sports_martial_arts, color: Colors.white),
                                        label: const Text(
                                          'Crear Combate',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
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