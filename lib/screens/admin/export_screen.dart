import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/user_model.dart';
import '../../providers/student_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/student_service.dart';
import '../../services/excel_export_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _exporting = false;
  String? _message;
  Color _msgColor = AppColors.success;

  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedUserId;
  String? _selectedUserName;

  Future<void> _export(String type) async {
    setState(() {
      _exporting = true;
      _message = null;
    });

    try {
      final fs = StudentService();
      final exporter = ExcelExportService();
      final now = DateFormatter.nowIST();

      switch (type) {
        case 'all':
          final students = await fs.getAllForExport();
          final err = await exporter.exportAndShare(students,
              customFileName:
                  'Student_Records_All_${DateFormatter.toFileName(now)}.xlsx');
          _message = err ?? 'Exported ${students.length} records.';
          _msgColor = err != null ? AppColors.error : AppColors.success;
          break;

        case 'user':
          if (_selectedUserId == null) {
            _message = 'Please select a user to export their records.';
            _msgColor = AppColors.error;
            break;
          }
          final students = await fs.filter(makerUserId: _selectedUserId);
          final safeName = (_selectedUserName ?? 'User').replaceAll(' ', '_');
          final err = await exporter.exportAndShare(students,
              customFileName:
                  'Student_Records_${safeName}_${DateFormatter.toFileName(now)}.xlsx');
          _message = err ??
              'Exported ${students.length} records entered by $_selectedUserName.';
          _msgColor = err != null ? AppColors.error : AppColors.success;
          break;

        case 'today':
          final students = await fs.getTodayForExport();
          final err = await exporter.exportAndShare(students,
              customFileName:
                  'Student_Records_Today_${DateFormatter.toFileName(now)}.xlsx');
          _message = err ?? 'Exported ${students.length} records.';
          _msgColor = err != null ? AppColors.error : AppColors.success;
          break;

        case 'filtered':
          final filter = ref.read(activeFilterProvider);
          final students = await fs.filter(
            area: filter.area,
            landmark: filter.landmark,
            parents: filter.parents,
            schoolName: filter.schoolName,
            makerUserId: filter.makerUserId,
            dateFrom: filter.dateFrom,
            dateTo: filter.dateTo,
          );
          final err = await exporter.exportAndShare(students,
              customFileName:
                  'Student_Records_Filtered_${DateFormatter.toFileName(now)}.xlsx');
          _message = err ?? 'Exported ${students.length} filtered records.';
          _msgColor = err != null ? AppColors.error : AppColors.success;
          break;

        case 'dateRange':
          if (_fromDate == null || _toDate == null) {
            _message = 'Please select both From and To dates.';
            _msgColor = AppColors.error;
            break;
          }
          final students = await fs.getDateRangeForExport(_fromDate!, _toDate!);
          final err = await exporter.exportAndShare(students,
              customFileName:
                  'Student_Records_${DateFormatter.toFileName(_fromDate!)}_to_${DateFormatter.toFileName(_toDate!)}.xlsx');
          _message = err ?? 'Exported ${students.length} records.';
          _msgColor = err != null ? AppColors.error : AppColors.success;
          break;
      }
    } catch (e) {
      _message = 'Export failed: $e';
      _msgColor = AppColors.error;
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _selectDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _fromDate : _toDate) ?? DateFormatter.nowIST(),
      firstDate: DateTime(2020),
      lastDate: DateFormatter.nowIST().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export to Excel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Exact Column Order Guaranteed:\n'
                      'Sr. No. | Student First Name | Middle Name | Surname | School Name | Bro/Sis In Class (STD & DIV) | Parents | Mother Contact No. | Father Contact No. | Address In Full | Area | Other Area | Landmark | Other Landmark | Student Photo | Maker | Date & Time',
                      style: TextStyle(
                          color: AppColors.info, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Message feedback
            if (_message != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _msgColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _msgColor.withAlpha(60)),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                      color: _msgColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_exporting) ...[
              const Center(
                child: Column(
                  children: [
                    SpinKitWave(color: AppColors.primary, size: 36),
                    SizedBox(height: 14),
                    Text('Generating Excel spreadsheet...',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Option 1: All Records
              _ExportOption(
                icon: Icons.file_download_outlined,
                title: 'Export All Records',
                subtitle: 'All student records from all data entry users',
                color: AppColors.statBlue,
                onTap: () => _export('all'),
              ),
              const SizedBox(height: 12),

              // Option 2: Today's Records
              _ExportOption(
                icon: Icons.today_outlined,
                title: "Export Today's Records",
                subtitle: "Submissions recorded today (IST)",
                color: AppColors.statGreen,
                onTap: () => _export('today'),
              ),
              const SizedBox(height: 12),

              // Option 3: Filtered Records
              _ExportOption(
                icon: Icons.filter_list_outlined,
                title: 'Export Filtered Records',
                subtitle: 'Export using current filter criteria',
                color: AppColors.statOrange,
                onTap: () => _export('filtered'),
              ),
              const SizedBox(height: 20),

              // Option 4: By Specific User / Maker
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_pin_outlined,
                            color: AppColors.adminBadge, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Export by Specific User / Maker',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    usersAsync.when(
                      data: (users) {
                        final active = users.where((u) => u.isActive).toList();
                        return DropdownButtonFormField<String>(
                          value: _selectedUserId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select User (Maker)',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: active.map((u) {
                            return DropdownMenuItem(
                              value: u.id,
                              child: Text('${u.name} (${u.role})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            final selected =
                                active.firstWhere((u) => u.id == val);
                            setState(() {
                              _selectedUserId = val;
                              _selectedUserName = selected.name;
                            });
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading users list'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminBadge,
                      ),
                      icon: const Icon(Icons.file_download, size: 18),
                      label: Text(
                        _selectedUserName != null
                            ? 'Export Records by $_selectedUserName'
                            : 'Export Selected User\'s Records',
                      ),
                      onPressed: () => _export('user'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Option 5: Date Range
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Export by Date Range',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DateButton(
                            label: 'From Date',
                            date: _fromDate,
                            onTap: () => _selectDate(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateButton(
                            label: 'To Date',
                            date: _toDate,
                            onTap: () => _selectDate(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.date_range_outlined, size: 18),
                      label: const Text('Export Date Range'),
                      onPressed: () => _export('dateRange'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.file_download, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({required this.label, this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? DateFormatter.toReadable(date!) : label,
                style: TextStyle(
                  color:
                      date != null ? AppColors.textPrimary : AppColors.textHint,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
