import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:face2face_app/config/app_config.dart';
import 'package:face2face_app/session.dart';
// ¡OJO! Importa el nuevo fichero de modelo.
// Puede que tengas que eliminar la importación del antiguo 'user_ratings_model.dart' si lo renombras.
// Para este ejemplo, asumimos que el modelo está en el mismo fichero.
import '../models/user_ratings_model.dart'; 

class RatingService {
  // El método ahora devuelve el nuevo modelo UserRatingsResponse
  Future<UserRatingsResponse> getUserRatings(String userId) async {
    final token = Session.token;
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final url = Uri.parse('$API_BASE_URL/ratings/user/$userId');
    print('Fetching user ratings from: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('RAW JSON RESPONSE for ratings: ${response.body}');
      final responseBody = json.decode(response.body);
      // Devuelve una instancia del nuevo modelo
      return UserRatingsResponse.fromJson(responseBody);
    } else {
      print('Error al cargar ratings: ${response.statusCode} - ${response.body}');
      throw Exception('Error al cargar las valoraciones');
    }
  }
}