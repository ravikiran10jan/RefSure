// ignore_for_file: require_trailing_commas

import 'package:flutter/material.dart';
import 'package:refsure/core/enums/enums.dart';

/// Single source of truth for colour tokens.
///
/// Palette (Groww-inspired white & green):
/// - Background: near-white page canvas with white card surfaces.
/// - Brand: #00B386 teal-green for primary actions, accents, and badges.
/// - Semantics: status, match-band, and work-mode colours tuned for the palette.
class AppColors {
  // ── Brand ────────────────────────────────────────────────────
  /// Groww teal-green — primary brand colour for buttons, links, accents.
  static const primary      = Color(0xFF00B386);
  /// Hover / pressed state for the primary colour.
  static const primaryDark  = Color(0xFF007A5E);
  /// 8 % tinted surface for selected chips, badges, and subtle highlights.
  static const primaryLight = Color(0xFFE8F7F2);
  /// Secondary accent — darker teal that pairs with the primary.
  static const accent       = Color(0xFF007A5E);
  static const accentLight  = Color(0xFFE8F7F2);

  // ── Surface ──────────────────────────────────────────────────
  /// App canvas — faint green-tinted white so white cards read as elevated.
  static const bg           = Color(0xFFF4FAF8);
  static const surface      = Colors.white;
  static const surfaceHover = Color(0xFFEBF6F1);
  static const border       = Color(0xFFE0F0EB);
  static const divider      = Color(0xFFE0F0EB);

  // ── Text ─────────────────────────────────────────────────────
  static const textPrimary  = Color(0xFF2A2D32);
  static const textSecond   = Color(0xFF5C6B6B);
  static const textHint     = Color(0xFF888888);

  // ── Semantic ─────────────────────────────────────────────────
  /// Confirmed / success — same green family as the brand.
  static const emerald      = Color(0xFF007A5E);
  static const emeraldLight = Color(0xFFE8F7F2);
  /// Pending / warning.
  static const amber        = Color(0xFFC06000);
  static const amberLight   = Color(0xFFFFF3E8);
  /// Informational — blue tone kept distinct from the green brand.
  static const info         = Color(0xFF2255CC);
  static const infoLight    = Color(0xFFE8F0FF);
  /// Alias used by VerifiedBadge and any "blue" semantic context.
  static const blue         = info;
  static const blueLight    = infoLight;
  /// Error / decline.
  static const red          = Color(0xFFE24B4A);
  static const redLight     = Color(0xFFFCEEEE);
  static const purple       = Color(0xFF6D5BD0);
  static const purpleLight  = Color(0xFFEFEBFA);
  static const gold         = Color(0xFFAA7C12);
  static const goldLight    = Color(0xFFFBF3DD);

  // ── Match band colours ───────────────────────────────────────
  static Color matchBg(MatchBand b) => switch (b) {
    MatchBand.sureShotMatch  => emeraldLight,
    MatchBand.excellentMatch => primaryLight,
    MatchBand.goodToGo       => purpleLight,
    MatchBand.needsReview    => amberLight,
    MatchBand.lowMatch       => redLight,
  };

  static Color matchFg(MatchBand b) => switch (b) {
    MatchBand.sureShotMatch  => emerald,
    MatchBand.excellentMatch => primary,
    MatchBand.goodToGo       => purple,
    MatchBand.needsReview    => amber,
    MatchBand.lowMatch       => red,
  };

  // ── Status colours ───────────────────────────────────────────
  static Color statusBg(String s) => switch (s) {
    'pending'      => bg,
    'underReview'  => infoLight,
    'strongMatch'  => emeraldLight,
    'needsReview'  => amberLight,
    'shortlisted'  => primaryLight,
    'referred'     => emeraldLight,
    'interview'    => infoLight,
    'hired'        => emeraldLight,
    'notSelected'  => redLight,
    'closed'       => bg,
    _              => bg,
  };

  static Color statusFg(String s) => switch (s) {
    'pending'      => textHint,
    'underReview'  => info,
    'strongMatch'  => emerald,
    'needsReview'  => amber,
    'shortlisted'  => primary,
    'referred'     => emerald,
    'interview'    => info,
    'hired'        => emerald,
    'notSelected'  => red,
    'closed'       => textHint,
    _              => textHint,
  };

  // ── Work-mode colours ────────────────────────────────────────
  static Color workModeBg(String m) => switch (m) {
    'Remote'  => emeraldLight,
    'Hybrid'  => amberLight,
    'On-site' => primaryLight,
    _         => bg,
  };

  static Color workModeFg(String m) => switch (m) {
    'Remote'  => emerald,
    'Hybrid'  => amber,
    'On-site' => primary,
    _         => textSecond,
  };

  /// Maps a 0–100 match score to a foreground colour.
  static Color matchScoreColor(int score) {
    if (score >= 90) return emerald;
    if (score >= 80) return primary;
    if (score >= 70) return accent;
    if (score >= 60) return amber;
    return red;
  }
}
