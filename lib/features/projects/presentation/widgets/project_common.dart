import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/project.dart';

// ────────────────────────────────────────────────────────────────────
// Status
// ────────────────────────────────────────────────────────────────────

String projectStatusLabel(AppLocalizations l, ProjectStatus s) => switch (s) {
  ProjectStatus.active => l.projectStatusActive,
  ProjectStatus.completed => l.projectStatusCompleted,
  ProjectStatus.cancelled => l.projectStatusCancelled,
  ProjectStatus.archived => l.projectStatusArchived,
};

/// A status's chip tone (use with `AppChip(selected: true, dot: true)`).
AppChipTone projectStatusTone(ProjectStatus s) => switch (s) {
  ProjectStatus.active => AppChipTone.primary,
  ProjectStatus.completed => AppChipTone.success,
  ProjectStatus.cancelled => AppChipTone.danger,
  ProjectStatus.archived => AppChipTone.neutral,
};

/// The "locked" banner text for a status, or null when nothing is locked.
String? projectLockMessage(AppLocalizations l, ProjectStatus s) => switch (s) {
  ProjectStatus.active => null,
  ProjectStatus.completed => l.projectLockedCompleted,
  ProjectStatus.cancelled => l.projectLockedCancelled,
  ProjectStatus.archived => l.projectLockedArchived,
};

// ────────────────────────────────────────────────────────────────────
// Dates
// ────────────────────────────────────────────────────────────────────

/// "12 ต.ค. – 15 ต.ค." from the API's optional `YYYY-MM-DD` start / end
/// (the year only when it isn't this year); null when neither is set.
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

/// A picked day as the API's `YYYY-MM-DD`.
String projectDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

// ────────────────────────────────────────────────────────────────────
// Members
// ────────────────────────────────────────────────────────────────────

/// A member's icon, else their initial: maps [ProjectMember] onto the kit's
/// [ProjectMemberAvatar].
Widget memberAvatar(ProjectMember m, {double size = 32}) =>
    ProjectMemberAvatar(name: m.displayName, iconCode: m.iconCode, size: size);

// ────────────────────────────────────────────────────────────────────
// Everything the detail tabs share, computed once per load.
// ────────────────────────────────────────────────────────────────────

class ProjectView {
  ProjectView({
    required this.project,
    required this.members,
    required this.txs,
    required this.summary,
    required this.currentUserId,
    this.eventTags = const [],
    this.userCurrency,
    this.page = 1,
    this.totalPages = 1,
  }) : trees = buildProjectTxTree(txs);

  /// From the page's one "open" call.
  factory ProjectView.of(
    ProjectDetail d, {
    required String? currentUserId,
    String? userCurrency,
  }) => ProjectView(
    project: d.project,
    members: d.members,
    txs: d.transactions,
    summary: d.summary,
    eventTags: d.tags,
    currentUserId: currentUserId,
    userCurrency: userCurrency,
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
    userCurrency: userCurrency,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
  );

  /// A write's [EventPatch] applied: the event, summary, members and tags
  /// replaced; the changed bill (with its splits) put in place of its old
  /// copy, or first when new; a removed bill dropped.
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
      txs: rows,
      summary: p.summary,
      eventTags: p.tags,
    );
  }

  /// The event's tags replaced (an import: `mine` flags changed), the
  /// rows' tag flags with them.
  ProjectView withEventTags(List<BoardTag> tags) =>
      _copy(eventTags: tags, txs: [for (final t in txs) t.withTagsFrom(tags)]);

  /// The next board page appended.
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

  /// Clamps [at] (an index in the old list) to [rows].
  static int _parentIndex(List<ProjectTransaction> rows, int at) =>
      at > rows.length ? rows.length : at;

  final Project project;
  final List<ProjectMember> members;
  final List<ProjectTransaction> txs;
  final List<ProjectTxTree> trees;
  final ProjectSummary? summary;

  /// The event's tags (shared by the members), with ids.
  final List<BoardTag> eventTags;
  final String? currentUserId;

  /// The signed-in user's currency (single-currency app, owner 2026-10-12).
  final String? userCurrency;

  /// The board's paging (the detail call brings the first page).
  final int page;
  final int totalPages;
  bool get hasMoreRows => page < totalPages;

  /// Server flag (falls back to the owner id for an older payload).
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

  /// Mine (one currency per user); a row's when the user's is unknown.
  String get currency {
    final mine = userCurrency;
    if (mine != null && mine.isNotEmpty) return mine;
    for (final t in txs) {
      if (t.currency.isNotEmpty) return t.currency;
    }
    return 'THB';
  }

  String get symbol => Currencies.symbolOf(currency);

  /// The BE decides (active event, I'm an active owner / contributor).
  bool get canAddTx => project.canAddBill;

  /// Cancelled / archived → rows can't be edited, deleted or ticked.
  bool get rowsLocked => project.isLocked;

  List<ProjectMember> get currentMembers =>
      members.where((m) => m.status != MemberStatus.left).toList();

  /// The event tags' ids for [names] (quick create's picks); names with no
  /// event tag yet are left out — create them first
  /// (`ProjectsRepository.createEventTag`).
  List<String> tagIdsFor(Iterable<String> names) {
    final byName = {for (final t in eventTags) t.name.toLowerCase(): t.id};
    return [for (final n in names) ?byName[n.trim().toLowerCase()]];
  }

  /// The event tag called [name], if any.
  BoardTag? eventTag(String name) {
    final n = name.trim().toLowerCase();
    for (final t in eventTags) {
      if (t.name.toLowerCase() == n) return t;
    }
    return null;
  }

  /// The payer / debtor of [tx]: the embedded `transaction_member` when the
  /// server sent it, else the members-list lookup.
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
