import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get firebaseUser => _auth.currentUser;

  // Stream for auth state changes (used in SplashScreen)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login
  Future<UserModel?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) return _mapFirebaseUser(cred.user!);
      return null;
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e);
    }
  }

  // Sign Up
  Future<UserModel?> signUp(String email, String password, String fullName) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Set display name
      await cred.user?.updateDisplayName(fullName);
      await cred.user?.reload();
      return _mapFirebaseUser(_auth.currentUser!);
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e);
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Resend verification email
  Future<void> resendVerificationEmail(String email) async {
    await _auth.currentUser?.sendEmailVerification();
  }

  UserModel _mapFirebaseUser(User user) {
    return UserModel(
      userId: user.uid,
      email: user.email!,
      fullName: user.displayName,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  // Human-readable error messages
  Exception _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return Exception('Incorrect email or password.');
      case 'email-already-in-use':
        return Exception('An account already exists with this email.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please wait a moment and try again.');
      case 'network-request-failed':
        return Exception('No internet connection.');
      default:
        return Exception(e.message ?? 'Authentication failed.');
    }
  }
}