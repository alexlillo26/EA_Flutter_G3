import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GymProfileTab extends StatefulWidget {
  final String gymId;
  const GymProfileTab({required this.gymId, Key? key}) : super(key: key);

  @override
  State<GymProfileTab> createState() => _GymProfileTabState();
}

class _GymProfileTabState extends State<GymProfileTab> {
  Map<String, dynamic>? gymData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGymData();
  }

  Future<void> fetchGymData() async {
    final response = await http.get(
      Uri.parse('http://localhost:9000/api/gym/${widget.gymId}'),
    );
    if (response.statusCode == 200) {
      setState(() {
        gymData = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

 @override
Widget build(BuildContext context) {
  if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  if (gymData == null) {
    return const Center(
      child: Text('No se pudo cargar el perfil del gimnasio', style: TextStyle(color: Colors.white)),
    );
  }
  return Center(
    child: Card(
      color: Colors.black.withOpacity(0.85),
      elevation: 24,
      shadowColor: Colors.redAccent.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(color: Colors.white24, width: 2),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.red.shade900.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white,
                child: Icon(Icons.fitness_center, color: Colors.red, size: 56),
              ),
              const SizedBox(height: 16),
              Text(
                gymData!['name'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                icon: Icon(Icons.edit, color: Colors.white),
                label: Text('Editar perfil', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: 16),
              _profileRow(Icons.email, 'Email', gymData!['email']),
              _profileRow(Icons.phone, 'Teléfono', gymData!['phone']),
              _profileRow(Icons.location_on, 'Ubicación', gymData!['place']),
              _profileRow(Icons.euro, 'Precio', gymData!['price']?.toString()),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _profileRow(IconData icon, String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: Colors.redAccent, size: 24),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value ?? '-',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}