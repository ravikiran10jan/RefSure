// lib/screens/main_screens.dart — v2.0
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/common.dart';
import '../widgets/cards.dart';
import 'match_detail_screen.dart';

// ── Home Screen ────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final user = prov.currentUser;
    if (user == null) return const _ProfileMissingState();

    final metrics  = prov.seekerMetrics;
    final myApps   = prov.myApplications;
    final topJobs  = prov.filteredJobs.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          floating: true, backgroundColor: AppColors.primary, surfaceTintColor: AppColors.primary,
          elevation: 0, scrolledUnderElevation: 1,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hello, ${user.name.split(' ').first}', style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            Text('Where real referrals happen', style: GoogleFonts.inter(
              fontSize: 11, color: Colors.white70)),
          ]),
          actions: [
            IconButton(
              tooltip: 'Messages',
              onPressed: () => context.push('/messages'),
              icon: const Icon(Icons.chat_bubble_outline,
                color: Colors.white)),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications'),
              icon: Stack(children: [
                const Icon(Icons.notifications_outlined, color: Colors.white),
                if (prov.unreadCount > 0) Positioned(right: 0, top: 0,
                  child: Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle))),
              ])),
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Padding(padding: const EdgeInsets.only(right: 16),
                child: UserAvatar(name: user.name, photoUrl: user.photoUrl, size: 36))),
          ],
        ),

        SliverPadding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList(delegate: SliverChildListDelegate([

            // ── Search ─────────────────────────────────────
            _SearchBar(onTap: () => context.push('/jobs')),
            const SizedBox(height: 16),

            // ── Dashboard ──────────────────────────────────
            _SeekerDashboard(metrics: metrics,
              onTap: () => context.push('/applications')),
            const SizedBox(height: 16),

            // ── Quick actions ──────────────────────────────
            _QuickActions(),
            const SizedBox(height: 20),

            // ── Recent applications ────────────────────────
            if (myApps.isNotEmpty) ...[
              SectionHeader(
                title: 'Recent applications',
                action: TextButton(onPressed: () => context.push('/applications'),
                  child: const Text('View all'))),
              const SizedBox(height: 10),
              ...myApps.take(2).map((app) {
                final job = prov.findJob(app.jobId);
                return Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: ApplicationCard(app: app, job: job));
              }),
              const SizedBox(height: 20),
            ],

            // ── Hot jobs ───────────────────────────────────
            SectionHeader(
              title: 'Hot jobs',
              action: TextButton(onPressed: () => context.push('/jobs'),
                child: const Text('See all'))),
            const SizedBox(height: 10),
            if (topJobs.isEmpty)
              _EmptyMini(text: 'No active jobs right now. Check back soon.')
            else
              ...topJobs.map((j) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: JobCard(job: j))),
            const SizedBox(height: 20),

            // ── Leadership board ───────────────────────────
            const _LeadershipBoard(),
          ])),
        ),
      ]),
    );
  }
}

class _ProfileMissingState extends StatelessWidget {
  const _ProfileMissingState();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.person_off_outlined, size: 64, color: AppColors.textHint),
      const SizedBox(height: 16),
      Text('Profile not found', style: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Your account exists but profile is missing.',
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecond)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () async {
          await context.read<AppProvider>().signOut();
          if (context.mounted) context.go('/auth');
        },
        child: const Text('Sign Out & Sign Up Again')),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => context.go('/onboarding'),
        child: const Text('Complete Profile Setup')),
    ])));
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border)),
      child: Row(children: [
        const Icon(Icons.search, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Text('Search jobs, companies, skills',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textHint)),
      ])));
}

class _SeekerDashboard extends StatelessWidget {
  final SeekerMetrics metrics;
  final VoidCallback onTap;
  const _SeekerDashboard({required this.metrics, required this.onTap});

