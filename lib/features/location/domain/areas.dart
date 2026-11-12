import 'dart:math' as math;

class Area {
  const Area(this.name, this.lat, this.lon);

  final String name;
  final double lat;
  final double lon;
}

/// Bengaluru localities (approximate centres). Used to label a GPS fix
/// ("Near Basaveshwaranagar") and as the manual fallback list.
const areas = <Area>[
  Area('Banashankari', 12.9255, 77.5468),
  Area('Bannerghatta Road', 12.8870, 77.5970),
  Area('Banaswadi', 13.0104, 77.6482),
  Area('Basavanagudi', 12.9422, 77.5737),
  Area('Basaveshwaranagar', 12.9934, 77.5398),
  Area('Begur', 12.8790, 77.6340),
  Area('Bellandur', 12.9260, 77.6762),
  Area('Bommanahalli', 12.9010, 77.6240),
  Area('Brookefield', 12.9667, 77.7167),
  Area('BTM Layout', 12.9166, 77.6101),
  Area('Domlur', 12.9610, 77.6387),
  Area('Electronic City', 12.8452, 77.6602),
  Area('Frazer Town', 12.9967, 77.6143),
  Area('HBR Layout', 13.0350, 77.6300),
  Area('Hebbal', 13.0358, 77.5970),
  Area('Hennur', 13.0450, 77.6400),
  Area('HSR Layout', 12.9116, 77.6474),
  Area('Indiranagar', 12.9719, 77.6412),
  Area('Jayanagar', 12.9250, 77.5938),
  Area('JP Nagar', 12.9063, 77.5857),
  Area('Kammanahalli', 13.0153, 77.6378),
  Area('Kanakapura Road', 12.8830, 77.5630),
  Area('Kengeri', 12.9081, 77.4826),
  Area('Koramangala', 12.9352, 77.6245),
  Area('KR Puram', 13.0076, 77.6950),
  Area('Mahadevapura', 12.9917, 77.7062),
  Area('Majestic', 12.9767, 77.5713),
  Area('Malleshwaram', 13.0035, 77.5710),
  Area('Marathahalli', 12.9569, 77.7011),
  Area('MG Road', 12.9756, 77.6066),
  Area('Nagarbhavi', 12.9600, 77.5100),
  Area('Peenya', 13.0280, 77.5190),
  Area('Rajajinagar', 12.9910, 77.5550),
  Area('Richmond Town', 12.9600, 77.6000),
  Area('RR Nagar', 12.9274, 77.5155),
  Area('RT Nagar', 13.0213, 77.5947),
  Area('Sadashivanagar', 13.0068, 77.5797),
  Area('Sahakara Nagar', 13.0620, 77.5880),
  Area('Sarjapur Road', 12.9100, 77.6870),
  Area('Seshadripuram', 12.9890, 77.5710),
  Area('Shivajinagar', 12.9857, 77.6057),
  Area('Thanisandra', 13.0560, 77.6340),
  Area('Ulsoor', 12.9817, 77.6286),
  Area('Uttarahalli', 12.9050, 77.5460),
  Area('Vidyaranyapura', 13.0790, 77.5560),
  Area('Vijayanagar', 12.9719, 77.5370),
  Area('Whitefield', 12.9698, 77.7500),
  Area('Wilson Garden', 12.9490, 77.5970),
  Area('Yelahanka', 13.1007, 77.5963),
  Area('Yeshwanthpur', 13.0285, 77.5409),
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

/// Closest locality to a GPS fix and how far it is, or null when outside
/// Bengaluru (more than 8 km from every locality).
(Area, double)? nearestArea(double lat, double lon) {
  Area? best;
  var bestKm = double.infinity;
  for (final a in areas) {
    final d = distanceKm(lat, lon, a.lat, a.lon);
    if (d < bestKm) {
      best = a;
      bestKm = d;
    }
  }
  return bestKm <= 8 ? (best!, bestKm) : null;
}

/// Bengaluru peak traffic: weekday mornings 8–11 and evenings 5–9.
bool isPeakHour(DateTime t) =>
    t.weekday <= DateTime.friday && ((t.hour >= 8 && t.hour < 11) || (t.hour >= 17 && t.hour < 21));

/// Realistic delivery estimate in minutes.
/// prep (kitchen) + 5 min pickup/handover + ~4 min per km (≈15 km/h city
/// riding), +35% in peak traffic; never under 20 minutes.
class Eta {
  const Eta({required this.prepMins, required this.totalMins});

  final int prepMins;
  final int totalMins;

  /// "35–40 mins"
  String get label => '$totalMins–${totalMins + 5} mins';
}

Eta estimateDelivery({required int baseMins, required double km, required DateTime now}) {
  final prep = math.max(10, (baseMins * 0.65).round());
  final travel = km * 4 * (isPeakHour(now) ? 1.35 : 1.0);
  final total = math.max(20, (prep + 5 + travel).round());
  return Eta(prepMins: prep, totalMins: total);
}
