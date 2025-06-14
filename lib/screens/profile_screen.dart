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
    Future<Map<String, int>> _fetchFollowersCount() async {
      final userId = Session.userId;
      final token = Session.token;
      final response = await http.get(
        Uri.parse('$API_BASE_URL/followers/count/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'followers': data['followers'] ?? 0,
          'following': data['following'] ?? 0,
        };
      }
      return {'followers': 0, 'following': 0};
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
                    FutureBuilder<Map<String, int>>(
                      future: _fetchFollowersCount(),
                      builder: (context, snapshot) {
                        final followers = snapshot.data?['followers'] ?? 0;
                        final following = snapshot.data?['following'] ?? 0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _counterColumn(
                              context,
                              label: 'Followers',
                              count: followers,
                              onTap: () => _showFollowersList(context),
                            ),
                            const SizedBox(width: 32),
                            _counterColumn(
                              context,
                              label: 'Following',
                              count: following,
                              onTap: () => _showFollowingList(context),
                            ),
                          ],
                        );
                      },
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
                          onPressed: () async {
                            await Session.clearSession();
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
  Widget _counterColumn(BuildContext context, {required String label, required int count, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }
  void _showFollowersList(BuildContext context) async {
    final userId = Session.userId;
    final token = Session.token;
    final response = await http.get(
      Uri.parse('$API_BASE_URL/followers/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    List followers = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      followers = data['followers'] ?? [];
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _userListModal('Seguidores', followers.map((f) => f['follower']).toList()),
    );
    setState(() {});
  }

  void _showFollowingList(BuildContext context) async {
    final userId = Session.userId;
    final token = Session.token;
    final response = await http.get(
      Uri.parse('$API_BASE_URL/followers/following/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    List following = [];
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      following = data['following'] ?? [];
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _userListModal('Siguiendo', following.map((f) => f['following']).toList()),
    );
    setState(() {});
  }

  Widget _userListModal(String title, List users) {
    return SizedBox(
      height: 400,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: users.isEmpty
                ? const Center(child: Text('No hay usuarios', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(user['name'] ?? '-', style: const TextStyle(color: Colors.white)),
                        subtitle: Text('@${user['username'] ?? ''}', style: const TextStyle(color: Colors.white70)),
                      );
                    },
                  ),
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