  @override
  Widget build(BuildContext context) => SectionCard(
    onTap: onTap,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Your referrals', style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w700)),
        const Spacer(),
        Text('Total ${metrics.total}', style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _MetricTile(
          icon: Icons.pending_actions_outlined,
          label: 'Pending',
          value: metrics.pending,
          color: AppColors.amber)),
        const SizedBox(width: 8),
        Expanded(child: _MetricTile(
          icon: Icons.trending_up,
          label: 'Open',
          value: metrics.open,
          color: AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: _MetricTile(
          icon: Icons.task_alt,
          label: 'Completed',
          value: metrics.completed,
          color: AppColors.emerald)),
      ]),
    ]),
  );
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _MetricTile({
    required this.icon, required this.label,
    required this.value, required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: AppColors.bg, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text('$value', style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ]),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.inter(
        fontSize: 11, color: AppColors.textSecond, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _QuickActionTile(
      icon: Icons.work_outline, label: 'Browse jobs',
      onTap: () => context.push('/jobs'))),
    const SizedBox(width: 10),
    Expanded(child: _QuickActionTile(
      icon: Icons.handshake_outlined, label: 'Referrers',
      onTap: () => context.push('/providers'))),
    const SizedBox(width: 10),
    Expanded(child: _QuickActionTile(
      icon: Icons.chat_bubble_outline, label: 'Messages',
      onTap: () => context.push('/messages'))),
    const SizedBox(width: 10),
    Expanded(child: _QuickActionTile(
      icon: Icons.assignment_outlined, label: 'Applied',
      onTap: () => context.push('/applications'))),
  ]);
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionTile({
    required this.icon, required this.label, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border)),
        child: Column(children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary), textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}

class _EmptyMini extends StatelessWidget {
  final String text;
  const _EmptyMini({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border)),
    alignment: Alignment.center,
    child: Text(text, style: GoogleFonts.inter(
      fontSize: 12, color: AppColors.textHint)),
  );
}

/// Home leadership section. Lets the seeker toggle between two rankings:
///   - Most referrals
///   - Most appreciated (gratitudes)
/// Both views pull from `AppProvider.leaderboard` so the underlying list is
/// identical, only the sort field differs.
class _LeadershipBoard extends StatefulWidget {
  const _LeadershipBoard();
  @override
  State<_LeadershipBoard> createState() => _LeadershipBoardState();
}

class _LeadershipBoardState extends State<_LeadershipBoard> {
  LeaderboardSort _sort = LeaderboardSort.referrals;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final top = prov.leaderboard(_sort);
    return SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Leadership board', style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton(onPressed: () => context.push('/providers'),
            child: const Text('See all')),
        ]),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.bg, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Expanded(child: _LeaderboardTab(
              icon: Icons.handshake_outlined,
              label: 'Most referrals',
              selected: _sort == LeaderboardSort.referrals,
              onTap: () => setState(() => _sort = LeaderboardSort.referrals))),
            Expanded(child: _LeaderboardTab(
              icon: Icons.favorite_outline,
              label: 'Most appreciated',
              selected: _sort == LeaderboardSort.gratitudes,
              onTap: () => setState(() => _sort = LeaderboardSort.gratitudes))),
          ]),
        ),
        const SizedBox(height: 12),
        if (top.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No referrers yet.', style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textHint))),
        for (var i = 0; i < top.length; i++)
          _LeaderRow(rank: i + 1, user: top[i], sort: _sort),
      ]),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LeaderboardTab({
    required this.icon, required this.label,
    required this.selected, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: selected ? Border.all(color: AppColors.border) : null),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 14,
          color: selected ? AppColors.primary : AppColors.textSecond),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? AppColors.primary : AppColors.textSecond),
          overflow: TextOverflow.ellipsis, maxLines: 1)),
      ]),
    ),
  );
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final AppUser user;
  final LeaderboardSort sort;
  const _LeaderRow({
    required this.rank, required this.user, required this.sort,
  });

  @override
  Widget build(BuildContext context) {
    final value = sort == LeaderboardSort.referrals
        ? user.referralsMade
        : user.gratitudesReceived;
    final unit = sort == LeaderboardSort.referrals
        ? (value == 1 ? 'referral' : 'referrals')
        : (value == 1 ? 'thanks' : 'thanks');
    final medal = rank <= 3;
    return InkWell(
      onTap: () => context.push('/providers/${user.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: medal ? AppColors.goldLight : AppColors.bg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border)),
            alignment: Alignment.center,
            child: Text('$rank', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w800,
              color: medal ? AppColors.gold : AppColors.textSecond))),
          const SizedBox(width: 10),
          UserAvatar(name: user.name, photoUrl: user.photoUrl, size: 32),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(user.name, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (user.orgVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 12, color: AppColors.primary),
              ],
            ]),
            if (user.company != null && user.company!.isNotEmpty)
              Text(user.company!, style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textHint)),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$value', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w800,
              color: AppColors.primary)),
            Text(unit, style: GoogleFonts.inter(
              fontSize: 9, color: AppColors.textHint)),
          ]),
        ]),
      ),
    );
  }
}

