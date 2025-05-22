import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'fighter_list_screen.dart';
import 'profile_screen.dart'; // Pantalla de perfil
import 'chat_list_screen.dart'; // Pantalla de chats
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as latlng;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  Position? _currentPosition;
  final bool _showMap = false; // Controla si el mapa se muestra o no

  final TextEditingController searchController = TextEditingController();
  String selectedWeight = 'Peso pluma';

  int _currentIndex = 2; // Índice inicial (Home)
  @override
void initState() {
  super.initState();
  _getCurrentLocation();
}

  List<Widget> get _screens => [
    ProfileScreen(),
    _buildMapScreen(),
    _buildHomeScreen(),
    ChatListScreen(),
  ];

    void _getCurrentLocation() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Servicio de ubicación deshabilitado');
      throw Exception('El servicio de ubicación está deshabilitado.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permiso de ubicación denegado');
        throw Exception('Permiso de ubicación denegado.');
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    print('Ubicación obtenida: ${position.latitude}, ${position.longitude}');
    setState(() {
      _currentPosition = position;
    });
  } catch (e) {
    print('Error al obtener la ubicación: $e');
  }
}

  Widget _buildMapScreen() {
  if (_currentPosition == null) {
    return const Center(child: CircularProgressIndicator());
  }
  return fmap.FlutterMap(
    options: fmap.MapOptions(
      center: latlng.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      zoom: 13.0,
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
            point: latlng.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
          ),
        ],
      ),
    ],
  );
}

  Widget _buildHomeScreen() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/boxing_bg.jpg', // Asegúrate de que esta imagen exista en tu proyecto
          fit: BoxFit.cover,
        ),
        Container(color: Colors.black.withOpacity(0.6)),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Organiza y encuentra combates de Boxeo al instante',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Conecta con rivales, promotores y gimnasios. Participa en peleas equilibradas, entrena con los mejores y escala en el ranking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Buscador de ciudad
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.black), // Texto en negro
                        decoration: InputDecoration(
                          hintText: 'Ciudad, gimnasio o boxeador',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12), // Ajusta la altura
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Selector de peso
                    Container(
                      height: 48, // Asegura que tenga la misma altura que el buscador
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white54),
                      ),
                      child: DropdownButton<String>(
                        value: selectedWeight,
                        items: ['Peso pluma', 'Peso ligero', 'Peso medio']
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e, style: const TextStyle(color: Colors.white)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedWeight = value!;
                          });
                        },
                        dropdownColor: Colors.black,
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón de buscar
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FighterListScreen(
                              selectedWeight: selectedWeight,
                              city: searchController.text,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Buscar Boxeadores',
                        style: TextStyle(color: Colors.white), // Texto en blanco
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // Cambia entre pantallas según el índice
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
        ],
      ),
    );
  }
}