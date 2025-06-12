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

    Map<String, dynamic> opponentInfo = json['opponent'] is Map
        ? json['opponent']
        : {'_id': json['opponent'], 'username': 'Desconocido'};

    String creatorId = currentUserId;
    String creatorName = 'Tú';

    String opponentId = opponentInfo['_id'] ?? opponentInfo['id'] ?? '';
    String opponentName = opponentInfo['username'] ?? opponentInfo['name'] ?? 'Oponente Desconocido';

    return CombatInvitation(
      id: json['_id'] ?? '',
      creatorId: creatorId,
      creatorName: creatorName,
      opponentId: opponentId,
      opponentName: opponentName,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      time: json['time'] ?? 'Hora no especificada',
      level: json['level'] ?? 'Nivel no especificado',
      gymId: json['gym'] is Map ? json['gym']['_id'] ?? '' : '',
      gymName: json['gym'] is Map ? json['gym']['name'] ?? '' : '',
      status: json['status'] ?? '',

    );
  }
}