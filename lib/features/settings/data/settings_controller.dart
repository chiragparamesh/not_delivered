import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/store.dart';

class AppSettings {
  const AppSettings({this.onboarded = false, this.area, this.address = '', this.name = 'Foodie'});

  final bool onboarded;

  /// Delivery area name (see location/domain/areas.dart). Null until chosen.
  final String? area;
  final String address;
  final String name;

  AppSettings copyWith({bool? onboarded, String? area, String? address, String? name}) => AppSettings(
        onboarded: onboarded ?? this.onboarded,
        area: area ?? this.area,
        address: address ?? this.address,
        name: name ?? this.name,
      );

  Map<String, dynamic> toJson() => {'onboarded': onboarded, 'area': area, 'address': address, 'name': name};

  factory AppSettings.fromJson(Map j) => AppSettings(
        onboarded: j['onboarded'] as bool? ?? false,
        area: j['area'] as String?,
        address: j['address'] as String? ?? '',
        name: j['name'] as String? ?? 'Foodie',
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
  void setArea(String area, {String? address}) => _save(state.copyWith(area: area, address: address));
  void setName(String name) => _save(state.copyWith(name: name.trim().isEmpty ? 'Foodie' : name.trim()));
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
