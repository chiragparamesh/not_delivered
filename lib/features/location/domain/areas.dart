import 'dart:math' as math;

class Area {
  const Area(this.name, this.lat, this.lon);

  final String name;
  final double lat;
  final double lon;
}

/// Neighbourhoods we "deliver" to (manual location fallback).
const areas = <Area>[
  Area('Koramangala', 12.9352, 77.6245),
  Area('Indiranagar', 12.9719, 77.6412),
  Area('HSR Layout', 12.9116, 77.6474),
  Area('Jayanagar', 12.9250, 77.5938),
  Area('Malleshwaram', 13.0035, 77.5710),
  Area('Whitefield', 12.9698, 77.7500),
  Area('BTM Layout', 12.9166, 77.6101),
  Area('JP Nagar', 12.9063, 77.5857),
  Area('Electronic City', 12.8452, 77.6602),
  Area('MG Road', 12.9756, 77.6066),
  Area('Basavanagudi', 12.9422, 77.5737),
  Area('Marathahalli', 12.9569, 77.7011),
];

Area areaByName(String name) => areas.firstWhere((a) => a.name == name, orElse: () => areas.first);

/// Great-circle distance in km.
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// Closest delivery area to a GPS fix, or null when outside Bengaluru (> 25 km away).
Area? nearestArea(double lat, double lon) {
  Area? best;
  var bestKm = double.infinity;
  for (final a in areas) {
    final d = distanceKm(lat, lon, a.lat, a.lon);
    if (d < bestKm) {
      best = a;
      bestKm = d;
    }
  }
  return bestKm <= 25 ? best : null;
}

/// Delivery estimate: kitchen time + ~2.5 min per km, at least 15 min.
int deliveryMinutes(int baseMins, double km) => math.max(15, (baseMins + km * 2.5).round());
