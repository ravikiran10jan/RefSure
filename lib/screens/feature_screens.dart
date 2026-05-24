// lib/screens/feature_screens.dart — v2.0
// Provider Dashboard, Applications (seeker), Post Job, Candidates,
// Profile, Messages, Job Fetch — all enhanced screens
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../core/router/route_names.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/test_data_seeder.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../screens/match_detail_screen.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';
import '../widgets/cards.dart';

// ════════════════════════════════════════════════════════════════
// APPLICATIONS SCREEN  (seeker view)
// ════════════════════════════════════════════════════════════════
class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});
  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  String _tab = 'all';

  static const _tabs = [
    ('all',       'All',        null),
    ('pending',   'Pending',    AppStatus.pending),
    ('referred',  'Referred',   AppStatus.referred),
    ('interview', 'Interview',  AppStatus.interview),
    ('hired',     'Hired',      AppStatus.hired),
  ];

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final all  = prov.myApplications;

    final filtered = _tab == 'all' ? all
        : all.where((a) => a.statusKey == _tab).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: Column(children: [
        Container(color: AppColors.surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: _tabs.map((t) {
              final cnt = t.$3 == null ? all.length : all.where((a) => a.statusKey == t.$1).length;
              final on = _tab == t.$1;
              return Padding(padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _tab = t.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: on ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: on ? AppColors.primary : AppColors.border)),
                    child: Text('${t.$2} ($cnt)', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: on ? Colors.white : AppColors.textSecond)))));
            }).toList()))),
        // ── Summary strip ────────────────────────────────────
        Container(color: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _Strip('${all.where((a) => a.status == AppStatus.strongMatch).length}',
              'Strong Match', AppColors.primary),
            _Strip('${all.where((a) => a.status == AppStatus.shortlisted).length}',
              'Shortlisted', AppColors.accent),
            _Strip('${all.where((a) => a.status == AppStatus.referred).length}',
              'Referred', AppColors.emerald),
            _Strip('${all.where((a) => a.status == AppStatus.hired).length}',
              'Hired', AppColors.gold),
          ])),

        Expanded(child: filtered.isEmpty
          ? EmptyState(icon: Icons.assignment_outlined,
              title: _tab == 'all' ? 'No applications yet' : 'None in this status',
              subtitle: 'Browse jobs and apply',
              action: _tab == 'all' ? ElevatedButton(
                onPressed: () => context.push('/jobs'),
                child: const Text('Browse Jobs')) : null)
          : ListView.separated(
              padding: const EdgeInsets.all(16), itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final app = filtered[i];
                final job = prov.findJob(app.jobId);
                return ApplicationCard(app: app, job: job);
              })),
      ]),
    );
  }
}

class _Strip extends StatelessWidget {
  final String val, label;
  final Color color;
  const _Strip(this.val, this.label, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(val, style: GoogleFonts.inter(
      fontSize: 18, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textHint)),
  ]);
}

// ════════════════════════════════════════════════════════════════
// PROVIDER DASHBOARD
// ════════════════════════════════════════════════════════════════
class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});
  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final user = prov.currentUser;
    final apps = prov.providerApplications;
    if (user == null) return const LoadingSpinner();

    final total      = apps.length;
    final pending    = apps.where((a) => a.status == AppStatus.pending).length;
    final strong     = apps.where((a) => a.status == AppStatus.strongMatch).length;
    final shortl     = apps.where((a) => a.status == AppStatus.shortlisted).length;
    final referred   = apps.where((a) => a.status == AppStatus.referred).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            tooltip: 'Post a Job',
            onPressed: () => context.push('/post-job')),
          Padding(padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: UserAvatar(name: user.name, photoUrl: user.photoUrl, size: 34))),
        ],
        bottom: TabBar(controller: _tabs,
          indicatorColor: AppColors.primary, labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Candidates ($total)'),
            Tab(text: 'My Jobs'),
          ]),
      ),

      body: TabBarView(controller: _tabs, children: [
        _OverviewTab(user: user, apps: apps, total: total,
          pending: pending, strong: strong, shortl: shortl, referred: referred),
        _CandidatesTab(apps: apps),
        _MyJobsTab(),
      ]),
    );
  }
}

