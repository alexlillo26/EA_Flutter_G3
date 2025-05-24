import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../session.dart';

class CreateCombatScreen extends StatefulWidget {
  final String creator;
  final String opponent;

  const CreateCombatScreen({
    super.key,
    required this.creator,
    required this.opponent,
  });

  @override
  State<CreateCombatScreen> createState() => _CreateCombatScreenState();
}

class _CreateCombatScreenState extends State<CreateCombatScreen> {
  final nivelController = TextEditingController();
  final fechaController = TextEditingController();
  final horaController = TextEditingController();

  List<Map<String, dynamic>> gyms = [];
  String? selectedGymId;

  @override
  void initState() {
    super.initState();
    fetchGyms();
  }

  Future<void> fetchGyms() async {
    final url = Uri.parse('https://ea3-api.upc.edu/api/gym');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json is List
            ? json
            : (json['results'] ?? json['gyms'] ?? json['data'] ?? []);
        setState(() {
          gyms = data
              .map<Map<String, dynamic>>((g) => {
                    "id": g["_id"],
                    "name": g["name"] ?? "Sin nombre",
                  })
              .toList();
          if (gyms.isNotEmpty) {
            selectedGymId = gyms.first["id"];
          }
        });
      } else {
        throw Exception('Error al obtener gimnasios: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar gimnasios: $e')),
      );
    }
  }

  Future<void> crearCombate() async {
    final creatorId = widget.creator;
    final opponentId = widget.opponent;
    final gymId = selectedGymId;
    final nivel = nivelController.text.trim();
    final fecha = fechaController.text.trim(); // dd/mm/aaaa
    final hora = horaController.text.trim(); // HH:mm

    if (gymId == null ||
        creatorId.isEmpty ||
        opponentId.isEmpty ||
        nivel.isEmpty ||
        fecha.isEmpty ||
        hora.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faltan datos obligatorios')),
      );
      return;
    }

    try {
      final partesFecha = fecha.split('/');
      if (partesFecha.length != 3) throw Exception('Fecha inválida');
      final fechaIso =
          '${partesFecha[2]}-${partesFecha[1].padLeft(2, '0')}-${partesFecha[0].padLeft(2, '0')}T${hora.padLeft(5, '0')}:00';

      final combate = {
        "creator": creatorId,
        "opponent": opponentId,
        "date": fechaIso,
        "time": hora,
        "level": nivel,
        "gym": gymId,
        "boxers": [creatorId, opponentId],
      };

      final url = Uri.parse('https://ea3-api.upc.edu/api/combat');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${Session.token}"
        },
        body: jsonEncode(combate),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear combate: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Datos inválidos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Combate'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creador: ${widget.creator}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Oponente: ${widget.opponent}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              gyms.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: selectedGymId,
                      items: gyms
                          .map((gym) => DropdownMenuItem<String>(
                                value: gym["id"],
                                child: Text(gym["name"]),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedGymId = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Gimnasio',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.black,
                      ),
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                    ),
              const SizedBox(height: 16),
              TextField(
                controller: nivelController,
                decoration: const InputDecoration(
                  labelText: 'Nivel',
                  hintText: 'Selecciona el nivel de combate',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.black,
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: fechaController,
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  hintText: 'dd/mm/aaaa',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.black,
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: horaController,
                decoration: const InputDecoration(
                  labelText: 'Hora',
                  hintText: '--:--',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.black,
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: crearCombate,
                    child: const Text(
                      'Crear Combate',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}