import 'package:flutter/material.dart';

import '../../ui.dart';

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
/// (null for kinds without a bank; a dismissed bank step keeps the bank as it
/// was).
@immutable
class IdentifierKindChoice {
  const IdentifierKindChoice(this.kindId, this.bankCode);
  final String kindId;
  final String? bankCode;
}

class IdentifierKindStrings {
  const IdentifierKindStrings({
    required this.title,
    required this.bankLabel,
    required this.bankNoneLabel,
  });

  final String title;

  final String bankLabel;

  final String bankNoneLabel;
}

/// The app's bank picker for the bank step; null = dismissed.
typedef PickBank =
    Future<BankPickerChoice?> Function(
      BuildContext context,
      String? currentCode,
    );

Future<IdentifierKindChoice?> showIdentifierKindSelectSheet(
  BuildContext context, {
  required List<IdentifierKindOption> kinds,
  required String currentKindId,
  required List<BankPickerItem> banks,
  required IdentifierKindStrings strings,
  required PickBank pickBank,
  String? currentBankCode,
}) {
  return showAppSheetCustom<IdentifierKindChoice>(
    context,
    builder: (_) => _KindSheet(
      kinds: kinds,
      currentKindId: currentKindId,
      banks: banks,
      strings: strings,
      pickBank: pickBank,
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
    required this.pickBank,
    required this.currentBankCode,
  });

  final List<IdentifierKindOption> kinds;
  final String currentKindId;

  /// Only to show the current bank on its row.
  final List<BankPickerItem> banks;
  final IdentifierKindStrings strings;
  final PickBank pickBank;
  final String? currentBankCode;

  Future<void> _pickBank(
    BuildContext context,
    IdentifierKindOption kind,
  ) async {
    final pick = await pickBank(context, currentBankCode);
    if (!context.mounted) return;
    Navigator.of(context).pop(
      IdentifierKindChoice(kind.id, pick == null ? currentBankCode : pick.code),
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
                  leading: AppIcon(k.icon),
                  title: k.label,
                  selected: k.id == currentKindId,
                  onTap: () {
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
                      ? const AppIcon(AppIcons.bank)
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
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
