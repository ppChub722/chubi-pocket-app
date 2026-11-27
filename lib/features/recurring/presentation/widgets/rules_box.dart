import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurring_item.dart' show RecurringDetail;
import '../../domain/rule_draft.dart';
import '../../domain/rule_group.dart';
import '../pages/rule_page.dart';
import 'rule_row.dart';

/// รายการอัตโนมัติ: the rules that touch this page (spec §3 "rules live
/// everywhere"; mock AutoBox / WalletKbank / GoalTrip): pulled by their own
/// columns ([filter]), titled with their recurring's name ("Netflix · rule 1
/// จาก 2"); several rules of one recurring sit under its name (a tap there =
/// the recurring). + opens the rule page with this page's field prefilled
/// ([preset]) under "อยู่ในรายการประจำ": a new recurring named [newName]
/// the first time, this page's recurring after that.
class RulesBox extends StatefulWidget {
  const RulesBox({
    required this.filter,
    required this.preset,
    required this.newName,
    this.title,
    this.addLabel,
    this.trackingType = 'other',
    this.empty,
    this.emptyHint,
    this.onChanged,
    super.key,
  });

  final RuleFilter filter;
  final RuleDraft preset;
  final String newName;
  final String? title;
  final String? addLabel;
  final String trackingType;

  /// Shown under the header with no rule (a card plan: "จ่ายผ่านบิล").
  final Widget? empty;

  /// The empty row's second line (default ยังไม่ตั้ง).
  final String? emptyHint;

  /// A rule was saved / changed here (the page reloads its own numbers).
  final VoidCallback? onChanged;

  @override
  State<RulesBox> createState() => _RulesBoxState();
}

class _RulesBoxState extends State<RulesBox> {
  List<RuleGroup>? _groups;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(RulesBox old) {
    super.didUpdateWidget(old);
    if (old.filter != widget.filter) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final g = await RecurringRepository.of(context).rulesOf(widget.filter);
      if (mounted) {
        setState(() {
          _groups = g;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// The recurring this page used before (the "อยู่ในรายการประจำ" default):
  /// the one named for it, else none (a new one).
  RuleGroup? get _own {
    for (final g in _groups ?? const <RuleGroup>[]) {
      if (g.name == widget.newName) return g;
    }
    return null;
  }

  Future<void> _add() async {
    final own = _own;
    final r = await context.push<Object?>(
      '/recurring-rules/new',
      extra: RulePageArgs(
        fromPage: RuleFromPage(
          newName: widget.newName,
          preset: widget.preset,
          existingId: own?.recurringId,
          existingName: own?.name,
          trackingType: widget.trackingType,
        ),
      ),
    );
    if (!mounted) return;
    if (r is RecurringDetail) widget.onChanged?.call();
    unawaited(_load());
  }

  Future<void> _open(RuleGroup g, String ruleId, int seq) async {
    final r = await context.push<Object?>(
      '/recurring/${g.recurringId}/rules/$ruleId',
      extra: RulePageArgs(seq: seq, recurringName: g.name),
    );
    if (!mounted) return;
    if (r is RecurringDetail) widget.onChanged?.call();
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final groups = _groups;
    final count = groups?.fold<int>(0, (s, g) => s + g.rules.length) ?? 0;
    final rows = <Widget>[];
    for (final g in groups ?? const <RuleGroup>[]) {
      if (g.rules.length > 1) {
        rows.add(
          PpForgeListRow(
            key: ValueKey('rulesGroup:${g.recurringId}'),
            leading: IconDisplay(
              type: IconType.category,
              size: 36,
              iconCode: g.iconCode,
            ),
            title: g.name,
            line2: ListRowLine(parts: [l.recurringRulesCount(g.rules.length)]),
            trailing: ListRowTrailing.text(
              l.recurringHomePerMonth(moneyString(context, g.monthTotal)),
            ),
            onTap: () => openPage(context, '/recurring/${g.recurringId}'),
          ),
        );
        for (final line in g.rules) {
          rows.add(
            RuleRow.of(
              line,
              key: ValueKey('rulesBox:${line.id}'),
              title: line.account?.name ?? line.paidBy?.name ?? g.name,
              onTap: () => _open(g, line.id, line.seq),
            ),
          );
        }
        continue;
      }
      final line = g.rules.single;
      rows.add(
        RuleRow.of(
          line,
          key: ValueKey('rulesBox:${line.id}'),
          title: g.name,
          subtitle: g.rulesCount > 1
              ? l.ruleOfTotal(line.seq, g.rulesCount)
              : null,
          onTap: () => _open(g, line.id, line.seq),
        ),
      );
    }
    return RulesBoxView(
      title: widget.title ?? l.rulesBoxTitle,
      addTooltip: widget.addLabel ?? l.rulesBoxAdd,
      onAdd: _add,
      rows: rows,
      count: groups == null ? null : count,
      loaded: groups != null,
      error: _error,
      onRetry: _load,
      empty:
          widget.empty ??
          SectionCard(
            first: true,
            children: [
              PpForgeListRow(
                key: const ValueKey('rulesBoxEmpty'),
                leading: const PpForgeIcon(AppIcons.add),
                title: widget.addLabel ?? l.rulesBoxAdd,
                line2: ListRowLine(
                  parts: [widget.emptyHint ?? l.rulesBoxEmpty],
                ),
                onTap: _add,
              ),
            ],
          ),
    );
  }
}
