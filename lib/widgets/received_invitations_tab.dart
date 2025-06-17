import 'package:flutter/material.dart';
import 'package:face2face_app/models/combat_invitation_model.dart';
import 'package:face2face_app/services/combat_service.dart';
import 'package:face2face_app/session.dart'; // <-- Añade esta línea para obtener el userId

class ReceivedInvitationsTab extends StatefulWidget {
  const ReceivedInvitationsTab({super.key});

  @override
  State<ReceivedInvitationsTab> createState() => _ReceivedInvitationsTabState();
}

class _ReceivedInvitationsTabState extends State<ReceivedInvitationsTab>
    with AutomaticKeepAliveClientMixin<ReceivedInvitationsTab> { // Para mantener el estado

  final CombatService _combatService = CombatService();
  List<CombatInvitation>? _receivedInvitations;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  // Obligatorio para AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  Future<void> _loadInvitations({bool showLoadingIndicator = true}) async {
    if (mounted && showLoadingIndicator) {
      setState(() {
        _isLoading = true;
        _error = null; // Limpiar errores previos
      });
    }
    try {
      final invitations = await _combatService.getReceivedInvitations();
      if (mounted) {
        setState(() {
          _receivedInvitations = invitations; // Siempre REEMPLAZA la lista, no añadas con .addAll()
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
      print("Error en _loadInvitations (Received): $e");
    }
  }

  Future<void> _handleResponse(String combatId, String status) async {
    // Mostrar un indicador de carga para la acción
     if (mounted) setState(() { _isLoading = true; });
    try {
      final success = await _combatService.respondToCombatInvitation(combatId, status);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Invitación ${status == "accepted" ? "aceptada" : "rechazada"} con éxito.'),
              backgroundColor: status == "accepted" ? Colors.green.shade600 : Colors.orange.shade700),
        );
        _loadInvitations(showLoadingIndicator: false); // Recargar la lista sin el indicador de pantalla completa
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al responder: ${e.toString()}')),
        );
         setState(() { _isLoading = false; }); // Quitar indicador si hay error
      }
    }
    // No es necesario quitar _isLoading aquí si _loadInvitations lo va a hacer.
    // Pero si la recarga falla, _isLoading podría quedarse en true.
    // Es mejor que _loadInvitations siempre ponga _isLoading = false al final.
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin

    if (_isLoading && _receivedInvitations == null) { // Mostrar carga solo la primera vez o si _error no está seteado
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error al cargar invitaciones: $_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                onPressed: _loadInvitations,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
              )
            ],
          ),
        ),
      );
    }

    if (_receivedInvitations == null || _receivedInvitations!.isEmpty) {
      return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No tienes invitaciones pendientes.',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Recargar', style: TextStyle(color: Colors.white)),
                onPressed: _loadInvitations,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
              )
            ],
          )
        );
    }

    return RefreshIndicator(
      onRefresh: () => _loadInvitations(showLoadingIndicator: false),
      color: Colors.red,
      backgroundColor: Colors.grey[900],
      child: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: _receivedInvitations!.length,
        itemBuilder: (context, index) {
          final invitation = _receivedInvitations![index];
          // Determina el nombre a mostrar igual que en las otras pestañas:
          final currentUserId = Session.userId;
          final displayName = (invitation.creatorId == currentUserId)
              ? invitation.opponentName
              : invitation.creatorName;

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
                          'Invitación de: $displayName',
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
                  _buildInfoRow(Icons.calendar_today_outlined, 'Fecha:', invitation.formattedDate),
                  _buildInfoRow(Icons.access_time_outlined, 'Hora:', invitation.formattedTime),
                  _buildInfoRow(Icons.location_on_outlined, 'Gimnasio:', invitation.gymName),
                  _buildInfoRow(Icons.shield_outlined, 'Nivel:', invitation.level),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.white, size: 22),
                        label: const Text('Rechazar', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _isLoading ? null : () => _handleResponse(invitation.id, 'rejected'),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton.icon(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                        label: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _isLoading ? null : () => _handleResponse(invitation.id, 'accepted'),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
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