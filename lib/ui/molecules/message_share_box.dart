import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/app_input.dart';
import '../tokens/app_spacing.dart';

class MessageShareBox extends StatefulWidget {
  const MessageShareBox({
    required this.text,
    required this.label,
    required this.copyLabel,
    required this.shareLabel,
    required this.onCopy,
    required this.onShare,
    this.fieldKey,
    this.copyKey,
    this.shareKey,
    super.key,
  });

  final String text;
  final String label;
  final String copyLabel;
  final String shareLabel;
  final ValueChanged<String> onCopy;
  final ValueChanged<String> onShare;
  final Key? fieldKey;
  final Key? copyKey;
  final Key? shareKey;

  @override
  State<MessageShareBox> createState() => _MessageShareBoxState();
}

class _MessageShareBoxState extends State<MessageShareBox> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(MessageShareBox old) {
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
          widget.label,
          style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppInput(
          key: widget.fieldKey,
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
                key: widget.copyKey,
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
                key: widget.shareKey,
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
