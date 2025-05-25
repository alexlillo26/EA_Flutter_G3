// lib/models/combat_invitation_model.dart
import 'package:intl/intl.dart'; // Para formatear la fecha

class CombatInvitation {
  final String id; // ID del combate/invitación
  final String creatorId;
  final String creatorName;
  final String opponentId; // Podría ser útil saber quién es el oponente (el usuario actual)
  final String opponentName; // No es estrictamente necesario si el usuario actual es el oponente
  final DateTime date; // Fecha y hora del combate
  final String time;   // Hora como string, tal como la espera/envía el backend
  final String level;
  final String gymId;
  final String gymName; // Nombre del gimnasio
  final String status; // 'pending', 'accepted', 'rejected'

  CombatInvitation({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.opponentId,
    required this.opponentName, // Aunque no se usa en la UI, puede ser útil para el futuro
    required this.date,
    required this.time,
    required this.level,
    required this.gymId,
    required this.gymName,
    required this.status,
  });

  // Formateador para mostrar la fecha de manera amigable
  String get formattedDate => DateFormat('dd/MM/yyyy').format(date.toLocal());
  String get formattedTime => time; // Asumimos que 'time' ya está en un formato amigable

  factory CombatInvitation.fromJson(Map<String, dynamic> json, String currentUserId) {
    // El backend en getInvitationsHandler populates 'creator', 'opponent', 'gym'
    // Asegúrate que los nombres de los campos y la estructura coincidan.
    Map<String, dynamic> creatorInfo = json['creator'] is Map ? json['creator'] : {'_id': json['creator'], 'name': 'Desconocido'};
    Map<String, dynamic> opponentInfo = json['opponent'] is Map ? json['opponent'] : {'_id': json['opponent'], 'name': 'Desconocido'};
    Map<String, dynamic> gymInfo = json['gym'] is Map ? json['gym'] : {'_id': json['gym'], 'name': 'Gimnasio Desconocido'};

    return CombatInvitation(
      id: json['_id'] ?? '',
      creatorId: creatorInfo['_id'] ?? '',
      creatorName: creatorInfo['name'] ?? 'Creador Desconocido',
      opponentId: opponentInfo['_id'] ?? '',
      opponentName: opponentInfo['name'] ?? 'Oponente Desconocido',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      time: json['time'] ?? 'Hora no especificada',
      level: json['level'] ?? 'Nivel no especificado',
      gymId: gymInfo['_id'] ?? '',
      gymName: gymInfo['name'] ?? 'Gimnasio Desconocido',
      status: json['status'] ?? 'pending',
    );
  }
}