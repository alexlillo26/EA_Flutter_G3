import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../session.dart';
import 'package:face2face_app/config/app_config.dart'; 


class EditProfileScreen extends StatefulWidget {
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? userData;
  bool isLoading = true;
  PlatformFile? _pickedFile;

  // Controladores para los campos editables
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final userId = Session.userId;
    final token = Session.token;
    if (userId == null || token == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final response = await http.get(
        Uri.parse('$API_BASE_URL/users/$userId'),      
        headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      userData = json.decode(response.body);
      nameController.text = userData!['name'] ?? '';
      cityController.text = userData!['city'] ?? '';
      phoneController.text = userData!['phone'] ?? '';
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // Necesario para web
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Session.userId;
    final token = Session.token;
    if (userId == null || token == null) return;

    var uri = Uri.parse('$API_BASE_URL/users/$userId');    
    var request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = nameController.text;
    request.fields['city'] = cityController.text;
    request.fields['phone'] = phoneController.text;

    if (_pickedFile != null) {
      if (_pickedFile!.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'profilePicture',
            _pickedFile!.bytes!,
            filename: _pickedFile!.name,
          ),
        );
      } else if (_pickedFile!.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profilePicture',
            _pickedFile!.path!,
          ),
        );
      }
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perfil actualizado')),
      );
      Navigator.pop(context, true); // Vuelve al perfil y refresca
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el perfil')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar perfil'),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Foto de perfil
                    GestureDetector(
                      onTap: _pickImage,
                      child: _pickedFile != null
                          ? CircleAvatar(
                              radius: 48,
                              backgroundImage: _pickedFile!.bytes != null
                                  ? MemoryImage(_pickedFile!.bytes!)
                                  : FileImage(File(_pickedFile!.path!)) as ImageProvider,
                            )
                          : (userData?['profilePicture'] != null &&
                                  userData!['profilePicture'].toString().isNotEmpty)
                              ? CircleAvatar(
                                  radius: 48,
                                  backgroundImage: NetworkImage(userData!['profilePicture']),
                                )
                              : const CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Colors.white24,
                                  child: Icon(Icons.person, size: 48, color: Colors.white70),
                                ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        filled: true,
                        fillColor: Colors.black,
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: cityController,
                      decoration: InputDecoration(
                        labelText: 'Ciudad',
                        filled: true,
                        fillColor: Colors.black,
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        filled: true,
                        fillColor: Colors.black,
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _saveProfile,
                        child: const Text(
                          'Guardar cambios',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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