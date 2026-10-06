import 'package:flutter/material.dart';

import '../../../../core/constants/currencies.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
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

Tone projectStatusTone(ProjectStatus s) => switch (s) {
      ProjectStatus.active => Tone.primary,
      ProjectStatus.completed => Tone.success,
      ProjectStatus.cancelled => Tone.danger,
      ProjectStatus.archived => Tone.neutral,
    };

class ProjectStatusPill extends StatelessWidget {
  const ProjectStatusPill({
    required this.status,
    this.onTap,
    this.dense = false,
    super.key,
  });

  final ProjectStatus status;

  /// Owner only — opens the status picker.
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StatusPill(
      label: projectStatusLabel(l, status),
      tone: projectStatusTone(status),
      dense: dense,
      onTap: onTap,
    );
  }
}

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

/// A member's icon, else a coloured initial (stable per member id).
class ProjectMemberAvatar extends StatelessWidget {
  const ProjectMemberAvatar({required this.member, this.size = 32, super.key});

  final ProjectMember member;
  final double size;

  static const _palette = <Color>[
    Color(0xFF64B5F6), Color(0xFFAED581), Color(0xFFFFB74D),
    Color(0xFFBA68C8), Color(0xFF4DD0E1), Color(0xFFF06292),
    Color(0xFF9575CD), Color(0xFFFFD54F), Color(0xFFA1887F),
    Color(0xFF4FC3F7), Color(0xFF7986CB), Color(0xFFE57373),
  ];

  @override
  Widget build(BuildContext context) {
    if (member.iconCode != null) {
      return IconDisplay(
          type: IconType.projectMember, size: size, iconCode: member.iconCode);
    }
    final color = _palette[member.id.hashCode.abs() % _palette.length];
    final name = member.displayName;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withValues(alpha: 0.28),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(
            fontSize: size * 0.4, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

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

  /// Completed / cancelled / archived → no new rows.
  bool get canAddTx => project.isActive;

  /// Cancelled / archived → rows can't be edited, deleted or ticked.
  bool get rowsLocked => project.isLocked;

  List<ProjectMember> get currentMembers =>
      members.where((m) => m.status != MemberStatus.left).toList();

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
