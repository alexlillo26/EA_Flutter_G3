class Fighter {
  final String id;
  final String name;
  final String weight;
  final String email;
  final String city; // <- nuevo campo

  Fighter({
    required this.id,
    required this.name,
    required this.weight,
    required this.email,
    required this.city,
  });

  factory Fighter.fromJson(Map<String, dynamic> json) {
    return Fighter(
      id: json['_id'],
      name: json['name'],
      weight: json['weight'],
      email: json['email'],
      city: json['city'], 
    );
  }
}
