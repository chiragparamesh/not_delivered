import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_controller.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(notificationsProvider.notifier).markAllRead());
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: list.isEmpty
          ? const Center(child: Text('All quiet. Suspiciously quiet.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final n in list)
                  Card(
                    child: ListTile(
                      leading: Text(n.emoji, style: const TextStyle(fontSize: 26)),
                      title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w500 : FontWeight.w800)),
                      subtitle: Text(n.body),
                    ),
                  ),
              ],
            ),
    );
  }
}
