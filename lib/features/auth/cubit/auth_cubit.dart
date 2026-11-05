import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial()) {
    _start();
  }

  final AuthRepository _repository;

  /// Pre-fills the login form; null until preferences have loaded.
  String? rememberedEmail;

  /// The last "Remember me" choice; null until preferences have loaded.
  bool? rememberMe;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  /// While registering, the auth user exists a moment before its profile doc;
  /// this stops us from writing a fallback profile in that gap.
  bool _registering = false;
  bool _repairingProfile = false;

  Future<void> _start() async {
    try {
      final prefs = await _repository.loadLoginPreferences();
      rememberedEmail = prefs.email;
      rememberMe = prefs.remember;
      // "Remember me" was off: end the previous session on launch.
      if (!prefs.remember) await _repository.signOut();
    } catch (_) {
      // Preferences are a convenience; carry on without them.
    }
    if (isClosed) return;
    _authSub = _repository.authStateChanges().listen(_onAuthChanged);
  }

  AppUser? get currentUser => switch (state) {
    AuthAuthenticated(:final user) => user,
    _ => null,
  };

  void _onAuthChanged(User? firebaseUser) {
    _profileSub?.cancel();
    if (firebaseUser == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    final email = firebaseUser.email ?? '';
    final role = UserRole.forEmail(email);
    if (role == UserRole.student && !firebaseUser.emailVerified) {
      emit(AuthUnverified(email));
      return;
    }
    // Listening (rather than reading once) means a role change made in the
    // console moves the user to the right home screen immediately.
    _profileSub = _repository
        .watchProfile(firebaseUser.uid)
        .listen(
          (profile) {
            if (profile != null && role == UserRole.staff && !profile.isStaff) {
              // Created as a student earlier; the next snapshot is staff.
              _repository
                  .setRole(profile.uid, role)
                  .catchError((_) => emit(AuthAuthenticated(profile)));
            } else if (profile != null) {
              emit(AuthAuthenticated(profile));
            } else if (!_registering) {
              _repairMissingProfile(firebaseUser);
            }
          },
          onError: (Object e) async {
            await _repository.signOut();
            emit(
              const AuthError(
                'Could not load your profile. Check your connection and try again.',
              ),
            );
          },
        );
  }

  Future<void> _repairMissingProfile(User firebaseUser) async {
    if (_repairingProfile) return;
    _repairingProfile = true;
    try {
      await _repository.createMissingProfile(firebaseUser);
    } catch (_) {
      // The listener will surface the problem if the profile stays missing.
    } finally {
      _repairingProfile = false;
    }
  }

  Future<void> login(
    String email,
    String password, {
    bool remember = true,
  }) async {
    emit(const AuthLoading());
    rememberMe = remember;
    rememberedEmail = remember ? email.trim() : null;
    try {
      await _repository.saveLoginPreferences(remember: remember, email: email);
    } catch (_) {}
    try {
      await _repository.signIn(email: email, password: password);
      // AuthAuthenticated arrives via the profile listener.
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String program,
    required String campus,
  }) async {
    emit(const AuthLoading());
    _registering = true;
    try {
      await _repository.register(
        name: name,
        email: email,
        password: password,
        program: program,
        campus: campus,
      );
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      await _repository.signOut();
      emit(const AuthError('Could not create your account. Please try again.'));
    } finally {
      _registering = false;
    }
  }

  /// Checks whether the email link has been opened; moves on if it has.
  /// Returns false while the address is still unverified.
  Future<bool> checkEmailVerified() async {
    try {
      final user = await _repository.reloadUser();
      if (user == null || !user.emailVerified) return false;
      _onAuthChanged(user);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns an error message, or null when the email was sent.
  Future<String?> resendVerification() async {
    try {
      await _repository.sendEmailVerification();
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    }
  }

  /// Returns an error message, or null when the email was sent.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _repository.sendPasswordReset(email);
      return null;
    } on AuthFailure catch (e) {
      return e.message;
    }
  }

  /// Clears the notification badge; if it fails the badge just stays.
  Future<void> markNotificationsSeen() async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _repository.markNotificationsSeen(user.uid);
    } catch (_) {}
  }

  Future<void> logout() async {
    // Stop listening first so the listener doesn't fire a permission error
    // once the user is signed out.
    await _profileSub?.cancel();
    _profileSub = null;
    await _repository.signOut();
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    await _profileSub?.cancel();
    return super.close();
  }
}
