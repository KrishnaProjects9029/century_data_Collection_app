// ============================================================
// App-wide constants: drop-down options, collection names, roles
// ============================================================

class AppConstants {
  // Supabase table names
  static const String studentsTable = 'students';
  static const String profilesTable = 'profiles';

  // Supabase Storage bucket
  static const String studentPhotosBucket = 'student_photos';

  // User roles
  static const String roleAdmin = 'ADMIN';
  static const String roleDataEntry = 'DATA_ENTRY';

  // Max photo file size in bytes (5 MB)
  static const int maxPhotoSizeBytes = 5 * 1024 * 1024;

  // Area dropdown options
  static const List<String> areaOptions = [
    'Kamraj',
    'Ramabai',
    'K.T',
    'L&T',
    'Nalanda',
    'OLD RTO',
    'D.B. Pawar Chawk',
    'Other',
  ];

  // Landmark dropdown options
  static const List<String> landmarkOptions = [
    'Om Sai Building',
    'KATKAR - BMC',
    'BMC - Vitthal Mandir',
    'Sathe Nagar',
    'Dakshata Colony',
    'Jal Prabhat Nagar',
    'Other',
  ];

  // Parents dropdown options
  static const List<String> parentOptions = [
    'Both',
    'Mother (Single)',
    'Father (Single)',
  ];

  // IST timezone identifier
  static const String istTimezone = 'Asia/Kolkata';

  // Excel column headers (exact order as specified)
  static const List<String> excelHeaders = [
    'Sr. No.',
    'Student First Name',
    'Middle Name',
    'Surname',
    'School Name',
    'Bro/Sis In Class (STD & DIV)',
    'Parents',
    'Mother Contact No.',
    'Father Contact No.',
    'Address In Full',
    'Area',
    'Other Area',
    'Landmark',
    'Other Landmark',
    'Student Photo',
    'Maker',
    'Date & Time',
  ];
}
