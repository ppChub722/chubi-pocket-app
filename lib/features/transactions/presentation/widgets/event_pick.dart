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

sealed class EventTarget {
  const EventTarget();
}

class NewEventTarget extends EventTarget {
  const NewEventTarget(this.name);
  final String name;
}

class ExistingEventTarget extends EventTarget {
  const ExistingEventTarget(this.project);
  final Project project;
}

class RemoveFromEvent extends EventTarget {
  const RemoveFromEvent();
}

/// The event call's refusals in plain words; the BE message otherwise.
String eventErrorMessage(AppLocalizations l, ApiException e) =>
    switch (e.code) {
      'TX_NOT_FOUND' => l.quickCreateErrorTxNotFound,
      'TX_ALREADY_IN_PROJECT' => l.quickCreateErrorTxAlreadyInProject,
      'VALIDATION_ERROR' => l.quickCreateErrorValidation,
      'TX_NOT_BILLABLE' => l.quickCreateErrorNotBillable,
      // 422: someone already paid their share back / a split was forgiven —
      // those can't move into an event.
      'TX_SPLIT_HAS_REPAYMENT' => l.txEventSplitRepaid,
      'TX_SPLIT_CANCELLED' => l.txEventSplitCancelled,
      'CONTACT_NOT_FOUND' || 'CONTACT_ARCHIVED' => l.txSplitErrorContact,
      _ => e.message,
    };

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

String? eventTargetName(AppLocalizations l, EventTarget? target) =>
    switch (target) {
      null || RemoveFromEvent() => null,
      NewEventTarget(:final name) => l.quickEventNewNamed(name),
      ExistingEventTarget(:final project) => project.name,
    };

Future<EventTarget?> showEventTargetSheet(
  BuildContext context, {
  required String suggestedName,
  String? currentProjectId,
  String? selectedProjectId,
  bool useRootNavigator = true,
  bool allowCreate = true,
}) {
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
      final opts = maybeTxFormOptions(context, watch: false);
      if (opts != null) {
        opts.loadIfNeeded();
      } else {
        context.read<ProjectsCubit>().loadIfNeeded();
      }
    });
  }

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
