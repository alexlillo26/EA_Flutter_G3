// lib/main.dart

import 'package:flutter/material.dart';
import 'routes.dart';
import 'screens/gym_login_screen.dart';
import 'session.dart'; // Session ya no se usa aquí, pero lo dejamos por si acaso
import 'screens/gym_home_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/splash_screen.dart'; // <-- 1. IMPORTA LA NUEVA PANTALLA

void main() async {
  // Ya no necesitas cargar la sesión aquí, la SplashScreen se encargará.
  WidgetsFlutterBinding.ensureInitialized();
  // await Session.loadSession(); // <-- 2. ELIMINA ESTA LÍNEA
  runApp(const Face2FaceApp());
}

class Face2FaceApp extends StatelessWidget {
  const Face2FaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face2Face',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
      ),
      // 3. CAMBIA LA RUTA INICIAL
      initialRoute: '/', // Usaremos '/' como la ruta para la SplashScreen
      routes: {
        // 4. AÑADE LA RUTA PARA LA SPLASH SCREEN
        '/': (context) => const SplashScreen(),
        ...appRoutes,
        '/gym-login': (context) => const GymLoginScreen(),
        '/gym-home': (context) => const GymHomeScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
      },
    );
  }
}