import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants.dart';

enum UserRole {
  student,
  staff;

  static UserRole fromName(String? name) =>
      name == UserRole.staff.name ? UserRole.staff : UserRole.student;

  /// ALU staff emails get the staff role; everyone else is a student.
  static bool needsVerification(String email) =>
      AppConstants.staffMustVerifyEmail || forEmail(email) == UserRole.student;

  static UserRole forEmail(String email) =>
      email.trim().toLowerCase().endsWith('@${AppConstants.staffEmailDomain}')
      ? UserRole.staff
      : UserRole.student;
}

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = UserRole.student,
    this.program = '',
    this.campus = '',
    this.photo,
    this.createdAt,
    this.notificationsSeenAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String program;
  final String campus;

  /// Small JPEG profile picture, stored on the profile document.
  final Uint8List? photo;
  final DateTime? createdAt;

  /// Last time the user opened their notifications; newer updates are unread.
  final DateTime? notificationsSeenAt;

  bool get isStaff => role == UserRole.staff;

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.fromName(map['role'] as String?),
      program: map['program'] as String? ?? '',
      campus: map['campus'] as String? ?? '',
      photo: (map['photo'] as Blob?)?.bytes,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      notificationsSeenAt: (map['notificationsSeenAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Map written when the profile is first created. `createdAt` is set by the
  /// server so clients can't backdate it.
  Map<String, dynamic> toCreateMap() => {
    'name': name,
    'email': email,
    'role': role.name,
    'program': program,
    'campus': campus,
    'createdAt': FieldValue.serverTimestamp(),
  };

  @override
  List<Object?> get props => [
    uid,
    name,
    email,
    role,
    program,
    campus,
    photo,
    createdAt,
    notificationsSeenAt,
  ];
}
