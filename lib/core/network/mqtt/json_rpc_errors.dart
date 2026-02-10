class JsonRpcErrorCodes {
  // Standard JSON-RPC 2.0
  static const int parseError = -32700;
  static const int invalidRequest = -32600;
  static const int methodNotFound = -32601;
  static const int invalidParams = -32602;
  static const int internalError = -32603;

  // Application-specific (reserved: -32000..-32099)
  static const int deviceBusy = -32001;
  static const int unsupportedSchema = -32003;
  static const int notAllowed = -32005;
}

class JsonRpcException implements Exception {
  final int code;
  final String message;
  final String? domain;

  const JsonRpcException({
    required this.code,
    required this.message,
    this.domain,
  });

  @override
  String toString() {
    final d = domain == null ? '' : ' ($domain)';
    return 'JsonRpcException$d: $message (code $code)';
  }
}

class JsonRpcNotAllowed extends JsonRpcException {
  const JsonRpcNotAllowed({required super.code, required super.message, super.domain});
}

class JsonRpcUnsupportedSchema extends JsonRpcException {
  const JsonRpcUnsupportedSchema({required super.code, required super.message, super.domain});
}

class JsonRpcInvalidParams extends JsonRpcException {
  const JsonRpcInvalidParams({required super.code, required super.message, super.domain});
}

class JsonRpcInternalError extends JsonRpcException {
  const JsonRpcInternalError({required super.code, required super.message, super.domain});
}

class JsonRpcMethodNotFound extends JsonRpcException {
  const JsonRpcMethodNotFound({required super.code, required super.message, super.domain});
}

class JsonRpcDeviceBusy extends JsonRpcException {
  const JsonRpcDeviceBusy({required super.code, required super.message, super.domain});
}

class JsonRpcUnknownError extends JsonRpcException {
  const JsonRpcUnknownError({required super.code, required super.message, super.domain});
}

JsonRpcException mapJsonRpcError(int code, String message, {String? domain}) {
  switch (code) {
    case JsonRpcErrorCodes.notAllowed:
      return JsonRpcNotAllowed(code: code, message: message, domain: domain);
    case JsonRpcErrorCodes.unsupportedSchema:
      return JsonRpcUnsupportedSchema(code: code, message: message, domain: domain);
    case JsonRpcErrorCodes.invalidParams:
      return JsonRpcInvalidParams(code: code, message: message, domain: domain);
    case JsonRpcErrorCodes.internalError:
      return JsonRpcInternalError(code: code, message: message, domain: domain);
    case JsonRpcErrorCodes.methodNotFound:
      return JsonRpcMethodNotFound(code: code, message: message, domain: domain);
    case JsonRpcErrorCodes.deviceBusy:
      return JsonRpcDeviceBusy(code: code, message: message, domain: domain);
    default:
      return JsonRpcUnknownError(code: code, message: message, domain: domain);
  }
}
