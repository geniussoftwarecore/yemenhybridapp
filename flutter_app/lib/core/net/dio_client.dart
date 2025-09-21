import 'package:dio/dio.dart';
import '../env/env.dart';

class DioClient {
  static DioClient? _instance;
  late Dio _dio;

  DioClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: Duration(milliseconds: Env.apiTimeoutMs),
      receiveTimeout: Duration(milliseconds: Env.apiTimeoutMs),
      sendTimeout: Duration(milliseconds: Env.apiTimeoutMs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add error interceptor that never blocks UI
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          // Log error but don't throw to prevent UI blocking
          print('API Error: ${error.message}');
          if (error.response != null) {
            print('Status Code: ${error.response?.statusCode}');
            print('Response Data: ${error.response?.data}');
          }
          
          // Continue with the error (don't throw)
          handler.next(error);
        },
        onRequest: (options, handler) {
          print('API Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('API Response: ${response.statusCode} ${response.requestOptions.path}');
          handler.next(response);
        },
      ),
    );
  }

  static DioClient get instance {
    _instance ??= DioClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  // Convenience methods
  Future<Response?> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      print('GET Error: $e');
      return null;
    }
  }

  Future<Response?> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      print('POST Error: $e');
      return null;
    }
  }

  Future<Response?> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      print('PUT Error: $e');
      return null;
    }
  }

  Future<Response?> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } catch (e) {
      print('DELETE Error: $e');
      return null;
    }
  }
}