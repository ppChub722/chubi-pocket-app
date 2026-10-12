import 'package:flutter/material.dart';

import '../atoms/app_avatar.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_input.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/icon_size.dart';

/// One row of a split — `avatar | name | amount | trailing` — with the same
/// slots on every row (me, a typed name, a contact, a linked person) so the
/// amounts, their underlines and the trailing icons line up (owner
/// 2026-10-12). The trailing slot is a FIXED [trailingSlot] wide whatever it
/// holds (a [SplitRowAction], or nothing).
///
/// Generic: the caller builds the pieces — the avatar (with whatever it
/// reserves for a 🔗), a [SplitRowName], the amount box.
class SplitRow extends StatelessWidget {
  const SplitRow({
    required this.avatar,
    required this.name,
    required this.amount,
    this.trailing,
    super.key,
  });

  /// A split row's height — a comfortable tap target (owner 2026-10-11).
  static const double height = 44;

  /// The avatar's size.
  static const double avatarSize = 36;

  /// The trailing slot's width: the ✕ or ⟳ is centred in it.
  static const double trailingSlot = 40;

  final Widget avatar;
  final Widget name;
  final Widget amount;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        height: height,
        child: Align(alignment: Alignment.centerLeft, child: avatar),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: name),
      const SizedBox(width: AppSpacing.xs),
      amount,
      SizedBox(
        width: trailingSlot,
        child: Center(child: trailing),
      ),
    ],
  );
}

/// The trailing icon of a [SplitRow]: one icon size for all. [selected] = a
/// tinted circle (fits inside the slot) — the "auto" switch ON; unselected
/// and the ✕ are the plain icon.
class SplitRowAction extends StatelessWidget {
  const SplitRowAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  /// The tinted circle: inside [SplitRow.trailingSlot].
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

/// The name cell of a [SplitRow], by who it is:
/// - [SplitRowName.muted] — me ("ส่วนของฉัน"): lighter weight, muted colour
///   (no italic: the Thai font has none);
/// - [SplitRowName.input] — level 1, a typed name: an outlined [AppInput],
///   clearly typeable;
/// - [SplitRowName.picked] — level 2 / 3, a contact: the name on a faint
///   highlight in the avatar's colour; a tap opens the picker.
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

  /// Where a name's text starts inside its cell — the outlined input's own
  /// inner inset (measured, test/ui/split_row_align_test.dart), so "my
  /// share", a typed name and a contact's highlighted name all start at the
  /// same x.
  static const double textInset = 16;

  /// The height of a name's box: the typed name's framed input and a
  /// contact's highlight are the SAME height (so the looks line up row to
  /// row), growing together with the text scale.
  static const double frameHeight = 40;

  /// Every name in the normal weight.
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
              // Italic + muted sets "my share" apart from the names (the
              // Thai font has no true italic: Flutter slants it).
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
