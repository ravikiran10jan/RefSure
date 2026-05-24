// ignore_for_file: require_trailing_commas

import 'package:refsure/core/models/app_user.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/core/models/match_report.dart';
import 'package:refsure/services/firestore_service.dart';
import 'package:refsure/services/match_engine.dart';

class JobsRepository {
  JobsRepository(this._db);
  final FirestoreService _db;

  Stream<List<Job>> watchActiveJobs() => _db.watchActiveJobs();

  Future<String?> postJob(Job job) => _db.postJob(job);

  MatchReport computeMatch({required AppUser seeker, required Job job}) =>
      MatchEngine.compute(seeker: seeker, job: job);

  Future<bool> hasApplied(String jobId, String seekerId) =>
      _db.hasApplied(jobId, seekerId);
}
