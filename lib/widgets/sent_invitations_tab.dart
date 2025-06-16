import 'dart:async'; // Importa Timer
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
  Timer? _refreshTimer; // Agrega un temporizador

  @override
  void initState() {
    super.initState();
    _loadSentInvitations();
    _startAutoRefresh(); // Inicia el temporizador
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancela el temporizador al destruir el widget
    super.dispose();
  }

  void _startAutoRefresh() {
    // Configura el temporizador para refrescar cada 30 segundos (puedes ajustar el tiempo)
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _loadSentInvitations(showLoadingIndicator: false); // Refresca sin mostrar el indicador de carga
    });
  }

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
          // Filtrar invitaciones rechazadas
          _sentInvitations = invitations.where((invitation) => invitation.status != 'rejected').toList();
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
                        child: Icon(Icons.send, color: Colors.white, size: 28),
                        radius: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Invitación enviada a: $opponentDisplayName',
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
                      if (invitation.status == 'pending')
                        Chip(
                          label: const Text('PENDIENTE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        )
                      else
                        Chip(
                          label: Text(_getStatusText(invitation.status),
                              style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                          backgroundColor: _getStatusColor(invitation.status),
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

  @override
  bool get wantKeepAlive => true; // Implementación requerida por AutomaticKeepAliveClientMixin
}