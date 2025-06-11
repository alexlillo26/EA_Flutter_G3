import 'package:flutter/material.dart';
import 'routes.dart';
import 'screens/gym_login_screen.dart'; // Importa la nueva pantalla de gimnasios
import 'screens/login_screen.dart'; // Importa donde está Session
import 'utils/session_manager.dart'; // <-- Nuevo import
import 'screens/gym_home_screen.dart';
import 'screens/edit_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.loadSession();
  runApp(const Face2FaceApp());
}

class Face2FaceApp extends StatelessWidget {
  const Face2FaceApp({Key? key}) : super(key: key);

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