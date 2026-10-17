import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../molecules/status_chip.dart';
import '../../tokens/chip_size.dart';

enum OccurrenceState {
  upcoming(StatusKind.upcoming),
  notCreated(StatusKind.notCreated),
  pending(StatusKind.pending),
  done(StatusKind.done),
  archived(StatusKind.archived);

  const OccurrenceState(this.kind);

  final StatusKind kind;

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
