// lib/core/models/external_job.dart
// ignore_for_file: sort_constructors_first

import 'package:refsure/core/enums/enums.dart';

/// A job listing fetched from an external careers portal or ATS.
/// Distinct from [Job] (which lives in Firestore). ExternalJobs are
/// transient — they are fetched on demand and can optionally be
/// imported into RefSure as a [Job].
class ExternalJob {
  ExternalJob({
    required this.id,
    required this.title,
    required this.company,
    this.department,
    this.location,
    this.workMode,
    this.description,
    required this.applyUrl,
    required this.postedAt,
    required this.source,
  });

  final String id;
  final String title;
  final String company;
  final String? department;
  final String? location;
  final String? workMode;
  final String? description;
  final String applyUrl;
  final DateTime postedAt;
  final AtsPlatform source;

  /// True when the job was posted within the last 30 days.
  bool get isWithin30Days =>
      DateTime.now().difference(postedAt).inDays <= 30;

  /// True when the job was posted within the last 24 hours.
  bool get isNew => DateTime.now().difference(postedAt).inDays <= 1;

  /// Human-readable platform name for display.
  String get sourceName => switch (source) {
    AtsPlatform.greenhouse => 'Greenhouse',
    AtsPlatform.lever      => 'Lever',
    AtsPlatform.bamboohr   => 'BambooHR',
    AtsPlatform.workday    => 'Workday',
    AtsPlatform.unknown    => 'Careers Portal',
  };

  @override
  String toString() => 'ExternalJob($id, $title, $company, $source)';
}
