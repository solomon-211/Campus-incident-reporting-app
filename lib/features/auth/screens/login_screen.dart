import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/extensions.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/no_handle_selection.dart';
import '../../../core/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  late bool _remember;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>();
    _remember = auth.rememberMe ?? true;
    _email.text = auth.rememberedEmail ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().login(
      _email.text,
      _password.text,
      remember: _remember,
    );
  }

  Future<void> _forgotPassword() async {
    final emailError = Validators.email(_email.text);
    if (emailError != null) {
      context.showSnack(
        'Enter your email above first, then tap "Forgot password".',
        info: true,
      );
      return;
    }
    final error = await context.read<AuthCubit>().sendPasswordReset(
      _email.text,
    );
    if (!mounted) return;
    context.showSnack(
      error ?? 'Password reset email sent to ${_email.text.trim()}',
      error: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) context.showSnack(state.message, error: true);
      },
      child: AuthScaffold(
        title: 'Sign in',
        subtitle: 'Use your ALU email and password.',
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  selectionControls: noHandleSelectionControls,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration('ALU email'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  selectionControls: noHandleSelectionControls,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: _fieldDecoration('Password').copyWith(
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 10),
                MergeSemantics(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Remember me',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      CupertinoSwitch(
                        value: _remember,
                        activeTrackColor: AppColors.primary,
                        onChanged: (v) => setState(() => _remember = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) => PrimaryButton(
                    label: 'Sign in',
                    loading: state is AuthLoading,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Create one'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A framed field on a light fill, so it stands out inside the white card.
  InputDecoration _fieldDecoration(String hint) =>
      InputDecoration(hintText: hint, fillColor: AppColors.background);
}
