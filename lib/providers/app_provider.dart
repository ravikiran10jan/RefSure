// lib/providers/app_provider.dart — v2.0 FIXED
// ignore_for_file: argument_type_not_assignable, require_trailing_commas
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/test_data_seeder.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/match_engine.dart';
import '../services/otp_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService      _auth    = AuthService();
  final FirestoreService _db      = FirestoreService();
  final StorageService   _storage = StorageService();
  final OtpService       _otp     = OtpService();

  AppUser?   _currentUser;
  bool       _authReady  = false;
  bool       _loading    = false;
  String?    _error;
  UserRole   _activeRole = UserRole.seeker;

  List<AppUser>         _providers    = [];
  List<AppUser>         _seekers      = [];
  List<Job>             _jobs         = [];
  List<Application>     _myApps       = [];
  List<Application>     _providerApps = [];
  List<AppNotification> _notifs       = [];
  List<Gratitude>       _gratitudes   = [];
  JobFilter             _jobFilter    = const JobFilter();

  final List<StreamSubscription> _subs = [];

  AppUser?  get currentUser  => _currentUser;
  bool      get authReady    => _authReady;
  bool      get loading      => _loading;
  String?   get error        => _error;
  bool      get isLoggedIn   => _currentUser != null;
  bool      get isSeeker     => _activeRole == UserRole.seeker;
  bool      get isProvider   => _activeRole == UserRole.provider;
  UserRole  get activeRole   => _activeRole;
  JobFilter get jobFilter    => _jobFilter;

  /// True when the Firebase user is anonymous (guest / not properly
  /// authenticated). Real email/password or Google users are not guests.
  bool get isGuest =>
      _auth.currentFirebaseUser?.isAnonymous ?? true;

  List<AppUser>         get providers           => _providers;
  List<AppUser>         get seekers             => _seekers;
  List<Job>             get allJobs             => _jobs;
  List<Application>     get myApplications      => _myApps;
  List<Application>     get providerApplications => _providerApps;
  List<AppNotification> get notifications       => _notifs;
  int                   get unreadCount         => _notifs.where((n) => !n.read).length;
  List<Gratitude>       get gratitudes          => _gratitudes;

  List<Job> get activeJobs => _jobs.where((j) => j.status == 'active').toList();

  /// Aggregated counts for the seeker dashboard.
  ///
  /// `total` is every application the seeker has sent. The other buckets
  /// partition that total by lifecycle stage:
  ///   - pending:   awaiting initial action (pending / underReview)
  ///   - open:      moving forward (strongMatch, shortlisted, referred, interview)
  ///   - completed: finalised (hired / notSelected / closed)
  SeekerMetrics get seekerMetrics {
    final apps = _myApps;
    int pending = 0, open = 0, completed = 0;
    for (final a in apps) {
      switch (a.status) {
        case AppStatus.pending:
        case AppStatus.underReview:
        case AppStatus.needsReview:
          pending++;
        case AppStatus.strongMatch:
        case AppStatus.shortlisted:
        case AppStatus.referred:
        case AppStatus.interview:
          open++;
        case AppStatus.hired:
        case AppStatus.notSelected:
        case AppStatus.closed:
          completed++;
      }
    }
    return SeekerMetrics(
      total: apps.length,
      pending: pending,
      open: open,
      completed: completed,
    );
  }

  List<Job> get filteredJobs {
    var jobs = activeJobs;
    final f = _jobFilter;

    if (f.query.isNotEmpty) {
      final q = f.query.toLowerCase();
      jobs = jobs.where((j) =>
        j.title.toLowerCase().contains(q) ||
        j.company.toLowerCase().contains(q) ||
        j.skills.any((s) => s.toLowerCase().contains(q)) ||
        j.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }
    if (f.workMode != null) {
      jobs = jobs.where((j) => j.workMode == f.workMode).toList();
    }
    if (f.location != null) {
      jobs = jobs.where((j) =>
        j.location.toLowerCase().contains(f.location!.toLowerCase()) ||
        j.workMode == 'Remote').toList();
    }
    if (f.hotOnly)    jobs = jobs.where((j) => j.isHot).toList();
    if (f.todayOnly) {
      final today = DateTime.now();
      jobs = jobs.where((j) =>
        j.postedAt.year == today.year &&
        j.postedAt.month == today.month &&
        j.postedAt.day == today.day).toList();
    }
    if (f.last10Days) {
      final cutoff = DateTime.now().subtract(const Duration(days: 10));
      jobs = jobs.where((j) => j.postedAt.isAfter(cutoff)).toList();
    }
    if (f.minExp != null) jobs = jobs.where((j) => j.maxExp >= f.minExp!).toList();
    if (f.maxExp != null) jobs = jobs.where((j) => j.minExp <= f.maxExp!).toList();
    if (f.tags.isNotEmpty) {
      jobs = jobs.where((j) => f.tags.any((t) => j.tags.contains(t))).toList();
    }

    switch (f.sortBy) {
      case JobSortBy.matchScore:
        if (_currentUser != null) {
          final user = _currentUser!;
          jobs.sort((a, b) =>
            MatchEngine.compute(seeker: user, job: b).score
            .compareTo(MatchEngine.compute(seeker: user, job: a).score));
        }
      case JobSortBy.recent:
        jobs.sort((a, b) => b.postedAt.compareTo(a.postedAt));
      case JobSortBy.hotFirst:
        jobs.sort((a, b) {
          if (a.isHot && !b.isHot) return -1;
          if (!a.isHot && b.isHot) return 1;
          return b.postedAt.compareTo(a.postedAt);
        });
    }
    return jobs;
  }

  AppProvider() { _init(); }


  void _init() {
    _subs.add(_auth.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        // Auto anonymous sign-in for demo / dev mode
        final anon = await _auth.signInAnonymously();
        if (!anon.success) {
          _currentUser = null;
          _authReady = true;
          notifyListeners();
        }
        return;
      }

      // Ensure user doc exists (for anonymous or new users)
      final existing = await _db.getUser(firebaseUser.uid);
      if (existing == null) {
        final dummyUser = AppUser(
          id: firebaseUser.uid,
          role: UserRole.seeker,
          name: 'Demo Seeker',
          headline: 'Job Seeker at RefSure',
          title: 'Software Engineer',
          location: 'Bangalore',
          experience: 3,
          skills: const ['Flutter', 'Dart', 'Firebase'],
          bio: 'Demo profile for testing RefSure.',
          email: firebaseUser.email ?? 'demo@refsure.com',
          profileComplete: 50,
        );
        await _db.saveUser(dummyUser);
      }

      await _loadUserData(firebaseUser.uid);
    }));
  }

  Future<void> _loadUserData(String uid) async {
    _authReady = true;
    _loading = true;
    notifyListeners();
    try {
      _subs.add(_db.watchUser(uid).listen((appUser) {
        if (appUser != null) {
          _currentUser = appUser;
          _activeRole  = appUser.role;
          notifyListeners();
        }
      }));
      _subs.add(_db.watchProviders().listen((list) {
        _providers = list;
        notifyListeners();
      }));
      _subs.add(_db.watchActiveJobs().listen((list) {
        _jobs = list;
        notifyListeners();
      }));
      _subs.add(_db.watchNotifications(uid).listen((list) {
        _notifs = list;
        notifyListeners();
      }));
      _subs.add(_db.watchAllGratitudes().listen((list) {
        _gratitudes = list;
        notifyListeners();
      }));

      final user = await _db.getUser(uid);
      if (user != null) {
        _activeRole = user.role;
        if (user.role == UserRole.seeker) {
          _subs.add(_db.watchSeekerApplications(uid).listen((list) {
            _myApps = list;
            notifyListeners();
          }));
        } else {
          _subs.add(_db.watchProviderApplications(uid).listen((list) {
            _providerApps = list;
            notifyListeners();
          }));
          _subs.add(_db.watchSeekers().listen((list) {
            _seekers = list;
            notifyListeners();
          }));
        }
      }
      // Always stop loading after setup, even if user doc missing
      _loading = false;
      notifyListeners();
      // Seed jobs if none exist
      _db.seedSampleJobs();
      // Auto-seed full test dataset (idempotent — safe to run every launch)
      unawaited(TestDataSeeder.seed(
        FirebaseFirestore.instance,
        currentUserId: uid,
      ).catchError((_) {}));
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final s in _subs) { s.cancel(); }
    super.dispose();
  }

  // ── Auth ────────────────────────────────────────────────────

  Future<AuthResult> signUp({
    required String email, required String password,
    required String name, required UserRole role,
  }) async {
    _loading = true; notifyListeners();
    final r = await _auth.signUpWithEmail(email: email, password: password, name: name, role: role);
    _loading = false; notifyListeners();
    return r;
  }

  Future<AuthResult> signIn({
    required String email, required String password,
  }) async {
    _loading = true; notifyListeners();
    final r = await _auth.signInWithEmail(email: email, password: password);
    _loading = false; notifyListeners();
    return r;
  }

  Future<AuthResult> signInWithGoogle({UserRole role = UserRole.seeker}) async {
    _loading = true; notifyListeners();
    final r = await _auth.signInWithGoogle(role: role);
    _loading = false; notifyListeners();
    return r;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ── Profile ─────────────────────────────────────────────────

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return;
    await _db.updateUser(_currentUser!.id, data);
  }

  /// Switches the user between Job Seeker and Referrer. Persists the new role
  /// to Firestore and rebuilds the role-scoped subscriptions so the rest of
  /// the app sees the right data immediately.
  Future<void> setActiveRole(UserRole role) async {
    if (_currentUser == null || _activeRole == role) return;
    _activeRole = role;
    notifyListeners();
    await _db.updateUser(_currentUser!.id, {'role': role.name});
    // Tear down role-scoped streams and rebuild for the new role.
    for (final s in _subs) { unawaited(s.cancel()); }
    _subs.clear();
    _myApps = [];
    _providerApps = [];
    _gratitudes = [];
    await _loadUserData(_currentUser!.id);
  }

  Future<String?> uploadResume() async {
    if (_currentUser == null) return null;
    final url = await _storage.uploadResumeFile(_currentUser!.id);
    if (url != null) await updateProfile({'resumeUrl': url});
    return url;
  }

  // ── Gratitudes ──────────────────────────────────────────────

  /// Whether the current seeker has already thanked [referrerId].
  bool hasThanked(String referrerId) =>
      _gratitudes.any((g) =>
        g.fromSeekerId == _currentUser?.id && g.toReferrerId == referrerId);

  /// Sends a "thank you" from the current seeker to [referrer]. The Firestore
  /// service writes the gratitude document and bumps the referrer's counter
  /// in a single batch.
  Future<bool> sendGratitude({
    required String referrerId, required String message,
  }) async {
    final me = _currentUser;
    if (me == null) return false;
    if (await _db.hasThanked(me.id, referrerId)) return false;
    await _db.addGratitude(Gratitude(
      id: '',
      fromSeekerId: me.id,
      fromSeekerName: me.name,
      toReferrerId: referrerId,
      message: message,
    ));
    return true;
  }

  /// Top referrers ordered by [LeaderboardSort]. Pulls from the in-memory
  /// `_providers` list so the home leaderboard updates live with the rest of
  /// the app.
  List<AppUser> leaderboard(LeaderboardSort sort, {int limit = 5}) {
    final list = [..._providers];
    list.sort((a, b) => switch (sort) {
      LeaderboardSort.referrals  => b.referralsMade.compareTo(a.referralsMade),
      LeaderboardSort.gratitudes => b.gratitudesReceived.compareTo(a.gratitudesReceived),
    });
    return list.take(limit).toList();
  }

  // ── OTP ─────────────────────────────────────────────────────

  Future<OtpSendResult> sendOrgEmailOtp(String email) async {
    if (_currentUser == null) {
      return OtpSendResult(success: false, error: 'Not logged in');
    }
    return _otp.sendOtp(userId: _currentUser!.id, email: email);
  }

  Future<OtpVerifyResult> verifyOrgEmailOtp(String email, String code) async {
    if (_currentUser == null) {
      return OtpVerifyResult(success: false, error: 'Not logged in');
    }
    final result = await _otp.verifyOtp(
      userId: _currentUser!.id, email: email, enteredOtp: code);
    if (result.success && result.companyName != null) {
      await _db.markOrgVerified(_currentUser!.id, email, result.companyName!);
    }
    return result;
  }

  bool isOrgEmail(String email) => _otp.isOrgEmail(email);

  // ── Filters ──────────────────────────────────────────────────

  void updateJobFilter(JobFilter filter) {
    _jobFilter = filter;
    notifyListeners();
  }

  /// Sets the work-mode filter. Pass `null` to clear it. Needed because
  /// JobFilter.copyWith uses `??` semantics that can't distinguish between
  /// "leave alone" and "clear to null".
  void setJobWorkMode(String? mode) {
    _jobFilter = JobFilter(
      query: _jobFilter.query, workMode: mode, location: _jobFilter.location,
      hotOnly: _jobFilter.hotOnly, todayOnly: _jobFilter.todayOnly,
      last10Days: _jobFilter.last10Days,
      minExp: _jobFilter.minExp, maxExp: _jobFilter.maxExp,
      tags: _jobFilter.tags, sortBy: _jobFilter.sortBy);
    notifyListeners();
  }

  void clearJobFilter() {
    _jobFilter = const JobFilter();
    notifyListeners();
  }

  // ── Jobs ─────────────────────────────────────────────────────

  Future<String?> postJob(Map<String, dynamic> data) async {
    if (_currentUser == null) return null;
    final job = Job(
      id: '',
      providerId: _currentUser!.id,
      company: _currentUser!.company ?? data['company'] ?? 'My Company',
      companyLogo: (_currentUser!.company ?? data['company'] ?? 'C')[0].toUpperCase(),
      title:       data['title'] ?? '',
      department:  data['department'] ?? 'Engineering',
      location:    data['location'] ?? '',
      workMode:    data['workMode'] ?? 'Hybrid',
      minExp:      data['minExp'] ?? 0,
      maxExp:      data['maxExp'] ?? 10,
      salaryMin:   data['salaryMin'] ?? 0,
      salaryMax:   data['salaryMax'] ?? 0,
      skills:      List<String>.from(data['skills'] ?? []),
      preferredSkills: List<String>.from(data['preferredSkills'] ?? []),
      tags:        List<String>.from(data['tags'] ?? []),
      description: data['description'] ?? '',
      providerNote: data['providerNote'],
      deadline:    data['deadline'] ?? '2026-12-31',
      jobRefId:    '',
      isHot:       data['isHot'] ?? false,
      externalUrl: data['externalUrl'],
    );
    return await _db.postJob(job);
  }

  // ── Applications ─────────────────────────────────────────────

  Future<dynamic> applyToJob(Job job) async {
    if (_currentUser == null) return 'error';
    final already = await _db.hasApplied(job.id, _currentUser!.id);
    if (already) return 'already';

    final report = MatchEngine.compute(seeker: _currentUser!, job: job);
    if (report.score < 40) return 'low_match';

    final initStatus = report.score >= 80 ? AppStatus.strongMatch : AppStatus.pending;

    final app = Application(
      id: '', jobId: job.id, seekerId: _currentUser!.id,
      providerId: job.providerId, matchScore: report.score,
      matchReport: report, status: initStatus,
      strongMatchFlag: report.score >= 80,
    );
    await _db.submitApplication(app);

    await _db.createNotification(AppNotification(
      id: '', userId: job.providerId, type: 'application',
      text: '${_currentUser!.name} applied to ${job.title} — ${report.bandLabel}',
      actionRoute: '/jobs/${job.id}',
    ));
    return true;
  }

  Future<void> updateApplicationStatus(
    String appId, AppStatus status, {String? note}) async {
    await _db.updateApplicationStatus(appId, status, note: note);

    Application? app;
    try {
      app = _providerApps.firstWhere((a) => a.id == appId);
    } catch (_) { return; }

    final job = findJob(app.jobId);
    final statusTexts = {
      AppStatus.shortlisted: 'was shortlisted',
      AppStatus.referred:    'has been referred',
      AppStatus.interview:   'has been scheduled for interview',
      AppStatus.hired:       'has been hired',
      AppStatus.notSelected: 'was not selected this time',
      AppStatus.closed:      'position has been closed',
    };
    if (statusTexts.containsKey(status)) {
      await _db.createNotification(AppNotification(
        id: '', userId: app.seekerId, type: 'status',
        text: 'Your application for ${job?.title ?? "a job"} ${statusTexts[status]}.',
        actionRoute: '/applications',
      ));
    }
  }

  // ── Match ─────────────────────────────────────────────────────

  MatchReport computeMatch(Job job) {
    if (_currentUser == null) {
      return MatchReport(
        score: 0, band: MatchBand.lowMatch, bandLabel: 'Low Match',
        recommendation: 'Sign in to see your match.',
        matchedSkills: [], missingSkills: job.skills,
        strengths: [], gaps: [],
        skillScore: 0, experienceScore: 0, locationScore: 0, contextScore: 0);
    }
    return MatchEngine.compute(seeker: _currentUser!, job: job);
  }

  MatchReport computeMatchForSeeker(AppUser seeker, Job job) =>
      MatchEngine.compute(seeker: seeker, job: job);

  // ── Messaging ────────────────────────────────────────────────

  Stream<List<Message>> watchConversation(String otherId) {
    if (_currentUser == null) return Stream.value([]);
    return _db.watchConversation(_currentUser!.id, otherId);
  }

  Future<void> sendMessage(String toId, String text) async {
    if (_currentUser == null) return;
    await _db.sendMessage(
      Message(id: '', fromId: _currentUser!.id, toId: toId, text: text));
  }

  // ── Notifications ────────────────────────────────────────────

  Future<void> markAllNotifsRead() async {
    if (_currentUser == null) return;
    await _db.markAllNotifsRead(_currentUser!.id);
  }

  Future<void> markNotifRead(String id) => _db.markNotifRead(id);

  // ── Helpers ──────────────────────────────────────────────────

  AppUser? findUser(String id) {
    try { return [..._providers, ..._seekers].firstWhere((u) => u.id == id); }
    catch (_) { return null; }
  }

  Job? findJob(String id) {
    try { return _jobs.firstWhere((j) => j.id == id); }
    catch (_) { return null; }
  }
}

