import 'package:flutter/material.dart';

import '../atoms/app_avatar.dart';
import '../atoms/app_chip.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_input.dart';
import '../atoms/app_input_type.dart';
import 'amount_input.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/icon_size.dart';

class SplitRow extends StatelessWidget {
  const SplitRow({
    required this.avatar,
    required this.name,
    required this.amount,
    this.trailing,
    this.nameTrailing,
    super.key,
  });

  static const double height = 44;

  static const double avatarSize = 36;

  static const double trailingSlot = 40;

  final Widget avatar;
  final Widget name;
  final Widget amount;
  final Widget? trailing;

  /// Chips right after the name ("จ่าย", "คืนแล้ว").
  final Widget? nameTrailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        height: height,
        child: Align(alignment: Alignment.centerLeft, child: avatar),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: nameTrailing == null
            ? name
            : Row(
                children: [
                  Flexible(child: name),
                  const SizedBox(width: AppSpacing.xs),
                  nameTrailing!,
                ],
              ),
      ),
      const SizedBox(width: AppSpacing.xs),
      amount,
      SizedBox(
        width: trailingSlot,
        child: Center(child: trailing),
      ),
    ],
  );
}

class SplitRowAction extends StatelessWidget {
  const SplitRowAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  static const double circle = 32;

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: SplitRow.trailingSlot / 2,
        child: Container(
          width: circle,
          height: circle,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? scheme.primaryContainer : null,
          ),
          child: AppIcon(
            icon,
            size: AppIconSize.md,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class SplitRowName extends StatelessWidget {
  const SplitRowName.muted(this.text, {super.key})
    : _kind = _Kind.muted,
      controller = null,
      focusNode = null,
      hint = null,
      autofocus = false,
      maxLength = 100,
      onChanged = null,
      onTap = null;

  const SplitRowName.input({
    required TextEditingController this.controller,
    required this.focusNode,
    this.hint,
    this.autofocus = false,
    this.maxLength = 100,
    this.onChanged,
    super.key,
  }) : _kind = _Kind.input,
       text = '',
       onTap = null;

  const SplitRowName.picked(this.text, {this.onTap, super.key})
    : _kind = _Kind.picked,
      controller = null,
      focusNode = null,
      hint = null,
      autofocus = false,
      maxLength = 100,
      onChanged = null;

  final _Kind _kind;
  final String text;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final bool autofocus;
  final int maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  static const double textInset = 16;

  static const double frameHeight = 40;

  static TextStyle? style(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (_kind) {
      case _Kind.muted:
        return SizedBox(
          height: SplitRow.height,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: textInset),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      case _Kind.input:
        return SizedBox(
          height: SplitRow.height,
          child: Center(
            child: AppInput(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              maxLength: maxLength,
              textInputAction: TextInputAction.done,
              style: style(context),
              dense: true,
              hint: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              onChanged: onChanged,
            ),
          ),
        );
      case _Kind.picked:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: SplitRow.height,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                constraints: const BoxConstraints(minHeight: frameHeight),
                padding: const EdgeInsets.symmetric(
                  horizontal: textInset,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppAvatar.colorFor(text).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style(context),
                ),
              ),
            ),
          ),
        );
    }
  }
}

enum _Kind { muted, input, picked }

/// A row's amount box (the split rows' look, now in the kit): [value] in, the
/// parsed number out on every keystroke. [auto] greys the number while the
/// row fills itself (the "A" toggle); typing calls [onChanged] as usual.
class ShareAmountField extends StatefulWidget {
  const ShareAmountField({
    required this.value,
    required this.onChanged,
    this.auto = false,
    this.enabled = true,
    this.hint = '0',
    super.key,
  });

  final double? value;
  final ValueChanged<double?>? onChanged;
  final bool auto;
  final bool enabled;

  /// While empty ("รอใส่ยอด" on a recurring row).
  final String hint;

  static const double width = 104;

  @override
  State<ShareAmountField> createState() => _ShareAmountFieldState();
}

class _ShareAmountFieldState extends State<ShareAmountField> {
  late final TextEditingController _amount = TextEditingController(
    text: _formatted(widget.value),
  );
  final _focus = FocusNode();

  static String _formatted(double? v) => v == null ? '' : AmountInput.format(v);

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  /// Leaving the box shows the number it stands for (a cleared box whose
  /// value fills itself, e.g. "the whole bill").
  void _onFocus() {
    if (!_focus.hasFocus) _sync();
  }

  void _sync() {
    if (AmountInput.parse(_amount.text) != widget.value) {
      _amount.text = _formatted(widget.value);
    }
  }

  @override
  void didUpdateWidget(covariant ShareAmountField old) {
    super.didUpdateWidget(old);
    // The number moved from outside (auto, หารเท่ากัน): show it, unless the
    // person is typing this very value, or just cleared the box to retype.
    if (_focus.hasFocus && _amount.text.trim().isEmpty) return;
    _sync();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _amount.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: widget.auto ? scheme.onSurfaceVariant : null,
    );
    final onChanged = widget.onChanged;
    return SizedBox(
      width: ShareAmountField.width,
      height: SplitRow.height,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AppInput.card(
          controller: _amount,
          focusNode: _focus,
          type: AppInputType.amount,
          style: style,
          hint: widget.hint,
          enabled: widget.enabled && onChanged != null,
          onChanged: onChanged == null
              ? null
              : (v) => onChanged(AmountInput.parse(v)),
        ),
      ),
    );
  }
}

/// "+ เลือกคนจ่าย" in a share row's name slot: a dashed primary chip, at the
/// start, level with a [SplitRow].
class SplitPickChip extends StatelessWidget {
  const SplitPickChip({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: SplitRow.height),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: AppChip(
        icon: AppIcons.add,
        label: label,
        tone: AppChipTone.primary,
        selected: true,
        dashed: true,
        onTap: onTap,
      ),
    ),
  );
}
