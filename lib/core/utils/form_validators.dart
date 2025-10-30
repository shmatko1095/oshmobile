class FormValidator {
  static String? length({
    required String? value,
    required String errorMessage,
    int length = 3,
  }) {
    return (value == null || value.length < length) ? errorMessage : null;
  }

  static String? email({
    required String? value,
    required String errorMessage,
  }) {
    const String pattern = r'^[a-zA-Z0-9.a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    return regExpPattern(
      value: value,
      errorMessage: errorMessage,
      pattern: pattern,
    );
  }

  static String? regExpPattern({
    required String? value,
    required String errorMessage,
    required String pattern,
  }) {
    final RegExp regex = RegExp(pattern);
    return (value == null || value.isEmpty || !regex.hasMatch(value)) ? errorMessage : null;
  }

  static String? same({
    required String? value,
    required String? same,
    required String errorMessage,
  }) {
    return (value != same) ? errorMessage : null;
  }
}
