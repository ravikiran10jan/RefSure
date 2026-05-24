// lib/features/careers_portal/presentation/screens/careers_portal_screen.dart
// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/external_job.dart';
import 'package:refsure/design_system/theme/app_colors.dart';
import 'package:refsure/features/careers_portal/presentation/cubit/careers_portal_cubit.dart';
import 'package:refsure/features/careers_portal/presentation/cubit/careers_portal_state.dart';
import 'package:refsure/providers/app_provider.dart';

class CareersPortalScreen extends StatefulWidget {
  const CareersPortalScreen({super.key});

  @override
  State<CareersPortalScreen> createState() => _CareersPortalScreenState();
}

class _CareersPortalScreenState extends State<CareersPortalScreen> {
  /// The company resolved from the user's profile (or set via the setup
  /// prompt). Null means we haven't resolved it yet — show the setup prompt.
  String? _resolvedCompany;

  /// Tracks which external job IDs have been imported this session.
  final Set<String> _imported = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveCompany());
  }

  /// Reads the company from the user's profile. If one exists, kicks off
  /// the auto-fetch immediately. Otherwise stays null so the setup prompt
  /// is shown.
  void _resolveCompany() {
    if (!mounted) return;
    final company =
        context.read<AppProvider>().currentUser?.company?.trim() ?? '';
    if (company.isNotEmpty) {
      setState(() => _resolvedCompany = company);
      context.read<CareersPortalCubit>().fetchJobs(company);
    }
    // If empty, _resolvedCompany stays null → _CompanySetupPrompt is shown.
  }

  /// Called by [_CompanySetupPrompt] once the user has confirmed a company.
  /// Persists it to their profile, then kicks off the fetch.
  Future<void> _onCompanyConfirmed(String company) async {
    final name = company.trim();
    if (name.isEmpty) return;

    // 1. Persist to Firestore via AppProvider
    await context.read<AppProvider>().updateProfile({
      'company': name,
      'currentCompany': name,
    });

    // 2. Update local state and start fetching
    if (!mounted) return;
    setState(() => _resolvedCompany = name);
    context.read<CareersPortalCubit>().fetchJobs(name);
  }

  /// Refreshes using the cubit's cached company + current filter setting,
  /// so toggling "all time" survives a refresh tap.
  void _refresh() => context.read<CareersPortalCubit>().refresh();

  @override
  Widget build(BuildContext context) {
    final isProvider = context.watch<AppProvider>().isProvider;

    return BlocListener<CareersPortalCubit, CareersPortalState>(
      listener: (ctx, state) {
        if (state is CareersPortalImported) {
          _imported.add(state.externalJobId);
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(
              '"${state.jobTitle}" posted to RefSure ✓',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
          ));
        }
        if (state is CareersPortalError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Open Roles',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_resolvedCompany != null)
                Text(
                  _resolvedCompany!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          surfaceTintColor: AppColors.primary,
          actions: [
            // Refresh button — only visible once a company is resolved
            if (_resolvedCompany != null)
              BlocBuilder<CareersPortalCubit, CareersPortalState>(
                builder: (_, state) {
                  final busy = state is CareersPortalLoading ||
                      state is CareersPortalImporting;
                  return IconButton(
                    tooltip: 'Refresh listings',
                    onPressed: busy ? null : _refresh,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.refresh_outlined,
                            color: AppColors.primary),
                  );
                },
              ),
            // Change company button
            if (_resolvedCompany != null)
              IconButton(
                tooltip: 'Change company',
                onPressed: _showChangeCompanySheet,
                icon: const Icon(Icons.edit_outlined,
                    size: 20, color: AppColors.textHint),
              ),
          ],
        ),
        body: _resolvedCompany == null
            // ── No company in profile yet — one-time setup ──────
            ? _CompanySetupPrompt(onConfirmed: _onCompanyConfirmed)
            // ── Company known — show live results ───────────────
            : BlocBuilder<CareersPortalCubit, CareersPortalState>(
                builder: (ctx, state) {
                  return switch (state) {
                    CareersPortalInitial() => const _IdleBody(),
                    CareersPortalLoading(:final companyName) =>
                      _LoadingBody(companyName: companyName),
                    CareersPortalLoaded() => _JobsList(
                        state: state,
                        isProvider: isProvider,
                        imported: _imported,
                      ),
                    CareersPortalError(:final message) => _ErrorBody(
                        message: message,
                        companyName: _resolvedCompany!,
                        onRetry: _refresh,
                      ),
                    CareersPortalImporting() => const _ImportingOverlay(),
                    CareersPortalImported() => const _ImportingOverlay(),
                  };
                },
              ),
      ),
    );
  }

  /// Bottom sheet that lets the user change their company after setup.
  void _showChangeCompanySheet() {
    final ctrl =
        TextEditingController(text: _resolvedCompany ?? '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change company',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'We'll save this to your profile and fetch fresh listings.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecond,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Stripe, Google, Shopify',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final name = ctrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(sheetCtx);
                  _onCompanyConfirmed(name);
                },
                child: Text(
                  'Save & Fetch',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(ctrl.dispose);
  }
}

