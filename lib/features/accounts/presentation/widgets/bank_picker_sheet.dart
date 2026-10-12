import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/payment_provider.dart';

/// What [showBankPicker] resolves to — `null` = dismissed. [bank] null =
/// ไม่ระบุ.
class BankPick {
  const BankPick(this.bank);
  final PaymentProvider? bank;
}

/// The big five, in this order, ahead of the rest (owner 2026-10-11):
/// กสิกร · ไทยพาณิชย์ · กรุงเทพ · กรุงไทย · กรุงศรี (BOT codes).
const _majorBankCodes = ['004', '014', '002', '006', '025'];

/// A provider as the kit's plain bank row, named in [lang].
BankPickerItem bankPickerItemOf(PaymentProvider p, String lang) =>
    BankPickerItem(
      code: p.code,
      name: p.name(lang),
      nameTh: p.nameTh,
      nameEn: p.nameEn,
      shortName: p.shortName,
    );

/// The banks among [providers], the major ones first then by name, as the kit's
/// plain rows.
List<BankPickerItem> rankedBankItems(
  List<PaymentProvider> providers,
  String lang,
) {
  int rank(PaymentProvider p) {
    final i = _majorBankCodes.indexOf(p.code);
    return i < 0 ? _majorBankCodes.length : i;
  }

  final banks = providers.where((p) => p.isBank).toList()
    ..sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : a.name(lang).compareTo(b.name(lang));
    });
  return [for (final b in banks) bankPickerItemOf(b, lang)];
}

/// "ธนาคาร" — the banks among [providers] on the kit bank sheet
/// ([showBankSelectSheet]): the major banks first, then the rest by name.
/// [allowNone] adds "ไม่ระบุ" on top. The current one ([selectedCode]) is
/// highlighted, no ✓. This wrapper ranks + maps the models and l10n.
Future<BankPick?> showBankPicker(
  BuildContext context, {
  required List<PaymentProvider> providers,
  String? selectedCode,
  bool allowNone = true,
  String? title,
}) async {
  final l = AppLocalizations.of(context)!;
  final lang = Localizations.localeOf(context).languageCode;
  final choice = await showBankSelectSheet(
    context,
    banks: rankedBankItems(providers, lang),
    selectedCode: selectedCode,
    allowNone: allowNone,
    strings: BankPickerStrings(
      title: title ?? l.identifierBankLabel,
      noneLabel: l.identifierBankNone,
    ),
  );
  if (choice == null) return null;
  return BankPick(
    choice.code == null
        ? null
        : providers.firstWhere((p) => p.code == choice.code),
  );
}

/// A bank's mark: the kit's [BankBrandMark] for a [PaymentProvider].
class BankMark extends StatelessWidget {
  const BankMark({required this.provider, this.size = 36, super.key});

  final PaymentProvider provider;
  final double size;

  @override
  Widget build(BuildContext context) => BankBrandMark(
    code: provider.code,
    shortName: provider.shortName,
    nameEn: provider.nameEn,
    size: size,
  );
}
