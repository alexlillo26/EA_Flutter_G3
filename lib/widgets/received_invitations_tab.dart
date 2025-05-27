import 'package:flutter/material.dart';
import 'package:face2face_app/models/combat_invitation_model.dart';
import 'package:face2face_app/services/combat_service.dart';
// No necesitas Session.userId aquí directamente si CombatService lo maneja internamente
// al obtener el token/ID de la clase Session.

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
                  Text('Invitación de: ${invitation.creatorName}',
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
                      TextButton.icon(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                        label: const Text('Rechazar', style: TextStyle(color: Colors.redAccent)),
                        onPressed: _isLoading ? null : () => _handleResponse(invitation.id, 'rejected'), // Deshabilitar si está cargando
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                        label: const Text('Aceptar', style: TextStyle(color: Colors.white)),
                        onPressed: _isLoading ? null : () => _handleResponse(invitation.id, 'accepted'), // Deshabilitar si está cargando
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