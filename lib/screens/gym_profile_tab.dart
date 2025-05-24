import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:face2face_app/config/app_config.dart';

class GymProfileTab extends StatefulWidget {
  final String gymId;
  const GymProfileTab({required this.gymId, super.key});

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
      Uri.parse('$API_BASE_URL/gym/${widget.gymId}'),
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
    child: Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 54,
            backgroundColor: Colors.red.shade900,
            child: Icon(Icons.fitness_center, color: Colors.white, size: 54),
          ),
          const SizedBox(height: 18),
          Text(
            gymData!['name'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            gymData!['place'] ?? '',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 8),
          _profileRow(Icons.email, 'Email', gymData!['email']),
          _profileRow(Icons.phone, 'Teléfono', gymData!['phone']),
          _profileRow(Icons.euro, 'Precio', gymData!['price']?.toString()),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Editar perfil', style: TextStyle(color: Colors.white)),
          ),
        ],
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
}