// ══════════════════════════════════════════════════════════════
// One-time company setup prompt
// Shown when AppUser.company is null/empty on first open.
// ══════════════════════════════════════════════════════════════

class _CompanySetupPrompt extends StatefulWidget {
  const _CompanySetupPrompt({required this.onConfirmed});
  final Future<void> Function(String company) onConfirmed;

  @override
  State<_CompanySetupPrompt> createState() => _CompanySetupPromptState();
}

class _CompanySetupPromptState extends State<_CompanySetupPrompt> {
  final _ctrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your company name.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.onConfirmed(name);
      // Screen will rebuild (setState in parent updates _resolvedCompany)
      // so this widget will be replaced — no need to reset _saving.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save company. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(
                Icons.business_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Headline
            Text(
              'Which company do you work at?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Sub-copy
            Text(
              'RefSure will auto-detect your company's careers portal '
              '(Greenhouse, Lever, BambooHR, Workday and more) and '
              'fetch open roles for you. You only need to set this once — '
              'it's saved to your profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecond,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Input
            TextField(
              controller: _ctrl,
              enabled: !_saving,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'e.g. Stripe, Google, Shopify',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textHint),
                prefixIcon: const Icon(
                  Icons.business_outlined, color: AppColors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5)),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),

            // CTA button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        'Fetch Open Roles',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Small reassurance copy
            Text(
              'Saved to your profile — you won't be asked again.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Results list
// ══════════════════════════════════════════════════════════════

class _JobsList extends StatelessWidget {
  const _JobsList({
    required this.state,
    required this.isProvider,
    required this.imported,
  });

  final CareersPortalLoaded state;
  final bool isProvider;
  final Set<String> imported;

  @override
  Widget build(BuildContext context) {
    final jobs = state.jobs;

    return CustomScrollView(slivers: [
      // ── Platform strip + date toggle ──────────────────────
      SliverToBoxAdapter(child: _ResultsStrip(state: state)),

      if (jobs.isEmpty)
        SliverFillRemaining(
          child: _EmptyResults(
            filterActive: state.filterLast30Days,
            totalFetched: state.totalFetched,
            onShowAll: () =>
                context.read<CareersPortalCubit>().toggleDateFilter(),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.separated(
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _ExternalJobCard(
              job: jobs[i],
              isProvider: isProvider,
              alreadyImported: imported.contains(jobs[i].id),
              onImport: () {
                final providerId =
                    context.read<AppProvider>().currentUser?.id ?? '';
                context
                    .read<CareersPortalCubit>()
                    .importJob(jobs[i], providerId);
              },
            ),
          ),
        ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// Platform + date-filter strip (sits above the jobs list)
// ══════════════════════════════════════════════════════════════

class _ResultsStrip extends StatelessWidget {
  const _ResultsStrip({required this.state});
  final CareersPortalLoaded state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Platform badge + job count
        Row(children: [
          _PlatformChip(state.platform),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${state.jobs.length} open role${state.jobs.length == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),

        const SizedBox(height: 10),

        // Date filter toggle
        Row(children: [
          const Icon(Icons.schedule_outlined,
              size: 14, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text(
            state.filterLast30Days
                ? 'Showing last 30 days'
                : 'Showing all time',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecond),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () =>
                context.read<CareersPortalCubit>().toggleDateFilter(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: state.filterLast30Days
                    ? AppColors.primaryLight
                    : AppColors.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: state.filterLast30Days
                      ? AppColors.primary.withOpacity(0.3)
                      : AppColors.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  state.filterLast30Days
                      ? Icons.toggle_on_outlined
                      : Icons.toggle_off_outlined,
                  size: 14,
                  color: state.filterLast30Days
                      ? AppColors.primary
                      : AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  'Last 30 days',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: state.filterLast30Days
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ),
              ]),
            ),
          ),
        ]),

        // Provider hint
        if (context.read<AppProvider>().isProvider) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  size: 13, color: AppColors.info),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tap "Post to RefSure" on any listing to share it '
                  'with seekers on the platform.',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.info),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// External Job Card
// ══════════════════════════════════════════════════════════════

class _ExternalJobCard extends StatelessWidget {
  const _ExternalJobCard({
    required this.job,
    required this.isProvider,
    required this.alreadyImported,
    required this.onImport,
  });

  final ExternalJob job;
  final bool isProvider;
  final bool alreadyImported;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              job.company.isNotEmpty
                  ? job.company[0].toUpperCase()
                  : '?',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                job.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                job.company,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecond,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ),
          if (job.isNew)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'NEW',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
        ]),

        const SizedBox(height: 10),

        // ── Meta ────────────────────────────────────────────
        Wrap(spacing: 12, runSpacing: 4, children: [
          if (job.department != null)
            _MetaChip(Icons.domain_outlined, job.department!),
          if (job.location != null)
            _MetaChip(Icons.location_on_outlined, job.location!),
          if (job.workMode != null) _WorkModeBadge(job.workMode!),
        ]),

        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 8),

        // ── Footer ──────────────────────────────────────────
        Row(children: [
          const Icon(Icons.schedule_outlined,
              size: 12, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text(
            timeago.format(job.postedAt),
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textHint),
          ),
          const Spacer(),
          if (isProvider)
            alreadyImported
                ? const _ImportedBadge()
                : _ImportButton(onTap: onImport),
        ]),
      ]),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: AppColors.textHint),
      const SizedBox(width: 3),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 11, color: AppColors.textSecond),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ],
  );
}

