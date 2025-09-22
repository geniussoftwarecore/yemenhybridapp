import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/env/env.dart';
import 'dart:convert';

// Auth state model
class AuthState {
  final String? token;
  final String? role;
  final String? email;

  const AuthState({
    this.token,
    this.role,
    this.email,
  });

  AuthState copyWith({
    String? token,
    String? role,
    String? email,
  }) {
    return AuthState(
      token: token ?? this.token,
      role: role ?? this.role,
      email: email ?? this.email,
    );
  }

  bool get isAuthenticated => token != null;
}

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadFromStorage();
  }

  final _dio = Dio();

  // Load auth state from SharedPreferences
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('auth_role');
      final email = prefs.getString('auth_email');

      if (token != null) {
        state = AuthState(
          token: token,
          role: role,
          email: email,
        );
      }
    } catch (e) {
      // If loading fails, remain unauthenticated
    }
  }

  // Sign in method
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final apiUrl = '${Env.apiBaseUrl}/api/v1';
      
      final response = await _dio.post(
        '$apiUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['access_token'] as String;
        final user = data['user'];
        final role = user['role'] as String;
        final userEmail = user['email'] as String;

        // Store in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('auth_role', role);
        await prefs.setString('auth_email', userEmail);

        // Update state
        state = AuthState(
          token: token,
          role: role,
          email: userEmail,
        );

        return {'success': true, 'fallback': false};
      } else {
        return {'success': false, 'error': 'Login failed'};
      }
    } on DioException catch (e) {
      // Check if this is a valid HTTP response (4xx/5xx errors)
      if (e.response != null) {
        // This is a valid HTTP response with an error status code
        // Return the specific error message from backend
        String errorMessage = 'Login failed';
        
        if (e.response!.data != null && e.response!.data is Map) {
          final errorData = e.response!.data['error'];
          if (errorData != null && errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        }
        
        return {'success': false, 'error': errorMessage};
      }
      
      // Only use DEV fallback for network errors (API is actually down)
      // and only in debug mode
      final isNetworkError = e.type == DioExceptionType.connectionTimeout ||
                           e.type == DioExceptionType.sendTimeout ||
                           e.type == DioExceptionType.receiveTimeout ||
                           e.type == DioExceptionType.connectionError ||
                           e.type == DioExceptionType.badCertificate;
      
      if (kDebugMode && isNetworkError) {
        // DEV fallback: API is actually down, use default admin role
        final prefs = await SharedPreferences.getInstance();
        const fallbackToken = 'dev-fallback-token';
        const fallbackRole = 'admin';
        
        await prefs.setString('auth_token', fallbackToken);
        await prefs.setString('auth_role', fallbackRole);
        await prefs.setString('auth_email', email);

        state = AuthState(
          token: fallbackToken,
          role: fallbackRole,
          email: email,
        );

        return {'success': true, 'fallback': true};
      }
      
      // For non-network errors or production mode, return error
      return {'success': false, 'error': 'Unable to connect to server'};
    } catch (e) {
      // For any other unexpected errors, return error
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }

  // Sign out method
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_role');
      await prefs.remove('auth_email');
      
      state = const AuthState();
    } catch (e) {
      // Even if clearing storage fails, clear the state
      state = const AuthState();
    }
  }
}

// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});