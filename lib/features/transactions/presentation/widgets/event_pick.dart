import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/text_limits.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/module_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../projects/data/projects_repository.dart';
import '../../../projects/domain/project.dart';
import '../../../projects/presentation/cubit/projects_cubit.dart';

export '../tx_rules.dart' show txCanJoinEvent, typeCanJoinEvent;

// A transaction ↔ an event (project): the quick create's "เพิ่มเข้าอีเวนต์"
// and the detail page's event card (owner 2026-10-10).

/// What the event sheet picked.
sealed class EventTarget {
  const EventTarget();
}

/// A new event, made with this name on บันทึก.
class NewEventTarget extends EventTarget {
  const NewEventTarget(this.name);
  final String name;
}

/// One of my active events.
class ExistingEventTarget extends EventTarget {
  const ExistingEventTarget(this.project);
  final Project project;
}

/// Out of the event it's in (the detail page only).
class RemoveFromEvent extends EventTarget {
  const RemoveFromEvent();
}

/// The event call's refusals in plain words; the BE message otherwise.
String eventErrorMessage(AppLocalizations l, ApiException e) =>
    switch (e.code) {
      'TX_NOT_FOUND' => l.quickCreateErrorTxNotFound,
      'TX_ALREADY_IN_PROJECT' => l.quickCreateErrorTxAlreadyInProject,
      'VALIDATION_ERROR' => l.quickCreateErrorValidation,
      // 422: an opening-balance / adjustment / repayment row.
      'TX_NOT_BILLABLE' => l.quickCreateErrorNotBillable,
      // 422: someone already paid their share back / a split was
      // forgiven — those can't move into an event.
      'TX_SPLIT_HAS_REPAYMENT' => l.txEventSplitRepaid,
      'TX_SPLIT_CANCELLED' => l.txEventSplitCancelled,
      // 400: a split's contact is gone.
      'CONTACT_NOT_FOUND' || 'CONTACT_ARCHIVED' => l.txSplitErrorContact,
      _ => e.message,
    };

/// Applies [change] to the saved row [txId], now in [currentProjectId]
/// (null = none): into an existing event (bills), into a new one (quick)
/// — `move` when it's leaving another — or out of it (DELETE). Throws
/// [ApiException].
Future<void> applyEventChange(
  ProjectsRepository repo, {
  required String txId,
  required String? currentProjectId,
  required EventTarget change,
}) async {
  final move = currentProjectId != null;
  switch (change) {
    case NewEventTarget(:final name):
      await repo.quickCreate(name: name, transactionIds: [txId], move: move);
    case ExistingEventTarget(:final project):
      if (project.id == currentProjectId) return;
      await repo.addBills(project.id, transactionIds: [txId], move: move);
    case RemoveFromEvent():
      if (currentProjectId == null) return;
      await repo.removeBill(currentProjectId, txId);
  }
}

/// The อีเวนต์ row of a transaction form's sections (owner 2026-10-10) —
/// "อีเวนต์   🎉 name ›", the same in quick create and the detail page.
/// View: [onTap] opens the event (the one link there). Editing: [onTap]
/// opens the picker, [onClear] adds ✕. No event: "ไม่ได้เลือก", muted.
/// [locked]: a 🔒 instead (a row that can't change its event).
class EventRow extends StatelessWidget {
  const EventRow({
    required this.name,
    this.onTap,
    this.onClear,
    this.locked = false,
    super.key,
  });

