// lib/widgets/upcoming_combats_tab.dart
import 'package:flutter/material.dart';
import 'package:face2face_app/models/combat_invitation_model.dart';
import 'package:face2face_app/services/combat_service.dart';
import 'package:face2face_app/session.dart';

class UpcomingCombatsTab extends StatefulWidget {
  const UpcomingCombatsTab({super.key});

  @override
  State<UpcomingCombatsTab> createState() => _UpcomingCombatsTabState();
}

class _UpcomingCombatsTabState extends State<UpcomingCombatsTab> {
  final CombatService _combatService = CombatService();
  Future<List<CombatInvitation>>? _upcomingCombatsFuture;

  @override
  void initState() {
    super.initState();
    _loadUpcomingCombats();
  }

  void _loadUpcomingCombats() {
    if (mounted) {
      setState(() {
        _upcomingCombatsFuture = _combatService.getUpcomingCombats();
      });
    }
  }

  String _getOpponentDisplayName(CombatInvitation combat, String currentUserId) {
    if (combat.creatorId == currentUserId) {
      return combat.opponentName;
    } else if (combat.opponentId == currentUserId) {
      return combat.creatorName;
    }
    return "Desconocido";
  }

  // --- NUEVO MÉTODO PARA MANEJAR LA CANCELACIÓN ---
  Future<void> _handleCancelCombat(CombatInvitation combat) async {
    final reasonController = TextEditingController();
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Cancelar Combate', style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Estás seguro de que quieres cancelar este combate?', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Motivo (opcional)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No, volver', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sí, cancelar', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _combatService.cancelCombat(combat.id, reason: reasonController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Combate cancelado.'),
              backgroundColor: Colors.orange,
            ),
          );
          // Recargamos la lista para que el combate desaparezca de "Próximos"
          _loadUpcomingCombats();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CombatInvitation>>(
      future: _upcomingCombatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error al cargar próximos combates: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70)),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No tienes combates programados próximamente.',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          );
        }

        List<CombatInvitation> upcomingCombats = snapshot.data!
            .where((c) => c.status == 'accepted' && c.date.isAfter(DateTime.now()))
            .toList();

        if (upcomingCombats.isEmpty) {
           return const Center(
              child: Text('No tienes combates programados próximamente.',
                  style: TextStyle(color: Colors.white, fontSize: 16)));
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadUpcomingCombats();
          },
          color: Colors.red,
          backgroundColor: Colors.grey[900],
          child: ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: upcomingCombats.length,
            itemBuilder: (context, index) {
              final combat = upcomingCombats[index];
              final opponentDisplayName = _getOpponentDisplayName(combat, Session.userId!);

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Colors.grey[900]!, Colors.red.withOpacity(0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade700, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.red.shade900,
                            child: Icon(Icons.sports_mma, color: Colors.white, size: 28),
                            radius: 24,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Combate vs: $opponentDisplayName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildInfoRow(Icons.calendar_today_outlined, 'Fecha:', combat.formattedDate),
                      _buildInfoRow(Icons.access_time_outlined, 'Hora:', combat.formattedTime),
                      _buildInfoRow(Icons.fitness_center_outlined, 'Gimnasio:', combat.gymName),
                      _buildInfoRow(Icons.shield_outlined, 'Nivel:', combat.level),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: const Text('ACEPTADO',
                                style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.green.shade700,
                          ),
                          TextButton.icon(
                            onPressed: () => _handleCancelCombat(combat),
                            icon: const Icon(Icons.cancel_schedule_send, color: Colors.white),
                            label: const Text('Cancelar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text('$label ', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}