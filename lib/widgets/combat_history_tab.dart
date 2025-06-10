import 'package:flutter/material.dart';
import 'package:face2face_app/models/combat_invitation_model.dart'; // Reutilizamos el modelo
import 'package:face2face_app/services/combat_service.dart';
import 'package:face2face_app/session.dart'; // Para saber quién es el usuario actual

class CombatHistoryTab extends StatefulWidget {
  const CombatHistoryTab({super.key});

  @override
  State<CombatHistoryTab> createState() => _CombatHistoryTabState();
}

class _CombatHistoryTabState extends State<CombatHistoryTab> {
  final CombatService _combatService = CombatService();
  Future<List<CombatInvitation>>? _combatHistoryFuture;

  @override
  void initState() {
    super.initState();
    _loadCombatHistory();
  }

  void _loadCombatHistory() {
    if (mounted) {
      setState(() {
        _combatHistoryFuture = _combatService.getCombatHistory();
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

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptado';
      case 'rejected':
        return 'Rechazado';
      case 'completed':
        return 'Completado'; // Añadir este estado si lo usas
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orangeAccent.shade100;
      case 'accepted':
        return Colors.blue.shade300; // Color diferente para aceptados no futuros
      case 'rejected':
        return Colors.redAccent.shade100;
      case 'completed':
        return Colors.green.shade400; // Color para completados
      default:
        return Colors.grey.shade400;
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CombatInvitation>>(
      future: _combatHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        } else if (snapshot.hasError) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error al cargar el historial: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70)),
          ));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No tienes combates en tu historial.',
                  style: TextStyle(color: Colors.white, fontSize: 16)));
        }

        List<CombatInvitation> combatHistory = snapshot.data!;
        
        
        // Si el backend no filtra por status 'completed' o 'rejected', hazlo aquí:
        // combatHistory = combatHistory.where((c) => c.status == 'completed' || c.status == 'rejected').toList();
        // if (combatHistory.isEmpty) {
        //    return const Center(child: Text('No tienes combates completados o rechazados en tu historial.', style: TextStyle(color: Colors.white, fontSize: 16)));
        // }


        return RefreshIndicator(
          onRefresh: () async {
            _loadCombatHistory();
          },
          color: Colors.red,
          backgroundColor: Colors.grey[900],
          child: ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: combatHistory.length,
            itemBuilder: (context, index) {
              final combat = combatHistory[index];
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
                      Text('Combate vs: ${combat.opponentName}',
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
                          if (combat.status == 'accepted')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () async{
                                final ratingService = CombatService();
                                final currentUserId = Session.userId!;
                                final toUserId = combat.creatorId == currentUserId ? combat.opponentId : combat.creatorId;

                                await showDialog(
                                  context: context,
                                  builder: (context) => _RatingDialog(
                                    opponentName: opponentDisplayName,
                                    onSubmit: (ratingData) async {
                                        print('creatorId: ${combat.creatorId}, opponentId: ${combat.opponentId}, currentUserId: $currentUserId, toUserId: $toUserId');

                                      try {
                                        await ratingService.sendRating(
                                          combatId: combat.id,
                                          fromUserId: currentUserId,
                                          toUserId: toUserId,
                                          punctuality: ratingData['punctuality'],
                                          attitude: ratingData['attitude'],
                                          technique: ratingData['technique'],
                                          intensity: ratingData['intensity'],
                                          sportmanship: ratingData['sportmanship'],
                                          comment: ratingData['comment'],
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('¡Valoración enviada correctamente!')),
                                          );
                                          _loadCombatHistory(); // Opcional: recarga el historial
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error al enviar la valoración: $e')),
                                        );
                                      }
                                    },
                                  ),
                                );
                                // Aquí irá la lógica de valoración
                              },
                              child: const Text('Valorar', style: TextStyle(fontWeight: FontWeight.bold)),
                            )
                          else
                            Chip(
                              label: Text(_getStatusText(combat.status), style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                              backgroundColor: _getStatusColor(combat.status),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
class _RatingDialog extends StatefulWidget {
  final void Function(Map<String, dynamic> ratingData) onSubmit;
  final String opponentName;

  const _RatingDialog({required this.onSubmit, required this.opponentName});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  final _commentController = TextEditingController();
  final Map<String, int> _ratings = {
    'Puntualidad': 0,
    'Actitud': 0,
    'Técnica': 0,
    'Intensidad': 0,
    'Deportividad': 0,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text('Valorar a ${widget.opponentName}', style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._ratings.keys.map((attr) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(attr, style: const TextStyle(color: Colors.white))),
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        Icons.star,
                        color: _ratings[attr]! >= i ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _ratings[attr] = i;
                        });
                      },
                    ),
                ],
              ),
            )),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Comentario (opcional)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Enviar'),
          onPressed: () {
            if (_ratings.values.any((v) => v == 0)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Por favor, valora todos los atributos')),
              );
              return;
            }
            widget.onSubmit({
              'punctuality': _ratings['Puntualidad'],
              'attitude': _ratings['Actitud'],
              'technique': _ratings['Técnica'],
              'intensity': _ratings['Intensidad'],
              'sportmanship': _ratings['Deportividad'],
              'comment': _commentController.text,
            });
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}