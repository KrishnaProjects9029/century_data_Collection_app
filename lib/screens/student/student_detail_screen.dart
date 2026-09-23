import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/student_service.dart';
import '../../widgets/confirmation_dialog.dart';
import 'student_edit_screen.dart';

class StudentDetailScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;
    final adminName = userAsync.valueOrNull?.name ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<StudentModel?>(
        future: StudentService().getStudent(studentId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final student = snap.data;
          if (student == null) {
            return const Center(child: Text('Record not found.'));
          }

          return CustomScrollView(
            slivers: [
              // Photo hero header
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (isAdmin) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                StudentEditScreen(student: student)),
                      ),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: () => _delete(context, ref, student, adminName),
                      tooltip: 'Delete',
                    ),
                  ]
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: student.photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: student.photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => _photoPlaceholder(),
                        )
                      : _photoPlaceholder(),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + serial
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              student.fullName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Sr. #${student.serialNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(student.schoolName,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 15)),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),

                      _section('Personal Details', [
                        _row('First Name', student.firstName),
                        _row('Middle Name', student.middleName),
                        _row('Surname', student.surname),
                        _row('School Name', student.schoolName),
                        _row('Bro/Sis In Class', student.siblingClass),
                      ]),

                      _section('Family Details', [
                        _row('Parents', student.parents),
                        _row('Mother Contact', student.motherContact),
                        _row('Father Contact', student.fatherContact),
                      ]),

                      _section('Address', [
                        _row('Full Address', student.fullAddress),
                        _row('Area', student.area +
                            (student.otherArea.isNotEmpty
                                ? ' — ${student.otherArea}'
                                : '')),
                        _row('Landmark', student.landmark +
                            (student.otherLandmark.isNotEmpty
                                ? ' — ${student.otherLandmark}'
                                : '')),
                      ]),

                      _section('Record Info', [
                        _row('Maker', student.makerName),
                        _row('Submitted', DateFormatter.toDisplay(student.submittedAtIST)),
                        if (student.updatedAt != null) ...[
                          _row('Last Updated', DateFormatter.toDisplay(student.updatedAtIST!)),
                          _row('Updated By', student.updatedBy),
                        ],
                      ]),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: AppColors.primary.withAlpha(20),
      child: const Center(
        child: Icon(Icons.person, size: 80, color: AppColors.textHint),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(children: rows),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref,
      StudentModel student, String adminName) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Record',
      message:
          'Are you sure you want to delete this student record?\nThis action cannot be undone.',
      confirmText: 'DELETE',
      confirmColor: AppColors.error,
      icon: Icons.delete_forever_outlined,
    );
    if (confirmed != true) return;

    final error =
        await StudentService().softDeleteStudent(student.id);

    if (context.mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      } else {
        ref.invalidate(allStudentsStreamProvider);
        ref.invalidate(myStudentsStreamProvider);
        ref.invalidate(totalCountProvider);
        ref.invalidate(todayCountProvider);
        ref.invalidate(myCountProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record deleted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}
