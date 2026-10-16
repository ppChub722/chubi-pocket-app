import 'package:flutter/material.dart';

import '../../ui.dart';

/// One bank in [showBankSelectSheet]: plain values, no app model. [name] is
/// the display name (already in the UI language); [nameTh] / [nameEn] /
/// [shortName] / [code] are what the search matches.
@immutable
class BankPickerItem {
  const BankPickerItem({
    required this.code,
    required this.name,
    this.nameTh = '',
    this.nameEn = '',
    this.shortName,
  });

  /// The BOT bank code ("004") — also picks the brand colour.
  final String code;
  final String name;
  final String nameTh;
  final String nameEn;
  final String? shortName;
}

/// What the bank sheet resolves to — null (dismissed) is not a pick;
/// [code] null = "none".
@immutable
class BankPickerChoice {
  const BankPickerChoice(this.code);
  final String? code;
}

/// The words of the bank sheet (the kit never reads the app's l10n).
class BankPickerStrings {
  const BankPickerStrings({
    required this.title,
    required this.noneLabel,
    this.searchHint,
  });

  final String title;

  /// The top "no bank" row (shown only when `allowNone`).
  final String noneLabel;
  final String? searchHint;
}

/// A bank on the kit [PickerSheet]: [banks] in the order given (the caller
/// ranks them), each row leading with its [BankBrandMark]. Searchable over
/// name / English name / short name / code. [allowNone] adds the "none" row
/// on top. The current one ([selectedCode]) is highlighted, no ✓.
Future<BankPickerChoice?> showBankSelectSheet(
  BuildContext context, {
  required List<BankPickerItem> banks,
  required BankPickerStrings strings,
  String? selectedCode,
  bool allowNone = true,
}) {
  return showPpForgeSheetCustom<BankPickerChoice>(
    context,
    builder: (_) => PickerSheet(
      title: strings.title,
      searchable: true,
      searchHint: strings.searchHint,
      builder: (context, query) {
        bool hit(BankPickerItem p) =>
            p.nameTh.toLowerCase().contains(query) ||
            p.nameEn.toLowerCase().contains(query) ||
            (p.shortName?.toLowerCase().contains(query) ?? false) ||
            p.code.contains(query);
        final shown = query.isEmpty ? banks : banks.where(hit).toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((allowNone && query.isEmpty) || shown.isNotEmpty)
              SectionCard(
                first: true,
                children: [
                  if (allowNone && query.isEmpty)
                    PickerRow(
                      leading: const PpForgeIcon(PpForgeIcons.bank),
                      title: strings.noneLabel,
                      selected: selectedCode == null,
                      onTap: () =>
                          Navigator.pop(context, const BankPickerChoice(null)),
                    ),
                  for (final b in shown)
                    PickerRow(
                      leading: BankBrandMark(
                        code: b.code,
                        shortName: b.shortName,
                        nameEn: b.nameEn,
                      ),
                      title: b.name,
                      subtitle: [?b.shortName, b.code].join(' · '),
                      selected: b.code == selectedCode,
                      onTap: () =>
                          Navigator.pop(context, BankPickerChoice(b.code)),
                    ),
                ],
              ),
            const SizedBox(height: PpForgeSpacing.md),
          ],
        );
      },
    ),
  );
}

/// A bank's mark: the kit brand avatar in the bank's colour, lettered from
/// its short code ("KBANK", "SCB"). The colour comes from [BankBrand] (BOT
/// code); unknown banks get a stable colour from their code.
class BankBrandMark extends StatelessWidget {
  const BankBrandMark({
    required this.code,
    this.shortName,
    this.nameEn = '',
    this.size = 36,
    super.key,
  });

  final String code;
  final String? shortName;
  final String nameEn;
  final double size;

  /// The short name, else the English name's initials ("Bangkok Bank" →
  /// "BB"), else the code.
  String get _letters {
    final s = shortName?.trim() ?? '';
    if (s.isNotEmpty) return s;
    final initials = nameEn
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .join();
    return initials.isEmpty ? code : initials;
  }

  @override
  Widget build(BuildContext context) => PpForgeAvatar.brand(
    name: _letters,
    color: BankBrand.of(code),
    size: size,
  );
}
