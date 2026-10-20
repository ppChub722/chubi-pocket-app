import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../projects/data/projects_repository.dart';
import '../../../projects/domain/project.dart';

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
