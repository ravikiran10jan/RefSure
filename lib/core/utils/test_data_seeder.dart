// ignore_for_file: require_trailing_commas
// lib/core/utils/test_data_seeder.dart
//
// Writes realistic QA seed data into Firestore so every screen in RefSure
// can be exercised without manual data entry.
//
// ─── HOW TO INVOKE ─────────────────────────────────────────────────────────
//   await TestDataSeeder.seed(FirebaseFirestore.instance);
//   // Optionally pass currentUserId to also update the logged-in user's profile:
//   await TestDataSeeder.seed(FirebaseFirestore.instance, currentUserId: uid);
//
// ─── GUARD ─────────────────────────────────────────────────────────────────
//   The method checks for document `_meta/seed_status` before writing.
//   If it already exists the call is a no-op, so it's safe to invoke twice.
// ───────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

class TestDataSeeder {
  TestDataSeeder._();

  // ── Fixed deterministic IDs ──────────────────────────────────────────────
  // Guard lives at _meta/seed_status to avoid polluting any user collection.
  static const _metaCollection = '_meta';
  static const _guardDocId     = 'seed_status';

  static const _providerIds = [
    'seed_provider_001',
    'seed_provider_002',
    'seed_provider_003',
    'seed_provider_004',
    'seed_provider_005',
  ];

  static const _jobIds = [
    'seed_job_001', // Google  – Flutter
    'seed_job_002', // Swiggy  – PM
    'seed_job_003', // Amazon  – Frontend SDE
    'seed_job_004', // Flipkart – Data Eng
    'seed_job_005', // Zepto   – Growth
    'seed_job_006', // Razorpay – UX
  ];

  static const _appIds = [
    'seed_app_google',
    'seed_app_swiggy',
    'seed_app_zepto',
    'seed_app_flipkart',
  ];

  static const _gratitudeIds = [
    'seed_gratitude_001',
    'seed_gratitude_002',
    'seed_gratitude_003',
  ];

  // ── Public entry point ───────────────────────────────────────────────────

