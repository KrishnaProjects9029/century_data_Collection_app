import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';

class StudentService {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseQueryBuilder get _students => _client.from('students');

  // ──────────────────────────────────────────────
  // CREATE
  // ──────────────────────────────────────────────

  /// Inserts a student record. PostgreSQL generates the unique serial_number atomically!
  Future<(StudentModel?, String?)> addStudent(StudentModel student) async {
    try {
      final payload = student.toMap(includeSerial: false);
      final response = await _students.insert(payload).select().single();
      final savedStudent = StudentModel.fromMap(response);
      return (savedStudent, null);
    } on PostgrestException catch (e) {
      return (null, e.message);
    } catch (e) {
      return (null, 'Database error. Please try again.\n$e');
    }
  }

  // ──────────────────────────────────────────────
  // READ — STREAMS
  // ──────────────────────────────────────────────

  /// Stream of all active student records (Admin)
  Stream<List<StudentModel>> allStudentsStream() {
    return _client
        .from('students')
        .stream(primaryKey: ['id'])
        .eq('is_deleted', false)
        .order('serial_number', ascending: false)
        .map((list) => list.map(StudentModel.fromMap).toList());
  }

  /// Stream of records entered by a specific maker (Data Entry User)
  Stream<List<StudentModel>> myStudentsStream(String makerUserId) {
    if (makerUserId.isEmpty) return Stream.value([]);
    return _client
        .from('students')
        .stream(primaryKey: ['id'])
        .eq('is_deleted', false)
        .eq('maker_user_id', makerUserId)
        .order('serial_number', ascending: false)
        .map((list) => list.map(StudentModel.fromMap).toList());
  }

  // ──────────────────────────────────────────────
  // READ — SINGLE
  // ──────────────────────────────────────────────

