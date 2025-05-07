import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/fighter_model.dart';
import 'login_screen.dart'; // ✅ Para usar Session.token

class FighterListScreen extends StatefulWidget {
  final String selectedWeight;
  final String city;

  const FighterListScreen({
    Key? key,
    required this.selectedWeight,
    required this.city,
  }) : super(key: key);

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
    // Aquí se mantiene la funcionalidad existente para obtener los peleadores
    final response = await http.get(
      Uri.parse('http://localhost:9000/api/users?page=1&pageSize=50'),
      headers: {
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
                padding: EdgeInsets.all(16),
                color: Colors.black.withOpacity(0.8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Resultados para: ${widget.city}, ${widget.selectedWeight}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Regresa a la pantalla de filtros
                      },
                      child: Text('Editar Filtros'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Fighter>>(
                  future: _fightersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No se encontraron peleadores.'));
                    } else {
                      final fighters = snapshot.data!;
                      return ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: fighters.length,
                        itemBuilder: (context, index) {
                          final fighter = fighters[index];
                          return Card(
                            color: Colors.grey[850]?.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fighter.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.location_city, color: Colors.white70, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        fighter.city,
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.scale, color: Colors.white70, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'Peso: ${fighter.weight}',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: () {
                                          // Aquí puedes implementar la funcionalidad de "Ver Perfil" o "Retar"
                                        },
                                        child: Text('Ver Perfil'),
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