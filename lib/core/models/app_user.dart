// ignore_for_file: argument_type_not_assignable, cast_nullable_to_non_nullable, always_put_required_named_parameters_first, sort_constructors_first, require_trailing_commas, avoid_dynamic_calls

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/referral_badge.dart';

class AppUser {
  final String id;
  final UserRole role;
  final String name;
  final String headline;
  final String? company;
  final bool verified;
  final bool orgVerified;
  final String title;
  final String location;
  final int experience;
  final List<String> skills;
  final List<String> preferredRoles;
  final String bio;
  final String? photoUrl;
  final String? email;
  final String? orgEmail;
  final String? linkedinUrl;
  final String? resumeUrl;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final OnboardingSource onboardingSource;

  // Seeker fields
  final String? education;
  final String? currentCompany;
  final String? noticePeriod;
  final String? expectedSalary;
  final bool activelyLooking;
  final int profileComplete;
  final int referralsReceived;

  // Provider fields
  final int referralsMade;
  final int successfulReferrals;
  final int totalJobsPosted;
  final int successRate;
  final String responseTime;
  final int avgResponseHours;
  final double responseRate;
  final double trustScore;
  /// Total "thank you" gratitudes received from seekers.
  final int gratitudesReceived;

  AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.headline,
    this.company,
    this.verified = false,
    this.orgVerified = false,
    required this.title,
    required this.location,
    required this.experience,
    required this.skills,
    this.preferredRoles = const [],
    required this.bio,
    this.photoUrl,
    this.email,
    this.orgEmail,
    this.linkedinUrl,
    this.resumeUrl,
    DateTime? createdAt,
    this.lastActiveAt,
    this.onboardingSource = OnboardingSource.manual,
    this.education,
    this.currentCompany,
    this.noticePeriod,
    this.expectedSalary,
    this.activelyLooking = false,
    this.profileComplete = 30,
    this.referralsReceived = 0,
    this.referralsMade = 0,
    this.successfulReferrals = 0,
    this.totalJobsPosted = 0,
    this.successRate = 0,
    this.responseTime = '< 48h',
    this.avgResponseHours = 48,
    this.responseRate = 1.0,
    this.trustScore = 0.0,
    this.gratitudesReceived = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  ReferralBadge? get badge => ReferralBadge.fromCount(referralsMade);

  bool get isTopProvider => referralsMade >= 10 && successRate >= 70;

  double get computedTrustScore {
    double s = 0;
    if (orgVerified) s += 30;
    if (verified)    s += 20;
    if (profileComplete >= 80) s += 15;
    if (responseRate >= 0.8) s += 10;
    // Referral volume (replaces success rate)
    if (referralsMade >= 5)  s += 5;
    if (referralsMade >= 10) s += 5;
    if (referralsMade >= 20) s += 5;
    if (referralsMade >= 30) s += 5;
    return s.clamp(0, 100);
  }

