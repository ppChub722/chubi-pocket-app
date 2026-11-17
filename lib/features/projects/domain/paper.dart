import '../../transactions/domain/refs.dart' show EmbeddedPerson, EventRef;

double _money(Object? v) => (v as num?)?.toDouble() ?? 0;

/// One person on a paper (`PaperPerson`): their row id (kept on an edit),
/// who they are and their numbers.
class PaperPersonView {
  const PaperPersonView({
    required this.id,
    required this.name,
    required this.share,
    required this.paid,
    this.memberId,
    this.contactId,
    this.person,
    this.isMe = false,
    this.paidBack = false,
    this.status = 'joined',
  });

  final String id;

  /// The name typed on the bill.
  final String name;
  final String? memberId;
  final String? contactId;

  /// My contact for them (its shown name and avatar); null = none.
  final EmbeddedPerson? person;
  final bool isMe;
  final double share;
  final double paid;
  final bool paidBack;
  final String status;

  factory PaperPersonView.fromJson(Map<String, dynamic> j) {
    final person = (j['person'] as Map?)?.cast<String, dynamic>() ?? const {};
    return PaperPersonView(
      id: j['id'] as String,
      name: (j['name'] as String?) ?? '',
      memberId: j['member_id'] as String?,
      contactId: person['contact_id'] as String?,
      person: person['contact_id'] == null
          ? null
          : EmbeddedPerson.fromJson(person),
      isMe: j['is_me'] == true,
      share: _money(j['share']),
      paid: _money(j['paid']),
      paidBack: j['paid_back'] == true,
      status: (j['status'] as String?) ?? 'joined',
    );
  }
}

/// A paper as one user sees it (`PaperView`), for the bill form's edit.
class PaperView {
  const PaperView({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.version,
    required this.people,
    this.projectId,
    this.event,
    this.paybackKind,
    this.description,
    this.note,
    this.splitMode = 'custom',
    this.myTransaction,
    this.myDebtIds = const [],
    this.canEdit = false,
    this.canRemovePeople = false,
    this.canLeave = false,
  });

  final String id;
  final String? projectId;

  /// The event it is a bill of (name, icon); null = a split bill.
  final EventRef? event;
  final String type;
  final String? paybackKind;
  final double amount;
  final String date;
  final String? description;
  final String? note;
  final String splitMode;
  final int version;
  final List<PaperPersonView> people;

  /// My transaction of it (the `Transaction` json), null = none.
  final Map<String, dynamic>? myTransaction;
  final List<String> myDebtIds;
  final bool canEdit;
  final bool canRemovePeople;
  final bool canLeave;

  bool get isPayback => type == 'payback';
  PaperPersonView? get me => people.where((p) => p.isMe).firstOrNull;

  /// My transaction of it, null = none yet.
  String? get myTransactionId => myTransaction?['id'] as String?;

  factory PaperView.fromJson(Map<String, dynamic> j) {
    final books = (j['my_books'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rights = (j['rights'] as Map?)?.cast<String, dynamic>() ?? const {};
    final projectId = j['project_id'] as String?;
    return PaperView(
      id: j['id'] as String,
      projectId: projectId,
      event: projectId != null && j['event'] is Map
          ? EventRef.fromJson((j['event'] as Map).cast<String, dynamic>())
          : null,
      type: (j['type'] as String?) ?? 'expense',
      paybackKind: j['payback_kind'] as String?,
      amount: _money(j['amount']),
      date: (j['date'] as String?) ?? '',
      description: j['description'] as String?,
      note: j['note'] as String?,
      splitMode: (j['split_mode'] as String?) ?? 'custom',
      version: (j['version'] as num?)?.toInt() ?? 1,
      people: [
        for (final p in (j['people'] as List?) ?? const [])
          PaperPersonView.fromJson((p as Map).cast<String, dynamic>()),
      ],
      myTransaction: (books['transaction'] as Map?)?.cast<String, dynamic>(),
      myDebtIds: [
        for (final id in (books['debt_ids'] as List?) ?? const []) id as String,
      ],
      canEdit: rights['edit'] == true,
      canRemovePeople: rights['remove_people'] == true,
      canLeave: rights['leave'] == true,
    );
  }
}

/// What a paper write answers that the caller acts on (`PaperWriteResult`):
/// the paper, its people in order, and my transaction of it. The rest of the
/// answer (`effects`) reaches the caches through the effects bus.
class PaperWriteResult {
  const PaperWriteResult({
    required this.paperId,
    required this.personIds,
    this.projectId,
    this.transactionId,
  });

  final String paperId;
  final String? projectId;

  /// The paper's people, in the order they were sent.
  final List<String> personIds;

  /// My transaction of it (null = my claim made none).
  final String? transactionId;

  factory PaperWriteResult.fromJson(Map<String, dynamic> json) {
    final paper = (json['paper'] as Map).cast<String, dynamic>();
    final books = paper['my_books'] as Map?;
    final tx = books?['transaction'] as Map?;
    return PaperWriteResult(
      paperId: paper['id'] as String,
      projectId: paper['project_id'] as String?,
      personIds: [
        for (final p in paper['people'] as List? ?? const [])
          (p as Map)['id'] as String,
      ],
      transactionId: tx?['id'] as String?,
    );
  }
}
