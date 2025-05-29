import 'package:flutter/material.dart';
import 'dart:convert'; // Para codificar/decodificar JSON
import 'package:http/http.dart' as http; // Para hacer llamadas API
import 'package:url_launcher/url_launcher.dart'; // Para abrir URLs
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Para el icono de Google
import '../session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  Future<void> _loginUser() async {
    if (!emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un correo válido')),
      );
      return;
    }
    if (passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener mínimo 8 caracteres')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://localhost:9000/api/users/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        Session.token = body['token'];
        Session.refreshToken = body['refreshToken'];
        Session.userId = body['userId'];
        Session.username = body['username'];

        if (Session.token == null || Session.token!.isEmpty ||
            Session.userId == null || Session.userId!.isEmpty ||
            Session.username == null || Session.username!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error en login: Datos incompletos del servidor.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión exitoso')),
        );

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        String errorMessage = 'Correo o contraseña incorrectos';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });

    // Modifica esta URL base si tu backend está en otro puerto o host
    const String baseUrl = 'http://localhost:9000';
    // El `origin` debe coincidir con el que configuraste en el backend para Flutter
    final String googleAuthUrl = '$baseUrl/api/auth/google?origin=flutter_local_web';

    final Uri uri = Uri.parse(googleAuthUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        // Para Flutter Web, es importante usar webOnlyWindowName para asegurar
        // que la redirección ocurra en la misma ventana/pestaña si es posible,
        // o que se maneje correctamente la nueva pestaña.
        // Para mobile, esto se ignora o se maneja diferente por el S.O.
        webOnlyWindowName: '_self', // Para intentar abrir en la misma pestaña en web
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la URL: $googleAuthUrl')),
      );
    }
    // No cambies _isGoogleLoading a false aquí,
    // la app se recargará con los tokens en la URL si el login es exitoso.
    // O el usuario volverá manualmente si cancela.
    // Considera un timeout o una forma de resetear si el usuario cierra la pestaña.
     Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isGoogleLoading) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/boxing_bg.jpg', // Asegúrate que esta imagen exista
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.6)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/gym-login');
                        },
                        child: const Text(
                          '¿Eres un gimnasio?',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Correo Electrónico',
                      filled: true,
                      fillColor: Colors.black, // Fondo negro para los campos
                      hintStyle: TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email, color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Contraseña',
                      filled: true,
                      fillColor: Colors.black, // Fondo negro
                      hintStyle: TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.red))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _loginUser,
                            child: const Text(
                              'Ingresar',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Botón de Iniciar Sesión con Google
                  SizedBox(
                    width: double.infinity,
                    child: _isGoogleLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                        : ElevatedButton.icon(
                            icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white),
                            label: const Text(
                              'Iniciar sesión con Google',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // Color de Google
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _signInWithGoogle,
                          ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: '¿No tienes cuenta? ',
                        style: TextStyle(color: Colors.white),
                        children: [
                          TextSpan(
                            text: 'Regístrate',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}