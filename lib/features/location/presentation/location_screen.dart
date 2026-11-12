import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/data/settings_controller.dart';
import '../data/location_service.dart';
import '../domain/areas.dart';

/// GPS first, manual area list as fallback.
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  var _busy = false;
  var _q = '';
  String? _message;
  late final _address = TextEditingController(text: ref.read(settingsProvider).address);

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _done() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _choose(Area a) {
    ref.read(settingsProvider.notifier).setArea(a.name, address: _address.text.trim(), lat: a.lat, lon: a.lon);
    _done();
  }

  Future<void> _useGps() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final pos = await ref.read(locationServiceProvider).currentPosition();
    if (!mounted) return;
    final near = pos == null ? null : nearestArea(pos.$1, pos.$2);
    setState(() {
      _busy = false;
      _message = pos == null
          ? 'Could not get your location. Check that location is on, or pick your area below.'
          : near == null
              ? 'Looks like you are outside Bengaluru. Pick an area below.'
              : null;
    });
    if (pos != null && near != null) {
      ref.read(settingsProvider.notifier).setGps(pos.$1, pos.$2, near.$1.name, address: _address.text.trim());
      _done();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(settingsProvider).area;
    return Scaffold(
      appBar: AppBar(title: const Text('Where should we (not) deliver?')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            key: const Key('use-gps'),
            onPressed: _busy ? null : _useGps,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            label: Text(_busy ? 'Finding you…' : 'Use my current location'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_message!, style: const TextStyle(color: AppColors.nonVeg)),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _address,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.home_outlined),
              hintText: 'Flat / house no., street (optional)',
            ),
          ),
          const SizedBox(height: 16),
          Text('Or choose your area', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            key: const Key('area-search'),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search 50 Bengaluru areas'),
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 8),
          for (final a in areas.where((a) => a.name.toLowerCase().contains(_q)))
            Card(
              child: ListTile(
                key: ValueKey('area-${a.name}'),
                leading: Icon(Icons.location_on_outlined, color: a.name == current ? AppColors.maroon : null),
                title: Text(a.name),
                trailing: a.name == current ? const Icon(Icons.check, color: AppColors.maroon) : null,
                onTap: () => _choose(a),
              ),
            ),
        ],
      ),
    );
  }
}
