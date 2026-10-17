import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'account_identifier.dart';
import 'account_type.dart';
import 'wallet_member.dart';
import '../../../ui/ui.dart';

/// What the wallet is to my net worth — computed in the BE from the type
/// (credit_card / pay_later = liability); drives the colour group.
enum WalletGroup {
  asset,
  liability;

  static WalletGroup parse(String? s) =>
      s == 'liability' ? WalletGroup.liability : WalletGroup.asset;
}

/// A wallet's lifecycle state.
enum AccountStatus {
  active,
  archived,
  closed;

  static AccountStatus parse(String? s) => switch (s) {
    'archived' => AccountStatus.archived,
    'closed' => AccountStatus.closed,
    _ => AccountStatus.active,
  };
}

/// One account — a place where money lives. Cash wallet, bank account, e-wallet,
/// credit card, or pay-later service. User-facing surfaces call this a
/// **wallet** (spec §14 naming rule); code and API keep `account`.
class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    this.iconCode,
    this.description,
    this.note,
    this.creditLimit,
    this.statementDate,
    this.paymentDueDate,
    this.minimumPayment,
    this.members = const [],
    this.myReportScope,
    this.isShared = false,
    this.identifiers = const [],
    this.createdAt,
    this.updatedAt,
    WalletGroup? group,
    this.logoUrl,
    this.status = AccountStatus.active,
    this.sortOrder = 0,
    this.myRole = WalletRole.owner,
    this.canEdit = true,
    this.trackBalance = true,
    this.savings,
    this.monthIn = 0,
    this.monthOut = 0,
    this.dueDateNext,
    this.daysUntilDue,
  }) : _group = group;

  final String id;
  final String name;
  final AccountType type;
  final String? description;
  final String? note;
  final double balance;

  /// "ติดตามยอดเงิน" (owner 2026-10-12): off → no balance is shown anywhere
  /// (list / pickers / hero), no ปรับยอด, and the wallet is left out of the
  /// totals. [balance] is still the running sum — hide it, don't trust it.
  final bool trackBalance;

  /// The caller's own savings held in this wallet (goals v2); null when the
  /// BE sent none.
  final WalletSavings? savings;

  /// This month's cash in / out on the wallet (user timezone; transfers and
  /// opening / adjustment rows are left out).
  final double monthIn;
  final double monthOut;

  /// A card's next due date and the days left (null without a due day).
  final DateTime? dueDateNext;
  final int? daysUntilDue;

  /// Whether any UI may show [balance] (and the credit figures built on it).
  bool get showsBalance => trackBalance;

  /// Read-only: the user's currency, set by the BE (never sent on writes).
  final String currency;
  final IconCode? iconCode;
  final String? logoUrl;

  final double? creditLimit;

  /// Day of month, 31 = the last day.
  final int? statementDate;
  final int? paymentDueDate;
  final double? minimumPayment;

  /// Active members (always including the caller), the caller's own report
  /// scope, and `is_shared` = more than one active member.
  final List<WalletMember> members;
  final WalletReportScope? myReportScope;
  final bool isShared;

  /// Numbers this wallet is known by on bank slips (spec 15 §5) — the
  /// owner edits them; slip import matches against them.
  final List<AccountIdentifier> identifiers;

  final AccountStatus status;
  final int sortOrder;

  /// The caller's role here, and whether they may edit it (= the owner).
  final WalletRole myRole;
  final bool canEdit;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final WalletGroup? _group;

  /// The BE's colour group (asset / liability). Rows built client-side
  /// (previews, samples) derive it from the type.
  WalletGroup get group =>
      _group ?? (type.isCredit ? WalletGroup.liability : WalletGroup.asset);

  /// A wallet whose kind is what I owe (credit card / pay later).
  bool get isLiability => group == WalletGroup.liability;

  bool get isArchived => status == AccountStatus.archived;

  /// The group's theme colour (have = cool, owe = warm).
  Color colorOf(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return isLiability ? palette.walletLiability : palette.walletAsset;
  }

  /// Active members other than the caller (BE `is_me`) — for the "other
  /// members" avatar stack on cards / detail (spec B2: exclude self).
  List<WalletMember> get otherMembers => members.where((m) => !m.isMe).toList();

  /// A card / pay-later's used credit — what's owed on it. A positive
  /// balance (overpaid) uses none; 0 for other types.
  double get creditUsed =>
      isLiability && trackBalance && balance < 0 ? -balance : 0;

  /// Credit left to spend: limit − [creditUsed] (null without a limit).
  /// Overpaid → the whole limit (the overpaid part is money of mine, not
  /// credit).
  double? get creditAvailable {
    final limit = creditLimit;
    if (!isLiability || !trackBalance || limit == null || limit <= 0) {
      return null;
    }
    return limit - creditUsed;
  }

  /// [creditUsed] / limit, 0..1 (null: not credit, or no limit).
  double? get creditUtilization {
    final limit = creditLimit;
    if (!isLiability || !trackBalance || limit == null || limit <= 0) {
      return null;
    }
    return (creditUsed / limit).clamp(0.0, 1.0);
  }

  /// Money I owe through this wallet: a card's used credit, or a wallet
  /// that isn't credit gone below zero (overdrawn). 0 otherwise.
  double get debt => balance < 0 ? -balance : 0;

  /// Money I have in it — any positive balance (an overpaid card too).
  double get asset => balance > 0 ? balance : 0;

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    IconCode? iconCode,
    String? description,
    String? note,
    double? creditLimit,
    int? statementDate,
    int? paymentDueDate,
    double? minimumPayment,
    List<WalletMember>? members,
    WalletReportScope? myReportScope,
    bool? isShared,
    List<AccountIdentifier>? identifiers,
    DateTime? createdAt,
    DateTime? updatedAt,
    WalletGroup? group,
    String? logoUrl,
    AccountStatus? status,
    int? sortOrder,
    WalletRole? myRole,
    bool? canEdit,
    bool? trackBalance,
    WalletSavings? savings,
    double? monthIn,
    double? monthOut,
    DateTime? dueDateNext,
    int? daysUntilDue,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      iconCode: iconCode ?? this.iconCode,
      description: description ?? this.description,
      note: note ?? this.note,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDate: statementDate ?? this.statementDate,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      members: members ?? this.members,
      myReportScope: myReportScope ?? this.myReportScope,
      isShared: isShared ?? this.isShared,
      identifiers: identifiers ?? this.identifiers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      group: group ?? _group,
      logoUrl: logoUrl ?? this.logoUrl,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      myRole: myRole ?? this.myRole,
      canEdit: canEdit ?? this.canEdit,
      trackBalance: trackBalance ?? this.trackBalance,
      savings: savings ?? this.savings,
      monthIn: monthIn ?? this.monthIn,
      monthOut: monthOut ?? this.monthOut,
      dueDateNext: dueDateNext ?? this.dueDateNext,
      daysUntilDue: daysUntilDue ?? this.daysUntilDue,
    );
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AccountType.fromJson(json['type'] as String),
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      description: json['description'] as String?,
      note: json['note'] as String?,
      creditLimit: (json['credit_limit'] as num?)?.toDouble(),
      statementDate: json['statement_date'] as int?,
      paymentDueDate: json['payment_due_date'] as int?,
      minimumPayment: (json['minimum_payment'] as num?)?.toDouble(),
      members: json['members'] is List
          ? (json['members'] as List)
                .cast<Map<String, dynamic>>()
                .map(WalletMember.fromJson)
                .toList()
          : const [],
      myReportScope: json['my_report_scope'] != null
          ? WalletReportScopeWire.parse(json['my_report_scope'] as String)
          : null,
      isShared: (json['is_shared'] as bool?) ?? false,
      identifiers: json['identifiers'] is List
          ? (json['identifiers'] as List)
                .cast<Map<String, dynamic>>()
                .map(AccountIdentifier.fromJson)
                .toList()
          : const [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      group: WalletGroup.parse(json['group'] as String?),
      logoUrl: json['logo_url'] as String?,
      status: AccountStatus.parse(json['status'] as String?),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      myRole: WalletRoleWire.parse(json['my_role'] as String?),
      canEdit: (json['can_edit'] as bool?) ?? false,
      trackBalance: (json['track_balance'] as bool?) ?? true,
      savings: json['savings'] is Map<String, dynamic>
          ? WalletSavings.fromJson(json['savings'] as Map<String, dynamic>)
          : null,
      monthIn: (json['month_in'] as num?)?.toDouble() ?? 0,
      monthOut: (json['month_out'] as num?)?.toDouble() ?? 0,
      dueDateNext: DateTime.tryParse(json['due_date_next'] as String? ?? ''),
      daysUntilDue: (json['days_until_due'] as num?)?.toInt(),
    );
  }

  /// `CreateAccountRequest` — no `currency`: the BE sets the user's own.
  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'name': name,
      'type': type.toJson(),
      // Off: no opening balance (the BE ignores one).
      'track_balance': trackBalance,
      if (trackBalance) 'balance': balance,
      if (iconCode != null) 'icon_code': iconCode!.toJson(),
      if (description != null) 'description': description,
      if (note != null) 'note': note,
      if (type.isCredit) ...{
        'credit_limit': creditLimit,
        if (statementDate != null) 'statement_date': statementDate,
        if (paymentDueDate != null) 'payment_due_date': paymentDueDate,
        if (minimumPayment != null) 'minimum_payment': minimumPayment,
      },
      if (identifiers.isNotEmpty)
        'identifiers': [for (final i in identifiers) i.toJson()],
    };
  }

  /// `UpdateAccountRequest` — no `currency` or `status`. [currentBalance]
  /// only goes with `track_balance: true` (turning tracking back on: the BE
  /// books the adjustment when it differs; without the flag it is a 400).
  Map<String, dynamic> toUpdateJson({double? currentBalance}) {
    return <String, dynamic>{
      'name': name,
      'track_balance': trackBalance,
      if (trackBalance && currentBalance != null)
        'current_balance': currentBalance,
      'type': type.toJson(),
      'icon_code': iconCode?.toJson(),
      'description': description,
      'note': note,
      if (type.isCredit) ...{
        'credit_limit': creditLimit,
        'statement_date': statementDate,
        'payment_due_date': paymentDueDate,
        'minimum_payment': minimumPayment,
      },
      // The whole list — the BE replaces the stored one ([] clears it).
      'identifiers': [for (final i in identifiers) i.toJson()],
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    balance,
    currency,
    iconCode,
    description,
    note,
    creditLimit,
    statementDate,
    paymentDueDate,
    minimumPayment,
    members,
    identifiers,
    myReportScope,
    isShared,
    createdAt,
    updatedAt,
    group,
    logoUrl,
    status,
    sortOrder,
    myRole,
    canEdit,
    trackBalance,
    savings,
    monthIn,
    monthOut,
    dueDateNext,
    daysUntilDue,
  ];
}

