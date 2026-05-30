import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode; // e.g. "E1011" — maps to backend ErrorCodes
  final String? email;     // present when errorCode == E1011 (unverified login)
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.email,
    this.data,
  });

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Connection timed out. Please try again.',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        String message = 'Something went wrong';
        String? errorCode;
        String? email;
        if (data is Map<String, dynamic>) {
          final err = data['error'];
          if (err is Map<String, dynamic>) {
            message = err['message']?.toString() ?? message;
            errorCode = err['code']?.toString();
            email = err['email']?.toString();
          } else if (data.containsKey('message')) {
            message = data['message'].toString();
          }
        }
        return ApiException(
          message: message,
          statusCode: statusCode,
          errorCode: errorCode,
          email: email,
          data: data,
        );
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request cancelled');
      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'No internet connection',
          statusCode: 0,
        );
      default:
        return ApiException(message: e.message ?? 'Unexpected error');
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Standardized API result wrapper.
class ApiResult<T> {
  final T? data;
  final ApiException? error;

  const ApiResult._({this.data, this.error});

  factory ApiResult.success(T data) => ApiResult._(data: data);
  factory ApiResult.failure(ApiException error) => ApiResult._(error: error);

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  R when<R>({
    required R Function(T data) success,
    required R Function(ApiException error) failure,
  }) {
    if (isSuccess) return success(data as T);
    return failure(error!);
  }
}
