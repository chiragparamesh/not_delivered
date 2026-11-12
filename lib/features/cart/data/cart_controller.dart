import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/store.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/models.dart';
import '../../orders/data/orders_controller.dart';
import '../domain/coupons.dart';

class CartState {
  const CartState({this.restaurantId, this.lines = const {}, this.couponCode, this.tip = 0});

  final String? restaurantId;

  /// dishId -> quantity
  final Map<String, int> lines;
  final String? couponCode;
  final int tip;

  bool get isEmpty => lines.isEmpty;
  int get itemCount => lines.values.fold(0, (a, b) => a + b);
  int qty(String dishId) => lines[dishId] ?? 0;

  CartState copyWith({String? restaurantId, Map<String, int>? lines, String? couponCode, bool clearCoupon = false, int? tip}) =>
      CartState(
        restaurantId: restaurantId ?? this.restaurantId,
        lines: lines ?? this.lines,
        couponCode: clearCoupon ? null : (couponCode ?? this.couponCode),
        tip: tip ?? this.tip,
      );

  Map<String, dynamic> toJson() => {'restaurantId': restaurantId, 'lines': lines, 'couponCode': couponCode, 'tip': tip};

  factory CartState.fromJson(Map j) => CartState(
        restaurantId: j['restaurantId'] as String?,
        lines: {for (final e in (j['lines'] as Map? ?? const {}).entries) e.key as String: e.value as int},
        couponCode: j['couponCode'] as String?,
        tip: j['tip'] as int? ?? 0,
      );
}

enum AddResult { added, otherRestaurant }

/// Cart from a single restaurant, persisted in Hive.
class CartController extends Notifier<CartState> {
  static const _key = 'cart';

  @override
  CartState build() {
    final raw = ref.read(storeProvider).read(_key);
    return raw is Map ? CartState.fromJson(raw) : const CartState();
  }

  void _save(CartState s) {
    final clean = s.lines.isEmpty ? const CartState() : s;
    state = clean;
    ref.read(storeProvider).write(_key, clean.toJson());
  }

  /// Returns [AddResult.otherRestaurant] (and changes nothing) when the cart
  /// holds another restaurant's food; call [startNewCart] after confirming.
  AddResult add(Dish dish) {
    if (state.restaurantId != null && state.restaurantId != dish.restaurantId && !state.isEmpty) {
      return AddResult.otherRestaurant;
    }
    _save(state.copyWith(restaurantId: dish.restaurantId, lines: {...state.lines, dish.id: state.qty(dish.id) + 1}));
    return AddResult.added;
  }

  void startNewCart(Dish dish) => _save(CartState(restaurantId: dish.restaurantId, lines: {dish.id: 1}));

  void remove(Dish dish) {
    final q = state.qty(dish.id) - 1;
    final lines = {...state.lines};
    q <= 0 ? lines.remove(dish.id) : lines[dish.id] = q;
    _save(state.copyWith(lines: lines));
  }

  /// One coupon at a time: applying a new one replaces the old one.
  void applyCoupon(String code) => _save(state.copyWith(couponCode: code));
  void removeCoupon() => _save(state.copyWith(clearCoupon: true));
  void setTip(int tip) => _save(state.copyWith(tip: tip));
  void clear() => _save(const CartState());

  /// Reorder: replace the cart with a past order's dishes (those still on the menu).
  void replaceWith(String restaurantId, Map<String, int> lines) =>
      _save(CartState(restaurantId: restaurantId, lines: lines));
}

final cartProvider = NotifierProvider<CartController, CartState>(CartController.new);

/// The live bill for the cart (null while the catalog loads or the cart is empty).
final cartBillProvider = Provider<Bill?>((ref) {
  final cart = ref.watch(cartProvider);
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null || cart.isEmpty) return null;
  final restaurant = catalog.restaurant(cart.restaurantId!);
  var itemTotal = 0;
  for (final e in cart.lines.entries) {
    itemTotal += (catalog.dish(e.key)?.price ?? 0) * e.value;
  }
  return computeBill(
    itemTotal: itemTotal,
    isFirstOrder: ref.watch(ordersProvider).isEmpty,
    isDessertOrBakery: restaurant?.isDessertOrBakery ?? false,
    couponCode: cart.couponCode,
    tip: cart.tip,
  );
});
