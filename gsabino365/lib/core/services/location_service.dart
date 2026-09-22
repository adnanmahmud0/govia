import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Centralized service for GPS location tracking, permissions, and Google Maps integration.
class LocationService {
  LocationService._();

  /// Retrieves the current device location with non-blocking resilience.
  /// First checks last known position (instant), then queries satellite/network fix
  /// with a configurable timeout so emergency workflows are never delayed.
  static Future<Position?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services are disabled on device');
        // Still attempt to get last known position
        try {
          return await Geolocator.getLastKnownPosition();
        } catch (_) {
          return null;
        }
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permission denied: $permission');
        return null;
      }

      // Fast-path: return last known position immediately if available
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        // Asynchronously request fresh fix in background if needed, but return lastKnown
        // if it's recent (less than 2 minutes old)
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age.inMinutes < 2) {
          return lastKnown;
        }
      }

      // Query current position with high accuracy and strict timeout
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: timeout,
          ),
        );
      } catch (_) {
        return lastKnown;
      }
    } catch (e) {
      debugPrint('[LocationService] Error fetching location: $e');
      return null;
    }
  }

  /// Opens Google Maps live view centered on the specified coordinates.
  /// Launches native Google Maps app if installed, or web browser.
  static Future<bool> openGoogleMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final query = '$latitude,$longitude';
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$query';

    try {
      final uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        return await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      debugPrint('[LocationService] Failed to launch Google Maps: $e');
      // Final fallback attempt
      try {
        return await launchUrl(
          Uri.parse('geo:$latitude,$longitude?q=$query'),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        return false;
      }
    }
  }

  /// Opens Google Maps query from an address or coordinate string.
  static Future<bool> openGoogleMapsByQuery(String query) async {
    final encoded = Uri.encodeComponent(query);
    final url = 'https://www.google.com/maps/search/?api=1&query=$encoded';
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[LocationService] Failed to launch Google Maps query: $e');
      return false;
    }
  }

  /// Formats raw decimal degrees into human-friendly coordinate string
  /// Example: "40.7128° N, 74.0060° W"
  static String formatCoordinates(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    final latAbs = lat.abs().toStringAsFixed(4);
    final lngAbs = lng.abs().toStringAsFixed(4);
    return '$latAbs° $latDir, $lngAbs° $lngDir';
  }

  /// Continuous live position stream for real-time tracking during active sessions.
  static Stream<Position> getPositionStream({int distanceFilter = 10}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }
}