  /// Seeds all test data into Firestore.
  ///
  /// [db] is the [FirebaseFirestore] instance to write to.
  /// [currentUserId] is optional — when provided the logged-in user's profile
  /// is updated to the Kiran Narla seeker persona and applications are written
  /// with their UID as [seekerId].
  static Future<void> seed(FirebaseFirestore db, {String? currentUserId}) async {

    // ── Guard: skip if _meta/seed_status already exists ─────────────────
    final guard = await db
        .collection(_metaCollection)
        .doc(_guardDocId)
        .get();
    if (guard.exists) return;

    // ── Batch 1: Provider user-docs + optional current-user update ───────
    final batch1 = db.batch();
    final now = Timestamp.now();

    if (currentUserId != null) {
      // Update the logged-in user to the Kiran Narla seeker persona
      batch1.update(db.collection('users').doc(currentUserId), {
      'name': 'Kiran Narla',
      'headline': 'Senior Flutter Developer · Open to referrals',
      'title': 'Senior Flutter Developer',
      'location': 'Bangalore',
      'experience': 5,
      'skills': ['Flutter', 'Dart', 'Firebase', 'Product Management', 'Figma'],
      'preferredRoles': ['Flutter Developer', 'Product Manager', 'Mobile Lead'],
      'bio': 'Senior Flutter developer with 5 years building consumer apps.',
      'activelyLooking': true,
      'profileComplete': 85,
      'role': 'seeker',
      'noticePeriod': '30 days',
      'expectedSalary': '35',
      'updatedAt': now,
      'lastActiveAt': now,
      });
    }

    // Seed 5 provider docs (ordered by referralsMade: 10, 8, 6, 4, 2)
    final providers = _buildProviders(now);
    for (var i = 0; i < providers.length; i++) {
      batch1.set(
        db.collection('users').doc(_providerIds[i]),
        providers[i],
        SetOptions(merge: false),
      );
    }

    await batch1.commit();

    // ── Batch 2: Jobs ────────────────────────────────────────────────────
    final batch2 = db.batch();
    final jobs = _buildJobs(now);
    for (var i = 0; i < jobs.length; i++) {
      batch2.set(
        db.collection('jobs').doc(_jobIds[i]),
        {...jobs[i], 'id': _jobIds[i]},
        SetOptions(merge: false),
      );
    }
    await batch2.commit();

    // ── Batch 3: 4 Applications (underReview / underReview / pending / hired) ─
    final batch3 = db.batch();
    final seekerId = currentUserId ?? 'seed_seeker_001';
    final apps = _buildApplications(seekerId, now);
    for (var i = 0; i < apps.length; i++) {
      batch3.set(
        db.collection('applications').doc(_appIds[i]),
        {...apps[i], 'id': _appIds[i]},
        SetOptions(merge: false),
      );
    }
    await batch3.commit();

    // ── Batch 4: 3 Gratitudes ────────────────────────────────────────────
    final batch4 = db.batch();
    final gratitudes = _buildGratitudes(seekerId, now);
    for (var i = 0; i < gratitudes.length; i++) {
      batch4.set(
        db.collection('gratitudes').doc(_gratitudeIds[i]),
        {...gratitudes[i], 'id': _gratitudeIds[i]},
        SetOptions(merge: false),
      );
    }
    await batch4.commit();

    // ── Batch 5: 5 Leaderboard entries + guard doc ────────────────────────
    final batch5 = db.batch();
    final leaderboard = _buildLeaderboard(now);
    for (var i = 0; i < leaderboard.length; i++) {
      batch5.set(
        db.collection('leaderboard')
            .doc('lb_entry_\${(i + 1).toString().padLeft(3, '0')}'),
        leaderboard[i],
        SetOptions(merge: false),
      );
    }
    // Write the guard last — a partial failure won't set the guard
    batch5.set(
      db.collection(_metaCollection).doc(_guardDocId),
      {
        'seededAt': now,
        'version': 1,
        'collections': [
          'users', 'jobs', 'applications', 'gratitudes', 'leaderboard'
        ],
      },
    );
    await batch5.commit();
  }

