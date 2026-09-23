import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/student_model.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/student_list_tile.dart';
import '../student/student_detail_screen.dart';
import '../student/student_form_screen.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  final bool myOnly;
  final bool openSearchOnLoad;

  const StudentListScreen({
    super.key,
    this.myOnly = false,
    this.openSearchOnLoad = false,
  });

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.openSearchOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _isSearching = true);
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserModelProvider);
    final user = userAsync.valueOrNull;
    final isAdmin = user?.isAdmin ?? false;

    // Stream source
    final studentsStream = widget.myOnly
        ? ref.watch(myStudentsStreamProvider)
        : ref.watch(allStudentsStreamProvider);

    // Search results
    final searchAsync = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search students...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) => ref
                    .read(searchQueryProvider.notifier)
                    .state = v.trim(),
              )
            : Text(widget.myOnly ? 'My Records' : 'All Students'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchCtrl.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => setState(() => _isSearching = true),
            ),
          if (_isSearching && query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchCtrl.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: _isSearching
                ? _buildSearchResults(searchAsync, query)
                : _buildStreamList(studentsStream, isAdmin),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentFormScreen()),
              ),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildStreamList(
      AsyncValue<List<StudentModel>> stream, bool isAdmin) {
    Future<void> refresh() async {
      if (widget.myOnly) {
        ref.invalidate(myStudentsStreamProvider);
      } else {
        ref.invalidate(allStudentsStreamProvider);
      }
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: refresh,
      child: stream.when(
        data: (students) {
          if (students.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                _emptyState(
                  icon: Icons.people_outline,
                  message: 'No student records yet.',
                  sub: 'Tap + to add the first student.',
                ),
              ],
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: students.length,
            itemBuilder: (_, i) => StudentListTile(
              student: students[i],
              onTap: () => _openDetail(students[i]),
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_off_rounded,
                        color: AppColors.error, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to Load Records',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString().contains('RealtimeSubscribeException')
                        ? 'Realtime synchronization issue. Pull down to refresh via central database.'
                        : 'Could not fetch records. Please check your internet connection.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                    onPressed: refresh,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
      AsyncValue<List<StudentModel>> searchAsync, String query) {
    if (query.isEmpty) {
      return _emptyState(
        icon: Icons.search_outlined,
        message: 'Search students',
        sub: 'Type a name, school, area, or contact number.',
      );
    }
    return searchAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return _emptyState(
            icon: Icons.search_off_outlined,
            message: 'No results found',
            sub: 'Try different keywords.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                '${results.length} result${results.length != 1 ? 's' : ''} for "$query"',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: results.length,
                itemBuilder: (_, i) => StudentListTile(
                  student: results[i],
                  onTap: () => _openDetail(results[i]),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Search error: $e')),
    );
  }

  void _openDetail(StudentModel student) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => StudentDetailScreen(studentId: student.id)),
    );
  }

  Widget _emptyState(
      {required IconData icon,
      required String message,
      required String sub}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
              )),
        ],
      ),
    );
  }
}
