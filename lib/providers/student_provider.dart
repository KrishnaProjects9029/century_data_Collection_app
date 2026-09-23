import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_model.dart';
import '../services/student_service.dart';
import 'auth_provider.dart';
import 'filter_provider.dart';

// ── Service ────────────────────────────────────
final studentServiceProvider =
    Provider<StudentService>((ref) => StudentService());

// ── All students stream (admin) ─────────────────
final allStudentsStreamProvider = StreamProvider<List<StudentModel>>((ref) {
  return ref.watch(studentServiceProvider).allStudentsStream();
});

// ── My students stream (data entry) ────────────
final myStudentsStreamProvider = StreamProvider<List<StudentModel>>((ref) {
  final userAsync = ref.watch(currentUserModelProvider);
  final uid = userAsync.valueOrNull?.id ?? '';
  return ref.watch(studentServiceProvider).myStudentsStream(uid);
});

// ── Stats ──────────────────────────────────────
final totalCountProvider = FutureProvider<int>((ref) {
  return ref.watch(studentServiceProvider).getTotalCount();
});

final todayCountProvider = FutureProvider<int>((ref) {
  return ref.watch(studentServiceProvider).getTodayCount();
});

final myCountProvider = FutureProvider<int>((ref) async {
  final user = await ref.watch(currentUserModelProvider.future);
  if (user == null) return 0;
  return ref.watch(studentServiceProvider).getMyCount(user.id);
});

// ── Search ─────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<StudentModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return Future.value([]);
  return ref.watch(studentServiceProvider).search(query);
});

// ── Filter results ─────────────────────────────
final filteredStudentsProvider = FutureProvider<List<StudentModel>>((ref) {
  final filter = ref.watch(activeFilterProvider);
  return ref.watch(studentServiceProvider).filter(
    area: filter.area,
    landmark: filter.landmark,
    parents: filter.parents,
    schoolName: filter.schoolName,
    makerUserId: filter.makerUserId,
    dateFrom: filter.dateFrom,
    dateTo: filter.dateTo,
  );
});
