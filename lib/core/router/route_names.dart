class RouteNames {
  RouteNames._();

  static const String auth = '/auth';
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String jobs = '/jobs';
  static const String jobDetail = '/jobs/:id';
  static const String providers = '/providers';
  static const String providerDetail = '/providers/:id';
  static const String applications = '/applications';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String messages = '/messages';
  static const String chat = '/messages/:id';
  static const String notifications = '/notifications';
  static const String verifyOrg = '/verify-org';
  static const String postJob = '/post-job';
  static const String careersPortal = '/careers-portal';

  static String jobDetailPath(String id) => '/jobs/$id';
  static String providerDetailPath(String id) => '/providers/$id';
  static String chatPath(String id) => '/messages/$id';
}
