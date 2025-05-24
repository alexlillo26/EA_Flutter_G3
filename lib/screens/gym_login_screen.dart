import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:face2face_app/config/app_config.dart';
import 'package:http/http.dart' as http;
import '../session.dart'; 

class GymLoginScreen extends StatefulWidget {
  const GymLoginScreen({super.key});

  @override
  _GymLoginScreenState createState() => _GymLoginScreenState();
}

class _GymLoginScreenState extends State<GymLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  bool _isRegistering = false; // Cambia entre login y registro
  bool _isLoading = false;

    Future<void> _submitGym() async {
    setState(() {
        _isLoading = true;
    });

    try {
        final url = Uri.parse(
        _isRegistering ? '$API_BASE_URL/gym' : '$API_BASE_URL/gym/login');        final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
            'email': emailController.text,
            'password': passwordController.text,
            if (_isRegistering) 'name': nameController.text,
            if (_isRegistering) 'phone': phoneController.text,
            if (_isRegistering) 'place': placeController.text,
            if (_isRegistering) 'price': double.tryParse(priceController.text) ?? 0,
        }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        print('Respuesta backend: $body');
        // Guarda el id del gimnasio si es login (no registro)
        if (body['gym'] != null && body['gym']['_id'] != null) {
         Session.gymId = body['gym']['_id'];
      }

        if (Session.gymId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_isRegistering ? 'Registro exitoso' : 'Inicio de sesión exitoso')),
          );
          Navigator.pushReplacementNamed(context, '/gym-home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo obtener el ID del gimnasio')),
          );
        }
        } else if (response.statusCode == 401) {
        } else if (response.statusCode == 400) {
        } else {
        String errorMessage = 'Error desconocido';
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
        setState(() {
        _isLoading = false;
        });
    }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistering ? 'Registro de Gimnasio' : 'Login de Gimnasio'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/boxing_bg.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.6)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRegistering)
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Gimnasio',
                        filled: true,
                        fillColor: Colors.black,
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  if (_isRegistering) const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      filled: true,
                      fillColor: Colors.black,
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      filled: true,
                      fillColor: Colors.black,
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (_isRegistering) const SizedBox(height: 16),
                  if (_isRegistering)
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        filled: true,
                        fillColor: Colors.black,
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  if (_isRegistering) const SizedBox(height: 16),
                  if (_isRegistering)
                    TextField(
                      controller: placeController,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación',
                        filled: true,
                        fillColor: Colors.black,
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  if (_isRegistering) const SizedBox(height: 16),
                  if (_isRegistering)
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        filled: true,
                        fillColor: Colors.black,
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
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
                            onPressed: _submitGym,
                            child: Text(
                              _isRegistering ? 'Registrar Gimnasio' : 'Iniciar Sesión',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isRegistering = !_isRegistering;
                      });
                    },
                    child: RichText(
                      text: TextSpan(
                        text: _isRegistering ? '¿Ya tienes cuenta? ' : '¿No tienes cuenta? ',
                        style: const TextStyle(color: Colors.white),
                        children: [
                          TextSpan(
                            text: _isRegistering ? 'Inicia Sesión' : 'Regístrate',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
}