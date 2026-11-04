import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// Ink panel used at the top of a screen (or, with [roundedTop], along the
/// bottom). Sets light status-bar icons; [child] sits inside the safe area.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
    this.radius = 24,
    this.roundedTop = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  /// Round the top corners instead of the bottom ones.
  final bool roundedTop;

  @override
  Widget build(BuildContext context) {
    final corner = Radius.circular(radius);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: roundedTop
              ? BorderRadius.vertical(top: corner)
              : BorderRadius.vertical(bottom: corner),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primarySoft],
          ),
        ),
        child: SafeArea(
          top: !roundedTop,
          bottom: roundedTop,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Back button (when there is somewhere to go back to) and a centered
/// white title, for use inside a [HeroHeader].
class HeaderTitleBar extends StatelessWidget {
  const HeaderTitleBar({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

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
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing),
        ],
      ),
    );
  }
}