// ── Overview Tab ───────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final AppUser user;
  final List<Application> apps;
  final int total, pending, strong, shortl, referred;
  const _OverviewTab({required this.user, required this.apps,
    required this.total, required this.pending, required this.strong,
    required this.shortl, required this.referred});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final topApps = apps.take(5).toList();

    return ListView(padding: const EdgeInsets.all(16), children: [

      // ── Profile completeness nudge ─────────────────────────
      if (!user.orgVerified) GestureDetector(
        onTap: () => context.push('/verify-org'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.verified_user_outlined, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Get Org Verified Badge', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('Builds trust. Seekers prefer verified referrers.',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
            ])),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
          ]))),

      // ── Stats grid ─────────────────────────────────────────
      SectionCard(child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          StatBox(label: 'Total Apps', value: '$total', valueColor: AppColors.primary),
          StatBox(label: 'Strong', value: '$strong', valueColor: AppColors.emerald),
          StatBox(label: 'Shortlisted', value: '$shortl', valueColor: AppColors.accent),
          StatBox(label: 'Referred', value: '$referred', valueColor: AppColors.emerald),
        ]),
        const SizedBox(height: 14),
        TrustScoreBar(user.computedTrustScore),
        const SizedBox(height: 10),
        ProfileCompletenessBar(user.profileComplete),
      ])),

      const SizedBox(height: 16),
      // ── Careers Portal shortcut ────────────────────────────
      GestureDetector(
        onTap: () => context.push(RouteNames.careersPortal),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.travel_explore_outlined,
                color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Fetch Open Jobs from Careers Portal',
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Colors.white)),
              Text('Auto-detect Greenhouse, Lever, BambooHR, Workday',
                style: GoogleFonts.inter(
                  fontSize: 11, color: Colors.white70)),
            ])),
            const Icon(Icons.arrow_forward_ios,
              size: 14, color: Colors.white70),
          ]),
        ),
      ),

      const SizedBox(height: 16),
      SectionHeader(title: 'Top Candidates',
        action: TextButton(onPressed: () {},
          child: const Text('View all'))),
      const SizedBox(height: 10),

      if (topApps.isEmpty)
        const EmptyState(icon: Icons.inbox_outlined,
          title: 'No applications yet',
          subtitle: 'Post jobs to start receiving applications'),

      ...topApps.map((app) {
        final seeker = prov.findUser(app.seekerId);
        final job    = prov.findJob(app.jobId);
        return Padding(padding: const EdgeInsets.only(bottom: 10),
          child: _CandidateCard(app: app, seeker: seeker, job: job));
      }),
    ]);
  }
}

// ── Candidates Tab (ranked list) ───────────────────────────────
class _CandidatesTab extends StatefulWidget {
  final List<Application> apps;
  const _CandidatesTab({required this.apps});
  @override
  State<_CandidatesTab> createState() => _CandidatesTabState();
}

class _CandidatesTabState extends State<_CandidatesTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    final filtered = widget.apps.where((a) {
      return switch (_filter) {
        'strong'    => a.matchScore >= 80,
        'pending'   => a.status == AppStatus.pending,
        'shortlisted' => a.status == AppStatus.shortlisted,
        'referred'  => a.status == AppStatus.referred,
        _           => true,
      };
    }).toList()..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return Column(children: [
      // Filter chips
      Container(color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _FilterTab('All', 'all', _filter, () => setState(() => _filter = 'all')),
            _FilterTab('80+ Match', 'strong', _filter, () => setState(() => _filter = 'strong')),
            _FilterTab('Pending', 'pending', _filter, () => setState(() => _filter = 'pending')),
            _FilterTab('Shortlisted', 'shortlisted', _filter, () => setState(() => _filter = 'shortlisted')),
            _FilterTab('Referred', 'referred', _filter, () => setState(() => _filter = 'referred')),
          ]))),

      Expanded(child: filtered.isEmpty
        ? EmptyState(icon: Icons.inbox_outlined, title: 'No candidates here',
            subtitle: 'Switch filter or post more jobs')
        : ListView.separated(
            padding: const EdgeInsets.all(16), itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final app    = filtered[i];
              final seeker = prov.findUser(app.seekerId);
              final job    = prov.findJob(app.jobId);
              return _CandidateCard(app: app, seeker: seeker, job: job, rankPosition: i + 1);
            })),
    ]);
  }
}

class _FilterTab extends StatelessWidget {
  final String label, value, current;
  final VoidCallback onTap;
  const _FilterTab(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final on = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? AppColors.primary : AppColors.border)),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: on ? Colors.white : AppColors.textSecond))));
  }
}

// ── Candidate Card (provider view) ────────────────────────────
class _CandidateCard extends StatefulWidget {
  final Application app;
  final AppUser? seeker;
  final Job? job;
  final int? rankPosition;
  const _CandidateCard({required this.app, this.seeker, this.job, this.rankPosition});
  @override
  State<_CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<_CandidateCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final app    = widget.app;
    final seeker = widget.seeker;
    final job    = widget.job;
    final report = app.matchReport;

