/// A placed (simulated) order. Stored as JSON in Hive.
class OrderLine {
  const OrderLine({required this.dishId, required this.name, required this.price, required this.qty, required this.isVeg});

  final String dishId;
  final String name;
  final int price;
  final int qty;
  final bool isVeg;

  Map<String, dynamic> toJson() => {'dishId': dishId, 'name': name, 'price': price, 'qty': qty, 'isVeg': isVeg};

  factory OrderLine.fromJson(Map j) => OrderLine(
        dishId: j['dishId'] as String,
        name: j['name'] as String,
        price: j['price'] as int,
        qty: j['qty'] as int,
        isVeg: j['isVeg'] as bool,
      );
}

class Order {
  const Order({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantCategory,
    required this.cuisine,
    required this.lines,
    required this.itemTotal,
    required this.deliveryFee,
    required this.discount,
    required this.tip,
    required this.couponCode,
    required this.placedAt,
    required this.payment,
    required this.address,
    required this.riderName,
    required this.easterEgg,
    this.deliveredAt,
    this.scratchReward,
  });

  final String id;
  final String restaurantId;
  final String restaurantName;
  final String restaurantCategory;

  /// Primary cuisine (for the Explorer badge).
  final String cuisine;
  final List<OrderLine> lines;
  final int itemTotal;
  final int deliveryFee;
  final int discount;
  final int tip;
  final String? couponCode;
  final DateTime placedAt;
  final String payment;
  final String address;
  final String riderName;

  /// Rare "Not Delivered… just kidding!" moment for this order.
  final bool easterEgg;
  final DateTime? deliveredAt;

  /// Null = scratch card not scratched yet. 0 = "better luck next time".
  final int? scratchReward;

  int get total => itemTotal + deliveryFee + tip - discount;
  int get itemCount => lines.fold(0, (s, l) => s + l.qty);
  bool get isDelivered => deliveredAt != null;

  /// Money saved: coupon discount (incl. free delivery coupons).
  int get savings => discount;

  Order copyWith({DateTime? deliveredAt, int? scratchReward}) => Order(
        id: id,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        restaurantCategory: restaurantCategory,
        cuisine: cuisine,
        lines: lines,
        itemTotal: itemTotal,
        deliveryFee: deliveryFee,
        discount: discount,
        tip: tip,
        couponCode: couponCode,
        placedAt: placedAt,
        payment: payment,
        address: address,
        riderName: riderName,
        easterEgg: easterEgg,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        scratchReward: scratchReward ?? this.scratchReward,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'restaurantCategory': restaurantCategory,
        'cuisine': cuisine,
        'lines': [for (final l in lines) l.toJson()],
        'itemTotal': itemTotal,
        'deliveryFee': deliveryFee,
        'discount': discount,
        'tip': tip,
        'couponCode': couponCode,
        'placedAt': placedAt.toIso8601String(),
        'payment': payment,
        'address': address,
        'riderName': riderName,
        'easterEgg': easterEgg,
        'deliveredAt': deliveredAt?.toIso8601String(),
        'scratchReward': scratchReward,
      };

  factory Order.fromJson(Map j) => Order(
        id: j['id'] as String,
        restaurantId: j['restaurantId'] as String,
        restaurantName: j['restaurantName'] as String,
        restaurantCategory: j['restaurantCategory'] as String,
        cuisine: j['cuisine'] as String,
        lines: [for (final l in j['lines'] as List) OrderLine.fromJson(l as Map)],
        itemTotal: j['itemTotal'] as int,
        deliveryFee: j['deliveryFee'] as int,
        discount: j['discount'] as int,
        tip: j['tip'] as int,
        couponCode: j['couponCode'] as String?,
        placedAt: DateTime.parse(j['placedAt'] as String),
        payment: j['payment'] as String,
        address: j['address'] as String,
        riderName: j['riderName'] as String,
        easterEgg: j['easterEgg'] as bool,
        deliveredAt: j['deliveredAt'] == null ? null : DateTime.parse(j['deliveredAt'] as String),
        scratchReward: j['scratchReward'] as int?,
      );
}
