import 'package:flutter/material.dart';
import 'package:face2face_app/models/combat_invitation_model.dart';
import 'package:face2face_app/services/combat_service.dart';
import 'package:face2face_app/session.dart';

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
      return combat.opponentName;
    } else if (combat.opponentId == currentUserId) {
      return combat.creatorName;
    }
    return "Desconocido";
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completado';
      case 'rejected':
        return 'Rechazado';
      case 'cancelled':
        return 'Cancelado';
      // Este caso maneja los combates 'accepted' que ya pasaron y ahora son parte del historial
      case 'accepted':
        return 'Completado';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
      case 'accepted': // Los 'accepted' del historial se muestran como 'completados'
        return Colors.green.shade400;
      case 'rejected':
        return Colors.redAccent.shade100;
      case 'cancelled':
        return Colors.grey.shade600;
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
            child: Text('Error al cargar el historial: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70)),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: RefreshIndicator(
              onRefresh: () async => _loadCombatHistory(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  alignment: Alignment.center,
                  child: const Text('No tienes combates en tu historial.',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ),
          );
        }

        List<CombatInvitation> combatHistory = snapshot.data!;
        
        return RefreshIndicator(
          onRefresh: () async => _loadCombatHistory(),
          color: Colors.red,
          backgroundColor: Colors.grey[900],
          child: ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: combatHistory.length,
            itemBuilder: (context, index) {
              final combat = combatHistory[index];
              final opponentDisplayName = _getOpponentDisplayName(combat, Session.userId!);

              final bool isPastAccepted = combat.status == 'accepted' && combat.date.isBefore(DateTime.now());
              final bool canRate = combat.status == 'completed' || isPastAccepted;

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
                            child: Icon(Icons.history, color: Colors.white, size: 28),
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
                      if (combat.status == 'cancelled' && combat.cancellationReason != null && combat.cancellationReason!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: _buildInfoRow(Icons.comment_outlined, 'Motivo:', combat.cancellationReason!),
                        ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (canRate)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () {
                                _showRatingDialog(context, combat, opponentDisplayName);
                              },
                              child: const Text('Valorar', style: TextStyle(fontWeight: FontWeight.bold)),
                            )
                          else if (combat.status == 'cancelled')
                            Chip(
                              label: const Text('CANCELADO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.grey.shade800,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            )
                          else
                            Chip(
                              label: Text(_getStatusText(combat.status), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text('$label ', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingDialog(BuildContext context, CombatInvitation combat, String opponentDisplayName) async {
    final ratingService = CombatService();
    final currentUserId = Session.userId!;
    final toUserId = combat.creatorId == currentUserId ? combat.opponentId : combat.creatorId;

    await showDialog(
      context: context,
      builder: (context) => _RatingDialog(
        opponentName: opponentDisplayName,
        onSubmit: (ratingData) async {
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
              _loadCombatHistory();
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al enviar la valoración: $e')),
            );
          }
        },
      ),
    );
  }
}

// La clase _RatingDialog se mantiene igual, no necesita cambios.
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
            content: //... El resto del diálogo de valoración
                SingleChildScrollView(
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