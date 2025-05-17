import 'package:flutter/material.dart';
import 'routes.dart';
import 'screens/gym_login_screen.dart'; // Importa la nueva pantalla de gimnasios
import 'screens/gym_home_screen.dart';
import 'screens/edit_profile_screen.dart';

void main() {
  runApp(Face2FaceApp());
}

class Face2FaceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face2Face',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/login',
      routes: {
        ...appRoutes, // Mantén las rutas existentes
        '/gym-login': (context) => const GymLoginScreen(), // Nueva ruta para gimnasios
        '/gym-home': (context) => const GymHomeScreen(), // Nueva ruta para el home del gimnasio
        '/edit-profile': (context) => EditProfileScreen(),

      },
    );
  }
}