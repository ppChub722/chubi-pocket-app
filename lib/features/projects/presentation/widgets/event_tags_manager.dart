import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import '../event_errors.dart';

/// "จัดการแท็กอีเวนต์" — the thin wrapper over the kit's [EventTagsSheet]:
/// the BE calls, the error snackbar, the list kept in step with every
/// answer. EVERY member may edit the event's tags (owner 2026-10-17; the BE
/// allows the owner and the contributors).
///
/// [onPatch] gets each write's [EventPatch] (the page patches itself from
/// it); [onImported] the import's answer (my personal tags may have grown).
Future<void> showEventTagsManager(
  BuildContext context, {
  required String projectId,
  required List<BoardTag> tags,
  required ValueChanged<EventPatch> onPatch,
  required void Function(EventTagImportResult result) onImported,
}) {
  return showAppSheetCustom<void>(
    context,
    builder: (_) => _EventTagsManager(
      projectId: projectId,
      initial: tags,
      onPatch: onPatch,
      onImported: onImported,
    ),
  );
}

class _EventTagsManager extends StatefulWidget {
  const _EventTagsManager({
    required this.projectId,
    required this.initial,
    required this.onPatch,
    required this.onImported,
  });

  final String projectId;
  final List<BoardTag> initial;
  final ValueChanged<EventPatch> onPatch;
  final void Function(EventTagImportResult result) onImported;

  @override
  State<_EventTagsManager> createState() => _EventTagsManagerState();
}

class _EventTagsManagerState extends State<_EventTagsManager> {
  late List<BoardTag> _tags = widget.initial;
  bool _busy = false;

  ProjectsRepository get _repo => context.read<ProjectsRepository>();

  BoardTag? _byId(String id) {
    for (final t in _tags) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// One call; its answer replaces the list. A failure keeps the sheet as
  /// it was and says why.
  Future<void> _run(Future<List<BoardTag>> Function() call) async {
    setState(() => _busy = true);
    try {
      final next = await call();
      if (mounted) setState(() => _tags = next);
    } on ApiException catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          eventErrorText(AppLocalizations.of(context)!, e),
          tone: Tone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<List<BoardTag>> _write({
    String? id,
    required String name,
    IconCode? icon,
  }) async {
    final w = await _repo.writeEventTag(
      widget.projectId,
      tagId: id,
      name: name,
      iconCode: icon,
    );
    widget.onPatch(w.patch);
    return w.patch.tags;
  }

  Future<void> _import(List<String> ids) => _run(() async {
    final r = await _repo.importTags(widget.projectId, tagIds: ids);
    widget.onImported(r);
    return r.tags;
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return EventTagsSheet(
      busy: _busy,
      tags: [
        for (final t in _tags)
          EventTagItem(
            id: t.id,
            name: t.name,
            iconCode: t.iconCode,
            subtitle: [
              l.fpEventsTagBills(t.count),
              if (t.mine) l.fpEventsTagInMine,
            ].join(' · '),
            canImport: !t.mine,
          ),
      ],
      labels: EventTagsLabels(
        title: l.fpEventsTagsTitle,
        add: l.fpEventsTagAdd,
        importAll: l.fpEventsTagsImportAll,
        rename: l.fpEventsTagRename,
        restyle: l.fpEventsTagRestyle,
        importOne: l.fpEventsTagImportOne,
        delete: l.commonDelete,
        nameLabel: l.fpEventsTagNameLabel,
        nameRequired: l.fpEventsTagNameRequired,
        addTitle: l.fpEventsTagNewTitle,
        renameTitle: l.fpEventsTagRenameTitle,
        save: l.commonSave,
        restyleTitle: l.fpEventsTagIconTitle,
        deleteTitle: l.fpEventsTagDeleteTitle,
        deleteBody: l.fpEventsTagDeleteBody,
        deleteConfirm: l.commonDelete,
        empty: l.fpEventsTagsEmpty,
      ),
      onAdd: (name) => _run(() => _write(name: name)),
      onRename: (id, name) =>
          _run(() => _write(id: id, name: name, icon: _byId(id)?.iconCode)),
      onRestyle: (id, icon) =>
          _run(() => _write(id: id, name: _byId(id)?.name ?? '', icon: icon)),
      onImport: (id) => _import([id]),
      onDelete: (id) => _run(() async {
        final p = await _repo.deleteEventTag(widget.projectId, id);
        widget.onPatch(p);
        return p.tags;
      }),
      onImportAll: () => _import(const []),
    );
  }
}
