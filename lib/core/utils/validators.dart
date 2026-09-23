// Form field validators

class Validators {
  /// Returns an error string if null/empty, otherwise null.
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  /// Validates a 10-digit Indian mobile number.
  static String? mobileNumber(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'Please enter a valid 10-digit mobile number.';
      return null; // optional field
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'Please enter a valid 10-digit mobile number.';
    }
    // Indian mobile: starts with 6–9
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Please enter a valid Indian mobile number.';
    }
    return null;
  }

  /// Validates email format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.\w+$').hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Validates password length.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  /// Validates dropdown selection.
  static String? dropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please select $fieldName.';
    }
    return null;
  }

  /// Validates file size ≤ 5 MB.
  static String? photoSize(int bytes) {
    const maxBytes = 5 * 1024 * 1024;
    if (bytes > maxBytes) {
      return 'Student photo must be 5 MB or smaller.';
    }
    return null;
  }
}
