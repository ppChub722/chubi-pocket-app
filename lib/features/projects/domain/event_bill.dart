import '../../personal_debts/domain/debt_ledger.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction.dart';
import 'project.dart';

/// 0.4.1-2 — what I may do with a shared bill (EventBillView.rights). A
/// completed event answers all false.
class BillRights {
  const BillRights({
    this.canEdit = false,
    this.canDelete = false,
    this.canChangePayer = false,
    this.canMove = false,
  });

  final bool canEdit;
  final bool canDelete;
  final bool canChangePayer;
  final bool canMove;

  factory BillRights.fromJson(Object? json) {
    if (json is! Map) return const BillRights();
    return BillRights(
      canEdit: json['can_edit'] == true,
      canDelete: json['can_delete'] == true,
      canChangePayer: json['can_change_payer'] == true,
      canMove: json['can_move'] == true,
    );
  }
}

/// My place in a shared bill.
enum MyBillRole { payer, share, paybackFrom, paybackTo }

/// 0.4.1-2 — MY copy of a shared bill (SA3 "my copy" block): my
/// transaction, my debts of it, whether it still matches the bill.
class MyBillCopy {
  const MyBillCopy({
    required this.role,
    this.connected = true,
    this.amount = 0,
    this.transaction,
    this.paidBy,
    this.paidBackMe = false,
    this.debts = const [],
    this.inSync,
    this.differences = const [],
    this.pendingUpdate = false,
    this.privateNote,
  });

  /// false = I disconnected it: my records are plain, the bill no longer
  /// reaches me (`my_books.on: true` connects again).
  final bool connected;
  final MyBillRole role;

  /// What my copy transaction should hold: the whole bill, my share or the
  /// payback.
  final double amount;

  /// My copy transaction; null = none yet / disconnected.
  final Transaction? transaction;

  /// Someone else paid and I haven't paid them back: "จ่ายโดย {name}" in
  /// the wallet slot (no wallet).
  final BillMemberRef? paidBy;

  /// My own "คืนแล้ว" tick.
  final bool paidBackMe;

  /// My person-book rows of this bill.
  final List<DebtEntry> debts;

  /// Null when I have no copy.
  final bool? inSync;
  final List<({String field, Object? mine, Object? event})> differences;

  /// An "อัปเดตตาม" notice about this bill waits for me.
  final bool pendingUpdate;
  final String? privateNote;

  bool get isPayer => role == MyBillRole.payer;

  static MyBillCopy? tryParse(Object? json) {
    if (json is! Map) return null;
    final j = json.cast<String, dynamic>();
    final tx = j['transaction'];
    final paidBy = j['paid_by'];
    return MyBillCopy(
      connected: j['connected'] != false,
      role: switch (j['role']) {
        'payer' => MyBillRole.payer,
        'payback_from' => MyBillRole.paybackFrom,
        'payback_to' => MyBillRole.paybackTo,
        _ => MyBillRole.share,
      },
      amount: (j['amount'] as num?)?.toDouble() ?? 0,
      transaction: tx is Map
          ? Transaction.fromJson(tx.cast<String, dynamic>())
          : null,
      paidBy: paidBy is Map
          ? BillMemberRef.fromJson(paidBy.cast<String, dynamic>())
          : null,
      paidBackMe: j['paid_back_me'] == true,
      debts: [
        for (final d in (j['debts'] as List?) ?? const [])
          if (d is Map) DebtEntry.fromJson(d.cast<String, dynamic>()),
      ],
      inSync: j['in_sync'] as bool?,
      differences: [
        for (final d in (j['differences'] as List?) ?? const [])
          if (d is Map)
            (
              field: (d['field'] as String?) ?? '',
              mine: d['mine'],
              event: d['event'],
            ),
      ],
      pendingUpdate: j['pending_update'] == true,
      privateNote: j['private_note'] as String?,
    );
  }
}

/// 0.4.1-2 SA2 — GET /event-bills/{pt_id}: everything the ONE bill form
/// needs, opened from anywhere (tx detail, a debt, a notification, the
/// event page).
class EventBillView {
  const EventBillView({
    required this.tree,
    required this.event,
    required this.updatedAt,
    this.members = const [],
    this.tags = const [],
    this.rights = const BillRights(),
    this.myCopy,
  });

  /// The bill with every share ("คืนแล้ว" on each split row).
  final ProjectTxTree tree;

  /// kind event | split, status.
  final EventRef event;

  /// The people the form may pick (an event's members / a split bill's
  /// people).
  final List<ProjectMember> members;

  /// Event tags ([] on a split bill).
  final List<BoardTag> tags;
  final BillRights rights;

  /// Null when I have no part in the bill.
  final MyBillCopy? myCopy;

  /// Sent back as-is as `expected_updated_at` (409 BILL_CHANGED).
  final String updatedAt;

  bool get isSplit => event.isSplit;

  factory EventBillView.fromJson(Map<String, dynamic> json) {
    final event = EventRef.fromJson(
      (json['event'] as Map).cast<String, dynamic>(),
    );
    return EventBillView(
      tree: buildProjectTxTree(
        ProjectTransaction.flatten(
          (json['bill'] as Map).cast<String, dynamic>(),
        ),
      ).first,
      event: event,
      members: [
        for (final m in (json['members'] as List?) ?? const [])
          if (m is Map)
            ProjectMember.fromJson(
              m.cast<String, dynamic>(),
              projectId: event.id,
            ),
      ],
      tags: [
        for (final t in (json['tags'] as List?) ?? const [])
          if (t is Map) BoardTag.fromJson(t.cast<String, dynamic>()),
      ],
      rights: BillRights.fromJson(json['rights']),
      myCopy: MyBillCopy.tryParse(json['my_copy']),
      updatedAt: (json['updated_at'] as String?) ?? '',
    );
  }
}

/// DELETE /event-bills/{pt_id}: the event patch (null on a split bill).
class EventBillDeleteResult {
  const EventBillDeleteResult({
    required this.id,
    this.patch,
    this.removedProject = false,
  });

  final String id;
  final EventPatch? patch;

  /// The hidden split "event" went with its last bill.
  final bool removedProject;

  factory EventBillDeleteResult.fromJson(Map<String, dynamic> json) {
    final event = json['event'];
    return EventBillDeleteResult(
      id: json['id'] as String,
      patch: event is Map
          ? EventPatch.fromJson(event.cast<String, dynamic>())
          : null,
      removedProject: json['removed_project'] == true,
    );
  }
}
