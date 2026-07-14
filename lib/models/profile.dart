class Profile {
  final String id;
  final String name;
  final String role; // 'admin' ou 'seller'
  final String? email;

  Profile({
    required this.id,
    required this.name,
    required this.role,
    this.email,
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
      email: map['email'],
    );
  }
}
