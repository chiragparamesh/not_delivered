import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/location/presentation/location_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/profile/presentation/photo_credits_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/restaurant/presentation/restaurant_screen.dart';
import '../../features/rewards/presentation/spin_wheel_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/tracking/presentation/tracking_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const location = '/location';
  static const home = '/home';
  static const search = '/search';
  static const orders = '/orders';
  static const profile = '/profile';
  static String restaurant(String id) => '/restaurant/$id';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static String track(String id, {bool celebrate = false}) => '/track/$id${celebrate ? '?celebrate=1' : ''}';
  static const favorites = '/favorites';
  static const notifications = '/notifications';
  static const spin = '/spin';
  static const credits = '/credits';
}

GoRouter createRouter() => GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: AppRoutes.location, builder: (_, _) => const LocationScreen()),
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => MainShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: AppRoutes.search, builder: (_, _) => const SearchScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: AppRoutes.orders, builder: (_, _) => const OrdersScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen())]),
          ],
        ),
        GoRoute(path: '/restaurant/:id', builder: (_, s) => RestaurantScreen(id: s.pathParameters['id']!)),
        GoRoute(path: AppRoutes.cart, builder: (_, _) => const CartScreen()),
        GoRoute(path: AppRoutes.checkout, builder: (_, _) => const CheckoutScreen()),
        GoRoute(
          path: '/track/:id',
          builder: (_, s) => TrackingScreen(
            orderId: s.pathParameters['id']!,
            celebrate: s.uri.queryParameters['celebrate'] == '1',
          ),
        ),
        GoRoute(path: AppRoutes.favorites, builder: (_, _) => const FavoritesScreen()),
        GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsScreen()),
        GoRoute(path: AppRoutes.spin, builder: (_, _) => const SpinWheelScreen()),
        GoRoute(path: AppRoutes.credits, builder: (_, _) => const PhotoCreditsScreen()),
      ],
    );

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      );
}
