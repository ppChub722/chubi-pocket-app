import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../molecules/status_chip.dart';
import '../../tokens/chip_size.dart';

enum OccurrenceState {
  upcoming(StatusKind.upcoming),

  /// ค้าง: its date came and nothing was recorded (wire `due`; the old
  /// `not_created`).
  notCreated(StatusKind.warning),
  pending(StatusKind.pending),

  /// Recorded with a tx.
  done(StatusKind.done),

  /// Marked paid without a tx (someone else paid; before the rule existed).
  paid(StatusKind.done),

  /// ข้าม (wire `skipped`; the old `archived`).
  archived(StatusKind.archived);

  const OccurrenceState(this.kind);

  final StatusKind kind;

  static OccurrenceState parse(String? wire) => switch (wire) {
    'upcoming' => upcoming,
    'pending' => pending,
    'done' => done,
    'paid' => paid,
    'archived' || 'skipped' => archived,
    _ => notCreated,
  };

  /// Nothing more to do with it: recorded, paid or skipped.
  bool get settled => this == done || this == paid || this == archived;

  String label(AppLocalizations l) => switch (this) {
    upcoming => l.occurrenceStateUpcoming,
    notCreated => l.occurrenceStateNotCreated,
    pending => l.occurrenceStatePending,
    done => l.occurrenceStateDone,
    paid => l.occurrenceStatePaid,
    archived => l.occurrenceStateArchived,
  };
}

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
