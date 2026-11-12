import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/store.dart';

class AppSettings {
  const AppSettings({this.onboarded = false, this.area, this.address = '', this.name = 'Foodie', this.lat, this.lon, this.fromGps = false});

  final bool onboarded;

  /// Delivery area name (see location/domain/areas.dart). Null until chosen.
  final String? area;
  final String address;
  final String name;

  /// Exact delivery point (GPS fix, or the chosen locality's centre).
  final double? lat;
  final double? lon;
  final bool fromGps;

  AppSettings copyWith({bool? onboarded, String? area, String? address, String? name, double? lat, double? lon, bool? fromGps}) =>
      AppSettings(
        onboarded: onboarded ?? this.onboarded,
        area: area ?? this.area,
        address: address ?? this.address,
        name: name ?? this.name,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        fromGps: fromGps ?? this.fromGps,
      );

  Map<String, dynamic> toJson() =>
      {'onboarded': onboarded, 'area': area, 'address': address, 'name': name, 'lat': lat, 'lon': lon, 'fromGps': fromGps};

  factory AppSettings.fromJson(Map j) => AppSettings(
        onboarded: j['onboarded'] as bool? ?? false,
        area: j['area'] as String?,
        address: j['address'] as String? ?? '',
        name: j['name'] as String? ?? 'Foodie',
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
        fromGps: j['fromGps'] as bool? ?? false,
      );
}

class SettingsController extends Notifier<AppSettings> {
  static const _key = 'settings';

  @override
  AppSettings build() {
    final raw = ref.read(storeProvider).read(_key);
    return raw is Map ? AppSettings.fromJson(raw) : const AppSettings();
  }

  void _save(AppSettings s) {
    state = s;
    ref.read(storeProvider).write(_key, s.toJson());
  }

  void finishOnboarding() => _save(state.copyWith(onboarded: true));
  /// Manual pick: the locality's centre becomes the delivery point.
  void setArea(String area, {String? address, required double lat, required double lon}) =>
      _save(state.copyWith(area: area, address: address, lat: lat, lon: lon, fromGps: false));

  /// GPS fix: keep the exact coordinates, label with the nearest locality.
  void setGps(double lat, double lon, String nearestArea, {String? address}) =>
      _save(state.copyWith(area: nearestArea, address: address, lat: lat, lon: lon, fromGps: true));
  void setName(String name) => _save(state.copyWith(name: name.trim().isEmpty ? 'Foodie' : name.trim()));
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
