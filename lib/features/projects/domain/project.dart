import 'package:equatable/equatable.dart';

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

class Project extends Equatable {
  const Project({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.status,
    this.type,
    this.description,
    this.startDate,
    this.endDate,
    this.membersCount = 0,
    this.iconId,
    this.colorId,
  });

  final String id;
  final String ownerUserId;
  final String name;
  final String? type;
  final String? description;
  final String? startDate;
  final String? endDate;
  final ProjectStatus status;
  final int membersCount;
  final String? iconId;
  final String? colorId;

  bool get isActive => status == ProjectStatus.active;
  bool get isLocked =>
      status == ProjectStatus.cancelled || status == ProjectStatus.archived;
  bool get isResolveReady =>
      status == ProjectStatus.completed || status == ProjectStatus.archived;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String?,
      description: json['description'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      status: ProjectStatusWire.parse(json['status'] as String?),
      membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
      iconId: json['icon_id'] as String?,
      colorId: json['color_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerUserId,
        name,
        type,
        description,
        startDate,
        endDate,
        status,
        membersCount,
        iconId,
        colorId,
      ];
}

/// Post-migration 27: members are linked (userId set) or ad-hoc (userId null).
/// The previous "contact" kind was collapsed — contacts are user-scoped, so
/// storing a contact_id on a shared project_members row was ambiguous. FE
/// resolves contact -> linkedUserId locally and adds members by-email or
/// ad-hoc.
class ProjectMember extends Equatable {
  const ProjectMember({
    required this.id,
    required this.projectId,
    required this.displayName,
    required this.role,
    required this.status,
    this.userId,
    this.avatarUrl,
  });

  final String id;
  final String projectId;
  final String? userId;
  final String displayName;
  final MemberRole role;
  final MemberStatus status;
  final String? avatarUrl;

  bool get isLinked => userId != null;
  bool get isAdHoc => userId == null;
  bool get isOwner => role == MemberRole.owner;

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String?,
      displayName: json['display_name'] as String,
      role: MemberRoleWire.parse(json['role'] as String?),
      status: MemberStatusWire.parse(json['status'] as String?),
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, userId, displayName, role, status, avatarUrl];
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
    this.categoryName,
    this.categoryIconId,
    this.categoryColorId,
  });

  final String id;
  final String projectId;

  /// null for parent rows; set on split-child rows.
  final String? parentProjectTransactionId;

  /// Whose money moved on the project board (the actor / payer for parent
  /// rows, the debtor for split-child rows).
  final String transactionMemberId;
  final String recordUserId;
  final String type; // expense | income
  final double amount;
  final String currency;
  final String date;
  final String? description;
  final String? note;
  final String? categoryName;
  final String? categoryIconId;
  final String? categoryColorId;

  /// project_member ids who have flagged this row resolved on the board.
  final List<String> marks;

  bool get isParent => parentProjectTransactionId == null;
  bool get isChild => parentProjectTransactionId != null;

  bool isMarkedBy(String projectMemberId) => marks.contains(projectMemberId);

  factory ProjectTransaction.fromJson(Map<String, dynamic> json) {
    return ProjectTransaction(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      parentProjectTransactionId:
          json['parent_project_transaction_id'] as String?,
      transactionMemberId: json['transaction_member_id'] as String,
      recordUserId: json['record_user_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      date: json['date'] as String,
      description: json['description'] as String?,
      note: json['note'] as String?,
      categoryName: json['category_name'] as String?,
      categoryIconId: json['category_icon_id'] as String?,
      categoryColorId: json['category_color_id'] as String?,
      marks: ((json['marks'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        parentProjectTransactionId,
        transactionMemberId,
        recordUserId,
        type,
        amount,
        currency,
        date,
        description,
        note,
        categoryName,
        categoryIconId,
        categoryColorId,
        marks,
      ];
}

/// One entry in the create/update transaction split list.
class ProjectSplitInput extends Equatable {
  const ProjectSplitInput({required this.memberId, required this.amount});
  final String memberId;
  final double amount;

  Map<String, dynamic> toJson() => {'member_id': memberId, 'amount': amount};

  @override
  List<Object?> get props => [memberId, amount];
}

/// FE-side accordion model. The repository returns a flat list (parents
/// followed by their children); [buildProjectTxTree] groups children under
/// their parent for display.
class ProjectTxTree extends Equatable {
  const ProjectTxTree({required this.parent, required this.children});
  final ProjectTransaction parent;
  final List<ProjectTransaction> children;

  /// Sum of children's amounts. Useful for "post-split" display on parent.
  double get childrenTotal =>
      children.fold<double>(0, (acc, c) => acc + c.amount);

  /// Parent's own share = parent.amount - sum(children.amount).
  double get parentShare => parent.amount - childrenTotal;

  @override
  List<Object?> get props => [parent, children];
}

/// Builds an accordion tree from a flat list of project transactions. Any
/// child whose parent is not in [flat] is dropped (defensive — should not
/// happen with the BE pagination contract, but keeps the UI from crashing).
List<ProjectTxTree> buildProjectTxTree(List<ProjectTransaction> flat) {
  final parents = <ProjectTransaction>[];
  final byParent = <String, List<ProjectTransaction>>{};
  for (final pt in flat) {
    if (pt.isParent) {
      parents.add(pt);
    } else {
      byParent
          .putIfAbsent(pt.parentProjectTransactionId!, () => [])
          .add(pt);
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
  });

  final String projectId;
  final double totalExpense;
  final double totalIncome;
  final int transactionCount;
  final int memberCount;

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      projectId: json['project_id'] as String,
      totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0,
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [projectId, totalExpense, totalIncome, transactionCount, memberCount];
}
