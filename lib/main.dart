import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Tus importaciones existentes
import 'routes.dart'; // Contiene appRoutes
import 'screens/gym_login_screen.dart'; //
import 'screens/gym_home_screen.dart';
import 'screens/edit_profile_screen.dart';

// Importaciones para pantallas y sesión
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'session.dart';

// TODO: Crea estas pantallas para el flujo de completar perfil
import 'screens/complete_user_profile_screen.dart'; 
// import 'screens/complete_gym_profile_screen.dart'; // Descomenta si también la implementas

void main() {
  runApp(const Face2FaceApp());
}

class Face2FaceApp extends StatefulWidget {
  const Face2FaceApp({super.key});

  @override
  State<Face2FaceApp> createState() => _Face2FaceAppState();
}

class _Face2FaceAppState extends State<Face2FaceApp> {
  String? _initialRoute;
  bool _isCheckingInitialRoute = true;

  @override
  void initState() {
    super.initState();
    _handleInitialUrl();
  }

  Future<void> _handleInitialUrl() async {
    String determinedRoute = '/login'; 

    if (kIsWeb) {
      try {
        final Uri initialUri = Uri.base;
        final queryParams = initialUri.queryParameters;

        final String? token = queryParams['token'];
        final String? refreshToken = queryParams['refreshToken'];
        final String? idFromUrl = queryParams['userId']; 
        final String? nameFromUrl = queryParams['username'];
        final String? accountType = queryParams['type']; 
        final bool isNewEntity = queryParams['isNewEntity'] == 'true'; // Leer el flag

        if (token != null && token.isNotEmpty &&
            idFromUrl != null && idFromUrl.isNotEmpty &&
            nameFromUrl != null && nameFromUrl.isNotEmpty &&
            accountType != null && accountType.isNotEmpty) {
          
          Session.token = token;
          Session.refreshToken = refreshToken;
          Session.username = nameFromUrl;

          if (accountType == 'user') {
            Session.userId = idFromUrl;
            Session.gymId = null; 
            if (isNewEntity) {
              determinedRoute = '/complete-user-profile'; // Dirigir a completar perfil de usuario
            } else {
              determinedRoute = '/home';
            }
          } else if (accountType == 'gym') {
            Session.gymId = idFromUrl;
            Session.userId = null; 
            if (isNewEntity) {
              // determinedRoute = '/complete-gym-profile'; // Dirigir a completar perfil de gimnasio
              // Por ahora, si no tienes CompleteGymProfileScreen, irá a gym-home
               print("[MainApp] New Gym detected, but /complete-gym-profile not implemented yet. Defaulting to /gym-home.");
               determinedRoute = '/gym-home';
            } else {
              determinedRoute = '/gym-home';
            }
          } else {
            Session.clear(); 
            determinedRoute = '/login';
          }
        } else {
          determinedRoute = '/login';
        }
      } catch (e) {
        print("[MainApp] Error parsing initial URI: $e");
        determinedRoute = '/login';
      }
    }

    if (mounted) {
      setState(() {
        _initialRoute = determinedRoute;
        _isCheckingInitialRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingInitialRoute) {
      return MaterialApp(
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.red,
          scaffoldBackgroundColor: Colors.black,
        ),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.red)),
        ),
      );
    }

    return MaterialApp(
      title: 'Face2Face',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: _initialRoute, 
      routes: {
        ...appRoutes, // Tus rutas de routes.dart
        
        '/gym-login': (context) => const GymLoginScreen(), //
        '/gym-home': (context) => const GymHomeScreen(),
        '/edit-profile': (context) => EditProfileScreen(),
        
        // Nuevas rutas para completar perfiles
        '/complete-user-profile': (context) => const CompleteUserProfileScreen(),
        // '/complete-gym-profile': (context) => const CompleteGymProfileScreen(), // Descomenta si la implementas
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) {
          return const LoginScreen(); 
        });
      },
    );
  }
}