  final String? name;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final accent = ModuleColors.of(context).people;
    final n = name;
    return DetailRow(
      label: l.quickEventLabel,
      leading: locked ? const Icon(AppIcons.lock) : null,
      onTap: onTap,
      showChevron: onTap != null && (n == null || onClear == null),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (n != null) ...[
            Icon(AppIcons.project, size: 18, color: accent),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              n ?? l.quickEventNone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: n == null ? scheme.onSurfaceVariant : null,
                fontWeight: n == null ? null : FontWeight.w600,
              ),
            ),
          ),
          if (n != null && onClear != null)
            IconButton(
              tooltip: l.quickEventRemove,
              icon: const Icon(AppIcons.clear, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}

/// [target]'s row text: "ใหม่: name" for one made on save.
String? eventTargetName(AppLocalizations l, EventTarget? target) =>
    switch (target) {
      null || RemoveFromEvent() => null,
      NewEventTarget(:final name) => l.quickEventNewNamed(name),
      ExistingEventTarget(:final project) => project.name,
    };

/// "เพิ่มเข้าอีเวนต์" (owner 2026-10-10) — on the kit [PickerSheet]:
///
///   อีเวนต์ที่เปิดอยู่                 (most recently updated first)
///   🎉 ทริปเชียงใหม่                    ← highlighted when it's the pick
///      4 คน · 12 ต.ค. – 15 ต.ค.
///   ▬▬▬▬
///   ＋ สร้างอีเวนต์ใหม่   → name (prefilled [suggestedName]) · who joins ·
///                         [สร้าง "name"]
///   ▬▬▬▬
///   เอาออกจากอีเวนต์       (when it's in one — [currentProjectId], which
///                         isn't offered again)
///
/// No open events: straight to the create section. [selectedProjectId]
/// highlights the event picked so far. Null when dismissed.
Future<EventTarget?> showEventTargetSheet(
  BuildContext context, {
  required String suggestedName,
  String? currentProjectId,
  String? selectedProjectId,
  bool useRootNavigator = true,
}) => showAppSheetCustom<EventTarget>(
  context,
  useRootNavigator: useRootNavigator,
  builder: (_) => _EventTargetSheet(
    suggestedName: suggestedName,
    currentProjectId: currentProjectId,
    selectedProjectId: selectedProjectId,
  ),
);

class _EventTargetSheet extends StatefulWidget {
  const _EventTargetSheet({
    required this.suggestedName,
    required this.currentProjectId,
    required this.selectedProjectId,
  });
  final String suggestedName;
  final String? currentProjectId;
  final String? selectedProjectId;

  @override
  State<_EventTargetSheet> createState() => _EventTargetSheetState();
}

class _EventTargetSheetState extends State<_EventTargetSheet> {
  late final _name = TextEditingController(text: widget.suggestedName);
  bool _creating = false;

  /// Show the counter only this close to the limit.
  static const _counterFrom = TextLimits.name - 20;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProjectsCubit>().load();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// "4 คน · 12 ต.ค. – 15 ต.ค." from what the list already carries.
  String? _subtitle(AppLocalizations l, Project p) {
    final locale = Localizations.localeOf(context).toLanguageTag();
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
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<ProjectsCubit>().state;
    final active = state.projects
        .where((p) => p.isActive && p.id != widget.currentProjectId)
        .toList();
    final loading = state.status == ProjectsStatus.loading && active.isEmpty;
    // Nothing to pick from → open on the create section.
    final creating = _creating || (!loading && active.isEmpty);
    final name = _name.text.trim();
    return PickerSheet(
      title: l.quickAddToEvent,
      searchable: active.length > 8,
      loading: loading,
      error: state.status == ProjectsStatus.error && active.isEmpty
          ? state.error
          : null,
      onRetry: context.read<ProjectsCubit>().load,
      footer: creating
          ? Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: AppButton(
                label: l.quickEventCreateNamed(name),
                expand: true,
                onPressed: name.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(NewEventTarget(name)),
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
                title: l.quickEventOpenTitle,
                children: [
                  for (final p in shown)
                    PickerRow(
                      leading: const Icon(AppIcons.project),
                      title: p.name,
                      subtitle: _subtitle(l, p),
                      selected: p.id == widget.selectedProjectId,
                      onTap: () =>
                          Navigator.of(context).pop(ExistingEventTarget(p)),
                    ),
                ],
              ),
            SectionCard(
              first: shown.isEmpty,
              title: creating ? l.quickEventNew : null,
              dividers: false,
              children: [
                if (!creating)
                  PickerCreateRow(
                    label: l.quickEventNewRow,
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
                        AppTextField(
                          controller: _name,
                          hint: l.quickEventNameLabel,
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
                            Icon(
                              AppIcons.info,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                // Nothing is created here — the event is made
                                // on บันทึก, with the split people in it.
                                l.quickEventMembersInfo,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (widget.currentProjectId != null)
              DangerRow(
                icon: AppIcons.clear,
                label: l.txEventRemove,
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                onTap: () => Navigator.of(context).pop(const RemoveFromEvent()),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}
