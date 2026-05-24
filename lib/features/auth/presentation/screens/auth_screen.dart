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

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fadeIn;
  bool _showForm = false;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  void _openForm({required bool signUp}) {
    setState(() { _showForm = true; _isSignUp = signUp; });
  }

  void _closeForm() => setState(() => _showForm = false);

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    listener: (context, state) {
      if (state is AuthSuccess) {
        context.go(_isSignUp ? '/onboarding' : '/');
      }
    },
    child: Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(fit: StackFit.expand, children: [
        // Gradient background
        _GradientBackground(),

        // Content
        SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _showForm
                ? _AuthFormSheet(
                    isSignUp: _isSignUp,
                    onToggle: () => setState(() => _isSignUp = !_isSignUp),
                    onClose: _closeForm,
                  )
                : _LandingContent(
                    fadeIn: _fadeIn,
                    onGetStarted: () => _openForm(signUp: true),
                    onSignIn: () => _openForm(signUp: false),
                  ),
          ),
        ),
      ]),
    ),
  );
}

// ── Landing Content ────────────────────────────────────────────

class _LandingContent extends StatelessWidget {
  final Animation<double> fadeIn;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;
  const _LandingContent({
    required this.fadeIn, required this.onGetStarted, required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: fadeIn,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        const Spacer(flex: 2),

        // Logo
        _AnimatedLogo(),
        const SizedBox(height: 20),

        // Title
        Text('RefSure', style: GoogleFonts.inter(
          fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white,
          letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text('Where real referrals happen.', style: GoogleFonts.inter(
          fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 40),

        // Headline
        Text('Get Referred.\nGet Hired.', textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white,
            height: 1.2, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Text('Skip the queue with insider referrals\nfrom people who work where you want to.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14, color: Colors.white70, height: 1.5)),
        const SizedBox(height: 36),

        // Feature pills
        Row(children: [
          Expanded(child: _FeaturePill(
            icon: Icons.verified_outlined,
            label: 'Verified insiders')),
          const SizedBox(width: 10),
          Expanded(child: _FeaturePill(
            icon: Icons.psychology_outlined,
            label: 'Smart match')),
          const SizedBox(width: 10),
          Expanded(child: _FeaturePill(
            icon: Icons.chat_bubble_outline,
            label: 'Direct chat')),
        ]),
        const Spacer(flex: 3),

        // CTAs
        ElevatedButton(
          onPressed: onGetStarted,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryDark,
            minimumSize: const Size.fromHeight(54),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w700),
          ),
          child: const Text('Get Started')),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onSignIn,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            side: const BorderSide(color: Colors.white54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w600),
          ),
          child: const Text('Sign In')),
        const SizedBox(height: 24),
      ]),
    ),
  );
}

class _AnimatedLogo extends StatefulWidget {
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      alignment: Alignment.center,
      child: Text('R', style: GoogleFonts.inter(
        color: AppColors.primary, fontSize: 36, fontWeight: FontWeight.w900)),
    ),
  );
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white24),
    ),
    child: Column(children: [
      Icon(icon, size: 22, color: Colors.white),
      const SizedBox(height: 6),
      Text(label, textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
    ]),
  );
}

class _GradientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary,
          AppColors.primaryDark,
          const Color(0xFF004D3A),
        ],
      ),
    ),
  );
}

// ── Auth Form Sheet ────────────────────────────────────────────

class _AuthFormSheet extends StatefulWidget {
  final bool isSignUp;
  final VoidCallback onToggle;
  final VoidCallback onClose;
  const _AuthFormSheet({
    required this.isSignUp, required this.onToggle, required this.onClose,
  });

  @override
  State<_AuthFormSheet> createState() => _AuthFormSheetState();
}

class _AuthFormSheetState extends State<_AuthFormSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 2, vsync: this, initialIndex: widget.isSignUp ? 1 : 0);
    _tab.addListener(() {
      if (_tab.indexIsChanging) widget.onToggle();
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Column(children: [
    // Drag handle + back
    Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(children: [
        IconButton(
          onPressed: widget.onClose,
          icon: const Icon(Icons.arrow_back, color: Colors.white)),
        const Spacer(),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: Colors.white38,
            borderRadius: BorderRadius.circular(2))),
        const Spacer(),
        const SizedBox(width: 48),
      ]),
    ),
    const SizedBox(height: 12),

    // Tab bar
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: Colors.white70,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
      ),
    ),
    const SizedBox(height: 16),

    // Form
    Expanded(child: TabBarView(controller: _tab, children: const [
      _SignInForm(),
      _SignUpForm(),
    ])),
  ]);
}

// ── Sign In Form ───────────────────────────────────────────────

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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (error != null) _LightErrorBanner(error),
            _LightTextField(
              controller: _email,
              label: 'Email',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _LightTextField(
              controller: _pw,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70),
                onPressed: () => setState(() => _obscure = !_obscure)),
            ),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showReset,
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                child: const Text('Forgot password?'))),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: loading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                disabledBackgroundColor: Colors.white.withOpacity(0.5),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 16),
              ),
              child: loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primaryDark))
                  : const Text('Sign In')),
            const SizedBox(height: 20),
            _LightOrDivider(),
            const SizedBox(height: 20),
            _LightGoogleButton(onPressed: loading ? () {} : () {
              context.read<AuthBloc>().add(const GoogleSignInRequested());
            }),
          ]),
        );
      },
    );
  }

  void _signIn() {
    if (_email.text.isEmpty || _pw.text.isEmpty) {
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
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<AuthBloc>().add(
              PasswordResetRequested(ctrl.text.trim()));
          },
          child: const Text('Send Link')),
      ],
    ));
  }
}

// ── Sign Up Form ───────────────────────────────────────────────

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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (error != null) _LightErrorBanner(error),
            _LightTextField(
              controller: _name,
              label: 'Full Name',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            _LightTextField(
              controller: _email,
              label: 'Email',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _LightTextField(
              controller: _pw,
              label: 'Password (6+ chars)',
              icon: Icons.lock_outline,
              obscureText: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70),
                onPressed: () => setState(() => _obscure = !_obscure)),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: loading ? null : _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                disabledBackgroundColor: Colors.white.withOpacity(0.5),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 16),
              ),
              child: loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primaryDark))
                  : const Text('Create Account')),
            const SizedBox(height: 20),
            _LightOrDivider(),
            const SizedBox(height: 20),
            _LightGoogleButton(onPressed: loading ? () {} : () {
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
        const SnackBar(
          content: Text('Password must be at least 6 characters.')),
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

// ── Light-themed form widgets (on dark bg) ─────────────────────

class _LightTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? suffix;
  const _LightTextField({
    required this.controller, required this.label, required this.icon,
    this.obscureText = false, this.keyboardType,
    this.textCapitalization = TextCapitalization.none, this.suffix,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
      floatingLabelStyle: GoogleFonts.inter(
        fontSize: 14, color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white70, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 1.5)),
    ),
  );
}

class _LightErrorBanner extends StatelessWidget {
  final String message;
  const _LightErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.red.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.red.withOpacity(0.4))),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.red, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(message, style: GoogleFonts.inter(
        fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600))),
    ]),
  );
}

class _LightOrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Divider(color: Colors.white30)),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text('or', style: GoogleFonts.inter(
        fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500))),
    Expanded(child: Divider(color: Colors.white30)),
  ]);
}

class _LightGoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _LightGoogleButton({required this.onPressed});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.g_mobiledata, size: 24, color: Colors.white),
    label: Text('Continue with Google', style: GoogleFonts.inter(
      fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      side: const BorderSide(color: Colors.white38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
