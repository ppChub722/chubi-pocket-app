import 'package:flutter/material.dart';

import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/tone.dart';

/// Quick create's debt result box (owner 2026-10-21, mock QuickCreateDebt):
/// three rows, the words left and the value right —
/// "ลี ตอนนี้ | รอจ่าย ฿230", "หลังบันทึก | ✓ เคลียร์ครบ",
/// "กระเป๋า test2 | −฿230" ("ไม่เปลี่ยน" when no money moves).
/// [warning] shows when the side flips (an overpayment). Words come in ready.
class DebtResultBox extends StatelessWidget {
  const DebtResultBox({
    required this.nowLabel,
    required this.afterLabel,
    required this.before,
    required this.after,
    required this.walletLabel,
    required this.walletValue,
    this.beforeColor,
    this.afterColor,
    this.warning,
    this.loading = false,
    super.key,
  });

  /// "ลี ตอนนี้".
  final String nowLabel;
  final String afterLabel;
  final String before;
  final String after;
  final Color? beforeColor;
  final Color? afterColor;

  /// "กระเป๋า test2" / "กระเป๋า".
  final String walletLabel;

  /// "−฿230" / "ไม่เปลี่ยน".
  final String walletValue;
  final String? warning;

  /// The BE preview is on its way: the numbers shown are the app's own.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    Widget row(
      String label,
      String value, {
      Color? color,
      FontWeight weight = FontWeight.w600,
      Key? key,
    }) => Row(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: text.bodySmall?.copyWith(
              color: color,
              fontWeight: weight,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
    final warning = this.warning;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: loading ? 0.6 : 1,
      child: Container(
        key: const ValueKey('debtResultBox'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            row(nowLabel, before, color: beforeColor),
            const SizedBox(height: AppSpacing.xs),
            row(afterLabel, after, color: afterColor, weight: FontWeight.w700),
            const SizedBox(height: AppSpacing.xs),
            row(
              walletLabel,
              walletValue,
              key: const ValueKey('debtResultWallet'),
            ),
            if (warning != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                warning,
                key: const ValueKey('debtResultWarning'),
                style: text.bodySmall?.copyWith(
                  color: Tone.warning.color(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
