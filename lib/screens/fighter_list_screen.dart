// lib/screens/fighter_list_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/fighter_model.dart';

class FighterListScreen extends StatefulWidget {
  final String selectedWeight;
   final String city;

  const FighterListScreen({Key? key, required this.selectedWeight, required this.city,}) : super(key: key);

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
    final response = await http.get(Uri.parse('http://localhost:9000/api/users'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
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
      appBar: AppBar(
        title: Text('Peleadores - ${widget.selectedWeight}'),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<List<Fighter>>(
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
              itemCount: fighters.length,
              itemBuilder: (context, index) {
                final fighter = fighters[index];
                return ListTile(
                  title: Text(fighter.name),
                  subtitle: Text(fighter.email),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Aquí puedes implementar la funcionalidad del botón "Mensaje" más adelante
                    },
                    child: Text('Mensaje'),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
