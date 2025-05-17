import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final userId = Session.userId;
    final token = Session.token;
    if (userId == null || token == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:9000/api/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        userData = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el perfil')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text('No se pudo cargar el perfil'))
              : Column(
                  children: [
                    const SizedBox(height: 24),
                    // Foto de perfil o icono
                    Center(
                      child: userData!['profilePicture'] != null &&
                              userData!['profilePicture'].toString().isNotEmpty
                          ? CircleAvatar(
                              radius: 48,
                              backgroundImage: NetworkImage(
                                  '${userData!['profilePicture']}?v=${DateTime.now().millisecondsSinceEpoch}',
                            )
                          )
                          : const CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.person, size: 48, color: Colors.white70),
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Botón Editar perfil
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final result = await Navigator.pushNamed(context, '/edit-profile');
                            if (result == true) {
                              fetchUserData(); // Refresca los datos al volver de editar
                            }

                          },
                          child: const Text(
                            'Editar perfil',
                            style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Botón Cerrar sesión
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Session.token = null;
                            Session.userId = null;
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          },
                          child: const Text(
                            'Cerrar sesión',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _profileCard('Nombre', userData!['name']),
                          _profileCard('Correo', userData!['email']),
                          _profileCard('Nacimiento', userData!['birthDate']?.toString()?.substring(0, 10) ?? ''),
                          _profileCard('Peso', userData!['weight']),
                          _profileCard('Ciudad', userData!['city']),
                          _profileCard('Teléfono', userData!['phone']),
                          _profileCard('Género', userData!['gender']),
                          _profileCard('Experiencia', userData!['isAdmin'] == true ? 'Administrador' : 'Usuario'),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _profileCard(String title, String? value) {
    return Card(
      color: Colors.grey[900],
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.white70)),
        subtitle: Text(value ?? '-', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}