import 'package:equatable/equatable.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction.dart';
import '../../../ui/ui.dart';

enum ProjectStatus { active, completed, cancelled, archived }

extension ProjectStatusWire on ProjectStatus {
  String get wire {
    switch (this) {
      case ProjectStatus.active:
        return 'active';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.cancelled:
        return 'cancelled';
      case ProjectStatus.archived:
        return 'archived';
    }
  }

  static ProjectStatus parse(String? s) {
    switch (s) {
      case 'completed':
        return ProjectStatus.completed;
      case 'cancelled':
        return ProjectStatus.cancelled;
      case 'archived':
        return ProjectStatus.archived;
      default:
        return ProjectStatus.active;
    }
  }
}

enum MemberRole { owner, contributor, viewer }

extension MemberRoleWire on MemberRole {
  String get wire {
    switch (this) {
      case MemberRole.owner:
        return 'owner';
      case MemberRole.contributor:
        return 'contributor';
      case MemberRole.viewer:
        return 'viewer';
    }
  }

  static MemberRole parse(String? s) {
    switch (s) {
      case 'owner':
        return MemberRole.owner;
      case 'viewer':
        return MemberRole.viewer;
      default:
        return MemberRole.contributor;
    }
  }
}

enum MemberStatus { pending, active, left }

extension MemberStatusWire on MemberStatus {
  String get wire {
    switch (this) {
      case MemberStatus.pending:
        return 'pending';
      case MemberStatus.active:
        return 'active';
      case MemberStatus.left:
        return 'left';
    }
  }

  static MemberStatus parse(String? s) {
    switch (s) {
      case 'active':
        return MemberStatus.active;
      case 'left':
        return MemberStatus.left;
      default:
        return MemberStatus.pending;
    }
  }
}

IconCode? _icon(Object? json) =>
    json is Map<String, dynamic> ? IconCode.fromJson(json) : null;

double _money(Object? v) => (v as num?)?.toDouble() ?? 0;

List<Map<String, dynamic>> _list(Object? json) =>
    ((json as List?) ?? const []).cast<Map<String, dynamic>>();

