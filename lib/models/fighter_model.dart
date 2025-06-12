class Fighter {
  final String id;
  final String name;
  final String weight;
  final String email;
  final String city; // <- nuevo campo
  final String? boxingVideo; // <-- Añade esto
  final String? profilePicture; // <-- Añade esto



  Fighter({
    required this.id,
    required this.name,
    required this.weight,
    required this.email,
    required this.city,
    this.boxingVideo, // <-- Añade esto
    this.profilePicture, // <-- Añade esto


  });

   factory Fighter.fromJson(Map<String, dynamic> json) {
    return Fighter(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      weight: json['weight'] ?? 'Peso no especificado',
      email: json['email'] ?? 'Sin email',
      city: json['city'] ?? 'Ciudad desconocida',
      boxingVideo: json['boxingVideo'], // <-- Añade esto
      profilePicture: json['profilePicture'], // <-- Añade esto


    );
  }
}
