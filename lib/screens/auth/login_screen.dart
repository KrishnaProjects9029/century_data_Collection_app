import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMsg;

  // Toggle between Standard User login and dedicated Admin login
  bool _isAdminPortal = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final authService = ref.read(authServiceProvider);
    final (user, error) = await authService.signIn(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
      return;
    }

    // Role-specific check if user selected Admin Portal
    if (_isAdminPortal && user != null && !user.isAdmin) {
      // User tried to log into Admin portal with a Data Entry account
      await authService.signOut();
      setState(() {
        _errorMsg =
            'Access Denied: Account "${user.email}" has Data Entry rights, not Admin rights. Please switch to "Data Entry Login" tab.';
      });
      return;
    }

    // Navigation is automatically handled by _AppRouter in main.dart
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMsg = 'Please enter your email address first.');
      return;
    }

    setState(() => _loading = true);
    final authService = ref.read(authServiceProvider);
    final error = await authService.sendPasswordResetEmail(email);
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Please check your inbox.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _showAdminSetupGuide() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppColors.adminBadge),
            SizedBox(width: 8),
            Text('Admin Account Setup'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To log in as Administrator:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '1. Create your account in Supabase Dashboard → Authentication → Users.\n'
                '2. In Supabase SQL Editor, run:\n'
                '   update public.profiles set role = \'ADMIN\' where email = \'your-email@example.com\';\n'
                '3. Once logged in as Admin, you can:\n'
                '   • View all student submissions from all users\n'
                '   • Search, filter, edit, and delete records\n'
                '   • Export all records to Excel with exact column order\n'
                '   • Create & manage Data Entry user accounts from inside the app.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _isAdminPortal ? AppColors.adminBadge : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Brand Logo / Header
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isAdminPortal
                          ? [AppColors.adminBadge, const Color(0xFF5B21B6)]
                          : [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isAdminPortal
                        ? Icons.admin_panel_settings_rounded
                        : Icons.school_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Krishna Century',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isAdminPortal
                    ? 'Administrator Portal'
                    : 'Student Registration & Data App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _isAdminPortal ? AppColors.adminBadge : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Role Tabs (Data Entry vs Admin Login)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_isAdminPortal) {
                            setState(() {
                              _isAdminPortal = false;
                              _errorMsg = null;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isAdminPortal ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isAdminPortal
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(20),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 18,
                                color: !_isAdminPortal
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Data Entry',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: !_isAdminPortal
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_isAdminPortal) {
                            setState(() {
                              _isAdminPortal = true;
                              _errorMsg = null;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isAdminPortal ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isAdminPortal
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(20),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 18,
                                color: _isAdminPortal
                                    ? AppColors.adminBadge
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Admin Login',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _isAdminPortal
                                      ? AppColors.adminBadge
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isAdminPortal ? 'Admin Portal' : 'Sign In',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: activeColor,
                            ),
                          ),
                          if (_isAdminPortal)
                            IconButton(
                              icon: const Icon(Icons.help_outline,
                                  color: AppColors.adminBadge, size: 20),
                              tooltip: 'Admin Setup Guide',
                              onPressed: _showAdminSetupGuide,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isAdminPortal
                            ? 'Access all users\' records, search, filter, edit & export to Excel.'
                            : 'Enter credentials to fill student registration forms.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Error message
                      if (_errorMsg != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.error.withAlpha(60)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMsg!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: _isAdminPortal
                              ? 'Admin Email Address'
                              : 'Username / Email',
                          prefixIcon: Icon(
                            _isAdminPortal
                                ? Icons.admin_panel_settings_outlined
                                : Icons.email_outlined,
                            color: activeColor,
                          ),
                        ),
                        validator: Validators.email,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline, color: activeColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: Validators.password,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 8),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Login button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeColor,
                          ),
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SpinKitThreeBounce(
                                  color: Colors.white, size: 22)
                              : Text(
                                  _isAdminPortal
                                      ? 'LOGIN TO ADMIN PORTAL'
                                      : 'LOGIN',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (!_isAdminPortal)
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.security, size: 16),
                    label: const Text('Need Admin Access? Switch to Admin Login'),
                    onPressed: () => setState(() => _isAdminPortal = true),
                  ),
                )
              else
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('How to setup your first Admin account'),
                    onPressed: _showAdminSetupGuide,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
