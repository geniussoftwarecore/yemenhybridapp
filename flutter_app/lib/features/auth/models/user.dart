class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['full_name'] ?? '', // Backend uses 'full_name'
      role: json['role'] ?? 'engineer',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': name, // Backend expects 'full_name'
      'role': role,
      'is_active': isActive,
    };
  }
}

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}