import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'fighter_list_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import 'combat_management_screen.dart'; // <--- NUEVA IMPORTACIÓN
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http; // Para realizar solicitudes HTTP
import 'dart:convert'; // Para decodificar respuestas JSON

const String API_BASE_URL = 'http://localhost:9000/api'; // Define la URL base de tu API

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  final TextEditingController searchController = TextEditingController();
  String selectedWeight = 'Peso pluma'; // Asegúrate que este es un valor válido inicial
  int _currentIndex = 2; // Índice inicial (Home - Búsqueda)

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  List<Widget> get _screens => [
        const ProfileScreen(), // Índice 0
        _buildMapScreen(), // Índice 1
        _buildSearchHomeScreenContent(), // Índice 2 (Contenido principal de búsqueda)
        const CombatManagementScreen(), // Índice 3 <--- NUEVA PANTALLA
        const ChatListScreen(), // Índice 4
      ];

  void _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Servicio de ubicación deshabilitado');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permiso de ubicación denegado');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Permiso de ubicación denegado permanentemente');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      print('Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      print('Error al obtener la ubicación: $e');
    }
  }

  Future<List<latlng.LatLng>> _fetchGymLocations() async {
    final response = await http.get(Uri.parse('$API_BASE_URL/gym?page=1&pageSize=50')); // Endpoint del backend

    if (response.statusCode == 200) {
      final Map<String, dynamic> gymsResponse = json.decode(response.body);
      final List<dynamic> gyms = gymsResponse['gyms'];
      List<latlng.LatLng> gymLocations = [];

      for (var gym in gyms) {
        final city = gym['place'];
        final geoResponse = await http.get(Uri.parse(
            'https://nominatim.openstreetmap.org/search?q=$city&format=json&limit=1'));

        if (geoResponse.statusCode == 200) {
          final List<dynamic> geoData = json.decode(geoResponse.body);
          if (geoData.isNotEmpty) {
            final lat = double.parse(geoData[0]['lat']);
            final lon = double.parse(geoData[0]['lon']);
            gymLocations.add(latlng.LatLng(lat, lon));
          }
        }
      }

      return gymLocations;
    } else {
      throw Exception('Error al obtener gimnasios');
    }
  }

  Widget _buildMapScreen() {
    if (_currentPosition == null) {
      return const Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.red),
          SizedBox(height: 10),
          Text("Obteniendo ubicación...", style: TextStyle(color: Colors.white70)),
        ],
      ));
    }

    return FutureBuilder<List<latlng.LatLng>>(
      future: _fetchGymLocations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar gimnasios: ${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        } else if (snapshot.hasData) {
          final gymLocations = snapshot.data!;
          return fmap.FlutterMap(
            options: fmap.MapOptions(
              initialCenter: latlng.LatLng(
                  _currentPosition!.latitude, _currentPosition!.longitude),
              initialZoom: 14.0,
            ),
            children: [
              fmap.TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              fmap.MarkerLayer(
                markers: [
                  fmap.Marker(
                    width: 80.0,
                    height: 80.0,
                    point: latlng.LatLng(
                        _currentPosition!.latitude, _currentPosition!.longitude),
                    child: const Icon(Icons.location_pin,
                        color: Colors.redAccent, size: 45),
                  ),
                  ...gymLocations.map((location) => fmap.Marker(
                        width: 80.0,
                        height: 80.0,
                        point: location,
                        child: const Icon(Icons.location_pin,
                            color: Colors.black, size: 45),
                      )),
                ],
              ),
            ],
          );
        } else {
          return const Center(
            child: Text(
              'No se encontraron gimnasios',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
      },
    );
  }

  Widget _buildSearchHomeScreenContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/boxing_bg.jpg',
          fit: BoxFit.cover,
        ),
        Container(color: Colors.black.withOpacity(0.65)),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Encuentra tu Próximo Combate',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Conecta con rivales de tu nivel y ciudad. ¡Prepárate para el ring!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Ciudad o nombre del boxeador',
                          hintStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.black54),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedWeight,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black87, fontSize: 16),
                          items: ['Peso pluma', 'Peso ligero', 'Peso medio', 'Peso pesado', 'Cualquiera']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedWeight = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_search_outlined, color: Colors.white),
                    label: const Text('Buscar Boxeadores', style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FighterListScreen(
                            selectedWeight: selectedWeight == 'Cualquiera' ? null : selectedWeight,
                            city: searchController.text.trim(),
                          ),
                        ),
                      );
                    },
                  ),
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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (mounted) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Combates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
        ],
      ),
    );
  }
}