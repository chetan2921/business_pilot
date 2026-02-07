import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Authentication result wrapper
class AuthResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  AuthResult._({this.data, this.error, required this.isSuccess});

  factory AuthResult.success(T data) =>
      AuthResult._(data: data, isSuccess: true);

  factory AuthResult.failure(String error) =>
      AuthResult._(error: error, isSuccess: false);
}

/// Auth repository providing clean interface for auth operations
class AuthRepository {
  AuthRepository._();
  static final AuthRepository _instance = AuthRepository._();
  static AuthRepository get instance => _instance;

  final _authService = AuthService.instance;

  /// Stream of auth state changes mapped to UserModel
  Stream<UserModel?> get userStream =>
      _authService.authStateChanges.map((state) {
        if (state.session?.user != null) {
          return UserModel.fromSupabaseUser(state.session!.user);
        }
        return null;
      });

  /// Get current user as UserModel
  UserModel? get currentUser {
    final user = _authService.currentUser;
    if (user == null) return null;
    return UserModel.fromSupabaseUser(user);
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _authService.isAuthenticated;

  /// Sign in with email and password
  Future<AuthResult<UserModel>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      if (response.user != null) {
        return AuthResult.success(UserModel.fromSupabaseUser(response.user!));
      }
      return AuthResult.failure('Sign in failed. Please try again.');
    } catch (e) {
      return AuthResult.failure(_parseAuthError(e));
    }
  }

  /// Sign up with email and password
  Future<AuthResult<UserModel>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (response.user != null) {
        return AuthResult.success(UserModel.fromSupabaseUser(response.user!));
      }
      return AuthResult.failure('Sign up failed. Please try again.');
    } catch (e) {
      return AuthResult.failure(_parseAuthError(e));
    }
  }

  /// Sign in with Google
  Future<AuthResult<bool>> signInWithGoogle() async {
    try {
      final success = await _authService.signInWithGoogle();
      if (success) {
        return AuthResult.success(true);
      }
      return AuthResult.failure('Google sign in was cancelled.');
    } catch (e) {
      return AuthResult.failure(_parseAuthError(e));
    }
  }

  /// Send password reset email
  Future<AuthResult<void>> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure(_parseAuthError(e));
    }
  }

  /// Sign out
  Future<AuthResult<void>> signOut() async {
    try {
      await _authService.signOut();
      return AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure(_parseAuthError(e));
    }
  }

  /// Parse auth errors to user-friendly messages
  String _parseAuthError(dynamic error) {
    final message = error.toString().toLowerCase();

    // Debug: Print actual error to console
    // ignore: avoid_print
    print('Auth Error: $error');

    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }
    if (message.contains('user already registered') ||
        message.contains('user_already_exists')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('password')) {
      return 'Password must be at least 6 characters long.';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (message.contains('network') || message.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    if (message.contains('invalid api key') || message.contains('apikey')) {
      return 'Configuration error: Invalid API key. Please check Supabase settings.';
    }

    // Show actual error for debugging (remove in production)
    return 'Error: ${error.toString()}';
  }
}
