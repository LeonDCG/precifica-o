class Profile {
  final String id;
  final String name;
  final String role; // 'admin' ou 'seller'
  final String? email;
  final double commissionPercent;

  Profile({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.commissionPercent = 30.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'commission_percent': commissionPercent,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'seller',
      email: map['email'],
      commissionPercent: ((map['commission_percent'] ?? map['commissionPercent'] ?? 30.0) as num).toDouble(),
    );
  }
}
