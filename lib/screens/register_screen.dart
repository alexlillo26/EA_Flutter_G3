import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  String selectedWeight = 'Peso pluma';

  Future<void> registerUser() async {
    final url = Uri.parse('http://localhost:9000/api/users/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': nameController.text,
        'birthDate': birthDateController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'isAdmin': false,
        'weight': selectedWeight,
        'city': cityController.text,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado correctamente')),
      );
      Navigator.pop(context);
    } else {
      final msg = json.decode(response.body)['message'] ?? 'Error desconocido';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $msg')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Registro',
                style: TextStyle(color: Colors.red, fontSize: 24),
              ),
              const SizedBox(height: 20),

              _buildInputField('Nombre', nameController),
              const SizedBox(height: 12),

              _buildDateField('Fecha de nacimiento', birthDateController),
              const SizedBox(height: 12),

              _buildInputField('Correo electrónico', emailController),
              const SizedBox(height: 12),

              _buildInputField('Contraseña', passwordController, obscure: true),
              const SizedBox(height: 12),

              _buildInputField('Ciudad', cityController),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: selectedWeight,
                items: ['Peso pluma', 'Peso medio', 'Peso pesado']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedWeight = value!;
                  });
                },
                decoration: _inputDecoration('Peso'),
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Registrarse'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, TextEditingController controller, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint),
    );
  }

  Widget _buildDateField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
