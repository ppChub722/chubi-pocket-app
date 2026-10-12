import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../projects/data/projects_repository.dart';
import '../../../projects/domain/project.dart';
import '../../../projects/presentation/cubit/projects_cubit.dart';
import '../../domain/refs.dart';
import '../cubit/tx_form_options_cubit.dart';

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

/// [target]'s row text: "ใหม่: name" for one made on save.
String? eventTargetName(AppLocalizations l, EventTarget? target) =>
    switch (target) {
      null || RemoveFromEvent() => null,
      NewEventTarget(:final name) => l.quickEventNewNamed(name),
      ExistingEventTarget(:final project) => project.name,
    };

/// "เพิ่มเข้าอีเวนต์" (owner 2026-10-10) — the thin wrapper of the kit's
/// [EventTargetSheet]: it reads the events from the form options (or the
/// [ProjectsCubit]), maps them + the l10n words to the organism's plain data
/// and maps its pick back to an [EventTarget].
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
/// highlights the event picked so far. [allowCreate] false (a draft can only
/// name an event that exists) leaves the create section out. Null when
/// dismissed.
Future<EventTarget?> showEventTargetSheet(
  BuildContext context, {
  required String suggestedName,
  String? currentProjectId,
  String? selectedProjectId,
  bool useRootNavigator = true,
  bool allowCreate = true,
}) {
  // A form that holds the form options (quick create) lends its events: the
  // sheet's route sits outside the form's tree, so pass the cubit along.
  final options = maybeTxFormOptions(context, watch: false);
  return showAppSheetCustom<EventTarget>(
    context,
    useRootNavigator: useRootNavigator,
    builder: (_) {
      final sheet = _EventTargetLoader(
        suggestedName: suggestedName,
        currentProjectId: currentProjectId,
        selectedProjectId: selectedProjectId,
        allowCreate: allowCreate,
      );
      return options == null
          ? sheet
          : BlocProvider<TxFormOptionsCubit>.value(
              value: options,
              child: sheet,
            );
    },
  );
}

/// Reads the cubit(s), feeds [EventTargetSheet], maps its pick.
class _EventTargetLoader extends StatefulWidget {
  const _EventTargetLoader({
    required this.suggestedName,
    required this.currentProjectId,
    required this.selectedProjectId,
    required this.allowCreate,
  });
  final bool allowCreate;
  final String suggestedName;
  final String? currentProjectId;
  final String? selectedProjectId;

  @override
  State<_EventTargetLoader> createState() => _EventTargetLoaderState();
}

class _EventTargetLoaderState extends State<_EventTargetLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The form options carry the events: no extra call.
      final opts = maybeTxFormOptions(context, watch: false);
      if (opts != null) {
        opts.loadIfNeeded();
      } else {
        context.read<ProjectsCubit>().loadIfNeeded();
      }
    });
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
    final opts = maybeTxFormOptions(context);
    final state = opts == null ? context.watch<ProjectsCubit>().state : null;
    // From the form options an event is just id + name + icon: no member
    // count / dates, so no subtitle.
    final projects = opts == null
        ? state!.projects
        : [
            for (final e in opts.state.options?.events ?? const <EventRef>[])
              Project(
                id: e.id,
                ownerUserId: '',
                name: e.name,
                status: ProjectStatusWire.parse(e.status),
                iconCode: e.iconCode,
              ),
          ];
    final active = projects
        .where((p) => p.isActive && p.id != widget.currentProjectId)
        .toList();
    final loading = opts == null
        ? state!.status == ProjectsStatus.loading && active.isEmpty
        : opts.state.isLoading;
    final loadError = opts == null
        ? (state!.status == ProjectsStatus.error && active.isEmpty
              ? state.error
              : null)
        : (opts.state.status == TxFormOptionsStatus.error && active.isEmpty
              ? opts.state.error
              : null);
    return EventTargetSheet(
      items: [
        for (final p in active)
          EventTargetItem(id: p.id, name: p.name, subtitle: _subtitle(l, p)),
      ],
      labels: EventTargetSheetLabels(
        title: l.quickAddToEvent,
        openTitle: l.quickEventOpenTitle,
        newTitle: l.quickEventNew,
        newRow: l.quickEventNewRow,
        nameHint: l.quickEventNameLabel,
        // Nothing is created here — the event is made on บันทึก, with the
        // split people in it.
        membersInfo: l.quickEventMembersInfo,
        remove: l.txEventRemove,
        createNamed: l.quickEventCreateNamed,
      ),
      suggestedName: widget.suggestedName,
      selectedId: widget.selectedProjectId,
      hasCurrent: widget.currentProjectId != null,
      allowCreate: widget.allowCreate,
      loading: loading,
      error: loadError,
      onRetry: opts == null ? context.read<ProjectsCubit>().load : opts.load,
      onPicked: (pick) => Navigator.of(context).pop(switch (pick) {
        EventPickNew(:final name) => NewEventTarget(name),
        EventPickRemove() => const RemoveFromEvent(),
        EventPickExisting(:final id) => ExistingEventTarget(
          active.firstWhere((p) => p.id == id),
        ),
      }),
    );
  }
}
