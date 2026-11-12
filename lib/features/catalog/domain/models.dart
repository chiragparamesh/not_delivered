class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.area,
    required this.lat,
    required this.lon,
    required this.cuisines,
    required this.category,
    required this.pureVeg,
    required this.rating,
    required this.ratingCount,
    required this.priceForTwo,
    required this.baseDeliveryMins,
    required this.emoji,
    required this.color,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String area;
  final double lat;
  final double lon;
  final List<String> cuisines;

  /// "restaurant", "cafe", "bakery" or "dessert" (SWEETTOOTH needs bakery/dessert).
  final String category;
  final bool pureVeg;
  final double rating;
  final int ratingCount;
  final int priceForTwo;
  final int baseDeliveryMins;
  final String emoji;

  /// ARGB colour for the header gradient.
  final int color;
  final List<String> tags;

  bool get isDessertOrBakery => category == 'dessert' || category == 'bakery';

  factory Restaurant.fromJson(Map<String, dynamic> j) => Restaurant(
        id: j['id'] as String,
        name: j['name'] as String,
        area: j['area'] as String,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        cuisines: [for (final c in j['cuisines'] as List) c as String],
        category: j['category'] as String,
        pureVeg: j['pureVeg'] as bool,
        rating: (j['rating'] as num).toDouble(),
        ratingCount: j['ratingCount'] as int,
        priceForTwo: j['priceForTwo'] as int,
        baseDeliveryMins: j['baseDeliveryMins'] as int,
        emoji: j['emoji'] as String,
        color: int.parse('FF${(j['color'] as String).substring(1)}', radix: 16),
        tags: [for (final t in (j['tags'] as List? ?? const [])) t as String],
      );
}

class Dish {
  const Dish({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.section,
    required this.isVeg,
    required this.price,
    required this.description,
    required this.bestseller,
    required this.emoji,
  });

  final String id;
  final String restaurantId;
  final String name;
  final String section;
  final bool isVeg;
  final int price;
  final String description;
  final bool bestseller;
  final String emoji;

  factory Dish.fromJson(Map<String, dynamic> j) => Dish(
        id: j['id'] as String,
        restaurantId: j['restaurantId'] as String,
        name: j['name'] as String,
        section: j['section'] as String,
        isVeg: j['isVeg'] as bool,
        price: j['price'] as int,
        description: j['description'] as String? ?? '',
        bestseller: j['bestseller'] as bool? ?? false,
        emoji: j['emoji'] as String? ?? '🍽️',
      );
}

/// Restaurants + dishes with lookups.
class Catalog {
  Catalog(this.restaurants, this.dishes)
      : _restaurantById = {for (final r in restaurants) r.id: r},
        _dishById = {for (final d in dishes) d.id: d};

  final List<Restaurant> restaurants;
  final List<Dish> dishes;
  final Map<String, Restaurant> _restaurantById;
  final Map<String, Dish> _dishById;

  Restaurant? restaurant(String id) => _restaurantById[id];
  Dish? dish(String id) => _dishById[id];
  List<Dish> menu(String restaurantId) => [for (final d in dishes) if (d.restaurantId == restaurantId) d];

  /// Cuisines ordered by how many restaurants serve them.
  List<String> get cuisines {
    final count = <String, int>{};
    for (final r in restaurants) {
      for (final c in r.cuisines) {
        count[c] = (count[c] ?? 0) + 1;
      }
    }
    return count.keys.toList()..sort((a, b) => count[b]!.compareTo(count[a]!));
  }
}