class _WorkModeBadge extends StatelessWidget {
  const _WorkModeBadge(this.mode);
  final String mode;

  @override
  Widget build(BuildContext context) {
    final lower = mode.toLowerCase();
    final Color bg, fg;
    if (lower.contains('remote')) {
      bg = AppColors.emeraldLight;
      fg = AppColors.emerald;
    } else if (lower.contains('hybrid') || lower.contains('flex')) {
      bg = AppColors.amberLight;
      fg = AppColors.amber;
    } else {
      bg = AppColors.primaryLight;
      fg = AppColors.primary;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        mode,
        style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _ImportButton extends StatelessWidget {
  const _ImportButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.upload_outlined,
            size: 13, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          'Post to RefSure',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ]),
    ),
  );
}

class _ImportedBadge extends StatelessWidget {
  const _ImportedBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.emeraldLight,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.check_circle_outline,
          size: 13, color: AppColors.emerald),
      const SizedBox(width: 4),
      Text(
        'Posted',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.emerald,
        ),
      ),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════
// Platform chip
// ══════════════════════════════════════════════════════════════

class _PlatformChip extends StatelessWidget {
  const _PlatformChip(this.platform);
  final AtsPlatform platform;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (platform) {
      AtsPlatform.greenhouse => ('Greenhouse', AppColors.emeraldLight, AppColors.emerald),
      AtsPlatform.lever      => ('Lever',      AppColors.primaryLight,  AppColors.primary),
      AtsPlatform.bamboohr   => ('BambooHR',   AppColors.amberLight,   AppColors.amber),
      AtsPlatform.workday    => ('Workday',    AppColors.infoLight,    AppColors.info),
      AtsPlatform.unknown    => ('Portal',     AppColors.bg,           AppColors.textSecond),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified_outlined, size: 11, color: fg),
        const SizedBox(width: 3),
        Text(
          'via $label',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Auxiliary body states
// ══════════════════════════════════════════════════════════════

/// Shown for the very brief window between screen mount and the first
/// auto-fetch being dispatched (essentially invisible).
class _IdleBody extends StatelessWidget {
  const _IdleBody();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.companyName});
  final String companyName;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text(
          'Searching $companyName’s careers portal…',
          style: GoogleFonts.inter(
            fontSize: 14, color: AppColors.textSecond),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Checking Greenhouse, Lever, BambooHR, Workday',
          style: GoogleFonts.inter(
            fontSize: 11, color: AppColors.textHint),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.companyName,
    required this.onRetry,
  });
  final String message;
  final String companyName;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.redLight, shape: BoxShape.circle),
            child: const Icon(
              Icons.search_off_outlined,
              size: 30,
              color: AppColors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No jobs found for $companyName',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecond),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => context
                    .findAncestorStateOfType<_CareersPortalScreenState>()
                    ?._showChangeCompanySheet(),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Change company'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecond,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({
    required this.filterActive,
    required this.totalFetched,
    required this.onShowAll,
  });
  final bool filterActive;
  final int totalFetched;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 14),
          Text(
            filterActive
                ? 'No jobs posted in the last 30 days'
                : 'No open positions found',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (filterActive && totalFetched > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$totalFetched older listing${totalFetched == 1 ? '' : 's'} '
              'found — toggle the filter to see them.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecond),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onShowAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Show all time'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ImportingOverlay extends StatelessWidget {
  const _ImportingOverlay();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          'Posting job to RefSure…',
          style: GoogleFonts.inter(
            fontSize: 14, color: AppColors.textSecond),
        ),
      ],
    ),
  );
}
