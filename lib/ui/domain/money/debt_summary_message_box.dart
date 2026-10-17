import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../atoms/app_input.dart';
import '../../tokens/app_spacing.dart';

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
