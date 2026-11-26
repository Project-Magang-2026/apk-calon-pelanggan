import 'dart:math';
import '../models/odp_model.dart';

class GeoCalculationService {
  // Titik ODP contoh milik PT Mitra Media Data di area operasional
  static final List<OdpPoint> registeredOdpList = [
    OdpPoint(
      id: 'odp_1',
      code: 'ODP-MMD-PST-01',
      locationName: 'Simpang Tiga Jl. Pemuda',
      latitude: -6.200000,
      longitude: 106.816666,
      totalPorts: 8,
      usedPorts: 3,
    ),
    OdpPoint(
      id: 'odp_2',
      code: 'ODP-MMD-BRT-02',
      locationName: 'Perumahan Griya Indah Blok A',
      latitude: -6.208500,
      longitude: 106.819200,
      totalPorts: 16,
      usedPorts: 10,
    ),
    OdpPoint(
      id: 'odp_3',
      code: 'ODP-MMD-TMR-03',
      locationName: 'Depan Alfamart Boulevard',
      latitude: -6.195200,
      longitude: 106.825100,
      totalPorts: 8,
      usedPorts: 5,
    ),
    OdpPoint(
      id: 'odp_4',
      code: 'ODP-MMD-SLT-04',
      locationName: 'Pertigaan Sukamaju Rt 03',
      latitude: -6.214000,
      longitude: 106.810500,
      totalPorts: 16,
      usedPorts: 15, // Hampir penuh
    ),
  ];

  /// Menghitung jarak antara 2 koordinat (Haversine Formula) dalam meter
  static double calculateDistanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distanceKm = earthRadiusKm * c;

    return distanceKm * 1000.0; // Konversi ke meter
  }

  static double _toRadians(double degree) {
    return degree * (pi / 180.0);
  }

  /// Mencari ODP terdekat dan menghitung jaraknya
  static Map<String, dynamic> findNearestOdp(double customerLat, double customerLon) {
    OdpPoint? nearestOdp;
    double minDistance = double.infinity;

    for (final odp in registeredOdpList) {
      final double distance = calculateDistanceInMeters(
        customerLat,
        customerLon,
        odp.latitude,
        odp.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestOdp = odp;
      }
    }

    return {
      'odp': nearestOdp,
      'distanceMeters': minDistance,
      'isCovered': minDistance <= 250.0, // Maksimal standar tarikan kabel drop core
      'isOptimal': minDistance <= 150.0,
    };
  }
}
