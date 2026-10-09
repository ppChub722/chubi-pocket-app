import 'package:equatable/equatable.dart';

/// Who money moves through — banks now, e-wallets / card issuers later
/// (BE `payment_providers`, `GET /v1/payment-providers`). [code] is in
/// [scheme]'s system: "bot" = the Bank of Thailand's 3-digit bank code.
class PaymentProvider extends Equatable {
  const PaymentProvider({
    required this.kind,
    required this.scheme,
    required this.code,
    required this.nameTh,
    required this.nameEn,
    this.shortName,
  });

  final String kind; // bank | e_wallet | card_issuer | other
  final String scheme;
  final String code;
  final String nameTh;
  final String nameEn;
  final String? shortName;

  bool get isBank => kind == 'bank';

  /// The name for [languageCode] ("th" → Thai, else English).
  String name(String languageCode) => languageCode == 'th' ? nameTh : nameEn;

  /// Short label for rows: "KBANK", else the full name.
  String label(String languageCode) => shortName ?? name(languageCode);

  factory PaymentProvider.fromJson(Map<String, dynamic> json) =>
      PaymentProvider(
        kind: json['kind'] as String,
        scheme: json['scheme'] as String,
        code: json['code'] as String,
        nameTh: json['name_th'] as String,
        nameEn: json['name_en'] as String,
        shortName: json['short_name'] as String?,
      );

  @override
  List<Object?> get props => [kind, scheme, code, nameTh, nameEn, shortName];
}