    return SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header row ──────────────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Rank badge
          if (widget.rankPosition != null) Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: widget.rankPosition! <= 3 ? AppColors.goldLight : AppColors.bg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border)),
            alignment: Alignment.center,
            child: Text('${widget.rankPosition}', style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: widget.rankPosition! <= 3 ? AppColors.gold : AppColors.textHint))),
          if (widget.rankPosition != null) const SizedBox(width: 8),

          UserAvatar(name: seeker?.name ?? 'Unknown', photoUrl: seeker?.photoUrl, size: 44),
          const SizedBox(width: 12),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(seeker?.name ?? 'Unknown Seeker',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (seeker?.orgVerified == true) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 14, color: AppColors.emerald)],
            ]),
            Text(seeker?.title ?? '', style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecond),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            if (seeker?.company != null)
              Text(seeker!.company!, style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
          ])),

          // Score ring
          GestureDetector(
            onTap: report != null ? () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MatchDetailScreen(
                report: report, jobTitle: job?.title ?? '',
                company: job?.company ?? '', seekerName: seeker?.name))) : null,
            child: Column(children: [
              MatchScoreRing(app.matchScore, size: 52),
              if (report != null)
                Text('tap to detail', style: GoogleFonts.inter(
                  fontSize: 8, color: AppColors.textHint)),
            ])),
        ]),

        // ── Match band ───────────────────────────────────────
        if (report != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            MatchBandPill(band: report.band, label: report.bandLabel),
            const SizedBox(width: 8),
            StatusPill(status: app.statusKey, label: app.statusLabel),
            const Spacer(),
            Text(timeago.format(app.appliedAt), style: GoogleFonts.inter(
              fontSize: 10, color: AppColors.textHint)),
          ]),
        ] else ...[
          const SizedBox(height: 8),
          StatusPill(status: app.statusKey, label: app.statusLabel),
        ],

        // ── Job context ──────────────────────────────────────
        if (job != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.work_outline, size: 12, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text('${job.title} · ${job.company}', style: GoogleFonts.inter(
              fontSize: 11, color: AppColors.textHint)),
          ]),
        ],

        // ── Skills ───────────────────────────────────────────
        if (seeker != null && seeker.skills.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 4, runSpacing: 4, children: [
            ...seeker.skills.take(4).map((s) => SkillChip(s,
              matched: report?.matchedSkills.map((m) => m.toLowerCase())
                  .contains(s.toLowerCase()) ?? false, compact: true)),
            if (seeker.skills.length > 4)
              Text('+${seeker.skills.length - 4}', style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textHint)),
          ]),
        ],

        // ── Quick summary ────────────────────────────────────
        if (_expanded && report != null) ...[
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(report.recommendation, style: GoogleFonts.inter(
            fontSize: 12, color: AppColors.textSecond, height: 1.5)),
          if (report.matchedSkills.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle_outline,
                size: 12, color: AppColors.emerald),
              const SizedBox(width: 4),
              Expanded(child: Text(report.matchedSkills.join(", "),
                style: GoogleFonts.inter(fontSize: 11,
                  color: AppColors.emerald, fontWeight: FontWeight.w600))),
            ]),
          ],
          if (report.missingSkills.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_outlined,
                size: 12, color: AppColors.amber),
              const SizedBox(width: 4),
              Expanded(child: Text(
                'Missing: ${report.missingSkills.join(", ")}',
                style: GoogleFonts.inter(fontSize: 11,
                  color: AppColors.amber, fontWeight: FontWeight.w600))),
            ]),
          ],
        ],

        // ── Actions ──────────────────────────────────────────
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(children: [
          // Expand/collapse
          if (report != null) GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                size: 16, color: AppColors.primary),
              Text(_expanded ? 'Less' : 'Analysis', style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ])),
          const SizedBox(width: 8),
          // Action row scrolls on narrow screens to prevent overflow.
          Expanded(child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _ActionBtn('Skip', AppColors.redLight, AppColors.red,
                () => _updateStatus(context, AppStatus.notSelected)),
              const SizedBox(width: 6),
              _ActionBtn('Review', AppColors.amberLight, AppColors.amber,
                () => _updateStatus(context, AppStatus.underReview)),
              const SizedBox(width: 6),
              _ActionBtn('Shortlist', AppColors.primaryLight, AppColors.primary,
                () => _updateStatus(context, AppStatus.shortlisted)),
              const SizedBox(width: 6),
              _ActionBtn('Refer', AppColors.emeraldLight, AppColors.emerald,
                () => _referWithNote(context)),
            ]),
          )),
        ]),
      ]),
    );
  }

  void _updateStatus(BuildContext context, AppStatus status) {
    context.read<AppProvider>().updateApplicationStatus(widget.app.id, status);
  }

  void _referWithNote(BuildContext context) {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
          MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Refer ${widget.seeker?.name ?? "Candidate"}',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(widget.job?.title ?? '', style: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textSecond)),
          const SizedBox(height: 16),
          TextField(controller: noteCtrl, maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Optional note to candidate',
              hintText: 'e.g. "Submitted your profile to the hiring manager..."')),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () {
                context.read<AppProvider>().updateApplicationStatus(
                  widget.app.id, AppStatus.referred,
                  note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Referral submitted.'),
                  backgroundColor: AppColors.emerald,
                  behavior: SnackBarBehavior.floating));
              },
              child: const Text('Confirm Referral'))),
          ]),
        ])));
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color bg, fg;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.bg, this.fg, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600, color: fg))));
}

// ── My Jobs Tab ────────────────────────────────────────────────
class _MyJobsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final uid  = prov.currentUser?.id;
    if (uid == null) return const LoadingSpinner();

    final jobs = prov.allJobs.where((j) => j.providerId == uid).toList()
        ..sort((a, b) => b.postedAt.compareTo(a.postedAt));

    return Column(children: [
      Container(color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Text('${jobs.length} jobs posted', style: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textSecond)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => context.push('/post-job'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Post Job'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap)),
        ])),

      Expanded(child: jobs.isEmpty
        ? EmptyState(icon: Icons.work_outline, title: 'No jobs posted yet',
            subtitle: 'Post jobs from your company careers portal or create manually',
            action: ElevatedButton(
              onPressed: () => context.push('/post-job'),
              child: const Text('Post First Job')))
        : ListView.separated(
            padding: const EdgeInsets.all(16), itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final job  = jobs[i];
              final apps = prov.providerApplications.where((a) => a.jobId == job.id).length;
              return _JobManageCard(job: job, appCount: apps);
            })),
    ]);
  }
}

