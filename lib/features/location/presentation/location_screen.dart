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
  String? _message;
  late final _address = TextEditingController(text: ref.read(settingsProvider).address);

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _choose(Area a) {
    ref.read(settingsProvider.notifier).setArea(a.name, address: _address.text.trim());
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _useGps() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final pos = await ref.read(locationServiceProvider).currentPosition();
    if (!mounted) return;
    final area = pos == null ? null : nearestArea(pos.$1, pos.$2);
    setState(() {
      _busy = false;
      _message = pos == null
          ? 'Could not get your location. Pick your area below.'
          : area == null
              ? 'Looks like you are outside Bengaluru. Pick an area below.'
              : null;
    });
    if (area != null) _choose(area);
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
          for (final a in areas)
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
