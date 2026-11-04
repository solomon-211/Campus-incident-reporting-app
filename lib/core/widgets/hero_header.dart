import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// Ink panel at the top of a screen, with light status-bar icons. [child]
/// sits inside the safe area.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
          gradient: AppGradients.ink,
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Back button (when there's somewhere to go back to) and a centered white
/// title, for use inside a [HeroHeader].
class HeaderTitleBar extends StatelessWidget {
  const HeaderTitleBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (Navigator.of(context).canPop())
            const Align(
              alignment: Alignment.centerLeft,
              child: BackButton(color: Colors.white),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
