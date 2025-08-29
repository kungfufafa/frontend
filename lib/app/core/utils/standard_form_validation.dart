import 'package:get/get.dart';

class ValidationResult {
  final bool isValid;
  final String errorMessage;
  const ValidationResult(this.isValid, this.errorMessage);
}

/// Utility class untuk validasi form yang konsisten di seluruh aplikasi
/// Menggunakan prinsip KISS dengan validasi yang sederhana dan mudah dipahami
class StandardFormValidation {
  // Private constructor untuk mencegah instantiation
  StandardFormValidation._();
  
  /// Validasi field yang wajib diisi
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }
  
  /// Validasi email dengan format yang benar
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!GetUtils.isEmail(value.trim())) {
  return 'Email tidak valid';
    }
    return null;
  }
  
  /// Validasi panjang minimum karakter
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    if (value.trim().length < minLength) {
      return '$fieldName minimal $minLength karakter';
    }
    return null;
  }
  
  /// Validasi panjang maksimum karakter
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.trim().length > maxLength) {
      return '$fieldName maksimal $maxLength karakter';
    }
    return null;
  }
  
  /// Validasi nomor telepon Indonesia
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
  return null; // Optional field
    }
    
    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Indonesian phone number patterns:
    // - Starting with 08: 08xxxxxxxxx (10-13 digits)
    // - Starting with +62: +628xxxxxxxxx 
    // - Starting with 62: 628xxxxxxxxx
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Format nomor tidak valid';
    }
    
    // Check Indonesian phone number patterns
    if (digitsOnly.startsWith('08') && digitsOnly.length >= 10) {
      return null; // Valid Indonesian mobile number
    }
    if (digitsOnly.startsWith('628') && digitsOnly.length >= 11) {
      return null; // Valid Indonesian mobile number with country code
    }
    if (digitsOnly.startsWith('21') || digitsOnly.startsWith('22') || 
        digitsOnly.startsWith('24') || digitsOnly.startsWith('31')) {
      return null; // Valid Indonesian landline
    }
    
  return 'Format nomor tidak valid';
  }
  
  /// Validasi password dengan kriteria keamanan
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < minLength) {
      return 'Password minimal $minLength karakter';
    }
    return null;
  }
  
  /// Validasi konfirmasi password
  static String? validatePasswordConfirmation(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != originalPassword) {
  return 'Konfirmasi password tidak cocok';
    }
    return null;
  }
  
  /// Validasi nomor (hanya angka)
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    if (!GetUtils.isNum(value.trim())) {
      return '$fieldName harus berupa angka';
    }
    return null;
  }
  
  /// Validasi range angka
  static String? validateNumericRange(String? value, String fieldName, {double? min, double? max}) {
    final numericError = validateNumeric(value, fieldName);
    if (numericError != null) return numericError;
    
    final number = double.tryParse(value!.trim());
    if (number == null) return '$fieldName harus berupa angka valid';
    
    if (min != null && number < min) {
      return '$fieldName minimal $min';
    }
    if (max != null && number > max) {
      return '$fieldName maksimal $max';
    }
    
    return null;
  }
  
  /// Validasi URL
  static String? validateUrl(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'URL tidak boleh kosong' : null;
    }
    if (!GetUtils.isURL(value.trim())) {
      return 'Format URL tidak valid';
    }
    return null;
  }
  
  /// Validasi tanggal dalam format ISO atau dd/MM/yyyy
  static String? validateDate(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    
    try {
      // Try parsing as ISO date first (yyyy-MM-dd)
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim())) {
        DateTime.parse(value.trim());
        return null;
      }
      
      // Try parsing as dd/MM/yyyy
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value.trim())) {
        final parts = value.trim().split('/');
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        
        final date = DateTime(year, month, day);
        if (date.day == day && date.month == month && date.year == year) {
          return null;
        }
      }
      
  return 'Format tanggal tidak valid (gunakan dd/MM/yyyy atau yyyy-MM-dd)';
    } catch (e) {
      return 'Format tanggal tidak valid';
    }
  }
  
  /// Validasi NIK (Nomor Induk Kependudukan) Indonesia
  static String? validateNIK(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digitsOnly.length != 16) {
      return 'NIK harus 16 digit';
    }
    
    // Basic NIK validation (could be enhanced with more sophisticated checks)
    if (!GetUtils.isNum(digitsOnly)) {
      return 'NIK harus berupa angka';
    }
    
    return null;
  }

  // Convenience wrappers expected in tests
  static ValidationResult isEmail(String value) {
    final err = validateEmail(value);
    return ValidationResult(err == null, err ?? '');
  }

  static ValidationResult isValidName(String value) {
    // Name rules: required and min 2 chars
    final err = validateMinLength(value, 2, 'Nama');
    return ValidationResult(err == null, err ?? '');
  }

  static ValidationResult isValidPhoneNumber(String value) {
    final err = validatePhoneNumber(value);
    return ValidationResult(err == null, err ?? '');
  }

  /// Validasi kombinasi beberapa field dengan operator AND
  static String? validateCombined(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) {
        return result; // Return first error found
      }
    }
    return null;
  }
  
  /// Validasi dropdown/select yang wajib dipilih
  static String? validateSelection(dynamic value, String fieldName) {
    if (value == null || 
        (value is String && value.trim().isEmpty) ||
        (value is int && value <= 0)) {
      return 'Pilih $fieldName';
    }
    return null;
  }
  
  /// Validasi custom dengan regex pattern
  static String? validatePattern(String? value, String pattern, String fieldName, String errorMessage) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    
    final regex = RegExp(pattern);
    if (!regex.hasMatch(value.trim())) {
      return errorMessage;
    }
    
    return null;
  }
  
  /// Helper method untuk membuat validator composite
  static String? Function(String?) createValidator({
    bool required = false,
    int? minLength,
    int? maxLength,
    String? pattern,
    String? patternErrorMessage,
    String fieldName = 'Field',
  }) {
    return (String? value) {
      if (required) {
        final requiredError = validateRequired(value, fieldName);
        if (requiredError != null) return requiredError;
      }
      
      if (value != null && value.trim().isNotEmpty) {
        if (minLength != null) {
          final minLengthError = validateMinLength(value, minLength, fieldName);
          if (minLengthError != null) return minLengthError;
        }
        
        if (maxLength != null) {
          final maxLengthError = validateMaxLength(value, maxLength, fieldName);
          if (maxLengthError != null) return maxLengthError;
        }
        
        if (pattern != null && patternErrorMessage != null) {
          final patternError = validatePattern(value, pattern, fieldName, patternErrorMessage);
          if (patternError != null) return patternError;
        }
      }
      
      return null;
    };
  }
}