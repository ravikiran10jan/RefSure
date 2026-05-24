// lib/features/careers_portal/data/careers_portal_repository.dart
// ignore_for_file: require_trailing_commas

import 'package:refsure/core/models/external_job.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/features/jobs/data/jobs_repository.dart';
import 'package:refsure/services/careers_portal_service.dart';
import 'package:uuid/uuid.dart';

class CareersPortalRepository {
  CareersPortalRepository(this._service, this._jobsRepository);

  final CareersPortalService _service;
  final JobsRepository _jobsRepository;

  /// Fetches open jobs for [companyName] from the best-matching ATS.
  Future<CareersPortalResult> fetchJobs(
    String companyName, {
    bool filterLast30Days = true,
  }) =>
      _service.fetchJobs(companyName, filterLast30Days: filterLast30Days);

  /// Imports an [ExternalJob] into RefSure as a proper [Job] posting.
  ///
  /// [providerId] is the uid of the referrer/provider performing the import.
  Future<String?> importJob(ExternalJob ext, String providerId) {
    final job = Job(
      id: '',
      providerId: providerId,
      company: ext.company,
      companyLogo: ext.company.isNotEmpty
          ? ext.company[0].toUpperCase()
          : '?',
      title: ext.title,
      department: ext.department ?? 'General',
      location: ext.location ?? 'Not specified',
      workMode: ext.workMode ?? 'Hybrid',
      minExp: 0,
      maxExp: 10,
      skills: const [],
      description: _stripHtml(ext.description ?? ''),
      deadline: '',
      postedAt: ext.postedAt,
      jobRefId: const Uuid().v4().substring(0, 8).toUpperCase(),
      source: JobSource.careersPortal,
      externalUrl: ext.applyUrl,
    );
    return _jobsRepository.postJob(job);
  }

  /// Very lightweight HTML-to-text strip for job descriptions fetched
  /// from Greenhouse (which returns raw HTML).
  static String _stripHtml(String html) =>
      html
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();
}
