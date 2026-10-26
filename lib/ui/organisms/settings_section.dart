import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../atoms/app_button.dart';
import '../atoms/ui_config.dart';
import '../tokens/app/app_icons.dart';
import '../atoms/app_switch.dart';
import '../atoms/connection_scope.dart';
import '../molecules/app_snackbar.dart';
import '../molecules/detail_rows.dart';
import '../molecules/option_menu.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import '../tokens/tone.dart';
import 'option_sheet.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    this.description,
    this.first = false,
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> children;
  final bool first;

  @override
  Widget build(BuildContext context) => SectionCard(
    first: first,
    title: title,
    description: description,
    children: children,
  );
}

/// A setting that saves itself in VIEW mode, no ✏️ needed (owner 2026-10-21):
/// a flip or a pick shows at once and makes ONE [save] call. [save] returns
/// false when the person backed out (e.g. closed a sheet it opened): the old
/// value comes back quietly. A throw also brings the old value back, with
/// [failedMessage] and a retry. While a save runs the row ignores new input.
///
/// [builder] draws any settings row with the value to show and the change
/// callback (null when read-only):
///
///     LiveSetting<bool>(
///       value: wallet.trackBalance,
///       save: (on) => saveTrack(on),
///       failedMessage: (e) => messageOf(e),
///       builder: (context, value, onChanged) => SettingToggleRow(
///         label: …, value: value, onChanged: onChanged),
///     )
class LiveSetting<T> extends StatefulWidget {
  const LiveSetting({
    required this.value,
    required this.save,
    required this.failedMessage,
    required this.builder,
    super.key,
  });

  /// The saved value (from the page's data).
  final T value;

  /// Null = read-only (the row gets no change callback).
  final Future<bool> Function(T value)? save;
  final String Function(Object error) failedMessage;
  final Widget Function(
    BuildContext context,
    T value,
    ValueChanged<T>? onChanged,
  )
  builder;

  @override
  State<LiveSetting<T>> createState() => _LiveSettingState<T>();
}

class _LiveSettingState<T> extends State<LiveSetting<T>> {
  /// The value picked but not yet confirmed by the page's data.
  T? _shown;
  bool _hasShown = false;
  bool _busy = false;

  T get _value => _hasShown ? _shown as T : widget.value;

  @override
  void didUpdateWidget(covariant LiveSetting<T> old) {
    super.didUpdateWidget(old);
    // The page's data moved (the save landed, or a refresh): it wins.
    if (old.value != widget.value && !_busy) _hasShown = false;
  }

  Future<void> _change(T next) async {
    final save = widget.save;
    if (save == null || _busy || next == _value) return;
    setState(() {
      _shown = next;
      _hasShown = true;
      _busy = true;
    });
    var saved = false;
    Object? error;
    try {
      saved = await save(next);
    } catch (e) {
      error = e;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      // Kept on success until the page's data catches up (no flicker back).
      if (!saved) _hasShown = false;
    });
    if (error != null) {
      showAppSnackBar(
        context,
        widget.failedMessage(error),
        tone: Tone.danger,
        actionLabel: UiConfig.stringsOf(context).retry,
        onAction: () => _change(next),
      );
    }
  }

  // The row stays enabled while saving (no grey flash); [_change] ignores
  // taps until the save is done.
  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _value, widget.save == null ? null : _change);
}

class SettingToggleRow extends StatelessWidget {
  const SettingToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.caption,
    this.submits = true,
    super.key,
  });

  final String label;
  final String? caption;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool submits;

  @override
  Widget build(BuildContext context) {
    final off =
        onChanged == null || (submits && ConnectionScope.isOffline(context));
    final cb = off ? null : onChanged;
    return DetailRow(
      label: label,
      helper: caption,
      onTap: cb == null ? null : () => cb(!value),
      trailing: AppSwitch(value: value, onChanged: cb, semanticLabel: label),
    );
  }
}

/// A settings row whose value is a ▾ button that opens a menu of [options]
/// right under that button. Tapping anywhere on the row opens it too. A null
/// [onSelected] makes the row read-only.
class SettingDropdownRow<T> extends StatefulWidget {
  const SettingDropdownRow({
    required this.label,
    required this.value,
    this.options = const [],
    this.selected,
    this.onSelected,
    this.helper,
    this.leading,
    this.icon,
    this.iconColor,
    this.submits = true,
    super.key,
  });

