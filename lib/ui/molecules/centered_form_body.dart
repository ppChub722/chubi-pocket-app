import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class CenteredFormBody extends StatelessWidget {
  const CenteredFormBody({
    required this.child,
    this.maxWidth = 400,
    this.safeTop = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xl,
    ),
    super.key,
  });

  final Widget child;
  final double maxWidth;

  final bool safeTop;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: safeTop,
    child: Center(
      child: SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    ),
  );
}
