import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import 'package:pp_forge/pp_forge.dart';

/// Where one produced item of a recurring stands (owner 2026-10-13, FINAL):
/// derived from its link — no link yet and its date is ahead = [upcoming];
/// its date came but nothing was made = [notCreated]; a pending draft =
/// [pending]; a real transaction = [done]; [archived] = "don't want it"
/// (a user flag, hidden).
enum OccurrenceState {
  upcoming(StatusKind.upcoming),
  notCreated(StatusKind.notCreated),
  pending(StatusKind.pending),
  done(StatusKind.done),
  archived(StatusKind.archived);

  const OccurrenceState(this.kind);

  final StatusKind kind;

  /// The BE's wire value (`upcoming` | `not_created` | `pending` | `done` |
  /// `archived`); unknown → [notCreated].
  static OccurrenceState parse(String? wire) => switch (wire) {
    'upcoming' => upcoming,
    'pending' => pending,
    'done' => done,
    'archived' => archived,
    _ => notCreated,
  };

  String label(AppLocalizations l) => switch (this) {
    upcoming => l.occurrenceStateUpcoming,
    notCreated => l.occurrenceStateNotCreated,
    pending => l.occurrenceStatePending,
    done => l.occurrenceStateDone,
    archived => l.occurrenceStateArchived,
  };
}

/// An occurrence's state as a [StatusChip] (ล่วงหน้า / ยังไม่สร้าง /
/// รอยืนยัน / บันทึกแล้ว / เก็บถาวร), one tone per state app-wide.
class OccurrenceStateChip extends StatelessWidget {
  const OccurrenceStateChip({required this.state, this.size, super.key});

  final OccurrenceState state;
  final ChipSize? size;

  @override
  Widget build(BuildContext context) => StatusChip(
    label: state.label(AppLocalizations.of(context)!),
    kind: state.kind,
    size: size,
  );
}