// ── Jobs Screen ─────────────────────────────────────────────────
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final _q = TextEditingController();

  @override
  void dispose() { _q.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<AppProvider>();
    final filter = prov.jobFilter;
    final jobs   = prov.filteredJobs;
    final user   = prov.currentUser;
    final hasCv  = (user?.resumeUrl ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Jobs')),
      body: Column(children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(children: [
            TextField(controller: _q, onChanged: (v) {
                prov.updateJobFilter(prov.jobFilter.copyWith(query: v));
              },
              decoration: InputDecoration(
                hintText: 'Search jobs, skills, companies',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _q.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear),
                        onPressed: () {
                          _q.clear();
                          prov.updateJobFilter(prov.jobFilter.copyWith(query: ''));
                        })
                    : null)),
            const SizedBox(height: 10),
            // Sort + work mode dropdowns + advanced filters button.
            Row(children: [
              Expanded(child: _FilterDropdown<JobSortBy>(
                icon: Icons.sort,
                label: 'Sort',
                value: filter.sortBy,
                items: const {
                  JobSortBy.matchScore: 'Best match',
                  JobSortBy.recent:     'Most recent',
                  JobSortBy.hotFirst:   'Hot first',
                },
                onChanged: (v) => prov.updateJobFilter(filter.copyWith(sortBy: v)))),
              const SizedBox(width: 10),
              Expanded(child: _FilterDropdown<String?>(
                icon: Icons.location_city_outlined,
                label: 'Work mode',
                value: filter.workMode,
                items: const {
                  null:      'All modes',
                  'Remote':  'Remote',
                  'Hybrid':  'Hybrid',
                  'On-site': 'On-site',
                },
                onChanged: prov.setJobWorkMode)),
              const SizedBox(width: 10),
              _AdvancedFiltersButton(
                badge: filter.activeCount,
                onTap: () => _showFilterSheet(context)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _ToggleChip(
                icon: Icons.local_fire_department_outlined,
                label: 'Hot',
                selected: filter.hotOnly,
                onTap: () => prov.updateJobFilter(
                  filter.copyWith(hotOnly: !filter.hotOnly))),
              const SizedBox(width: 8),
              _ToggleChip(
                icon: Icons.fiber_new_outlined,
                label: 'Today',
                selected: filter.todayOnly,
                onTap: () => prov.updateJobFilter(
                  filter.copyWith(todayOnly: !filter.todayOnly))),
              const SizedBox(width: 8),
              _ToggleChip(
                icon: Icons.calendar_today_outlined,
                label: 'Last 10 days',
                selected: filter.last10Days,
                onTap: () => prov.updateJobFilter(
                  filter.copyWith(last10Days: !filter.last10Days))),
              const Spacer(),
              if (filter.isActive)
                TextButton.icon(
                  onPressed: prov.clearJobFilter,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: Text('Clear (${filter.activeCount})')),
            ]),
          ]),
        ),

        // CV upload nudge — Best Match only delivers great rankings once we
        // have a CV to score against.
        if (prov.isSeeker && !hasCv && filter.sortBy == JobSortBy.matchScore)
          _CvNudgeBanner(),

        Expanded(child: jobs.isEmpty
          ? EmptyState(icon: Icons.search_off_outlined,
              title: 'No jobs found',
              subtitle: 'Try different filters or clear all',
              action: TextButton(onPressed: prov.clearJobFilter,
                child: const Text('Clear filters')))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                if (i == 0) return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Text('${jobs.length} jobs', style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textHint)),
                    const Spacer(),
                    if (filter.sortBy == JobSortBy.matchScore && prov.isSeeker)
                      Row(children: [
                        const Icon(Icons.gps_fixed,
                          size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Sorted by match',
                          style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                      ]),
                  ]));
                return JobCard(job: jobs[i - 1]);
              })),
      ]),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true,
      builder: (ctx) => const _FilterSheet());
  }
}

