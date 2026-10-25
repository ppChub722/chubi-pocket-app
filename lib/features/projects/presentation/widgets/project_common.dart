import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/project.dart';

String projectStatusLabel(AppLocalizations l, ProjectStatus s) => switch (s) {
  ProjectStatus.active => l.projectStatusActive,
  ProjectStatus.completed => l.projectStatusCompleted,
  ProjectStatus.cancelled => l.projectStatusCancelled,
  ProjectStatus.archived => l.projectStatusArchived,
};

AppChipTone projectStatusTone(ProjectStatus s) => switch (s) {
  ProjectStatus.active => AppChipTone.primary,
  ProjectStatus.completed => AppChipTone.success,
  ProjectStatus.cancelled => AppChipTone.danger,
  ProjectStatus.archived => AppChipTone.neutral,
};

String? projectLockMessage(AppLocalizations l, ProjectStatus s) => switch (s) {
  ProjectStatus.active => null,
  ProjectStatus.completed => l.projectLockedCompleted,
  ProjectStatus.cancelled => l.projectLockedCancelled,
  ProjectStatus.archived => l.projectLockedArchived,
};

String? projectDateRange(BuildContext context, String? start, String? end) {
  final s = DateFormatter.parseDay(start);
  final e = DateFormatter.parseDay(end);
  if (s == null && e == null) return null;
  final locale = Localizations.localeOf(context).languageCode;
  final year = DateTime.now().year;
  String fmt(DateTime d) => d.year == year
      ? DateFormat.MMMd(locale).format(d)
      : DateFormat.yMMMd(locale).format(d);
  if (s != null && e != null) {
    return s == e ? fmt(s) : '${fmt(s)} – ${fmt(e)}';
  }
  return s != null ? fmt(s) : '– ${fmt(e!)}';
}

String projectDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

Widget memberAvatar(ProjectMember m, {double size = 32}) =>
    ProjectMemberAvatar(name: m.displayName, iconCode: m.iconCode, size: size);

class ProjectView {
  ProjectView({
    required this.project,
    required this.members,
    required this.txs,
    required this.summary,
    required this.currentUserId,
    this.eventTags = const [],
    this.page = 1,
    this.totalPages = 1,
  }) : trees = buildProjectTxTree(txs);

  factory ProjectView.of(ProjectDetail d, {required String? currentUserId}) =>
      ProjectView(
        project: d.project,
        members: d.members,
        txs: d.transactions,
        summary: d.summary,
        eventTags: d.tags,
        currentUserId: currentUserId,
        page: d.page,
        totalPages: d.totalPages,
      );

  ProjectView _copy({
    Project? project,
    List<ProjectMember>? members,
    List<ProjectTransaction>? txs,
    ProjectSummary? summary,
    List<BoardTag>? eventTags,
    int? page,
    int? totalPages,
  }) => ProjectView(
    project: project ?? this.project,
    members: members ?? this.members,
    txs: txs ?? this.txs,
    summary: summary ?? this.summary,
    eventTags: eventTags ?? this.eventTags,
    currentUserId: currentUserId,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
  );

  ProjectView apply(EventPatch p) {
    var rows = txs;
    final removed = p.removedRowId;
    if (removed != null) rows = _without(rows, removed);
    if (p.row.isNotEmpty) {
      final id = p.row.first.id;
      final at = rows.indexWhere((t) => t.id == id);
      rows = _without(rows, id);
      final insertAt = at < 0 ? 0 : _parentIndex(rows, at);
      rows = [...rows.take(insertAt), ...p.row, ...rows.skip(insertAt)];
    }
    return _copy(
      project: p.project,
      members: p.members,
      txs: [for (final t in rows) t.withTagsFrom(p.tags)],
      summary: p.summary,
      eventTags: p.tags,
    );
  }

  ProjectView withEventTags(List<BoardTag> tags) =>
      _copy(eventTags: tags, txs: [for (final t in txs) t.withTagsFrom(tags)]);

  ProjectView withMore(List<ProjectTransaction> more, {required int page}) {
    final seen = {for (final t in txs) t.id};
    return _copy(
      txs: [...txs, ...more.where((t) => !seen.contains(t.id))],
      page: page,
    );
  }

  /// [rows] without the bill [id] and its splits.
  static List<ProjectTransaction> _without(
    List<ProjectTransaction> rows,
    String id,
  ) => [
    for (final t in rows)
      if (t.id != id && t.parentProjectTransactionId != id) t,
  ];

  static int _parentIndex(List<ProjectTransaction> rows, int at) =>
      at > rows.length ? rows.length : at;

  final Project project;
  final List<ProjectMember> members;
  final List<ProjectTransaction> txs;
  final List<ProjectTxTree> trees;
  final ProjectSummary? summary;

  final List<BoardTag> eventTags;
  final String? currentUserId;

  final int page;
  final int totalPages;
  bool get hasMoreRows => page < totalPages;

  bool get isOwner =>
      project.isOwner ||
      (currentUserId != null && project.ownerUserId == currentUserId);

  ProjectMember? get me {
    for (final m in members) {
      if (m.isMe) return m;
    }
    for (final m in members) {
      if (m.userId != null && m.userId == currentUserId) return m;
    }
    return null;
  }

  bool get canAddTx => project.canAddBill;

  /// Cancelled / archived → rows can't be edited, deleted or ticked.
  bool get rowsLocked => project.isLocked;

  List<ProjectMember> get currentMembers =>
      members.where((m) => m.status != MemberStatus.left).toList();

  List<String> tagIdsFor(Iterable<String> names) {
    final byName = {for (final t in eventTags) t.name.toLowerCase(): t.id};
    return [for (final n in names) ?byName[n.trim().toLowerCase()]];
  }

  BoardTag? eventTag(String name) {
    final n = name.trim().toLowerCase();
    for (final t in eventTags) {
      if (t.name.toLowerCase() == n) return t;
    }
    return null;
  }

  ProjectMember memberOf(ProjectTransaction tx) {
    final r = tx.transactionMember;
    if (r == null) return member(tx.transactionMemberId);
    final listed = members.where((m) => m.id == r.id);
    return ProjectMember(
      id: r.id,
      projectId: project.id,
      userId: r.userId,
      displayName: r.name,
      iconCode: r.iconCode,
      isMe: r.isMe,
      // The listed member's contact: a debt from this row binds to it.
      contactId: listed.isEmpty ? null : listed.first.contactId,
      role: listed.isEmpty ? MemberRole.contributor : listed.first.role,
      status: listed.isEmpty ? MemberStatus.active : listed.first.status,
    );
  }

  ProjectMember member(String id) => members.firstWhere(
    (m) => m.id == id,
    orElse: () => ProjectMember(
      id: id,
      projectId: project.id,
      displayName: '?',
      role: MemberRole.contributor,
      status: MemberStatus.left,
    ),
  );
}
