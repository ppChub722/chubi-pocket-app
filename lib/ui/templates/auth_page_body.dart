import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import 'brand_screen.dart';

class AuthPageBody extends StatelessWidget {
  const AuthPageBody({
    required this.brand,
    required this.groups,
    required this.submit,
    this.alternatives = const [],
    this.switchLink,
    this.footer,
    this.formKey,
    this.autovalidateMode,
    super.key,
  });

  final Widget brand;
  final List<Widget> groups;
  final Widget submit;
  final List<Widget> alternatives;
  final Widget? switchLink;
  final Widget? footer;
  final GlobalKey<FormState>? formKey;
  final AutovalidateMode? autovalidateMode;
  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: formKey,
        autovalidateMode: autovalidateMode,
        child: BrandScreen(
          header: brand,
          children: [
            const SizedBox(height: AppSpacing.xl),
            for (final (i, g) in groups.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              g,
            ],
            const SizedBox(height: AppSpacing.xl),
            submit,
            if (alternatives.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              for (final (i, a) in alternatives.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.lg),
                a,
              ],
            ],
            if (switchLink != null) ...[
              SizedBox(
                height: alternatives.isNotEmpty ? AppSpacing.lg : AppSpacing.md,
              ),
              switchLink!,
            ],
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.xl),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
