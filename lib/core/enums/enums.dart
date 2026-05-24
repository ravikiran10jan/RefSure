enum UserRole { seeker, provider }

enum OnboardingSource { manual, linkedin, cvUpload }

enum AppStatus {
  pending,
  underReview,
  strongMatch,
  needsReview,
  shortlisted,
  referred,
  interview,
  hired,
  notSelected,
  closed,
}

enum MatchBand { sureShotMatch, excellentMatch, goodToGo, needsReview, lowMatch }

enum ReferralBadgeTier { bronze, silver, gold, diamond, platinum }

enum JobSource { manual, careersPortal }

enum AtsPlatform { greenhouse, lever, bamboohr, workday, unknown }

enum JobSortBy { matchScore, recent, hotFirst }

enum LeaderboardSort { referrals, gratitudes }
