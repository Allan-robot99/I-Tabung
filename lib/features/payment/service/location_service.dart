import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:i_tabung/features/payment/model/payment_review_request.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorLocationService();
});

abstract class LocationService {
  Future<PaymentLocationContext> getCurrentLocationContext({
    bool requestPermission = true,
  });

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<PaymentLocationContext> getCurrentLocationContext({
    bool requestPermission = true,
  }) async {
    LocationPermission permission;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      permission = await Geolocator.checkPermission();

      if (!serviceEnabled) {
        return const PaymentLocationContext(permissionStatus: 'service_disabled');
      }

      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const PaymentLocationContext(permissionStatus: 'denied');
      }

      if (permission == LocationPermission.deniedForever) {
        return const PaymentLocationContext(permissionStatus: 'denied_forever');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      return PaymentLocationContext(
        permissionStatus: permission.name,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
    } catch (_) {
      return const PaymentLocationContext(permissionStatus: 'unavailable');
    }
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
