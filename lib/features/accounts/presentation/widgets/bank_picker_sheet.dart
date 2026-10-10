import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
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

/// "ธนาคาร" — the banks among [providers] on the kit [PickerSheet]: the
/// major banks first, then the rest by name; each row leads with its
/// [BankMark]. Searchable over the Thai / English name, short name and
/// code. [allowNone] adds "ไม่ระบุ" on top. The current one
/// ([selectedCode]) is highlighted, no ✓.
Future<BankPick?> showBankPicker(
  BuildContext context, {
  required List<PaymentProvider> providers,
  String? selectedCode,
  bool allowNone = true,
  String? title,
}) {
  final l = AppLocalizations.of(context)!;
  final lang = Localizations.localeOf(context).languageCode;
  int rank(PaymentProvider p) {
    final i = _majorBankCodes.indexOf(p.code);
    return i < 0 ? _majorBankCodes.length : i;
  }

  final banks = providers.where((p) => p.isBank).toList()
    ..sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : a.name(lang).compareTo(b.name(lang));
    });
  return showAppSheetCustom<BankPick>(
    context,
    builder: (_) => PickerSheet(
      title: title ?? l.identifierBankLabel,
      searchable: true,
      builder: (context, query) {
        bool hit(PaymentProvider p) =>
            p.nameTh.toLowerCase().contains(query) ||
            p.nameEn.toLowerCase().contains(query) ||
            (p.shortName?.toLowerCase().contains(query) ?? false) ||
            p.code.contains(query);
        final shown = query.isEmpty ? banks : banks.where(hit).toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (allowNone && query.isEmpty)
              PickerRow(
                leading: const Icon(AppIcons.bank),
                title: l.identifierBankNone,
                selected: selectedCode == null,
                onTap: () => Navigator.pop(context, const BankPick(null)),
              ),
            for (final b in shown)
              PickerRow(
                leading: BankMark(provider: b),
                title: b.name(lang),
                subtitle: [?b.shortName, b.code].join(' · '),
                selected: b.code == selectedCode,
                onTap: () => Navigator.pop(context, BankPick(b)),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    ),
  );
}

/// A bank's mark: a circle in the bank's colour with its short code
/// ("KBANK", "SCB"). The colour comes from a built-in table of Thai banks
/// (BOT code); unknown banks get a stable colour from their code.
/// `payment_providers` has no logo yet — when it does, the logo goes here.
class BankMark extends StatelessWidget {
  const BankMark({required this.provider, this.size = 36, super.key});

  final PaymentProvider provider;
  final double size;

  /// Brand colours by BOT bank code.
  static const _brand = <String, Color>{
    '002': Color(0xFF1E4598), // BBL
    '004': Color(0xFF138F2D), // KBANK
    '006': Color(0xFF1BA5E1), // KTB
    '011': Color(0xFF0050F0), // TTB
    '014': Color(0xFF4E2E7F), // SCB
    '022': Color(0xFF7E2F36), // CIMB
    '024': Color(0xFF0B3979), // UOB
    '025': Color(0xFFFEC43B), // BAY
    '030': Color(0xFFEB198D), // GSB
    '033': Color(0xFFF57D23), // GHB
    '034': Color(0xFF4B9B2E), // BAAC
    '067': Color(0xFF12549F), // TISCO
    '069': Color(0xFF199CC5), // KKP
    '073': Color(0xFF6D6E71), // LH Bank
  };

  static const _fallback = <Color>[
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEF6C00),
    Color(0xFF8D6E63),
    Color(0xFF7E57C2),
    Color(0xFF00897B),
  ];

  Color get _color =>
      _brand[provider.code] ??
      _fallback[provider.code.codeUnits.fold(0, (a, b) => a + b) %
          _fallback.length];

  /// The short name, else the English name's initials ("Bangkok Bank" →
  /// "BB").
  String get _code {
    final s = provider.shortName?.trim() ?? '';
    if (s.isNotEmpty) return s;
    final initials = provider.nameEn
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .join();
    return initials.isEmpty ? provider.code : initials;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final onColor = color.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: FittedBox(
        child: Text(
          _code,
          maxLines: 1,
          style: TextStyle(
            color: onColor,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.32,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