  Future<StudentModel?> getStudent(String id) async {
    try {
      final data = await _students.select().eq('id', id).maybeSingle();
      if (data == null) return null;
      return StudentModel.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────────────────
  // STATS
  // ──────────────────────────────────────────────

  Future<int> getTotalCount() async {
    try {
      final count = await _client
          .from('students')
          .count(CountOption.exact)
          .eq('is_deleted', false);
      return count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getTodayCount() async {
    try {
      final now = DateTime.now().toUtc();
      // IST is UTC+5:30. Start of today in IST:
      final istNow = now.add(const Duration(hours: 5, minutes: 30));
      final startOfTodayIST = DateTime.utc(istNow.year, istNow.month, istNow.day)
          .subtract(const Duration(hours: 5, minutes: 30));

      final count = await _client
          .from('students')
          .count(CountOption.exact)
          .eq('is_deleted', false)
          .gte('submitted_at', startOfTodayIST.toIso8601String());
      return count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getMyCount(String makerUserId) async {
    if (makerUserId.isEmpty) return 0;
    try {
      final count = await _client
          .from('students')
          .count(CountOption.exact)
          .eq('is_deleted', false)
          .eq('maker_user_id', makerUserId);
      return count;
    } catch (_) {
      return 0;
    }
  }

  // ──────────────────────────────────────────────
  // SEARCH
  // ──────────────────────────────────────────────

  Future<List<StudentModel>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    try {
      // PostgreSQL ILIKE multi-field search
      final data = await _students
          .select()
          .eq('is_deleted', false)
          .or('first_name.ilike.%$q%,surname.ilike.%$q%,middle_name.ilike.%$q%,school_name.ilike.%$q%,area.ilike.%$q%,maker_name.ilike.%$q%,mother_contact.ilike.%$q%,father_contact.ilike.%$q%')
          .order('serial_number', ascending: false)
          .limit(100);

      return (data as List).map((row) => StudentModel.fromMap(row)).toList();
    } catch (e) {
      return [];
    }
  }

  // ──────────────────────────────────────────────
  // FILTER
  // ──────────────────────────────────────────────

  Future<List<StudentModel>> filter({
    String? area,
    String? landmark,
    String? parents,
    String? schoolName,
    String? makerUserId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      var builder = _students.select().eq('is_deleted', false);

      if (area != null && area.isNotEmpty) {
        builder = builder.eq('area', area);
      }
      if (landmark != null && landmark.isNotEmpty) {
        builder = builder.eq('landmark', landmark);
      }
      if (parents != null && parents.isNotEmpty) {
        builder = builder.eq('parents', parents);
      }
      if (makerUserId != null && makerUserId.isNotEmpty) {
        builder = builder.eq('maker_user_id', makerUserId);
      }
      if (schoolName != null && schoolName.isNotEmpty) {
        builder = builder.ilike('school_name', '%$schoolName%');
      }
      if (dateFrom != null) {
        builder = builder.gte('submitted_at', dateFrom.toUtc().toIso8601String());
      }
      if (dateTo != null) {
        final end = dateTo.add(const Duration(days: 1));
        builder = builder.lt('submitted_at', end.toUtc().toIso8601String());
      }

      final data = await builder.order('serial_number', ascending: false);
      return (data as List).map((row) => StudentModel.fromMap(row)).toList();
    } catch (e) {
      return [];
    }
  }

  // ──────────────────────────────────────────────
  // EXPORT QUERIES
  // ──────────────────────────────────────────────

  Future<List<StudentModel>> getAllForExport() async {
    final data = await _students
        .select()
        .eq('is_deleted', false)
        .order('serial_number', ascending: true);
    return (data as List).map((row) => StudentModel.fromMap(row)).toList();
  }

  Future<List<StudentModel>> getTodayForExport() async {
    final now = DateTime.now().toUtc();
    final istNow = now.add(const Duration(hours: 5, minutes: 30));
    final startOfTodayIST = DateTime.utc(istNow.year, istNow.month, istNow.day)
        .subtract(const Duration(hours: 5, minutes: 30));

    final data = await _students
        .select()
        .eq('is_deleted', false)
        .gte('submitted_at', startOfTodayIST.toIso8601String())
        .order('serial_number', ascending: true);
    return (data as List).map((row) => StudentModel.fromMap(row)).toList();
  }

  Future<List<StudentModel>> getDateRangeForExport(DateTime from, DateTime to) async {
    final end = to.add(const Duration(days: 1));
    final data = await _students
        .select()
        .eq('is_deleted', false)
        .gte('submitted_at', from.toUtc().toIso8601String())
        .lt('submitted_at', end.toUtc().toIso8601String())
        .order('serial_number', ascending: true);
    return (data as List).map((row) => StudentModel.fromMap(row)).toList();
  }

  // ──────────────────────────────────────────────
  // UPDATE
  // ──────────────────────────────────────────────

  Future<String?> updateStudent(
    String id,
    Map<String, dynamic> changes,
    String updatedByName,
  ) async {
    try {
      changes['updated_at'] = DateTime.now().toUtc().toIso8601String();
      changes['updated_by'] = updatedByName;

      await _students.update(changes).eq('id', id);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return 'Update failed: $e';
    }
  }

  // ──────────────────────────────────────────────
  // SOFT DELETE
  // ──────────────────────────────────────────────

  Future<String?> softDeleteStudent(String id) async {
    try {
      await _students.update({
        'is_deleted': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return 'Delete failed: $e';
    }
  }

  // ──────────────────────────────────────────────
  // DUPLICATE CHECK
  // ──────────────────────────────────────────────

  Future<bool> checkDuplicate({
    required String firstName,
    required String surname,
    required String schoolName,
    String motherContact = '',
    String fatherContact = '',
  }) async {
    try {
      // 1. Name + School duplicate check
      final query = await _students
          .select('id')
          .eq('is_deleted', false)
          .ilike('first_name', firstName.trim())
          .ilike('surname', surname.trim())
          .ilike('school_name', schoolName.trim())
          .limit(1);

      if ((query as List).isNotEmpty) return true;

      // 2. Phone + Surname duplicate check
      if (motherContact.isNotEmpty) {
        final contactMatch = await _students
            .select('id')
            .eq('is_deleted', false)
            .ilike('surname', surname.trim())
            .eq('mother_contact', motherContact.trim())
            .limit(1);
        if ((contactMatch as List).isNotEmpty) return true;
      }

      if (fatherContact.isNotEmpty) {
        final contactMatch = await _students
            .select('id')
            .eq('is_deleted', false)
            .ilike('surname', surname.trim())
            .eq('father_contact', fatherContact.trim())
            .limit(1);
        if ((contactMatch as List).isNotEmpty) return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
