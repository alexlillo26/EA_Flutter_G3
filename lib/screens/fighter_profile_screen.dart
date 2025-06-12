import 'package:flutter/material.dart';
import 'package:face2face_app/models/fighter_model.dart';
import 'package:face2face_app/services/combat_service.dart';

class FighterProfileScreen extends StatefulWidget {
  final Fighter fighter;
  const FighterProfileScreen({super.key, required this.fighter});

  @override
  State<FighterProfileScreen> createState() => _FighterProfileScreenState();
}

class _FighterProfileScreenState extends State<FighterProfileScreen> {
  late Future<List<Map<String, dynamic>>> _combatsFuture;

  @override
  void initState() {
    super.initState();
    _combatsFuture = _fetchCombats();
  }

  Future<List<Map<String, dynamic>>> _fetchCombats() async {
    final service = CombatService();
    final allCombats = await service.getCombatHistory();
    return allCombats
        .where((c) => c.creatorId == widget.fighter.id || c.opponentId == widget.fighter.id)
        .map((c) => {
              'opponent': c.creatorId == widget.fighter.id ? c.opponentName : c.creatorName,
              'date': c.date,
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final fighter = widget.fighter;
    return Scaffold(
      backgroundColor: Colors.grey[950],
      appBar: AppBar(
        title: Text('Perfil de ${fighter.name}'),
        backgroundColor: Colors.red[800],
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: Colors.white24,
                backgroundImage: (fighter.profilePicture != null && fighter.profilePicture!.isNotEmpty)
                    ? NetworkImage(fighter.profilePicture!)
                    : null,
                child: (fighter.profilePicture == null || fighter.profilePicture!.isEmpty)
                    ? const Icon(Icons.person, size: 56, color: Colors.white70)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              fighter.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              fighter.city,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[200],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.grey[900],
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Combates realizados',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _combatsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text(
                          'Sin combates',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        );
                      }
                      final combats = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: combats.map((c) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.sports_mma, color: Colors.redAccent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'vs ${c['opponent']}',
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                                Text(
                                  '${c['date'].toString().substring(0, 10)}',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
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