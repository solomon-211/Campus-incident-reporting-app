import 'package:flutter/material.dart';

/// Text selection without the teardrop handles under the selected text.
/// Selecting, copying and pasting still work; only the handles are hidden.
class _NoHandleSelectionControls extends MaterialTextSelectionControls {
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) => const SizedBox.shrink();

  @override
  Size getHandleSize(double textLineHeight) => Size.zero;
}

final noHandleSelectionControls = _NoHandleSelectionControls();
