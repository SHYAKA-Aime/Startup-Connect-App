import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/app_user.dart';

/// Turns raw Firebase error codes into sentences a student can actually read.
String friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Please choose a stronger password (min 6 characters).';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}

/// Drives the sign-in / sign-up forms.
///
/// The controller's own state is an `AsyncValue<void>`: `loading` disables the
/// button and shows a spinner, `error` shows the message, `data` means success.
/// `AsyncValue.guard` runs the async work and captures any throw into the state
/// without try/catch boilerplate — this is the idiomatic Riverpod pattern the
/// report cites for keeping UI logic out of widgets.
class AuthController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> signIn({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repo.signIn(email: email, password: password),
    );
    return !state.hasError;
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      ),
    );
    return !state.hasError;
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();

  Future<bool> sendReset(String email) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    state =
        await AsyncValue.guard(() => repo.sendPasswordReset(email));
    return !state.hasError;
  }
}

final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, void>(AuthController.new);
