// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:refsure/core/models/application.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/core/router/route_names.dart';
import 'package:refsure/design_system/atoms/status_pill.dart';
import 'package:refsure/design_system/molecules/company_logo.dart';
import 'package:refsure/design_system/molecules/match_band_pill.dart';
import 'package:refsure/design_system/molecules/match_score_ring.dart';
import 'package:refsure/design_system/organisms/section_card.dart';
import 'package:refsure/design_system/theme/app_colors.dart';

class ApplicationCard extends StatelessWidget {
  final Application app;
  final Job? job;
  const ApplicationCard({super.key, required this.app, this.job});

  @override
  Widget build(BuildContext context) => SectionCard(
    onTap: job != null ? () => context.push(RouteNames.jobDetailPath(job!.id)) : null,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        if (job != null) ...[
          CompanyLogo(letter: job!.companyLogo, size: 40),
          const SizedBox(width: 12),
        ],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(job?.title ?? 'Unknown Job', style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700)),
          if (job != null)
            Text('${job!.company} \u00B7 ${job!.location}', style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textSecond)),
        ])),
        if (app.matchReport != null)
          MatchScoreRing(app.matchScore, size: 44),
      ]),

      const SizedBox(height: 10),

      Row(children: [
        StatusPill(status: app.statusKey, label: app.statusLabel),
        const Spacer(),
        Text(timeago.format(app.appliedAt), style: GoogleFonts.inter(
          fontSize: 11, color: AppColors.textHint)),
      ]),

      if (app.matchReport != null) ...[
        const SizedBox(height: 8),
        MatchBandPill(band: app.matchReport!.band, label: app.matchReport!.bandLabel),
      ],

      if (app.providerNote != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.format_quote, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(child: Text(app.providerNote!, style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textSecond, fontStyle: FontStyle.italic))),
          ])),
      ],
    ]),
  );
}
