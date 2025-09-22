import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'env/env.dart';
import 'services/toast_service.dart';

// HTTP client provider
final httpClientProvider = Provider<HttpClient>((ref) {
  final toastService = ref.read(toastServiceProvider);
  return HttpClient(toastService);
});

class HttpClient {
  late final Dio _dio;
  static const String _tokenKey = 'auth_token';
  final ToastService _toastService;

  HttpClient(this._toastService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Request interceptor - Add JWT token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - logout user
          if (error.response?.statusCode == 401) {
            await _clearToken();
            _handleLogout();
          }
          handler.next(error);
        },
      ),
    );

    // Logging interceptor for debug mode only
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false, // Disable to prevent logging passwords/sensitive data
          responseBody: false, // Disable to prevent logging tokens/sensitive data
          error: true,
          requestHeader: false, // Don't log headers to avoid logging auth tokens
          responseHeader: false,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }
  }

  // Auth methods
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  void _handleLogout() {
    // Clear any existing messages
    _toastService.clearSnackBars();
    
    // Show logout message
    _toastService.showError('Session expired. Please login again.');
    
    // Navigate to login screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = ToastService.scaffoldMessengerKey.currentContext;
      if (context != null && context.mounted) {
        context.go('/login');
      }
    });
  }

  // HTTP methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // Public logout method
  Future<void> logout() async {
    await _clearToken();
  }
}