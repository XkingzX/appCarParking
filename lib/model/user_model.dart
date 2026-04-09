// models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String role;
  final num balance;
  final String? avatarUrl;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.balance,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      balance: _parseBalance(json['balance']),
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
  static num _parseBalance(dynamic balance) {
    if (balance == null) return 0;
    if (balance is num) return balance;
    if (balance is String) return num.tryParse(balance) ?? 0;
    if (balance is int) return balance;
    if (balance is double) return balance;
    return 0;
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'balance': balance.toInt(),
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}