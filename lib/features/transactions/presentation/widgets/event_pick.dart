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

/// The tx detail's event pick. [billId]: the paper my tx belongs to: another
/// event moves the paper (every copy stays connected); leaving only unlinks
/// my tx (the paper stays). Not in a paper yet: my tx becomes a bill I paid
/// in that event ([amount] = my share, the PUT /transactions อีเวนต์ link,
/// as the tab does); a new event is made first.
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
    final String to;
    switch (change) {
      case RemoveFromEvent():
        await repo.unlinkMyTransaction(txId);
        return;
      case ExistingEventTarget(:final project):
        if (project.id == currentProjectId) return;
        to = project.id;
      case NewEventTarget(:final name):
        to = (await repo.create(name: name)).project.id;
    }
    await repo.movePaper(
      billId,
      fromProjectId: currentProjectId,
      toProjectId: to,
    );
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