/// One slice of a wallet's saved money: a goal, or the spare (unassigned)
/// savings.
class WalletSavingsBucket extends Equatable {
  const WalletSavingsBucket({
    required this.isGoal,
    required this.name,
    required this.amount,
    this.id,
    this.iconCode,
  });

  /// `goal` (has an [id]) or `spare`.
  final bool isGoal;
  final String? id;
  final String name;
  final IconCode? iconCode;
  final double amount;

  factory WalletSavingsBucket.fromJson(Map<String, dynamic> json) =>
      WalletSavingsBucket(
        isGoal: json['type'] == 'goal',
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        iconCode: json['icon_code'] is Map<String, dynamic>
            ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
            : null,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [isGoal, id, name, iconCode, amount];
}

/// The caller's own savings in one wallet (`Account.savings`). A warning
/// only — [savedExceedsBalance] blocks nothing.
class WalletSavings extends Equatable {
  const WalletSavings({
    required this.balance,
    required this.saved,
    this.spare = 0,
    this.available,
    this.savedExceedsBalance = false,
    this.overBy = 0,
    this.buckets = const [],
  });

  final double balance;
  final double saved;
  final double spare;

  /// Null when the wallet doesn't track its balance.
  final double? available;
  final bool savedExceedsBalance;
  final double overBy;
  final List<WalletSavingsBucket> buckets;