class Project extends Equatable {
  const Project({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.status,
    this.description,
    this.note,
    this.startDate,
    this.endDate,
    this.membersCount = 0,
    this.iconCode,
    this.plannedAmount,
    this.totalExpense = 0,
    this.totalIncome = 0,
    this.myNet = 0,
    this.myPaid = 0,
    this.myShare = 0,
    this.myReceivable = 0,
    this.myPayable = 0,
    this.remaining,
    this.tags = const [],
    this.myMemberId,
    this.myRole,
    this.isOwner = false,
    this.readOnly = false,
    this.canAddBill = false,
    this.canEdit = false,
    this.canManageMembers = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUserId;
  final String name;
  final String? description;
  final String? note;

  final String? startDate;
  final String? endDate;
  final ProjectStatus status;
  final int membersCount;
  final IconCode? iconCode;

  final double? plannedAmount;

  final double totalExpense;
  final double totalIncome;

  final double myNet;

  final double myPaid;
  final double myShare;

  final double myReceivable;
  final double myPayable;

  /// Planned budget left (BE `remaining` = planned − (expense − income),
  /// negative when over); null without a plan.
  final double? remaining;

  final List<EmbeddedTag> tags;

  final String? myMemberId;
  final MemberRole? myRole;

  final bool isOwner;

  final bool readOnly;
  final bool canAddBill;
  final bool canEdit;
  final bool canManageMembers;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  bool get isActive => status == ProjectStatus.active;

  bool get isUnsettled => myReceivable > 0 || myPayable > 0;

  /// Cancelled / archived: rows can't be edited, deleted or ticked.
  bool get isLocked =>
      status == ProjectStatus.cancelled || status == ProjectStatus.archived;
  bool get isResolveReady =>
      status == ProjectStatus.completed || status == ProjectStatus.archived;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      note: json['note'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      status: ProjectStatusWire.parse(json['status'] as String?),
      membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
      iconCode: _icon(json['icon_code']),
      plannedAmount: (json['planned_amount'] as num?)?.toDouble(),
      totalExpense: _money(json['total_expense']),
      totalIncome: _money(json['total_income']),
      myNet: _money(json['my_net']),
      myPaid: _money(json['my_paid']),
      myShare: _money(json['my_share']),
      myReceivable: _money(json['my_receivable']),
      myPayable: _money(json['my_payable']),
      remaining: (json['remaining'] as num?)?.toDouble(),
      tags: [for (final t in _list(json['tags'])) EmbeddedTag.fromJson(t)],
      myMemberId: json['my_member_id'] as String?,
      myRole: json['my_role'] == null
          ? null
          : MemberRoleWire.parse(json['my_role'] as String?),
      isOwner: json['is_owner'] == true,
      readOnly: json['is_locked'] == true,
      canAddBill: json['can_add_bill'] == true,
      canEdit: json['can_edit'] == true,
      canManageMembers: json['can_manage_members'] == true,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerUserId,
    name,
    description,
    note,
    startDate,
    endDate,
    status,
    membersCount,
    iconCode,
    plannedAmount,
    totalExpense,
    totalIncome,
    myNet,
    myPaid,
    myShare,
    myReceivable,
    myPayable,
    remaining,
    tags,
    myMemberId,
    myRole,
    isOwner,
    readOnly,
    canAddBill,
    canEdit,
    canManageMembers,
    createdAt,
    updatedAt,
  ];
}

class ProjectMember extends Equatable {
  const ProjectMember({
    required this.id,
    required this.projectId,
    required this.displayName,
    required this.role,
    required this.status,
    this.userId,
    this.iconCode,
    this.isMe = false,
    this.contactId,
  });

  final String id;
  final String projectId;
  final String? userId;

  /// MY contact for this member (linked: the contact of that user; typed: my
  /// contact with the same name); null when none and on my own row.
  final String? contactId;

  final String displayName;
  final MemberRole role;
  final MemberStatus status;
  final IconCode? iconCode;
  final bool isMe;

  bool get isLinked => userId != null;
  bool get isAdHoc => userId == null;
  bool get isOwner => role == MemberRole.owner;

  factory ProjectMember.fromJson(
    Map<String, dynamic> json, {
    String projectId = '',
  }) {
    return ProjectMember(
      id: json['id'] as String,
      projectId: (json['project_id'] as String?) ?? projectId,
      userId: json['user_id'] as String?,
      displayName:
          (json['name'] as String?) ?? (json['display_name'] as String?) ?? '?',
      role: MemberRoleWire.parse(json['role'] as String?),
      status: MemberStatusWire.parse(json['status'] as String?),
      iconCode: _icon(json['icon_code']),
      isMe: json['is_me'] == true,
      contactId: json['contact_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    userId,
    contactId,
    displayName,
    role,
    status,
    iconCode,
    isMe,
  ];
}

class ProjectMemberRef extends Equatable {
  const ProjectMemberRef({
    required this.id,
    required this.name,
    this.userId,
    this.iconCode,
    this.isMe = false,
  });

  final String id;
  final String? userId;
  final String name;
  final IconCode? iconCode;
  final bool isMe;

  static ProjectMemberRef? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return ProjectMemberRef(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: (json['name'] as String?) ?? '?',
      iconCode: _icon(json['icon_code']),
      isMe: json['is_me'] == true,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, iconCode, isMe];
}

class BoardTag extends Equatable {
  const BoardTag({
    required this.id,
    required this.name,
    this.iconCode,
    this.mine = false,
    this.count = 0,
  });

  final String id;
  final String name;
  final IconCode? iconCode;

  final bool mine;

  final int count;

  factory BoardTag.fromJson(Map<String, dynamic> json) => BoardTag(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    iconCode: _icon(json['icon_code']),
    mine: json['mine'] == true,
    count: (json['count'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [id, name, iconCode, mine, count];
}

class BoardSourceTx extends Equatable {
  const BoardSourceTx({required this.id, this.description, this.accountName});

  final String id;
  final String? description;
  final String? accountName;

  static BoardSourceTx? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final account = json['account'];
    return BoardSourceTx(
      id: json['id'] as String,
      description: json['description'] as String?,
      accountName: account is Map<String, dynamic>
          ? account['name'] as String?
          : null,
    );
  }

  @override
  List<Object?> get props => [id, description, accountName];
}

class ProjectTransaction extends Equatable {
  const ProjectTransaction({
    required this.id,
    required this.projectId,
    required this.transactionMemberId,
    required this.recordUserId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    required this.marks,
    this.parentProjectTransactionId,
    this.description,
    this.note,
    this.tags = const [],
    this.tagRefs = const [],
    this.transactionMember,
    this.myMark = false,
    this.myShare = 0,
    this.locked = false,
    this.linked = false,
    this.myBooked = false,
    this.myBooks = const [],
    this.sourceTx,
  });

  final String id;
  final String projectId;

  /// A payback: [transactionMember] paid back the one child's member.
  bool get isPayback => type == 'payback';

  /// My part is already in my books (a tx / repayment / debt points here).
  final bool myBooked;

  /// Which parts of my books hold it: [bookTx] / [bookDebt] / [bookRepay].
  final List<String> myBooks;

  static const bookTx = 'tx';
  static const bookDebt = 'debt';
  static const bookRepay = 'repay';

  final ProjectMemberRef? transactionMember;

  final String? parentProjectTransactionId;

  final String transactionMemberId;
  final String recordUserId;
  final String type; // expense | income

  final String currency;
  final double amount;
  final String date;
  final String? description;
  final String? note;

  final List<String> tags;

  final List<BoardTag> tagRefs;

  final List<String> marks;
  final bool myMark;

  final double myShare;

  /// I can't edit it (event not active / I'm a viewer).
  final bool locked;

  final bool linked;

  final BoardSourceTx? sourceTx;

  bool get isParent => parentProjectTransactionId == null;
  bool get isChild => parentProjectTransactionId != null;

  bool isMarkedBy(String projectMemberId) => marks.contains(projectMemberId);

  static List<String> _ids(Object? json) =>
      ((json as List?) ?? const []).map((e) => e as String).toList();

  /// A bill (API `BoardRow`) without its children — see [flatten].
  factory ProjectTransaction.fromJson(Map<String, dynamic> json) {
    final member = ProjectMemberRef.tryParse(json['transaction_member']);
    final tagRefs = [
      for (final t in ((json['tags'] as List?) ?? const []))
        if (t is Map<String, dynamic>) BoardTag.fromJson(t),
    ];
    return ProjectTransaction(
      id: json['id'] as String,
      projectId: (json['project_id'] as String?) ?? '',
      parentProjectTransactionId:
          json['parent_project_transaction_id'] as String?,
      transactionMemberId:
          member?.id ?? (json['transaction_member_id'] as String? ?? ''),
      transactionMember: member,
      recordUserId: (json['record_user_id'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'expense',
      amount: _money(json['amount']),
      currency: (json['currency'] as String?) ?? '',
      date: (json['date'] as String?) ?? '',
      description: json['description'] as String?,
      note: json['note'] as String?,
      tags: [for (final t in tagRefs) t.name],
      tagRefs: tagRefs,
      marks: _ids(json['marks']),
      myMark: json['my_mark'] == true,
      myShare: _money(json['my_share']),
      locked: json['locked'] == true,
      linked: json['linked'] == true,
      myBooked: json['my_booked'] == true,
      myBooks: [
        if (json['my_books'] case final Map<String, dynamic> b)
          for (final k in const [bookTx, bookDebt, bookRepay])
            if (b[k] == true) k,
      ],
      sourceTx: BoardSourceTx.tryParse(json['source_tx']),
    );
  }

  factory ProjectTransaction.split(
    Map<String, dynamic> json,
    ProjectTransaction parent,
  ) {
    final member = ProjectMemberRef.tryParse(json['transaction_member']);
    return ProjectTransaction(
      id: json['id'] as String,
      projectId: parent.projectId,
      parentProjectTransactionId: parent.id,
      transactionMemberId: member?.id ?? '',
      transactionMember: member,
      recordUserId: parent.recordUserId,
      type: parent.type,
      amount: _money(json['amount']),
      currency: parent.currency,
      date: parent.date,
      marks: _ids(json['marks']),
      myMark: json['my_mark'] == true,
      locked: parent.locked,
    );
  }

  ProjectTransaction withTagsFrom(List<BoardTag> tags) {
    if (tagRefs.isEmpty) return this;
    final byId = {for (final t in tags) t.id: t};
    final fresh = [
      for (final t in tagRefs)
        if (byId[t.id] case final f?)
          BoardTag(id: t.id, name: f.name, iconCode: f.iconCode, mine: f.mine),
    ];
    return ProjectTransaction(
      id: id,
      projectId: projectId,
      parentProjectTransactionId: parentProjectTransactionId,
      transactionMemberId: transactionMemberId,
      transactionMember: transactionMember,
      recordUserId: recordUserId,
      type: type,
      amount: amount,
      currency: currency,
      date: date,
      description: description,
      note: note,
      tags: [for (final t in fresh) t.name],
      tagRefs: fresh,
      marks: marks,
      myMark: myMark,
      myShare: myShare,
      locked: locked,
      linked: linked,
      myBooked: myBooked,
      myBooks: myBooks,
      sourceTx: sourceTx,
    );
  }

  static List<ProjectTransaction> flatten(Map<String, dynamic> json) {
    final parent = ProjectTransaction.fromJson(json);
    return [
      parent,
      for (final c in _list(json['children']))
        ProjectTransaction.split(c, parent),
    ];
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    parentProjectTransactionId,
    transactionMemberId,
    transactionMember,
    recordUserId,
    type,
    amount,
    currency,
    date,
    description,
    note,
    tags,
    tagRefs,
    marks,
    myMark,
    myShare,
    locked,
    linked,
    myBooked,
    myBooks,
    sourceTx,
  ];
}

class ProjectSplitInput extends Equatable {
  const ProjectSplitInput({required this.memberId, required this.amount});
  final String memberId;
  final double amount;

  Map<String, dynamic> toJson() => {'member_id': memberId, 'amount': amount};

  @override
  List<Object?> get props => [memberId, amount];
}

class ProjectTxTree extends Equatable {
  const ProjectTxTree({required this.parent, required this.children});
  final ProjectTransaction parent;
  final List<ProjectTransaction> children;

  double get childrenTotal =>
      children.fold<double>(0, (acc, c) => acc + c.amount);

  double get parentShare => parent.amount - childrenTotal;

  @override
  List<Object?> get props => [parent, children];
}

List<ProjectTxTree> buildProjectTxTree(List<ProjectTransaction> flat) {
  final parents = <ProjectTransaction>[];
  final byParent = <String, List<ProjectTransaction>>{};
  for (final pt in flat) {
    if (pt.isParent) {
      parents.add(pt);
    } else {
      byParent.putIfAbsent(pt.parentProjectTransactionId!, () => []).add(pt);
    }
  }
  return [
    for (final p in parents)
      ProjectTxTree(parent: p, children: byParent[p.id] ?? const []),
  ];
}

class ProjectSummary extends Equatable {
  const ProjectSummary({
    required this.projectId,
    required this.totalExpense,
    required this.totalIncome,
    required this.transactionCount,
    required this.memberCount,
    this.plannedAmount,
    this.spentNet,
    this.remaining,
    this.myPaid,
    this.myShare,
    this.myNet,
    this.positions = const [],
    this.byTag = const [],
  });

  final String projectId;
  final double totalExpense;
  final double totalIncome;
  final int transactionCount;
  final int memberCount;

  /// Plan-vs-actual trio: null without a plan.
  final double? plannedAmount;
  final double? spentNet;
  final double? remaining;

  final double? myPaid;
  final double? myShare;
  final double? myNet;

  final List<ProjectMemberPosition> positions;

  final List<ProjectTagTotal> byTag;

  bool get hasPlan => plannedAmount != null;
  bool get isOverPlan => (remaining ?? 0) < 0;

  factory ProjectSummary.fromJson(
    Map<String, dynamic> json, {
    String projectId = '',
  }) {
    final my = json['my_position'];
    return ProjectSummary(
      projectId: (json['project_id'] as String?) ?? projectId,
      totalExpense: _money(json['total_expense']),
      totalIncome: _money(json['total_income']),
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      plannedAmount: (json['planned_amount'] as num?)?.toDouble(),
      spentNet: (json['spent_net'] as num?)?.toDouble(),
      remaining: (json['remaining'] as num?)?.toDouble(),
      myPaid: my is Map ? _money(my['paid']) : null,
      myShare: my is Map ? _money(my['share']) : null,
      myNet: my is Map ? _money(my['net']) : null,
      positions: [
        for (final m in _list(json['members']))
          ProjectMemberPosition.fromJson(m),
      ],
      byTag: [
        for (final t in _list(json['by_tag'])) ProjectTagTotal.fromJson(t),
      ],
    );
  }

  @override
  List<Object?> get props => [
    projectId,
    totalExpense,
    totalIncome,
    transactionCount,
    memberCount,
    plannedAmount,
    spentNet,
    remaining,
    myPaid,
    myShare,
    myNet,
    positions,
    byTag,
  ];
}

class ProjectMemberPosition extends Equatable {
  const ProjectMemberPosition({
    required this.memberId,
    required this.displayName,
    required this.paid,
    required this.share,
    required this.net,
    this.receivable = 0,
    this.payable = 0,
    this.sent = 0,
    this.received = 0,
    this.userId,
    this.iconCode,
  });

  final String memberId;
  final String? userId;
  final String displayName;
  final IconCode? iconCode;
  final double paid;
  final double share;

  /// Paybacks this member made / got; net = paid − share + sent − received.
  final double sent;
  final double received;
  final double net;

  final double receivable;
  final double payable;

  factory ProjectMemberPosition.fromJson(Map<String, dynamic> json) {
    final m = ProjectMemberRef.tryParse(json['member']);
    return ProjectMemberPosition(
      memberId: m?.id ?? (json['member_id'] as String? ?? ''),
      userId: m?.userId ?? json['user_id'] as String?,
      displayName: m?.name ?? (json['display_name'] as String? ?? '?'),
      iconCode: m?.iconCode,
      paid: _money(json['paid']),
      share: _money(json['share']),
      net: _money(json['net']),
      receivable: _money(json['receivable']),
      payable: _money(json['payable']),
      sent: _money(json['sent']),
      received: _money(json['received']),
    );
  }

  @override
  List<Object?> get props => [
    memberId,
    userId,
    displayName,
    iconCode,
    paid,
    share,
    sent,
    received,
    net,
    receivable,
    payable,
  ];
}

/// [from] owes [to] [amount] (GET /projects/:id/settle).
class SettleLine extends Equatable {
  const SettleLine({
    required this.from,
    required this.to,
    required this.amount,
    this.recorded = false,
  });

  final ProjectMemberRef from;
  final ProjectMemberRef to;
  final double amount;

  /// A line with me in it that I already recorded as a debt.
  final bool recorded;

  bool get mine => from.isMe || to.isMe;

  static SettleLine? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final from = ProjectMemberRef.tryParse(json['from']);
    final to = ProjectMemberRef.tryParse(json['to']);
    if (from == null || to == null) return null;
    return SettleLine(
      from: from,
      to: to,
      amount: _money(json['amount']),
      recorded: json['recorded'] == true,
    );
  }

  @override
  List<Object?> get props => [from, to, amount, recorded];
}

/// Who pays whom: [pairs] nets each two members; [simplified] is the
/// fewest transfers.
class EventSettle extends Equatable {
  const EventSettle({this.pairs = const [], this.simplified = const []});

  final List<SettleLine> pairs;
  final List<SettleLine> simplified;

  factory EventSettle.fromJson(Map<String, dynamic> json) {
    List<SettleLine> lines(String k) => [
      for (final l in (json[k] as List?) ?? const []) ?SettleLine.tryParse(l),
    ];
    return EventSettle(pairs: lines('pairs'), simplified: lines('simplified'));
  }

  @override
  List<Object?> get props => [pairs, simplified];
}

class ProjectTagTotal extends Equatable {
  const ProjectTagTotal({
    required this.total,
    required this.count,
    this.tag,
    this.share = 0,
  });

  final BoardTag? tag;
  final double total;

  final double share;
  final int count;

  String get name => tag?.name ?? '';
  bool get isUntagged => tag == null;

  factory ProjectTagTotal.fromJson(Map<String, dynamic> json) {
    final t = json['tag'];
    return ProjectTagTotal(
      tag: t is Map<String, dynamic> ? BoardTag.fromJson(t) : null,
      total: _money(json['total']),
      share: _money(json['share']),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [tag, total, share, count];
}

List<ProjectTransaction> _board(Object? rows) => [
  for (final r in _list(rows)) ...ProjectTransaction.flatten(r),
];

class EventDeletePreview {
  const EventDeletePreview({
    this.bills = 0,
    this.members = 0,
    this.linkedTxCount = 0,
  });

  factory EventDeletePreview.fromJson(Map<String, dynamic> json) =>
      EventDeletePreview(
        bills: (json['bills'] as num?)?.toInt() ?? 0,
        members: (json['members'] as num?)?.toInt() ?? 0,
        linkedTxCount: (json['linked_tx_count'] as num?)?.toInt() ?? 0,
      );

  final int bills;
  final int members;

  final int linkedTxCount;
}

class ProjectDetail {
  const ProjectDetail({
    required this.project,
    required this.members,
    required this.transactions,
    required this.summary,
    this.tags = const [],
    this.page = 1,
    this.totalPages = 1,
    this.deletePreview,
  });

  final EventDeletePreview? deletePreview;

  final Project project;
  final List<ProjectMember> members;

  final List<ProjectTransaction> transactions;
  final ProjectSummary summary;

  final List<BoardTag> tags;

  final int page;
  final int totalPages;

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    final project = Project.fromJson(json['event'] as Map<String, dynamic>);
    final board = json['board'] as Map<String, dynamic>?;
    final pag = board?['pagination'] as Map<String, dynamic>?;
    return ProjectDetail(
      project: project,
      members: [
        for (final m in _list(json['members']))
          ProjectMember.fromJson(m, projectId: project.id),
      ],
      transactions: _board(board?['data']),
      summary: ProjectSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
        projectId: project.id,
      ),
      tags: [for (final t in _list(json['tags'])) BoardTag.fromJson(t)],
      page: (pag?['page'] as num?)?.toInt() ?? 1,
      totalPages: (pag?['total_pages'] as num?)?.toInt() ?? 1,
      deletePreview: json['delete_preview'] is Map<String, dynamic>
          ? EventDeletePreview.fromJson(
              json['delete_preview'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// What every event write returns (API `EventPatch`): the final state to patch
/// the page from — never a re-fetch.
class EventPatch {
  const EventPatch({
    required this.project,
    required this.summary,
    required this.members,
    required this.tags,
    this.row = const [],
    this.removedRowId,
    this.accountBalances = const {},
    this.myTransaction,
  });

  final Project project;
  final ProjectSummary summary;
  final List<ProjectMember> members;
  final List<BoardTag> tags;

  final List<ProjectTransaction> row;

  final String? removedRowId;

  final Map<String, double> accountBalances;

  /// A bill edit (0.4.0-3 B3): MY tx linked to the bill (made from it, or my
  /// copy) after the edit; its event_bill.in_sync says whether to offer
  /// "แก้ในสมุดของฉันด้วย" (apply-event).
  final Transaction? myTransaction;

  factory EventPatch.fromJson(Map<String, dynamic> json) {
    final project = Project.fromJson(json['event'] as Map<String, dynamic>);
    final row = json['row'];
    return EventPatch(
      project: project,
      summary: ProjectSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
        projectId: project.id,
      ),
      members: [
        for (final m in _list(json['members']))
          ProjectMember.fromJson(m, projectId: project.id),
      ],
      tags: [for (final t in _list(json['tags'])) BoardTag.fromJson(t)],
      row: row is Map<String, dynamic>
          ? ProjectTransaction.flatten(row)
          : const [],
      removedRowId: json['removed_row_id'] as String?,
      accountBalances: WalletBalance.mapOf(json['account_balances']),
      myTransaction: json['my_transaction'] is Map
          ? Transaction.fromJson(
              (json['my_transaction'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  static List<ProjectTransaction> rowsOf(Map<String, dynamic> json) =>
      _board(json['rows']);
}

/// `POST /event-bills` / `PUT /event-bills/{pt_id}` (0.4.1-1 E8, one call
/// for the bill sheet): the bill's patch and my transaction for it. The
/// wallets, people and rows it moved arrive as its `effects` (B2: the caches
/// apply them by themselves).
class EventBillBookResult {
  const EventBillBookResult({required this.patch, this.transactionId});

  final EventPatch patch;

  /// My transaction for the bill (made or kept); null = none.
  final String? transactionId;

  factory EventBillBookResult.fromJson(Map<String, dynamic> json) =>
      EventBillBookResult(
        patch: EventPatch.fromJson(json),
        transactionId: json['transaction_id'] as String?,
      );
}

/// The bill sheet's `?preview=true` (0.4.1-1 E8): every person and wallet
/// the save would move, before → after; nothing is saved.
class EventBillBookPreview {
  const EventBillBookPreview({
    this.people = const {},
    this.wallets = const {},
    this.debtDefault = true,
  });

  /// Person key → (before, after); net > 0 = they owe me.
  final Map<String, ({double before, double after})> people;

  /// Wallet id → (before, after).
  final Map<String, ({double before, double after})> wallets;

  /// What `my_books.debt: null` does on a payback (false = my book already
  /// holds this event's debt with them).
  final bool debtDefault;

  factory EventBillBookPreview.fromJson(Map<String, dynamic> json) {
    double n(Object? v) => (v as num?)?.toDouble() ?? 0;
    return EventBillBookPreview(
      people: {
        for (final p in _list(json['people']))
          p['key'] as String: (before: n(p['before']), after: n(p['after'])),
      },
      wallets: {
        for (final w in _list(json['wallets']))
          w['account_id'] as String: (
            before: n(w['before']),
            after: n(w['after']),
          ),
      },
      debtDefault: json['debt_default'] as bool? ?? true,
    );
  }
}

/// Share / paid: active events. Receivable / payable and the counts: every
/// event but archived.
class ProjectListSummary extends Equatable {
  const ProjectListSummary({
    this.myShareTotal = 0,
    this.paidTotal = 0,
    this.receivableTotal = 0,
    this.payableTotal = 0,
    this.all = 0,
    this.active = 0,
    this.unsettled = 0,
    this.receivable = 0,
    this.payable = 0,
    this.ended = 0,
  });

  final double myShareTotal;
  final double paidTotal;
  final double receivableTotal;
  final double payableTotal;

  final int all;
  final int active;
  final int unsettled;
  final int receivable;
  final int payable;
  final int ended;

  double get net => receivableTotal - payableTotal;

  factory ProjectListSummary.fromJson(Map<String, dynamic> json) {
    final c = json['counts'];
    int n(String k) => c is Map ? (c[k] as num?)?.toInt() ?? 0 : 0;
    return ProjectListSummary(
      myShareTotal: _money(json['my_share_total']),
      paidTotal: _money(json['paid_total']),
      receivableTotal: _money(json['receivable_total']),
      payableTotal: _money(json['payable_total']),
      all: n('all'),
      active: n('active'),
      unsettled: n('unsettled'),
      receivable: n('receivable'),
      payable: n('payable'),
      ended: n('ended'),
    );
  }

  @override
  List<Object?> get props => [
    myShareTotal,
    paidTotal,
    receivableTotal,
    payableTotal,
    all,
    active,
    unsettled,
    receivable,
    payable,
    ended,
  ];
}

class ProjectPage {
  const ProjectPage({
    required this.projects,
    required this.page,
    required this.totalPages,
    this.summary,
  });

  final List<Project> projects;
  final int page;
  final int totalPages;

  final ProjectListSummary? summary;

  bool get hasMore => page < totalPages;
}

enum ProjectSort { updatedDesc, startDateDesc, nameAsc }

extension ProjectSortWire on ProjectSort {
  String get wire => switch (this) {
    ProjectSort.updatedDesc => 'updated_desc',
    ProjectSort.startDateDesc => 'start_date_desc',
    ProjectSort.nameAsc => 'name_asc',
  };
}
