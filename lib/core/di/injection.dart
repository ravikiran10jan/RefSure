import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:refsure/features/applications/data/applications_repository.dart';
import 'package:refsure/features/careers_portal/careers_portal.dart';
import 'package:refsure/features/applications/presentation/cubit/applications_cubit.dart';
import 'package:refsure/features/auth/data/auth_repository.dart';
import 'package:refsure/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:refsure/features/dashboard/data/dashboard_repository.dart';
import 'package:refsure/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:refsure/features/jobs/data/jobs_repository.dart';
import 'package:refsure/features/jobs/presentation/cubit/jobs_cubit.dart';
import 'package:refsure/features/messaging/data/messaging_repository.dart';
import 'package:refsure/features/messaging/presentation/cubit/messaging_cubit.dart';
import 'package:refsure/features/notifications/data/notifications_repository.dart';
import 'package:refsure/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:refsure/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:refsure/features/profile/data/profile_repository.dart';
import 'package:refsure/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:refsure/services/auth_service.dart';
import 'package:refsure/services/careers_portal_service.dart';
import 'package:refsure/services/firestore_service.dart';
import 'package:refsure/services/otp_service.dart';
import 'package:refsure/services/storage_service.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // Firebase instances
  getIt
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    )
    ..registerLazySingleton<FirebaseStorage>(
      () => FirebaseStorage.instance,
    )
    // Services
    ..registerLazySingleton<AuthService>(AuthService.new)
    ..registerLazySingleton<FirestoreService>(FirestoreService.new)
    ..registerLazySingleton<StorageService>(StorageService.new)
    ..registerLazySingleton<OtpService>(OtpService.new)
    ..registerLazySingleton<CareersPortalService>(CareersPortalService.new)
    // Repositories
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepository(getIt<AuthService>()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepository(
        getIt<FirestoreService>(),
        getIt<StorageService>(),
      ),
    )
    ..registerLazySingleton<JobsRepository>(
      () => JobsRepository(getIt<FirestoreService>()),
    )
    ..registerLazySingleton<ApplicationsRepository>(
      () => ApplicationsRepository(getIt<FirestoreService>()),
    )
    ..registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepository(getIt<FirestoreService>()),
    )
    ..registerLazySingleton<MessagingRepository>(
      () => MessagingRepository(getIt<FirestoreService>()),
    )
    ..registerLazySingleton<DashboardRepository>(
      () => DashboardRepository(getIt<FirestoreService>()),
    )
    ..registerLazySingleton<CareersPortalRepository>(
      () => CareersPortalRepository(
        getIt<CareersPortalService>(),
        getIt<JobsRepository>(),
      ),
    )
    // BLoCs & Cubits
    ..registerFactory<AuthBloc>(
      () => AuthBloc(authRepository: getIt<AuthRepository>()),
    )
    ..registerFactory<ProfileCubit>(
      () => ProfileCubit(profileRepository: getIt<ProfileRepository>()),
    )
    ..registerFactory<JobsCubit>(
      () => JobsCubit(jobsRepository: getIt<JobsRepository>()),
    )
    ..registerFactory<ApplicationsCubit>(
      () => ApplicationsCubit(
        applicationsRepository: getIt<ApplicationsRepository>(),
      ),
    )
    ..registerFactory<NotificationsCubit>(
      () => NotificationsCubit(
        notificationsRepository: getIt<NotificationsRepository>(),
      ),
    )
    ..registerFactory<MessagingCubit>(
      () => MessagingCubit(
        messagingRepository: getIt<MessagingRepository>(),
      ),
    )
    ..registerFactory<DashboardCubit>(
      () => DashboardCubit(
        dashboardRepository: getIt<DashboardRepository>(),
      ),
    )
    ..registerFactory<OnboardingCubit>(
      () => OnboardingCubit(
        profileRepository: getIt<ProfileRepository>(),
      ),
    )
    ..registerFactory<CareersPortalCubit>(
      () => CareersPortalCubit(
        repository: getIt<CareersPortalRepository>(),
      ),
    );
}
