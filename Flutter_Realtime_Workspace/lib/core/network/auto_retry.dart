// // lib/core/network/auto_retry.dart
// import 'package:dio/dio.dart';
// import 'package:dio_smart_retry/dio_smart_retry.dart';
// import 'package:flutter/foundation.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// /// Retry configuration
// class RetryConfig {
//   final int maxRetries;
//   final List<Duration> retryDelays;
//   final bool useExponentialBackoff;
//   final Duration baseDelay;
//   final double backoffMultiplier;
//   final Duration maxDelay;
//   final List<int> retryableStatusCodes;
//   final List<DioExceptionType> retryableExceptionTypes;

//   const RetryConfig({
//     this.maxRetries = 1,  //chang later
//     this.retryDelays = const [],
//     this.useExponentialBackoff = true,
//     this.baseDelay = const Duration(seconds: 1),
//     this.backoffMultiplier = 2.0,
//     this.maxDelay = const Duration(seconds: 10),
//     this.retryableStatusCodes = const [500, 502, 503, 504, 408, 429],
//     this.retryableExceptionTypes = const [
//       DioExceptionType.connectionTimeout,
//       DioExceptionType.connectionError,
//       DioExceptionType.sendTimeout,
//       DioExceptionType.receiveTimeout,
//     ],
//   });

//   List<Duration> generateRetryDelays() {
//     if (retryDelays.isNotEmpty) return retryDelays;
//     if (useExponentialBackoff) {
//       return List.generate(maxRetries, (index) {
//         final delay = Duration(
//           milliseconds:
//               (baseDelay.inMilliseconds * (backoffMultiplier * (index + 1)))
//                   .round(),
//         );
//         return delay.inMilliseconds > maxDelay.inMilliseconds
//             ? maxDelay
//             : delay;
//       });
//     }
//     return List.generate(maxRetries, (_) => baseDelay);
//   }
// }

// /// AuthInterceptor: Adds Firebase ID token to all requests
// class AuthInterceptor extends Interceptor {
//   @override
//   Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         final token = await user.getIdToken();
//         if (token!.isNotEmpty) {
//           options.headers['Authorization'] = 'Bearer $token';
//         }
//       }
//     } catch (e) {
//       // Log the error but don't block the request
//       if (kDebugMode) {
//         debugPrint('AuthInterceptor error: $e');
//       }
//     }
//     handler.next(options);
//   }

//   @override
//   Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
//     // Handle 401 errors by refreshing token
//     if (err.response?.statusCode == 401) {
//       try {
//         final user = FirebaseAuth.instance.currentUser;
//         if (user != null) {
//           // Force refresh the token
//           final newToken = await user.getIdToken(true);
//           if (newToken!.isNotEmpty) {
//             // Retry the original request with new token
//             final options = err.requestOptions;
//             options.headers['Authorization'] = 'Bearer $newToken';
            
//             final dio = Dio();
//             final response = await dio.fetch(options);
//             return handler.resolve(response);
//           }
//         }
//       } catch (e) {
//         if (kDebugMode) {
//           debugPrint('Token refresh failed: $e');
//         }
//       }
//     }
//     handler.next(err);
//   }
// }

// /// Dio error handler utility
// class DioErrorHandler {
//   static Exception handle(DioException error) {
//     switch (error.type) {
//       case DioExceptionType.connectionTimeout:
//         return Exception('Connection timeout');
//       case DioExceptionType.sendTimeout:
//         return Exception('Send timeout');
//       case DioExceptionType.receiveTimeout:
//         return Exception('Receive timeout');
//       case DioExceptionType.connectionError:
//         return Exception('Connection error');
//       case DioExceptionType.cancel:
//         return Exception('Request cancelled');
//       case DioExceptionType.unknown:
//         return Exception('Unknown error: ${error.message}');
//       case DioExceptionType.badCertificate:
//         return Exception('Certificate error');
//       case DioExceptionType.badResponse:
//         final statusCode = error.response?.statusCode;
//         final message = error.response?.data?['message'] ?? 
//                        error.response?.data?['error'] ?? 
//                        error.message;
//         return Exception('HTTP $statusCode: $message');
//     }
//   }
// }

// /// Singleton Dio client with retry, logging, and auth
// class DioClient {
//   static DioClient? _instance;
//   static Dio? _dio;

//   DioClient._internal();

//   factory DioClient() {
//     _instance ??= DioClient._internal();
//     return _instance!;
//   }

