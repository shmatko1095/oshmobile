class ControlBindingAction {
  final String kind;
  final String? domain;
  final String? schema;
  final String? method;
  final String? path;
  final String? payloadKey;
  final List<String> requires;
  final String? field;
  final String? validField;
  final String? mode;
  final String? feature;
  final Map<String, dynamic> raw;

  const ControlBindingAction({
    required this.kind,
    required this.raw,
    this.domain,
    this.schema,
    this.method,
    this.path,
    this.payloadKey,
    this.requires = const <String>[],
    this.field,
    this.validField,
    this.mode,
    this.feature,
  });

  factory ControlBindingAction.fromJson(Map<String, dynamic> json) {
    return ControlBindingAction(
      kind: json['kind']?.toString() ?? '',
      raw: Map<String, dynamic>.from(json),
      domain: json['domain']?.toString(),
      schema: json['schema']?.toString(),
      method: json['method']?.toString(),
      path: json['path']?.toString(),
      payloadKey: json['payloadKey']?.toString(),
      requires: (json['requires'] as List? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      field: json['field']?.toString(),
      validField: json['validField']?.toString(),
      mode: json['mode']?.toString(),
      feature: json['feature']?.toString(),
    );
  }
}

class ControlBinding {
  final ControlBindingAction? read;
  final ControlBindingAction? write;

  const ControlBinding({
    this.read,
    this.write,
  });

  factory ControlBinding.fromJson(Map<String, dynamic> json) {
    final readRaw = json['read'];
    final writeRaw = json['write'];

    return ControlBinding(
      read: readRaw is Map
          ? ControlBindingAction.fromJson(readRaw.cast<String, dynamic>())
          : null,
      write: writeRaw is Map
          ? ControlBindingAction.fromJson(writeRaw.cast<String, dynamic>())
          : null,
    );
  }
}

class ActionBinding {
  final ControlBindingAction write;

  const ActionBinding({
    required this.write,
  });

  factory ActionBinding.fromJson(Map<String, dynamic> json) {
    final writeRaw = json['write'];
    if (writeRaw is! Map) {
      throw const FormatException('Invalid action binding');
    }

    return ActionBinding(
      write: ControlBindingAction.fromJson(writeRaw.cast<String, dynamic>()),
    );
  }
}
