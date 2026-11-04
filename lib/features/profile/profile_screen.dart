import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/widgets/hero_header.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/cubit/auth_cubit.dart';
import '../home/student_shell.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to log in again to see your reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              minimumSize: const Size(88, 40),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
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
                UserAvatar(user, radius: 46, ring: true),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.isStaff ? 'Staff' : 'Student',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
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
