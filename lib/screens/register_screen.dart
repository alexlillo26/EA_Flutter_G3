import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

String formatBirthDate(String input) {
  try {
    List<String> parts = input.split('/');
    if (parts.length != 3) return input; // Si no está separado por '/', lo devuelve igual
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return '$year-$month-$day';
  } catch (e) {
    return input;
  }
}


class RegisterScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthdateController = TextEditingController();
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
                    'REGISTRO',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 32),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Nombre',
                      filled: true,
                      fillColor: Colors.black,
                      hintStyle: TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: birthdateController,
                    decoration: InputDecoration(
                      hintText: 'Fecha de nacimiento (dd/mm/aaaa)',
                      filled: true,
                      fillColor: Colors.black,
                      hintStyle: TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
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
                        final url = Uri.parse('http://localhost:9000/api/users/register');

                         final response = await http.post(
                         url,
                          headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                        'name': nameController.text,
                        'birthDate': formatBirthDate(birthdateController.text),
                        'email': emailController.text,
                        'password': passwordController.text,
                        'isAdmin': false
                                        }),
                );

                    if (response.statusCode == 201) {
                    Navigator.pushNamed(context, '/home');
                 } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Error al registrar: ${response.body}')),
                     );
                    }           
                        
                        },
                      child: Text('Registrarse'),
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
