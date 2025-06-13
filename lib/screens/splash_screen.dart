// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:face2face_app/session.dart';
import 'package:http/http.dart' as http;
import 'package:face2face_app/config/app_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Añadimos "with TickerProviderStateMixin" para poder usar los controladores de animación
class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Declaramos los controladores para las animaciones
  late final AnimationController _logoController;
  late final AnimationController _textController;

  // Declaramos las animaciones que modificaremos
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // --- Configuración de Animaciones ---
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Definimos cómo cambian los valores de la animación del logo
    _logoScaleAnimation =
        Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack, // Un efecto de "rebote" suave al final
    ));
    _logoFadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    ));

    // Definimos la animación para el texto
    _textFadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));
    
    // Enlazamos las animaciones: cuando la del logo termine, empieza la del texto
    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _textController.forward();
      }
    });

    // Iniciamos la primera animación
    _logoController.forward();
    
    // La lógica de inicialización de la app sigue funcionando igual
    _initializeApp();
  }

  @override
  void dispose() {
    // Es MUY importante desechar los controladores para liberar recursos
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Aumentamos ligeramente el delay para dar tiempo a las animaciones
    await Future.delayed(const Duration(milliseconds: 3500));
    
    await Session.loadSession();
    if (!mounted) return;

    if (!Session.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/users/${Session.userId}'),
        headers: {'Authorization': 'Bearer ${Session.token}'},
      );
      if (mounted) {
        if (response.statusCode == 200) {
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          await Session.clearSession();
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      if (mounted) {
        await Session.clearSession();
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 1. Fondo con Gradiente Radial
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              Color(0xFF2C2C2C), // Un gris muy oscuro en el centro
              Colors.black,      // Negro en los bordes
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2. Animación Compuesta para el Logo
              FadeTransition(
                opacity: _logoFadeAnimation,
                child: ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: Image.asset(
                    'assets/images/logo.png', // Asegúrate de que esta ruta sea correcta
                    width: 180,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 3. Animación Secuencial para el Texto
              FadeTransition(
                opacity: _textFadeAnimation,
                child: const Text(
                  'Face2Face',
                  style: TextStyle(
                    fontFamily: 'Roboto', // Puedes experimentar con fuentes
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 80),
              // 4. Indicador de Carga Sutil
              FadeTransition(
                opacity: _textFadeAnimation, // Aparece junto con el texto
                child: const SizedBox(
                  width: 150,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    minHeight: 2.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}