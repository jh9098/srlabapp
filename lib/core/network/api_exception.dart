class ApiException implements Exception {
  ApiException({required this.message, this.statusCode, this.errorCode});

  final String message;
  final int? statusCode;
  final String? errorCode;

  @override
  String toString() => 'ApiException(statusCode: $statusCode, errorCode: $errorCode, message: $message)';
}
