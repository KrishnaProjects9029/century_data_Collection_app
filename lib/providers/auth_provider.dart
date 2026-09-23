import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// ── Service ────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── Supabase Auth State ────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── Current User Profile Model ─────────────────
final currentUserModelProvider = StreamProvider<UserModel?>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return authAsync.when(
    data: (state) {
      final user = state.session?.user ?? Supabase.instance.client.auth.currentUser;
      if (user == null) return Stream.value(null);
      return ref.watch(authServiceProvider).currentUserModelStream();
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ── UI States ──────────────────────────────────
final loginLoadingProvider = StateProvider<bool>((ref) => false);
final loginErrorProvider = StateProvider<String?>((ref) => null);