  final String label;
  final String value;
  final List<SheetOption<T>> options;
  final T? selected;
  final ValueChanged<T>? onSelected;
  final String? helper;
  final Widget? leading;

  /// A pick is saved at once, so the row is read-only while offline.
  final bool submits;

  /// The chosen value's icon, in the button before its label.
  final IconData? icon;

  /// The chosen value's own colour (e.g. a type's), for [icon] only.
  final Color? iconColor;

  @override
  State<SettingDropdownRow<T>> createState() => _SettingDropdownRowState<T>();
}

class _SettingDropdownRowState<T> extends State<SettingDropdownRow<T>> {
  final _menu = MenuController();

  void _toggle() => _menu.isOpen ? _menu.close() : _menu.open();

  @override
  Widget build(BuildContext context) {
    final cb = widget.submits && ConnectionScope.isOffline(context)
        ? null
        : widget.onSelected;
    return DetailRow(
      leading: widget.leading,
      label: widget.label,
      helper: widget.helper,
      onTap: cb == null ? null : _toggle,
      trailing: OptionMenuAnchor<T>(
        controller: _menu,
        alignEnd: true,
        options: widget.options,
        selected: widget.selected,
        onSelected: (v) => cb?.call(v),
        builder: (context, toggle) => AppButton(
          label: widget.value,
          icon: widget.icon,
          iconColor: widget.iconColor,
          variant: AppButtonVariant.outlined,
          size: AppButtonSize.control,
          trailingIcon: AppIcons.dropdown,
          onPressed: cb == null ? null : toggle,
        ),
      ),
    );
  }
}

class SettingSwitchViewRow extends StatelessWidget {
  const SettingSwitchViewRow({
    required this.label,
    required this.value,
    this.onLongPress,
    this.caption,
    super.key,
  });

  final String label;
  final String? caption;
  final bool value;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onLongPress: onLongPress,
    child: DetailRow(
      label: label,
      helper: caption,
      trailing: IgnorePointer(
        child: AppSwitch(value: value, onChanged: (_) {}, semanticLabel: label),
      ),
    ),
  );
}

class SettingSummaryRow extends StatelessWidget {
  const SettingSummaryRow({
    required this.label,
    required this.onTap,
    this.summary,
    this.error,
    this.trailing,
    super.key,
  });

  final String label;
  final String? summary;
  final VoidCallback? onTap;

  final String? error;

  /// Shown instead of [summary].
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => DetailRow(
    label: label,
    onTap: onTap,
    error: error,
    showChevron: true,
    trailing:
        trailing ??
        (summary == null
            ? null
            : Text(summary!, maxLines: 1, overflow: TextOverflow.ellipsis)),
  );
}

/// What a [SettingMenuRow] lets people type when none of its options fits.
class SettingMenuCustom<T> {
  const SettingMenuCustom({
    required this.hint,
    required this.parse,
    this.suffix,
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
    this.format,
  });

  final String hint;
  final String? suffix;

  /// A value as the field shows it; null = its toString().
  final String Function(T value)? format;

  /// The typed text as a value; null = not one (nothing changes).
  final T? Function(String text) parse;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
}

/// A settings row whose value opens a menu of [options] (the dropdown row with
/// its [OptionMenuAnchor] built in). With [custom] the menu ends in an empty
/// input box; choosing it turns the value into a field to type any value. A
/// typed value stays shown in that field, and the field keeps its ▾, so the
/// menu is always one tap away.
class SettingMenuRow<T> extends StatefulWidget {
  const SettingMenuRow({
    required this.label,
    required this.value,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.custom,
    this.helper,
    this.note,
    this.compact = false,
    this.submits = true,
    super.key,
  });

  final String label;

  /// A pick is saved at once, so the row is read-only while offline.
  final bool submits;

  /// Small words after the value, e.g. "= ฿1,600" for a percentage.
  final String? note;

  /// A bare line (label, value, note) without the settings-row inset, for use
  /// inside a hero.
  final bool compact;

  /// The current value as the button shows it.
  final String value;
  final List<SheetOption<T>> options;
  final T? selected;

  /// Null = read-only.
  final ValueChanged<T>? onSelected;
  final SettingMenuCustom<T>? custom;
  final String? helper;

  @override
  State<SettingMenuRow<T>> createState() => _SettingMenuRowState<T>();
}