class _JobManageCard extends StatelessWidget {
  final Job job;
  final int appCount;
  const _JobManageCard({required this.job, required this.appCount});

  @override
  Widget build(BuildContext context) => SectionCard(
    onTap: () => context.push('/jobs/${job.id}'),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(child: Text(job.title, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700))),
          if (job.isHot) ...[const SizedBox(width: 6), const HotBadge()],
        ]),
        Text('${job.location} · ${job.workMode} · ${job.minExp}–${job.maxExp} yrs',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecond)),
        const SizedBox(height: 4),
        Row(children: [
          Icon(Icons.people_outline, size: 12, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text('$appCount applicants', style: GoogleFonts.inter(
            fontSize: 11, color: AppColors.textHint)),
          const SizedBox(width: 12),
          Text(timeago.format(job.postedAt), style: GoogleFonts.inter(
            fontSize: 11, color: AppColors.textHint)),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 4, children: job.tags.take(3).map((t) => TagChip(t)).toList()),
      ])),
      Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: job.status == 'active' ? AppColors.emeraldLight : AppColors.bg,
            borderRadius: BorderRadius.circular(20)),
          child: Text(job.status.toUpperCase(), style: GoogleFonts.inter(
            fontSize: 9, fontWeight: FontWeight.w700,
            color: job.status == 'active' ? AppColors.emerald : AppColors.textHint))),
        const SizedBox(height: 6),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
      ]),
    ]));
}

// ════════════════════════════════════════════════════════════════
// POST JOB SCREEN — with tags, notes, hot flag, careers URL
// ════════════════════════════════════════════════════════════════
class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});
  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Post a Job'),
      bottom: TabBar(controller: _tabs,
        indicatorColor: AppColors.primary, labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        tabs: const [Tab(text: 'Manual Entry'), Tab(text: 'Import from Portal')])),
    body: TabBarView(controller: _tabs, children: [
      _ManualPostForm(),
      _CareersPortalImport(),
    ]));
}

class _ManualPostForm extends StatefulWidget {
  @override
  State<_ManualPostForm> createState() => _ManualPostFormState();
}

class _ManualPostFormState extends State<_ManualPostForm> {
  final _title      = TextEditingController();
  final _department = TextEditingController();
  final _location   = TextEditingController();
  final _desc       = TextEditingController();
  final _note       = TextEditingController();
  final _tagInput   = TextEditingController();
  final _extUrl     = TextEditingController();

  String _workMode = 'Hybrid';
  double _minExp = 0, _maxExp = 5;
  double _salMin = 0, _salMax = 30;
  String _deadline = '';
  bool _isHot = false;
  bool _saving = false;

  final List<String> _skills = [];
  final List<String> _preferred = [];
  final List<String> _tags = [];

  static const _commonSkills = [
    'React','Node.js','Python','Java','Go','AWS','Azure','GCP','SQL',
    'MongoDB','TypeScript','Kubernetes','Docker','Spring Boot','Flutter',
    'iOS','Android','Machine Learning','System Design','Product Strategy',
  ];

  static const _commonTags = [
    'urgent','senior','lead','remote-friendly','startup','fintech',
    'healthtech','ai-ml','infra','backend','frontend','fullstack',
  ];

