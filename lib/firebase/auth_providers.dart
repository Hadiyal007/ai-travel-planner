import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Live stream of the signed-in user (or null). Used to decide whether
/// the app shows the Login flow or Home — wire this into routing when
/// the Signup/Login screens are in place.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

class AuthActionState {
  final bool isLoading;
  final String? error;

  const AuthActionState({this.isLoading = false, this.error});

  AuthActionState copyWith({bool? isLoading, String? error}) {
    return AuthActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Drives the Signup/Login screens: tracks in-flight/loading and
/// error state for a signup or sign-in attempt. Auth-state itself
/// (whether someone ends up signed in) is read from
/// [authStateChangesProvider], not from here.
class AuthNotifier extends StateNotifier<AuthActionState> {
  final AuthService _service;
  AuthNotifier(this._service) : super(const AuthActionState());

  Future<bool> signUp({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.signUp(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = AuthActionState(isLoading: false, error: _service.messageForError(e));
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.signIn(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = AuthActionState(isLoading: false, error: _service.messageForError(e));
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthActionState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});