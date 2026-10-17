import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({this.height = 1, this.indent = 0, super.key});

  const AppDivider.row({super.key}) : height = 1, indent = AppSpacing.lg;

  final double height;

  final double indent;

  @override
  Widget build(BuildContext context) => Divider(
    height: height,
    thickness: 1,
    indent: indent,
    endIndent: indent,
    color: Theme.of(context).colorScheme.outlineVariant,
  );
}
