import '../../../../l10n/gen/app_localizations.dart';
import '../../../projects/data/projects_repository.dart';
import '../../../projects/domain/project.dart';
import '../../data/transactions_repository.dart';
import '../../domain/link_draft.dart';

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

/// The tx detail's event pick, on the 0.4.1-2 endpoints only (V16 retires
/// quick / bills / my-books). [billId]: the bill my tx belongs to
/// (`event_bill.bill_id`): another event moves the bill (PUT /event-bills
/// move, every copy stays connected); leaving only disconnects my copy (POST
/// /event-bills/{id}/disconnect; the bill stays, rule f). Not in a bill yet:
/// my tx becomes a bill I paid in that event ([amount] = my share, the PUT
/// /transactions อีเวนต์ link, as the tab does); a new event is made first.
Future<void> applyEventChange(
  ProjectsRepository repo, {
  required TransactionsRepository txRepo,
  required String txId,
  required double amount,
  required String? currentProjectId,
  required EventTarget change,
  String? billId,
}) async {
  if (billId != null) {
    switch (change) {
      case RemoveFromEvent():
        await repo.disconnectEventBill(billId);
      case ExistingEventTarget(:final project):
        if (project.id == currentProjectId) return;
        await repo.rebookEventBill(
          billId,
          myBooks: const {'on': true},
          move: {'project_id': project.id},
        );
      case NewEventTarget(:final name):
        await repo.rebookEventBill(
          billId,
          myBooks: const {'on': true},
          move: {
            'new_event': {'name': name},
          },
        );
    }
    return;
  }
  final String projectId;
  switch (change) {
    case RemoveFromEvent():
      return;
    case ExistingEventTarget(:final project):
      projectId = project.id;
    case NewEventTarget(:final name):
      projectId = (await repo.create(name: name)).project.id;
  }
  await txRepo.update(
    id: txId,
    link: {
      'link_mode': LinkMode.event.wire,
      'event': {
        'project_id': projectId,
        'payer': const {'me': true},
        'members': [
          {'me': true, 'share': amount},
        ],
      },
    },
  );
}

String? eventTargetName(AppLocalizations l, EventTarget? target) =>
    switch (target) {
      null || RemoveFromEvent() => null,
      NewEventTarget(:final name) => l.quickEventNewNamed(name),
      ExistingEventTarget(:final project) => project.name,
    };
