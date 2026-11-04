import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants.dart';
import '../../../core/widgets/hero_header.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SizedBox.expand(
        child: HeroHeader(
          radius: 0,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - t)),
                  child: child,
                ),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(size: 92),
                  SizedBox(height: 28),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Help make our campus safer',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 44),
                  SizedBox.square(
                    dimension: 26,
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