// ── JobFilter ─────────────────────────────────────────────────

class JobFilter {
  final String  query;
  final String? workMode;
  final String? location;
  final bool    hotOnly;
  final bool    todayOnly;
  final bool    last10Days;
  final int?    minExp;
  final int?    maxExp;
  final List<String> tags;
  final JobSortBy sortBy;

  const JobFilter({
    this.query = '',
    this.workMode,
    this.location,
    this.hotOnly    = false,
    this.todayOnly  = false,
    this.last10Days = false,
    this.minExp,
    this.maxExp,
    this.tags   = const [],
    this.sortBy = JobSortBy.matchScore,
  });

  JobFilter copyWith({
    String? query, String? workMode, String? location,
    bool? hotOnly, bool? todayOnly, bool? last10Days,
    int? minExp, int? maxExp, List<String>? tags, JobSortBy? sortBy,
  }) => JobFilter(
    query:      query      ?? this.query,
    workMode:   workMode   ?? this.workMode,
    location:   location   ?? this.location,
    hotOnly:    hotOnly    ?? this.hotOnly,
    todayOnly:  todayOnly  ?? this.todayOnly,
    last10Days: last10Days ?? this.last10Days,
    minExp:     minExp     ?? this.minExp,
    maxExp:     maxExp     ?? this.maxExp,
    tags:       tags       ?? this.tags,
    sortBy:     sortBy     ?? this.sortBy,
  );

  bool get isActive =>
      query.isNotEmpty || workMode != null || location != null ||
      hotOnly || todayOnly || last10Days ||
      minExp != null || maxExp != null || tags.isNotEmpty;

  int get activeCount {
    int n = 0;
    if (query.isNotEmpty) n++;
    if (workMode != null) n++;
    if (location != null) n++;
    if (hotOnly)  n++;
    if (todayOnly || last10Days) n++;
    if (minExp != null || maxExp != null) n++;
    n += tags.length;
    return n;
  }
}

/// Seeker dashboard counts — see [AppProvider.seekerMetrics].
class SeekerMetrics {
  final int total;
  final int pending;
  final int open;
  final int completed;
  const SeekerMetrics({
    required this.total,
    required this.pending,
    required this.open,
    required this.completed,
  });
}
