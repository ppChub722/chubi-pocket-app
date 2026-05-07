import 'package:equatable/equatable.dart';

import '../../../shared/icon_maker/icon_code.dart';
import 'scheduled_enums.dart';

/// One scheduled-transaction template (spec §11/§2).
///
/// One table covers three use cases, discriminated by [entryType] +
/// [interestRate]:
/// - `recurring` — indefinite (Netflix, salary)
/// - `installment` (no interest) — finite count (BNPL)
/// - `installment` (interest > 0) — loan; UI labels accordingly
///
/// Installment-only fields (`totalAmount`, `downPayment`,
/// `totalInstallments`, `remainingInstallments`, `interestRate`) are
/// null when [entryType] is `recurring`.
class ScheduledTransaction extends Equatable {
  const ScheduledTransaction({
    required this.id,
    required this.name,
    required this.type,
    required this.entryType,
    required this.amount,
    required this.accountId,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.status,
    this.categoryId,
    this.note,
    this.iconCode,
    this.account,
    this.category,
    this.totalAmount,
    this.downPayment,
    this.totalInstallments,
    this.remainingInstallments,
    this.interestRate,
    this.dayOfMonth,
  });

  final String id;
  final String name;
  final ScheduledTransactionType type;
  final ScheduledEntryType entryType;
  final double amount;
  final String accountId;
  final String? categoryId;
  final BillingCycle billingCycle;
  final String nextBillingDate; // ISO YYYY-MM-DD
  final ScheduledStatus status;
  final String? note;
  final IconCode? iconCode;

  // Embedded refs (returned in list/detail responses)
  final ScheduledAccountRef? account;
  final ScheduledCategoryRef? category;

  // Installment-only
  final double? totalAmount;
  final double? downPayment;
  final int? totalInstallments;
  final int? remainingInstallments;
  final double? interestRate;

  // Day-clamping helper (spec §2.3, §4.4)
  final int? dayOfMonth;

  /// Spec §4.2: an installment with positive interest is shown as "Loan".
  bool get isLoan =>
      entryType == ScheduledEntryType.installment &&
      (interestRate ?? 0) > 0;

  bool get isInstallment => entryType == ScheduledEntryType.installment;

  bool get canPause => status == ScheduledStatus.active;
  bool get canResume => status == ScheduledStatus.paused;
  bool get canCancel =>
      status == ScheduledStatus.active || status == ScheduledStatus.paused;
  bool get canGenerateNow =>
      status == ScheduledStatus.active || status == ScheduledStatus.paused;

  ScheduledTransaction copyWith({
    String? id,
    String? name,
    ScheduledTransactionType? type,
    ScheduledEntryType? entryType,
    double? amount,
    String? accountId,
    String? categoryId,
    BillingCycle? billingCycle,
    String? nextBillingDate,
    ScheduledStatus? status,
    String? note,
    IconCode? iconCode,
    ScheduledAccountRef? account,
    ScheduledCategoryRef? category,
    double? totalAmount,
    double? downPayment,
    int? totalInstallments,
    int? remainingInstallments,
    double? interestRate,
    int? dayOfMonth,
  }) {
    return ScheduledTransaction(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      entryType: entryType ?? this.entryType,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      billingCycle: billingCycle ?? this.billingCycle,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      status: status ?? this.status,
      note: note ?? this.note,
      iconCode: iconCode ?? this.iconCode,
      account: account ?? this.account,
      category: category ?? this.category,
      totalAmount: totalAmount ?? this.totalAmount,
      downPayment: downPayment ?? this.downPayment,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      remainingInstallments:
          remainingInstallments ?? this.remainingInstallments,
      interestRate: interestRate ?? this.interestRate,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    );
  }

  factory ScheduledTransaction.fromJson(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;
    return ScheduledTransaction(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ScheduledTransactionType.fromJson(json['type'] as String),
      entryType:
          ScheduledEntryType.fromJson(json['entry_type'] as String),
      amount: (json['amount'] as num).toDouble(),
      accountId: (json['account_id'] as String?) ??
          (account?['id'] as String? ?? ''),
      categoryId: json['category_id'] as String? ??
          (category?['id'] as String?),
      billingCycle:
          BillingCycle.fromJson(json['billing_cycle'] as String),
      nextBillingDate: json['next_billing_date'] as String,
      status: ScheduledStatus.fromJson(json['status'] as String),
      note: json['note'] as String?,
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      account:
          account != null ? ScheduledAccountRef.fromJson(account) : null,
      category:
          category != null ? ScheduledCategoryRef.fromJson(category) : null,
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      downPayment: (json['down_payment'] as num?)?.toDouble(),
      totalInstallments: json['total_installments'] as int?,
      remainingInstallments: json['remaining_installments'] as int?,
      interestRate: (json['interest_rate'] as num?)?.toDouble(),
      dayOfMonth: json['day_of_month'] as int?,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'name': name,
      'type': type.toJson(),
      'entry_type': entryType.toJson(),
      'amount': amount,
      'account_id': accountId,
      if (categoryId != null) 'category_id': categoryId,
      'billing_cycle': billingCycle.toJson(),
      'next_billing_date': nextBillingDate,
      if (note != null) 'note': note,
      if (iconCode != null) 'icon_code': iconCode!.toJson(),
      if (entryType == ScheduledEntryType.installment) ...{
        'total_amount': totalAmount,
        'down_payment': downPayment ?? 0,
        'total_installments': totalInstallments,
        'remaining_installments': remainingInstallments,
        if (interestRate != null) 'interest_rate': interestRate,
      },
    };
  }

  /// Spec §3.5: `type`, `entry_type`, `status` are not editable.
  /// Status changes go through pause / resume / cancel endpoints.
  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'name': name,
      'amount': amount,
      'account_id': accountId,
      'category_id': categoryId,
      'billing_cycle': billingCycle.toJson(),
      'next_billing_date': nextBillingDate,
      'note': note,
      'icon_code': iconCode?.toJson(),
      if (entryType == ScheduledEntryType.installment) ...{
        'total_amount': totalAmount,
        'down_payment': downPayment ?? 0,
        'total_installments': totalInstallments,
        'remaining_installments': remainingInstallments,
        'interest_rate': interestRate,
      },
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        entryType,
        amount,
        accountId,
        categoryId,
        billingCycle,
        nextBillingDate,
        status,
        note,
        iconCode,
        account,
        category,
        totalAmount,
        downPayment,
        totalInstallments,
        remainingInstallments,
        interestRate,
        dayOfMonth,
      ];
}

class ScheduledAccountRef extends Equatable {
  const ScheduledAccountRef({required this.id, required this.name});
  final String id;
  final String name;

  factory ScheduledAccountRef.fromJson(Map<String, dynamic> json) {
    return ScheduledAccountRef(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class ScheduledCategoryRef extends Equatable {
  const ScheduledCategoryRef({required this.id, required this.name});
  final String id;
  final String name;

  factory ScheduledCategoryRef.fromJson(Map<String, dynamic> json) {
    return ScheduledCategoryRef(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  @override
  List<Object?> get props => [id, name];
}
