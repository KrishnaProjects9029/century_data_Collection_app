import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/excel_export_service.dart';
import '../../services/student_service.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/student_list_tile.dart';
import '../student/student_detail_screen.dart';
import '../student/student_form_screen.dart';
import '../student/student_list_screen.dart';
import '../admin/user_management_screen.dart';
import '../admin/export_screen.dart';
import '../admin/filter_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isExporting = false;
  String? _selectedMakerId; // null means all users

  Future<void> _quickExportAll() async {
    setState(() => _isExporting = true);
    try {
      final fs = StudentService();
      final exporter = ExcelExportService();
      final now = DateFormatter.nowIST();

      final students = await fs.getAllForExport();
      if (!mounted) return;

      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No student records found to export.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      final error = await exporter.exportAndShare(
        students,
        customFileName:
            'Student_Records_All_${DateFormatter.toFileName(now)}.xlsx',
      );

      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully exported ${students.length} student records!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserModelProvider);
    final totalAsync = ref.watch(totalCountProvider);
    final todayAsync = ref.watch(todayCountProvider);
    final myAsync = ref.watch(myCountProvider);
    final allStudentsAsync = ref.watch(allStudentsStreamProvider);
    final usersAsync = ref.watch(allUsersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const ConnectivityBanner(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 120,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                        child: userAsync.when(
                          data: (user) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Admin: ${user?.name ?? 'Administrator'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'ADMIN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Central Database • All Users Data & Excel Export',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        tooltip: 'Logout',
                        onPressed: () => _logout(context, ref),
                      ),
                    ],
                  ),

                  // Quick Excel Export Highlight Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withAlpha(50),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.table_chart_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Export All Data to Excel',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Export student records submitted by all operators (${totalAsync.valueOrNull ?? 0} records)',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1B5E20),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isExporting ? null : _quickExportAll,
                              child: _isExporting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    )
                                  : const Text(
                                      'EXPORT',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Stats Grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                      ),
                      delegate: SliverChildListDelegate([
                        StatsCard(
                          title: 'Total Students (All Users)',
                          value: totalAsync.valueOrNull?.toString() ?? '—',
                          icon: Icons.groups_outlined,
                          color: AppColors.statBlue,
                          onTap: () => _goToList(context, false),
                        ),
                        StatsCard(
                          title: "Today's Entries",
                          value: todayAsync.valueOrNull?.toString() ?? '—',
                          icon: Icons.today_outlined,
                          color: AppColors.statGreen,
                        ),
                        StatsCard(
                          title: 'My Submissions',
                          value: myAsync.valueOrNull?.toString() ?? '—',
                          icon: Icons.person_outlined,
                          color: AppColors.statOrange,
                          onTap: () => _goToList(context, true),
                        ),
                        StatsCard(
                          title: 'Excel Export Options',
                          value: 'Options →',
                          icon: Icons.file_download_outlined,
                          color: AppColors.statPurple,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ExportScreen()),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  // Quick Action Tiles
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.95,
                          children: [
                            _ActionCard(
                              icon: Icons.person_add_outlined,
                              label: 'Add Student',
                              color: AppColors.primary,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const StudentFormScreen()),
                              ),
                            ),
                            _ActionCard(
                              icon: Icons.list_alt_outlined,
                              label: 'All Students',
                              color: AppColors.statBlue,
                              onTap: () => _goToList(context, false),
                            ),
                            _ActionCard(
                              icon: Icons.search_outlined,
                              label: 'Search',
                              color: AppColors.statGreen,
                              onTap: () =>
                                  _goToList(context, false, openSearch: true),
                            ),
                            _ActionCard(
                              icon: Icons.filter_list_outlined,
                              label: 'Filter',
                              color: AppColors.statOrange,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const FilterScreen()),
                              ),
                            ),
                            _ActionCard(
                              icon: Icons.file_download_outlined,
                              label: 'Export Excel',
                              color: AppColors.statPurple,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ExportScreen()),
                              ),
                            ),
                            _ActionCard(
                              icon: Icons.manage_accounts_outlined,
                              label: 'Manage Users',
                              color: AppColors.adminBadge,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const UserManagementScreen()),
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),

                  // Data Inserted by All Users (Live Stream) Header & Filter
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Data Inserted from Users',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _goToList(context, false),
                                child: const Text('View All >'),
                              ),
                            ],
                          ),
                          // Filter by Maker dropdown
                          usersAsync.when(
                            data: (users) {
                              final activeUsers =
                                  users.where((u) => u.isActive).toList();
                              if (activeUsers.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    value: _selectedMakerId,
                                    isExpanded: true,
                                    hint: const Text(
                                      'Filter by User: All Users',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textPrimary),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          '👤 All Users (Showing everything)',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                      ),
                                      ...activeUsers.map(
                                        (u) => DropdownMenuItem(
                                          value: u.id,
                                          child: Text(
                                            '👤 ${u.name} (${u.role})',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      setState(() => _selectedMakerId = val);
                                    },
                                  ),
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Data List
                  allStudentsAsync.when(
                    data: (students) {
                      // Filter by selected maker if set
                      final displayed = _selectedMakerId == null
                          ? students
                          : students
                              .where((s) => s.makerUserId == _selectedMakerId)
                              .toList();

                      if (displayed.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.inbox_outlined,
                                      size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No records found.',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Take the top 15 most recent for the dashboard feed
                      final feedList = displayed.take(15).toList();

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final student = feedList[index];
                            return StudentListTile(
                              student: student,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentDetailScreen(
                                      studentId: student.id),
                                ),
                              ),
                            );
                          },
                          childCount: feedList.length,
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      ),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Error loading data: $e',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentFormScreen()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add Student',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _goToList(BuildContext context, bool myOnly, {bool openSearch = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentListScreen(
          myOnly: myOnly,
          openSearchOnLoad: openSearch,
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout from Admin Portal?',
      confirmText: 'LOGOUT',
      confirmColor: AppColors.error,
      icon: Icons.logout,
    );
    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
    }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
