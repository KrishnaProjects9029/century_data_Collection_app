import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/confirmation_dialog.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _UserTile(user: users[i]),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add User',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _showCreateUserDialog(
      BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (_) => const _CreateUserDialog(),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final UserModel user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: user.isAdmin
                ? AppColors.adminBadge.withAlpha(30)
                : AppColors.dataEntryBadge.withAlpha(30),
            child: Icon(
              user.isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
              color: user.isAdmin ? AppColors.adminBadge : AppColors.dataEntryBadge,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    if (!user.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('INACTIVE',
                            style: TextStyle(
                                color: AppColors.error,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                Text(user.email,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isAdmin
                        ? AppColors.adminBadge.withAlpha(20)
                        : AppColors.dataEntryBadge.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(
                      color: user.isAdmin
                          ? AppColors.adminBadge
                          : AppColors.dataEntryBadge,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) =>
                _handleAction(context, ref, user, action),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: const Row(children: [
                  Icon(Icons.edit_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Edit')
                ]),
              ),
              PopupMenuItem(
                value: user.isActive ? 'deactivate' : 'activate',
                child: Row(children: [
                  Icon(
                      user.isActive
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                      size: 16),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'Deactivate' : 'Activate')
                ]),
              ),
              PopupMenuItem(
                value: 'reset',
                child: const Row(children: [
                  Icon(Icons.lock_reset_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Reset Password')
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, UserModel user, String action) async {
    final service = ref.read(userServiceProvider);
    switch (action) {
      case 'edit':
        await showDialog(
          context: context,
          builder: (_) => _EditUserDialog(user: user),
        );
        break;
      case 'activate':
      case 'deactivate':
        final newStatus = action == 'activate';
        final confirmed = await showConfirmationDialog(
          context: context,
          title: newStatus ? 'Activate User' : 'Deactivate User',
          message: newStatus
              ? 'Activate ${user.name}?'
              : 'Deactivate ${user.name}? They will not be able to login.',
          confirmText: newStatus ? 'ACTIVATE' : 'DEACTIVATE',
          confirmColor: newStatus ? AppColors.success : AppColors.warning,
        );
        if (confirmed == true) {
          await service.toggleUserStatus(user.id, newStatus);
        }
        break;
      case 'reset':
        await service.sendPasswordReset(user.email);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Password reset email sent.'),
            backgroundColor: AppColors.success,
          ));
        }
        break;
    }
  }
}

class _CreateUserDialog extends ConsumerStatefulWidget {
  const _CreateUserDialog();

  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = AppConstants.roleDataEntry;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final service = ref.read(userServiceProvider);
    final error = await service.createUser(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: _role,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _error = error);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('User created successfully.'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New User'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name *'),
                validator: (v) => Validators.required(v, 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *'),
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password *'),
                validator: Validators.password,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [
                  DropdownMenuItem(
                    value: AppConstants.roleAdmin,
                    child: const Text('Admin'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.roleDataEntry,
                    child: const Text('Data Entry'),
                  ),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: _loading ? null : _create,
          child: _loading
              ? const SpinKitThreeBounce(color: Colors.white, size: 16)
              : const Text('CREATE'),
        ),
      ],
    );
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  final UserModel user;

  const _EditUserDialog({required this.user});

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  late final TextEditingController _nameCtrl;
  late String _role;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _role = widget.user.role;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final service = ref.read(userServiceProvider);
    await service.updateUser(widget.user.id,
        name: _nameCtrl.text.trim(), role: _role);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: [
              DropdownMenuItem(
                value: AppConstants.roleAdmin,
                child: const Text('Admin'),
              ),
              DropdownMenuItem(
                value: AppConstants.roleDataEntry,
                child: const Text('Data Entry'),
              ),
            ],
            onChanged: (v) => setState(() => _role = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SpinKitThreeBounce(color: Colors.white, size: 16)
              : const Text('SAVE'),
        ),
      ],
    );
  }
}
