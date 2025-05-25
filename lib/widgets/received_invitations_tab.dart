import 'package:flutter/material.dart';
import 'package:face2face_app/models/combat_invitation_model.dart';
import 'package:face2face_app/services/combat_service.dart';
// import 'package:face2face_app/session.dart'; // No es necesario aquí si CombatService lo maneja

class ReceivedInvitationsTab extends StatefulWidget {
  const ReceivedInvitationsTab({super.key});

  @override
  State<ReceivedInvitationsTab> createState() => _ReceivedInvitationsTabState();
}

class _ReceivedInvitationsTabState extends State<ReceivedInvitationsTab> {
  final CombatService _combatService = CombatService();
  Future<List<CombatInvitation>>? _invitationsFuture;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  void _loadInvitations() {
    if (mounted) {
      setState(() {
        _invitationsFuture = _combatService.getReceivedInvitations();
      });
    }
  }

  Future<void> _handleResponse(String combatId, String status) async {
    try {
      final success = await _combatService.respondToCombatInvitation(combatId, status);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Invitación ${status == "accepted" ? "aceptada" : "rechazada"} con éxito.'),
              backgroundColor: status == "accepted" ? Colors.green : Colors.orange),
        );
        _loadInvitations(); // Recargar la lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al responder: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CombatInvitation>>(
      future: _invitationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        } else if (snapshot.hasError) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error al cargar invitaciones: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70)),
          ));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No tienes invitaciones pendientes.',
                  style: TextStyle(color: Colors.white, fontSize: 16)));
        }

        List<CombatInvitation> invitations = snapshot.data!;
        return RefreshIndicator( // Para deslizar y recargar
          onRefresh: () async {
            _loadInvitations();
          },
          color: Colors.red,
          backgroundColor: Colors.grey[900],
          child: ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              return Card(
                color: Colors.grey[850]?.withOpacity(0.9),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invitación de: ${invitation.creatorName}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.calendar_today_outlined, 'Fecha:', invitation.formattedDate),
                      _buildInfoRow(Icons.access_time_outlined, 'Hora:', invitation.formattedTime),
                      _buildInfoRow(Icons.fitness_center_outlined, 'Gimnasio:', invitation.gymName),
                      _buildInfoRow(Icons.shield_outlined, 'Nivel:', invitation.level),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                            label: const Text('Rechazar', style: TextStyle(color: Colors.redAccent)),
                            onPressed: () => _handleResponse(invitation.id, 'rejected'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                            label: const Text('Aceptar', style: TextStyle(color: Colors.white)),
                            onPressed: () => _handleResponse(invitation.id, 'accepted'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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