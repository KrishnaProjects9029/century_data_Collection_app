import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterState {
  final String? area;
  final String? landmark;
  final String? parents;
  final String? schoolName;
  final String? makerUserId;
  final String? makerName;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const FilterState({
    this.area,
    this.landmark,
    this.parents,
    this.schoolName,
    this.makerUserId,
    this.makerName,
    this.dateFrom,
    this.dateTo,
  });

  bool get hasFilter =>
      area != null ||
      landmark != null ||
      parents != null ||
      schoolName != null ||
      makerUserId != null ||
      dateFrom != null ||
      dateTo != null;

  FilterState copyWith({
    String? area,
    String? landmark,
    String? parents,
    String? schoolName,
    String? makerUserId,
    String? makerName,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearArea = false,
    bool clearLandmark = false,
    bool clearParents = false,
    bool clearSchool = false,
    bool clearMaker = false,
    bool clearDates = false,
  }) {
    return FilterState(
      area: clearArea ? null : (area ?? this.area),
      landmark: clearLandmark ? null : (landmark ?? this.landmark),
      parents: clearParents ? null : (parents ?? this.parents),
      schoolName: clearSchool ? null : (schoolName ?? this.schoolName),
      makerUserId: clearMaker ? null : (makerUserId ?? this.makerUserId),
      makerName: clearMaker ? null : (makerName ?? this.makerName),
      dateFrom: clearDates ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDates ? null : (dateTo ?? this.dateTo),
    );
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  void apply(FilterState newFilter) => state = newFilter;
  void clear() => state = const FilterState();
}

final activeFilterProvider =
    StateNotifierProvider<FilterNotifier, FilterState>(
  (ref) => FilterNotifier(),
);
