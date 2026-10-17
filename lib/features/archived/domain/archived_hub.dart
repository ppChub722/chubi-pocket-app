import '../../../ui/ui.dart';

enum ArchivedKind {
  wallets('wallets'),
  budgets('budgets'),
  goals('goals'),
  events('events'),
  contacts('contacts'),
  recurring('recurring');

  const ArchivedKind(this.key);

  final String key;

  String detailPath(String id) => switch (this) {
    wallets => '/accounts/$id',
    budgets => '/budgets/$id',
    goals => '/saving-goals/$id',
    events => '/projects/$id',
    contacts => '/contacts/$id',
    recurring => '/recurring/$id',
  };
}

class ArchivedItem {
  const ArchivedItem({
    required this.id,
    required this.name,
    required this.archivedAt,
    this.iconCode,
    this.canRestore = true,
    this.secondary,
  });

  factory ArchivedItem.fromJson(Map<String, dynamic> json) {
    final icon = json['icon_code'];
    return ArchivedItem(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      iconCode: icon is Map<String, dynamic> ? IconCode.fromJson(icon) : null,
      archivedAt: DateTime.tryParse(
        json['archived_at'] as String? ?? '',
      )?.toLocal(),
      canRestore: json['can_restore'] != false,
      secondary: ArchivedSecondary.maybe(json['secondary']),
    );
  }

  final String id;
  final String name;
  final IconCode? iconCode;

  final DateTime? archivedAt;

  final bool canRestore;

  final ArchivedSecondary? secondary;
}

enum ArchivedSecondaryKind { balance, limit, target, planned, amount }

class ArchivedSecondary {
  const ArchivedSecondary({required this.kind, required this.amount});

  final ArchivedSecondaryKind kind;
  final double amount;

  /// Null when absent, malformed or without an amount (nothing to show).
  static ArchivedSecondary? maybe(Object? json) {
    if (json is! Map) return null;
    final amount = json['amount'];
    if (amount is! num) return null;
    for (final k in ArchivedSecondaryKind.values) {
      if (k.name == json['kind']) {
        return ArchivedSecondary(kind: k, amount: amount.toDouble());
      }
    }
    return null;
  }
}

class ArchivedHub {
  const ArchivedHub({required this.total, required this.groups});

  factory ArchivedHub.fromJson(Map<String, dynamic> json) {
    final groups = <ArchivedKind, List<ArchivedItem>>{};
    for (final kind in ArchivedKind.values) {
      final g = json[kind.key];
      final items = g is Map<String, dynamic> ? g['items'] : null;
      groups[kind] = [
        if (items is List)
          for (final i in items)
            ArchivedItem.fromJson(i as Map<String, dynamic>),
      ];
    }
    return ArchivedHub(
      total: (json['total'] as num?)?.toInt() ?? 0,
      groups: groups,
    );
  }

  final int total;
  final Map<ArchivedKind, List<ArchivedItem>> groups;

  List<ArchivedItem> of(ArchivedKind kind) => groups[kind] ?? const [];

  /// The hub without one restored row (removal only — no other number moves).
  ArchivedHub without(ArchivedKind kind, String id) {
    final next = {
      for (final e in groups.entries)
        e.key: e.key == kind
            ? [
                for (final i in e.value)
                  if (i.id != id) i,
              ]
            : e.value,
    };
    final removed = of(kind).length - (next[kind]?.length ?? 0);
    return ArchivedHub(total: total - removed, groups: next);
  }
}
