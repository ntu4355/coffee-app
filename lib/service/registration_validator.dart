class RegistrationValidator {
  static final _emailPattern = RegExp(
    r"^[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,63}$",
    caseSensitive: false,
  );

  static bool isValidEmail(String email) {
    if (email.length > 254 || !_emailPattern.hasMatch(email)) return false;
    final parts = email.split('@');
    final localPart = parts.first;
    return !localPart.startsWith('.') &&
        !localPart.endsWith('.') &&
        !localPart.contains('..') &&
        localPart.length <= 64 &&
        parts.last.length <= 253;
  }

  static String? passwordError(String password) {
    if (password.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Mật khẩu phải có ít nhất một chữ cái in hoa.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Mật khẩu phải có ít nhất một chữ cái thường.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Mật khẩu phải có ít nhất một chữ số.';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Mật khẩu phải có ít nhất một ký tự đặc biệt.';
    }
    return null;
  }
}
