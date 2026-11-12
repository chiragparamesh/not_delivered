import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_constants.dart';
import '../../settings/data/settings_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final s = ref.read(settingsProvider);
      context.go(!s.onboarded ? AppRoutes.onboarding : (s.area == null ? AppRoutes.location : AppRoutes.home));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.maroon,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🛵', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text(AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800, fontFamily: AppTheme.headingFont)),
            const SizedBox(height: 6),
            const Text(AppConstants.tagline, style: TextStyle(color: AppColors.gold, fontSize: 16)),
          ]),
        ),
      );
}
