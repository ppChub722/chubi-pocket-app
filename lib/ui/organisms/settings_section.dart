import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../atoms/app_button.dart';
import '../tokens/app/app_icons.dart';
import '../atoms/app_switch.dart';
import '../atoms/connection_scope.dart';
import '../molecules/detail_rows.dart';
import '../molecules/option_menu.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
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

class SettingDropdownRow extends StatelessWidget {
  const SettingDropdownRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.helper,
    this.leading,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? helper;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => DetailRow(
    leading: leading,
    label: label,
    helper: helper,
    onTap: onTap,
    trailing: AppButton(
      label: value,
      variant: AppButtonVariant.outlined,
      size: AppButtonSize.control,
      trailingIcon: AppIcons.dropdown,
      onPressed: onTap,
    ),
  );
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

  /// Shown instead of [summary] (e.g. an [IconStackCount]).
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
    super.key,
  });

  final String label;

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
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    _syncText();
    _focus.addListener(() {
      if (!_focus.hasFocus && _typing) _commit();
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
    final cb = widget.onSelected;
    if (value != null && cb != null) {
      cb(value);
    } else {
      _syncText();
    }
  }

  Widget _field(SettingMenuCustom<T> custom, VoidCallback toggle) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyLarge;
    OutlineInputBorder edge(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: c),
    );
    return SizedBox(
      width: 124,
      child: TextField(
        controller: _text,
        focusNode: _focus,
        keyboardType: custom.keyboardType,
        inputFormatters: custom.inputFormatters,
        textAlign: TextAlign.end,
        textInputAction: TextInputAction.done,
        readOnly: widget.onSelected == null,
        style: style,
        onSubmitted: (_) => _commit(),
        decoration: InputDecoration(
          isDense: true,
          hintText: custom.hint,
          hintStyle: style?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          suffixText: custom.suffix,
          contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            0,
            AppSpacing.sm,
          ),
          suffixIcon: IconButton(
            onPressed: widget.onSelected == null ? null : toggle,
            icon: const Icon(AppIcons.dropdown),
            visualDensity: VisualDensity.compact,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          enabledBorder: edge(scheme.outline),
          focusedBorder: edge(scheme.primary),
          border: edge(scheme.outline),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final custom = widget.custom;
    final cb = widget.onSelected;
    return OptionMenuAnchor<T>(
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
      builder: (context, toggle) => DetailRow(
        label: widget.label,
        helper: widget.helper,
        onTap: cb == null || _typing ? null : toggle,
        trailing: custom != null && (_typing || _isCustomValue)
            ? _field(custom, toggle)
            : AppButton(
                label: widget.value,
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.control,
                trailingIcon: AppIcons.dropdown,
                onPressed: cb == null ? null : toggle,
              ),
      ),
    );
  }
}
