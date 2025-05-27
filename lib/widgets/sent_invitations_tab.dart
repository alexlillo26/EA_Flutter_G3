import 'package:flutter/material.dart';
import 'package:face2face_app/models/combat_invitation_model.dart';
import 'package:face2face_app/services/combat_service.dart';
import 'package:face2face_app/session.dart'; // Para determinar el oponente

class SentInvitationsTab extends StatefulWidget {
  const SentInvitationsTab({super.key});

  @override
  State<SentInvitationsTab> createState() => _SentInvitationsTabState();
}

class _SentInvitationsTabState extends State<SentInvitationsTab>
    with AutomaticKeepAliveClientMixin<SentInvitationsTab> {

  final CombatService _combatService = CombatService();
  List<CombatInvitation>? _sentInvitations;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSentInvitations();
  }

  @override
  bool get wantKeepAlive => true; // Mantiene el estado de la pestaña

  Future<void> _loadSentInvitations({bool showLoadingIndicator = true}) async {
    if (!mounted) return; // Si el widget no está montado, no hacer nada

    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
        _error = null; // Limpiar errores previos al recargar
      });
    }

    try {
      final invitations = await _combatService.getSentInvitations();
      if (mounted) {
        setState(() {
          _sentInvitations = invitations; // Reemplazar la lista con los nuevos datos
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      print("Error en _loadSentInvitations: $e");
      // Opcional: Mostrar un SnackBar global si el error es persistente
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('No se pudieron cargar las invitaciones enviadas: ${e.toString()}')),
      // );
    }
  }

  // --- Funciones de ayuda para UI ---
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptada';
      case 'rejected':
        return 'Rechazada';
      case 'completed': // Si aplica
        return 'Completada';
      default:
        return status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : 'Desconocido';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orangeAccent.shade200;
      case 'accepted':
        return Colors.green.shade400; // Un verde más brillante para aceptadas
      case 'rejected':
        return Colors.redAccent.shade200;
      case 'completed':
        return Colors.blueGrey.shade300;
      default:
        return Colors.grey.shade500;
    }
  }

  // Determina el nombre del oponente para mostrarlo en la lista de invitaciones enviadas
  String _getOpponentDisplayNameForSent(CombatInvitation invitation) {
    // En invitaciones enviadas, el usuario actual (Session.userId) es el creador.
    // El nombre del oponente ya debería estar en invitation.opponentName
    // gracias al factory CombatInvitation.fromJson.
    return invitation.opponentName.isNotEmpty ? invitation.opponentName : "Oponente no especificado";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin

    if (_isLoading && _sentInvitations == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent.shade100, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error al cargar invitaciones enviadas:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                onPressed: _loadSentInvitations,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
              )
            ],
          ),
        ),
      );
    }

    if (_sentInvitations == null || _sentInvitations!.isEmpty) {
      return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.outgoing_mail, size: 48, color: Colors.white54),
              const SizedBox(height: 16),
              const Text('No has enviado ninguna invitación aún.',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 10),
               ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Recargar', style: TextStyle(color: Colors.white)),
                  onPressed: _loadSentInvitations,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                )
            ],
          )
        );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSentInvitations(showLoadingIndicator: false),
      color: Colors.red,
      backgroundColor: Colors.grey[900],
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
        itemCount: _sentInvitations!.length,
        itemBuilder: (context, index) {
          final invitation = _sentInvitations![index];
          final opponentDisplayName = _getOpponentDisplayNameForSent(invitation);

          return Card(
            color: Colors.grey[850]?.withOpacity(0.95),
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invitación enviada a: $opponentDisplayName',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.calendar_today_outlined, 'Fecha:', invitation.formattedDate),
                  _buildInfoRow(Icons.access_time_outlined, 'Hora:', invitation.formattedTime),
                  _buildInfoRow(Icons.location_on_outlined, 'Gimnasio:', invitation.gymName),
                  _buildInfoRow(Icons.shield_outlined, 'Nivel:', invitation.level),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Chip(
                        label: Text(_getStatusText(invitation.status), style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                        backgroundColor: _getStatusColor(invitation.status),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                      // Opcional: Botón para cancelar una invitación PENDIENTE
                      if (invitation.status == 'pending') ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            // TODO: Implementar lógica y endpoint para cancelar una invitación enviada
                            // bool success = await _combatService.cancelSentInvitation(invitation.id);
                            // if (success && mounted) {
                            //   ScaffoldMessenger.of(context).showSnackBar(
                            //     const SnackBar(content: Text('Invitación cancelada.')),
                            //   );
                            //   _loadSentInvitations(showLoadingIndicator: false);
                            // } else if(mounted) {
                            //    ScaffoldMessenger.of(context).showSnackBar(
                            //     const SnackBar(content: Text('No se pudo cancelar la invitación.')),
                            //   );
                            // }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cancelar invitación (Pendiente de implementar)')),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          child: Text('Cancelar', style: TextStyle(color: Colors.redAccent.shade100)),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Text('$label ', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}