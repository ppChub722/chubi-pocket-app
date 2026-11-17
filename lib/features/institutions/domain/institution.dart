import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import '../../transactions/domain/refs.dart';

/// What an institution is (0.4.3): a bank, a card issuer, a finance company,
/// a store (SPayLater …) or something else.
enum InstitutionKind {
  bank,
  card,
  finance,
  store,
  other;

  static InstitutionKind fromJson(Object? v) => InstitutionKind.values
      .firstWhere((k) => k.name == v, orElse: () => InstitutionKind.other);

  String toJson() => name;
}

enum InstitutionStatus {
  active,
  archived;

  static InstitutionStatus fromJson(Object? v) =>
      v == 'archived' ? archived : active;
}

PpForgeIconCode? _icon(Object? v) =>
    v is Map<String, dynamic> ? PpForgeIconCode.fromJson(v) : null;

String? _text(Object? v) {
  final s = (v as String?)?.trim();
  return s == null || s.isEmpty ? null : s;
}

/// A central provider an institution was picked from (read-only).
class InstitutionProvider extends Equatable {
  const InstitutionProvider({
    required this.id,
    required this.name,
    this.shortName,
    this.color,
    this.phone,
    this.website,
  });

  static InstitutionProvider? tryParse(Object? json) =>
      json is Map<String, dynamic> && json['id'] is String
      ? InstitutionProvider(
          id: json['id'] as String,
          name: (json['name'] as String?) ?? '',
          shortName: _text(json['short_name']),
          color: _text(json['color']),
          phone: _text(json['phone']),
          website: _text(json['website']),
        )
      : null;

  final String id;
  final String name;
  final String? shortName;

  /// "#RRGGBB" from the providers table.
  final String? color;
  final String? phone;
  final String? website;

  @override
  List<Object?> get props => [id, name, shortName, color, phone, website];
}

/// An institution embedded in another row (a wallet, a debt counterparty, a
/// recurring item): `{id, name, kind, icon_code}`.
class InstitutionRef extends Equatable {
  const InstitutionRef({
    required this.id,
    required this.name,
    this.kind = InstitutionKind.other,
    this.iconCode,
  });

  static InstitutionRef? tryParse(Object? json) =>
      json is Map<String, dynamic> && json['id'] is String
      ? InstitutionRef(
          id: json['id'] as String,
          name: (json['name'] as String?) ?? '',
          kind: InstitutionKind.fromJson(json['kind']),
          iconCode: _icon(json['icon_code']),
        )
      : null;

  final String id;
  final String name;
  final InstitutionKind kind;
  final PpForgeIconCode? iconCode;

  /// The counterparty key of its debt page (`i:<id>`).
  String get debtKey => institutionDebtKey(id);

  @override
  List<Object?> get props => [id, name, kind, iconCode];
}

/// The debt pages' counterparty key of an institution.
String institutionDebtKey(String id) => 'i:$id';

/// The institution id of an `i:` key; null for a person key.
String? institutionIdOfKey(String key) =>
    key.startsWith('i:') ? key.substring(2) : null;

/// One of the user's institutions (`GET /institutions`, `/institutions/{id}`).
class Institution extends Equatable {
  const Institution({
    required this.id,
    required this.name,
    this.kind = InstitutionKind.other,
    this.providerId,
    this.provider,
    this.phone,
    this.email,
    this.iconCode,
    this.description,
    this.note,
    this.status = InstitutionStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    kind: InstitutionKind.fromJson(json['kind']),
    providerId: json['provider_id'] as String?,
    provider: InstitutionProvider.tryParse(json['provider']),
    phone: _text(json['phone']),
    email: _text(json['email']),
    iconCode: _icon(json['icon_code']),
    description: _text(json['description']),
    note: _text(json['note']),
    status: InstitutionStatus.fromJson(json['status']),
    createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
    updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? ''),
  );

  final String id;
  final String name;
  final InstitutionKind kind;
  final String? providerId;
  final InstitutionProvider? provider;
  final String? phone;
  final String? email;
  final PpForgeIconCode? iconCode;
  final String? description;
  final String? note;
  final InstitutionStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// The user's own phone, else the central provider's.
  String? get shownPhone => phone ?? provider?.phone;

  String? get website => provider?.website;

  bool get archived => status == InstitutionStatus.archived;

  InstitutionRef get ref =>
      InstitutionRef(id: id, name: name, kind: kind, iconCode: iconCode);

  @override
  List<Object?> get props => [
    id,
    name,
    kind,
    providerId,
    provider,
    phone,
    email,
    iconCode,
    description,
    note,
    status,
    createdAt,
    updatedAt,
  ];
}

/// An institution's debt in short (its page's hero): net > 0 = it owes me.
class InstitutionDebtSummary extends Equatable {
  const InstitutionDebtSummary({
    required this.key,
    this.net = 0,
    this.entryCount = 0,
    this.recurringCount = 0,
  });

  factory InstitutionDebtSummary.fromJson(
    Map<String, dynamic>? json, {
    required String id,
  }) => InstitutionDebtSummary(
    key: (json?['key'] as String?) ?? institutionDebtKey(id),
    net: (json?['net'] as num?)?.toDouble() ?? 0,
    entryCount: (json?['entry_count'] as num?)?.toInt() ?? 0,
    recurringCount: (json?['recurring_count'] as num?)?.toInt() ?? 0,
  );

  final String key;
  final double net;
  final int entryCount;
  final int recurringCount;

  @override
  List<Object?> get props => [key, net, entryCount, recurringCount];
}

/// `GET /institutions/{id}`: the institution, its linked wallets and its
/// debt in short.
class InstitutionDetail extends Equatable {
  const InstitutionDetail({
    required this.institution,
    this.accounts = const [],
    required this.debt,
  });

  factory InstitutionDetail.fromJson(Map<String, dynamic> json) {
    final i = Institution.fromJson(json);
    return InstitutionDetail(
      institution: i,
      accounts: [
        for (final a in (json['accounts'] as List?) ?? const [])
          if (a is Map<String, dynamic>) AccountRef.fromJson(a),
      ],
      debt: InstitutionDebtSummary.fromJson(
        json['debt'] as Map<String, dynamic>?,
        id: i.id,
      ),
    );
  }

  final Institution institution;
  final List<AccountRef> accounts;
  final InstitutionDebtSummary debt;

  @override
  List<Object?> get props => [institution, accounts, debt];
}

/// `POST / PUT /institutions` body.
class InstitutionWrite extends Equatable {
  const InstitutionWrite({
    required this.name,
    required this.kind,
    this.providerId,
    this.phone,
    this.email,
    this.iconCode,
    this.description,
    this.note,
  });

  final String name;
  final InstitutionKind kind;
  final String? providerId;
  final String? phone;
  final String? email;
  final PpForgeIconCode? iconCode;
  final String? description;
  final String? note;

  Map<String, dynamic> toJson() => {
    'name': name,
    'kind': kind.toJson(),
    'provider_id': providerId,
    'phone': phone,
    'email': email,
    'icon_code': iconCode?.toJson(),
    'description': description,
    'note': note,
  };

  @override
  List<Object?> get props => [
    name,
    kind,
    providerId,
    phone,
    email,
    iconCode,
    description,
    note,
  ];
}
