import 'package:flutter/material.dart';
import 'package:face2face_app/models/combat_invitation_model.dart';
import 'package:face2face_app/services/combat_service.dart';

class SentInvitationsTab extends StatefulWidget {
  const SentInvitationsTab({super.key});

  @override
  State<SentInvitationsTab> createState() => _SentInvitationsTabState();
}

class _SentInvitationsTabState extends State<SentInvitationsTab> {
  final CombatService _combatService = CombatService();
  Future<List<CombatInvitation>>? _sentInvitationsFuture;

  @override
  void initState() {
    super.initState();
    _loadSentInvitations();
  }

  void _loadSentInvitations() {
    if (mounted) {
      setState(() {
        _sentInvitationsFuture = _combatService.getSentInvitations();
      });
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptada';
      case 'rejected':
        return 'Rechazada';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orangeAccent.shade200;
      case 'accepted':
        return Colors.green.shade300;
      case 'rejected':
        return Colors.redAccent.shade100;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CombatInvitation>>(
      future: _sentInvitationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        } else if (snapshot.hasError) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error al cargar invitaciones enviadas: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70)),
          ));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No has enviado ninguna invitación aún.',
                  style: TextStyle(color: Colors.white, fontSize: 16)));
        }

        List<CombatInvitation> invitations = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            _loadSentInvitations();
          },
          color: Colors.red,
          backgroundColor: Colors.grey[900],
          child: ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              // Para invitaciones enviadas, el 'opponent' es a quien se la enviaste.
              // Necesitas asegurarte que CombatInvitation.fromJson() puede obtener el opponentName.
              // Si tu backend en 'getSentInvitations' ya populates 'opponent',
              // y CombatInvitation.fromJson puede extraer opponent.name, esto funcionará.
              // De lo contrario, necesitarás ajustar el modelo o la lógica aquí para obtener el nombre del oponente.
              // Por ahora, asumimos que invitation.opponentName está disponible o es manejado por el modelo
              String opponentNameDisplay = "Oponente Desconocido";
              if (invitation.opponentId.isNotEmpty) {
                 // Si tu modelo no tiene opponentName directamente pero sí el ID,
                 // podrías necesitar buscarlo o ajustar el modelo.
                 // Por ahora, si el modelo lo incluye, se usa.
                 // Este es un placeholder, necesitas la lógica correcta en tu modelo.
                 // Asumiremos que el fromJson de CombatInvitation ha cargado opponentName
                 // y si no, caerá en el default.
                 // El modelo CombatInvitation necesita acceso a opponent.name desde el JSON
                 // o podrías pasar el currentUserId al fromJson y determinar quién es el oponente.

                 // AHORA: CombatInvitation.fromJson necesita recibir currentUserId
                 // para determinar si el nombre a mostrar es creatorName o opponentName.
                 // En `getSentInvitations` currentUserId es el `creatorId`.
                 // Entonces `invitation.opponentName` (si lo añades al modelo) sería lo correcto.
                 // Por ahora, voy a asumir que tu `CombatInvitation` tiene un `opponentName`.
                 // Si no, necesitas adaptar el modelo o esta UI.
                 // Vamos a suponer que el fromJson es suficientemente inteligente para que
                 // invitation.opponentName tenga el nombre del oponente.

                 // Si el `fromJson` actual pone el nombre del oponente en `opponentName`
                 // (necesitarías añadir `opponentName` al modelo CombatInvitation y poblarlo en fromJson)
                 // opponentNameDisplay = invitation.opponentName; // Si tu modelo tiene esto
                 
                 // Si no tienes opponentName en el modelo CombatInvitation, necesitarás
                 // que tu API /api/combat/sent-invitations devuelva el nombre del oponente
                 // y que CombatInvitation.fromJson() lo parsee y lo asigne.
                 // Por ahora, usamos un placeholder si no está disponible en el modelo.
                 // LA SOLUCIÓN IDEAL: el `CombatInvitation.fromJson` debería recibir el `currentUserId`
                 // y determinar si el `creator` o el `opponent` del JSON es el "otro" usuario.
                 // En este caso (`SentInvitationsTab`), el usuario actual es el creador.
                 // El modelo `CombatInvitation` ya tiene `creatorName` y `opponentId`.
                 // Necesitamos el `opponentName`.
                 // Asegúrate que el `CombatInvitation.fromJson` llene `opponentName`.
                 //  `opponentName: opponentInfo['name'] ?? 'Oponente Desconocido'` debe estar en el modelo.

                 // Suponiendo que CombatInvitation tiene un campo opponentName:
                 // opponentNameDisplay = invitation.opponentName; // Si existe en el modelo

                 // MODIFICACIÓN: Para que funcione con el CombatInvitation actual,
                 // que tiene creatorName y opponentId, pero no opponentName explícito.
                 // Necesitamos que el backend, en la ruta getSentInvitations, popule el opponent
                 // y que el fromJson en CombatInvitation lo parsee.
                 // El `fromJson` que te di antes ya intenta esto con `opponentInfo`.
                 // Así que `invitation.opponentName` (si lo añades a la clase) debería funcionar.

                 // Si el modelo `CombatInvitation` tiene `creatorName` y `opponentName`:
                 // Para invitaciones enviadas, el "otro" es el `opponentName`.
                 opponentNameDisplay = invitation.opponentName; // Asumimos que esto existe en tu modelo
              }


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
                      Text('Invitación enviada a: $opponentNameDisplay', // Mostrar nombre del oponente
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
                          Chip(
                            label: Text(_getStatusText(invitation.status), style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            backgroundColor: _getStatusColor(invitation.status),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          // Aquí podrías añadir un botón de "Cancelar invitación" si el estado es 'pending'
                          // y si tu backend soporta esa acción.
                          // Ejemplo:
                          // if (invitation.status == 'pending')
                          //   TextButton(onPressed: () { /* Lógica para cancelar */ }, child: Text('Cancelar'))
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