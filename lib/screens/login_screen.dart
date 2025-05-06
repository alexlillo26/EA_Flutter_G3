import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ✅ Clase global temporal para guardar sesión
class Session {
  static String? token;
  static String? refreshToken;
}

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 32),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Correo Electrónico',
                      filled: true,
                      fillColor: Colors.black,
                      hintStyle: TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      filled: true,
                      fillColor: Colors.black,
                      hintStyle: TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        if (!emailController.text.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Por favor ingresa un correo válido')),
                          );
                          return;
                        }

                        if (passwordController.text.length < 8) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('La contraseña debe tener mínimo 8 caracteres')),
                          );
                          return;
                        }

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

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Inicio de sesión exitoso')),
                          );

                          Navigator.pushReplacementNamed(context, '/home');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Correo o contraseña incorrectos')),
                          );
                        }
                      },
                      child: Text('Ingresar'),
                    ),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: '¿No tienes cuenta? ',
                        style: TextStyle(color: Colors.white),
                        children: [
                          TextSpan(
                            text: 'Regístrate',
                            style: TextStyle(color: Colors.red),
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