  /// Nothing saved here — the section stays hidden.
  bool get isEmpty => saved == 0 && buckets.isEmpty;

  factory WalletSavings.fromJson(Map<String, dynamic> json) {
    double n(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return WalletSavings(
      balance: n('balance'),
      saved: n('saved'),
      spare: n('spare'),
      available: (json['available'] as num?)?.toDouble(),
      savedExceedsBalance: (json['saved_exceeds_balance'] as bool?) ?? false,
      overBy: n('over_by'),
      buckets: [
        for (final b in (json['buckets'] as List? ?? const []))
          WalletSavingsBucket.fromJson(b as Map<String, dynamic>),
      ],
    );
  }

  @override
  List<Object?> get props => [
    balance,
    saved,
    spare,
    available,
    savedExceedsBalance,
    overBy,
    buckets,
  ];
}

/// Income / expense of one wallet over a period (`include=summary`).
class AccountSummary extends Equatable {
  const AccountSummary({
    required this.from,
    required this.to,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    required this.transactionCount,
  });

  final String from;
  final String to;
  final double totalIncome;
  final double totalExpense;
  final double net;
  final int transactionCount;

  factory AccountSummary.fromJson(Map<String, dynamic> json) => AccountSummary(
    from: json['from'] as String? ?? '',
    to: json['to'] as String? ?? '',
    totalIncome: (json['total_income'] as num).toDouble(),
    totalExpense: (json['total_expense'] as num).toDouble(),
    net: (json['net'] as num).toDouble(),
    transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [
    from,
    to,
    totalIncome,
    totalExpense,
    net,
    transactionCount,
  ];
}

/// `GET /accounts/:id?include=summary,members` — the wallet plus this
/// period's summary and the whole members history (pending / left too).
class AccountDetail extends Equatable {
  const AccountDetail({
    required this.account,
    this.summary,
    this.membersHistory,
  });

