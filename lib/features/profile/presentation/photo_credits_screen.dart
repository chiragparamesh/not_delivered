import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Attribution for the bundled food photos (Wikimedia Commons, CC licences).
final photoCreditsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final j = jsonDecode(await rootBundle.loadString('assets/data/photo_credits.json')) as Map<String, dynamic>;
  return [for (final c in j['photos'] as List) c as Map<String, dynamic>];
});

class PhotoCreditsScreen extends ConsumerWidget {
  const PhotoCreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits = ref.watch(photoCreditsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Photo credits')),
      body: credits.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Food photos are from Wikimedia Commons, used under their free licences. '
              'Photos are illustrative; restaurants in this app are fictional.',
            ),
            const SizedBox(height: 8),
            for (final c in list)
              ListTile(
                dense: true,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/images/dishes/${c['file']}', width: 44, height: 44, fit: BoxFit.cover),
                ),
                title: Text('${c['title']}'.replaceFirst('File:', '')),
                subtitle: Text('${c['artist']} · ${c['license']}\n${c['page']}'),
                isThreeLine: true,
              ),
          ],
        ),
      ),
    );
  }
}
