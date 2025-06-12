import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:face2face_app/config/app_config.dart';
import 'package:http/http.dart' as http;
import '../session.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  VideoPlayerController? _videoController;
  String? _videoUrl;
  bool _isUploadingVideo = false;

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
      setState(() {
        userData = json.decode(response.body);
        _videoUrl = userData?['boxingVideo'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el perfil')),
      );
    }
  }

  Future<void> _pickAndUploadVideo() async {
    setState(() {
      _isUploadingVideo = true;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: true, // Necesario para web
    );

    if (result == null || result.files.single.bytes == null) {
      setState(() {
        _isUploadingVideo = false;
      });
      return;
    }

    final userId = Session.userId;
    final token = Session.token;
    final uri = Uri.parse('$API_BASE_URL/users/$userId/boxing-video');
    final request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'video',
        result.files.single.bytes!,
        filename: result.files.single.name,
      ));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final updatedUser = json.decode(respStr);
      setState(() {
        _videoUrl = updatedUser['boxingVideo'];
        _isUploadingVideo = false;
      });
      fetchUserData(); // Refresca datos
    } else {
      setState(() {
        _isUploadingVideo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir el video')),
      );
    }
  }

  Future<void> _removeVideo() async {
    setState(() {
      _isUploadingVideo = true;
    });

    final userId = Session.userId;
    final token = Session.token;
    final uri = Uri.parse('$API_BASE_URL/users/$userId/boxing-video');
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _videoUrl = null;
        _isUploadingVideo = false;
      });
      fetchUserData();
    } else {
      setState(() {
        _isUploadingVideo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al quitar el video')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text('No se pudo cargar el perfil'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: userData!['profilePicture'] != null &&
                              userData!['profilePicture'].toString().isNotEmpty
                          ? CircleAvatar(
                              radius: 48,
                              backgroundImage: NetworkImage(
                                '${userData!['profilePicture']}?v=${DateTime.now().millisecondsSinceEpoch}',
                              ),
                            )
                          : const CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.person, size: 48, color: Colors.white70),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _videoSection(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final result = await Navigator.pushNamed(context, '/edit-profile');
                            if (result == true) {
                              fetchUserData();
                            }
                          },
                          child: const Text(
                            'Editar perfil',
                            style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Session.token = null;
                            Session.userId = null;
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          },
                          child: const Text(
                            'Cerrar sesión',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _profileCard('Nombre', userData!['name']),
                    _profileCard('Correo', userData!['email']),
                    _profileCard('Nacimiento', userData!['birthDate']?.toString().substring(0, 10) ?? ''),
                    _profileCard('Peso', userData!['weight']),
                    _profileCard('Ciudad', userData!['city']),
                    _profileCard('Teléfono', userData!['phone']),
                    _profileCard('Género', userData!['gender']),
                    _profileCard('Experiencia', userData!['isAdmin'] == true ? 'Administrador' : 'Usuario'),
                  ],
                ),
    );
  }

  Widget _profileCard(String title, String? value) {
    return Card(
      color: Colors.grey[900],
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.white70)),
        subtitle: Text(value ?? '-', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _videoSection() {
    if (_isUploadingVideo) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_videoUrl == null || _videoUrl!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _pickAndUploadVideo,
          icon: const Icon(Icons.video_call, color: Colors.white),
          label: const Text('Añadir video', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    // Mostrar solo el botón "Ver video" y los otros botones
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  contentPadding: EdgeInsets.zero,
                  content: SizedBox(
                    width: 320,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: VideoPlayerWidget(videoUrl: _videoUrl!),
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text('Ver video', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _pickAndUploadVideo,
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Cambiar video', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            onPressed: _removeVideo,
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Quitar video', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({required this.videoUrl, super.key});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        // No reproducir automáticamente
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

    @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                VideoProgressIndicator(_controller, allowScrubbing: true),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.black54,
                    onPressed: _togglePlayPause,
                    child: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}