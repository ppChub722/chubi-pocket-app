import '../../../ui/ui.dart';

/// The six kinds the archive hub groups, in display order.
enum ArchivedKind {
  wallets('wallets'),
  budgets('budgets'),
  goals('goals'),
  events('events'),
  contacts('contacts'),
  recurring('recurring');

  const ArchivedKind(this.key);

  /// The key in `GET /me/archived`.
  final String key;

  /// The entity's detail page (all of them open archived rows).
  String detailPath(String id) => switch (this) {
    wallets => '/accounts/$id',
    budgets => '/budgets/$id',
    goals => '/saving-goals/$id',
    events => '/projects/$id',
    contacts => '/contacts/$id',
    recurring => '/recurring/$id',
  };
}

/// One archived row of `GET /me/archived`.
class ArchivedItem {
  const ArchivedItem({
    required this.id,
    required this.name,
    required this.archivedAt,
    this.iconCode,
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
    );
  }

  final String id;
  final String name;
  final IconCode? iconCode;

  /// The row's last change (when it was archived).
  final DateTime? archivedAt;
}

/// The archive hub: every kind's rows, one call.
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
