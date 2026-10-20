import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/cubit_feed.dart';
import '../../../../core/data/sync_refresh.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/tag.dart';
import '../cubit/tags_cubit.dart';
import 'tag_chip.dart';

sealed class TagPick {
  const TagPick();
}

class TagPicked extends TagPick {
  const TagPicked(this.tag);
  final Tag tag;
}

/// "ไม่ระบุแท็ก" was picked.
class TagPickedNone extends TagPick {
  const TagPickedNone();
}

class TagPicks {
  const TagPicks({this.tags = const [], this.none = false});

  final List<Tag> tags;

  /// "ไม่ระบุแท็ก" is ticked.
  final bool none;

  Set<String> get ids => {for (final t in tags) t.id};
}

/// The tag picker every page opens: coloured chips, a search that also names a
/// new tag (ticked at once). [tags] = a fixed list (no creating); without it
/// the tags cache, live.
abstract final class TagPicker {
  static Future<TagPick?> one(
    BuildContext context, {
    String? selectedId,
    bool allowNone = false,
    String? noneLabel,
    bool allowCreate = true,
    String? title,
    List<Tag>? tags,
    bool useRootNavigator = true,
  }) async {
    final r = await _open(
      context,
      multi: false,
      selected: {?selectedId},
      allowNone: allowNone,
      noneLabel: noneLabel,
      allowCreate: allowCreate,
      title: title,
      tags: tags,
      useRootNavigator: useRootNavigator,
    );
    if (r == null) return null;
    if (r.result.none) return const TagPickedNone();
    final hit = r.lookup(r.result.id);
    return hit == null ? null : TagPicked(hit);
  }

  static Future<TagPicks?> many(
    BuildContext context, {
    Set<String> selected = const {},
    bool allowNone = false,
    bool noneSelected = false,
    String? noneLabel,
    bool allowCreate = true,
    String? title,
    List<Tag>? tags,
    bool useRootNavigator = true,
  }) async {
    final r = await _open(
      context,
      multi: true,
      selected: selected,
      allowNone: allowNone,
      noneSelected: noneSelected,
      noneLabel: noneLabel,
      allowCreate: allowCreate,
      title: title,
      tags: tags,
      useRootNavigator: useRootNavigator,
    );
    if (r == null) return null;
    return TagPicks(
      tags: [for (final id in r.result.ids) ?r.lookup(id)],
      none: r.result.none,
    );
  }

  static Future<_Opened?> _open(
    BuildContext context, {
    required bool multi,
    Set<String> selected = const {},
    bool allowNone = false,
    bool noneSelected = false,
    String? noneLabel,
    bool allowCreate = true,
    String? title,
    List<Tag>? tags,
    bool useRootNavigator = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    TagsCubit? cache;
    if (tags == null) {
      try {
        cache = context.read<TagsCubit>();
      } catch (_) {
        cache = null;
      }
    }
    var latest = tags ?? cache?.state.tags ?? const <Tag>[];
    final start = latest;
    PickerData dataOf(TagsState s) {
      latest = s.tags;
      return PickerData(
        _items(l, palette, latest),
        loading:
            s.status == TagsStatus.initial || s.status == TagsStatus.loading,
        error: s.status == TagsStatus.error ? s.error : null,
      );
    }

    final feed = cache == null
        ? null
        : CubitFeed<TagsState, PickerData>(cache, dataOf);
    if (cache != null) unawaited(cache.loadIfNeeded());
    final refresh = cache == null
        ? null
        : syncRefreshOf(context, const {SyncSet.tags});
    final canCreate = allowCreate && cache != null;
    final created = <String, Tag>{};

    final sheet = ItemPickerSheet(
      title: title ?? l.transactionFormTagsLabel,
      items: _items(l, palette, latest),
      live: feed?.listenable,
      multi: multi,
      layout: PickerLayout.chips,
      selected: selected,
      noneSelected: noneSelected,
      none: allowNone
          ? PickerNone(label: noneLabel ?? l.txFilterNoTag, icon: AppIcons.tag)
          : null,
      create: canCreate
          ? PickerCreate(
              label: (typed) => typed.isEmpty
                  ? l.projectTxAddTag
                  : l.tagPickerCreateNamed(typed),
              onCreate: (typed) async {
                final name = typed.isNotEmpty
                    ? typed
                    : await askNewTagName(context);
                if (name == null || !context.mounted) return null;
                final tag = await createOrFindTag(context, name);
                if (tag != null) created[tag.id] = tag;
                return tag?.id;
              },
              fromSearch: true,
            )
          : null,
      searchable: true,
      searchHint: canCreate ? l.tagPickerSearchHint : l.multiPickSearch,
      emptyText: canCreate ? null : l.tagPickerEmpty,
      noMatchText: canCreate ? null : l.tagPickerNoMatch,
      confirmLabel: multi
          ? (n) => n == 0 ? l.commonOk : l.multiPickConfirm(n)
          : null,
      onRetry: cache?.load,
      onRefresh: refresh,
    );

    try {
      final result = await showItemPicker(
        context,
        useRootNavigator: useRootNavigator,
        sheet,
      );
      if (result == null) return null;
      Tag? lookup(String? id) {
        if (id == null) return null;
        return created[id] ??
            latest.where((t) => t.id == id).firstOrNull ??
            start.where((t) => t.id == id).firstOrNull;
      }

      return _Opened(result, lookup);
    } finally {
      unawaited(feed?.dispose());
    }
  }

  static List<PickerItem> _items(
    AppLocalizations l,
    AppColors palette,
    List<Tag> all,
  ) => [
    for (final t in all)
      PickerItem(
        id: t.id,
        title: t.name.isEmpty ? l.tagFormNameLabel : t.name,
        icon: IconRegistry.get(t.iconCode?.icon, fallback: AppIcons.tag),
        color: tagColor(t.iconCode, palette),
      ),
  ];
}

class _Opened {
  const _Opened(this.result, this.lookup);

  final PickerResult result;
  final Tag? Function(String? id) lookup;
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
