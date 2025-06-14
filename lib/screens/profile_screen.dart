import 'package:face2face_app/models/user_ratings_model.dart';
import 'package:face2face_app/services/rating_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:face2face_app/config/app_config.dart';
import 'package:http/http.dart' as http;
import '../session.dart';
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
  String? _videoUrl;
  bool _isUploadingVideo = false;

  final RatingService _ratingService = RatingService();
  UserRatingsResponse? userRatingsResponse;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!isLoading) setState(() => isLoading = true);
    final userId = Session.userId;
    if (userId == null || Session.token == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
    try {
      await Future.wait([
        _fetchUserData(),
        _fetchUserRatings(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar el perfil: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchUserData() async {
    final response = await http.get(
      Uri.parse('$API_BASE_URL/users/${Session.userId}'),
      headers: {
        'Authorization': 'Bearer ${Session.token}',
        'Content-Type': 'application/json',
      },
    );
    if (mounted && response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userData = data;
        _videoUrl = data?['boxingVideo'];
      });
    } else {
      throw Exception('Error al cargar datos de usuario. Status: ${response.statusCode}');
    }
  }

  Future<void> _fetchUserRatings() async {
    try {
      final ratings = await _ratingService.getUserRatings(Session.userId!);
      if (mounted) {
        setState(() {
          userRatingsResponse = ratings;
        });
      }
    } catch (e) {
      print("No se pudieron cargar las valoraciones del usuario: $e");
    }
  }

  Future<void> _pickAndUploadVideo() async {
    setState(() => _isUploadingVideo = true);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) {
      setState(() => _isUploadingVideo = false);
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
      await _loadProfileData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir el video')),
      );
    }
    if (mounted) setState(() => _isUploadingVideo = false);
  }

  Future<void> _removeVideo() async {
    setState(() => _isUploadingVideo = true);
    final userId = Session.userId;
    final token = Session.token;
    final uri = Uri.parse('$API_BASE_URL/users/$userId/boxing-video');
    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      await _loadProfileData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al quitar el video')),
      );
    }
    if (mounted) setState(() => _isUploadingVideo = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : userData == null
              ? const Center(child: Text('No se pudo cargar el perfil'))
              : RefreshIndicator(
                  onRefresh: _loadProfileData,
                  color: Colors.red,
                  child: ListView(
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
                                child: Icon(Icons.person,
                                    size: 48, color: Colors.white70),
                              ),
                      ),
                      const SizedBox(height: 16),
                      if (userRatingsResponse != null && userRatingsResponse!.totalRatings > 0)
                        _buildRatingsCard(userRatingsResponse!),
                      _videoSection(),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              final result = await Navigator.pushNamed(
                                  context, '/edit-profile');
                              if (result == true) {
                                _loadProfileData();
                              }
                            },
                            child: const Text(
                              'Editar perfil',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              await Session.clearSession();
                              if (mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                );
                              }
                            },
                            child: const Text(
                              'Cerrar sesión',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _profileCard('Nombre', userData!['name']),
                      _profileCard('Correo', userData!['email']),
                      _profileCard(
                          'Nacimiento',
                          userData!['birthDate']
                                  ?.toString()
                                  .substring(0, 10) ??
                              ''),
                      _profileCard('Peso', userData!['weight']),
                      _profileCard('Ciudad', userData!['city']),
                      _profileCard('Teléfono', userData!['phone']),
                      _profileCard('Género', userData!['gender']),
                      _profileCard('Experiencia',
                          userData!['isAdmin'] == true ? 'Administrador' : 'Usuario'),
                    ],
                  ),
                ),
    );
  }

  // --- WIDGET DE TARJETA DE VALORACIÓN MODIFICADO ---
  Widget _buildRatingsCard(UserRatingsResponse ratings) {
    return Card(
      color: Colors.grey[900]?.withOpacity(0.85),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valoraciones Detalladas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Basado en ${ratings.totalRatings} valoraciones',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildStarRatingRow("Puntualidad", ratings.averagePunctuality),
            _buildStarRatingRow("Actitud", ratings.averageAttitude),
            _buildStarRatingRow("Técnica", ratings.averageTechnique),
            _buildStarRatingRow("Intensidad", ratings.averageIntensity),
            _buildStarRatingRow("Deportividad", ratings.averageSportmanship),
          ],
        ),
      ),
    );
  }

  // --- NUEVO WIDGET PARA DIBUJAR UNA FILA DE ESTRELLAS ---
  Widget _buildStarRatingRow(String label, double rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      IconData iconData = Icons.star_border;
      // Llena la estrella si el rating es mayor o igual al paso actual
      if (rating >= i) {
        iconData = Icons.star;
      // Llena media estrella si está en el rango de 0.5
      } else if (rating >= i - 0.5) {
        iconData = Icons.star_half;
      }
      stars.add(Icon(iconData, color: Colors.amber, size: 20));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Row(children: stars),
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
          label:
              const Text('Añadir video', style: TextStyle(color: Colors.white)),
        ),
      );
    }
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
            label:
                const Text('Ver video', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _pickAndUploadVideo,
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Cambiar video',
                style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            onPressed: _removeVideo,
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Quitar video',
                style: TextStyle(color: Colors.white)),
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
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
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