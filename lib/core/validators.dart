class Validators {
  const Validators._();

  static String? required(String? value, {String label = 'Поле'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label обязательно';
    }
    return null;
  }

  static String? maxLength(String? value, int max, {String label = 'Поле'}) {
    if (value != null && value.trim().length > max) {
      return '$label: не больше $max символов';
    }
    return null;
  }

  static String? minLength(String? value, int min, {String label = 'Поле'}) {
    if (value == null || value.trim().length < min) {
      return '$label: не меньше $min символов';
    }
    return null;
  }

  static String? combine(String? value, List<String? Function(String?)> rules) {
    for (final rule in rules) {
      final error = rule(value);
      if (error != null) return error;
    }
    return null;
  }

  static String? positiveInt(String? value, {String label = 'Значение'}) {
    if (value == null || value.trim().isEmpty) return '$label обязательно';
    final n = int.tryParse(value.trim());
    if (n == null) return '$label должно быть целым числом';
    if (n <= 0) return '$label должно быть больше 0';
    return null;
  }

  static String? nonNegativeInt(String? value, {String label = 'Значение'}) {
    if (value == null || value.trim().isEmpty) return '$label обязательно';
    final n = int.tryParse(value.trim());
    if (n == null) return '$label должно быть целым числом';
    if (n < 0) return '$label не может быть отрицательным';
    return null;
  }

  static String? intInRange(
    String? value, {
    required int min,
    required int max,
    String label = 'Значение',
  }) {
    if (value == null || value.trim().isEmpty) return '$label обязательно';
    final n = int.tryParse(value.trim());
    if (n == null) return '$label должно быть целым числом';
    if (n < min || n > max) return '$label: от $min до $max';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email обязателен';
    final email = value.trim();
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!ok) return 'Некорректный формат email';
    return null;
  }

  static String? requiredId(int? value, {String label = 'Значение'}) {
    if (value == null || value == 0) return 'Выберите $label';
    return null;
  }

  static String? requiredIds(List<int>? value, {String label = 'значения'}) {
    if (value == null || value.isEmpty) {
      return 'Выберите хотя бы один $label';
    }
    return null;
  }
}
