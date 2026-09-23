import '../core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // ADMIN or DATA_ENTRY
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isDataEntry => role == AppConstants.roleDataEntry;

  factory UserModel.fromMap(Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return UserModel(
      id: (data['id'] ?? '').toString(),
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? AppConstants.roleDataEntry,
      isActive: data['is_active'] ?? data['isActive'] ?? true,
      createdAt: parseDate(data['created_at'] ?? data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
