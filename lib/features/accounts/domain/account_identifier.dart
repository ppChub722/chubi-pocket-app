import 'package:equatable/equatable.dart';

enum IdentifierKind {
  bankAccount('bank_account'),
  promptPay('promptpay'),
  card('card'),
  other('other');

  const IdentifierKind(this.wire);
  final String wire;

  static IdentifierKind parse(String? s) => IdentifierKind.values.firstWhere(
    (k) => k.wire == s,
    orElse: () => IdentifierKind.other,
  );
}

class AccountIdentifier extends Equatable {
  const AccountIdentifier({
    required this.kind,
    required this.value,
    this.bankCode,
  });

  final IdentifierKind kind;
  final String value;

  final String? bankCode;

  static const minDigits = 4;

  factory AccountIdentifier.fromJson(Map<String, dynamic> json) =>
      AccountIdentifier(
        kind: IdentifierKind.parse(json['kind'] as String?),
        value: (json['value'] as String?) ?? '',
        bankCode: json['bank_code'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'kind': kind.wire,
    'value': value,
    if (bankCode != null && bankCode!.isNotEmpty) 'bank_code': bankCode,
  };

  static String normalize(String input) {
    final b = StringBuffer();
    for (final r in input.runes) {
      final c = String.fromCharCode(r);
      if (RegExp(r'\d').hasMatch(c)) {
        b.write(c);
      } else if ('xX×*•'.contains(c)) {
        b.write('x');
      }
    }
    return b.toString();
  }

  static bool looksValid(String input) =>
      RegExp(r'^[0-9xX×*•\-\s.]+$').hasMatch(input.trim());

  static int digitCount(String s) => RegExp(r'\d').allMatches(s).length;

  String get lastDigits {
    final digits = value.replaceAll('x', '');
    return digits.length <= 4 ? digits : digits.substring(digits.length - 4);
  }

  String get masked => '•••• $lastDigits';

  String get formatted => value;

  @override
  List<Object?> get props => [kind, value, bankCode];
}
