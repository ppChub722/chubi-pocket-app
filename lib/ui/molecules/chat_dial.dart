import 'package:flutter/material.dart';

import '../atoms/app_icon_button.dart';
import '../atoms/app_input.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

class ChatDial extends StatefulWidget {
  const ChatDial({
    required this.hint,
    this.tooltip,
    this.sendTooltip,
    this.closeTooltip,
    this.onSend,
    this.openWidth,
    super.key,
  });

  final String hint;
  final String? tooltip;
  final String? sendTooltip;
  final String? closeTooltip;
  final ValueChanged<String>? onSend;

  final double? openWidth;

  @override
  State<ChatDial> createState() => _ChatDialState();
}

class _ChatDialState extends State<ChatDial> {
  final _text = TextEditingController();
  bool _open = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    widget.onSend?.call(t);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width =
        widget.openWidth ??
        MediaQuery.sizeOf(context).width - AppSpacing.lg * 2;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerRight,
      child: _open
          ? SizedBox(
              width: width,
              child: Material(
                color: scheme.surface,
                elevation: 4,
                shadowColor: scheme.shadow.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      AppIconButton.close(
                        tooltip: widget.closeTooltip,
                        iconSize: 20,
                        onPressed: () => setState(() => _open = false),
                      ),
                      Expanded(
                        child: AppInput.card(
                          controller: _text,
                          autofocus: true,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          underline: false,
                          hint: widget.hint,
                        ),
                      ),
                      AppIconButton.filled(
                        icon: AppIcons.send,
                        tooltip: widget.sendTooltip,
                        size: 36,
                        onPressed: _send,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ),
                ),
              ),
            )
          : AppIconButton.fab(
              icon: AppIcons.chat,
              tooltip: widget.tooltip,
              onPressed: () => setState(() => _open = true),
            ),
    );
  }
}
