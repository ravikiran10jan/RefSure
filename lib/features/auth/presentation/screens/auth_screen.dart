// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/design_system/theme/app_colors.dart';
import 'package:refsure/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:refsure/features/auth/presentation/bloc/auth_event.dart';
import 'package:refsure/features/auth/presentation/bloc/auth_state.dart';
import 'package:refsure/features/auth/presentation/widgets/auth_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    listener: (context, state) {
      if (state is AuthSuccess) {
        // Sign-in from the sign-in tab: go to home
        // Sign-up from the sign-up tab: go to onboarding
        if (_tab.index == 0) {
          context.go('/');
        } else {
          context.go('/onboarding');
        }
      }
    },
    child: Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: Column(children: [
        const SizedBox(height: 32),
        // Logo
        Column(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Text('R', style: GoogleFonts.inter(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 12),
          Text('RefSure', style: GoogleFonts.inter(
            fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text('Where real referrals happen.', style: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textHint)),
        ]),
        const SizedBox(height: 28),

        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TabBar(
            controller: _tab,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecond,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
            dividerColor: Colors.transparent,
            tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(child: TabBarView(controller: _tab, children: const [
          _SignInForm(),
          _SignUpForm(),
        ])),
      ])),
    ),
  );
}

// Sign In Form
class _SignInForm extends StatefulWidget {
  const _SignInForm();
  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final loading = state is AuthLoading;
        final error = state is AuthFailure ? state.message : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (error != null) ErrorBanner(error),
            TextField(controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
            const SizedBox(height: 12),
            TextField(controller: _pw, obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure)))),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showReset,
                child: const Text('Forgot password?'))),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading ? null : _signIn,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Sign In')),
            const SizedBox(height: 16),
            const OrDivider(),
            const SizedBox(height: 16),
            GoogleSignInButton(onPressed: loading ? () {} : () {
              context.read<AuthBloc>().add(const GoogleSignInRequested());
            }),
          ]),
        );
      },
    );
  }

  void _signIn() {
    if (_email.text.isEmpty || _pw.text.isEmpty) {
      // Local validation - show via snackbar rather than BLoC state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }
    context.read<AuthBloc>().add(EmailSignInRequested(
      email: _email.text.trim(),
      password: _pw.text,
    ));
  }

  void _showReset() {
    final ctrl = TextEditingController(text: _email.text);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Reset Password'),
      content: TextField(controller: ctrl,
        decoration: const InputDecoration(labelText: 'Email')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<AuthBloc>().add(PasswordResetRequested(ctrl.text.trim()));
          },
          child: const Text('Send Link')),
      ],
    ));
  }
}

// Sign Up Form
class _SignUpForm extends StatefulWidget {
  const _SignUpForm();
  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _obscure = true;

  // Role gets chosen during onboarding; sign-up just creates the account.
  static const _defaultRole = UserRole.seeker;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final loading = state is AuthLoading;
        final error = state is AuthFailure ? state.message : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (error != null) ErrorBanner(error),

            TextField(controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 12),
            TextField(controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
            const SizedBox(height: 12),
            TextField(controller: _pw, obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password (6+ chars)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure)))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _signUp,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Account')),
            const SizedBox(height: 16),
            const OrDivider(),
            const SizedBox(height: 16),
            GoogleSignInButton(onPressed: loading ? () {} : () {
              context.read<AuthBloc>().add(
                const GoogleSignInRequested(role: _defaultRole));
            }),
          ]),
        );
      },
    );
  }

  void _signUp() {
    if (_name.text.isEmpty || _email.text.isEmpty || _pw.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }
    if (_pw.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }
    context.read<AuthBloc>().add(EmailSignUpRequested(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _pw.text,
      role: _defaultRole,
    ));
  }
}
