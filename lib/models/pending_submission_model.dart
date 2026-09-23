// Model for offline pending submissions stored in SharedPreferences
class PendingSubmissionModel {
  final String localId;        // UUID generated locally
  final Map<String, dynamic> studentData;  // serialized student fields
  final String? localPhotoPath; // absolute path on device
  final DateTime createdLocally;
  final bool isSyncing;

  const PendingSubmissionModel({
    required this.localId,
    required this.studentData,
    this.localPhotoPath,
    required this.createdLocally,
    this.isSyncing = false,
  });

  factory PendingSubmissionModel.fromJson(Map<String, dynamic> json) {
    return PendingSubmissionModel(
      localId: json['localId'] as String,
      studentData: Map<String, dynamic>.from(json['studentData'] as Map),
      localPhotoPath: json['localPhotoPath'] as String?,
      createdLocally: DateTime.parse(json['createdLocally'] as String),
      isSyncing: json['isSyncing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'localId': localId,
      'studentData': studentData,
      'localPhotoPath': localPhotoPath,
      'createdLocally': createdLocally.toIso8601String(),
      'isSyncing': isSyncing,
    };
  }

  PendingSubmissionModel copyWith({bool? isSyncing}) {
    return PendingSubmissionModel(
      localId: localId,
      studentData: studentData,
      localPhotoPath: localPhotoPath,
      createdLocally: createdLocally,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}
