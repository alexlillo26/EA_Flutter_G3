import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'fighter_list_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import 'combat_management_screen.dart'; // <--- NUEVA IMPORTACIÓN
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as latlng;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  // final bool _showMap = false; // No parece usarse

  final TextEditingController searchController = TextEditingController();
  String selectedWeight = 'Peso pluma'; // Asegúrate que este es un valor válido inicial

  // El orden de los BottomNavigationBarItems ahora será:
  // 0: Perfil, 1: Mapa, 2: Home (Búsqueda), 3: Mis Combates <NUEVO>, 4: Chats
  int _currentIndex = 2; // Índice inicial (Home - Búsqueda)

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Actualizar la lista de pantallas para incluir CombatManagementScreen
  List<Widget> get _screens => [
        const ProfileScreen(), // Índice 0
        _buildMapScreen(), // Índice 1
        _buildSearchHomeScreenContent(), // Índice 2 (Contenido principal de búsqueda)
        const CombatManagementScreen(), // Índice 3 <--- NUEVA PANTALLA
        const ChatListScreen(), // Índice 4
      ];

  void _getCurrentLocation() async {
    // ... (tu código existente para obtener la ubicación) ...
     try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Servicio de ubicación deshabilitado');
        // Considera mostrar un mensaje al usuario
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permiso de ubicación denegado');
          // Considera mostrar un mensaje al usuario
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('Permiso de ubicación denegado permanentemente');
        // Considera mostrar un mensaje al usuario y guiarlo a la configuración de la app
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
      // Considera mostrar un mensaje al usuario
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
    return fmap.FlutterMap(
      options: fmap.MapOptions(
        initialCenter: latlng.LatLng(
            _currentPosition!.latitude, _currentPosition!.longitude),
        initialZoom: 14.0, // Zoom un poco más cercano
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
                  color: Colors.redAccent, size: 45), // Icono más grande y color diferente
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchHomeScreenContent() { // Renombrado para claridad
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/boxing_bg.jpg',
          fit: BoxFit.cover,
        ),
        Container(color: Colors.black.withOpacity(0.65)), // Un poco más de opacidad
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Encuentra tu Próximo Combate', // Título más directo
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30, // Un poco más grande
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Conecta con rivales de tu nivel y ciudad. ¡Prepárate para el ring!', // Texto más corto y motivador
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
                          items: ['Peso pluma', 'Peso ligero', 'Peso medio', 'Peso pesado', 'Cualquiera'] // Añadido "Cualquiera"
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
                 SizedBox( // Botón de búsqueda más prominente
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
                            selectedWeight: selectedWeight == 'Cualquiera' ? null : selectedWeight, // Enviar null si es "Cualquiera"
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
      // El AppBar se puede definir dentro de cada pantalla individual si se necesita
      // o aquí si es común a todas las pantallas del BottomNav
      body: IndexedStack( // Usar IndexedStack para mantener el estado de las pantallas
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (mounted) { // Buena práctica verificar `mounted`
            setState(() {
              _currentIndex = index;
            });
          }
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.redAccent, // Un tono de rojo más vibrante
        unselectedItemColor: Colors.white60, // Un gris más claro para mejor contraste
        type: BottomNavigationBarType.fixed, // Para que todos los items sean visibles
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person), // Icono diferente cuando está activo
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined), // Cambiado de home a search para reflejar la acción
            activeIcon: Icon(Icons.search),
            label: 'Buscar', // Etiqueta más clara
          ),
          BottomNavigationBarItem( // NUEVO ITEM
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