  @override
  void dispose() {
    _title.dispose(); _department.dispose(); _location.dispose();
    _desc.dispose(); _note.dispose(); _tagInput.dispose(); _extUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16), children: [

    SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Basic Info', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      _f('Job Title *', _title, 'e.g. Senior Software Engineer'),
      const SizedBox(height: 12),
      _f('Department', _department, 'e.g. Engineering, Product, Design'),
      const SizedBox(height: 12),
      _f('Location *', _location, 'e.g. Bangalore, Remote'),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _workMode,
        decoration: const InputDecoration(labelText: 'Work Mode'),
        items: ['Remote','Hybrid','On-site']
            .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
        onChanged: (v) => setState(() => _workMode = v!)),
    ])),

    const SizedBox(height: 12),

    SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Experience & Salary', style: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Text('Experience: ${_minExp.round()}–${_maxExp.round()} years',
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
      RangeSlider(
        values: RangeValues(_minExp, _maxExp), min: 0, max: 25, divisions: 25,
        activeColor: AppColors.primary,
        onChanged: (v) => setState(() { _minExp = v.start; _maxExp = v.end; })),
      const SizedBox(height: 8),
      Text('Salary: ${_salMin.round()}–${_salMax.round()} LPA',
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
      RangeSlider(
        values: RangeValues(_salMin, _salMax), min: 0, max: 200, divisions: 40,
        activeColor: AppColors.primary,
        onChanged: (v) => setState(() { _salMin = v.start; _salMax = v.end; })),
    ])),

    const SizedBox(height: 12),

    SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Required Skills *', style: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: _commonSkills.map((s) {
        final on = _skills.contains(s);
        return FilterChip(
          label: Text(s), selected: on,
          onSelected: (_) => setState(() => on ? _skills.remove(s) : _skills.add(s)),
          selectedColor: AppColors.primary, checkmarkColor: Colors.white,
          backgroundColor: AppColors.surface,
          side: BorderSide(color: on ? AppColors.primary : AppColors.border),
          labelStyle: GoogleFonts.inter(
            color: on ? Colors.white : AppColors.textSecond, fontSize: 12));
      }).toList()),
    ])),

    const SizedBox(height: 12),

    SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Tags', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('Add tags to help seekers discover this job',
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint)),
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: _commonTags.map((t) {
        final on = _tags.contains(t);
        return FilterChip(
          label: Text('#$t'), selected: on,
          onSelected: (_) => setState(() => on ? _tags.remove(t) : _tags.add(t)),
          selectedColor: AppColors.accent, checkmarkColor: Colors.white,
          backgroundColor: AppColors.surface,
          side: BorderSide(color: on ? AppColors.accent : AppColors.border),
          labelStyle: GoogleFonts.inter(
            color: on ? Colors.white : AppColors.textSecond, fontSize: 12));
      }).toList()),
    ])),

    const SizedBox(height: 12),

    SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Description *', style: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      TextField(controller: _desc, maxLines: 6,
        decoration: const InputDecoration(
          hintText: 'Describe the role, responsibilities, team, and culture...',
          border: InputBorder.none)),
    ])),

    const SizedBox(height: 12),

    SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Provider Note (private)', style: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('Visible only to you. Not shown to seekers.',
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint)),
      const SizedBox(height: 10),
      TextField(controller: _note, maxLines: 2,
        decoration: const InputDecoration(
          hintText: 'e.g. Hiring manager prefers AWS experience over GCP...',
          border: InputBorder.none)),
    ])),

    const SizedBox(height: 12),

    SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Options', style: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mark as Hot / Urgent', style: GoogleFonts.inter(fontSize: 14)),
          Text('Shown with a Hot badge', style: GoogleFonts.inter(
            fontSize: 11, color: AppColors.textHint)),
        ])),
        Switch(value: _isHot, onChanged: (v) => setState(() => _isHot = v)),
      ]),
      const SizedBox(height: 12),
      _f('Careers Portal URL (optional)', _extUrl, 'https://company.com/careers/job-id'),
      const SizedBox(height: 12),
      TextFormField(
        readOnly: true, decoration: InputDecoration(
          labelText: 'Application Deadline',
          suffixIcon: const Icon(Icons.calendar_today),
          hintText: _deadline.isEmpty ? 'Select date' : _deadline),
        onTap: () async {
          final d = await showDatePicker(
            context: context, initialDate: DateTime.now().add(const Duration(days: 30)),
            firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
          if (d != null) setState(() => _deadline = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}');
        }),
    ])),

    const SizedBox(height: 20),

    ElevatedButton(
      onPressed: _saving ? null : _post,
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
      child: _saving
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text('Publish Job')),
    const SizedBox(height: 16),
  ]);

  Widget _f(String label, TextEditingController ctrl, String hint) =>
    TextField(controller: ctrl, decoration: InputDecoration(labelText: label, hintText: hint));

  Future<void> _post() async {
    if (_title.text.trim().isEmpty || _location.text.trim().isEmpty ||
        _desc.text.trim().isEmpty || _skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fill in title, location, description, and at least one skill')));
      return;
    }
    setState(() => _saving = true);
    await context.read<AppProvider>().postJob({
      'title':          _title.text.trim(),
      'department':     _department.text.trim().isEmpty ? 'Engineering' : _department.text.trim(),
      'location':       _location.text.trim(),
      'workMode':       _workMode,
      'description':    _desc.text.trim(),
      'skills':         _skills,
      'preferredSkills': _preferred,
      'tags':           _tags,
      'minExp':         _minExp.round(),
      'maxExp':         _maxExp.round(),
      'salaryMin':      _salMin.round(),
      'salaryMax':      _salMax.round(),
      'isHot':          _isHot,
      'deadline':       _deadline.isEmpty ? '2026-12-31' : _deadline,
      'providerNote':   _note.text.trim().isEmpty ? null : _note.text.trim(),
      'externalUrl':    _extUrl.text.trim().isEmpty ? null : _extUrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Job published.'),
      backgroundColor: AppColors.emerald, behavior: SnackBarBehavior.floating));
    context.pop();
  }
}

// ── Careers Portal Import ───────────────────────────────────────
class _CareersPortalImport extends StatefulWidget {
  @override
  State<_CareersPortalImport> createState() => _CareersPortalImportState();
}

