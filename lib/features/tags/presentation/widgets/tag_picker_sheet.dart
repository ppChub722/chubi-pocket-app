import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/tag.dart';
import '../cubit/tags_cubit.dart';

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
