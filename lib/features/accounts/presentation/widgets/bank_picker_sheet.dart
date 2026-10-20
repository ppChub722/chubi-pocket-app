import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../domain/payment_provider.dart';

const _majorBankCodes = ['004', '014', '002', '006', '025'];

BankPickerItem bankPickerItemOf(PaymentProvider p, String lang) =>
    BankPickerItem(
      code: p.code,
      name: p.name(lang),
      nameTh: p.nameTh,
      nameEn: p.nameEn,
      shortName: p.shortName,
    );

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
