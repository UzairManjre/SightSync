import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  // Login
  Future<UserModel?> login(String email, String password) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) return _mapSupabaseUser(res.user!);
      return null;
    } catch (e) {
      print("Login Error: $e");
      rethrow;
    }
  }

  // Sign Up
  Future<UserModel?> signUp(String email, String password, String fullName) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName}, // Triggers your DB function
      );
      if (res.user != null) return _mapSupabaseUser(res.user!);
      return null;
    } catch (e) {
      print("Signup Error: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Correct Mapping using String ID
  UserModel _mapSupabaseUser(User user) {
    return UserModel(
      userId: user.id, // Now a String, matching the model
      email: user.email!,
      fullName: user.userMetadata?['full_name'],
      createdAt: DateTime.parse(user.createdAt),
    );
  }
}