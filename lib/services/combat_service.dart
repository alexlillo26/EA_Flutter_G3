// lib/services/combat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:face2face_app/config/app_config.dart';
import 'package:face2face_app/session.dart';
import 'package:face2face_app/models/combat_invitation_model.dart'; // Importa el modelo

class CombatService {
  Future<List<CombatInvitation>> getReceivedInvitations() async {
    final token = Session.token;
    final currentUserId = Session.userId; // Necesario para el factory del modelo

    if (token == null || currentUserId == null) {
      print("Error: Usuario no autenticado o ID de usuario no disponible.");
      throw Exception('Usuario no autenticado');
    }

    // Endpoint para obtener invitaciones RECIBIDAS donde el usuario es 'opponent' y status 'pending'
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
      // Si success no es true o 'invitations' no está presente o no es una lista
      print('Formato de respuesta inesperado para invitaciones recibidas: ${response.body}');
      throw Exception('Formato de respuesta inesperado para invitaciones recibidas');
    } else {
      print('Error al cargar invitaciones recibidas: ${response.statusCode} - ${response.body}');
      throw Exception('Error al cargar invitaciones recibidas');
    }
  }

  Future<bool> respondToCombatInvitation(String combatId, String statusResponse) async {
    // statusResponse debe ser "accepted" o "rejected"
    final token = Session.token;
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    // Tu Swagger indica PATCH para /api/combat/:id/respond, pero tu controlador
    // respondToInvitationHandler no especifica método, así que depende de tu router.
    // Asumamos que la ruta en Express es PATCH. Si es POST, cambia http.patch a http.post
    final url = Uri.parse('$API_BASE_URL/combat/$combatId/respond');
    print('Responding to invitation $combatId with $statusResponse to URL: $url');
    
    final response = await http.patch( // O http.post si tu ruta es POST
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'status': statusResponse}),
    );

    if (response.statusCode == 200 || response.statusCode == 204) { // 200 OK o 204 No Content
      print('Respuesta a invitación enviada exitosamente: ${response.statusCode}');
      return true;
    } else {
      print('Error al responder a la invitación: ${response.statusCode} - ${response.body}');
      final responseBody = json.decode(response.body);
      throw Exception('Error al responder a la invitación: ${responseBody['message'] ?? response.body}');
    }
  }

  // --- Funciones para las otras pestañas (esqueletos por ahora) ---

   Future<List<CombatInvitation>> getSentInvitations() async {
    final token = Session.token;
    final currentUserId = Session.userId; // Necesario para el factory del modelo y para saber a quién mostrarle la info

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

      // El backend podría devolver la lista directamente o un objeto con una clave.
      // Basado en getInvitationsHandler, /api/combat/invitations devuelve { success: true, invitations: [] }
      // Asumimos que /api/combat/sent-invitations (getSentInvitationsHandler) devuelve algo similar
      // o directamente una lista. Ajusta según la respuesta REAL de tu API.
      if (responseBody is List) {
        invitationsData = responseBody;
      } else if (responseBody is Map<String, dynamic>) {
        if (responseBody['success'] == true && responseBody['invitations'] != null) {
          invitationsData = responseBody['invitations'];
        } else if (responseBody.containsKey('invitations')) { // Si solo tiene la clave invitations
           invitationsData = responseBody['invitations'];
        } else if (responseBody.containsKey('combats')) { // Si devuelve 'combats' en lugar de 'invitations'
           invitationsData = responseBody['combats'];
        }
         else {
          // Si es un objeto pero no tiene la clave esperada, podría ser un error o un formato diferente
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
    final currentUserId = Session.userId; // Necesario para el factory del modelo

    if (token == null || currentUserId == null) {
      print("Error: Usuario no autenticado o ID de usuario no disponible para próximos combates.");
      throw Exception('Usuario no autenticado');
    }

    // Endpoint para obtener combates futuros (asumimos que son los 'accepted' con fecha futura)
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

      // Ajusta esto según la estructura REAL de la respuesta de tu API /api/combat/future
      // Puede ser una lista directa, o un objeto con una clave como 'combats' o 'results'.
      if (responseBody is List) {
        combatsData = responseBody;
      } else if (responseBody is Map<String, dynamic>) {
        // Intenta con claves comunes si es un objeto
        combatsData = responseBody['combats'] ?? 
                      responseBody['results'] ?? 
                      responseBody['data'] ?? 
                      []; // Si ninguna clave coincide, usa una lista vacía
        if (responseBody is Map<String, dynamic> && !(responseBody.containsKey('combats') || responseBody.containsKey('results') || responseBody.containsKey('data')) && responseBody.isNotEmpty && !(responseBody.values.first is List) ) {
            // Si es un objeto pero no tiene una clave de lista conocida y no está vacío,
            // podría ser un solo objeto de combate, lo envolvemos en una lista.
            // O podría ser un error de formato no esperado.
            // Esta lógica es especulativa, depende de tu API.
            // Si esperas una lista, y no llega, es mejor lanzar un error.
             print('Formato de respuesta inesperado para próximos combates (objeto sin clave de lista conocida): ${response.body}');
             // Descomenta la siguiente línea si este caso debe ser un error:
             // throw Exception('Formato de respuesta inesperado para próximos combates');
        }
      } else {
        print('Formato de respuesta inesperado para próximos combates (no es lista ni objeto): ${response.body}');
        throw Exception('Formato de respuesta inesperado para próximos combates');
      }
      
      if (combatsData is List) {
        return combatsData
            .map((data) => CombatInvitation.fromJson(data, currentUserId)) // Reutilizamos el modelo
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
    final currentUserId = Session.userId; // Necesario para el endpoint y para el factory del modelo

    if (token == null || currentUserId == null) {
      print("Error: Usuario no autenticado o ID de usuario no disponible para el historial.");
      throw Exception('Usuario no autenticado');
    }

    // Endpoint para obtener el historial de combates del usuario.
    // Podrías necesitar añadir un query param como ?status=completed o ?status=finished
    // o tu backend podría tener un endpoint específico /api/combat/history
    // Usando el endpoint existente y asumiendo que podemos filtrar o que devuelve estados:
    final url = Uri.parse('$API_BASE_URL/combat/boxer/$currentUserId?pageSize=50'); // Pedimos más para el historial
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

      // El endpoint /api/combat/boxer/{boxerId} devuelve un objeto { combats, totalPages }
      if (responseBody is Map<String, dynamic> && responseBody.containsKey('combats')) {
        combatsData = responseBody['combats'];
      } else {
        print('Formato de respuesta inesperado para historial de combates: ${response.body}');
        throw Exception('Formato de respuesta inesperado para historial de combates');
      }
      
      if (combatsData is List) {
        // Aquí podrías querer filtrar adicionalmente por estados como 'completed', 'rejected', 'cancelled'
        // si el backend no lo hace por ti.
        return combatsData
            .map((data) => CombatInvitation.fromJson(data, currentUserId)) // Reutilizamos el modelo
            .where((combat) => combat.status == 'completed' || combat.status == 'rejected') // Ejemplo de filtro cliente
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
}