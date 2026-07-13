class Profile {
  final String id;
  final String name;
  final String role; // 'admin' ou 'seller'

  Profile({
    required this.id,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'seller',
    );
  }
}
