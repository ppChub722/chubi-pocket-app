import 'package:equatable/equatable.dart';

/// Kinds of [AccountIdentifier] (BE `accounts.identifiers[].kind`).
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

/// A number a wallet is known by on bank slips — its bank account,
/// PromptPay, card (spec 15 §5). Slip import matches a slip's masked
/// numbers against these to pick the wallet and the draft's direction.
///
/// [value] is digits with `x` for digits not known: a full number the
/// user typed, or a masked one saved from a slip ("xxxxx2780x").
class AccountIdentifier extends Equatable {
  const AccountIdentifier({
    required this.kind,
    required this.value,
    this.bankCode,
  });

  final IdentifierKind kind;
  final String value;

  /// The bank's 3-digit code (`payment_providers`, scheme "bot").
  final String? bankCode;

  /// Minimum digits a value needs (same rule as the BE).
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

  /// "123-4-52780-6" → "1234527806", "xxx-x-x2780-x" → "xxxxx2780x":
  /// separators dropped, every hidden-digit mark becomes `x`.
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

  /// What a user may type: digits, x for hidden ones, and separators.
  static bool looksValid(String input) =>
      RegExp(r'^[0-9xX×*•\-\s.]+$').hasMatch(input.trim());

  static int digitCount(String s) => RegExp(r'\d').allMatches(s).length;

  /// The last four visible digits ("2780"), for the hidden view.
  String get lastDigits {
    final digits = value.replaceAll('x', '');
    return digits.length <= 4 ? digits : digits.substring(digits.length - 4);
  }

  /// Hidden view: "•••• 2780".
  String get masked => '•••• $lastDigits';

  /// Shown view: the digits exactly as typed (owner 2026-10-11: no grouping
  /// — the numbers only exist to match accounts when scanning slips).
  String get formatted => value;

  @override
  List<Object?> get props => [kind, value, bankCode];
}