class _CareersPortalImportState extends State<_CareersPortalImport> {
  final _url = TextEditingController();
  bool _fetching = false;
  List<Map<String, String>> _fetchedJobs = [];
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Import from Company Careers', style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 6),
        Text('Enter your company careers page URL. We\'ll extract open positions '
          'for you to review and publish.', style: GoogleFonts.inter(
          fontSize: 13, color: AppColors.textSecond)),
      ])),

    const SizedBox(height: 16),
    TextField(controller: _url, keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        labelText: 'Careers Page URL',
        hintText: 'https://careers.google.com/jobs',
        prefixIcon: Icon(Icons.link))),
    const SizedBox(height: 12),

    ElevatedButton.icon(
      onPressed: _fetching ? null : _fetch,
      icon: _fetching
          ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.download_outlined),
      label: Text(_fetching ? 'Fetching...' : 'Fetch Open Positions'),
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48))),

    const SizedBox(height: 16),

    if (_fetchedJobs.isNotEmpty) ...[
      Row(children: [
        Text('Found ${_fetchedJobs.length} positions', style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton(
          onPressed: () => setState(() {
            _selected.addAll(List.generate(_fetchedJobs.length, (i) => i));
          }), child: const Text('Select all')),
      ]),
      const SizedBox(height: 8),
      ..._fetchedJobs.asMap().entries.map((e) {
        final on = _selected.contains(e.key);
        return GestureDetector(
          onTap: () => setState(() => on ? _selected.remove(e.key) : _selected.add(e.key)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: on ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: on ? AppColors.primary : AppColors.border,
                width: on ? 2 : 1)),
            child: Row(children: [
              Icon(on ? Icons.check_box : Icons.check_box_outline_blank,
                color: on ? AppColors.primary : AppColors.textHint),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.value['title'] ?? '', style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700)),
                Text('${e.value['location']} · ${e.value['department']}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecond)),
              ])),
            ])));
      }),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: _selected.isEmpty ? null : _publishSelected,
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: Text('Publish ${_selected.length} Job(s)')),
    ],

    // Note about real integration
    const SizedBox(height: 20),
    Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberLight, borderRadius: BorderRadius.circular(8)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline, size: 14, color: AppColors.amber),
        const SizedBox(width: 8),
        Expanded(child: Text(
          'Full careers portal scraping requires a backend Cloud Function '
          'due to CORS restrictions. This screen shows the UX flow. '
          'Connect your Firebase function at /functions/fetchCareers.js.',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.amber, height: 1.4))),
      ])),
  ]);

  Future<void> _fetch() async {
    if (_url.text.trim().isEmpty) return;
    setState(() { _fetching = true; _fetchedJobs = []; _selected.clear(); });
    await Future.delayed(const Duration(seconds: 2)); // Simulate API
    setState(() {
      _fetching = false;
      // Demo data — real version calls Cloud Function
      _fetchedJobs = [
        {'title': 'Software Engineer III', 'location': 'Bangalore', 'department': 'Infrastructure'},
        {'title': 'Senior PM', 'location': 'Hyderabad', 'department': 'Product'},
        {'title': 'Data Scientist', 'location': 'Remote', 'department': 'ML Platform'},
      ];
    });
  }

  Future<void> _publishSelected() async {
    final prov = context.read<AppProvider>();
    for (final i in _selected) {
      final job = _fetchedJobs[i];
      await prov.postJob({
        'title':       job['title']!,
        'location':    job['location']!,
        'department':  job['department']!,
        'workMode':    job['location'] == 'Remote' ? 'Remote' : 'Hybrid',
        'description': 'Imported from ${_url.text.trim()}. Please update with full details.',
        'skills':      <String>[],
        'tags':        <String>['imported'],
        'minExp':      0,
        'maxExp':      10,
        'isHot':       false,
        'externalUrl': _url.text.trim(),
        'deadline':    '2026-12-31',
      });
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${_selected.length} job(s) published!'),
      backgroundColor: AppColors.emerald, behavior: SnackBarBehavior.floating));
    context.pop();
  }
}

