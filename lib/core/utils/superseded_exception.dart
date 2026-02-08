class SupersededException implements Exception {
  final String message;

  const SupersededException([this.message = 'Operation superseded']);

  @override
  String toString() => 'SupersededException: $message';
}
