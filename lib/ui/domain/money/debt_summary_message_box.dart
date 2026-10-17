import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../atoms/app_input.dart';
import '../../tokens/app_spacing.dart';

/// The debt person hero's embedded tool (row G, owner 2026-10-17, reference
/// §4): the summary message to send the person.
///
///   📤 ข้อความสรุปยอด · แก้ได้ก่อนส่ง
///   ┌──────────────────────────────────┐
///   │ multiline text, prefilled        │   ← edits are one-off, local
///   └──────────────────────────────────┘
///   [ 📋 คัดลอก ]  [ 📤 แชร์ ]            ← two equal full-width buttons
///
/// The text is built by the BE; this box only edits a local copy. A NEW
/// [text] from the page (after a reload) replaces the edits. [onCopy] /
/// [onShare] get the text as it is in the field now (the page does the
/// clipboard / the OS share sheet). Words come from the caller.
class DebtSummaryMessageBox extends StatefulWidget {
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

  /// "ข้อความสรุปยอด · แก้ได้ก่อนส่ง" (the 📤 is drawn here).
  final String label;
  final String copyLabel;
  final String shareLabel;
  final ValueChanged<String> onCopy;
  final ValueChanged<String> onShare;

  @override
  State<DebtSummaryMessageBox> createState() => _DebtSummaryMessageBoxState();
}

class _DebtSummaryMessageBoxState extends State<DebtSummaryMessageBox> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(DebtSummaryMessageBox old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text && _controller.text != widget.text) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '📤 ${widget.label}',
          style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppInput(
          key: const ValueKey('debtSummaryMessage'),
          controller: _controller,
          minLines: 4,
          maxLines: 10,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppButton(
                key: const ValueKey('debtSummaryCopy'),
                label: widget.copyLabel,
                icon: Icons.content_copy_rounded,
                variant: AppButtonVariant.outlined,
                expand: true,
                onPressed: () => widget.onCopy(_controller.text),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                key: const ValueKey('debtSummaryShare'),
                label: widget.shareLabel,
                icon: Icons.ios_share_rounded,
                expand: true,
                onPressed: () => widget.onShare(_controller.text),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