/// Pill-shaped dropdown that fits the design system. Used on the Jobs
/// header for Sort and Work Mode.
class _FilterDropdown<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  const _FilterDropdown({
    required this.icon, required this.label,
    required this.value, required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, size: 18,
          color: AppColors.textSecond),
        style: GoogleFonts.inter(
          fontSize: 13, color: AppColors.textPrimary,
          fontWeight: FontWeight.w600),
        items: [
          for (final e in items.entries) DropdownMenuItem<T>(
            value: e.key,
            child: Row(children: [
              Icon(icon, size: 14, color: AppColors.textSecond),
              const SizedBox(width: 8),
              Flexible(child: Text(e.value,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary))),
            ])),
        ],
        onChanged: (v) { if (v != null || null is T) onChanged(v as T); },
        selectedItemBuilder: (_) => [
          for (final e in items.entries) Row(children: [
            Icon(icon, size: 14, color: AppColors.textSecond),
            const SizedBox(width: 6),
            Flexible(child: Text('$label: ${e.value}',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary))),
          ]),
        ],
      ),
    ),
  );
}

class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({
    required this.icon, required this.label,
    required this.selected, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12,
          color: selected ? Colors.white : AppColors.textSecond),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.textSecond)),
      ]),
    ),
  );
}

class _AdvancedFiltersButton extends StatelessWidget {
  final int badge;
  final VoidCallback onTap;
  const _AdvancedFiltersButton({required this.badge, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border)),
        child: Stack(clipBehavior: Clip.none, children: [
          const Icon(Icons.tune, size: 18, color: AppColors.textPrimary),
          if (badge > 0)
            Positioned(right: -6, top: -4,
              child: Container(
                width: 14, height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('$badge', style: GoogleFonts.inter(
                  fontSize: 9, color: Colors.white,
                  fontWeight: FontWeight.w800)))),
        ]),
      ),
    ),
  );
}

class _CvNudgeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.primary.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.upload_file, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Expanded(child: Text(
        'Upload your CV to see jobs ranked by match score.',
        style: GoogleFonts.inter(
          fontSize: 12, color: AppColors.primary,
          fontWeight: FontWeight.w600))),
      TextButton(onPressed: () => context.push('/edit-profile'),
        child: const Text('Add CV')),
    ]),
  );
}

// ── Filter Bottom Sheet ────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  const _FilterSheet();
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _loc;
  RangeValues _exp = const RangeValues(0, 25);

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<AppProvider>();
    final filter = prov.jobFilter;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20,
        MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Advanced Filters', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton(onPressed: () { prov.clearJobFilter(); Navigator.pop(context); },
            child: const Text('Reset all')),
        ]),
        const SizedBox(height: 16),

        TextField(
          onChanged: (v) => setState(() => _loc = v),
          decoration: const InputDecoration(
            labelText: 'Location', prefixIcon: Icon(Icons.location_on_outlined))),
        const SizedBox(height: 14),

        Text('Experience Range: ${_exp.start.round()}–${_exp.end.round()} yrs',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        RangeSlider(
          values: _exp, min: 0, max: 25, divisions: 25,
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() => _exp = v)),

        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            prov.updateJobFilter(filter.copyWith(
              location: _loc?.isEmpty == true ? null : _loc,
              minExp: _exp.start.round(),
              maxExp: _exp.end.round()));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Apply Filters')),
      ]));
  }
}

