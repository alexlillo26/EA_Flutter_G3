import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as latlng;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session.dart'; // importa tu clase Session


// --- Widget para el perfil real del gimnasio ---
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
      return const Center(child: Text('No se pudo cargar el perfil del gimnasio', style: TextStyle(color: Colors.white)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          gymData!['name'] ?? '',
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _profileRow('Email', gymData!['email']),
        _profileRow('Teléfono', gymData!['phone']),
        _profileRow('Ubicación', gymData!['place']),
        _profileRow('Precio', gymData!['price']?.toString()),
      ],
    );
  }

  Widget _profileRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '-', style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

// --- Widget para el mapa del gimnasio con marcador rojo ---
class GymMapTab extends StatelessWidget {
  final double latitude;
  final double longitude;
  const GymMapTab({required this.latitude, required this.longitude, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return fmap.FlutterMap(
      options: fmap.MapOptions(
        center: latlng.LatLng(latitude, longitude),
        zoom: 15.0,
      ),
      children: [
        fmap.TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        fmap.MarkerLayer(
          markers: [
            fmap.Marker(
              width: 80.0,
              height: 80.0,
              point: latlng.LatLng(latitude, longitude),
              child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
            ),
          ],
        ),
      ],
    );
  }
}

// --- Pantalla principal del gimnasio ---
class GymHomeScreen extends StatefulWidget {
  const GymHomeScreen({Key? key}) : super(key: key);

  @override
  State<GymHomeScreen> createState() => _GymHomeScreenState();
}

class _GymHomeScreenState extends State<GymHomeScreen> {
  int _currentIndex = 0;

  // Cambia estos valores por los reales de tu sesión/gimnasio
  String? get gymId => Session.gymId;
  final double gymLat = 40.4168; // <-- PON AQUÍ LA LATITUD REAL
  final double gymLng = -3.7038; // <-- PON AQUÍ LA LONGITUD REAL

  List<Widget> get _tabs =>[
    Center(child: Text('Eventos', style: TextStyle(color: Colors.white, fontSize: 22))),
    Center(child: Text('Combates del Gimnasio', style: TextStyle(color: Colors.white, fontSize: 22))),
    if (gymId != null)
    GymProfileTab(gymId: gymId!)
    else
    const Center(child: CircularProgressIndicator()),
    GymMapTab(latitude: gymLat, longitude: gymLng),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Face2Face', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'cornella',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton('Eventos', 0),
              _buildTabButton('Combates del Gimnasio', 1),
              _buildTabButton('Perfil', 2),
              _buildTabButton('Mapa', 3),
            ],
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/boxing_bg.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.7)),
          if (_currentIndex == 0)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Bienvenido a tu panel de gimnasio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gestiona tus combates, consulta estadísticas y mantén tu información actualizada.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _tabs[_currentIndex],
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: isSelected
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white, width: 3),
                ),
              )
            : null,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}