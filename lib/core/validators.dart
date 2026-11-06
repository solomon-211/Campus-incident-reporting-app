import 'constants.dart';

/// Form validators. Each returns an error message, or `null` when valid, so
/// they can be passed straight to `TextFormField.validator`.
abstract final class Validators {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    final domain = v.split('@').last.toLowerCase();
    if (!AppConstants.allowedEmailDomains.contains(domain)) {
      return 'Use your ALU email (@alustudent.com or @alueducation.com)';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < AppConstants.passwordMinLength) {
      return 'Password must be at least ${AppConstants.passwordMinLength} characters';
    }
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? title(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Title is required';
    if (v.length < AppConstants.titleMinLength) {
      return 'Title must be at least ${AppConstants.titleMinLength} characters';
    }
    if (v.length > AppConstants.titleMaxLength) {
      return 'Title must be at most ${AppConstants.titleMaxLength} characters';
    }
    return null;
  }

  static String? description(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Description is required';
    if (v.length < AppConstants.descriptionMinLength) {
      return 'Description must be at least ${AppConstants.descriptionMinLength} characters';
    }
    return null;
  }

  static String? attachmentCount(int count) {
    if (count > AppConstants.maxAttachments) {
      return 'You can attach at most ${AppConstants.maxAttachments} files';
    }
    return null;
  }
}
