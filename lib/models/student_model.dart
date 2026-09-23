import '../core/utils/date_formatter.dart';

class StudentModel {
  final String id;
  final int serialNumber;
  final String firstName;
  final String middleName;
  final String surname;
  final String schoolName;
  final String siblingClass;
  final String parents;
  final String motherContact;
  final String fatherContact;
  final String fullAddress;
  final String area;
  final String otherArea;
  final String landmark;
  final String otherLandmark;
  final String photoUrl;
  final String makerUserId;
  final String makerName;
  final DateTime submittedAt; // stored in UTC, display in IST
  final DateTime? updatedAt;
  final String updatedBy;
  final bool isDeleted;

  const StudentModel({
    required this.id,
    required this.serialNumber,
    required this.firstName,
    this.middleName = '',
    required this.surname,
    required this.schoolName,
    this.siblingClass = '',
    required this.parents,
    this.motherContact = '',
    this.fatherContact = '',
    required this.fullAddress,
    required this.area,
    this.otherArea = '',
    required this.landmark,
    this.otherLandmark = '',
    this.photoUrl = '',
    required this.makerUserId,
    required this.makerName,
    required this.submittedAt,
    this.updatedAt,
    this.updatedBy = '',
    this.isDeleted = false,
  });

  /// Full name helper.
  String get fullName =>
      [firstName, middleName, surname].where((s) => s.isNotEmpty).join(' ');

  /// IST-converted submission time.
  DateTime get submittedAtIST => DateFormatter.fromTimestamp(submittedAt);

  /// IST-converted update time.
  DateTime? get updatedAtIST =>
      updatedAt != null ? DateFormatter.fromTimestamp(updatedAt!) : null;

  factory StudentModel.fromMap(Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return StudentModel(
      id: (data['id'] ?? '').toString(),
      serialNumber: (data['serial_number'] ?? data['serialNumber'] as num?)?.toInt() ?? 0,
      firstName: data['first_name'] ?? data['firstName'] ?? '',
      middleName: data['middle_name'] ?? data['middleName'] ?? '',
      surname: data['surname'] ?? '',
      schoolName: data['school_name'] ?? data['schoolName'] ?? '',
      siblingClass: data['sibling_class'] ?? data['siblingClass'] ?? '',
      parents: data['parents'] ?? '',
      motherContact: data['mother_contact'] ?? data['motherContact'] ?? '',
      fatherContact: data['father_contact'] ?? data['fatherContact'] ?? '',
      fullAddress: data['full_address'] ?? data['fullAddress'] ?? '',
      area: data['area'] ?? '',
      otherArea: data['other_area'] ?? data['otherArea'] ?? '',
      landmark: data['landmark'] ?? '',
      otherLandmark: data['other_landmark'] ?? data['otherLandmark'] ?? '',
      photoUrl: data['photo_url'] ?? data['photoUrl'] ?? '',
      makerUserId: (data['maker_user_id'] ?? data['makerUserId'] ?? '').toString(),
      makerName: data['maker_name'] ?? data['makerName'] ?? '',
      submittedAt: parseDate(data['submitted_at'] ?? data['submittedAt']),
      updatedAt: data['updated_at'] != null || data['updatedAt'] != null
          ? parseDate(data['updated_at'] ?? data['updatedAt'])
          : null,
      updatedBy: data['updated_by'] ?? data['updatedBy'] ?? '',
      isDeleted: data['is_deleted'] ?? data['isDeleted'] ?? false,
    );
  }

  /// Map for Supabase PostgreSQL insert/update
  Map<String, dynamic> toMap({bool includeSerial = false}) {
    final map = <String, dynamic>{
      'first_name': firstName,
      'middle_name': middleName,
      'surname': surname,
      'school_name': schoolName,
      'sibling_class': siblingClass,
      'parents': parents,
      'mother_contact': motherContact,
      'father_contact': fatherContact,
      'full_address': fullAddress,
      'area': area,
      'other_area': otherArea,
      'landmark': landmark,
      'other_landmark': otherLandmark,
      'photo_url': photoUrl,
      'maker_user_id': makerUserId,
      'maker_name': makerName,
      'submitted_at': submittedAt.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'updated_by': updatedBy,
      'is_deleted': isDeleted,
    };
    if (includeSerial && serialNumber > 0) {
      map['serial_number'] = serialNumber;
    }
    return map;
  }

  StudentModel copyWith({
    String? id,
    int? serialNumber,
    String? firstName,
    String? middleName,
    String? surname,
    String? schoolName,
    String? siblingClass,
    String? parents,
    String? motherContact,
    String? fatherContact,
    String? fullAddress,
    String? area,
    String? otherArea,
    String? landmark,
    String? otherLandmark,
    String? photoUrl,
    String? makerUserId,
    String? makerName,
    DateTime? submittedAt,
    DateTime? updatedAt,
    String? updatedBy,
    bool? isDeleted,
  }) {
    return StudentModel(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      surname: surname ?? this.surname,
      schoolName: schoolName ?? this.schoolName,
      siblingClass: siblingClass ?? this.siblingClass,
      parents: parents ?? this.parents,
      motherContact: motherContact ?? this.motherContact,
      fatherContact: fatherContact ?? this.fatherContact,
      fullAddress: fullAddress ?? this.fullAddress,
      area: area ?? this.area,
      otherArea: otherArea ?? this.otherArea,
      landmark: landmark ?? this.landmark,
      otherLandmark: otherLandmark ?? this.otherLandmark,
      photoUrl: photoUrl ?? this.photoUrl,
      makerUserId: makerUserId ?? this.makerUserId,
      makerName: makerName ?? this.makerName,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
