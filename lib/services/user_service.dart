import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Admin-only service for managing user accounts in Supabase.
class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  // ──────────────────────────────────────────────
  // LIST
  // ──────────────────────────────────────────────

  /// Stream of all users from profiles table
  Stream<List<UserModel>> allUsersStream() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((list) => list.map(UserModel.fromMap).toList());
  }

  // ──────────────────────────────────────────────
  // CREATE
  // ──────────────────────────────────────────────

  /// Creates a user account in Supabase and inserts their profile.
  /// Returns error message or null on success.
  Future<String?> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name.trim(),
          'role': role,
        },
      );

      final user = response.user;
      if (user == null) {
        return 'User creation failed. Please check credentials.';
      }

      // Ensure profile record exists in profiles table
      await _client.from('profiles').upsert({
        'id': user.id,
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'is_active': true,
      });

      return null;
    } on AuthException catch (e) {
      return e.message;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return 'Failed to create user. Please try again.\n$e';
    }
  }

  // ──────────────────────────────────────────────
  // UPDATE
  // ──────────────────────────────────────────────

  Future<String?> updateUser(
    String uid, {
    String? name,
    String? role,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name.trim();
      if (role != null) updates['role'] = role;
      if (isActive != null) updates['is_active'] = isActive;

      await _client.from('profiles').update(updates).eq('id', uid);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return 'Update failed: $e';
    }
  }

  // ──────────────────────────────────────────────
  // RESET PASSWORD
  // ──────────────────────────────────────────────

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Failed to send reset email: $e';
    }
  }

  // ──────────────────────────────────────────────
  // ACTIVATE / DEACTIVATE
  // ──────────────────────────────────────────────

  Future<String?> toggleUserStatus(String uid, bool isActive) async {
    return updateUser(uid, isActive: isActive);
  }
}
