class JsonRpcMeta {
  final String schema;
  final String? src;
  final int? ts;

  const JsonRpcMeta({
    required this.schema,
    this.src,
    this.ts,
  });

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{'schema': schema};
    if (src != null) out['src'] = src;
    if (ts != null) out['ts'] = ts;
    return out;
  }

  static JsonRpcMeta? from(dynamic raw) {
    if (raw is! Map) return null;
    final schema = raw['schema']?.toString();
    if (schema == null || schema.isEmpty) return null;

    final src = raw['src']?.toString();
    final tsRaw = raw['ts'];
    final ts = tsRaw is num ? tsRaw.toInt() : null;

    return JsonRpcMeta(schema: schema, src: src, ts: ts);
  }
}

class JsonRpcError {
  final int code;
  final String message;

  const JsonRpcError({
    required this.code,
    required this.message,
  });
}

class JsonRpcResponse {
  final String id;
  final JsonRpcMeta? meta;
  final Map<String, dynamic>? data;
  final JsonRpcError? error;

  const JsonRpcResponse({
    required this.id,
    this.meta,
    this.data,
    this.error,
  });

  bool get isError => error != null;
}

class JsonRpcNotification {
  final String method;
  final JsonRpcMeta meta;
  final Map<String, dynamic>? data;

  const JsonRpcNotification({
    required this.method,
    required this.meta,
    this.data,
  });
}

String jsonRpcMethod(String domain, String op) => '$domain.$op';

Map<String, dynamic> buildJsonRpcRequest({
  required String id,
  required String method,
  required JsonRpcMeta meta,
  Map<String, dynamic>? data,
}) {
  final params = <String, dynamic>{'meta': meta.toJson()};
  if (data != null) {
    params['data'] = data;
  }

  return <String, dynamic>{
    'jsonrpc': '2.0',
    'id': id,
    'method': method,
    'params': params,
  };
}

Map<String, dynamic> buildJsonRpcNotification({
  required String method,
  required JsonRpcMeta meta,
  Map<String, dynamic>? data,
}) {
  final params = <String, dynamic>{'meta': meta.toJson()};
  if (data != null) {
    params['data'] = data;
  }

  return <String, dynamic>{
    'jsonrpc': '2.0',
    'method': method,
    'params': params,
  };
}

JsonRpcResponse? decodeJsonRpcResponse(Map<String, dynamic> map) {
  final idRaw = map['id'];
  if (idRaw == null) return null;

  final id = idRaw.toString();
  final errorRaw = map['error'];
  if (errorRaw is Map) {
    final codeRaw = errorRaw['code'];
    final code = codeRaw is num ? codeRaw.toInt() : -32000;
    final message = errorRaw['message']?.toString() ?? 'Unknown error';
    return JsonRpcResponse(
      id: id,
      error: JsonRpcError(code: code, message: message),
    );
  }

  final resultRaw = map['result'];
  if (resultRaw is Map) {
    final meta = JsonRpcMeta.from(resultRaw['meta']);
    final dataRaw = resultRaw['data'];
    return JsonRpcResponse(
      id: id,
      meta: meta,
      data: dataRaw is Map ? dataRaw.cast<String, dynamic>() : null,
    );
  }

  return JsonRpcResponse(id: id);
}

JsonRpcNotification? decodeJsonRpcNotification(Map<String, dynamic> map) {
  final method = map['method']?.toString();
  if (method == null || method.isEmpty) return null;

  final params = map['params'];
  if (params is! Map) return null;

  final meta = JsonRpcMeta.from(params['meta']);
  if (meta == null) return null;

  final dataRaw = params['data'];
  return JsonRpcNotification(
    method: method,
    meta: meta,
    data: dataRaw is Map ? dataRaw.cast<String, dynamic>() : null,
  );
}
