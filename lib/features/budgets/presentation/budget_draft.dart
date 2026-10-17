import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import '../../recurring/domain/recurrence_rule.dart' show today;
import '../../transactions/domain/refs.dart';
import '../domain/budget.dart';
import '../domain/budget_detail.dart';

class BudgetDraft extends Equatable {
  const BudgetDraft({
    required this.start,
    this.name = '',
    this.description = '',
    this.note = '',
    this.amount = '',
    this.iconCode,
    this.warnPct = 80,
    this.allScope = false,
    this.categories = const [],
    this.tags = const [],
    this.wallets = const [],
    this.recurring = true,
    this.freq = 'monthly',
    this.interval = 1,
    this.end = const BudgetEnd.none(),
  });

  factory BudgetDraft.blank() {
    final t = today();
    return BudgetDraft(start: DateTime(t.year, t.month, 1));
  }

  factory BudgetDraft.from(Budget b) => BudgetDraft(
    name: b.name,
    description: b.description ?? '',
    note: b.note ?? '',
    amount: AmountInput.format(b.amount),
    iconCode: b.iconCode,
    warnPct: b.warnPct,
    allScope: b.scope.all,
    categories: b.scope.categories,
    tags: b.scope.tags,
    wallets: b.scope.wallets,
    recurring: b.recurring,
    freq: b.rule?.freq ?? 'monthly',
    interval: b.rule?.interval ?? 1,
    start: b.startDate,
    end: b.end,
  );

  final String name;
  final String description;
  final String note;

  final String amount;
  final IconCode? iconCode;

  final int? warnPct;
  final bool allScope;
  final List<BudgetScopeCategory> categories;
  final List<String> tags;
  final List<AccountRef> wallets;
  final bool recurring;
  final String freq;
  final int interval;
  final DateTime start;
  final BudgetEnd end;

  bool get scopeEmpty =>
      !allScope && categories.isEmpty && tags.isEmpty && wallets.isEmpty;

  BudgetRule get rule => BudgetRule(freq: freq, interval: interval);

  RecurrenceRule get kitRule => RecurrenceRule(
    freq: RecurrenceFreq.values.firstWhere(
      (f) => f.name == freq,
      orElse: () => RecurrenceFreq.monthly,
    ),
    start: start,
    interval: interval,
    end: switch (end.kind) {
      'date' when end.date != null => RecurrenceEnd.onDate(end.date!),
      'count' when end.count != null => RecurrenceEnd.afterCount(end.count!),
      _ => const RecurrenceEnd.never(),
    },
  );

  BudgetDraft withKitRule(RecurrenceRule r) => copyWith(
    freq: r.freq == RecurrenceFreq.dates ? 'monthly' : r.freq.name,
    interval: r.interval < 1 ? 1 : r.interval,
    end: switch (r.end.kind) {
      RecurrenceEndKind.onDate when r.end.date != null => BudgetEnd.onDate(
        r.end.date!,
      ),
      RecurrenceEndKind.afterCount when r.end.count != null =>
        BudgetEnd.afterCount(r.end.count!),
      _ => const BudgetEnd.none(),
    },
  );

  bool periodShapeDiffers(BudgetDraft other) =>
      amount.trim() != other.amount.trim() ||
      freq != other.freq ||
      interval != other.interval ||
      start != other.start ||
      end != other.end;

  BudgetWrite toWrite() {
    final d = description.trim();
    final n = note.trim();
    return BudgetWrite(
      name: name.trim(),
      description: d.isEmpty ? null : d,
      note: n.isEmpty ? null : n,
      iconCode: iconCode?.toJson(),
      amount: AmountInput.parse(amount) ?? 0,
      warnPct: warnPct,
      scope: BudgetScope(
        all: allScope,
        categories: allScope ? const [] : categories,
        tags: allScope ? const [] : tags,
        wallets: allScope ? const [] : wallets,
      ),
      recurring: recurring,
      rule: recurring ? rule : null,
      startDate: start,
      end: end,
    );
  }

  BudgetDraft copyWith({
    String? name,
    String? description,
    String? note,
    String? amount,
    IconCode? iconCode,
    bool clearIcon = false,
    int? warnPct,
    bool clearWarn = false,
    bool? allScope,
    List<BudgetScopeCategory>? categories,
    List<String>? tags,
    List<AccountRef>? wallets,
    bool? recurring,
    String? freq,
    int? interval,
    DateTime? start,
    BudgetEnd? end,
  }) => BudgetDraft(
    name: name ?? this.name,
    description: description ?? this.description,
    note: note ?? this.note,
    amount: amount ?? this.amount,
    iconCode: clearIcon ? null : (iconCode ?? this.iconCode),
    warnPct: clearWarn ? null : (warnPct ?? this.warnPct),
    allScope: allScope ?? this.allScope,
    categories: categories ?? this.categories,
    tags: tags ?? this.tags,
    wallets: wallets ?? this.wallets,
    recurring: recurring ?? this.recurring,
    freq: freq ?? this.freq,
    interval: interval ?? this.interval,
    start: start ?? this.start,
    end: end ?? this.end,
  );

  @override
  List<Object?> get props => [
    name,
    description,
    note,
    amount,
    iconCode,
    warnPct,
    allScope,
    categories,
    tags,
    wallets,
    recurring,
    freq,
    interval,
    start,
    end,
  ];
}
