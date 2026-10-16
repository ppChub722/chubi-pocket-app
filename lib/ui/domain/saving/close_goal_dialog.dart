import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../atoms/app_card.dart';
import '../../tokens/app_spacing.dart';
import '../money/money_text.dart';

/// Where a closed goal's money goes.
enum CloseGoalChoice {
  /// Into "ยังไม่จัดสรร" — stays saved, in its wallets.
  toSpare,

  /// Back to the wallets it came from (each part to its own wallet).
  backToWallets,
}

/// One line of the "if it goes back" list.
typedef CloseGoalReturn = ({String wallet, double amount});

/// The close-goal dialog (goals v2 frame 3):
///
///   ปิดเป้าหมาย "ทริปญี่ปุ่น"
///   เงินออม ฿52,000 จะไปที่ไหน?
///   ┌ ถ้ากลับกระเป๋า ──────────┐
///   │ กสิกร         +฿40,000   │
///   │ ไทยพาณิชย์    +฿12,000   │
///   └──────────────────────────┘
///   [เข้ายังไม่จัดสรร]  [กลับกระเป๋า]  [ยกเลิก]
///
/// Every word is a param. [returns] is the per-wallet list the "back to
/// wallets" option would credit (empty = box left out). Resolves the
/// [CloseGoalChoice], or null for cancel / back / barrier (nothing happens).
Future<CloseGoalChoice?> showCloseGoalDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String returnsTitle,
  required List<CloseGoalReturn> returns,
  required String toSpareLabel,
  required String backToWalletsLabel,
  required String cancelLabel,
  String currencySymbol = '฿',
}) {
  return showDialog<CloseGoalChoice>(
    context: context,
    builder: (_) => CloseGoalDialog(
      title: title,
      message: message,
      returnsTitle: returnsTitle,
      returns: returns,
      toSpareLabel: toSpareLabel,
      backToWalletsLabel: backToWalletsLabel,
      cancelLabel: cancelLabel,
      currencySymbol: currencySymbol,
    ),
  );
}

/// The dialog itself (exposed for the hub and tests).
class CloseGoalDialog extends StatelessWidget {
  const CloseGoalDialog({
    required this.title,
    required this.message,
    required this.returnsTitle,
    required this.returns,
    required this.toSpareLabel,
    required this.backToWalletsLabel,
    required this.cancelLabel,
    this.currencySymbol = '฿',
    super.key,
  });

  final String title;
  final String message;
  final String returnsTitle;
  final List<CloseGoalReturn> returns;
  final String toSpareLabel;
  final String backToWalletsLabel;
  final String cancelLabel;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message),
          if (returns.isNotEmpty) ...[
            const SizedBox(height: PpForgeSpacing.md),
            PpForgeCard(
              color: scheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(PpForgeSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    returnsTitle,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: PpForgeSpacing.xs),
                  for (final r in returns)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: PpForgeSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.wallet,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          MoneyText(
                            r.amount,
                            tone: MoneyTone.income,
                            symbol: currencySymbol,
                            style: text.titleSmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: PpForgeSpacing.lg),
          PpForgeButton(
            label: toSpareLabel,
            expand: true,
            onPressed: () => Navigator.pop(context, CloseGoalChoice.toSpare),
          ),
          const SizedBox(height: PpForgeSpacing.sm),
          PpForgeButton(
            label: backToWalletsLabel,
            variant: PpForgeButtonVariant.outlined,
            expand: true,
            onPressed: () =>
                Navigator.pop(context, CloseGoalChoice.backToWallets),
          ),
          const SizedBox(height: PpForgeSpacing.sm),
          PpForgeButton(
            label: cancelLabel,
            variant: PpForgeButtonVariant.text,
            expand: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
