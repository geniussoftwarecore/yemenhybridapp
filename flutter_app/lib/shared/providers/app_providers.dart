import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/net/dio_client.dart';

// Dio provider
final dioProvider = Provider<Dio>((ref) {
  return DioClient.instance.dio;
});

// Auth state placeholder
class AuthState {
  final bool isLoggedIn;
  final String? token;
  final String? userRole;

  const AuthState({
    this.isLoggedIn = false,
    this.token,
    this.userRole,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? token,
    String? userRole,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      token: token ?? this.token,
      userRole: userRole ?? this.userRole,
    );
  }
}

// Auth state provider placeholder
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(const AuthState());

  void login(String token, String role) {
    state = state.copyWith(
      isLoggedIn: true,
      token: token,
      userRole: role,
    );
  }

  void logout() {
    state = const AuthState();
  }
}