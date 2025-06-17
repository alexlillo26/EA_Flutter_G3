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
  final String? cancellationReason;

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
    this.cancellationReason,
  });

  String get formattedDate => DateFormat('dd/MM/yyyy').format(date.toLocal());
  String get formattedTime => time;

  factory CombatInvitation.fromJson(Map<String, dynamic> json, String currentUserId) {
    // Determina correctamente el creador y el oponente
    String creatorId = '';
    String creatorName = '';
    String opponentId = '';
    String opponentName = '';

    // Si el campo 'creator' es un Map, extrae los datos, si no, usa el id
    if (json['creator'] is Map) {
      creatorId = json['creator']['_id'] ?? json['creator']['id'] ?? '';
      creatorName = json['creator']['username'] ?? json['creator']['name'] ?? 'Desconocido';
    } else {
      creatorId = json['creator'] ?? '';
      creatorName = 'Desconocido';
    }

    // Igual para el oponente
    if (json['opponent'] is Map) {
      opponentId = json['opponent']['_id'] ?? json['opponent']['id'] ?? '';
      opponentName = json['opponent']['username'] ?? json['opponent']['name'] ?? 'Oponente Desconocido';
    } else {
      opponentId = json['opponent'] ?? '';
      opponentName = 'Oponente Desconocido';
    }

    // Si el usuario actual es el creador, muestra "Tú" como creador
    if (creatorId == currentUserId) {
      creatorName = 'Tú';
    }

    // Hora: intenta extraer el campo 'time' o, si no existe, formatea la hora de 'date'
    String timeValue = '';
    if (json['time'] != null && json['time'].toString().isNotEmpty) {
      timeValue = json['time'].toString();
    } else if (json['date'] != null && json['date'].toString().isNotEmpty) {
      // Intenta extraer la hora de la fecha ISO
      try {
        final dt = DateTime.tryParse(json['date']);
        if (dt != null) {
          final hour = dt.hour.toString().padLeft(2, '0');
          final minute = dt.minute.toString().padLeft(2, '0');
          timeValue = '$hour:$minute';
        }
      } catch (_) {
        timeValue = '';
      }
    } else {
      timeValue = '';
    }

    return CombatInvitation(
      id: json['_id'] ?? '',
      creatorId: creatorId,
      creatorName: creatorName,
      opponentId: opponentId,
      opponentName: opponentName,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      time: timeValue.isNotEmpty ? timeValue : 'Hora no especificada',
      level: json['level'] ?? 'Nivel no especificado',
      gymId: json['gym'] is Map ? json['gym']['_id'] ?? '' : '',
      gymName: json['gym'] is Map ? json['gym']['name'] ?? '' : '',
      status: json['status'] ?? '',
      cancellationReason: json['cancellationReason'] ?? null,
    );
  }
}