/// Typed exceptions for the application layers.
class ServerException implements Exception {
  ServerException([this.message = 'A server error occurred.']);
  final String message;
  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  CacheException([this.message = 'Cache read/write failed.']);
  final String message;
  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  NetworkException([this.message = 'No internet connection.']);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  AuthException([this.message = 'Authentication failed.']);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}

class PermissionException implements Exception {
  PermissionException([this.message = 'Permission denied.']);
  final String message;
  @override
  String toString() => 'PermissionException: $message';
}

class ValidationException implements Exception {
  ValidationException([this.message = 'Validation failed.']);
  final String message;
  @override
  String toString() => 'ValidationException: $message';
}
