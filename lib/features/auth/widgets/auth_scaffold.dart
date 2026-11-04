import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/hero_header.dart';
import 'app_logo.dart';

/// Login/register layout: ink hero, with the form card overlapping it.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showHighlights = false,
  });

  final String title;
  final String subtitle;
  final Widget child;

  /// Shows what the app does under the headline (login only; the register
  /// form is long enough already).
  final bool showHighlights;

  /// How far the card reaches up into the hero.
  static const _overlap = 56.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            HeroHeader(
              radius: 32,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, _overlap + 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      const FadeSlideIn(child: _BrandLockup()),
                      const SizedBox(height: 32),
                      FadeSlideIn(
                        index: 1,
                        child: _Headline(title: title, subtitle: subtitle),
                      ),
                      if (showHighlights) ...[
                        const SizedBox(height: 24),
                        const FadeSlideIn(index: 2, child: _Highlights()),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -_overlap),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FadeSlideIn(
                      index: 3,
                      child: _FormCard(child: child),
                    ),
                  ),
                ),
              ),
            ),
            const _TrustLine(),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: 36),
        SizedBox(width: 10),
        Text(
          AppConstants.appName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _Highlights extends StatelessWidget {
  const _Highlights();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.bolt_rounded, 'Report in\na minute'),
      (Icons.notifications_active_outlined, 'Track every\nupdate'),
      (Icons.shield_outlined, 'Anonymous\nsafety reports'),
    ];
    return Row(
      spacing: 10,
      children: [
        for (final (icon, label) in items)
          Expanded(
            child: Glass(
              borderRadius: BorderRadius.circular(16),
              tint: Colors.white,
              opacity: 0.08,
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Icon(icon, size: 20, color: AppColors.accent),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 11,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TrustLine extends StatelessWidget {
  const _TrustLine();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        // The card's overlap leaves space above; pull the line up into it.
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Transform.translate(
          offset: const Offset(0, -AuthScaffold._overlap + 16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Secured with Firebase Authentication',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
