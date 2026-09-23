import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/admin_dashboard_screen.dart';
import 'screens/dashboard/data_entry_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: KrishnaCenturyApp()));
}

class KrishnaCenturyApp extends ConsumerWidget {
  const KrishnaCenturyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Krishna Century',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AppRouter(),
    );
  }
}

/// Listens to Supabase auth state and routes accordingly.
class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        final user = state.session?.user ?? Supabase.instance.client.auth.currentUser;
        if (user == null) return const LoginScreen();
        // User is signed in — resolve their role
        return const _RoleRouter();
      },
      loading: () {
        // Check if there is an active cached session
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) return const _RoleRouter();
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connecting to Supabase...'),
              ],
            ),
          ),
        );
      },
      error: (e, _) => Scaffold(
        body: Center(
          child: Text('Initialization error: $e'),
        ),
      ),
    );
  }
}

/// Once the user is authenticated, fetch their role and show the correct dashboard.
class _RoleRouter extends ConsumerWidget {
  const _RoleRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const LoginScreen();
        if (!user.isActive) {
          // Deactivated user — sign out and show login
          ref.read(authServiceProvider).signOut();
          return const LoginScreen();
        }
        return user.isAdmin
            ? const AdminDashboardScreen()
            : const DataEntryDashboardScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const LoginScreen(),
    );
  }
}
