import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

/// Thrown with a message that is safe to show to the user.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  static const _rememberKey = 'remember_me';
  static const _emailKey = 'remembered_email';

  /// The "Remember me" choice from the last sign-in (default on), and the
  /// email saved with it.
  Future<({bool remember, String? email})> loadLoginPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      remember: prefs.getBool(_rememberKey) ?? true,
      email: prefs.getString(_emailKey),
    );
  }

  Future<void> saveLoginPreferences({
    required bool remember,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, remember);
    if (remember) {
      await prefs.setString(_emailKey, email.trim());
    } else {
      await prefs.remove(_emailKey);
    }
  }

  /// Emits the profile document, or `null` while it doesn't exist yet
  /// (e.g. in the moment between creating the account and writing the doc).
  Stream<AppUser?> watchProfile(String uid) {
    return _users
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null);
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String program,
    required String campus,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      final role = UserRole.forEmail(email);
      if (role == UserRole.student) await user.sendEmailVerification();
      await createProfile(
        AppUser(
          uid: user.uid,
          name: name.trim(),
          email: email.trim(),
          role: role,
          program: program.trim(),
          campus: campus.trim(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  /// The role comes from the email domain; the security rules check it.
  Future<void> createProfile(AppUser user) {
    return _users.doc(user.uid).set(user.toCreateMap());
  }

  /// Fallback profile for an account that exists in Auth but has no user doc
  /// (for example one created by hand in the Firebase console).
  Future<void> createMissingProfile(User user) async {
    // The listener may have seen an empty local cache; confirm with the
    // server so we never overwrite a real profile.
    final existing = await _users
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));
    if (existing.exists) return;
    final email = user.email ?? '';
    return createProfile(
      AppUser(
        uid: user.uid,
        name: user.displayName ?? email.split('@').first,
        email: email,
        role: UserRole.forEmail(email),
      ),
    );
  }

  /// Fixes a staff account that was saved as a student.
  Future<void> setRole(String uid, UserRole role) {
    return _users.doc(uid).update({'role': role.name});
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  /// Saves the profile picture, or removes it when [photo] is null.
  Future<void> updatePhoto(String uid, Uint8List? photo) {
    return _users.doc(uid).update({
      'photo': photo == null ? null : Blob(photo),
    });
  }

  Future<void> markNotificationsSeen(String uid) {
    return _users.doc(uid).update({
      'notificationsSeenAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  /// Refreshes the signed-in user from the server, picking up a verification
  /// done in the email link, and returns the up-to-date user.
  Future<User?> reloadUser() async {
    await _auth.currentUser?.reload();
    final user = _auth.currentUser;
    // The security rules read `email_verified` from the ID token, which
    // otherwise keeps saying false until its hourly refresh.
    if (user != null && user.emailVerified) await user.getIdToken(true);
    return user;
  }

  Future<void> signOut() => _auth.signOut();

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
