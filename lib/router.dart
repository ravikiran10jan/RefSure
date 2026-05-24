// lib/router.dart — v2.0 FIXED
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/di/injection.dart';
import 'core/router/route_names.dart';
import 'design_system/design_system.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/auth_screen.dart' as auth_feature;
import 'features/careers_portal/careers_portal.dart';
import 'providers/app_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screens.dart';
import 'screens/feature_screens.dart';

final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

GoRouter buildRouter(AppProvider prov) => GoRouter(
  refreshListenable: prov,
  redirect: (context, state) {
    // GUEST MODE - no auth redirect
    return null;
  },
  routes: [
    GoRoute(path: '/auth', builder: (_, __) => BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: const auth_feature.AuthScreen(),
    )),
    GoRoute(path: '/onboarding',  builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/verify-org',  builder: (_, __) => const OrgVerifyScreen()),
    GoRoute(path: '/post-job',    builder: (_, __) => const PostJobScreen()),
    GoRoute(
      path: RouteNames.careersPortal,
      builder: (_, __) => BlocProvider(
        create: (_) => getIt<CareersPortalCubit>(),
        child: const CareersPortalScreen(),
      ),
    ),
    GoRoute(path: '/edit-profile', builder: (_, __) => const _EditProfileScreen()),
    GoRoute(
      path: '/providers/:id',
      builder: (_, state) =>
          ProviderDetailScreen(providerId: state.pathParameters['id']!)),
    GoRoute(
      path: '/jobs/:id',
      builder: (_, state) =>
          JobDetailScreen(jobId: state.pathParameters['id']!)),
    GoRoute(
      path: '/messages/:id',
      builder: (_, state) =>
          ChatScreen(otherId: state.pathParameters['id']!)),

    // Shell with bottom nav
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (ctx, state, child) => _ShellScaffold(child: child),
      routes: [
        GoRoute(path: '/',            builder: (_, __) => const _HomeRouter()),
        GoRoute(path: '/jobs',        builder: (_, __) => const JobsScreen()),
        GoRoute(path: '/providers',   builder: (_, __) => const ProvidersScreen()),
        GoRoute(path: '/applications', builder: (_, __) => const ApplicationsScreen()),
        GoRoute(path: '/profile',     builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/messages',    builder: (_, __) => const MessagesScreen()),
      ],
    ),
  ],
);

class _HomeRouter extends StatelessWidget {
  const _HomeRouter();
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return prov.isProvider
        ? const ProviderDashboardScreen()
        : const HomeScreen();
  }
}

class _ShellScaffold extends StatelessWidget {
  final Widget child;
  const _ShellScaffold({required this.child});

  static const _seekerItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined),   activeIcon: Icon(Icons.home),       label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.work_outline),    activeIcon: Icon(Icons.work),       label: 'Jobs'),
    BottomNavigationBarItem(icon: Icon(Icons.people_outline),  activeIcon: Icon(Icons.people),     label: 'Referrers'),
    BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Applied'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline),  activeIcon: Icon(Icons.person),     label: 'Profile'),
  ];

  static const _providerItems = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.work_outline),       activeIcon: Icon(Icons.work),      label: 'Jobs'),
    BottomNavigationBarItem(icon: Icon(Icons.people_outline),     activeIcon: Icon(Icons.people),    label: 'Seekers'),
    BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline),activeIcon: Icon(Icons.chat_bubble),label: 'Messages'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline),     activeIcon: Icon(Icons.person),    label: 'Profile'),
  ];

  static const _seekerRoutes   = ['/', '/jobs', '/providers', '/applications', '/profile'];
  static const _providerRoutes = ['/', '/jobs', '/providers', '/messages',     '/profile'];

  int _currentIndex(String location, bool isProvider) {
    final routes = isProvider ? _providerRoutes : _seekerRoutes;
    for (int i = 0; i < routes.length; i++) {
      if (location == routes[i]) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final prov       = context.watch<AppProvider>();
    final isProvider = prov.isProvider;
    final location   = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    final index      = _currentIndex(location, isProvider);
    final routes     = isProvider ? _providerRoutes : _seekerRoutes;
    final unread     = prov.unreadCount;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border))),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => context.go(routes[i]),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: AppColors.surface,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          items: isProvider ? _providerItems : _seekerItems,
        ),
      ),
    );
  }
}

