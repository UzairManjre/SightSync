class UserModel {
  final int? userId;
  final String email;
  final String passwordHash;
  final DateTime createdAt;

  UserModel({
    this.userId,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
  });

  // Convert a UserModel into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'email': email,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Implement toString to make it easier to see information about
  // each user when using the print statement.
  @override
  String toString() {
    return 'UserModel{userId: $userId, email: $email, passwordHash: $passwordHash, createdAt: $createdAt}';
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'],
      email: map['email'],
      passwordHash: map['password_hash'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
