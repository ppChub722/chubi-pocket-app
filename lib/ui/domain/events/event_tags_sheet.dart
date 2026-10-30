import 'package:flutter/material.dart';

import '../../ui.dart';

@immutable
class EventTagItem {
  const EventTagItem({
    required this.id,
    required this.name,
    this.iconCode,
    this.subtitle,
    this.canImport = true,
  });

  final String id;
  final String name;
  final IconCode? iconCode;

  final String? subtitle;

  final bool canImport;
}

class EventTagsLabels {
  const EventTagsLabels({
    required this.title,
    required this.add,
    required this.importAll,
    required this.rename,
    required this.restyle,
    required this.importOne,
    required this.delete,
    required this.nameLabel,
    required this.addTitle,
    required this.renameTitle,
    required this.save,
    required this.restyleTitle,
    required this.deleteTitle,
    required this.deleteBody,
    required this.deleteConfirm,
    required this.empty,
  });

  final String title;
  final String add;
  final String importAll;
  final String rename;
  final String restyle;
  final String importOne;
  final String delete;
  final String nameLabel;
  final String addTitle;
  final String renameTitle;
  final String save;
  final String restyleTitle;

  final String Function(String name) deleteTitle;
  final String deleteBody;
  final String deleteConfirm;
  final String empty;
}

enum _TagAction { rename, restyle, importOne, delete }

class EventTagsSheet extends StatelessWidget {
  const EventTagsSheet({
    required this.tags,
    required this.labels,
    required this.onAdd,
    required this.onRename,
    required this.onRestyle,
    required this.onImport,
    required this.onDelete,
    required this.onImportAll,
    this.busy = false,
    super.key,
  });

  final List<EventTagItem> tags;
  final EventTagsLabels labels;
  final bool busy;
  final ValueChanged<String> onAdd;
  final void Function(String id, String name) onRename;
  final void Function(String id, IconCode iconCode) onRestyle;
  final ValueChanged<String> onImport;
  final ValueChanged<String> onDelete;
  final VoidCallback onImportAll;

  Future<void> _add(BuildContext context) async {
    final name = await _askName(context, title: labels.addTitle);
    if (name != null) onAdd(name);
  }

  Future<String?> _askName(
    BuildContext context, {
    required String title,
    String initial = '',
  }) => showNewTagNameSheet(
    context,
    title: title,
    saveLabel: labels.save,
    hint: labels.nameLabel,
    initial: initial,
  );

  Future<void> _act(
    BuildContext context,
    EventTagItem tag,
    _TagAction a,
  ) async {
    switch (a) {
      case _TagAction.rename:
        final name = await _askName(
          context,
          title: labels.renameTitle,
          initial: tag.name,
        );
        if (name != null && name != tag.name) onRename(tag.id, name);
      case _TagAction.restyle:
        final r = await showIconMakerSheet(
          context: context,
          type: IconType.tag,
          initial: tag.iconCode,
          title: labels.restyleTitle,
        );
        if (r is IconMakerSelected) onRestyle(tag.id, r.iconCode);
      case _TagAction.importOne:
        onImport(tag.id);
      case _TagAction.delete:
        final ok = await showConfirmDialog(
          context,
          title: labels.deleteTitle(tag.name),
          message: labels.deleteBody,
          confirmLabel: labels.deleteConfirm,
          destructive: true,
        );
        if (ok) onDelete(tag.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canImportAny = tags.any((t) => t.canImport);
    return BusyScope(
      busy: busy,
      child: AppSheetScaffold(
        title: labels.title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tags.isEmpty)
              EmptyView.compact(message: labels.empty)
            else
              for (final t in tags)
                AppListRow(
                  leading: IconDisplay(
                    type: IconType.tag,
                    size: 36,
                    iconCode: t.iconCode,
                  ),
                  title: t.name,
                  line2: ListRowLine(parts: [?t.subtitle]),
                  actions: [
                    ListRowAction.menu<_TagAction>(
                      options: [
                        SheetOption(
                          value: _TagAction.rename,
                          label: labels.rename,
                          leading: const AppIcon(AppIcons.edit),
                          submits: true,
                        ),
                        SheetOption(
                          value: _TagAction.restyle,
                          label: labels.restyle,
                          leading: const AppIcon(AppIcons.colorPicker),
                          submits: true,
                        ),
                        SheetOption(
                          value: _TagAction.importOne,
                          label: labels.importOne,
                          leading: const AppIcon(AppIcons.add),
                          enabled: t.canImport,
                          submits: true,
                        ),
                        SheetOption(
                          value: _TagAction.delete,
                          label: labels.delete,
                          leading: const AppIcon(AppIcons.delete),
                          destructive: true,
                          submits: true,
                        ),
                      ],
                      onSelected: (a) => _act(context, t, a),
                    ),
                  ],
                ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: AddTile(
                label: labels.add,
                variant: AddTileVariant.row,
                onTap: () => _add(context),
              ),
            ),
            if (canImportAny)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: AppButton(
                    label: labels.importAll,
                    icon: AppIcons.download,
                    variant: AppButtonVariant.text,
                    onPressed: onImportAll,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
