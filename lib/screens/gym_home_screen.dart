import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as latlng;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session.dart'; // importa tu clase Session
import 'package:face2face_app/config/app_config.dart'; // <-- Añade esto

// --- Widget para el perfil real del gimnasio ---
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
      Uri.parse('$API_BASE_URL/gym/${widget.gymId}'), // <-- Cambia aquí
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
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.fitness_center, color: Colors.white, size: 48),
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
              const SizedBox(height: 16),
              Divider(color: Colors.redAccent, thickness: 1.5),
              const SizedBox(height: 16),
              _profileRow(Icons.email, 'Email', gymData!['email']),
              _profileRow(Icons.phone, 'Teléfono', gymData!['phone']),
              _profileRow(Icons.location_on, 'Ubicación', gymData!['place']),
              _profileRow(Icons.attach_money, 'Precio', gymData!['price']?.toString()),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                onPressed: () {
                  _showEditProfileDialog(context);                },
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  'Editar perfil',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
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
  // Añade esto en _GymProfileTabState:
  void _showEditProfileDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: gymData?['name'] ?? '');
    final emailCtrl = TextEditingController(text: gymData?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: gymData?['phone'] ?? '');
    final placeCtrl = TextEditingController(text: gymData?['place'] ?? '');
    final priceCtrl = TextEditingController(text: gymData?['price']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar perfil', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', labelStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono', labelStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: placeCtrl,
                  decoration: const InputDecoration(labelText: 'Ubicación', labelStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Precio', labelStyle: TextStyle(color: Colors.white70)),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final updated = {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'place': placeCtrl.text.trim(),
                  'price': double.tryParse(priceCtrl.text.trim()) ?? 0,
                };
                final response = await http.put(
                  Uri.parse('$API_BASE_URL/gym/${widget.gymId}'), // <-- Cambia aquí
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ${Session.token}',
                  },
                  body: json.encode(updated),
                );
                if (response.statusCode == 200) {
                  setState(() {
                    gymData = json.decode(response.body);
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil actualizado correctamente')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar: ${json.decode(response.body)['message'] ?? 'Error'}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// --- Widget para el mapa del gimnasio con marcador rojo ---
class GymMapTab extends StatelessWidget {
  final double latitude;
  final double longitude;
  const GymMapTab({required this.latitude, required this.longitude, super.key});

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

// --- TAB DE COMBATES DEL GIMNASIO ---
class GymCombatsTab extends StatefulWidget {
  final String gymId;
  const GymCombatsTab({required this.gymId, super.key});

  @override
  State<GymCombatsTab> createState() => _GymCombatsTabState();
}

class _GymCombatsTabState extends State<GymCombatsTab> {
  late Future<List<dynamic>> _combatsFuture;

  @override
  void initState() {
    super.initState();
    _combatsFuture = fetchCombats();
  }

  Future<List<dynamic>> fetchCombats() async {
    final response = await http.get(
      Uri.parse('$API_BASE_URL/combat/gym/search/${widget.gymId}'), // <-- Cambia aquí
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Session.token}',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['combats'] ?? [];
    } else {
      throw Exception('Error al cargar los combates');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _combatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay combates en este gimnasio', style: TextStyle(color: Colors.white)));
        }
        final combats = snapshot.data!;
        final now = DateTime.now();

        // Separar futuros y pasados
        final futuros = combats.where((c) {
          final date = DateTime.tryParse(c['date'] ?? '') ?? now;
          return (c['status'] == 'pending' || c['status'] == 'accepted') && date.isAfter(now);
        }).toList();

        final pasados = combats.where((c) {
          final date = DateTime.tryParse(c['date'] ?? '') ?? now;
          return c['status'] == 'completed' || (c['status'] == 'accepted' && date.isBefore(now));
        }).toList();

        return ListView(
          children: [
            const Text(
              'Próximos combates',
              style: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (futuros.isEmpty)
              const Text('No hay combates futuros', style: TextStyle(color: Colors.white70)),
            ...futuros.map((c) => _combatCard(c, context, isFuture: true)),
            const SizedBox(height: 24),
            const Text(
              'Historial de combates',
              style: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (pasados.isEmpty)
              const Text('No hay combates pasados', style: TextStyle(color: Colors.white70)),
            ...pasados.map((c) => _combatCard(c, context, isFuture: false)),
          ],
        );
      },
    );
  }

  Widget _combatCard(dynamic combat, BuildContext context, {required bool isFuture}) {
    final date = DateTime.tryParse(combat['date'] ?? '') ?? DateTime.now();
    final creator = combat['creator']?['name'] ?? 'Desconocido';
    final opponent = combat['opponent']?['name'] ?? 'Desconocido';
    final status = combat['status'] ?? '';
    final level = combat['level'] ?? '';
    final image = combat['image'];
    final winner = combat['winner']?['name'];

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (image != null && image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.sports_mma, color: Colors.redAccent, size: 40),
                ),
              )
            else
              const Icon(Icons.sports_mma, color: Colors.redAccent, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$creator vs $opponent',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nivel: $level',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    'Fecha: ${date.day}/${date.month}/${date.year}  ${combat['time'] ?? ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    'Estado: ${_statusText(status)}',
                    style: TextStyle(
                      color: status == 'completed'
                          ? Colors.green
                          : status == 'pending'
                              ? Colors.orange
                              : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isFuture && winner != null)
                    Text(
                      'Ganador: $winner',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptado';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }
}

// --- Pantalla principal del gimnasio ---
class GymHomeScreen extends StatefulWidget {
  const GymHomeScreen({super.key});

  @override
  State<GymHomeScreen> createState() => _GymHomeScreenState();
}

class _GymHomeScreenState extends State<GymHomeScreen> {
  int _currentIndex = 0;

  // Cambia estos valores por los reales de tu sesión/gimnasio
  String? get gymId => Session.gymId;
  final double gymLat = 40.4168; // <-- PON AQUÍ LA LATITUD REAL
  final double gymLng = -3.7038; // <-- PON AQUÍ LA LONGITUD REAL

  List<Widget> get _tabs => [
    Center(child: Text('Eventos', style: TextStyle(color: Colors.white, fontSize: 22))),
    if (gymId != null)
      GymCombatsTab(gymId: gymId!)
    else
      const Center(child: CircularProgressIndicator()),
    if (gymId != null)
      GymProfileTab(gymId: gymId!)
    else
      const Center(child: CircularProgressIndicator()),
    GymMapTab(latitude: gymLat, longitude: gymLng),
  ];

  @override
  Widget build(BuildContext context) {
    print('Entrando en GymHomeScreen');

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
                '',
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
              _buildTabButton('Inicio', 0),
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