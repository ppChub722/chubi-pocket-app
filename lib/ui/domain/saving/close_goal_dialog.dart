import 'package:flutter/material.dart';

import 'package:pp_forge_core/ui.dart';
import '../money/money_text.dart';

enum CloseGoalChoice { toSpare, backToWallets }

typedef CloseGoalReturn = ({String wallet, double amount});

Future<CloseGoalChoice?> showCloseGoalDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String returnsTitle,
  required List<CloseGoalReturn> returns,
  required String toSpareLabel,
  required String backToWalletsLabel,
  required String cancelLabel,
  String? currencySymbol,
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

class CloseGoalDialog extends StatelessWidget {
  const CloseGoalDialog({
    required this.title,
    required this.message,
    required this.returnsTitle,
    required this.returns,
    required this.toSpareLabel,
    required this.backToWalletsLabel,
    required this.cancelLabel,
    this.currencySymbol,
    super.key,
  });

  final String title;
  final String message;
  final String returnsTitle;
  final List<CloseGoalReturn> returns;
  final String toSpareLabel;
  final String backToWalletsLabel;
  final String cancelLabel;
  final String? currencySymbol;

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
            kind: ButtonIconKind.cancel,
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
