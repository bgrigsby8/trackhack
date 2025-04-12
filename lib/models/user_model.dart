// lib/models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String photoUrl;
  final List<String> projectIds;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl = '',
    this.projectIds = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'photoUrl': photoUrl,
      'projectIds': projectIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
      photoUrl: map['photoUrl'] as String? ?? '',
      projectIds: List<String>.from(map['projectIds'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? photoUrl,
    List<String>? projectIds,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      projectIds: projectIds ?? this.projectIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
