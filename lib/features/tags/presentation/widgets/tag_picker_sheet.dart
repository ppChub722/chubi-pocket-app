import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/text_limits.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/tag.dart';
import '../cubit/tags_cubit.dart';
import 'tag_chip.dart';

/// Pick tags — search, several at once, and "+ แท็กใหม่" without leaving
/// (the name is what's in the search box, or asked for). Resolves the new
/// selection on ตกลง, null when dismissed.
///
/// Reusable: the quick-create form's "⋯ เพิ่มเติม", and later the
/// transactions list's tag filter ([allowCreate] false there).
Future<Set<String>?> showTagPickerSheet(
  BuildContext context, {
  required Set<String> selected,
  String? title,
  bool allowCreate = true,
}) {
  context.read<TagsCubit>().loadIfNeeded();
  return showAppSheetCustom<Set<String>>(
    context,
    builder: (_) => _TagPicker(
      selected: selected,
      title: title ?? AppLocalizations.of(context)!.transactionFormTagsLabel,
      allowCreate: allowCreate,
    ),
  );
}

/// Creates a tag named [name] — or, when one by that name exists (any
/// case), returns that one. Null (with a snackbar) when it fails.
Future<Tag?> createOrFindTag(BuildContext context, String name) async {
  final l = AppLocalizations.of(context)!;
  final cubit = context.read<TagsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final n = name.trim();
  if (n.isEmpty) return null;
  final existing = cubit.state.tags
      .where((t) => t.name.toLowerCase() == n.toLowerCase())
      .firstOrNull;
  if (existing != null) return existing;
  try {
    return await cubit.add(Tag(id: 'draft', name: n));
  } on ApiException {
    showAppSnackBarOn(messenger, l.txTagCreateFailed, tone: Tone.danger);
    return null;
  }
}

/// Asks for a new tag's name (a small sheet with one field). Trimmed;
/// null when dismissed or blank.
Future<String?> askNewTagName(
  BuildContext context, {
  int maxLength = TextLimits.tagName,
}) async {
  final name = await showAppSheetCustom<String>(
    context,
    builder: (_) => _NewTagNameSheet(maxLength: maxLength),
  );
  final n = name?.trim() ?? '';
  return n.isEmpty ? null : n;
}

/// The name sheet owns its controller: the sheet's future resolves on pop,
/// while the field is still on screen animating out — a controller the
/// caller disposed right then crashed (owner bug 2026-10-10).
class _NewTagNameSheet extends StatefulWidget {
  const _NewTagNameSheet({required this.maxLength});
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
    final l = AppLocalizations.of(context)!;
    return AppSheetScaffold(
      title: l.projectTxAddTag,
      footer: AppButton(
        label: l.commonSave,
        expand: true,
        onPressed: () => Navigator.pop(context, _text.text),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: AppTextField(
          controller: _text,
          autofocus: true,
          maxLength: widget.maxLength,
          hint: l.projectTxTagHint,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
      ),
    );
  }
}

class _TagPicker extends StatefulWidget {
  const _TagPicker({
    required this.selected,
    required this.title,
    required this.allowCreate,
  });

  final Set<String> selected;
  final String title;
  final bool allowCreate;

  @override
  State<_TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<_TagPicker> {
  late final Set<String> _picked = {...widget.selected};
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _query.trim().isNotEmpty
        ? _query.trim()
        : await askNewTagName(context);
    if (name == null || !mounted) return;
    final tag = await createOrFindTag(context, name);
    if (tag == null || !mounted) return;
    setState(() {
      _picked.add(tag.id);
      _search.clear();
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final q = _query.trim().toLowerCase();
    final tags = context
        .watch<TagsCubit>()
        .state
        .tags
        .where((t) => q.isEmpty || t.name.toLowerCase().contains(q))
        .toList();
    final exact = tags.any((t) => t.name.toLowerCase() == q);
    return AppSheetScaffold(
      title: widget.title,
      footer: AppButton(
        label: l.commonOk,
        expand: true,
        onPressed: () => Navigator.pop(context, _picked),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSearchBar(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final t in tags)
                  TagChip(
                    tag: t,
                    selected: _picked.contains(t.id),
                    onTap: () => setState(() {
                      if (!_picked.remove(t.id)) _picked.add(t.id);
                    }),
                  ),
                // Typed a name that isn't there → make it, right here.
                if (widget.allowCreate && !exact)
                  ActionChip(
                    avatar: const Icon(AppIcons.add, size: 16),
                    label: Text(
                      q.isEmpty
                          ? l.projectTxAddTag
                          : l.tagPickerCreateNamed(_query.trim()),
                    ),
                    onPressed: _create,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
