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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
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
          Container(color: Colors.black.withOpacity(0.82)),
          isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.red))
              : userData == null
                  ? const Center(child: Text('No se pudo cargar el perfil', style: TextStyle(color: Colors.white70)))
                  : RefreshIndicator(
                      onRefresh: _loadProfileData,
                      color: Colors.red,
                      child: ListView(
                        padding: const EdgeInsets.all(0),
                        children: [
                          const SizedBox(height: 38),
                          // Avatar y nombre
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.32),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                    border: Border.all(color: Colors.redAccent, width: 2),
                                  ),
                                  child: userData!['profilePicture'] != null &&
                                          userData!['profilePicture'].toString().isNotEmpty
                                      ? CircleAvatar(
                                          radius: 60,
                                          backgroundImage: NetworkImage(
                                            '${userData!['profilePicture']}?v=${DateTime.now().millisecondsSinceEpoch}',
                                          ),
                                        )
                                      : const CircleAvatar(
                                          radius: 60,
                                          backgroundColor: Colors.white24,
                                          child: Icon(Icons.person, size: 60, color: Colors.white70),
                                        ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  userData!['name'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '@${userData!['username'] ?? ''}',
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          // Contadores followers/following
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
                                    label: 'Seguidores',
                                    count: followers,
                                    onTap: () => _showFollowersList(context),
                                  ),
                                  Container(
                                    height: 32,
                                    width: 1.5,
                                    color: Colors.redAccent.withOpacity(0.3),
                                    margin: const EdgeInsets.symmetric(horizontal: 18),
                                  ),
                                  _counterColumn(
                                    context,
                                    label: 'Siguiendo',
                                    count: following,
                                    onTap: () => _showFollowingList(context),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 22),
                          // Card combinada de valoraciones y datos personales
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Card(
                              color: Colors.black.withOpacity(0.88),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 10,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Valoraciones (si existen)
                                    if (userRatingsResponse != null && userRatingsResponse!.totalRatings > 0)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber.shade400, size: 28),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Valoraciones',
                                                style: TextStyle(
                                                  color: Colors.amber.shade400,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '(${userRatingsResponse!.totalRatings})',
                                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          _buildStarRatingRow("Puntualidad", userRatingsResponse!.averagePunctuality),
                                          _buildStarRatingRow("Actitud", userRatingsResponse!.averageAttitude),
                                          _buildStarRatingRow("Técnica", userRatingsResponse!.averageTechnique),
                                          _buildStarRatingRow("Intensidad", userRatingsResponse!.averageIntensity),
                                          _buildStarRatingRow("Deportividad", userRatingsResponse!.averageSportmanship),
                                          const Divider(color: Colors.white24, height: 32, thickness: 1),
                                        ],
                                      ),
                                    // Datos personales alineados
                                    _profileRow(Icons.email, 'Correo', userData!['email']),
                                    _profileRow(Icons.cake, 'Nacimiento', userData!['birthDate']?.toString().substring(0, 10) ?? ''),
                                    _profileRow(Icons.scale, 'Peso', userData!['weight']),
                                    _profileRow(Icons.location_city, 'Ciudad', userData!['city']),
                                    _profileRow(Icons.phone, 'Teléfono', userData!['phone']),
                                    _profileRow(Icons.person, 'Género', userData!['gender']),
                                    _profileRow(Icons.workspace_premium, 'Rol', userData!['isAdmin'] == true ? 'Administrador' : 'Usuario'),
                                    const SizedBox(height: 18),
                                    // Video
                                    _videoSection(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Botón editar perfil (ahora justo encima de cerrar sesión)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 6,
                              ),
                              onPressed: () async {
                                final result = await Navigator.pushNamed(context, '/edit-profile');
                                if (result == true) {
                                  _loadProfileData();
                                }
                              },
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: const Text(
                                'Editar perfil',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Botón cerrar sesión al final
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 6,
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
                              icon: const Icon(Icons.logout, color: Colors.white),
                              label: const Text(
                                'Cerrar sesión',
                                style: TextStyle(color: Colors.white, fontSize: 17),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent, size: 22),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(color: Colors.white, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET DE TARJETA DE VALORACIÓN MODIFICADO ---
  Widget _buildRatingsCard(UserRatingsResponse ratings) {
    return Card(
      color: Colors.grey[900]?.withOpacity(0.85),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
      if (rating >= i) {
        iconData = Icons.star;
      } else if (rating >= i - 0.5) {
        iconData = Icons.star_half;
      }
      stars.add(Icon(iconData, color: Colors.amber, size: 22));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 17)),
          Row(children: stars),
        ],
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
          const SizedBox(height: 12), // Más espacio antes de "Quitar video"
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
    await showModalBottomSheet(
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
    await showModalBottomSheet(
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