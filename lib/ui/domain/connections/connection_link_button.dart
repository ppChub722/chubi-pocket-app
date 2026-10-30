import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../tokens/color_contrast.dart';

/// The big `เชื่อม <App>` button of an unlinked connection page (0.4.2 1b):
/// a full-width primary [AppButton] filled with the app's [brand] colour,
/// white text, as the apps' own buttons are (owner mock 2026-10-28). A brand
/// too light for white text (Telegram #26A5E4 is ~2.6:1) is darkened until
/// the label reads at [minContrast] ([fillFor]).
class ConnectionLinkButton extends StatelessWidget {
  const ConnectionLinkButton({
    required this.label,
    required this.onPressed,
    this.brand,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Null = the theme's primary.
  final Color? brand;
  final bool loading;

  static const Color labelColor = Color(0xFFFFFFFF);

  /// WCAG AA for normal text.
  static const double minContrast = 4.5;

  /// The fill drawn for [brand]: the brand itself when white text reads on
  /// it, else the nearest darker shade that does.
  static Color fillFor(Color brand) =>
      ensureContrast(brand, labelColor, min: minContrast);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = AppButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      expand: true,
      size: AppButtonSize.large,
      submits: true,
    );
    final brand = this.brand;
    if (brand == null) return button;
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: fillFor(brand),
          onPrimary: labelColor,
        ),
      ),
      child: button,
    );
  }
}
