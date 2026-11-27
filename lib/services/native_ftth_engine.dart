import 'dart:ffi';
import 'dart:io';
import 'dart:math';

typedef _HaversineNative = Double Function(Double, Double, Double, Double);
typedef _HaversineDart = double Function(double, double, double, double);

typedef _EstimateAttenuationNative = Double Function(Double, Double, Int32);
typedef _EstimateAttenuationDart = double Function(double, double, int);

typedef _IsAcceptableNative = Int32 Function(Double);
typedef _IsAcceptableDart = int Function(double);

/// Bridge FFI ke library C++ native (`libftth_engine.so`) pada smartphone Android.
/// Memiliki fallback Dart otomatis jika dijalankan pada lingkungan test/non-native.
class NativeFtthEngine {
  static final NativeFtthEngine _instance = NativeFtthEngine._internal();
  factory NativeFtthEngine() => _instance;

  DynamicLibrary? _lib;
  _HaversineDart? _haversine;
  _EstimateAttenuationDart? _estimateAttenuation;
  _IsAcceptableDart? _isAcceptable;

  NativeFtthEngine._internal() {
    _loadNativeLibrary();
  }

  bool get isNativeLoaded => _lib != null;

  void _loadNativeLibrary() {
    if (!Platform.isAndroid) return;

    try {
      final lib = DynamicLibrary.open('libftth_engine.so');
      _haversine = lib
          .lookup<NativeFunction<_HaversineNative>>('ftth_haversine_meters')
          .asFunction<_HaversineDart>();
      _estimateAttenuation = lib
          .lookup<NativeFunction<_EstimateAttenuationNative>>(
            'ftth_estimate_attenuation_dbm',
          )
          .asFunction<_EstimateAttenuationDart>();
      _isAcceptable = lib
          .lookup<NativeFunction<_IsAcceptableNative>>(
            'ftth_is_attenuation_acceptable',
          )
          .asFunction<_IsAcceptableDart>();
      _lib = lib;
    } catch (_) {
      _lib = null;
    }
  }

  double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (_haversine != null) {
      return _haversine!(lat1, lon1, lat2, lon2);
    }

    const double earthRadiusKm = 6371.0;
    final double dLat = (lat2 - lat1) * (pi / 180.0);
    final double dLon = (lon2 - lon1) * (pi / 180.0);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (earthRadiusKm * c) * 1000.0;
  }

  double estimateAttenuationDbm({
    double odpPowerDbm = -19.0,
    required double distanceMeters,
    int spliceCount = 2,
  }) {
    if (_estimateAttenuation != null) {
      return _estimateAttenuation!(odpPowerDbm, distanceMeters, spliceCount);
    }

    final double distanceKm = distanceMeters / 1000.0;
    return odpPowerDbm - (distanceKm * 0.35) - (spliceCount * 0.15) - 0.5;
  }

  bool isAttenuationAcceptable(double attenuationDbm) {
    if (_isAcceptable != null) {
      return _isAcceptable!(attenuationDbm) == 1;
    }
    return attenuationDbm >= -25.0 && attenuationDbm <= -14.0;
  }
}
