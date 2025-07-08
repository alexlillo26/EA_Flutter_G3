import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../session.dart';
import 'package:face2face_app/config/app_config.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController fightsController = TextEditingController();

  String selectedGender = 'Hombre';

  // Lista de categorías de peso según tu imagen
  final List<String> weightCategories = [
    '-48 kg',
    '48 – 51 kg',
    '51 – 54 kg',
    '54 – 57 kg',
    '57 – 60 kg',
    '60 – 63.5 kg',
    '63.5 – 67 kg',
    '67 – 71 kg',
    '71 – 75 kg',
    '75 – 80 kg',
    '80 – 92 kg',
    '+92 kg',
  ];
  String? selectedWeight;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);
    final userId = Session.userId;
    final token = Session.token;
    final response = await http.get(
      Uri.parse('$API_BASE_URL/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        nameController.text = data['name'] ?? '';
        birthDateController.text = data['birthDate']?.toString().substring(0, 10) ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? '';
        cityController.text = data['city'] ?? '';
        fightsController.text = data['fights']?.toString() ?? '';
        selectedGender = data['gender'] ?? 'Hombre';
        // Selecciona la categoría de peso correspondiente
        final userWeight = data['weight']?.toString();
        if (userWeight != null && weightCategories.contains(userWeight)) {
          selectedWeight = userWeight;
        } else {
          selectedWeight = weightCategories.first;
        }
      });
    }
    setState(() => isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final userId = Session.userId;
    final token = Session.token;
    final response = await http.put(
      Uri.parse('$API_BASE_URL/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': nameController.text,
        'birthDate': birthDateController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'city': cityController.text,
        'weight': selectedWeight,
        'fights': fightsController.text,
        'gender': selectedGender,
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
      Navigator.pop(context, true);
    } else {
      final msg = json.decode(response.body)['message'] ?? 'Error al actualizar perfil';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Introduce tu nombre' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: birthDateController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Fecha de nacimiento'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(birthDateController.text) ?? DateTime(2000),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          birthDateController.text =
                              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Introduce tu correo' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      items: ['Hombre', 'Mujer']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Sexo'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: cityController,
                      decoration: const InputDecoration(labelText: 'Ciudad'),
                    ),
                    const SizedBox(height: 16),
                    // CAMBIO: Selector de peso en vez de campo de texto
                    DropdownButtonFormField<String>(
                      value: selectedWeight,
                      items: weightCategories
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedWeight = value!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Peso (kg)'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Selecciona tu peso' : null,
                    ),
                    const SizedBox(height: 16),
                    // CAMPO NÚMERO DE COMBATES EDITABLE
                    TextFormField(
                      controller: fightsController,
                      decoration: const InputDecoration(
                        labelText: 'Número de combates',
                        hintText: 'Ejemplo: 12',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Introduce el número de combates';
                        final num? combates = num.tryParse(value);
                        if (combates == null || combates < 0) return 'Introduce un número válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _saveProfile,
                        child: const Text(
                          'Guardar cambios',
                          style: TextStyle(fontSize: 18, color: Colors.white),
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