import 'dart:async';
import '../models/user_model.dart';

class AuthService {
  // Mock user for now
  UserModel? _currentUser;

  Future<UserModel?> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (email == "test@example.com" && password == "password") {
      _currentUser = UserModel(
        userId: 1,
        email: email,
        passwordHash: "hashed_password",
        createdAt: DateTime.now(),
      );
      return _currentUser;
    }
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
  }

  UserModel? get currentUser => _currentUser;
}
