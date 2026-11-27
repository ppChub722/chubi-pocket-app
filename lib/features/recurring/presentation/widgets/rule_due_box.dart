import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../ui/ui.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurring_item.dart';
import '../../domain/rule_group.dart';
import '../due_boxes.dart';
import '../occurrence_actions.dart' show openOccurrenceSheet;

/// The due rounds of the rules that match [filter] (every page a rule
/// touches pulls them by its columns, spec §3).
Future<List<RecurringItem>> dueOfRules(
  RecurringRepository repo,
  RuleFilter filter,
) async {
  final groups = await repo.rulesOf(filter);
  final lists = await Future.wait([
    for (final g in groups)
      for (final r in g.rules) repo.dueItems(ruleId: r.id),
  ]);
  return [for (final l in lists) ...l]
    ..sort((a, b) => a.date.compareTo(b.date));
}

/// ต้องทำ on a debt page (mock CardNew / PlanNew): the due rounds of the
/// rules that touch it, as the รอยืนยัน box of the list page; nothing when
/// none is due. [reloadKey] changes = load again (a rule was added).
class RuleDueBox extends StatefulWidget {
  const RuleDueBox({
    required this.filter,
    this.onChanged,
    this.reloadKey,
    super.key,
  });

  final RuleFilter filter;

  /// A round was settled here (the page reloads its own numbers).
  final VoidCallback? onChanged;
  final Object? reloadKey;

  @override
  State<RuleDueBox> createState() => _RuleDueBoxState();
}

class _RuleDueBoxState extends State<RuleDueBox> {
  List<RecurringItem> _due = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(RuleDueBox old) {
    super.didUpdateWidget(old);
    if (old.filter != widget.filter || old.reloadKey != widget.reloadKey) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    try {
      final due = await dueOfRules(
        RecurringRepository.of(context),
        widget.filter,
      );
      if (mounted) setState(() => _due = due);
    } on ApiException {
      // the page's own pay buttons still work
    }
  }

  void _changed(ItemWriteResult _) {
    widget.onChanged?.call();
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    if (_due.isEmpty) return const SizedBox.shrink();
    return DueBoxes(
      items: _due,
      showDate: false,
      titleOf: (i) => i.recurring?.name ?? i.title,
      leading: (i) => DateTile(date: i.date),
      onChanged: _changed,
      onOpen: (i) => openOccurrenceSheet(context, i, onChanged: _changed),
    );
  }
}