//   static Dio getInstance({
//     String? baseUrl,
//     Map<String, dynamic>? headers,
//     RetryConfig? retryConfig,
//     List<Interceptor>? additionalInterceptors,
//     Duration? connectTimeout,
//     Duration? receiveTimeout,
//     Duration? sendTimeout,
//   }) {
//     if (_dio != null) return _dio!;

//     _dio = Dio(BaseOptions(
//       baseUrl: baseUrl ?? '',
//       connectTimeout: connectTimeout ?? const Duration(seconds: 30),
//       receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
//       sendTimeout: sendTimeout ?? const Duration(seconds: 30),
//       headers: {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//         ...?headers,
//       },
//     ));

//     // Add interceptors in correct order
//     // 1. Auth interceptor (first to add auth headers)
//     _dio!.interceptors.add(AuthInterceptor());
    
//     // 2. Additional interceptors (if any)
//     if (additionalInterceptors != null) {
//       _dio!.interceptors.addAll(additionalInterceptors);
//     }
    
//     // 3. Retry interceptor (after auth to retry with proper headers)
//     final config = retryConfig ?? RetryPresets.conservative;
//     _dio!.interceptors.add(RetryInterceptor(
//       dio: _dio!,
//       retries: config.maxRetries,
//       retryDelays: config.generateRetryDelays(),
//       retryEvaluator: (error, attempt) {
//         // Don't retry if max retries is 0
//         if (config.maxRetries == 0) return false;
        
//         // Check if exception type is retryable
//         if (config.retryableExceptionTypes.contains(error.type)) {
//           return true;
//         }
        
//         // Check if status code is retryable
//         if (error.response?.statusCode != null) {
//           return config.retryableStatusCodes.contains(error.response!.statusCode);
//         }
        
//         // Handle unknown errors that might be network-related
//         if (error.type == DioExceptionType.unknown) {
//           final errorMessage = error.message?.toLowerCase() ?? '';
//           return errorMessage.contains('network') ||
//                  errorMessage.contains('connection') ||
//                  errorMessage.contains('socket') ||
//                  errorMessage.contains('timeout');
//         }
        
//         return false;
//       },
//     ));
    
//     // 4. Logging interceptor (last to log final requests/responses)
//     if (kDebugMode) {
//       _dio!.interceptors.add(LogInterceptor(
//         requestBody: true,
//         responseBody: true,
//         requestHeader: true,
//         responseHeader: false,
//         error: true,
//         logPrint: (obj) => debugPrint(obj.toString()),
//       ));
//     }

//     return _dio!;
//   }

//   static void reset() {
//     _instance = null;
//     _dio = null;
//   }

//   static Dio get dio {
//     if (_dio == null) {
//       throw Exception('DioClient not initialized. Call getInstance() first.');
//     }
//     return _dio!;
//   }
// }

// /// API Service wrapper for common HTTP operations
// class ApiService {
//   final Dio _dio;

//   ApiService({Dio? dio}) : _dio = dio ?? DioClient.dio;

//   /// GET request
//   Future<Response<T>> get<T>(
//     String path, {
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//     CancelToken? cancelToken,
//   }) async {
//     try {
//       return await _dio.get<T>(
//         path,
//         queryParameters: queryParameters,
//         options: options,
//         cancelToken: cancelToken,
//       );
//     } on DioException catch (e) {
//       throw DioErrorHandler.handle(e);
//     }
//   }

//   /// POST request
//   Future<Response<T>> post<T>(
//     String path, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//     CancelToken? cancelToken,
//   }) async {
//     try {
//       return await _dio.post<T>(
//         path,
//         data: data,
//         queryParameters: queryParameters,
//         options: options,
//         cancelToken: cancelToken,
//       );
//     } on DioException catch (e) {
//       throw DioErrorHandler.handle(e);
//     }
//   }

//   /// PUT request
//   Future<Response<T>> put<T>(
//     String path, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//     CancelToken? cancelToken,
//   }) async {
//     try {
//       return await _dio.put<T>(
//         path,
//         data: data,
//         queryParameters: queryParameters,
//         options: options,
//         cancelToken: cancelToken,
//       );
//     } on DioException catch (e) {
//       throw DioErrorHandler.handle(e);
//     }
//   }

