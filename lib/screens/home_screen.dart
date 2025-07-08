import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'fighter_list_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import 'combat_management_screen.dart';
import 'statistics_screen.dart'; // Import the new screen
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:face2face_app/config/app_config.dart'; // <-- Añade esto

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  final TextEditingController searchController = TextEditingController();

  // Cambia aquí las categorías de peso por las del screenshot
  final List<String> weightCategories = [
    '-48 kg',
    '48 – 51 kg',
    '51 – 54 kg',
    '54 – 57 kg',
    '57 – 60 kg',
    '60 – 63.5 kg',
    '63.5 – 67 kg',
    '67 – 71 kg',
    '71 – 75 kg',
    '75 – 80 kg',
    '80 – 92 kg',
    '+92 kg',
    'Cualquiera',
  ];

  String selectedWeight = '-48 kg';
  int _currentIndex = 0;
  bool _showMap = false;

  List<Widget> get _screens => [
        _buildSearchHomeScreenContent(), // 0: Buscar (Home)
        const CombatManagementScreen(),   // 1: Combates
        const ChatListScreen(),           // 2: Chats
      ];

  void _showMapDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 400,
          child: _buildMapScreen(),
        ),
      ),
    );
  }

  Widget _buildMapScreen() {
    final position = _currentPosition;
    return fmap.FlutterMap(
      options: fmap.MapOptions(
        center: position != null
            ? latlng.LatLng(position.latitude, position.longitude)
            : latlng.LatLng(40.4168, -3.7038), // Default to Madrid if no location
        zoom: 13.0,
      ),
      children: [
        fmap.TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        if (position != null)
          fmap.MarkerLayer(
            markers: [
              fmap.Marker(
                width: 40.0,
                height: 40.0,
                point: latlng.LatLng(position.latitude, position.longitude),
                child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
              ),
            ],
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, do nothing or prompt user
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, do nothing or prompt user
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, do nothing or prompt user
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
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
                          hintText: 'Ciudad del boxeador',
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
                          items: weightCategories
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(
                      _showMap ? Icons.close : Icons.map_outlined,
                      color: Colors.redAccent,
                    ),
                    label: Text(
                      _showMap ? 'Ocultar mapa de gimnasios' : 'Ver mapa de gimnasios',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      backgroundColor: Colors.black.withOpacity(0.85),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _showMap = !_showMap;
                      });
                    },
                  ),
                ),
                if (_showMap) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 320,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMapScreen(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // ...resto de la columna...
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens;
    return Scaffold(
      endDrawer: Drawer(
        backgroundColor: Colors.black.withOpacity(0.92),
        child: SafeArea(
          child: Column(
            children: [
              // Eliminado DrawerHeader con "Menú"
              const SizedBox(height: 32),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.redAccent),
                title: const Text('Perfil', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_outlined, color: Colors.redAccent),
                title: const Text('Estadísticas', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen()));
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'Face2Face',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16, letterSpacing: 1.1),
                ),
              ),
            ],
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.25), // Más transparente
        elevation: 0,
        title: const Text('Face2Face', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.redAccent),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Menú',
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
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
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
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