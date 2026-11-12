import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/clock.dart';
import '../../../core/services/store.dart';

class AppNotification {
  const AppNotification({required this.title, required this.body, required this.time, this.read = false, this.emoji = '🔔'});

  final String title;
  final String body;
  final DateTime time;
  final bool read;
  final String emoji;

  Map<String, dynamic> toJson() =>
      {'title': title, 'body': body, 'time': time.toIso8601String(), 'read': read, 'emoji': emoji};

  factory AppNotification.fromJson(Map j) => AppNotification(
        title: j['title'] as String,
        body: j['body'] as String,
        time: DateTime.parse(j['time'] as String),
        read: j['read'] as bool? ?? false,
        emoji: j['emoji'] as String? ?? '🔔',
      );
}

/// In-app notifications (newest first, max 50).
class NotificationsController extends Notifier<List<AppNotification>> {
  static const _key = 'notifications';

  @override
  List<AppNotification> build() =>
      [for (final j in ref.read(storeProvider).read(_key) as List? ?? const []) AppNotification.fromJson(j as Map)];

  void push(String emoji, String title, String body) => _save([
        AppNotification(emoji: emoji, title: title, body: body, time: ref.read(clockProvider)()),
        ...state,
      ].take(50).toList());

  void markAllRead() => _save([
        for (final n in state)
          AppNotification(emoji: n.emoji, title: n.title, body: n.body, time: n.time, read: true),
      ]);

  void _save(List<AppNotification> list) {
    state = list;
    ref.read(storeProvider).write(_key, [for (final n in list) n.toJson()]);
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsController, List<AppNotification>>(NotificationsController.new);

final unreadCountProvider = Provider<int>((ref) => ref.watch(notificationsProvider).where((n) => !n.read).length);