  // ── Builders ─────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _buildProviders(Timestamp now) => [
    {
      'id': _providerIds[0],
      'role': 'provider',
      'name': 'Arjun Mehta',
      'headline': 'Engineering Manager at Google India',
      'company': 'Google',
      'title': 'Engineering Manager',
      'location': 'Bangalore',
      'experience': 10,
      'skills': ['Flutter', 'Dart', 'Firebase', 'System Design', 'Cloud Architecture'],
      'preferredRoles': [],
      'bio': 'EM at Google India with 10 years in distributed systems. '
          'Happy to refer strong Flutter and backend engineers.',
      'verified': true,
      'orgVerified': true,
      'orgEmail': 'arjun.mehta@google.com',
      'email': 'arjun@example.com',
      'photoUrl': null,
      'linkedinUrl': 'https://linkedin.com/in/arjunmehta',
      'resumeUrl': null,
      'activelyLooking': false,
      'profileComplete': 95,
      'referralsReceived': 0,
      'referralsMade': 10,
      'successfulReferrals': 7,
      'totalJobsPosted': 3,
      'successRate': 70,
      'responseTime': '< 24h',
      'avgResponseHours': 20,
      'responseRate': 0.92,
      'trustScore': 88.0,
      'gratitudesReceived': 5,
      'onboardingSource': 'manual',
      'createdAt': now,
      'lastActiveAt': now,
      'updatedAt': now,
    },
    {
      'id': _providerIds[1],
      'role': 'provider',
      'name': 'Priya Sharma',
      'headline': 'Senior Product Manager at Flipkart',
      'company': 'Flipkart',
      'title': 'Senior Product Manager',
      'location': 'Bangalore',
      'experience': 8,
      'skills': ['Product Management', 'Analytics', 'SQL', 'Figma', 'A/B Testing'],
      'preferredRoles': [],
      'bio': 'Senior PM at Flipkart working on growth products. '
          'Passionate about connecting talent with great opportunities.',
      'verified': true,
      'orgVerified': true,
      'orgEmail': 'priya.sharma@flipkart.com',
      'email': 'priya@example.com',
      'photoUrl': null,
      'linkedinUrl': null,
      'resumeUrl': null,
      'activelyLooking': false,
      'profileComplete': 90,
      'referralsReceived': 0,
      'referralsMade': 8,
      'successfulReferrals': 5,
      'totalJobsPosted': 2,
      'successRate': 62,
      'responseTime': '< 48h',
      'avgResponseHours': 36,
      'responseRate': 0.88,
      'trustScore': 82.0,
      'gratitudesReceived': 4,
      'onboardingSource': 'manual',
      'createdAt': now,
      'lastActiveAt': now,
      'updatedAt': now,
    },
    {
      'id': _providerIds[2],
      'role': 'provider',
      'name': 'Rohan Verma',
      'headline': 'Staff Engineer at Swiggy',
      'company': 'Swiggy',
      'title': 'Staff Engineer',
      'location': 'Bangalore',
      'experience': 9,
      'skills': ['Go', 'Python', 'Kafka', 'Kubernetes', 'System Design'],
      'preferredRoles': [],
      'bio': 'Staff Engineer at Swiggy building reliable food delivery infrastructure. '
          'Love mentoring and referring talented engineers.',
      'verified': false,
      'orgVerified': true,
      'orgEmail': 'rohan.verma@swiggy.in',
      'email': 'rohan@example.com',
      'photoUrl': null,
      'linkedinUrl': null,
      'resumeUrl': null,
      'activelyLooking': false,
      'profileComplete': 80,
      'referralsReceived': 0,
      'referralsMade': 6,
      'successfulReferrals': 4,
      'totalJobsPosted': 1,
      'successRate': 66,
      'responseTime': '< 48h',
      'avgResponseHours': 40,
      'responseRate': 0.80,
      'trustScore': 74.0,
      'gratitudesReceived': 3,
      'onboardingSource': 'manual',
      'createdAt': now,
      'lastActiveAt': now,
      'updatedAt': now,
    },
    {
      'id': _providerIds[3],
      'role': 'provider',
      'name': 'Nisha Kapoor',
      'headline': 'Data Engineering Lead at Amazon',
      'company': 'Amazon',
      'title': 'Data Engineering Lead',
      'location': 'Hyderabad',
      'experience': 7,
      'skills': ['Python', 'Spark', 'SQL', 'AWS Redshift', 'dbt'],
      'preferredRoles': [],
      'bio': 'Data Engineering Lead at Amazon India. '
          'Hiring data engineers with strong Python and Spark skills.',
      'verified': false,
      'orgVerified': false,
      'orgEmail': null,
      'email': 'nisha@example.com',
      'photoUrl': null,
      'linkedinUrl': null,
      'resumeUrl': null,
      'activelyLooking': false,
      'profileComplete': 65,
      'referralsReceived': 0,
      'referralsMade': 4,
      'successfulReferrals': 2,
      'totalJobsPosted': 1,
      'successRate': 50,
      'responseTime': '< 72h',
      'avgResponseHours': 60,
      'responseRate': 0.70,
      'trustScore': 55.0,
      'gratitudesReceived': 2,
      'onboardingSource': 'manual',
      'createdAt': now,
      'lastActiveAt': now,
      'updatedAt': now,
    },
    {
      'id': _providerIds[4],
      'role': 'provider',
      'name': 'Vikram Singh',
      'headline': 'UX Design Lead at Razorpay',
      'company': 'Razorpay',
      'title': 'UX Design Lead',
      'location': 'Bangalore',
      'experience': 6,
      'skills': ['Figma', 'UX Research', 'Prototyping', 'Design Systems', 'Framer'],
      'preferredRoles': [],
      'bio': 'UX Design Lead at Razorpay. '
          'Building the next generation of fintech experiences.',
      'verified': false,
      'orgVerified': false,
      'orgEmail': null,
      'email': 'vikram@example.com',
      'photoUrl': null,
      'linkedinUrl': null,
      'resumeUrl': null,
      'activelyLooking': false,
      'profileComplete': 60,
      'referralsReceived': 0,
      'referralsMade': 2,
      'successfulReferrals': 1,
      'totalJobsPosted': 1,
      'successRate': 50,
      'responseTime': '< 72h',
      'avgResponseHours': 72,
      'responseRate': 0.65,
      'trustScore': 42.0,
      'gratitudesReceived': 1,
      'onboardingSource': 'manual',
      'createdAt': now,
      'lastActiveAt': now,
      'updatedAt': now,
    },
  ];

  static List<Map<String, dynamic>> _buildJobs(Timestamp now) {
    final deadline = '2026-08-31';
    return [
      {
        // seed_job_001 — Google Flutter
        'providerId': _providerIds[0],
        'company': 'Google India',
        'companyLogo': 'G',
        'title': 'Senior Flutter Developer',
        'department': 'Mobile Platform',
        'location': 'Bangalore',
        'workMode': 'Remote',
        'minExp': 4,
        'maxExp': 8,
        'salaryMin': 30,
        'salaryMax': 45,
        'skills': ['Flutter', 'Dart', 'Firebase'],
        'preferredSkills': ['Go', 'gRPC', 'Kubernetes'],
        'tags': ['mobile', 'flutter', 'remote', 'hot'],
        'description':
            'Join Google India\'s Mobile Platform team to build next-generation Flutter '
            'apps used by hundreds of millions of users worldwide. You will own critical '
            'features end-to-end, work with world-class engineers, and ship code that '
            'reaches users across Android and iOS. Strong Flutter and Dart skills required; '
            'Firebase experience is a plus.',
        'providerNote': 'Hiring bar is high — best to have open-source Flutter contributions.',
        'status': 'active',
        'applicants': 23,
        'viewCount': 145,
        'deadline': deadline,
        'postedAt': now,
        'jobRefId': 'GGL-FLT-2026',
        'isHot': true,
        'source': 'manual',
        'externalUrl': null,
      },
      {
        // seed_job_002 — Swiggy PM
        'providerId': _providerIds[2],
        'company': 'Swiggy',
        'companyLogo': 'S',
        'title': 'Product Manager',
        'department': 'Consumer Growth',
        'location': 'Bangalore',
        'workMode': 'Hybrid',
        'minExp': 3,
        'maxExp': 6,
        'salaryMin': 25,
        'salaryMax': 35,
        'skills': ['Product Management', 'Figma', 'Analytics'],
        'preferredSkills': ['SQL', 'A/B Testing', 'Growth Hacking'],
        'tags': ['product', 'growth', 'consumer'],
        'description':
            'Drive growth for Swiggy\'s core consumer experience. You will define the '
            'product roadmap for acquisition and retention features, run A/B experiments, '
            'and collaborate with design, data, and engineering to ship impactful features. '
            'Prior experience with consumer-facing products and strong analytical skills required.',
        'providerNote': null,
        'status': 'active',
        'applicants': 18,
        'viewCount': 112,
        'deadline': deadline,
        'postedAt': now,
        'jobRefId': 'SWG-PM-2026',
        'isHot': false,
        'source': 'manual',
        'externalUrl': null,
      },
      {
        // seed_job_003 — Amazon SDE-II Frontend
        'providerId': _providerIds[3],
        'company': 'Amazon',
        'companyLogo': 'A',
        'title': 'SDE-II Frontend',
        'department': 'Prime Video',
        'location': 'Hyderabad',
        'workMode': 'Hybrid',
        'minExp': 3,
        'maxExp': 6,
        'salaryMin': 20,
        'salaryMax': 30,
        'skills': ['React', 'JavaScript', 'TypeScript'],
        'preferredSkills': ['GraphQL', 'Redux', 'Jest'],
        'tags': ['frontend', 'react', 'amazon'],
        'description':
            'Build the Prime Video web experience serving 200M+ subscribers. '
            'You will own critical player UI components, streaming quality dashboards, '
            'and the recommendation carousel. Strong React and TypeScript fundamentals '
            'required. Experience with video streaming tech is a bonus.',
        'providerNote': 'Focus on LP answers in the interview — Leadership Principles matter.',
        'status': 'active',
        'applicants': 41,
        'viewCount': 230,
        'deadline': deadline,
        'postedAt': now,
        'jobRefId': 'AMZ-SDE2-2026',
        'isHot': false,
        'source': 'manual',
        'externalUrl': null,
      },
      {
        // seed_job_004 — Flipkart Data Engineer
        'providerId': _providerIds[1],
        'company': 'Flipkart',
        'companyLogo': 'F',
        'title': 'Data Engineer',
        'department': 'Data Platform',
        'location': 'Bangalore',
        'workMode': 'Hybrid',
        'minExp': 2,
        'maxExp': 5,
        'salaryMin': 18,
        'salaryMax': 25,
        'skills': ['Python', 'Spark', 'SQL'],
        'preferredSkills': ['Kafka', 'dbt', 'Airflow'],
        'tags': ['data', 'backend', 'python'],
        'description':
            'Join Flipkart\'s Data Platform team to build scalable ETL pipelines processing '
            'petabytes of e-commerce data daily. You will own pipeline reliability, design '
            'data models, and enable analytics across business units. Python and Spark expertise '
            'required; Airflow and dbt experience are a strong plus.',
        'providerNote': null,
        'status': 'active',
        'applicants': 29,
        'viewCount': 175,
        'deadline': deadline,
        'postedAt': now,
        'jobRefId': 'FLK-DE-2026',
        'isHot': false,
        'source': 'manual',
        'externalUrl': null,
      },
      {
        // seed_job_005 — Zepto Growth Manager
        'providerId': _providerIds[0],
        'company': 'Zepto',
        'companyLogo': 'Z',
        'title': 'Growth Manager',
        'department': 'Marketing',
        'location': 'Mumbai',
        'workMode': 'On-site',
        'minExp': 2,
        'maxExp': 5,
        'salaryMin': 15,
        'salaryMax': 22,
        'skills': ['Growth', 'Analytics', 'SQL'],
        'preferredSkills': ['Firebase Analytics', 'Clevertap', 'Meta Ads'],
        'tags': ['growth', 'marketing', 'startup', 'urgent'],
        'description':
            'Drive user acquisition and retention for Zepto\'s 10-minute grocery delivery '
            'across 25 cities. You will own paid performance channels, referral programmes, '
            'and reactivation campaigns. Strong analytical mindset and hands-on experience '
            'with growth tools required.',
        'providerNote': null,
        'status': 'active',
        'applicants': 12,
        'viewCount': 89,
        'deadline': deadline,
        'postedAt': now,
        'jobRefId': 'ZPT-GM-2026',
        'isHot': true,
        'source': 'manual',
        'externalUrl': null,
      },
      {
        // seed_job_006 — Razorpay UX Designer
        'providerId': _providerIds[4],
        'company': 'Razorpay',
        'companyLogo': 'R',
        'title': 'UX Designer',
        'department': 'Design',
        'location': 'Bangalore',
        'workMode': 'Hybrid',
        'minExp': 2,
        'maxExp': 5,
        'salaryMin': 12,
        'salaryMax': 18,
        'skills': ['Figma', 'UX Research'],
        'preferredSkills': ['Framer', 'Zeroheight', 'Design Systems'],
        'tags': ['design', 'ux', 'fintech'],
        'description':
            'Shape the design of Razorpay\'s merchant and consumer products used by '
            '8M+ businesses. You will conduct user research, create high-fidelity '
            'prototypes, and maintain the design system. A strong portfolio with end-to-end '
            'case studies is required.',
        'providerNote': null,
        'status': 'active',
        'applicants': 8,
        'viewCount': 64,
        'deadline': deadline,
        'postedAt': now,
        'jobRefId': 'RPY-UX-2026',
        'isHot': false,
        'source': 'manual',
        'externalUrl': null,
      },
    ];
  }

  static List<Map<String, dynamic>> _buildApplications(
      String seekerId, Timestamp now) {
    final fiveDaysAgo = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 5)),
    );
    final threeDaysAgo = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 3)),
    );
    final oneDayAgo = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    return [
      {
        // Google Flutter — underReview (provider has seen it)
        'jobId': _jobIds[0],
        'seekerId': seekerId,
        'providerId': _providerIds[0],
        'status': 'underReview',
        'matchScore': 87,
        'matchReport': {
          'score': 87,
          'band': 'excellentMatch',
          'bandLabel': 'Excellent Match',
          'recommendation':
              'Kiran is an excellent fit for this role. '
              'Flutter, Dart, and Firebase are all strong matches. '
              'The 4-year experience threshold is met with room to grow.',
          'matchedSkills': ['Flutter', 'Dart', 'Firebase'],
          'missingSkills': ['Go', 'gRPC'],
          'strengths': [
              'All three required skills matched',
              'Location match — Bangalore',
              'Experience within required range',
            ],
          'gaps': ['Go / gRPC preferred but not required'],
          'skillScore': 90,
          'experienceScore': 85,
          'locationScore': 100,
          'contextScore': 80,
          'computedAt': now,
        },
        'appliedAt': threeDaysAgo,
        'updatedAt': oneDayAgo,
        'viewedAt': oneDayAgo,
        'providerNote': 'Profile looks strong. Will review CV and follow up.',
        'strongMatchFlag': true,
      },
      {
        // Swiggy PM — underReview (viewed by provider)
        'jobId': _jobIds[1],
        'seekerId': seekerId,
        'providerId': _providerIds[2],
        'status': 'underReview',
        'matchScore': 79,
        'matchReport': {
          'score': 79,
          'band': 'goodToGo',
          'bandLabel': 'Good to Go',
          'recommendation':
              'Kiran\'s product management and Figma skills are directly relevant. '
              'Lacking dedicated analytics tooling experience, but core PM skills '
              'are solid.',
          'matchedSkills': ['Product Management', 'Figma'],
          'missingSkills': ['Analytics', 'SQL'],
          'strengths': [
              'Product Management and Figma are direct matches',
              'Location matches Bangalore HQ',
            ],
          'gaps': [
              'Analytics and SQL listed as required — partial match only',
            ],
          'skillScore': 75,
          'experienceScore': 80,
          'locationScore': 100,
          'contextScore': 70,
          'computedAt': now,
        },
        'appliedAt': fiveDaysAgo,
        'updatedAt': threeDaysAgo,
        'viewedAt': threeDaysAgo,
        'providerNote': null,
        'strongMatchFlag': false,
      },
      {
        // Zepto Growth — pending (just applied, 5 days ago)
        'jobId': _jobIds[4],
        'seekerId': seekerId,
        'providerId': _providerIds[0],
        'status': 'pending',
        'matchScore': 62,
        'matchReport': {
          'score': 62,
          'band': 'needsReview',
          'bandLabel': 'Needs Review',
          'recommendation':
              'Some transferable skills present but Growth and Analytics are '
              'not primary skills on Kiran\'s profile. Worth applying given '
              'the PM background.',
          'matchedSkills': ['Analytics'],
          'missingSkills': ['Growth', 'SQL'],
          'strengths': ['Product mindset transferable to growth roles'],
          'gaps': ['Growth marketing and SQL are required — not in profile'],
          'skillScore': 55,
          'experienceScore': 70,
          'locationScore': 60,
          'contextScore': 65,
          'computedAt': now,
        },
        'appliedAt': fiveDaysAgo,
        'updatedAt': fiveDaysAgo,
        'viewedAt': null,
        'providerNote': null,
        'strongMatchFlag': false,
      },
      {
        // Flipkart Data Eng — hired
        'jobId': _jobIds[3],
        'seekerId': seekerId,
        'providerId': _providerIds[1],
        'status': 'hired',
        'matchScore': 55,
        'matchReport': {
          'score': 55,
          'band': 'needsReview',
          'bandLabel': 'Needs Review',
          'recommendation':
              'Firebase experience overlaps with data engineering concepts, '
              'but Python, Spark, and SQL are not core Kiran skills. '
              'Considered based on referrer relationship.',
          'matchedSkills': ['Firebase'],
          'missingSkills': ['Python', 'Spark', 'SQL'],
          'strengths': ['Firebase familiarity helps with data pipeline concepts'],
          'gaps': [
              'Python required — not in profile',
              'Spark and SQL are core requirements',
            ],
          'skillScore': 45,
          'experienceScore': 65,
          'locationScore': 100,
          'contextScore': 60,
          'computedAt': now,
        },
        'appliedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 14)),
        ),
        'updatedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 2)),
        ),
        'viewedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 10)),
        ),
        'providerNote': 'Referred internally — strong cultural fit.',
        'strongMatchFlag': false,
      },
    ];
  }

  static List<Map<String, dynamic>> _buildGratitudes(
      String fromSeekerId, Timestamp now) {
    return [
      {
        'fromSeekerId': fromSeekerId,
        'fromSeekerName': 'Kiran Narla',
        'toReferrerId': _providerIds[0],
        'message':
            'Thank you so much, Arjun! Your referral to Google was a game-changer. '
            'I got the interview and the process has been amazing so far.',
        'createdAt': now,
      },
      {
        'fromSeekerId': fromSeekerId,
        'fromSeekerName': 'Kiran Narla',
        'toReferrerId': _providerIds[1],
        'message':
            'Priya, I really appreciate you taking the time to forward my profile at Flipkart. '
            'The hiring team was super responsive. Thank you!',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 3)),
        ),
      },
      {
        'fromSeekerId': fromSeekerId,
        'fromSeekerName': 'Kiran Narla',
        'toReferrerId': _providerIds[2],
        'message':
            'Rohan, your note to the Swiggy hiring manager opened doors I did not expect. '
            'Genuinely grateful for your support!',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 7)),
        ),
      },
    ];
  }

  static List<Map<String, dynamic>> _buildLeaderboard(Timestamp now) => [
    {
      'rank': 1,
      'userId': _providerIds[0],
      'name': 'Arjun Mehta',
      'company': 'Google',
      'title': 'Engineering Manager',
      'referralsMade': 10,
      'successfulReferrals': 7,
      'successRate': 70,
      'trustScore': 88.0,
      'period': 'allTime',
      'updatedAt': now,
    },
    {
      'rank': 2,
      'userId': _providerIds[1],
      'name': 'Priya Sharma',
      'company': 'Flipkart',
      'title': 'Senior Product Manager',
      'referralsMade': 8,
      'successfulReferrals': 5,
      'successRate': 62,
      'trustScore': 82.0,
      'period': 'allTime',
      'updatedAt': now,
    },
    {
      'rank': 3,
      'userId': _providerIds[2],
      'name': 'Rohan Verma',
      'company': 'Swiggy',
      'title': 'Staff Engineer',
      'referralsMade': 6,
      'successfulReferrals': 4,
      'successRate': 66,
      'trustScore': 74.0,
      'period': 'allTime',
      'updatedAt': now,
    },
    {
      'rank': 4,
      'userId': _providerIds[3],
      'name': 'Nisha Kapoor',
      'company': 'Amazon',
      'title': 'Data Engineering Lead',
      'referralsMade': 4,
      'successfulReferrals': 2,
      'successRate': 50,
      'trustScore': 55.0,
      'period': 'allTime',
      'updatedAt': now,
    },
    {
      'rank': 5,
      'userId': _providerIds[4],
      'name': 'Vikram Singh',
      'company': 'Razorpay',
      'title': 'UX Design Lead',
      'referralsMade': 2,
      'successfulReferrals': 1,
      'successRate': 50,
      'trustScore': 42.0,
      'period': 'allTime',
      'updatedAt': now,
    },
  ];
}
