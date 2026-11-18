class PasswordRules {
  const PasswordRules._();

  static const minLength = 8;

  static bool hasMinLength(String value) => value.length >= minLength;

  static bool hasDigit(String value) => RegExp(r'\d').hasMatch(value);

  static bool hasSpecial(String value) =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\;/]').hasMatch(value);

  static bool isStrong(String value) =>
      hasMinLength(value) && hasDigit(value) && hasSpecial(value);

  static String? validate(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Пароль обязателен';
    if (!hasMinLength(v)) return 'Не меньше $minLength символов';
    if (!hasDigit(v)) return 'Добавьте хотя бы одну цифру';
    if (!hasSpecial(v)) return 'Добавьте спецсимвол (!@# и т.п.)';
    return null;
  }
}
