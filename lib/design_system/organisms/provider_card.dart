// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:refsure/core/models/app_user.dart';
import 'package:refsure/core/router/route_names.dart';
import 'package:refsure/core/models/referral_badge.dart';
import 'package:refsure/design_system/atoms/org_badge.dart';
import 'package:refsure/design_system/atoms/skill_chip.dart';
import 'package:refsure/design_system/atoms/user_avatar.dart';
import 'package:refsure/design_system/atoms/verified_badge.dart';
import 'package:refsure/design_system/molecules/trust_score_bar.dart';
import 'package:refsure/design_system/organisms/section_card.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class ProviderCard extends StatelessWidget {
  final AppUser provider;
  const ProviderCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) => SectionCard(
    onTap: () => context.push(RouteNames.providerDetailPath(provider.id)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        UserAvatar(name: provider.name, photoUrl: provider.photoUrl, size: 48),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(provider.name, style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (provider.verified) ...[const SizedBox(width: 6), const VerifiedBadge()],
          ]),
          Text(provider.title, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecond),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          if (provider.company != null)
            Text(provider.company!, style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
        ])),
        if (provider.badge != null) _BadgePill(provider.badge!),
      ]),

      // Org verified
      if (provider.orgVerified) ...[
        const SizedBox(height: 8),
        OrgBadge(company: provider.company),
      ],

      const SizedBox(height: 10),
      if (provider.bio.isNotEmpty)
        Text(provider.bio, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecond),
          maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 10),

      Wrap(spacing: 6, runSpacing: 4, children: [
        ...provider.skills.take(3).map((s) => SkillChip(s, compact: true)),
        if (provider.skills.length > 3) Text('+${provider.skills.length - 3}',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textHint)),
      ]),

      const SizedBox(height: 10),
      TrustScoreBar(provider.computedTrustScore),
      const SizedBox(height: 10),
      const Divider(height: 1),
      const SizedBox(height: 8),

      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _StatItem(Icons.handshake_outlined, '${provider.referralsMade}', 'Referrals'),
        _StatItem(Icons.gps_fixed, '${provider.successRate}%', 'Success'),
        _StatItem(Icons.bolt_outlined, provider.responseTime, 'Response'),
        _StatItem(Icons.work_outline, '${provider.totalJobsPosted}', 'Jobs'),
      ]),
    ]),
  );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatItem(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.textSecond),
      const SizedBox(width: 4),
      Text(value, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ]),
    Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textHint)),
  ]);
}

class _BadgePill extends StatelessWidget {
  final ReferralBadge badge;
  const _BadgePill(this.badge);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.goldLight, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.workspace_premium_outlined,
        size: 12, color: AppColors.gold),
      const SizedBox(width: 4),
      Text(badge.label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gold)),
    ]));
}
