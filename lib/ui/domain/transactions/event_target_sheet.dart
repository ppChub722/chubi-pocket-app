import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui.dart';

/// One event the sheet can pick, as plain display data.
@immutable
class EventTargetItem {
  const EventTargetItem({
    required this.id,
    required this.name,
    this.icon,
    this.subtitle,
  });

  final String id;
  final String name;

  /// null = the event icon.
  final IconData? icon;

  /// A line under the name ("4 people · 12 Oct – 15 Oct").
  final String? subtitle;
}

/// What [EventTargetSheet] picked.
sealed class EventTargetPick {
  const EventTargetPick();
}

/// One of the listed events.
class EventPickExisting extends EventTargetPick {
  const EventPickExisting(this.id);
  final String id;
}

/// A new event with this name.
class EventPickNew extends EventTargetPick {
  const EventPickNew(this.name);
  final String name;
}

/// Out of the event it is in.
class EventPickRemove extends EventTargetPick {
  const EventPickRemove();
}

/// The words of [EventTargetSheet] — the caller passes its localised strings.
class EventTargetSheetLabels {
  const EventTargetSheetLabels({
    required this.title,
    required this.openTitle,
    required this.newTitle,
    required this.newRow,
    required this.nameHint,
    required this.membersInfo,
    required this.remove,
    required this.createNamed,
  });

  final String title;

  /// The section of the listed events.
  final String openTitle;

  /// The create section's title.
  final String newTitle;

  /// The "＋ new event" row.
  final String newRow;
  final String nameHint;

  /// The note under the name field.
  final String membersInfo;

  /// The "take it out of the event" row.
  final String remove;

  /// The create button's text for the typed name.
  final String Function(String name) createNamed;
}

/// "Add to event" — a PRESENTATIONAL organism on the kit [PickerSheet]: the
/// listed [items] (the caller filters them: open events, not the current
/// one), a create section (name prefilled with [suggestedName]), and — when
/// [hasCurrent] — a remove row. Data, words and states in, an
/// [EventTargetPick] out; nothing imported from cubits / repositories.
/// Resolves null when dismissed.
Future<EventTargetPick?> showEventTargetPickSheet(
  BuildContext context, {
  required List<EventTargetItem> items,
  required EventTargetSheetLabels labels,
  String suggestedName = '',
  String? selectedId,
  bool hasCurrent = false,
  bool allowCreate = true,
  bool useRootNavigator = true,
}) => showAppSheetCustom<EventTargetPick>(
  context,
  useRootNavigator: useRootNavigator,
  builder: (ctx) => EventTargetSheet(
    items: items,
    labels: labels,
    suggestedName: suggestedName,
    selectedId: selectedId,
    hasCurrent: hasCurrent,
    allowCreate: allowCreate,
    onPicked: (p) => Navigator.of(ctx).pop(p),
  ),
);

/// The sheet itself — see [showEventTargetPickSheet]. [loading] / [error]
/// (+ [onRetry]) are the list's states while it isn't there yet.
class EventTargetSheet extends StatefulWidget {
  const EventTargetSheet({
    required this.items,
    required this.labels,
    required this.onPicked,
    this.suggestedName = '',
    this.selectedId,
    this.hasCurrent = false,
    this.allowCreate = true,
    this.loading = false,
    this.error,
    this.onRetry,
    super.key,
  });

  final List<EventTargetItem> items;
  final EventTargetSheetLabels labels;
  final ValueChanged<EventTargetPick> onPicked;
  final String suggestedName;

  /// The event picked so far (highlighted).
  final String? selectedId;

  /// The row is in an event now — offers [EventPickRemove].
  final bool hasCurrent;

  /// false leaves the create section out.
  final bool allowCreate;
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  State<EventTargetSheet> createState() => _EventTargetSheetState();
}

class _EventTargetSheetState extends State<EventTargetSheet> {
  late final _name = TextEditingController(text: widget.suggestedName);
  bool _creating = false;

  /// Show the counter only this close to the limit.
  static const _counterFrom = TextLimits.name - 20;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = widget.labels;
    final active = widget.items;
    final loading = widget.loading && active.isEmpty;
    final error = active.isEmpty ? widget.error : null;
    // Nothing to pick from → open on the create section (when there is one).
    final creating =
        widget.allowCreate && (_creating || (!loading && active.isEmpty));
    final name = _name.text.trim();
    return PickerSheet(
      title: l.title,
      searchable: active.length > 8,
      loading: loading,
      error: error,
      onRetry: widget.onRetry,
      footer: creating
          ? Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: AppButton(
                label: l.createNamed(name),
                expand: true,
                onPressed: name.isEmpty
                    ? null
                    : () => widget.onPicked(EventPickNew(name)),
              ),
            )
          : null,
      builder: (context, query) {
        final shown = query.isEmpty
            ? active
            : active
                  .where((p) => p.name.toLowerCase().contains(query))
                  .toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (shown.isNotEmpty)
              SectionCard(
                first: true,
                title: l.openTitle,
                children: [
                  for (final p in shown)
                    PickerRow(
                      leading: AppIcon(p.icon ?? AppIcons.project),
                      title: p.name,
                      subtitle: p.subtitle,
                      selected: p.id == widget.selectedId,
                      onTap: () => widget.onPicked(EventPickExisting(p.id)),
                    ),
                ],
              ),
            if (widget.allowCreate)
              SectionCard(
                first: shown.isEmpty,
                title: creating ? l.newTitle : null,
                dividers: false,
                children: [
                  if (!creating)
                    PickerCreateRow(
                      label: l.newRow,
                      onTap: () => setState(() => _creating = true),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppInput(
                            controller: _name,
                            hint: l.nameHint,
                            autofocus: _creating,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(TextLimits.name),
                            ],
                          ),
                          // The counter only near the limit.
                          if (_name.text.length >= _counterFrom)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${_name.text.length}/${TextLimits.name}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppIcon(
                                AppIcons.info,
                                size: AppIconSize.sm,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  l.membersInfo,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            if (widget.hasCurrent)
              DangerRow(
                icon: AppIcons.clear,
                label: l.remove,
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                onTap: () => widget.onPicked(const EventPickRemove()),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}
