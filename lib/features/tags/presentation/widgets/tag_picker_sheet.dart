import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/tag.dart';
import '../cubit/tags_cubit.dart';

/// Pick tags — a THIN WRAPPER over the presentational organism
/// `showTagPicker` (lib/ui/domain/pickers): feeds it the [TagsCubit] list
/// (live) + l10n strings, and creates tags through the cubit. Search,
/// several at once (chips), and "＋ แท็กใหม่" without leaving (the name is
/// what's in the search box, or asked for). No tags and no creating (the
/// filter): an empty line. Resolves the new selection on ตกลง, null when
/// dismissed.
///
/// Reusable: the quick-create form's "⋯ เพิ่มเติม", and later the
/// transactions list's tag filter ([allowCreate] false there).
Future<Set<String>?> showTagPickerSheet(
  BuildContext context, {
  required Set<String> selected,
  String? title,
  bool allowCreate = true,
}) async {
  final cubit = context.read<TagsCubit>()..loadIfNeeded();
  final l = AppLocalizations.of(context)!;

  TagPickerData dataOf(TagsState s) => TagPickerData(
    items: [
      for (final t in s.tags)
        TagPickerItem(
          id: t.id,
          name: t.name.isEmpty ? l.tagFormNameLabel : t.name,
          iconCode: t.iconCode,
        ),
    ],
    loading: s.status == TagsStatus.loading && s.tags.isEmpty,
    error: s.status == TagsStatus.error && s.tags.isEmpty ? s.error : null,
  );

  // The sheet follows the cubit while it is open.
  final data = ValueNotifier(dataOf(cubit.state));
  final sub = cubit.stream.listen((s) => data.value = dataOf(s));
  try {
    return await showTagPicker(
      context,
      data: data,
      labels: TagPickerLabels(
        title: title ?? l.transactionFormTagsLabel,
        searchHint: l.tagPickerSearchHint,
        ok: l.commonOk,
        addTag: l.projectTxAddTag,
        createNamed: l.tagPickerCreateNamed,
        empty: l.tagPickerEmpty,
        noMatch: l.tagPickerNoMatch,
        nameSave: l.commonSave,
        nameHint: l.projectTxTagHint,
      ),
      selected: selected,
      onCreate: allowCreate
          ? (name) async => (await createOrFindTag(context, name))?.id
          : null,
      onRetry: cubit.load,
    );
  } finally {
    await sub.cancel();
  }
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
}) {
  final l = AppLocalizations.of(context)!;
  return showNewTagNameSheet(
    context,
    title: l.projectTxAddTag,
    saveLabel: l.commonSave,
    hint: l.projectTxTagHint,
    maxLength: maxLength,
  );
}
