import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/store.dart';

/// Favourite restaurant ids.
class FavoritesController extends Notifier<Set<String>> {
  static const _key = 'favorites';

  @override
  Set<String> build() => {...(ref.read(storeProvider).read(_key) as List? ?? const []).cast<String>()};

  void toggle(String restaurantId) {
    final next = {...state};
    next.contains(restaurantId) ? next.remove(restaurantId) : next.add(restaurantId);
    state = next;
    ref.read(storeProvider).write(_key, next.toList());
  }
}

final favoritesProvider = NotifierProvider<FavoritesController, Set<String>>(FavoritesController.new);