class _SettingMenuRowState<T> extends State<SettingMenuRow<T>> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _menu = MenuController();
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    _syncText();
    _focus.addListener(() {
      if (!_focus.hasFocus && _typing) {
        _commit();
      } else if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant SettingMenuRow<T> old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus) _syncText();
  }

  /// The field shows the value while it is a typed one (none of the options).
  void _syncText() {
    final v = widget.selected;
    final format = widget.custom?.format;
    _text.text = v == null || !_isCustomValue
        ? ''
        : (format == null ? '$v' : format(v));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  ValueChanged<T>? get _onSelected =>
      widget.submits && ConnectionScope.isOffline(context)
      ? null
      : widget.onSelected;

  bool get _isCustomValue {
    final v = widget.selected;
    return v != null && !widget.options.any((o) => o.value == v);
  }

  void _startTyping() {
    setState(() {
      _typing = true;
      _syncText();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _commit() {
    final value = widget.custom?.parse(_text.text.trim());
    setState(() => _typing = false);
    final cb = _onSelected;
    if (value != null && cb != null) {
      cb(value);
    } else {
      _syncText();
    }
  }

  /// The typed value in the same pill as the menu button (size, edge, words,
  /// ▾), only the number is an input with no box of its own.
  Widget _field(SettingMenuCustom<T> custom, VoidCallback toggle) {
    final scheme = Theme.of(context).colorScheme;
    const size = ChipSize.control;
    final style = size
        .textStyle(context)
        ?.copyWith(
          fontWeight: ChipSize.chipWeight,
          color: scheme.primary,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    final focused = _focus.hasFocus;
    final enabled = _onSelected != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? _focus.requestFocus : null,
      child: Container(
        height: size.heightOf(context),
        padding: EdgeInsetsDirectional.only(start: size.padding),
        decoration: ShapeDecoration(
          shape: StadiumBorder(
            side: BorderSide(
              color: focused ? scheme.primary : scheme.outline,
              width: focused ? 1.5 : 1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IntrinsicWidth(
              child: TextField(
                controller: _text,
                focusNode: _focus,
                keyboardType: custom.keyboardType,
                inputFormatters: custom.inputFormatters,
                textAlign: TextAlign.end,
                textInputAction: TextInputAction.done,
                readOnly: !enabled,
                style: style,
                onSubmitted: (_) => _commit(),
                decoration: InputDecoration.collapsed(
                  hintText: custom.hint,
                  hintStyle: style?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            if (custom.suffix case final suffix?) Text(suffix, style: style),
            InkResponse(
              onTap: enabled ? toggle : null,
              radius: 18,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: size.gap,
                  end: size.padding,
                ),
                child: Icon(
                  AppIcons.dropdown,
                  size: size.icon + 4,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final custom = widget.custom;
    final cb = _onSelected;
    // The menu hangs under the value, not under the whole row.
    final value = OptionMenuAnchor<T>(
      controller: _menu,
      // The value ends the row unless a note follows it.
      alignEnd: widget.note == null,
      options: widget.options,
      selected: widget.selected,
      onSelected: (v) {
        if (_typing) setState(() => _typing = false);
        cb?.call(v);
      },
      custom: custom == null || cb == null
          ? null
          : OptionMenuCustom(
              hint: custom.hint,
              suffix: custom.suffix,
              selectedLabel: _isCustomValue ? widget.value : null,
              onChoose: _startTyping,
            ),
      builder: (context, toggle) => custom != null && (_typing || _isCustomValue)
          ? _field(custom, toggle)
          : AppButton(
              label: widget.value,
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.control,
              trailingIcon: AppIcons.dropdown,
              onPressed: cb == null ? null : toggle,
            ),
    );
    final note = widget.note;
    // As big as the value on the button beside it.
    final noteText = note == null
        ? null
        : Text(
            note,
            maxLines: 1,
            style: ChipSize.control
                .textStyle(context)
                ?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          );
    if (widget.compact) {
      return Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          value,
          if (noteText != null) ...[
            const SizedBox(width: AppSpacing.sm),
            noteText,
          ],
        ],
      );
    }
    return DetailRow(
      label: widget.label,
      helper: widget.helper,
      onTap: cb == null || _typing
          ? null
          : () => _menu.isOpen ? _menu.close() : _menu.open(),
      trailing: noteText == null
          ? value
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                value,
                const SizedBox(width: AppSpacing.sm),
                noteText,
              ],
            ),
    );
  }
}
