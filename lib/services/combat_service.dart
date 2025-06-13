// lib/services/combat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:face2face_app/config/app_config.dart';
import 'package:face2face_app/session.dart';
import 'package:face2face_app/models/combat_invitation_model.dart';

class CombatService {
  Future<List<CombatInvitation>> getReceivedInvitations() async {
    final token = Session.token;
    final currentUserId = Session.userId; 

    if (token == null || currentUserId == null) {
      print("Error: Usuario no autenticado o ID de usuario no disponible.");
      throw Exception('Usuario no autenticado');
    }

    final url = Uri.parse('$API_BASE_URL/combat/invitations');
    print('Fetching received invitations from: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      if (responseBody['success'] == true && responseBody['invitations'] != null) {
        final List<dynamic> invitationsData = responseBody['invitations'];
        if (invitationsData is List) {
          return invitationsData
              .map((data) => CombatInvitation.fromJson(data, currentUserId))
              .toList();
        }
      }
      print('Formato de respuesta inesperado para invitaciones recibidas: ${response.body}');
      throw Exception('Formato de respuesta inesperado para invitaciones recibidas');
    } else {
      print('Error al cargar invitaciones recibidas: ${response.statusCode} - ${response.body}');
      throw Exception('Error al cargar invitaciones recibidas');
    }
  }

  Future<bool> respondToCombatInvitation(String combatId, String statusResponse) async {
    final token = Session.token;
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final url = Uri.parse('$API_BASE_URL/combat/$combatId/respond');
    print('Responding to invitation $combatId with $statusResponse to URL: $url');
    
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'status': statusResponse}),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      print('Respuesta a invitación enviada exitosamente: ${response.statusCode}');
      return true;
    } else {
      print('Error al responder a la invitación: ${response.statusCode} - ${response.body}');
      final responseBody = json.decode(response.body);
      throw Exception('Error al responder a la invitación: ${responseBody['message'] ?? response.body}');
    }
  }

   Future<List<CombatInvitation>> getSentInvitations() async {
    final token = Session.token;
    final currentUserId = Session.userId;

    if (token == null || currentUserId == null) {
      print("Error: Usuario no autenticado o ID de usuario no disponible para invitaciones enviadas.");
      throw Exception('Usuario no autenticado');
    }

    final url = Uri.parse('$API_BASE_URL/combat/sent-invitations');
    print('Fetching sent invitations from: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final dynamic responseBody = json.decode(response.body);
      List<dynamic> invitationsData = [];

      if (responseBody is List) {
        invitationsData = responseBody;
      } else if (responseBody is Map<String, dynamic>) {
        if (responseBody['success'] == true && responseBody['invitations'] != null) {
          invitationsData = responseBody['invitations'];
        } else if (responseBody.containsKey('invitations')) {
           invitationsData = responseBody['invitations'];
        } else if (responseBody.containsKey('combats')) {
           invitationsData = responseBody['combats'];
        }
         else {
          print('Formato de respuesta inesperado para invitaciones enviadas (objeto): ${response.body}');
          throw Exception('Formato de respuesta inesperado para invitaciones enviadas');
        }
      } else {
        print('Formato de respuesta inesperado para invitaciones enviadas (no es lista ni objeto): ${response.body}');
        throw Exception('Formato de respuesta inesperado para invitaciones enviadas');
      }
      
      if (invitationsData is List) {
        return invitationsData
            .map((data) => CombatInvitation.fromJson(data, currentUserId))
            .toList();
      } else {
         print('InvitationsData no es una lista después del parseo: $invitationsData');
         throw Exception('Los datos de invitaciones procesados no son una lista.');
      }

    } else {
      print('Error al cargar invitaciones enviadas: ${response.statusCode} - ${response.body}');
      throw Exception('Error al cargar invitaciones enviadas');
    }
  }

   Future<List<CombatInvitation>> getUpcomingCombats() async {
    final token = Session.token;
    final currentUserId = Session.userId;

    if (token == null || currentUserId == null) {
      print("Error: Usuario no autenticado o ID de usuario no disponible para próximos combates.");
      throw Exception('Usuario no autenticado');
    }

    final url = Uri.parse('$API_BASE_URL/combat/future');
    print('Fetching upcoming combats from: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final dynamic responseBody = json.decode(response.body);
      List<dynamic> combatsData = [];

      if (responseBody is List) {
        combatsData = responseBody;
      } else if (responseBody is Map<String, dynamic>) {
        combatsData = responseBody['combats'] ?? 
                      responseBody['results'] ?? 
                      responseBody['data'] ?? 
                      [];
        if (responseBody is Map<String, dynamic> && !(responseBody.containsKey('combats') || responseBody.containsKey('results') || responseBody.containsKey('data')) && responseBody.isNotEmpty && !(responseBody.values.first is List) ) {
             print('Formato de respuesta inesperado para próximos combates (objeto sin clave de lista conocida): ${response.body}');
        }
      } else {
        print('Formato de respuesta inesperado para próximos combates (no es lista ni objeto): ${response.body}');
        throw Exception('Formato de respuesta inesperado para próximos combates');
      }
      
      if (combatsData is List) {
        return combatsData
            .map((data) => CombatInvitation.fromJson(data, currentUserId))
            .toList();
      } else {
         print('CombatData no es una lista después del parseo para próximos combates: $combatsData');
         throw Exception('Los datos de próximos combates procesados no son una lista.');
      }

    } else {
      print('Error al cargar próximos combates: ${response.statusCode} - ${response.body}');
      throw Exception('Error al cargar próximos combates');
    }
  }

  Future<List<CombatInvitation>> getCombatHistory() async {
    final token = Session.token;
    final currentUserId = Session.userId;

    if (token == null || currentUserId == null) {
      print("Error: Usuario no autenticado o ID de usuario no disponible para el historial.");
      throw Exception('Usuario no autenticado');
    }

    final url = Uri.parse('$API_BASE_URL/combat/history/user/$currentUserId?pageSize=50');
    print('Fetching combat history from: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final dynamic responseBody = json.decode(response.body);
      List<dynamic> combatsData = [];

      if (responseBody is Map<String, dynamic> &&
          responseBody.containsKey('data') &&
          responseBody['data'] is Map &&
          responseBody['data'].containsKey('combats')) {
        combatsData = responseBody['data']['combats'];
      } else if (responseBody is Map<String, dynamic> && responseBody.containsKey('combats')) {
        combatsData = responseBody['combats'];
      } else if (responseBody is List) {
        combatsData = responseBody;
      } else {
        print('Formato de respuesta inesperado para historial de combates: ${response.body}');
        throw Exception('Formato de respuesta inesperado para historial de combates');
      }

      if (combatsData is List) {
        return combatsData
            .map((data) => CombatInvitation.fromJson(data, currentUserId))
            .toList();
      } else {
        print('CombatData no es una lista después del parseo para historial: $combatsData');
        throw Exception('Los datos de historial procesados no son una lista.');
      }
    } else {
      print('Error al cargar historial de combates: ${response.statusCode} - ${response.body}');
      throw Exception('Error al cargar historial de combates');
    }
  }

  Future<void> sendRating({
    required String combatId,
    required String fromUserId,
    required String toUserId,
    required int punctuality,
    required int attitude,
    required int technique,
    required int intensity,
    required int sportmanship,
    String? comment,
  }) async {
    final token = Session.token;
    final url = Uri.parse('$API_BASE_URL/ratings');
    final body = {
      'combat': combatId,
      'from': fromUserId,
      'to': toUserId,
      'punctuality': punctuality,
      'attitude': attitude,
      'technique': technique,
      'intensity': intensity,
      'sportmanship': sportmanship,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    };
    
    print('Enviando rating: $body');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al enviar la valoración: ${response.body}');
    }
  }

  // --- NUEVO MÉTODO AÑADIDO ---
  Future<bool> cancelCombat(String combatId, {String? reason}) async {
    final token = Session.token;
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    // Apuntamos a la ruta PATCH que nos indicaste
    final url = Uri.parse('$API_BASE_URL/combat/$combatId/cancel');
    final body = <String, String>{};
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final responseBody = json.decode(response.body);
      throw Exception('Error al cancelar el combate: ${responseBody['message'] ?? 'Error desconocido'}');
    }
  }
}