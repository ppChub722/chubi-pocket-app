import 'package:flutter/material.dart';

import '../../molecules/message_share_box.dart';

/// The debt summary message (copy / share) — a [MessageShareBox] with the
/// debt page's keys.
class DebtSummaryMessageBox extends StatelessWidget {
  const DebtSummaryMessageBox({
    required this.text,
    required this.label,
    required this.copyLabel,
    required this.shareLabel,
    required this.onCopy,
    required this.onShare,
    super.key,
  });

  final String text;
  final String label;
  final String copyLabel;
  final String shareLabel;
  final ValueChanged<String> onCopy;
  final ValueChanged<String> onShare;

  @override
  Widget build(BuildContext context) => MessageShareBox(
    text: text,
    label: '📤 $label',
    copyLabel: copyLabel,
    shareLabel: shareLabel,
    onCopy: onCopy,
    onShare: onShare,
    fieldKey: const ValueKey('debtSummaryMessage'),
    copyKey: const ValueKey('debtSummaryCopy'),
    shareKey: const ValueKey('debtSummaryShare'),
  );
}