  final Account account;
  final AccountSummary? summary;
  final List<WalletMember>? membersHistory;

  AccountDetail copyWith({
    Account? account,
    List<WalletMember>? membersHistory,
  }) => AccountDetail(
    account: account ?? this.account,
    summary: summary,
    membersHistory: membersHistory ?? this.membersHistory,
  );

  factory AccountDetail.fromJson(Map<String, dynamic> json) => AccountDetail(
    account: Account.fromJson(json),
    summary: json['summary'] is Map<String, dynamic>
        ? AccountSummary.fromJson(json['summary'] as Map<String, dynamic>)
        : null,
    membersHistory: json['members_history'] is List
        ? [
            for (final m in (json['members_history'] as List))
              WalletMember.fromJson(m as Map<String, dynamic>),
          ]
        : null,
  );

  @override
  List<Object?> get props => [account, summary, membersHistory];
}

/// One type's slice of [AccountTotals].
class AccountTypeTotal extends Equatable {
  const AccountTypeTotal({
    required this.type,
    required this.count,
    required this.balance,
  });

  final AccountType type;
  final int count;
  final double balance;

  @override
  List<Object?> get props => [type, count, balance];
}

/// The accounts page's summary card, computed by the BE over the wallets in
/// the user's currency. [liabilities] and [creditUsed] are positive numbers
/// owed; [net] = [assets] − [liabilities].
class AccountTotals extends Equatable {
  const AccountTotals({
    this.assets = 0,
    this.liabilities = 0,
    this.net = 0,
    this.currency = '',
    this.byType = const [],
    this.creditUsed = 0,
    this.creditLimit = 0,
    this.sharedCount = 0,
    this.sharedBalance = 0,
    this.otherCurrencyCount = 0,
    this.untrackedCount = 0,
    this.cashTotal = 0,
    this.cardDebt = 0,
    this.cardUsedPct = 0,
    this.savedTotal = 0,
    this.availableTotal = 0,
    this.cashSplit = const [],
    this.cardRemaining = 0,
  });

  final double assets;
  final double liabilities;
  final double net;
  final String currency;
  final List<AccountTypeTotal> byType;
  final double creditUsed;
  final double creditLimit;
  final int sharedCount;

  /// Signed sum of the shared wallets' balances, in the user's currency.
  final double sharedBalance;

  /// Wallets in another (legacy) currency — left out of the sums.
  final int otherCurrencyCount;

  /// Wallets with "ติดตามยอดเงิน" off — left out of every sum.
  final int untrackedCount;

  /// The กระเป๋าตังค์ tile (the non-credit wallets), the หนี้บัตร tile and
  /// its used % of the cards' limits; what is earmarked as savings and what
  /// is really spendable (BE, no client sums).
  final double cashTotal;
  final double cardDebt;
  final int cardUsedPct;
  final double savedTotal;
  final double availableTotal;

  /// The กระเป๋าตังค์ tile caption: each non-credit type's % of [cashTotal].
  final List<CashSplitShare> cashSplit;

  /// Credit left on the cards (limit − used), for the หนี้บัตร caption.
  final double cardRemaining;

