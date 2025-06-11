import 'package:face2face_app/session.dart';
import 'package:intl/intl.dart';

class CombatInvitation {
  final String id;
  final String creatorId;
  final String creatorName;
  final String opponentId;
  final String opponentName;
  final DateTime date;
  final String time;
  final String level;
  final String gymId;
  final String gymName;
  final String status;

  CombatInvitation({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.opponentId,
    required this.opponentName,
    required this.date,
    required this.time,
    required this.level,
    required this.gymId,
    required this.gymName,
    required this.status,
  });

  String get formattedDate => DateFormat('dd/MM/yyyy').format(date.toLocal());
  String get formattedTime => time;

  factory CombatInvitation.fromJson(Map<String, dynamic> json, String currentUserId) {
    Map<String, dynamic> creatorInfo;
    Map<String, dynamic> opponentInfo;

    // --- ¡NUEVA LÓGICA AQUÍ! ---
    // Si el JSON no tiene un campo 'creator' (como ocurre en la respuesta del historial),
    // asumimos que el creador es el usuario de la sesión actual.
    if (json.containsKey('creator')) {
      creatorInfo = json['creator'] is Map
          ? json['creator']
          : {'_id': json['creator'], 'name': 'Creador Desconocido'};
    } else {
      creatorInfo = {
        '_id': Session.userId,
        'name': Session.username ?? 'Usuario Actual', // Usamos el nombre de la sesión
      };
    }

    // El oponente siempre debería estar presente.
    opponentInfo = json['opponent'] is Map
        ? json['opponent']
        : {'_id': json['opponent'], 'name': 'Oponente Desconocido'};

    // Se extraen los nombres. Para el oponente, se comprueba 'username' y 'name'
    // para ser compatible con lo que muestra tu log.
    final String creatorNameValue = creatorInfo['name'] ?? 'Creador Desconocido';
    final String opponentNameValue = opponentInfo['username'] ?? opponentInfo['name'] ?? 'Oponente Desconocido';

    return CombatInvitation(
      id: json['_id'] ?? '',
      creatorId: creatorInfo['_id'] ?? '',
      creatorName: creatorNameValue,
      opponentId: opponentInfo['id'] ?? opponentInfo['_id'] ?? '',
      opponentName: opponentNameValue,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      time: json['time'] ?? 'Hora no especificada',
      level: json['level'] ?? 'Nivel no especificado',
      gymId: (json['gym'] is Map ? json['gym']['_id'] : json['gym']) ?? '',
      gymName: (json['gym'] is Map ? json['gym']['name'] : 'Gimnasio Desconocido') ?? 'Gimnasio Desconocido',
      status: json['status'] ?? 'pending',
    );
  }
}