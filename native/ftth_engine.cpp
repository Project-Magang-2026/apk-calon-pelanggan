#include <cmath>
#include <cstdint>

namespace {
constexpr double kPi = 3.14159265358979323846;
constexpr double kEarthRadiusKm = 6371.0;

double toRadians(double degree) {
  return degree * (kPi / 180.0);
}
}  // namespace

extern "C" {

#if defined(_WIN32)
#define FTTH_EXPORT __declspec(dllexport)
#else
#define FTTH_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

/// Menghitung jarak Haversine antara dua koordinat GPS dalam satuan meter.
FTTH_EXPORT double ftth_haversine_meters(
    double lat1,
    double lon1,
    double lat2,
    double lon2) {
  const double dLat = toRadians(lat2 - lat1);
  const double dLon = toRadians(lon2 - lon1);

  const double a = std::sin(dLat / 2.0) * std::sin(dLat / 2.0) +
                   std::cos(toRadians(lat1)) * std::cos(toRadians(lat2)) *
                       std::sin(dLon / 2.0) * std::sin(dLon / 2.0);

  const double c = 2.0 * std::atan2(std::sqrt(a), std::sqrt(1.0 - a));
  return (kEarthRadiusKm * c) * 1000.0;
}

/// Estimasi redaman optik (dBm) berdasarkan daya ODP, jarak kabel drop (m), dan jumlah sambungan.
FTTH_EXPORT double ftth_estimate_attenuation_dbm(
    double odpPowerDbm,
    double distanceMeters,
    int32_t spliceCount) {
  const double distanceKm = distanceMeters / 1000.0;
  const double fiberLoss = distanceKm * 0.35;      // ~0.35 dB/km (1310nm)
  const double spliceLoss = spliceCount * 0.15;    // ~0.15 dB per sambungan
  const double connectorLoss = 0.5;                // ~0.50 dB konektor
  return odpPowerDbm - fiberLoss - spliceLoss - connectorLoss;
}

/// Validasi apakah redaman optik memenuhi standar operasional FTTH (-25.0 s/d -14.0 dBm).
FTTH_EXPORT int32_t ftth_is_attenuation_acceptable(double attenuationDbm) {
  return (attenuationDbm >= -25.0 && attenuationDbm <= -14.0) ? 1 : 0;
}

}  // extern "C"