  factory AccountTotals.fromJson(Map<String, dynamic> json) {
    double n(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return AccountTotals(
      assets: n('assets'),
      liabilities: n('liabilities'),
      net: n('net'),
      currency: json['currency'] as String? ?? '',
      byType: [
        for (final t in (json['by_type'] as List? ?? const []))
          AccountTypeTotal(
            type: AccountType.fromJson((t as Map)['type'] as String),
            count: (t['count'] as num?)?.toInt() ?? 0,
            balance: (t['balance'] as num?)?.toDouble() ?? 0,
          ),
      ],
      creditUsed: n('credit_used'),
      creditLimit: n('credit_limit'),
      sharedCount: (json['shared_count'] as num?)?.toInt() ?? 0,
      sharedBalance: n('shared_balance'),
      otherCurrencyCount: (json['other_currency_count'] as num?)?.toInt() ?? 0,
      untrackedCount: (json['untracked_count'] as num?)?.toInt() ?? 0,
      cashTotal: n('cash_total'),
      cardDebt: n('card_debt'),
      cardUsedPct: (json['card_used_pct'] as num?)?.toInt() ?? 0,
      savedTotal: n('saved_total'),
      availableTotal: n('available_total'),
      cashSplit: [
        for (final s in (json['cash_split'] as List? ?? const []))
          CashSplitShare(
            type: AccountType.fromJson((s as Map)['type'] as String),
            pct: (s['pct'] as num?)?.toInt() ?? 0,
          ),
      ],
      cardRemaining: n('card_remaining'),
    );
  }

  @override
  List<Object?> get props => [
    assets,
    liabilities,
    net,
    currency,
    byType,
    creditUsed,
    creditLimit,
    sharedCount,
    sharedBalance,
    otherCurrencyCount,
    untrackedCount,
    cashTotal,
    cardDebt,
    cardUsedPct,
    savedTotal,
    availableTotal,
    cashSplit,
    cardRemaining,
  ];
}

/// `GET /accounts` (and the reorder response).
class AccountList {
  const AccountList({
    required this.data,
    required this.total,
    required this.totals,
    required this.archivedCount,
  });

  final List<Account> data;
  final int total;
  final AccountTotals totals;

  /// Archived wallets the caller has (whatever `status` was asked for).
  final int archivedCount;

  factory AccountList.fromJson(Map<String, dynamic> json) => AccountList(
    data: [
      for (final a in (json['data'] as List))
        Account.fromJson(a as Map<String, dynamic>),
    ],
    total: (json['total'] as num?)?.toInt() ?? 0,
    totals: json['totals'] is Map<String, dynamic>
        ? AccountTotals.fromJson(json['totals'] as Map<String, dynamic>)
        : const AccountTotals(),
    archivedCount: (json['archived_count'] as num?)?.toInt() ?? 0,
  );
}

/// A members action's response: the wallet and the whole members history.
/// [account] is null when the caller just left (then [members] is empty).
class MembersResult {
  const MembersResult({required this.account, required this.members});

  final Account? account;
  final List<WalletMember> members;

  factory MembersResult.fromJson(Map<String, dynamic> json) => MembersResult(
    account: json['account'] is Map<String, dynamic>
        ? Account.fromJson(json['account'] as Map<String, dynamic>)
        : null,
    members: [
      for (final m in (json['members'] as List? ?? const []))
        WalletMember.fromJson(m as Map<String, dynamic>),
    ],
  );
}

/// `POST /accounts/:id/adjust-balance`: the wallet, the adjustment row's id
/// and the post-write balances of every wallet touched.
class AdjustBalanceResult {
  const AdjustBalanceResult({
    required this.account,
    required this.transactionId,
    required this.accountBalances,
  });

  final Account account;
  final String? transactionId;
  final Map<String, double> accountBalances;

  factory AdjustBalanceResult.fromJson(Map<String, dynamic> json) {
    final tx = json['transaction'];
    return AdjustBalanceResult(
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      transactionId: tx is Map ? tx['id'] as String? : null,
      accountBalances: {
        for (final b in (json['account_balances'] as List? ?? const []))
          (b as Map)['account_id'] as String: (b['balance'] as num).toDouble(),
      },
    );
  }
}

/// One type's share of the cash tile (`totals.cash_split`).
class CashSplitShare extends Equatable {
  const CashSplitShare({required this.type, required this.pct});

  final AccountType type;
  final int pct;

  @override
  List<Object?> get props => [type, pct];
}
