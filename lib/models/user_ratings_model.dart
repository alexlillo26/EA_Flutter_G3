// Modelo para una única valoración individual
class Rating {
  final int punctuality;
  final int attitude;
  final int technique;
  final int intensity;
  final int sportmanship;

  Rating({
    required this.punctuality,
    required this.attitude,
    required this.technique,
    required this.intensity,
    required this.sportmanship,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    // Helper para parsear de forma segura, por si algún valor no viniera
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    return Rating(
      punctuality: parseInt(json['punctuality']),
      attitude: parseInt(json['attitude']),
      technique: parseInt(json['technique']),
      intensity: parseInt(json['intensity']),
      sportmanship: parseInt(json['sportmanship']),
    );
  }
}

// Modelo para la respuesta completa de la API
class UserRatingsResponse {
  final List<Rating> ratings;
  final int totalRatings;

  UserRatingsResponse({
    required this.ratings,
    required this.totalRatings,
  });

  // --- NUEVOS GETTERS PARA CADA CATEGORÍA ---

  // Función genérica para calcular la media de una propiedad
  double _calculateAverage(int Function(Rating r) getProperty) {
    if (ratings.isEmpty) return 0.0;
    final double total = ratings.fold(0, (sum, item) => sum + getProperty(item));
    return total / ratings.length;
  }

  double get averagePunctuality => _calculateAverage((r) => r.punctuality);
  double get averageAttitude => _calculateAverage((r) => r.attitude);
  double get averageTechnique => _calculateAverage((r) => r.technique);
  double get averageIntensity => _calculateAverage((r) => r.intensity);
  double get averageSportmanship => _calculateAverage((r) => r.sportmanship);


  factory UserRatingsResponse.fromJson(Map<String, dynamic> json) {
    final ratingsList = (json['ratings'] as List<dynamic>?) ?? [];
    return UserRatingsResponse(
      ratings: ratingsList.map((item) => Rating.fromJson(item)).toList(),
      totalRatings: json['totalRatings'] ?? 0,
    );
  }
}