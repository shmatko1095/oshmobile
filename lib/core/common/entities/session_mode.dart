enum SessionMode {
  demo;

  static SessionMode? fromJsonValue(dynamic raw) {
    final normalized = raw?.toString().trim().toLowerCase();
    return switch (normalized) {
      'demo' => SessionMode.demo,
      _ => null,
    };
  }

  String get jsonValue => switch (this) {
        SessionMode.demo => 'demo',
      };
}