// ════════════════════════════════════════════════════════════════
// PROFILE SCREEN
// ════════════════════════════════════════════════════════════════
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final user = prov.currentUser;
    if (user == null) return const LoadingSpinner();

    final isReferrer = prov.isProvider;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('My Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
            onPressed: () => context.push('/edit-profile')),
        ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        SectionCard(child: Column(children: [
          UserAvatar(name: user.name, photoUrl: user.photoUrl, size: 72),
          const SizedBox(height: 12),
          Text(user.name, style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w800)),
          Text(user.headline, style: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textSecond), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (user.verified) ...[const VerifiedBadge(), const SizedBox(width: 8)],
            if (user.orgVerified) OrgBadge(company: user.company),
          ]),
          const SizedBox(height: 12),
          ProfileCompletenessBar(user.profileComplete),
        ])),

        const SizedBox(height: 12),

        // ── Verify work email (Referrers only, until verified) ──
        if (isReferrer && !user.orgVerified) ...[
          _VerifyWorkEmailCard(
            currentEmail: user.orgEmail ?? user.email,
            onVerifyNow: () => context.push('/verify-org')),
          const SizedBox(height: 12),
        ],

        // ── Role switcher ─────────────────────────────────────
        _RoleSwitcherCard(
          activeRole: prov.activeRole,
          onSwitch: (role) => _confirmRoleSwitch(context, role)),

        const SizedBox(height: 12),

        // Info
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Details', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _InfoLine(Icons.mail_outline, user.email ?? 'Add email'),
          _InfoLine(Icons.business_outlined, user.company ?? 'Add organisation'),
          if (user.title.isNotEmpty)
            _InfoLine(Icons.work_outline, user.title),
          if (user.location.isNotEmpty)
            _InfoLine(Icons.location_on_outlined, user.location),
          if (user.experience > 0)
            _InfoLine(Icons.timer_outlined, '${user.experience} years experience'),
          if (user.noticePeriod != null)
            _InfoLine(Icons.schedule_outlined, user.noticePeriod!),
          if (user.expectedSalary != null)
            _InfoLine(Icons.currency_rupee, '${user.expectedSalary} LPA expected'),
          if (user.linkedinUrl != null)
            _InfoLine(Icons.link, user.linkedinUrl!),
          _InfoLine(
            Icons.attach_file,
            user.resumeUrl != null
                ? 'Resume uploaded'
                : (isReferrer ? 'No resume (optional)' : 'No resume yet'),
          ),
        ])),

        if (user.skills.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionHeader(title: 'Skills (${user.skills.length})',
              action: IconButton(icon: const Icon(Icons.edit, size: 16),
                onPressed: () => context.push('/edit-profile'))),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6,
              children: user.skills.map((s) => SkillChip(s)).toList()),
          ])),
        ],

        // Referrer-specific stats
        if (isReferrer) ...[
          const SizedBox(height: 12),
          SectionCard(child: Column(children: [
            Text('Referrer Stats', style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              StatBox(label: 'Jobs Posted', value: '${user.totalJobsPosted}'),
              StatBox(label: 'Referrals Made', value: '${user.referralsMade}',
                valueColor: AppColors.primary),
              StatBox(label: 'Successful', value: '${user.successfulReferrals}',
                valueColor: AppColors.emerald),
              StatBox(label: 'Success %', value: '${user.successRate}%'),
            ]),
            const SizedBox(height: 14),
            TrustScoreBar(user.computedTrustScore),
          ])),
        ],

        const SizedBox(height: 16),

        // Sign out
        OutlinedButton.icon(
          onPressed: () => _confirmSignOut(context),
          icon: const Icon(Icons.logout, size: 16),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red),
            minimumSize: const Size.fromHeight(48))),

        const SizedBox(height: 24),

        // ── Developer section ─────────────────────────────────
        _DeveloperSection(userId: user.id),

        const SizedBox(height: 24),
      ]),
    );
  }

  void _confirmRoleSwitch(BuildContext context, UserRole target) {
    final prov = context.read<AppProvider>();
    if (prov.activeRole == target) return;
    final label = target == UserRole.provider ? 'Referrer' : 'Job Seeker';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Switch to $label?'),
        content: Text(
          target == UserRole.provider
              ? 'You will see the referrer dashboard with candidates and posted jobs.'
              : 'You will see the job seeker home with jobs and matches.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await prov.setActiveRole(target);
              if (context.mounted) context.go('/');
            },
            child: Text('Switch to $label')),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final prov = context.read<AppProvider>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access your profile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await prov.signOut();
              if (context.mounted) context.go('/auth');
            },
            child: const Text('Sign Out')),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// DEVELOPER SECTION  (seed test data)
// ════════════════════════════════════════════════════════════════
class _DeveloperSection extends StatefulWidget {
  final String userId;
  const _DeveloperSection({required this.userId});
  @override
  State<_DeveloperSection> createState() => _DeveloperSectionState();
}

class _DeveloperSectionState extends State<_DeveloperSection> {
  bool _seeding  = false;
  String? _msg;

  Future<void> _seed() async {
    setState(() { _seeding = true; _msg = null; });
    try {
      await TestDataSeeder.seed(FirebaseFirestore.instance, currentUserId: widget.userId);
      if (!mounted) return;
      setState(() => _msg = 'Seed data written — reload the app to see all screens populated.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Test data seeded successfully'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _msg = 'Error: $e');
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.amberLight,
            borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: const Icon(Icons.science_outlined,
            size: 17, color: AppColors.amber)),
        const SizedBox(width: 10),
        Text('Developer', style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: AppColors.amber)),
      ]),
      const SizedBox(height: 8),
      Text(
        'Populate Firestore with realistic QA data — 5 referrers, '
        '6 jobs, 4 applications with varied statuses, a leaderboard, '
        'and 3 gratitude messages. Safe to run once; already-seeded '
        'data is skipped.',
        style: GoogleFonts.inter(
          fontSize: 12, color: AppColors.textSecond, height: 1.4)),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _seeding ? null : _seed,
          icon: _seeding
              ? const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.amber))
              : const Icon(Icons.play_circle_outline,
                  size: 16, color: AppColors.amber),
          label: Text(
            _seeding ? 'Seeding…' : 'Seed Test Data',
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.amber)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.amber),
            padding: const EdgeInsets.symmetric(vertical: 12)))),
      if (_msg != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _msg!.startsWith('Error')
                ? AppColors.redLight : AppColors.emeraldLight,
            borderRadius: BorderRadius.circular(6)),
          child: Text(_msg!, style: GoogleFonts.inter(
            fontSize: 11, height: 1.4,
            color: _msg!.startsWith('Error')
                ? AppColors.red : AppColors.emerald))),
      ],
    ]),
  );
}

