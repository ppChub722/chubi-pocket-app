import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/account_identifier.dart';
import '../../domain/payment_provider.dart';

/// Wallet numbers (spec 15 §5) — the rows on the wallet page and the
/// add / edit sheet. Feature widgets, not shared UI kit.

String identifierKindLabel(AppLocalizations l, IdentifierKind k) => switch (k) {
  IdentifierKind.bankAccount => l.identifierKindBankAccount,
  IdentifierKind.promptPay => l.identifierKindPromptPay,
  IdentifierKind.card => l.identifierKindCard,
  IdentifierKind.other => l.identifierKindOther,
};

IconData identifierKindIcon(IdentifierKind k) => switch (k) {
  IdentifierKind.bankAccount => AppIcons.bank,
  IdentifierKind.promptPay => AppIcons.eWallet,
  IdentifierKind.card => AppIcons.creditCard,
  IdentifierKind.other => AppIcons.accountNumber,
};

/// One wallet number: kind (+ bank) on the left, the number on the right —
/// "•••• 2780" while money is hidden (the app-wide 👁). Edit mode: tap to
/// edit, × to remove.
class IdentifierRow extends StatelessWidget {
  const IdentifierRow({
    required this.identifier,
    required this.providers,
    this.hidden = false,
    this.onTap,
    this.onDelete,
    super.key,
  });

  final AccountIdentifier identifier;
  final List<PaymentProvider> providers;
  final bool hidden;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final bank = identifier.bankCode == null
        ? null
        : providers.where((p) => p.code == identifier.bankCode).firstOrNull;
    final label = [
      identifierKindLabel(l, identifier.kind),
      if (bank != null) bank.label(lang) else ?identifier.bankCode,
    ].join(' · ');
    return DetailRow(
      leading: Icon(identifierKindIcon(identifier.kind), color: scheme.primary),
      label: label,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hidden ? identifier.masked : identifier.formatted,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: l.identifierDelete,
              visualDensity: VisualDensity.compact,
              icon: Icon(AppIcons.close, color: scheme.error),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

/// Add ([initial] null) or edit one wallet number. Returns the cleaned
/// identifier, or null when dismissed.
Future<AccountIdentifier?> showIdentifierSheet(
  BuildContext context, {
  required List<PaymentProvider> providers,
  AccountIdentifier? initial,
}) {
  return showAppSheetCustom<AccountIdentifier>(
    context,
    builder: (_) => _IdentifierSheet(providers: providers, initial: initial),
  );
}

class _IdentifierSheet extends StatefulWidget {
  const _IdentifierSheet({required this.providers, this.initial});

  final List<PaymentProvider> providers;
  final AccountIdentifier? initial;

  @override
  State<_IdentifierSheet> createState() => _IdentifierSheetState();
}

class _IdentifierSheetState extends State<_IdentifierSheet> {
  final _formKey = GlobalKey<FormState>();
  late IdentifierKind _kind =
      widget.initial?.kind ?? IdentifierKind.bankAccount;
  late String? _bankCode = widget.initial?.bankCode;
  late final _value = TextEditingController(text: widget.initial?.formatted);

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  String? _validate(String? v, AppLocalizations l) {
    final t = v?.trim() ?? '';
    if (t.isEmpty || !AccountIdentifier.looksValid(t)) {
      return l.identifierValueInvalid;
    }
    final norm = AccountIdentifier.normalize(t);
    if (AccountIdentifier.digitCount(norm) < AccountIdentifier.minDigits) {
      return l.identifierValueTooShort;
    }
    if (norm.length > 32) return l.identifierValueTooLong;
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      AccountIdentifier(
        kind: _kind,
        value: AccountIdentifier.normalize(_value.text),
        // The bank only means something for a bank account.
        bankCode: _kind == IdentifierKind.bankAccount ? _bankCode : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final banks = widget.providers.where((p) => p.isBank).toList();
    final bank = banks.where((p) => p.code == _bankCode).firstOrNull;
    return AppSheetScaffold(
      title: widget.initial == null
          ? l.identifierSheetAddTitle
          : l.identifierSheetEditTitle,
      footer: AppButton(label: l.commonSave, onPressed: _save, expand: true),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectCardGroup<IdentifierKind>(
              columns: 4,
              selected: _kind,
              onChanged: (k) => setState(() => _kind = k),
              options: [
                for (final k in IdentifierKind.values)
                  SelectCardOption(
                    value: k,
                    label: identifierKindLabel(l, k),
                    icon: identifierKindIcon(k),
                  ),
              ],
            ),
            if (_kind == IdentifierKind.bankAccount) ...[
              const SizedBox(height: AppSpacing.md),
              DetailRow(
                label: l.identifierBankLabel,
                trailing: OptionMenuAnchor<String>(
                  selected: _bankCode ?? '',
                  onSelected: (c) =>
                      setState(() => _bankCode = c.isEmpty ? null : c),
                  options: [
                    SheetOption(value: '', label: l.identifierBankNone),
                    for (final b in banks)
                      SheetOption(
                        value: b.code,
                        label: b.name(lang),
                        subtitle: b.code,
                      ),
                  ],
                  builder: (context, toggle) => TextButton(
                    onPressed: toggle,
                    child: Text(bank?.label(lang) ?? l.identifierBankNone),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _value,
              label: l.identifierValueLabel,
              hint: l.identifierValueHint,
              helper: _kind == IdentifierKind.promptPay
                  ? l.identifierValueHelperPromptPay
                  : null,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              autofocus: widget.initial == null,
              validator: (v) => _validate(v, l),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
    );
  }
}

/// The numbers section's title row — [SectionCard]'s title look, with the
/// app-wide 👁 on the right (the same toggle that hides money).
class IdentifiersTitle extends StatelessWidget {
  const IdentifiersTitle({
    required this.title,
    this.showToggle = true,
    super.key,
  });

  final String title;
  final bool showToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showToggle)
            const MoneyVisibilityToggle()
          else
            const SizedBox(height: 40),
        ],
      ),
    );
  }
}
