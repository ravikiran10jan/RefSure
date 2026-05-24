// lib/features/careers_portal/presentation/cubit/careers_portal_state.dart

import 'package:equatable/equatable.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/external_job.dart';

sealed class CareersPortalState extends Equatable {
  const CareersPortalState();

  @override
  List<Object?> get props => [];
}

class CareersPortalInitial extends CareersPortalState {
  const CareersPortalInitial();
}

class CareersPortalLoading extends CareersPortalState {
  const CareersPortalLoading(this.companyName);
  final String companyName;

  @override
  List<Object?> get props => [companyName];
}

class CareersPortalLoaded extends CareersPortalState {
  const CareersPortalLoaded({
    required this.jobs,
    required this.platform,
    required this.companyName,
    required this.companySlug,
    required this.totalFetched,
    this.filterLast30Days = true,
  });

  final List<ExternalJob> jobs;
  final AtsPlatform platform;
  final String companyName;
  final String companySlug;

  /// Raw count before date filtering.
  final int totalFetched;

  /// Whether the 30-day filter is currently active.
  final bool filterLast30Days;

  CareersPortalLoaded copyWith({bool? filterLast30Days}) =>
      CareersPortalLoaded(
        jobs: jobs,
        platform: platform,
        companyName: companyName,
        companySlug: companySlug,
        totalFetched: totalFetched,
        filterLast30Days: filterLast30Days ?? this.filterLast30Days,
      );

  @override
  List<Object?> get props =>
      [jobs, platform, companyName, companySlug, totalFetched, filterLast30Days];
}

class CareersPortalError extends CareersPortalState {
  const CareersPortalError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Emitted while a single job is being imported into RefSure.
class CareersPortalImporting extends CareersPortalState {
  const CareersPortalImporting(this.jobId);
  final String jobId;

  @override
  List<Object?> get props => [jobId];
}

/// Emitted after a successful import.
class CareersPortalImported extends CareersPortalState {
  const CareersPortalImported({
    required this.jobTitle,
    required this.refSureJobId,
    required this.externalJobId,
  });

  final String jobTitle;
  final String refSureJobId;

  /// The original [ExternalJob.id] — used to mark the card as imported.
  final String externalJobId;

  @override
  List<Object?> get props => [jobTitle, refSureJobId, externalJobId];
}
