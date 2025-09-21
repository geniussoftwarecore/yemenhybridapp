import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/http.dart';
import '../models/user.dart';

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(httpClientProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final HttpClient _httpClient;

  AuthNotifier(this._httpClient) : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final hasToken = await _httpClient.hasToken();
      if (hasToken) {
        await _getCurrentUser();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _getCurrentUser() async {
    try {
      final response = await _httpClient.get('/auth/me');
      final user = User.fromJson(response.data);
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      await _httpClient.logout();
      state = state.copyWith(
        isAuthenticated: false,
        user: null,
        isLoading: false,
        error: null,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _httpClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['access_token'];
      await _httpClient.setToken(token);
      
      // Get user info
      await _getCurrentUser();
      
      return true;
    } catch (e) {
      String errorMessage = 'Login failed';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          errorMessage = 'Invalid email or password';
        } else if (e.response?.data != null && e.response!.data['detail'] != null) {
          errorMessage = e.response!.data['detail'];
        }
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _httpClient.logout();
    state = AuthState();
  }
}