class _RoleSwitcherCard extends StatelessWidget {
  final UserRole activeRole;
  final ValueChanged<UserRole> onSwitch;
  const _RoleSwitcherCard({required this.activeRole, required this.onSwitch});

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Account mode', style: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('Switch between Job Seeker and Referrer at any time.',
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecond)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _RoleToggle(
          icon: Icons.person_search_outlined,
          label: 'Job Seeker',
          selected: activeRole == UserRole.seeker,
          onTap: () => onSwitch(UserRole.seeker))),
        const SizedBox(width: 10),
        Expanded(child: _RoleToggle(
          icon: Icons.handshake_outlined,
          label: 'Referrer',
          selected: activeRole == UserRole.provider,
          onTap: () => onSwitch(UserRole.provider))),
      ]),
    ]),
  );
}

class _RoleToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleToggle({
    required this.icon, required this.label,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 16,
          color: selected ? AppColors.primary : AppColors.textSecond),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected ? AppColors.primary : AppColors.textSecond)),
        if (selected) ...[
          const SizedBox(width: 6),
          const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
        ],
      ]),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.textHint),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: GoogleFonts.inter(
        fontSize: 13, color: AppColors.textSecond))),
    ]));
}

/// Prompts a Referrer to verify their work email via OTP. Shown on the
/// profile until [AppUser.orgVerified] flips to true. Tapping "Verify now"
/// opens the OTP screen; "Verify later" simply dismisses the visual prompt
/// for this session — the card returns on the next visit.
class _VerifyWorkEmailCard extends StatefulWidget {
  final String? currentEmail;
  final VoidCallback onVerifyNow;
  const _VerifyWorkEmailCard({
    required this.currentEmail, required this.onVerifyNow,
  });
  @override
  State<_VerifyWorkEmailCard> createState() => _VerifyWorkEmailCardState();
}

class _VerifyWorkEmailCardState extends State<_VerifyWorkEmailCard> {
  bool _dismissed = false;
  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.mark_email_read_outlined,
              size: 18, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Verify your work email', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700)),
            Text(widget.currentEmail == null
                ? 'Confirm your work email to unlock the Org Verified badge.'
                : 'Send a code to ${widget.currentEmail} to unlock the Org '
                  'Verified badge.',
              style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecond, height: 1.4)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => setState(() => _dismissed = true),
            child: const Text('Verify later'))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: widget.onVerifyNow,
            child: const Text('Verify now'))),
        ]),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// MESSAGES SCREEN
// ════════════════════════════════════════════════════════════════
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final contacts = prov.isProvider ? prov.seekers : prov.providers;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: contacts.isEmpty
          ? const EmptyState(icon: Icons.chat_bubble_outline,
              title: 'No conversations',
              subtitle: 'Message referrers to ask about open roles')
          : ListView.separated(
              padding: const EdgeInsets.all(16), itemCount: contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final c = contacts[i];
                return SectionCard(
                  onTap: () => context.push('/messages/${c.id}'),
                  child: Row(children: [
                    UserAvatar(name: c.name, photoUrl: c.photoUrl, size: 44,
                      showOnlineDot: true),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.name, style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('${c.title} · ${c.company ?? ""}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecond)),
                    ])),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
                  ]));
              }),
    );
  }
}

// ── Chat Screen ─────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String otherId;
  const ChatScreen({super.key, required this.otherId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final prov  = context.watch<AppProvider>();
    final other = prov.findUser(widget.otherId);
    final uid   = prov.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: other != null
            ? Row(children: [
                UserAvatar(name: other.name, photoUrl: other.photoUrl, size: 32),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(other.name, style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(other.title, style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textHint)),
                ]),
              ])
            : const Text('Chat')),

      body: Column(children: [
        Expanded(child: StreamBuilder<List<Message>>(
          stream: prov.watchConversation(widget.otherId),
          builder: (ctx, snap) {
            if (!snap.hasData) return const LoadingSpinner();
            final msgs = snap.data!;
            return ListView.builder(
              controller: _scroll, padding: const EdgeInsets.all(16),
              itemCount: msgs.length,
              itemBuilder: (ctx, i) {
                final m    = msgs[i];
                final mine = m.fromId == uid;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(ctx).size.width * 0.72),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: mine ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: mine ? const Radius.circular(4) : null,
                        bottomLeft:  mine ? null : const Radius.circular(4)),
                      border: mine ? null : Border.all(color: AppColors.border)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(m.text, style: GoogleFonts.inter(
                        fontSize: 14, color: mine ? Colors.white : AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(timeago.format(m.sentAt), style: GoogleFonts.inter(
                        fontSize: 9, color: mine ? Colors.white54 : AppColors.textHint)),
                    ])));
              });
          })),

        Container(
          padding: EdgeInsets.only(
            left: 16, right: 8, top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 10),
          decoration: const BoxDecoration(color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Expanded(child: TextField(controller: _ctrl, maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Message...', border: InputBorder.none))),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
              onPressed: _send),
          ])),
      ]),
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await context.read<AppProvider>().sendMessage(widget.otherId, text);
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }
}