  Map<String, dynamic> toFirestore() => {
    'id': id, 'role': role.name, 'name': name, 'headline': headline,
    'company': company, 'verified': verified, 'orgVerified': orgVerified,
    'title': title, 'location': location, 'experience': experience,
    'skills': skills, 'preferredRoles': preferredRoles, 'bio': bio,
    'photoUrl': photoUrl, 'email': email, 'orgEmail': orgEmail,
    'linkedinUrl': linkedinUrl, 'resumeUrl': resumeUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    'onboardingSource': onboardingSource.name,
    'education': education, 'currentCompany': currentCompany,
    'noticePeriod': noticePeriod, 'expectedSalary': expectedSalary,
    'activelyLooking': activelyLooking, 'profileComplete': profileComplete,
    'referralsReceived': referralsReceived, 'referralsMade': referralsMade,
    'successfulReferrals': successfulReferrals, 'totalJobsPosted': totalJobsPosted,
    'successRate': successRate, 'responseTime': responseTime,
    'avgResponseHours': avgResponseHours, 'responseRate': responseRate,
    'trustScore': computedTrustScore,
    'gratitudesReceived': gratitudesReceived,
  };

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      role: d['role'] == 'provider' ? UserRole.provider : UserRole.seeker,
      name: d['name'] ?? '',
      headline: d['headline'] ?? '',
      company: d['company'],
      verified: d['verified'] ?? false,
      orgVerified: d['orgVerified'] ?? false,
      title: d['title'] ?? '',
      location: d['location'] ?? '',
      experience: d['experience'] ?? 0,
      skills: List<String>.from(d['skills'] ?? []),
      preferredRoles: List<String>.from(d['preferredRoles'] ?? []),
      bio: d['bio'] ?? '',
      photoUrl: d['photoUrl'],
      email: d['email'],
      orgEmail: d['orgEmail'],
      linkedinUrl: d['linkedinUrl'],
      resumeUrl: d['resumeUrl'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (d['lastActiveAt'] as Timestamp?)?.toDate(),
      onboardingSource: OnboardingSource.values.firstWhere(
        (o) => o.name == (d['onboardingSource'] ?? 'manual'),
        orElse: () => OnboardingSource.manual),
      education: d['education'],
      currentCompany: d['currentCompany'],
      noticePeriod: d['noticePeriod'],
      expectedSalary: d['expectedSalary'],
      activelyLooking: d['activelyLooking'] ?? false,
      profileComplete: d['profileComplete'] ?? 30,
      referralsReceived: d['referralsReceived'] ?? 0,
      referralsMade: d['referralsMade'] ?? 0,
      successfulReferrals: d['successfulReferrals'] ?? 0,
      totalJobsPosted: d['totalJobsPosted'] ?? 0,
      successRate: d['successRate'] ?? 0,
      responseTime: d['responseTime'] ?? '< 48h',
      avgResponseHours: d['avgResponseHours'] ?? 48,
      responseRate: (d['responseRate'] ?? 1.0).toDouble(),
      trustScore: (d['trustScore'] ?? 0.0).toDouble(),
      gratitudesReceived: d['gratitudesReceived'] ?? 0,
    );
  }

  AppUser copyWith({
    UserRole? role,
    String? name, String? bio, String? headline, String? photoUrl,
    bool? activelyLooking, int? profileComplete, List<String>? skills,
    String? noticePeriod, String? expectedSalary, String? orgEmail,
    bool? orgVerified, String? resumeUrl, String? linkedinUrl,
    String? company, String? title, String? location, int? experience,
    List<String>? preferredRoles, String? education,
  }) => AppUser(
    id: id, role: role ?? this.role, name: name ?? this.name,
    headline: headline ?? this.headline,
    company: company ?? this.company, verified: verified,
    orgVerified: orgVerified ?? this.orgVerified, title: title ?? this.title,
    location: location ?? this.location, experience: experience ?? this.experience,
    skills: skills ?? this.skills, preferredRoles: preferredRoles ?? this.preferredRoles,
    bio: bio ?? this.bio, photoUrl: photoUrl ?? this.photoUrl, email: email,
    orgEmail: orgEmail ?? this.orgEmail, linkedinUrl: linkedinUrl ?? this.linkedinUrl,
    resumeUrl: resumeUrl ?? this.resumeUrl, createdAt: createdAt,
    lastActiveAt: DateTime.now(), onboardingSource: onboardingSource,
    education: education ?? this.education, currentCompany: currentCompany,
    noticePeriod: noticePeriod ?? this.noticePeriod,
    expectedSalary: expectedSalary ?? this.expectedSalary,
    activelyLooking: activelyLooking ?? this.activelyLooking,
    profileComplete: profileComplete ?? this.profileComplete,
    referralsReceived: referralsReceived, referralsMade: referralsMade,
    successfulReferrals: successfulReferrals, totalJobsPosted: totalJobsPosted,
    successRate: successRate, responseTime: responseTime,
    avgResponseHours: avgResponseHours, responseRate: responseRate,
  );
}
