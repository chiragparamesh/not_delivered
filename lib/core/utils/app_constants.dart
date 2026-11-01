/// App-wide constants.
class AppConstants {
  static const appName = 'Not Delivered';
  static const tagline = 'Hungry? We\'ll fix that.';

  /// Feature modules from the brief. Each one lives in `lib/features/<name>/`.
  static const modules = <AppModule>[
    AppModule('Splash', 'Splash screen'),
    AppModule('Onboarding', 'Onboarding carousel'),
    AppModule('Location', 'GPS location with manual fallback'),
    AppModule('Home', 'Home with cuisine chips and filters'),
    AppModule('Search', 'Search restaurants and dishes'),
    AppModule('Restaurant', 'Restaurant menu'),
    AppModule('Cart', 'Cart with coupons and tip'),
    AppModule('Checkout', 'Checkout with simulated (demo) payment'),
    AppModule('Tracking', 'Timer-based order tracking with funny messages'),
    AppModule('Orders', 'Order history with reorder'),
    AppModule('Favorites', 'Favorites'),
    AppModule('Profile', 'Profile'),
    AppModule('Notifications', 'Notifications'),
    AppModule('Rewards', 'Scratch card, savings counter, badges, streaks, spin wheel'),
  ];
}

class AppModule {
  const AppModule(this.title, this.description);
  final String title;
  final String description;
}
