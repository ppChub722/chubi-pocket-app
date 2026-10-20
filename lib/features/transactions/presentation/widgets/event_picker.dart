import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/cubit_feed.dart';
import '../../../../core/data/sync_refresh.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../projects/domain/project.dart';
import '../../../projects/presentation/cubit/project_directory_cubit.dart';
import '../../domain/refs.dart';
import '../cubit/tx_form_options_cubit.dart';
import 'event_pick.dart';

/// The event a transaction goes to: an open event, a new one by name (the
/// name row, starting with [suggestedName]), or out of the current one.
/// [showClosed] adds a ปิดแล้ว tab: closed events are locked, so they show
/// but can't be picked.
abstract final class EventPicker {
  static const _openGroup = 'open';
  static const _closedGroup = 'closed';
  static const _remove = 'remove';

  static Future<EventTarget?> one(
    BuildContext context, {
    String suggestedName = '',
    String? currentProjectId,
    String? selectedProjectId,
    bool allowCreate = true,
    bool showClosed = true,
    bool useRootNavigator = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    ProjectDirectoryCubit? directory;
    try {
      directory = context.read<ProjectDirectoryCubit>();
    } catch (_) {
      directory = null;
    }
    final options = directory == null
        ? maybeTxFormOptions(context, watch: false)
        : null;

    List<PickerItem> itemsOf(
      List<Project> open, [
      List<Project> closed = const [],
    ]) => [
      for (final p in open)
        if (p.isActive && p.id != currentProjectId)
          PickerItem(
            id: p.id,
            title: p.name,
            subtitle: _subtitle(l, locale, p),
            leading: const AppIcon(AppIcons.project),
            group: _openGroup,
          ),
      if (showClosed)
        for (final p in closed)
          if (_isClosed(p) && p.id != currentProjectId)
            PickerItem(
              id: p.id,
              title: p.name,
              subtitle: [
                _statusLabel(l, p.status),
                ?_subtitle(l, locale, p),
              ].join(' | '),
              leading: const AppIcon(AppIcons.project),
              group: _closedGroup,
              enabled: false,
            ),
    ];

    var latest = const <Project>[];
    var closed = const <Project>[];
    PickerData fromDirectory(ProjectDirectoryState s) {
      latest = s.formEvents;
      closed = [
        for (final p in s.projects)
          if (p.myRole != null) p,
      ];
      return PickerData(
        itemsOf(latest, closed),
        loading:
            s.status == ProjectDirectoryStatus.initial ||
            s.status == ProjectDirectoryStatus.loading,
        error: s.status == ProjectDirectoryStatus.error ? s.error : null,
      );
    }

    PickerData fromOptions(TxFormOptionsState s) {
      latest = [
        for (final e in s.options?.events ?? const <EventRef>[])
          Project(
            id: e.id,
            ownerUserId: '',
            name: e.name,
            status: ProjectStatusWire.parse(e.status),
            iconCode: e.iconCode,
          ),
      ];
      return PickerData(
        itemsOf(latest),
        loading: s.isLoading,
        error: s.status == TxFormOptionsStatus.error ? s.error : null,
      );
    }

    final CubitFeed<Object?, PickerData>? feed = directory != null
        ? CubitFeed<ProjectDirectoryState, PickerData>(directory, fromDirectory)
        : options != null
        ? CubitFeed<TxFormOptionsState, PickerData>(options, fromOptions)
        : null;
    final start = latest;
    if (directory != null) {
      unawaited(directory.loadIfNeeded());
    } else if (options != null) {
      unawaited(options.loadIfNeeded());
    }

    try {
      final r = await showItemPicker(
        context,
        useRootNavigator: useRootNavigator,
        ItemPickerSheet(
          title: l.quickAddToEvent,
          items: itemsOf(latest, closed),
          live: feed?.listenable,
          selected: {?selectedProjectId},
          filters: [
            PickerFilter(l.eventPickerTabOpen, (i) => i.group == _openGroup),
            if (showClosed)
              PickerFilter(
                l.eventPickerTabClosed,
                (i) => i.group == _closedGroup,
              ),
          ],
          freeText: allowCreate
              ? PickerFreeText(
                  hint: l.quickEventNameLabel,
                  saveLabel: l.quickEventCreateNamed,
                  leading: (_) => const AppIcon(AppIcons.add),
                  initial: _clip(suggestedName),
                  maxLength: TextLimits.name,
                )
              : null,
          actions: [
            if (currentProjectId != null)
              PickerAction(
                id: _remove,
                label: l.txEventRemove,
                icon: AppIcons.clear,
                destructive: true,
              ),
          ],
          note: allowCreate ? l.quickEventMembersInfo : null,
          emptyText: l.quickEventNoneYet,
          noMatchText: allowCreate ? null : l.multiPickNoMatch,
          onRetry: directory?.load ?? options?.load,
          onRefresh: feed == null
              ? null
              : syncRefreshOf(context, const {SyncSet.projects}),
        ),
      );
      if (r == null) return null;
      if (r.action == _remove) return const RemoveFromEvent();
      if (r.text case final text?) return NewEventTarget(text);
      final id = r.id;
      final hit =
          latest.where((p) => p.id == id).firstOrNull ??
          start.where((p) => p.id == id).firstOrNull;
      return hit == null ? null : ExistingEventTarget(hit);
    } finally {
      unawaited(feed?.dispose());
    }
  }

  static bool _isClosed(Project p) =>
      p.status == ProjectStatus.completed ||
      p.status == ProjectStatus.cancelled;

  static String _statusLabel(AppLocalizations l, ProjectStatus s) =>
      switch (s) {
        ProjectStatus.completed => l.projectStatusCompleted,
        ProjectStatus.cancelled => l.projectStatusCancelled,
        ProjectStatus.archived => l.projectStatusArchived,
        ProjectStatus.active => l.projectStatusActive,
      };

  /// The input's limit cuts only what is typed, not the text it starts with.
  static String _clip(String name) {
    final n = name.trim().characters;
    return (n.length > TextLimits.name ? n.take(TextLimits.name) : n)
        .toString();
  }

  static String? _subtitle(AppLocalizations l, String locale, Project p) {
    String? day(String? ymd) {
      final d = ymd == null ? null : DateTime.tryParse(ymd);
      return d == null ? null : DateFormatter.medium(d, locale: locale);
    }

    final from = day(p.startDate);
    final to = day(p.endDate);
    final parts = [
      if (p.membersCount > 0) l.walletMembersCount(p.membersCount),
      if (from != null && to != null && from != to) '$from – $to' else ?from,
    ];
    return parts.isEmpty ? null : parts.join(' | ');
  }
}
