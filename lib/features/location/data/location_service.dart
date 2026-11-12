import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// GPS behind an interface: geolocator on Android and web, fake in tests.
abstract class LocationService {
  /// (lat, lon) or null when permission is denied, GPS is off or it times out.
  Future<(double, double)?> currentPosition();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<(double, double)?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 12)),
      );
      return (p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) => GeolocatorLocationService());