// ── Job Detail Screen ──────────────────────────────────────────
class JobDetailScreen extends StatelessWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final prov     = context.watch<AppProvider>();
    final job      = prov.findJob(jobId);
    if (job == null) return const Scaffold(body: Center(child: Text('Job not found')));

    final user     = prov.currentUser;
    final report   = user != null && prov.isSeeker ? prov.computeMatch(job) : null;
    final myApp    = prov.myApplications.firstWhere(
      (a) => a.jobId == jobId, orElse: () =>
        Application(id: '', jobId: '', seekerId: '', providerId: '', matchScore: 0));
    final provider = prov.findUser(job.providerId);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(job.company), actions: [
        if (report != null) Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MatchDetailScreen(
                report: report, jobTitle: job.title, company: job.company,
                seekerName: user?.name))),
            child: const Text('Full Analysis'))),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // Job header card
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _CompanyLogo(letter: job.companyLogo, size: 52),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(job.title, style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800)),
              Text('${job.company} · ${job.department}', style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecond, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(children: [
                WorkModePill(job.workMode),
                if (job.isHot) ...[const SizedBox(width: 8), const HotBadge()],
                if (job.isNew) ...[const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4)),
                    child: Text('NEW', style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primary)))],
              ]),
            ])),
            if (report != null) MatchScoreRing(report.score, size: 56),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 6, children: [
            InfoRow(Icons.location_on_outlined, job.location),
            InfoRow(Icons.work_outline, '${job.minExp}–${job.maxExp} yrs'),
            if (job.salaryMax > 0) InfoRow(Icons.currency_rupee,
              '${job.salaryMin}–${job.salaryMax}L'),
            InfoRow(Icons.people_outline, '${job.applicants} applied'),
            InfoRow(Icons.calendar_today, 'Deadline: ${job.deadline}'),
          ]),
          if (job.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4,
              children: job.tags.map((t) => TagChip(t)).toList()),
          ],
        ])),

        // Match report card
        if (report != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MatchDetailScreen(
                report: report, jobTitle: job.title,
                company: job.company, seekerName: user?.name))),
            child: SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Match Analysis', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                MatchBandPill(band: report.band, label: report.bandLabel),
              ]),
              const SizedBox(height: 12),
              if (report.matchedSkills.isNotEmpty) ...[
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.check_circle_outline,
                    size: 14, color: AppColors.emerald),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    'Matched: ${report.matchedSkills.take(3).join(", ")}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.emerald,
                      fontWeight: FontWeight.w600))),
                ]),
                const SizedBox(height: 4),
              ],
              if (report.missingSkills.isNotEmpty)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.warning_amber_outlined,
                    size: 14, color: AppColors.amber),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    'Missing: ${report.missingSkills.take(2).join(", ")}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.amber,
                      fontWeight: FontWeight.w600))),
                ]),
              const SizedBox(height: 8),
              Row(children: [
                Text('Tap to see full analysis', style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.primary,
                  fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward,
                  size: 12, color: AppColors.primary),
              ]),
            ])),
          ),
        ],

        const SizedBox(height: 12),

        // Description
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('About this role', style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(job.description, style: GoogleFonts.inter(
            fontSize: 14, color: AppColors.textSecond, height: 1.6)),
        ])),

        const SizedBox(height: 12),

        // Skills
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Required Skills', style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: job.skills.map((s) =>
            SkillChip(s, highlight: true,
              matched: report?.matchedSkills.map((m) => m.toLowerCase())
                  .contains(s.toLowerCase()) ?? false)).toList()),
          if (job.preferredSkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Preferred', style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6,
              children: job.preferredSkills.map((s) => SkillChip(s)).toList()),
          ],
        ])),

        // Provider card
        if (provider != null) ...[
          const SizedBox(height: 12),
          SectionCard(
            onTap: () => context.push('/providers/${provider.id}'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Posted by', style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(children: [
                UserAvatar(name: provider.name, photoUrl: provider.photoUrl, size: 44),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(provider.name, style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700)),
                    if (provider.verified) ...[const SizedBox(width: 6), const VerifiedBadge()],
                  ]),
                  Text('${provider.title} · ${provider.company ?? ""}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecond)),
                ])),
                Column(children: [
                  Text('${provider.referralsMade}', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  Text('Referrals', style: GoogleFonts.inter(
                    fontSize: 9, color: AppColors.textHint)),
                ]),
              ]),
              if (provider.orgVerified) ...[
                const SizedBox(height: 8),
                OrgBadge(company: provider.company),
              ],
            ])),
        ],

        const SizedBox(height: 80),
      ]),

      // Bottom action bar
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border))),
          child: myApp.id.isNotEmpty
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle, color: AppColors.emerald),
                  const SizedBox(width: 8),
                  Text('Applied · ${myApp.statusLabel}', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.emerald)),
                ])
              : Row(children: [
                  if (provider != null)
                    Expanded(child: OutlinedButton(
                      onPressed: () => context.push('/messages/${provider.id}'),
                      child: const Text('Message'))),
                  if (provider != null) const SizedBox(width: 12),
                  Expanded(flex: 2, child: _FullApplyButton(job: job, report: report)),
                ]),
        ),
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  final String letter;
  final double size;
  const _CompanyLogo({required this.letter, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.primary.withOpacity(0.2))),
    alignment: Alignment.center,
    child: Text(letter.toUpperCase(), style: GoogleFonts.inter(
      fontSize: size * 0.45, fontWeight: FontWeight.w900,
      color: AppColors.primary)));
}

