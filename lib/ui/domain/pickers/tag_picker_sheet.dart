import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../atoms/app_chip.dart';
import '../../atoms/app_input.dart';
import '../../molecules/empty_view.dart';
import '../../organisms/app_sheet.dart';
import '../../organisms/picker_sheet.dart';
import '../../templates/form_sheet.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app/text_limits.dart';
import '../../tokens/app_spacing.dart';
import '../icons/color_token.dart';
import '../icons/icon_code.dart';
import '../icons/icon_registry.dart';

@immutable
class TagPickerItem {
  const TagPickerItem({required this.id, required this.name, this.iconCode});

  final String id;
  final String name;
  final IconCode? iconCode;
}

@immutable
class TagPickerData {
  const TagPickerData({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  final List<TagPickerItem> items;

  final bool loading;

  final Object? error;
}

/// The words of the tag picker — the caller passes its localised strings (the
/// kit never reads the app's l10n).
class TagPickerLabels {
  const TagPickerLabels({
    required this.title,
    required this.searchHint,
    required this.ok,
    required this.addTag,
    required this.createNamed,
    required this.empty,
    required this.noMatch,
    required this.nameSave,
    required this.nameHint,
  });

  final String title;
  final String searchHint;

  final String ok;

  /// The create row without a typed name; also the name sheet's title.
  final String addTag;

  final String Function(String name) createNamed;

  final String empty;
  final String noMatch;

  final String nameSave;
  final String nameHint;
}

Color _tagColor(IconCode? code, AppColors palette) =>
    (code?.iconColors.isNotEmpty ?? false)
    ? resolveColor(code!.iconColors.first, palette)
    : palette.primary;

Future<Set<String>?> showTagPicker(
  BuildContext context, {
  required ValueListenable<TagPickerData> data,
  required TagPickerLabels labels,
  required Set<String> selected,
  Future<String?> Function(String name)? onCreate,
  VoidCallback? onRetry,
}) {
  return showAppSheetCustom<Set<String>>(
    context,
    builder: (_) => TagPickerSheet(
      data: data,
      labels: labels,
      selected: selected,
      onCreate: onCreate,
      onRetry: onRetry,
    ),
  );
}

Future<String?> showNewTagNameSheet(
  BuildContext context, {
  required String title,
  required String saveLabel,
  required String hint,
  int maxLength = TextLimits.tagName,
}) async {
  final name = await showAppSheetCustom<String>(
    context,
    builder: (_) => _NewTagNameSheet(
      title: title,
      saveLabel: saveLabel,
      hint: hint,
      maxLength: maxLength,
    ),
  );
  final n = name?.trim() ?? '';
  return n.isEmpty ? null : n;
}

class _NewTagNameSheet extends StatefulWidget {
  const _NewTagNameSheet({
    required this.title,
    required this.saveLabel,
    required this.hint,
    required this.maxLength,
  });

  final String title;
  final String saveLabel;
  final String hint;
  final int maxLength;

  @override
  State<_NewTagNameSheet> createState() => _NewTagNameSheetState();
}

class _NewTagNameSheetState extends State<_NewTagNameSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: widget.title,
      primaryLabel: widget.saveLabel,
      onPrimary: () => Navigator.pop(context, _text.text),
      child: AppInput(
        controller: _text,
        autofocus: true,
        maxLength: widget.maxLength,
        hint: widget.hint,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
    );
  }
}

class TagPickerSheet extends StatefulWidget {
  const TagPickerSheet({
    required this.data,
    required this.labels,
    required this.selected,
    this.onCreate,
    this.onRetry,
    super.key,
  });

  final ValueListenable<TagPickerData> data;
  final TagPickerLabels labels;
  final Set<String> selected;
  final Future<String?> Function(String name)? onCreate;
  final VoidCallback? onRetry;

  @override
  State<TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<TagPickerSheet> {
  late final Set<String> _picked = {...widget.selected};
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l = widget.labels;
    final typed = _search.text.trim();
    final name = typed.isNotEmpty
        ? typed
        : await showNewTagNameSheet(
            context,
            title: l.addTag,
            saveLabel: l.nameSave,
            hint: l.nameHint,
          );
    if (name == null || !mounted) return;
    final id = await widget.onCreate!(name);
    if (id == null || !mounted) return;
    setState(() => _picked.add(id));
    _search.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.labels;
    final palette = Theme.of(context).extension<AppColors>()!;
    final allowCreate = widget.onCreate != null;
    return ValueListenableBuilder<TagPickerData>(
      valueListenable: widget.data,
      builder: (context, data, _) => PickerSheet(
        title: l.title,
        searchable: true,
        searchToggle: true,
        searchHint: l.searchHint,
        searchController: _search,
        loading: data.loading,
        error: data.error,
        onRetry: widget.onRetry,
        footer: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: AppButton(
            label: _picked.isEmpty ? l.ok : '${l.ok} (${_picked.length})',
            expand: true,
            onPressed: () => Navigator.pop(context, _picked),
          ),
        ),
        builder: (context, q) {
          final tags = data.items
              .where((t) => q.isEmpty || t.name.toLowerCase().contains(q))
              .toList();
          final exact = data.items.any((t) => t.name.toLowerCase() == q);
          final typed = _search.text.trim();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final t in tags)
                        AppChip(
                          label: t.name,
                          icon: IconRegistry.get(
                            t.iconCode?.icon,
                            fallback: AppIcons.tag,
                          ),
                          color: _tagColor(t.iconCode, palette),
                          selected: _picked.contains(t.id),
                          dashed: !_picked.contains(t.id),
                          onTap: () => setState(() {
                            if (!_picked.remove(t.id)) _picked.add(t.id);
                          }),
                        ),
                    ],
                  ),
                )
              else if (!allowCreate)
                EmptyView.compact(message: q.isEmpty ? l.empty : l.noMatch),
              if (allowCreate && !exact)
                PickerCreateRow(
                  label: typed.isEmpty ? l.addTag : l.createNamed(typed),
                  onTap: _create,
                ),
            ],
          );
        },
      ),
    );
  }
}
