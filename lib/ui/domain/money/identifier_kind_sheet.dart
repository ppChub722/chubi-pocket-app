import 'package:flutter/material.dart';

import '../../ui.dart';

/// One kind in [showIdentifierKindSelectSheet] (account / PromptPay / card /
/// other). [id] is the caller's own key; [hasBank] kinds go on to the bank
/// step.
@immutable
class IdentifierKindOption {
  const IdentifierKindOption({
    required this.id,
    required this.label,
    required this.icon,
    this.hasBank = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool hasBank;
}

/// What the kind sheet resolves to: the picked [kindId] and its [bankCode]
/// (null for kinds without a bank; a dismissed bank step keeps the bank as
/// it was).
@immutable
class IdentifierKindChoice {
  const IdentifierKindChoice(this.kindId, this.bankCode);
  final String kindId;
  final String? bankCode;
}

/// The words of the kind sheet.
class IdentifierKindStrings {
  const IdentifierKindStrings({
    required this.title,
    required this.bankLabel,
    required this.bankNoneLabel,
  });

  final String title;

  /// The bank row's title (also the bank sheet's title).
  final String bankLabel;

  /// The bank row's subtitle while no bank is set (also the bank sheet's
  /// "none" row).
  final String bankNoneLabel;
}

/// The edit row's chip sheet (kit [PickerSheet]): the kind, the current one
/// ([currentKindId]) highlighted (no check) and, for a kind with a bank, its
/// bank row (the bank sheet over [banks]). Resolves the picked kind + bank,
/// or null when dismissed.
Future<IdentifierKindChoice?> showIdentifierKindSelectSheet(
  BuildContext context, {
  required List<IdentifierKindOption> kinds,
  required String currentKindId,
  required List<BankPickerItem> banks,
  required IdentifierKindStrings strings,
  String? currentBankCode,
}) {
  return showPpForgeSheetCustom<IdentifierKindChoice>(
    context,
    builder: (_) => _KindSheet(
      kinds: kinds,
      currentKindId: currentKindId,
      banks: banks,
      strings: strings,
      currentBankCode: currentBankCode,
    ),
  );
}

class _KindSheet extends StatelessWidget {
  const _KindSheet({
    required this.kinds,
    required this.currentKindId,
    required this.banks,
    required this.strings,
    required this.currentBankCode,
  });

  final List<IdentifierKindOption> kinds;
  final String currentKindId;
  final List<BankPickerItem> banks;
  final IdentifierKindStrings strings;
  final String? currentBankCode;

  Future<void> _pickBank(
    BuildContext context,
    IdentifierKindOption kind,
  ) async {
    final pick = await showBankSelectSheet(
      context,
      banks: banks,
      selectedCode: currentBankCode,
      strings: BankPickerStrings(
        title: strings.bankLabel,
        noneLabel: strings.bankNoneLabel,
      ),
    );
    if (!context.mounted) return;
    Navigator.of(context).pop(
      IdentifierKindChoice(
        kind.id,
        // Dismissed: the bank stays as it was.
        pick == null ? currentBankCode : pick.code,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = kinds.where((k) => k.id == currentKindId).firstOrNull;
    final bank = currentBankCode == null
        ? null
        : banks.where((b) => b.code == currentBankCode).firstOrNull;
    return PickerSheet(
      title: strings.title,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            first: true,
            children: [
              for (final k in kinds)
                PickerRow(
                  leading: PpForgeIcon(k.icon),
                  title: k.label,
                  selected: k.id == currentKindId,
                  onTap: () {
                    // With a bank: on to its bank; the others are done.
                    if (k.hasBank && k.id != currentKindId) {
                      _pickBank(context, k);
                      return;
                    }
                    Navigator.of(context).pop(
                      IdentifierKindChoice(
                        k.id,
                        k.hasBank ? currentBankCode : null,
                      ),
                    );
                  },
                ),
              if (current != null && current.hasBank)
                PickerRow(
                  leading: bank == null
                      ? const PpForgeIcon(PpForgeIcons.bank)
                      : BankBrandMark(
                          code: bank.code,
                          shortName: bank.shortName,
                          nameEn: bank.nameEn,
                          size: 24,
                        ),
                  title: strings.bankLabel,
                  subtitle: bank?.name ?? strings.bankNoneLabel,
                  chevron: true,
                  onTap: () => _pickBank(context, current),
                ),
            ],
          ),
          const SizedBox(height: PpForgeSpacing.sm),
        ],
      ),
    );
  }
}
