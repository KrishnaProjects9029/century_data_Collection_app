import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Currently signed-in Supabase user.
  User? get currentUser => _client.auth.currentUser;

  /// Sign in with email and password.
  /// Returns (UserModel?, errorMessage).
  Future<(UserModel?, String?)> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return (null, 'Login failed. Please check your credentials.');
      }

      // Fetch user profile from profiles table
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        await _client.auth.signOut();
        return (null, 'User profile not found. Please contact your administrator.');
      }

      final userModel = UserModel.fromMap(data);

      if (!userModel.isActive) {
        await _client.auth.signOut();
        return (null, 'Your account has been deactivated. Please contact administrator.');
      }

      return (userModel, null);
    } on AuthException catch (e) {
      return (null, _authErrorMessage(e.message));
    } catch (e) {
      return (null, 'An unexpected error occurred. Please try again.\n$e');
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Send password reset email.
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Failed to send reset email. Please try again.';
    }
  }

  /// Fetch user profile for currently signed-in user.
  Future<UserModel?> getCurrentUserModel() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data == null) return null;
      return UserModel.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  /// Stream of current user's profile from profiles table.
  Stream<UserModel?> currentUserModelStream() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value(null);

    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((list) => list.isNotEmpty ? UserModel.fromMap(list.first) : null);
  }

  String _authErrorMessage(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('invalid login credentials') || lower.contains('invalid_grant')) {
      return 'Incorrect email or password.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email address has not been confirmed yet.';
    }
    if (lower.contains('too many requests')) {
      return 'Too many login attempts. Please try again later.';
    }
    return msg;
  }
}
