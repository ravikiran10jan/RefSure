// lib/screens/onboarding_screen.dart
//
// Two-step onboarding:
//   1. Role selection — Job Seeker or Referrer.
//   2. Profile sheet  — first name, last name, email, organisation, CV.
//      CV is mandatory for Job Seekers, optional for Referrers.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/enums/enums.dart';
import '../design_system/design_system.dart';
import '../providers/app_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0 = role, 1 = details
  UserRole? _role;

  final _firstName = TextEditingController();
  final _lastName  = TextEditingController();
  final _email     = TextEditingController();
  final _org       = TextEditingController();
  String? _resumeUrl;
  String? _resumeName;
  bool _uploadingResume = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser;
    if (user != null) {
      final parts = user.name.trim().split(RegExp(r'\s+'));
      if (parts.isNotEmpty) _firstName.text = parts.first;
      if (parts.length > 1) _lastName.text = parts.sublist(1).join(' ');
      _email.text = user.email ?? '';
      _org.text = user.company ?? '';
      _resumeUrl = user.resumeUrl;
      if (_resumeUrl != null) _resumeName = 'Resume on file';
      _role = user.role;
    }
  }

  @override
  void dispose() {
    _firstName.dispose(); _lastName.dispose();
    _email.dispose(); _org.dispose();
    super.dispose();
  }

  bool get _isReferrer => _role == UserRole.provider;
  String get _roleLabel => _isReferrer ? 'Referrer' : 'Job Seeker';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      title: const Text('Set up your profile'),
      leading: _step == 1
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _step = 0))
          : null,
    ),
    body: SafeArea(child: Column(children: [
      LinearProgressIndicator(
        value: (_step + 1) / 2,
        backgroundColor: AppColors.border,
        color: AppColors.primary, minHeight: 3),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: [
          Text('Step ${_step + 1} of 2', style: GoogleFonts.inter(
            fontSize: 12, color: AppColors.textHint)),
        ]),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: _step == 0 ? _roleStep() : _detailsStep(),
      )),
    ])),
  );

  // ── Step 1: role selection ──────────────────────────────────
  Widget _roleStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    Text('How will you use RefSure?', style: GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w800)),
    const SizedBox(height: 4),
    Text('You can switch this later from your profile.',
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecond)),
    const SizedBox(height: 24),

    _RoleCard(
      icon: Icons.person_search_outlined,
      title: 'Job Seeker',
      subtitle: 'Find jobs and request referrals from trusted insiders.',
      selected: _role == UserRole.seeker,
      onTap: () => setState(() => _role = UserRole.seeker),
    ),
    const SizedBox(height: 12),
    _RoleCard(
      icon: Icons.handshake_outlined,
      title: 'Referrer',
      subtitle: 'Share open roles and refer strong candidates from your network.',
      selected: _role == UserRole.provider,
      onTap: () => setState(() => _role = UserRole.provider),
    ),

    const SizedBox(height: 28),
    ElevatedButton(
      onPressed: _role == null ? null : () => setState(() => _step = 1),
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
      child: const Text('Continue')),
  ]);

  // ── Step 2: details sheet ───────────────────────────────────
  Widget _detailsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    Text('Tell us about you', style: GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w800)),
    const SizedBox(height: 4),
    Text('Setting up as $_roleLabel.',
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecond)),
    const SizedBox(height: 20),

    Row(children: [
      Expanded(child: TextField(controller: _firstName,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'First name', hintText: 'Aanya'))),
      const SizedBox(width: 12),
      Expanded(child: TextField(controller: _lastName,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Last name', hintText: 'Sharma'))),
    ]),
    const SizedBox(height: 14),

    TextField(controller: _email,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email', hintText: 'you@example.com',
        prefixIcon: Icon(Icons.mail_outline))),
    const SizedBox(height: 14),

    TextField(controller: _org,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Organisation',
        hintText: 'Where you work or last worked',
        prefixIcon: Icon(Icons.business_outlined))),
    const SizedBox(height: 18),

    // CV upload — required for seekers, optional for referrers.
    Row(children: [
      Text('CV / Resume', style: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary)),
      const SizedBox(width: 6),
      Text(_isReferrer ? '(optional)' : '(required)',
        style: GoogleFonts.inter(
          fontSize: 12, color: AppColors.textHint)),
    ]),
    const SizedBox(height: 8),
    _CvUploadTile(
      fileName: _resumeName,
      uploading: _uploadingResume,
      onTap: _uploadResume,
    ),

    if (_error != null) ...[
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.redLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.red.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: GoogleFonts.inter(
            fontSize: 12, color: AppColors.red))),
        ])),
    ],

    const SizedBox(height: 24),
    ElevatedButton(
      onPressed: _saving ? null : _finish,
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
      child: _saving
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text('Finish setup')),
  ]);

  // ── Actions ─────────────────────────────────────────────────

  Future<void> _uploadResume() async {
    if (_uploadingResume) return;
    setState(() { _uploadingResume = true; _error = null; });
    final url = await context.read<AppProvider>().uploadResume();
    if (!mounted) return;
    setState(() {
      _uploadingResume = false;
      if (url != null) {
        _resumeUrl = url;
        _resumeName = 'Resume uploaded';
      } else {
        _error = 'Could not upload resume. Try again.';
      }
    });
  }

  String? _validate() {
    if (_firstName.text.trim().isEmpty) return 'Enter your first name.';
    if (_lastName.text.trim().isEmpty)  return 'Enter your last name.';
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      return 'Enter a valid email.';
    }
    if (_org.text.trim().isEmpty) return 'Enter your organisation.';
    if (!_isReferrer && _resumeUrl == null) {
      return 'Job Seekers need to upload a CV to continue.';
    }
    return null;
  }

  Future<void> _finish() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() { _saving = true; _error = null; });

    final prov = context.read<AppProvider>();
    final fullName = '${_firstName.text.trim()} ${_lastName.text.trim()}';

    final updates = <String, dynamic>{
      'role':            _role!.name,
      'name':            fullName,
      'email':           _email.text.trim(),
      'company':         _org.text.trim(),
      'currentCompany':  _org.text.trim(),
      'headline':        _isReferrer
          ? 'Referrer at ${_org.text.trim()}'
          : 'Looking for opportunities',
      'profileComplete': _isReferrer ? 70 : 80,
      'activelyLooking': !_isReferrer,
    };
    if (_resumeUrl != null) updates['resumeUrl'] = _resumeUrl;

    await prov.updateProfile(updates);
    if (_role != prov.currentUser?.role) {
      await prov.setActiveRole(_role!);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/');
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({
    required this.icon, required this.title,
    required this.subtitle, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: AppColors.primary)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(
            fontSize: 12, color: AppColors.textSecond, height: 1.4)),
        ])),
        if (selected)
          const Icon(Icons.check_circle, color: AppColors.primary),
      ]),
    ),
  );
}

class _CvUploadTile extends StatelessWidget {
  final String? fileName;
  final bool uploading;
  final VoidCallback onTap;
  const _CvUploadTile({
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
          color: hasFile ? AppColors.emeraldLight : AppColors.surface,
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
                ? 'Uploading…'
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
