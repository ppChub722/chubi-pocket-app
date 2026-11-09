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
            const SizedBox(height: PpForgeSpacing.xl),
            for (final (i, g) in groups.indexed) ...[
              if (i > 0) const SizedBox(height: PpForgeSpacing.md),
              g,
            ],
            const SizedBox(height: PpForgeSpacing.xl),
            submit,
            if (alternatives.isNotEmpty) ...[
              const SizedBox(height: PpForgeSpacing.lg),
              for (final (i, a) in alternatives.indexed) ...[
                if (i > 0) const SizedBox(height: PpForgeSpacing.lg),
                a,
              ],
            ],
            if (switchLink != null) ...[
              SizedBox(
                height: alternatives.isNotEmpty ? PpForgeSpacing.lg : PpForgeSpacing.md,
              ),
              switchLink!,
            ],
            if (footer != null) ...[
              const SizedBox(height: PpForgeSpacing.xl),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