//   /// DELETE request
//   Future<Response<T>> delete<T>(
//     String path, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//     CancelToken? cancelToken,
//   }) async {
//     try {
//       return await _dio.delete<T>(
//         path,
//         data: data,
//         queryParameters: queryParameters,
//         options: options,
//         cancelToken: cancelToken,
//       );
//     } on DioException catch (e) {
//       throw DioErrorHandler.handle(e);
//     }
//   }

//   /// PATCH request
//   Future<Response<T>> patch<T>(
//     String path, {
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     Options? options,
//     CancelToken? cancelToken,
//   }) async {
//     try {
//       return await _dio.patch<T>(
//         path,
//         data: data,
//         queryParameters: queryParameters,
//         options: options,
//         cancelToken: cancelToken,
//       );
//     } on DioException catch (e) {
//       throw DioErrorHandler.handle(e);
//     }
//   }

//   /// Upload file
//   Future<Response<T>> upload<T>(
//     String path,
//     FormData formData, {
//     Options? options,
//     CancelToken? cancelToken,
//     ProgressCallback? onSendProgress,
//   }) async {
//     try {
//       return await _dio.post<T>(
//         path,
//         data: formData,
//         options: options,
//         cancelToken: cancelToken,
//         onSendProgress: onSendProgress,
//       );
//     } on DioException catch (e) {
//       throw DioErrorHandler.handle(e);
//     }
//   }

//   /// Download file
//   Future<Response> download(
//     String urlPath,
//     String savePath, {
//     ProgressCallback? onReceiveProgress,
//     CancelToken? cancelToken,
//     bool deleteOnError = true,
//     Options? options,
//   }) async {
//     try {
//       return await _dio.download(
//         urlPath,
//         savePath,
//         onReceiveProgress: onReceiveProgress,
//         cancelToken: cancelToken,
//         deleteOnError: deleteOnError,
//         options: options,
//       );
//     } on DioException catch (e) {
//       throw DioErrorHandler.handle(e);
//     }
//   }
// }

// /// Dependency injection setup for network services
// class NetworkModule {
//   static void initialize({
//     String? baseUrl,
//     Map<String, dynamic>? headers,
//     RetryConfig? retryConfig,
//     List<Interceptor>? additionalInterceptors,
//   }) {
//     DioClient.getInstance(
//       baseUrl: baseUrl,
//       headers: headers,
//       retryConfig: retryConfig,
//       additionalInterceptors: additionalInterceptors,
//     );
//   }

//   static Dio get dio => DioClient.dio;
//   static ApiService get apiService => ApiService();

//   /// Helper to get Dio instance with a custom baseUrl (for feature APIs)
//   static Dio getDioWithBaseUrl(String baseUrl) {
//     return DioClient.getInstance(
//       baseUrl: baseUrl,
//       retryConfig: RetryPresets.conservative,
//     );
//   }
// }

// /// Predefined retry configurations for common scenarios
// class RetryPresets {
//   /// Aggressive retry for critical operations
//   static const RetryConfig aggressive = RetryConfig(
//     maxRetries: 1, //5
//     useExponentialBackoff: true,
//     baseDelay: Duration(milliseconds: 500),
//     backoffMultiplier: 2.0,
//     maxDelay: Duration(seconds: 30),
//   );

//   /// Conservative retry for normal operations
//   static const RetryConfig conservative = RetryConfig(
//     maxRetries: 1, //2
//     useExponentialBackoff: true,
//     baseDelay: Duration(seconds: 1),
//     backoffMultiplier: 1.5,
//     maxDelay: Duration(seconds: 5),
//   );

//   /// Fast retry for real-time operations
//   static const RetryConfig fast = RetryConfig(
//     maxRetries: 1, //3
//     retryDelays: [
//       Duration(milliseconds: 100),
//       Duration(milliseconds: 200),
//       Duration(milliseconds: 400),
//     ],
//   );

//   /// No retry for operations that should fail fast
//   static const RetryConfig none = RetryConfig(
//     maxRetries: 0,
//   );
// }

// /// Usage examples:
// /// 
// /// // Initialize in main.dart
// /// void main() {
// ///   NetworkModule.initialize(
// ///     baseUrl: 'https://api.example.com',
// ///     retryConfig: RetryPresets.conservative,
// ///   );
// ///   runApp(MyApp());
// /// }
// /// 
// /// // Use in repository
// /// class UserRepository {
// ///   final ApiService _apiService = NetworkModule.apiService;
// ///   
// ///   Future<User> getUser(String id) async {
// ///     final response = await _apiService.get('/users/$id');
// ///     return User.fromJson(response.data);
// ///   }
// /// }