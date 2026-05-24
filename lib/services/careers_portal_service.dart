// lib/services/careers_portal_service.dart
// ignore_for_file: require_trailing_commas

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/external_job.dart';

/// Result returned by [CareersPortalService.fetchJobs].
class CareersPortalResult {
  const CareersPortalResult({
    required this.jobs,
    required this.platform,
    required this.companySlug,
    required this.totalFetched,
  });

  /// Jobs passing the active filter (e.g. last-30-days).
  final List<ExternalJob> jobs;

  /// Which ATS platform the data came from.
  final AtsPlatform platform;

  /// The slug that was actually used in the successful API call.
  final String companySlug;

  /// Total raw job count before date-filtering.
  final int totalFetched;
}

/// Intelligently finds and fetches open job listings from a company's
/// careers portal.
///
/// Strategy (tried in order):
///   1. Greenhouse public jobs board API
///   2. Lever public postings API
///   3. BambooHR public careers list API
///   4. Workday jobs API (common URL pattern)
///
/// Each source is tried with several slug variants derived from the
/// company name (e.g. "Goldman Sachs" → "goldman-sachs", "goldmansachs").
class CareersPortalService {
  CareersPortalService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 12);

  // ── Public API ────────────────────────────────────────────────

  /// Fetches open jobs for [companyName].
  ///
  /// When [filterLast30Days] is true (default) only jobs posted/updated
  /// in the last 30 days are returned; the full raw count is still
  /// available via [CareersPortalResult.totalFetched].
  ///
  /// Throws a [CareersPortalException] if no source returns results.
  Future<CareersPortalResult> fetchJobs(
    String companyName, {
    bool filterLast30Days = true,
  }) async {
    final slugs = _buildSlugs(companyName);

    for (final slug in slugs) {
      // Try each ATS for this slug variant
      for (final attempt in [
        () => _tryGreenhouse(slug, companyName),
        () => _tryLever(slug, companyName),
        () => _tryBambooHR(slug, companyName),
        () => _tryWorkday(slug, companyName),
      ]) {
        try {
          final (jobs, platform) = await attempt();
          if (jobs.isNotEmpty) {
            final filtered = filterLast30Days
                ? jobs.where((j) => j.isWithin30Days).toList()
                : jobs;
            return CareersPortalResult(
              jobs: filtered,
              platform: platform,
              companySlug: slug,
              totalFetched: jobs.length,
            );
          }
        } catch (_) {
          // Swallow errors and try the next source
        }
      }
    }

    throw CareersPortalException(
      'No open job listings found for "$companyName". '
      'The company may use a different careers platform, '
      'or the slug could not be detected automatically.',
    );
  }

  void dispose() => _client.close();

  // ── Slug generation ───────────────────────────────────────────

  /// Builds an ordered list of slug candidates from a company name.
  ///
  /// "Goldman Sachs & Co. LLC" → ["goldman-sachs", "goldman-sachs-co",
  ///                               "goldmansachs", "goldman"]
  static List<String> _buildSlugs(String companyName) {
    // Strip common legal suffixes
    final cleaned = companyName
        .toLowerCase()
        .trim()
        .replaceAll(
            RegExp(
              r'\s*(,?\s*inc\.?|,?\s*llc\.?|,?\s*corp\.?|,?\s*corporation'
              r'|,?\s*limited|,?\s*ltd\.?|,?\s*plc\.?|,?\s*co\.?'
              r'|,?\s*group|&\s*co\.?)\s*$',
              caseSensitive: false,
            ),
            '')
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim();

    // Hyphenated slug  e.g. "goldman sachs"
    final hyphen = cleaned.replaceAll(RegExp(r'\s+'), '-');
    // No-separator slug  e.g. "goldmansachs"
    final noSep = cleaned.replaceAll(RegExp(r'\s+'), '');
    // First word only  e.g. "goldman"
    final first = cleaned.split(RegExp(r'\s+')).first;

    // Deduplicate while preserving insertion order
    final seen = <String>{};
    return [hyphen, noSep, first]
        .where((s) => s.isNotEmpty && seen.add(s))
        .toList();
  }

  // ── Greenhouse ────────────────────────────────────────────────

  Future<(List<ExternalJob>, AtsPlatform)> _tryGreenhouse(
    String slug,
    String company,
  ) async {
    final uri = Uri.https(
      'boards-api.greenhouse.io',
      '/v1/boards/$slug/jobs',
      {'content': 'true'},
    );
    final response = await _client.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Greenhouse ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawJobs = (data['jobs'] as List<dynamic>?) ?? [];

    final jobs = rawJobs.map((j) {
      final m = j as Map<String, dynamic>;
      final departments = (m['departments'] as List<dynamic>?) ?? [];
      final offices = (m['offices'] as List<dynamic>?) ?? [];
      return ExternalJob(
        id: m['id'].toString(),
        title: (m['title'] as String?) ?? '',
        company: company,
        department: departments.isNotEmpty
            ? departments.first['name'] as String?
            : null,
        location: offices.isNotEmpty
            ? offices.map((o) => o['name'] as String).join(', ')
            : null,
        description: m['content'] as String?,
        applyUrl: (m['absolute_url'] as String?) ?? '',
        postedAt: DateTime.tryParse(
              (m['updated_at'] as String?) ?? '',
            ) ??
            DateTime.now(),
        source: AtsPlatform.greenhouse,
      );
    }).toList();

    return (jobs, AtsPlatform.greenhouse);
  }

  // ── Lever ─────────────────────────────────────────────────────

  Future<(List<ExternalJob>, AtsPlatform)> _tryLever(
    String slug,
    String company,
  ) async {
    final uri = Uri.https(
      'api.lever.co',
      '/v0/postings/$slug',
      {'mode': 'json'},
    );
    final response = await _client.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Lever ${response.statusCode}');
    }

    final raw = jsonDecode(response.body);
    if (raw is! List) throw Exception('Lever: unexpected response format');

    final jobs = raw.map((j) {
      final m = j as Map<String, dynamic>;
      final cats = (m['categories'] as Map<String, dynamic>?) ?? {};
      final createdMs = m['createdAt'] as int?;
      return ExternalJob(
        id: (m['id'] as String?) ?? '',
        title: (m['text'] as String?) ?? '',
        company: company,
        department: cats['department'] as String?,
        location: cats['location'] as String?,
        workMode: cats['commitment'] as String?,
        description: (m['descriptionPlain'] as String?) ??
            (m['description'] as String?),
        applyUrl: (m['hostedUrl'] as String?) ?? '',
        postedAt: createdMs != null
            ? DateTime.fromMillisecondsSinceEpoch(createdMs)
            : DateTime.now(),
        source: AtsPlatform.lever,
      );
    }).toList();

    return (jobs, AtsPlatform.lever);
  }

  // ── BambooHR ──────────────────────────────────────────────────

  Future<(List<ExternalJob>, AtsPlatform)> _tryBambooHR(
    String slug,
    String company,
  ) async {
    // BambooHR's public careers list endpoint (JSON)
    final uri = Uri.https(
      '$slug.bamboohr.com',
      '/careers/list',
    );
    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('BambooHR ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawJobs = (data['result'] as List<dynamic>?) ?? [];

    final jobs = rawJobs.map((j) {
      final m = j as Map<String, dynamic>;
      final dept = m['department'] as Map<String, dynamic>?;
      final loc = m['location'] as Map<String, dynamic>?;
      return ExternalJob(
        id: m['id'].toString(),
        title: (m['jobOpeningName'] as String?) ?? '',
        company: company,
        department: dept?['name'] as String?,
        location: loc?['name'] as String?,
        applyUrl: 'https://$slug.bamboohr.com/careers/${m['id']}',
        postedAt: DateTime.tryParse(
              (m['datePosted'] as String?) ?? '',
            ) ??
            DateTime.now(),
        source: AtsPlatform.bamboohr,
      );
    }).toList();

    return (jobs, AtsPlatform.bamboohr);
  }

  // ── Workday ───────────────────────────────────────────────────

  Future<(List<ExternalJob>, AtsPlatform)> _tryWorkday(
    String slug,
    String company,
  ) async {
    // Workday uses slug-based subdomain and path; try the most common pattern.
    final slugNoDash = slug.replaceAll('-', '');
    final uri = Uri.https(
      '$slug.wd1.myworkdayjobs.com',
      '/wday/cxs/$slug/${slugNoDash}Jobs/jobs',
    );
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'appliedFacets': <String, dynamic>{},
            'limit': 20,
            'offset': 0,
            'searchText': '',
          }),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Workday ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawJobs = (data['jobPostings'] as List<dynamic>?) ?? [];

    final jobs = rawJobs.map((j) {
      final m = j as Map<String, dynamic>;
      final extPath = m['externalPath'] as String? ?? '';
      // Use extPath as ID when available (stable, unique per job).
      // Fall back to a deterministic hash of title + location.
      final jobId = extPath.isNotEmpty
          ? extPath
          : Object.hash(m['title'] ?? '', m['locationsText'] ?? '').toString();
      return ExternalJob(
        id: jobId,
        title: (m['title'] as String?) ?? '',
        company: company,
        location: m['locationsText'] as String?,
        applyUrl:
            'https://$slug.wd1.myworkdayjobs.com/en-US/${slugNoDash}Jobs/job$extPath',
        postedAt: DateTime.tryParse(
              (m['postedOn'] as String?) ?? '',
            ) ??
            DateTime.now(),
        source: AtsPlatform.workday,
      );
    }).toList();

    return (jobs, AtsPlatform.workday);
  }
}

/// Thrown when [CareersPortalService] cannot find any listings.
class CareersPortalException implements Exception {
  const CareersPortalException(this.message);
  final String message;

  @override
  String toString() => 'CareersPortalException: $message';
}
