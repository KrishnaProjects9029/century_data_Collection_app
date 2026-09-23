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
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(totalCountProvider);
                  ref.invalidate(todayCountProvider);
                  ref.invalidate(myCountProvider);
                  ref.invalidate(allStudentsStreamProvider);
                  ref.invalidate(allUsersStreamProvider);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                  // Compact Modern SaaS Header
                  SliverAppBar(
                    expandedHeight: 88,
                    toolbarHeight: 88,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    flexibleSpace: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            // Profile Avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  const Color(0xFF2563EB).withOpacity(0.1),
                              child: Text(
                                (userAsync.valueOrNull?.name.isNotEmpty == true
                                        ? userAsync.valueOrNull!.name[0]
                                        : 'K')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // User Info & Badges
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          userAsync.valueOrNull?.name ?? 'Krishna',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB)
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF2563EB)
                                                .withOpacity(0.25),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Text(
                                          'ADMIN',
                                          style: TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Central Database • All users data & Excel export',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Logout Button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                tooltip: 'Logout',
                                onPressed: () => _logout(context, ref),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Premium "Export Data" Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF059669).withOpacity(0.22),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 360;
                            final content = Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.table_view_rounded,
                                    color: Color(0xFF059669),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Export All Data',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Export student records submitted by all operators (${totalAsync.valueOrNull ?? 0} records)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            final button = ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isExporting ? null : _quickExportAll,
                              icon: _isExporting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.file_download_rounded,
                                      size: 18),
                              label: const Text(
                                'EXPORT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  content,
                                  const SizedBox(height: 14),
                                  button,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: content),
                                const SizedBox(width: 12),
                                button,
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Stats Grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.crossAxisExtent > 640;
                        final crossAxisCount = isWide ? 4 : 2;
                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: isWide ? 1.35 : 1.18,
                          ),
                          delegate: SliverChildListDelegate([
                            StatsCard(
                              title: 'Total Students',
                              value: totalAsync.valueOrNull?.toString() ?? '0',
                              subtitle: 'All-time registered',
                              icon: Icons.groups_rounded,
                              color: AppColors.statBlue,
                              onTap: () => _goToList(context, false),
                            ),
                            StatsCard(
                              title: "Today's Entries",
                              value: todayAsync.valueOrNull?.toString() ?? '0',
                              subtitle: 'Recorded today',
                              icon: Icons.event_available_rounded,
                              color: const Color(0xFF059669),
                              onTap: () => _goToList(context, false),
                            ),
                            StatsCard(
                              title: 'Active Operators',
                              value: usersAsync.when(
                                data: (users) => users
                                    .where((u) => u.isActive && !u.isAdmin)
                                    .length
                                    .toString(),
                                loading: () => '...',
                                error: (_, __) => '0',
                              ),
                              subtitle: 'Team members',
                              icon: Icons.badge_outlined,
                              color: const Color(0xFFD97706),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const UserManagementScreen()),
                              ),
                            ),
                            StatsCard(
                              title: 'Export Options',
                              value: 'Open →',
                              subtitle: 'Custom Excel sheets',
                              icon: Icons.table_view_rounded,
                              color: const Color(0xFF7C3AED),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ExportScreen()),
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),

                  // Quick Action Tiles
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Quick Actions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = constraints.maxWidth > 800;
                              final isTablet = constraints.maxWidth > 500;
                              final cols = isDesktop ? 6 : (isTablet ? 3 : 2);
                              final aspectRatio =
                                  isDesktop ? 1.6 : (isTablet ? 1.9 : 1.85);

                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: cols,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: aspectRatio,
                                children: [
                                  _ActionCard(
                                    icon: Icons.person_add_rounded,
                                    label: 'Add Student',
                                    subtitle: 'New entry form',
                                    color: AppColors.primary,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const StudentFormScreen()),
                                    ),
                                  ),
                                  _ActionCard(
                                    icon: Icons.format_list_bulleted_rounded,
                                    label: 'All Students',
                                    subtitle: 'View database',
                                    color: AppColors.statBlue,
                                    onTap: () => _goToList(context, false),
                                  ),
                                  _ActionCard(
                                    icon: Icons.search_rounded,
                                    label: 'Search',
                                    subtitle: 'Instant lookup',
                                    color: const Color(0xFF059669),
                                    onTap: () => _goToList(context, false,
                                        openSearch: true),
                                  ),
                                  _ActionCard(
                                    icon: Icons.filter_alt_rounded,
                                    label: 'Filter Data',
                                    subtitle: 'Date & school',
                                    color: const Color(0xFFD97706),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const FilterScreen()),
                                    ),
                                  ),
                                  _ActionCard(
                                    icon: Icons.receipt_long_rounded,
                                    label: 'Excel Options',
                                    subtitle: 'Custom downloads',
                                    color: const Color(0xFF7C3AED),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const ExportScreen()),
                                    ),
                                  ),
                                  _ActionCard(
                                    icon: Icons.manage_accounts_rounded,
                                    label: 'Manage Users',
                                    subtitle: 'Team accounts',
                                    color: const Color(0xFFDC2626),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const UserManagementScreen()),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Data Inserted by All Users (Live Stream) Header & Filter
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.45),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Live Submissions Feed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  visualDensity: VisualDensity.compact,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: () => _goToList(context, false),
                                icon: const Text(
                                  'View All',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                label: const Icon(Icons.arrow_forward_rounded,
                                    size: 15),
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
                                margin:
                                    const EdgeInsets.only(top: 8, bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    value: _selectedMakerId,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                    hint: const Text(
                                      'Filter by Operator: All Users',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          '👥 All Operators (All submissions)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      ...activeUsers.map(
                                        (u) => DropdownMenuItem(
                                          value: u.id,
                                          child: Text(
                                            '👤 ${u.name} (${u.role})',
                                            style:
                                                const TextStyle(fontSize: 13),
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
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primary.withOpacity(0.06),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.inbox_outlined,
                                        size: 40,
                                        color: AppColors.primary
                                            .withOpacity(0.6)),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No records found',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'New student entries will show up here live.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                    ),
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
                        padding: EdgeInsets.all(36),
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

                  // Bottom padding so FAB never covers the last item
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
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
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Add Student',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            letterSpacing: 0.2,
          ),
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
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.16), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


