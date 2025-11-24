class UserModel {
  final String userId;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'],
      avatarUrl: map['avatar_url'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }
}