import 'package:face2face_app/screens/edit_profile_screen.dart';
import 'package:face2face_app/screens/gym_home_screen.dart';
import 'package:face2face_app/screens/gym_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'services/notification_service.dart'; // Importamos el servicio

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const Face2FaceApp());
}

class Face2FaceApp extends StatelessWidget {
  const Face2FaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // !! CORRECCIÓN AQUÍ: ACCEDEMOS A LA KEY A TRAVÉS DE LA CLASE !!
      navigatorKey: NotificationService.navigatorKey, 
      title: 'Face2Face',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/login',
      routes: {
        ...appRoutes,
        '/gym-login': (context) => const GymLoginScreen(),
        '/gym-home': (context) => const GymHomeScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
      },
    );
  }
}