class _FullApplyButton extends StatefulWidget {
  final Job job;
  final MatchReport? report;
  const _FullApplyButton({required this.job, this.report});
  @override
  State<_FullApplyButton> createState() => _FullApplyButtonState();
}

class _FullApplyButtonState extends State<_FullApplyButton> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: _loading ? null : _apply,
    child: _loading
        ? const SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(widget.report != null
            ? 'Apply · ${widget.report!.score}% match' : 'Apply Now'));

  Future<void> _apply() async {
    setState(() => _loading = true);
    final r = await context.read<AppProvider>().applyToJob(widget.job);
    if (!mounted) return;
    setState(() => _loading = false);
    final msgs = {
      true:         ('Applied. The provider will be notified.', AppColors.emerald),
      'already':    ('Already applied to this job.', AppColors.textSecond),
      'low_match':  ('Match score below 40%. Update your profile.', AppColors.amber),
    };
    final m = msgs[r] ?? ('Error. Try again.', AppColors.red);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m.$1), backgroundColor: m.$2, behavior: SnackBarBehavior.floating));
  }
}

// ── Providers Screen ────────────────────────────────────────────
class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({super.key});
  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  final _q   = TextEditingController();
  bool _verifiedOnly = false;
  bool _orgVerifiedOnly = false;
  String _sortBy = 'trust';

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    var providers = prov.providers.where((p) {
      if (_q.text.isNotEmpty) {
        final q = _q.text.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
               (p.company?.toLowerCase().contains(q) ?? false) ||
               p.skills.any((s) => s.toLowerCase().contains(q)) ||
               p.location.toLowerCase().contains(q);
      }
      return true;
    }).where((p) => !_verifiedOnly || p.verified)
      .where((p) => !_orgVerifiedOnly || p.orgVerified)
      .toList();

    providers.sort((a, b) => switch (_sortBy) {
      'trust'   => b.computedTrustScore.compareTo(a.computedTrustScore),
      'referrals' => b.referralsMade.compareTo(a.referralsMade),
      'response'  => a.avgResponseHours.compareTo(b.avgResponseHours),
      _           => b.computedTrustScore.compareTo(a.computedTrustScore),
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Referrers')),
      body: Column(children: [
        Container(color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16,8,16,10),
          child: TextField(controller: _q, onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search by name, company, skill, location...',
              prefixIcon: Icon(Icons.search, color: AppColors.primary)))),
        // Filter/sort bar
        Container(color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _QuickChip('Verified', _verifiedOnly,
                () => setState(() => _verifiedOnly = !_verifiedOnly)),
              _QuickChip('Org Verified', _orgVerifiedOnly,
                () => setState(() => _orgVerifiedOnly = !_orgVerifiedOnly)),
              _QuickChip('Trust', _sortBy == 'trust',
                () => setState(() => _sortBy = 'trust')),
              _QuickChip('Most Referrals', _sortBy == 'referrals',
                () => setState(() => _sortBy = 'referrals')),
              _QuickChip('Fastest Response', _sortBy == 'response',
                () => setState(() => _sortBy = 'response')),
            ]))),

        Expanded(child: providers.isEmpty
          ? const EmptyState(icon: Icons.group_outlined, title: 'No referrers found',
              subtitle: 'Try different filters')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: providers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => ProviderCard(provider: providers[i]))),
      ]),
    );
  }
}

