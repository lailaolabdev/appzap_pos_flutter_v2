/// Form validators for AppZap POS
class Validators {
  Validators._();

  /// Validate Lao phone number
  /// Formats: 020 12345678, 02012345678, +856 20 12345678
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces, dashes, and country code
    final cleaned =
        value
            .replaceAll(' ', '')
            .replaceAll('-', '')
            .replaceAll('+856', '')
            .trim();

    // Lao phone numbers start with 020 and are 10 digits total
    // or 20 and are 9 digits after removing leading 0
    final phoneRegex = RegExp(r'^(020|20)\d{7,8}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Invalid phone number format';
    }

    return null;
  }

  /// Validate PIN (4-6 digits)
  static String? pin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }

    if (value.length < 4) {
      return 'PIN must be at least 4 digits';
    }

    if (value.length > 6) {
      return 'PIN must be at most 6 digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }

    return null;
  }

  /// Validate OTP (6 digits)
  static String? otp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }

    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Invalid OTP format';
    }

    return null;
  }

  /// Validate name
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 100) {
      return 'Name must be less than 100 characters';
    }

    return null;
  }

  /// Validate email (optional)
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }

    return null;
  }

  /// Validate required field
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validate positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Value'} is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Invalid number';
    }

    if (number <= 0) {
      return '${fieldName ?? 'Value'} must be greater than 0';
    }

    return null;
  }

  /// Validate quantity (positive integer)
  static String? quantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return 'Invalid quantity';
    }

    if (number <= 0) {
      return 'Quantity must be greater than 0';
    }

    return null;
  }

  /// Validate discount percentage (0-100)
  static String? discountPercent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Discount is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Invalid discount';
    }

    if (number < 0 || number > 100) {
      return 'Discount must be between 0 and 100';
    }

    return null;
  }

  /// Validate barcode
  static String? barcode(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Barcode is optional
    }

    if (value.length < 6) {
      return 'Barcode is too short';
    }

    if (value.length > 20) {
      return 'Barcode is too long';
    }

    return null;
  }

  /// Format phone number for display
  static String formatPhone(String phone) {
    final cleaned = phone.replaceAll(' ', '').replaceAll('-', '');

    if (cleaned.startsWith('020') && cleaned.length >= 10) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 7)} ${cleaned.substring(7)}';
    }

    return phone;
  }

  /// Normalize phone number for API
  static String normalizePhone(String phone) {
    return phone.replaceAll(' ', '').replaceAll('-', '');
  }
}
