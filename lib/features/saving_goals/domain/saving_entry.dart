import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import 'saving_goal.dart';

/// ออม (wallet → spare / goal) · ถอนออม (→ back to the wallet) · จัดสรร
/// (spare → goal, goal ↔ goal).
enum SavingEntryKind {
  save,
  withdraw,
  move;

  static SavingEntryKind fromJson(String? raw) => switch (raw) {
    'withdraw' => SavingEntryKind.withdraw,
    'move' => SavingEntryKind.move,
    _ => SavingEntryKind.save,
  };

  String toJson() => name;
}

enum SavingEndpointType { wallet, spare, goal }

/// One end of a saving entry (`SavingBucketRef`): a wallet, the spare bucket
/// or a goal. [name] is null for spare (the app's label) and for a deleted
/// goal.
class SavingEndpoint extends Equatable {
  const SavingEndpoint({required this.type, this.id, this.name, this.iconCode});

  final SavingEndpointType type;
  final String? id;
  final String? name;
  final IconCode? iconCode;

  factory SavingEndpoint.fromJson(Map<String, dynamic> json) {
    final icon = json['icon_code'];
    return SavingEndpoint(
      type: switch (json['type']) {
        'wallet' => SavingEndpointType.wallet,
        'goal' => SavingEndpointType.goal,
        _ => SavingEndpointType.spare,
      },
      id: json['id'] as String?,
      name: json['name'] as String?,
      iconCode: icon is Map<String, dynamic> ? IconCode.fromJson(icon) : null,
    );
  }

  @override
  List<Object?> get props => [type, id, name, iconCode];
}

/// A saving entry row: ONE wallet, from → to, an amount. Lives in its own
/// table; never a real transaction. A multi-wallet action = several entries
/// sharing a [groupId].
class SavingEntry extends Equatable {
  const SavingEntry({
    required this.id,
    required this.groupId,
    required this.kind,
    required this.date,
    required this.amount,
    this.wallet,
    required this.from,
    required this.to,
    this.note,
    this.source = 'manual',
    this.recurringName,
  });

  final String id;
  final String groupId;
  final SavingEntryKind kind;
  final String date; // ISO YYYY-MM-DD
  final double amount;

  /// Null = saved with no wallet (money outside the app).
  final SavingWalletRef? wallet;
  final SavingEndpoint from;
  final SavingEndpoint to;
  final String? note;

  /// manual | recurring | pending.
  final String source;

  /// The recurring setting that made it (when [source] is recurring).
  final String? recurringName;

  bool get fromRecurring => source == 'recurring';

  factory SavingEntry.fromJson(Map<String, dynamic> json) {
    final rec = json['recurring'];
    return SavingEntry(
      id: json['id'] as String,
      groupId: json['group_id'] as String? ?? json['id'] as String,
      kind: SavingEntryKind.fromJson(json['kind'] as String?),
      date: json['date'] as String,
      amount: (json['amount'] as num).toDouble(),
      wallet: json['wallet'] is Map
          ? SavingWalletRef.fromJson(
              (json['wallet'] as Map).cast<String, dynamic>(),
            )
          : null,
      from: SavingEndpoint.fromJson(
        (json['from'] as Map).cast<String, dynamic>(),
      ),
      to: SavingEndpoint.fromJson((json['to'] as Map).cast<String, dynamic>()),
      note: json['note'] as String?,
      source: json['source'] as String? ?? 'manual',
      recurringName: rec is Map ? rec['recurring_name'] as String? : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    kind,
    date,
    amount,
    wallet,
    from,
    to,
    note,
    source,
    recurringName,
  ];
}

/// One page of entries (`SavingEntryList`: `data` + `pagination`).
class SavingEntryPage extends Equatable {
  const SavingEntryPage({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
  });

  final List<SavingEntry> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory SavingEntryPage.fromJson(Map<String, dynamic> json) {
    final p = (json['pagination'] as Map? ?? const {}).cast<String, dynamic>();
    return SavingEntryPage(
      items: [
        for (final e in (json['data'] as List? ?? const []))
          SavingEntry.fromJson((e as Map).cast<String, dynamic>()),
      ],
      page: (p['page'] as num?)?.toInt() ?? 1,
      totalPages: (p['total_pages'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [items, page, totalPages];
}

/// How much of a bucket (goal / spare) sits in one wallet.
class SavingWalletShare extends Equatable {
  const SavingWalletShare({
    this.wallet,
    required this.amount,
    this.sharePct = 0,
  });

  /// Null = saved with no wallet (money outside the app).
  final SavingWalletRef? wallet;
  final double amount;
  final double sharePct;

  factory SavingWalletShare.fromJson(Map<String, dynamic> json) =>
      SavingWalletShare(
        wallet: json['wallet'] is Map
            ? SavingWalletRef.fromJson(
                (json['wallet'] as Map).cast<String, dynamic>(),
              )
            : null,
        amount: (json['amount'] as num).toDouble(),
        sharePct: (json['share_pct'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [wallet, amount, sharePct];
}

/// A wallet's chosen part of a withdraw / move (sent only when edited).
class SavingSplit extends Equatable {
  const SavingSplit({required this.walletId, required this.amount});

  final String walletId;
  final double amount;

  Map<String, dynamic> toJson() => {'wallet_id': walletId, 'amount': amount};

  @override
  List<Object?> get props => [walletId, amount];
}
