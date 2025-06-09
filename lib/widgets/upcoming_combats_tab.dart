import 'package:flutter/material.dart';
import 'package:face2face_app/models/combat_invitation_model.dart'; // Reutilizamos el modelo
import 'package:face2face_app/services/combat_service.dart';
import 'package:face2face_app/session.dart'; // Para saber quién es el usuario actual

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
      return combat.opponentName; // Asume que opponentName está en el modelo
    } else if (combat.opponentId == currentUserId) {
      return combat.creatorName;
    }
    return "Desconocido"; // Fallback
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CombatInvitation>>(
      future: _upcomingCombatsFuture,
      builder: (context, snapshot) {
        print('Entrando al builder de UpcomingCombatsTab');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        } else if (snapshot.hasError) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error al cargar próximos combates: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70)),
          ));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No tienes combates programados próximamente.',
                  style: TextStyle(color: Colors.white, fontSize: 16)));
        }

        List<CombatInvitation> upcomingCombats = snapshot.data!;
        print('Todos los combates aceptados:');
        for (var c in upcomingCombats) {
          print('${c.status} - ${c.date.toIso8601String()}');
        }

        upcomingCombats = upcomingCombats.where((c) {
          return c.status == 'accepted' && c.date.isAfter(DateTime.now());
        }).toList();

        print('Solo futuros:');
        for (var c in upcomingCombats) {
          print('${c.status} - ${c.date.toIso8601String()}');
        }
        // Filtrar para asegurar que solo se muestren los aceptados (el backend ya debería hacerlo)
        // y que la fecha sea futura (el backend ya debería hacerlo con /future)
        // List<CombatInvitation> filteredCombats = upcomingCombats.where((c) => 
        //    c.status == 'accepted' && c.date.isAfter(DateTime.now())
        // ).toList();
        // if (filteredCombats.isEmpty) {
        //    return const Center(child: Text('No tienes combates programados próximamente.', style: TextStyle(color: Colors.white, fontSize: 16)));
        // }
        // Si confías en que el backend /future ya hace este filtrado, puedes usar upcomingCombats directamente.


        return RefreshIndicator(
          onRefresh: () async {
            _loadUpcomingCombats();
          },
          color: Colors.red,
          backgroundColor: Colors.grey[900],
          child: ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: upcomingCombats.length, // Usar la lista directamente si el backend filtra
            itemBuilder: (context, index) {
              final combat = upcomingCombats[index];
              final opponentDisplayName = _getOpponentDisplayName(combat, Session.userId!);

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
                      Text('Combate vs: $opponentDisplayName',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.calendar_today_outlined, 'Fecha:', combat.formattedDate),
                      _buildInfoRow(Icons.access_time_outlined, 'Hora:', combat.formattedTime),
                      _buildInfoRow(Icons.fitness_center_outlined, 'Gimnasio:', combat.gymName),
                      _buildInfoRow(Icons.shield_outlined, 'Nivel:', combat.level),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                           Chip(
                            label: Text('ACEPTADO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.green.shade700,
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          ),
                          // Aquí podrías añadir más acciones si son relevantes para combates futuros
                          // ej. "Ver detalles", "Chatear con oponente" (si no es el mismo chat de la invitación)
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