// Edit profile — first/last name, email, organisation, CV, and (for
// Referrers) a verify-work-email CTA.
class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();
  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late TextEditingController _first, _last, _email, _company, _bio;
  String? _resumeUrl;
  String? _resumeName;
  bool _uploading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser;
    final parts = (user?.name ?? '').trim().split(RegExp(r'\s+'));
    _first   = TextEditingController(
      text: parts.isNotEmpty ? parts.first : '');
    _last    = TextEditingController(
      text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
    _email   = TextEditingController(text: user?.email ?? '');
    _company = TextEditingController(text: user?.company ?? '');
    _bio     = TextEditingController(text: user?.bio ?? '');
    _resumeUrl  = user?.resumeUrl;
    _resumeName = _resumeUrl != null ? 'Resume on file' : null;
  }

  @override
  void dispose() {
    _first.dispose(); _last.dispose(); _email.dispose();
    _company.dispose(); _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final user = prov.currentUser;
    final isReferrer = prov.isProvider;
    final orgVerified = user?.orgVerified ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
        ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        Row(children: [
          Expanded(child: TextField(controller: _first,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'First name'))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _last,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Last name'))),
        ]),
        const SizedBox(height: 14),

        TextField(controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline))),
        const SizedBox(height: 14),

        TextField(controller: _company,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Organisation',
            prefixIcon: Icon(Icons.business_outlined))),
        const SizedBox(height: 18),

        // ── CV upload ─────────────────────────────────────────
        Row(children: [
          Text('CV / Resume', style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary)),
          const SizedBox(width: 6),
          Text(isReferrer ? '(optional)' : '(required)',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint)),
        ]),
        const SizedBox(height: 8),
        _ResumeTile(
          fileName: _resumeName,
          uploading: _uploading,
          onTap: _uploadResume),
        const SizedBox(height: 18),

        // ── Verify work email (Referrers only) ────────────────
        if (isReferrer) ...[
          _EditVerifyEmailRow(
            verified: orgVerified,
            onVerifyNow: () => context.push(RouteNames.verifyOrg)),
          const SizedBox(height: 18),
        ],

        TextField(controller: _bio, maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Bio / Summary',
            hintText: 'Brief overview of your background and goals.')),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: GoogleFonts.inter(
            fontSize: 12, color: AppColors.red)),
        ],
      ]),
    );
  }

  Future<void> _uploadResume() async {
    if (_uploading) return;
    setState(() { _uploading = true; _error = null; });
    final url = await context.read<AppProvider>().uploadResume();
    if (!mounted) return;
    setState(() {
      _uploading = false;
      if (url != null) {
        _resumeUrl = url;
        _resumeName = 'Resume uploaded';
      } else {
        _error = 'Could not upload resume. Try again.';
      }
    });
  }

  Future<void> _save() async {
    if (_first.text.trim().isEmpty || _last.text.trim().isEmpty) {
      setState(() => _error = 'Enter both first and last name.');
      return;
    }
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      setState(() => _error = 'Enter a valid email.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    final fullName = '${_first.text.trim()} ${_last.text.trim()}';
    await context.read<AppProvider>().updateProfile({
      'name':           fullName,
      'email':          _email.text.trim(),
      'company':        _company.text.trim(),
      'currentCompany': _company.text.trim(),
      'bio':            _bio.text.trim(),
      if (_resumeUrl != null) 'resumeUrl': _resumeUrl,
    });
    if (mounted) { setState(() => _saving = false); context.pop(); }
  }
}

class _ResumeTile extends StatelessWidget {
  final String? fileName;
  final bool uploading;
  final VoidCallback onTap;
  const _ResumeTile({
    required this.fileName, required this.uploading, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: hasFile ? AppColors.emeraldLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFile ? AppColors.emerald.withOpacity(0.4)
                : AppColors.border)),
        child: Row(children: [
          if (uploading)
            const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          else
            Icon(hasFile ? Icons.check_circle_outline : Icons.upload_file,
              size: 20,
              color: hasFile ? AppColors.emerald : AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(
            uploading
                ? 'Uploading...'
                : (fileName ?? 'Upload PDF or DOCX'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: hasFile ? AppColors.emerald : AppColors.textPrimary,
              fontWeight: FontWeight.w600))),
          if (hasFile && !uploading)
            Text('Replace', style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.primary,
              fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _EditVerifyEmailRow extends StatelessWidget {
  final bool verified;
  final VoidCallback onVerifyNow;
  const _EditVerifyEmailRow({
    required this.verified, required this.onVerifyNow,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: verified ? AppColors.emeraldLight : AppColors.primaryLight,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: verified
            ? AppColors.emerald.withOpacity(0.4)
            : AppColors.primary.withOpacity(0.3))),
    child: Row(children: [
      Icon(verified ? Icons.verified_outlined : Icons.mark_email_read_outlined,
        size: 20,
        color: verified ? AppColors.emerald : AppColors.primary),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(verified ? 'Work email verified' : 'Verify your work email',
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: verified ? AppColors.emerald : AppColors.primary)),
        Text(verified
            ? 'Org Verified badge is active on your profile.'
            : 'Unlock the Org Verified badge with a one-time code.',
          style: GoogleFonts.inter(
            fontSize: 11, color: AppColors.textSecond)),
      ])),
      if (!verified)
        TextButton(onPressed: onVerifyNow, child: const Text('Verify')),
    ]),
  );
}
