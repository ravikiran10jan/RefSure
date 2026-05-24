// lib/services/tour_service.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Manages whether the app tour has been seen by the user.
class TourService {
  static const _key = 'app_tour_seen';

  static Future<bool> hasSeenTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markTourSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
  }
}
