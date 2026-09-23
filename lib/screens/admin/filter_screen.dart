import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/user_model.dart';
import '../../providers/filter_provider.dart';
import '../../providers/user_provider.dart';
import '../student/student_list_screen.dart';

class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  // Local state mirroring FilterState
  String? _area;
  String? _landmark;
  String? _parents;
  final _schoolCtrl = TextEditingController();
  String? _makerUserId;
  String? _makerName;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    // Pre-populate from existing filter
    final current = ref.read(activeFilterProvider);
    _area = current.area;
    _landmark = current.landmark;
    _parents = current.parents;
    _schoolCtrl.text = current.schoolName ?? '';
    _makerUserId = current.makerUserId;
    _makerName = current.makerName;
    _dateFrom = current.dateFrom;
    _dateTo = current.dateTo;
  }

  @override
  void dispose() {
    _schoolCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    ref.read(activeFilterProvider.notifier).apply(FilterState(
      area: _area,
      landmark: _landmark,
      parents: _parents,
      schoolName:
          _schoolCtrl.text.trim().isEmpty ? null : _schoolCtrl.text.trim(),
      makerUserId: _makerUserId,
      makerName: _makerName,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    ));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => const StudentListScreen(myOnly: false)),
    );
  }

  void _clear() {
    ref.read(activeFilterProvider.notifier).clear();
    setState(() {
      _area = null;
      _landmark = null;
      _parents = null;
      _schoolCtrl.clear();
      _makerUserId = null;
      _makerName = null;
      _dateFrom = null;
      _dateTo = null;
    });
  }

  Future<void> _selectDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          (isFrom ? _dateFrom : _dateTo) ?? DateFormatter.nowIST(),
      firstDate: DateTime(2020),
      lastDate: DateFormatter.nowIST().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Records'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _clear,
            child: const Text('Clear', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Area'),
            _dropdown(
                _area, AppConstants.areaOptions, (v) => setState(() => _area = v)),
            const SizedBox(height: 16),

            _label('Landmark'),
            _dropdown(_landmark, AppConstants.landmarkOptions,
                (v) => setState(() => _landmark = v)),
            const SizedBox(height: 16),

            _label('Parents'),
            _dropdown(_parents, AppConstants.parentOptions,
                (v) => setState(() => _parents = v)),
            const SizedBox(height: 16),

            _label('School Name'),
            TextFormField(
              controller: _schoolCtrl,
              decoration: const InputDecoration(hintText: 'Enter school name'),
            ),
            const SizedBox(height: 16),

            _label('Maker (Data Entry User)'),
            usersAsync.when(
              data: (users) {
                final dataEntryUsers = users
                    .where((u) => u.isActive)
                    .toList();
                return DropdownButtonFormField<String>(
                  value: _makerUserId,
                  isExpanded: true,
                  decoration: const InputDecoration(hintText: 'All makers'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...dataEntryUsers.map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.name),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _makerUserId = v;
                      _makerName = v == null
                          ? null
                          : dataEntryUsers
                              .firstWhere((u) => u.id == v)
                              .name;
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 20),

            _label('Date Range'),
            Row(
              children: [
                Expanded(
                  child: _DateBtn(
                    label: 'From Date',
                    date: _dateFrom,
                    onTap: () => _selectDate(true),
                    onClear: _dateFrom != null
                        ? () => setState(() => _dateFrom = null)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateBtn(
                    label: 'To Date',
                    date: _dateTo,
                    onTap: () => _selectDate(false),
                    onClear: _dateTo != null
                        ? () => setState(() => _dateTo = null)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.filter_list),
                label: const Text('APPLY FILTER'),
                onPressed: _apply,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('CLEAR FILTER'),
                onPressed: _clear,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            )),
      );

  Widget _dropdown(
      String? value, List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(hintText: 'All'),
      items: [
        const DropdownMenuItem(value: null, child: Text('All')),
        ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
      ],
      onChanged: onChanged,
    );
  }
}

class _DateBtn extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateBtn(
      {required this.label,
      this.date,
      required this.onTap,
      this.onClear});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date != null ? DateFormatter.toReadable(date!) : label,
                style: TextStyle(
                  fontSize: 12,
                  color: date != null ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 14, color: AppColors.textHint),
              ),
          ],
        ),
      ),
    );
  }
}
