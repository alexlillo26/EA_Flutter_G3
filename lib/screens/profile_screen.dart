import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, String> userData = {
    'Nombre': 'Juan Pérez',
    'Correo': 'juan@example.com',
    'Nacimiento': '15/05/2001',
    'Experiencia': 'Amateur',
    'Peso': 'Peso ligero',
    'Ubicación': 'Madrid'
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
        backgroundColor: Colors.red,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: userData.entries.map((entry) {
          return Card(
            color: Colors.grey[900],
            child: ListTile(
              title: Text(entry.key, style: TextStyle(color: Colors.white70)),
              subtitle: Text(entry.value, style: TextStyle(color: Colors.white)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
