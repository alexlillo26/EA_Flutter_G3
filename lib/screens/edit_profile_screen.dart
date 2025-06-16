import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../session.dart';
import 'package:face2face_app/config/app_config.dart'; 


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: Colors.black.withOpacity(0.18),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/boxing_bg.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.8)),
          isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.red))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Card(
                        color: Colors.black.withOpacity(0.88),
                        elevation: 10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    _pickedFile != null
                                        ? CircleAvatar(
                                            radius: 54,
                                            backgroundImage: _pickedFile!.bytes != null
                                                ? MemoryImage(_pickedFile!.bytes!)
                                                : FileImage(File(_pickedFile!.path!)) as ImageProvider,
                                          )
                                        : (userData?['profilePicture'] != null &&
                                                userData!['profilePicture'].toString().isNotEmpty)
                                            ? CircleAvatar(
                                                radius: 54,
                                                backgroundImage: NetworkImage(userData!['profilePicture']),
                                              )
                                            : const CircleAvatar(
                                                radius: 54,
                                                backgroundColor: Colors.white24,
                                                child: Icon(Icons.person, size: 54, color: Colors.white70),
                                              ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              _buildProfileField(
                                label: 'Nombre',
                                controller: nameController,
                                icon: Icons.person,
                                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                              ),
                              const SizedBox(height: 18),
                              _buildProfileField(
                                label: 'Ciudad',
                                controller: cityController,
                                icon: Icons.location_city,
                                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                              ),
                              const SizedBox(height: 18),
                              _buildProfileField(
                                label: 'Teléfono',
                                controller: phoneController,
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 6,
                                  ),
                                  onPressed: _saveProfile,
                                  icon: const Icon(Icons.save, color: Colors.white),
                                  label: const Text(
                                    'Guardar cambios',
                                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 17),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: Colors.redAccent),
        filled: true,
        fillColor: Colors.grey[900]?.withOpacity(0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}