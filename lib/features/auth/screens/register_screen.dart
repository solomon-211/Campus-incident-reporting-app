import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/field_label.dart';
import '../../../core/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _program = TextEditingController();
  final _campus = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_name, _email, _program, _campus, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      program: _program.text,
      campus: _campus.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) context.showSnack(state.message, error: true);
      },
      child: AuthScaffold(
        title: 'Create account',
        subtitle: 'Sign up with your ALU email.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldLabel('Full name'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  hintText: 'e.g. Amina Hassan',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => Validators.required(v, 'Name'),
              ),
              gap,
              const FieldLabel('Email address'),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'name@alustudent.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: Validators.email,
              ),
              gap,
              const FieldLabel('Program'),
              TextFormField(
                controller: _program,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'e.g. Computer Science',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                validator: (v) => Validators.required(v, 'Program'),
              ),
              gap,
              const FieldLabel('Campus (optional)'),
              TextFormField(
                controller: _campus,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'e.g. Kigali, Rwanda',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              gap,
              const FieldLabel('Password'),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  hintText: 'At least 6 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: Validators.password,
              ),
              gap,
              const FieldLabel('Confirm password'),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'Re-enter your password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (v) =>
                    v != _password.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 24),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) => PrimaryButton(
                  label: 'Create account',
                  loading: state is AuthLoading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
