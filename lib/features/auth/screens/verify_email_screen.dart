import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../core/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_scaffold.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _poll;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Moves on by itself once the link in the email has been opened.
    _poll = Timer.periodic(
      const Duration(seconds: 5),
      (_) => context.read<AuthCubit>().checkEmailVerified(),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final verified = await context.read<AuthCubit>().checkEmailVerified();
    if (!mounted) return;
    setState(() => _checking = false);
    if (!verified) {
      context.showSnack(
        'Not verified yet. Open the link in the email, then try again.',
        info: true,
      );
    }
  }

  Future<void> _resend() async {
    final error = await context.read<AuthCubit>().resendVerification();
    if (!mounted) return;
    context.showSnack(error ?? 'Verification email sent', error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;
    final email = state is AuthUnverified ? state.email : '';

    return AuthScaffold(
      title: 'Check your inbox',
      subtitle: 'Verify your ALU email to start reporting.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.mark_email_unread_outlined,
            size: 48,
            color: AppColors.accent,
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'We sent a verification link to '),
                TextSpan(
                  text: email,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(
                  text:
                      '. Open it, then come back here. Check your spam '
                      'folder if it isn\'t in your inbox.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: "I've verified my email",
            loading: _checking,
            onPressed: _check,
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _resend, child: const Text('Resend email')),
          TextButton(
            onPressed: context.read<AuthCubit>().logout,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Use a different account'),
          ),
        ],
      ),
    );
  }
}
