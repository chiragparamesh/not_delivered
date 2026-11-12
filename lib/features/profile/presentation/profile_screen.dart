import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/clock.dart';
import '../../../core/services/store.dart';
import '../../../core/theme/app_theme.dart';
import '../../cart/data/cart_controller.dart';
import '../../favorites/data/favorites_controller.dart';
import '../../notifications/data/notifications_controller.dart';
import '../../orders/data/orders_controller.dart';
import '../../rewards/data/rewards_controller.dart';
import '../../rewards/domain/rewards.dart';
import '../../settings/data/settings_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController(text: ref.read(settingsProvider).name);
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(controller: c, autofocus: true),
        actions: [FilledButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('Save'))],
      ),
    );
    if (name != null) ref.read(settingsProvider.notifier).setName(name);
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text('Clears orders, cart, favourites, rewards and settings on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(storeProvider).clear();
    for (final p in [settingsProvider, cartProvider, ordersProvider, favoritesProvider, rewardsProvider, notificationsProvider]) {
      ref.invalidate(p);
    }
    if (context.mounted) context.go(AppRoutes.splash);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final orders = ref.watch(ordersProvider);
    final rewards = ref.watch(rewardsProvider);
    final now = ref.watch(clockProvider)();
    final earned = earnedBadges(orders, now);
    final streak = orderStreak(orders, now);
    final saved = totalSavings(orders);
    final unread = ref.watch(unreadCountProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            const CircleAvatar(radius: 30, backgroundColor: AppColors.gold, child: Text('😋', style: TextStyle(fontSize: 30))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: theme.textTheme.titleLarge),
                Text('${s.area ?? ''}${s.address.isNotEmpty ? ' · ${s.address}' : ''}', style: theme.textTheme.bodySmall),
              ]),
            ),
            IconButton(tooltip: 'Edit name', onPressed: () => _editName(context, ref), icon: const Icon(Icons.edit_outlined)),
          ]),
          const SizedBox(height: 16),
          Card(
            color: AppColors.maroon,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('You have saved', style: TextStyle(color: Colors.white70)),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: saved),
                  duration: const Duration(milliseconds: 900),
                  builder: (_, v, _) => Text('₹$v',
                      key: const Key('savings'),
                      style: const TextStyle(color: AppColors.gold, fontSize: 40, fontWeight: FontWeight.w800, fontFamily: AppTheme.headingFont)),
                ),
                Text('with coupons across ${orders.length} order${orders.length == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white)),
              ]),
            ),
          ),
          Row(children: [
            _stat('🔥', '$streak day${streak == 1 ? '' : 's'}', 'Order streak'),
            _stat('⭐', '${rewards.points}', 'Reward points'),
            _stat('🏅', '${earned.length}/${allBadges.length}', 'Badges'),
          ]),
          const SizedBox(height: 12),
          Text('Badges', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.95,
            children: [
              for (final b in allBadges)
                Opacity(
                  opacity: earned.contains(b.id) ? 1 : 0.35,
                  child: Card(
                    child: Tooltip(
                      message: b.description,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(earned.contains(b.id) ? b.emoji : '🔒', style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 4),
                        Text(b.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(children: [
              ListTile(leading: const Icon(Icons.favorite_border), title: const Text('Favourites'), onTap: () => context.push(AppRoutes.favorites)),
              ListTile(
                leading: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_none)),
                title: const Text('Notifications'),
                onTap: () => context.push(AppRoutes.notifications),
              ),
              ListTile(leading: const Icon(Icons.casino_outlined), title: const Text('Daily spin'), onTap: () => context.push(AppRoutes.spin)),
              ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Change location'), onTap: () => context.push(AppRoutes.location)),
              ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Photo credits'), onTap: () => context.push(AppRoutes.credits)),
              ListTile(leading: const Icon(Icons.restart_alt), title: const Text('Reset demo data'), onTap: () => _reset(context, ref)),
            ]),
          ),
          const SizedBox(height: 12),
          const Center(child: Text('Not Delivered is a demo. No food, no payments, all fun.', style: TextStyle(fontSize: 12, color: Colors.black54))),
        ],
      ),
    );
  }

  Widget _stat(String emoji, String value, String label) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(label, style: const TextStyle(fontSize: 11)),
            ]),
          ),
        ),
      );
}
