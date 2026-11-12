import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/data/settings_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  var _index = 0;

  static const slides = [
    ('🍛', 'All of Bengaluru, one app', 'Dosas in Jayanagar, biryani in BTM, kulfi in Jayanagar again. 25 kitchens, 190+ dishes.'),
    ('🛵', 'Live tracking, zero calories', 'Watch your rider battle Silk Board in real time. Spoiler: the food is imaginary.'),
    ('🎁', 'Coupons, scratch cards, streaks', 'Save money you never spent. Spin daily, unlock badges, brag responsibly.'),
  ];

  void _finish() {
    ref.read(settingsProvider.notifier).finishOnboarding();
    context.go(AppRoutes.location);
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _finish, child: const Text('Skip')),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                for (final (emoji, title, body) in slides)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 180,
                        height: 180,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.25), shape: BoxShape.circle),
                        child: Text(emoji, style: const TextStyle(fontSize: 88)),
                      ),
                      const SizedBox(height: 32),
                      Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                    ]),
                  ),
              ],
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: i == _index ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _index ? AppColors.maroon : AppColors.maroon.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: FilledButton(
              key: const Key('onboarding-next'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              onPressed: last
                  ? _finish
                  : () => _pages.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              child: Text(last ? 'Get started' : 'Next'),
            ),
          ),
        ]),
      ),
    );
  }
}