// ── Provider Detail ─────────────────────────────────────────────
class ProviderDetailScreen extends StatelessWidget {
  final String providerId;
  const ProviderDetailScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    final prov     = context.watch<AppProvider>();
    final provider = prov.findUser(providerId);
    if (provider == null) return const Scaffold(body: Center(child: Text('Not found')));
    final jobs = prov.activeJobs.where((j) => j.providerId == providerId).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(provider.name)),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // Profile header
        SectionCard(child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            UserAvatar(name: provider.name, photoUrl: provider.photoUrl, size: 64),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(provider.name, style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w800))),
                if (provider.verified) ...[const SizedBox(width: 8), const VerifiedBadge()],
              ]),
              Text(provider.headline, style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecond)),
              if (provider.company != null)
                Text(provider.company!, style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              if (provider.badge != null) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldLight, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.workspace_premium_outlined,
                    size: 14, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text('${provider.badge!.label} Referrer',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.gold)),
                ])),
            ])),
          ]),
          if (provider.orgVerified) ...[
            const SizedBox(height: 10),
            OrgBadge(company: provider.company),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Stats grid
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            StatBox(label: 'Referrals', value: '${provider.referralsMade}',
              valueColor: AppColors.primary),
            StatBox(label: 'Successful', value: '${provider.successfulReferrals}',
              valueColor: AppColors.emerald),
            StatBox(label: 'Success %', value: '${provider.successRate}%'),
            StatBox(label: 'Thanks', value: '${provider.gratitudesReceived}',
              valueColor: AppColors.accent),
          ]),
          const SizedBox(height: 14),
          TrustScoreBar(provider.computedTrustScore),
          const SizedBox(height: 10),
          ProfileCompletenessBar(provider.profileComplete),
        ])),

        const SizedBox(height: 12),

        // Bio
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('About', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(provider.bio.isEmpty ? 'No bio provided.' : provider.bio,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecond, height: 1.6)),
        ])),

        const SizedBox(height: 12),

        // Skills
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Skills & Expertise', style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6,
            children: provider.skills.map((s) => SkillChip(s)).toList()),
        ])),

        // Active jobs
        if (jobs.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Active Openings (${jobs.length})', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...jobs.map((j) => Padding(padding: const EdgeInsets.only(bottom: 12),
            child: JobCard(job: j))),
        ],

        const SizedBox(height: 80),
      ]),

      bottomNavigationBar: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: prov.isSeeker
                  ? () => _showThanksSheet(context, provider)
                  : null,
              icon: Icon(prov.hasThanked(providerId)
                  ? Icons.favorite : Icons.favorite_outline),
              label: Text(prov.hasThanked(providerId)
                  ? 'Thanked'
                  : 'Send thanks'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => context.push('/messages/$providerId'),
              icon: const Icon(Icons.message_outlined),
              label: Text('Message ${provider.name.split(' ').first}'))),
          ]))),
    );
  }

  void _showThanksSheet(BuildContext context, AppUser referrer) {
    final prov = context.read<AppProvider>();
    if (prov.hasThanked(referrer.id)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('You have already thanked ${referrer.name.split(' ').first}.'),
        behavior: SnackBarBehavior.floating));
      return;
    }
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true,
      builder: (ctx) => _SendThanksSheet(referrer: referrer),
    );
  }
}

class _SendThanksSheet extends StatefulWidget {
  final AppUser referrer;
  const _SendThanksSheet({required this.referrer});
  @override
  State<_SendThanksSheet> createState() => _SendThanksSheetState();
}

class _SendThanksSheetState extends State<_SendThanksSheet> {
  final _msg = TextEditingController(
    text: 'Thank you for your support and the referral.');
  bool _sending = false;
  String? _error;

  @override
  void dispose() { _msg.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20,
      MediaQuery.of(context).viewInsets.bottom + 20),
    child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Icons.favorite_outline,
            size: 18, color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Thank ${widget.referrer.name.split(' ').first}',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          Text('Your note will appear on their profile and the leaderboard.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecond)),
        ])),
      ]),
      const SizedBox(height: 16),
      TextField(controller: _msg, maxLines: 3, maxLength: 240,
        decoration: const InputDecoration(
          labelText: 'Your message',
          hintText: 'Say what they did to help.')),
      if (_error != null) ...[
        const SizedBox(height: 4),
        Text(_error!, style: GoogleFonts.inter(
          fontSize: 12, color: AppColors.red)),
      ],
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('Cancel'))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(
          onPressed: _sending ? null : _send,
          icon: _sending
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.favorite, size: 16),
          label: const Text('Send thanks'))),
      ]),
    ]),
  );

  Future<void> _send() async {
    final text = _msg.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Add a short note before sending.');
      return;
    }
    setState(() { _sending = true; _error = null; });
    final ok = await context.read<AppProvider>().sendGratitude(
      referrerId: widget.referrer.id, message: text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (!ok) {
      setState(() => _error = 'You have already thanked this referrer.');
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Thanks sent to ${widget.referrer.name.split(' ').first}.'),
      backgroundColor: AppColors.emerald,
      behavior: SnackBarBehavior.floating));
  }
}

