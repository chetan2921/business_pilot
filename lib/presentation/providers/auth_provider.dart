import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/auth_service.dart';

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository.instance;
});

/// Stream provider for auth state changes (raw Supabase session)
final authStateProvider = StreamProvider<Session?>((ref) {
  return AuthService.instance.authStateChanges.map((state) => state.session);
});

/// Stream provider for current user model
final userStreamProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).userStream;
});

/// Current user provider (synchronous access)
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(userStreamProvider).valueOrNull;
});

/// Auth loading state
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Auth error state
final authErrorProvider = StateProvider<String?>((ref) => null);

/// Auth notifier for managing authentication actions
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _repository.userStream.listen((user) {
      state = AsyncValue.data(user);
    });
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    final result = await _repository.signInWithEmail(
      email: email,
      password: password,
    );

    _ref.read(authLoadingProvider.notifier).state = false;

    if (result.isSuccess) {
      return true;
    } else {
      _ref.read(authErrorProvider.notifier).state = result.error;
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    final result = await _repository.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );

    _ref.read(authLoadingProvider.notifier).state = false;

    if (result.isSuccess) {
      return true;
    } else {
      _ref.read(authErrorProvider.notifier).state = result.error;
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    final result = await _repository.signInWithGoogle();

    _ref.read(authLoadingProvider.notifier).state = false;

    if (result.isSuccess) {
      return true;
    } else {
      _ref.read(authErrorProvider.notifier).state = result.error;
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    final result = await _repository.sendPasswordResetEmail(email);

    _ref.read(authLoadingProvider.notifier).state = false;

    if (result.isSuccess) {
      return true;
    } else {
      _ref.read(authErrorProvider.notifier).state = result.error;
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _ref.read(authLoadingProvider.notifier).state = true;
    await _repository.signOut();
    _ref.read(authLoadingProvider.notifier).state = false;
  }

  /// Clear error
  void clearError() {
    _ref.read(authErrorProvider.notifier).state = null;
  }
}

/// Auth notifier provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
      return AuthNotifier(ref.watch(authRepositoryProvider), ref);
    });
