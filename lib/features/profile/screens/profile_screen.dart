import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/hero_header.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../core/extensions.dart';
import '../../../core/widgets/photo_picker.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/app_user.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../../app/student_shell.dart';
import '../cubit/profile_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Log out?',
      message: 'You will need to log in again to see your reports.',
      confirmLabel: 'Log out',
    );
    if (confirmed && context.mounted) {
      await context.read<AuthCubit>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.currentUser);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: StudentShell.bottomClearance),
        children: [
          HeroHeader(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
            child: Column(
              children: [
                const HeaderTitleBar(title: 'Profile'),
                const SizedBox(height: 12),
                _EditableAvatar(user: user),
                const SizedBox(height: 14),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                RoleBadge(user.role, large: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: user.email,
                      ),
                      if (user.program.isNotEmpty)
                        _InfoTile(
                          icon: Icons.school_outlined,
                          label: 'Program',
                          value: user.program,
                        ),
                      if (user.campus.isNotEmpty)
                        _InfoTile(
                          icon: Icons.location_on_outlined,
                          label: 'Campus',
                          value: user.campus,
                        ),
                      if (user.createdAt != null)
                        _InfoTile(
                          icon: Icons.event_outlined,
                          label: 'Member since',
                          value: DateFormat('MMMM y').format(user.createdAt!),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({required this.user});

  final AppUser user;

  Future<void> _change(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final choice = await showPhotoSourceSheet(
      context,
      canRemove: user.photo != null,
    );
    if (choice == null || !context.mounted) return;

    String? error;
    if (choice == PhotoSourceChoice.remove) {
      error = await cubit.removePhoto();
    } else {
      final picked = await pickPhotos(context, choice.imageSource!);
      if (picked.isEmpty) return;
      error = await cubit.updatePhoto(picked.single);
    }
    if (!context.mounted) return;
    context.showSnack(error ?? 'Profile photo updated', error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<ProfileCubit>().state;
    return Semantics(
      button: true,
      label: 'Change profile photo',
      child: GestureDetector(
        onTap: saving ? null : () => _change(context),
        child: Stack(
          children: [
            UserAvatar(user, radius: 46, ring: true),
            if (saving)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
