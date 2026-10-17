import 'package:flutter/material.dart';

import '../molecules/centered_form_body.dart';
import '../tokens/app_spacing.dart';

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
    this.compact = false,
    this.clearTopBar = false,
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
  final bool compact;

  final bool clearTopBar;

  @override
  Widget build(BuildContext context) {
    final gap = compact ? AppSpacing.lg : AppSpacing.xl;
    return CenteredFormBody(
      safeTop: !clearTopBar,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        clearTopBar
            ? MediaQuery.paddingOf(context).top + AppSpacing.md
            : AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: AutofillGroup(
        child: Form(
          key: formKey,
          autovalidateMode: autovalidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              brand,
              SizedBox(height: gap),
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
                  height: alternatives.isNotEmpty
                      ? AppSpacing.lg
                      : AppSpacing.md,
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
      ),
    );
  }
}
