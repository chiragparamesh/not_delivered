import 'package:flutter_test/flutter_test.dart';
import 'package:not_delivered/features/cart/domain/coupons.dart';

CouponResult ev(String code, int total, {bool first = false, bool sweet = false}) => evaluateCoupon(
      couponByCode(code)!,
      CouponContext(itemTotal: total, isFirstOrder: first, isDessertOrBakery: sweet),
    );

void main() {
  test('delivery fee: ₹30 below ₹199, free from ₹199', () {
    expect(deliveryFeeFor(198), 30);
    expect(deliveryFeeFor(199), 0);
    expect(deliveryFeeFor(500), 0);
    expect(deliveryFeeFor(0), 0);
  });

  group('WELCOME50 (50%, max ₹100, min ₹149, first order)', () {
    test('half off below the cap', () => expect(ev('WELCOME50', 150, first: true).discount, 75));
    test('capped at ₹100', () => expect(ev('WELCOME50', 500, first: true).discount, 100));
    test('min ₹149 inclusive', () {
      expect(ev('WELCOME50', 149, first: true).eligible, isTrue);
      expect(ev('WELCOME50', 148, first: true).reason, 'Add ₹1 more');
    });
    test('first order only', () => expect(ev('WELCOME50', 500).reason, 'Only on your first order'));
  });

  test('FREEDEL199 waives the fee only when there is one (as written in the brief)', () {
    expect(ev('FREEDEL199', 150).reason, 'Add ₹49 more');
    // At ₹199+ delivery is already free, so the coupon has nothing to waive.
    expect(ev('FREEDEL199', 250).reason, 'Delivery is already free on this order');
  });

  test('FLAT20 needs ₹300', () {
    expect(ev('FLAT20', 299).eligible, isFalse);
    expect(ev('FLAT20', 300).discount, 20);
  });

  test('BIGFEAST needs ₹600', () {
    expect(ev('BIGFEAST', 599).eligible, isFalse);
    expect(ev('BIGFEAST', 600).discount, 75);
  });

  test('WEEKEND10: 10% capped at ₹50, no minimum', () {
    expect(ev('WEEKEND10', 120).discount, 12);
    expect(ev('WEEKEND10', 900).discount, 50);
  });

  test('SWEETTOOTH: dessert/bakery only, min ₹150', () {
    expect(ev('SWEETTOOTH', 200).reason, 'Only on dessert & bakery orders');
    expect(ev('SWEETTOOTH', 149, sweet: true).eligible, isFalse);
    expect(ev('SWEETTOOTH', 150, sweet: true).discount, 30);
  });

  group('bill', () {
    test('items + delivery + tip - coupon', () {
      final b = computeBill(itemTotal: 180, isFirstOrder: true, isDessertOrBakery: false, couponCode: 'WELCOME50', tip: 20);
      expect(b.deliveryFee, 30);
      expect(b.discount, 90);
      expect(b.total, 180 + 30 + 20 - 90);
      expect(b.coupon?.code, 'WELCOME50');
    });

    test('a coupon that stops applying is reported, not applied', () {
      final b = computeBill(itemTotal: 250, isFirstOrder: true, isDessertOrBakery: false, couponCode: 'FLAT20');
      expect(b.discount, 0);
      expect(b.coupon, isNull);
      expect(b.couponProblem, 'FLAT20: Add ₹50 more');
    });

    test('one coupon at a time: the bill uses exactly the chosen code', () {
      final b = computeBill(itemTotal: 700, isFirstOrder: false, isDessertOrBakery: false, couponCode: 'FLAT20');
      expect(b.discount, 20); // BIGFEAST would be better, but only the applied one counts
    });
  });
}