// ── Notifications ───────────────────────────────────────────────
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<AppProvider>();
    final notifs = prov.notifications;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'),
        actions: [
          if (prov.unreadCount > 0)
            TextButton(onPressed: prov.markAllNotifsRead, child: const Text('Mark all read')),
        ]),
      body: notifs.isEmpty
          ? const EmptyState(icon: Icons.notifications_none_outlined,
              title: 'No notifications yet',
              subtitle: 'Referral updates and application status changes will appear here')
          : ListView.separated(
              padding: const EdgeInsets.all(16), itemCount: notifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final n = notifs[i];
                const icons = {
                  'application': Icons.assignment_outlined,
                  'status':      Icons.notifications_outlined,
                  'message':     Icons.chat_bubble_outline,
                  'referral':    Icons.check_circle_outline,
                  'match':       Icons.gps_fixed,
                };
                final iconData = icons[n.type] ?? Icons.notifications_outlined;
                return GestureDetector(
                  onTap: () {
                    prov.markNotifRead(n.id);
                    if (n.actionRoute != null) context.push(n.actionRoute!);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n.read ? AppColors.surface : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: n.read ? AppColors.border : AppColors.primary.withOpacity(0.3))),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Icon(iconData, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.text, style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: n.read ? FontWeight.w400 : FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(timeago.format(n.createdAt), style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textHint)),
                      ])),
                      if (!n.read) Container(width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle)),
                    ])));
              }),
    );
  }
}

// ── Org Verify Screen ───────────────────────────────────────────
class OrgVerifyScreen extends StatefulWidget {
  const OrgVerifyScreen({super.key});
  @override
  State<OrgVerifyScreen> createState() => _OrgVerifyScreenState();
}

class _OrgVerifyScreenState extends State<OrgVerifyScreen> {
  final _email = TextEditingController();
  final _otp   = TextEditingController();
  bool _otpSent = false, _sending = false, _verifying = false;
  String? _error, _success;

  @override
  void initState() {
    super.initState();
    // Pre-fill the work email from the user's profile if they've already
    // entered an organisation email during onboarding.
    final user = context.read<AppProvider>().currentUser;
    final seed = user?.orgEmail ?? user?.email;
    if (seed != null) _email.text = seed;
  }

  void _exitVerifyLater() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Verify Work Email'),
      actions: [
        if (_success == null)
          TextButton(
            onPressed: _exitVerifyLater,
            child: const Text('Verify later')),
      ]),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.center,
          child: const Icon(Icons.domain_outlined,
            size: 28, color: AppColors.primary)),
        const SizedBox(height: 14),
        Text('Verify your work email', style: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w800)),
        Text('We will send a 6-digit code to your work email and unlock the '
            'Org Verified badge once confirmed.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecond)),
        const SizedBox(height: 24),

        TextField(controller: _email, enabled: !_otpSent,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Work Email',
            hintText: 'yourname@company.com',
            prefixIcon: Icon(Icons.business_outlined))),

        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.red)),
        ],

        const SizedBox(height: 16),

        if (!_otpSent) ElevatedButton(
          onPressed: _sending ? null : _send,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: _sending
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Send Verification Code')),

        if (_otpSent) ...[
          const SizedBox(height: 16),
          TextField(controller: _otp, keyboardType: TextInputType.number, maxLength: 6,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700,
              letterSpacing: 10),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'Verification Code', counterText: '',
              helperText: 'Code sent to ${_email.text}')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _verifying ? null : _verify,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _verifying
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify & Get Badge')),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _sending ? null : _send,
            child: const Text('Resend code')),
        ],

        if (_success != null) ...[
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.emeraldLight, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.verified, color: AppColors.emerald, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(_success!, style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.emerald))),
            ])),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Back to Profile')),
        ],
      ])),
  );

  Future<void> _send() async {
    setState(() { _sending = true; _error = null; });
    final r = await context.read<AppProvider>().sendOrgEmailOtp(_email.text.trim());
    if (!mounted) return;
    setState(() { _sending = false; });
    if (r.success) setState(() => _otpSent = true);
    else setState(() => _error = r.error);
  }

  Future<void> _verify() async {
    setState(() { _verifying = true; _error = null; });
    final r = await context.read<AppProvider>()
        .verifyOrgEmailOtp(_email.text.trim(), _otp.text.trim());
    if (!mounted) return;
    setState(() => _verifying = false);
    if (r.success) setState(() => _success = '${r.companyName ?? "Organisation"} verified. Your profile now shows the Org Verified badge.');
    else setState(() => _error = r.error);
  }
}
