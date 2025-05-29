class Fighter {
  final String id;
  final String name;
  final String weight;
  final String email;
  final String city; // <- nuevo campo
  bool isFollowed; // Indica si el luchador está seguido por el usuario

  Fighter({
    required this.id,
    required this.name,
    required this.weight,
    required this.email,
    required this.city,
    this.isFollowed = false, // Valor predeterminado

  });

   factory Fighter.fromJson(Map<String, dynamic> json) {
    return Fighter(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      weight: json['weight'] ?? 'Peso no especificado',
      email: json['email'] ?? 'Sin email',
      city: json['city'] ?? 'Ciudad desconocida',
      isFollowed: json['isFollowed'] ?? false, // Asume que el JSON puede contener este campo
    );
  }
}
