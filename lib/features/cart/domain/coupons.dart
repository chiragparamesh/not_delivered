import 'dart:math' as math;

/// Delivery fee rule from the brief: ₹30 below ₹199, free from ₹199.
const freeDeliveryFrom = 199;
const deliveryFee = 30;

int deliveryFeeFor(int itemTotal) => itemTotal <= 0 || itemTotal >= freeDeliveryFrom ? 0 : deliveryFee;

enum CouponKind { percent, flat, freeDelivery }

class Coupon {
  const Coupon({
    required this.code,
    required this.title,
    required this.kind,
    this.value = 0,
    this.maxDiscount,
    this.minOrder = 0,
    this.firstOrderOnly = false,
    this.dessertOrBakeryOnly = false,
  });

  final String code;
  final String title;
  final CouponKind kind;

  /// Percent for [CouponKind.percent], rupees for [CouponKind.flat].
  final int value;
  final int? maxDiscount;
  final int minOrder;
  final bool firstOrderOnly;
  final bool dessertOrBakeryOnly;
}

/// The six coupons, exactly as in the brief.
const allCoupons = <Coupon>[
  Coupon(code: 'WELCOME50', title: '50% off up to ₹100 on your first order (min ₹149)',
      kind: CouponKind.percent, value: 50, maxDiscount: 100, minOrder: 149, firstOrderOnly: true),
  Coupon(code: 'FREEDEL199', title: 'Free delivery on orders of ₹199+', kind: CouponKind.freeDelivery, minOrder: 199),
  Coupon(code: 'FLAT20', title: '₹20 off on orders of ₹300+', kind: CouponKind.flat, value: 20, minOrder: 300),
  Coupon(code: 'BIGFEAST', title: '₹75 off on orders of ₹600+', kind: CouponKind.flat, value: 75, minOrder: 600),
  Coupon(code: 'WEEKEND10', title: '10% off up to ₹50', kind: CouponKind.percent, value: 10, maxDiscount: 50),
  Coupon(code: 'SWEETTOOTH', title: '₹30 off desserts & bakery (min ₹150)',
      kind: CouponKind.flat, value: 30, minOrder: 150, dessertOrBakeryOnly: true),
];

Coupon? couponByCode(String? code) {
  if (code == null) return null;
  for (final c in allCoupons) {
    if (c.code == code) return c;
  }
  return null;
}

/// What a coupon is checked against.
class CouponContext {
  const CouponContext({
    required this.itemTotal,
    required this.isFirstOrder,
    required this.isDessertOrBakery,
  });

  final int itemTotal;

  /// "First order" = order history is empty.
  final bool isFirstOrder;
  final bool isDessertOrBakery;

  int get deliveryFee => deliveryFeeFor(itemTotal);
}

class CouponResult {
  const CouponResult.ok(this.coupon, this.discount) : reason = null;
  const CouponResult.no(this.coupon, this.reason) : discount = 0;

  final Coupon coupon;
  final int discount;
  final String? reason;

  bool get eligible => reason == null;
}

CouponResult evaluateCoupon(Coupon c, CouponContext ctx) {
  if (ctx.itemTotal <= 0) return CouponResult.no(c, 'Add items first');
  if (c.firstOrderOnly && !ctx.isFirstOrder) return CouponResult.no(c, 'Only on your first order');
  if (c.dessertOrBakeryOnly && !ctx.isDessertOrBakery) {
    return CouponResult.no(c, 'Only on dessert & bakery orders');
  }
  if (ctx.itemTotal < c.minOrder) return CouponResult.no(c, 'Add ₹${c.minOrder - ctx.itemTotal} more');
  switch (c.kind) {
    case CouponKind.freeDelivery:
      if (ctx.deliveryFee == 0) return CouponResult.no(c, 'Delivery is already free on this order');
      return CouponResult.ok(c, ctx.deliveryFee);
    case CouponKind.percent:
      var d = (ctx.itemTotal * c.value / 100).floor();
      if (c.maxDiscount != null) d = math.min(d, c.maxDiscount!);
      return CouponResult.ok(c, math.min(d, ctx.itemTotal));
    case CouponKind.flat:
      return CouponResult.ok(c, math.min(c.value, ctx.itemTotal));
  }
}

/// The final bill. One coupon at a time.
class Bill {
  const Bill({
    required this.itemTotal,
    required this.deliveryFee,
    required this.discount,
    required this.tip,
    this.coupon,
    this.couponProblem,
  });

  final int itemTotal;
  final int deliveryFee;
  final int discount;
  final int tip;
  final Coupon? coupon;

  /// Set when a chosen coupon no longer applies (e.g. cart changed).
  final String? couponProblem;

  int get total => itemTotal + deliveryFee + tip - discount;

  Map<String, dynamic> toJson() => {
        'itemTotal': itemTotal,
        'deliveryFee': deliveryFee,
        'discount': discount,
        'tip': tip,
        'coupon': coupon?.code,
      };
}

Bill computeBill({
  required int itemTotal,
  required bool isFirstOrder,
  required bool isDessertOrBakery,
  String? couponCode,
  int tip = 0,
}) {
  final ctx = CouponContext(
    itemTotal: itemTotal,
    isFirstOrder: isFirstOrder,
    isDessertOrBakery: isDessertOrBakery,
  );
  final coupon = couponByCode(couponCode);
  final result = coupon == null ? null : evaluateCoupon(coupon, ctx);
  return Bill(
    itemTotal: itemTotal,
    deliveryFee: ctx.deliveryFee,
    discount: result?.discount ?? 0,
    tip: tip,
    coupon: result != null && result.eligible ? coupon : null,
    couponProblem: result != null && !result.eligible ? '${coupon!.code}: ${result.reason}' : null,
  );
}
