import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../session.dart'; // Para acceder a Session.userId y Session.token

class CompleteUserProfileScreen extends StatefulWidget {
  const CompleteUserProfileScreen({super.key});

  @override
  State<CompleteUserProfileScreen> createState() => _CompleteUserProfileScreenState();
}

class _CompleteUserProfileScreenState extends State<CompleteUserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores para los campos del formulario
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedGender; // Para el DropdownButtonFormField

  // Opciones para el género y peso (ajusta según tu modelo User)
  final List<String> _genderOptions = ['Hombre', 'Mujer', 'Otro']; //
  final List<String> _weightOptions = ['Peso pluma', 'Peso medio', 'Peso pesado']; //
  String? _selectedWeight;


  @override
  void dispose() {
    _weightController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // Si el formulario no es válido, no hacer nada.
    }

    setState(() {
      _isLoading = true;
    });

    if (Session.userId == null || Session.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Sesión no válida. Por favor, inicia sesión de nuevo.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
      setState(() { _isLoading = false; });
      return;
    }

    final url = Uri.parse('http://localhost:9000/api/users/${Session.userId}');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${Session.token}',
    };
    final body = jsonEncode({
      'weight': _selectedWeight, // Usar el valor seleccionado
      'city': _cityController.text,
      'phone': _phoneController.text,
      'gender': _selectedGender,
      // Puedes añadir otros campos que necesites actualizar aquí
      // No envíes 'password', 'email', 'name', 'googleId' a menos que tu endpoint los espere
    });

    try {
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Perfil actualizado con éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil completado con éxito.')),
        );
        Navigator.pushReplacementNamed(context, '/home'); // Ir a la pantalla principal
      } else {
        // Error del backend
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ?? 'Error al actualizar el perfil.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${response.statusCode}: $errorMessage')),
        );
      }
    } catch (e) {
      // Error de conexión o similar
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Perfil de Boxeador'),
        backgroundColor: Colors.red,
        automaticallyImplyLeading: false, // Para no mostrar botón de atrás por defecto
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset( // Puedes usar el mismo fondo u otro
            'assets/images/boxing_bg.jpg', 
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.75)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      '¡Casi listo! Completa tu información',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Selector de Peso
                    DropdownButtonFormField<String>(
                      value: _selectedWeight,
                      items: _weightOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(color: Colors.black87)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedWeight = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Categoría de Peso',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        labelStyle: const TextStyle(color: Colors.black54),
                      ),
                      dropdownColor: Colors.white,
                      validator: (value) => value == null || value.isEmpty ? 'Por favor selecciona tu peso' : null,
                    ),
                    const SizedBox(height: 16),

                    // Ciudad
                    TextFormField(
                      controller: _cityController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Ciudad',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.location_city, color: Colors.black54),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Por favor ingresa tu ciudad' : null,
                    ),
                    const SizedBox(height: 16),

                    // Teléfono
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Teléfono (9 dígitos)',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.phone, color: Colors.black54),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu teléfono';
                        }
                        if (!RegExp(r'^\d{9}$').hasMatch(value)) { //
                          return 'El teléfono debe tener 9 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Selector de Género
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      items: _genderOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(color: Colors.black87)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Género',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        labelStyle: const TextStyle(color: Colors.black54),
                      ),
                      dropdownColor: Colors.white,
                      validator: (value) => value == null || value.isEmpty ? 'Por favor selecciona tu género' : null,
                    ),
                    const SizedBox(height: 32),
                    
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.red)
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _submitProfile,
                              child: const Text('Guardar y Continuar', style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}