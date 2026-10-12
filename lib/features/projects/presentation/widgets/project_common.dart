import 'package:flutter/material.dart';

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
  }) : trees = buildProjectTxTree(txs);

  final Project project;
  final List<ProjectMember> members;
  final List<ProjectTransaction> txs;
  final List<ProjectTxTree> trees;
  final ProjectSummary? summary;
  final String? currentUserId;

  bool get isOwner =>
      currentUserId != null && project.ownerUserId == currentUserId;

  ProjectMember? get me {
    for (final m in members) {
      if (m.userId != null && m.userId == currentUserId) return m;
    }
    return null;
  }

  String get currency => txs.isNotEmpty ? txs.first.currency : 'THB';
  String get symbol => Currencies.symbolOf(currency);

  /// Completed / cancelled / archived → no new rows; viewers are
  /// read-only (contract §6b).
  bool get canAddTx => project.isActive && me?.role != MemberRole.viewer;

  /// Cancelled / archived → rows can't be edited, deleted or ticked.
  bool get rowsLocked => project.isLocked;

  List<ProjectMember> get currentMembers =>
      members.where((m) => m.status != MemberStatus.left).toList();

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
