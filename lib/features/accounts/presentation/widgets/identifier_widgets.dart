import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/account_identifier.dart';
import '../../domain/payment_provider.dart';
import 'bank_picker_sheet.dart';

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

bool identifierHasBank(IdentifierKind k) =>
    k == IdentifierKind.bankAccount || k == IdentifierKind.card;

PaymentProvider? _bankOf(
  AccountIdentifier id,
  List<PaymentProvider> providers,
) => id.bankCode == null
    ? null
    : providers.where((p) => p.code == id.bankCode).firstOrNull;

Widget _mark(
  BuildContext context,
  AccountIdentifier id,
  List<PaymentProvider> providers, {
  double size = 24,
}) {
  final bank = identifierHasBank(id.kind) ? _bankOf(id, providers) : null;
  if (bank != null) return BankMark(provider: bank, size: size);
  return AppIcon(
    identifierKindIcon(id.kind),
    size: size * 0.9,
    color: Theme.of(context).colorScheme.primary,
  );
}

String identifierKindLine(
  BuildContext context,
  AccountIdentifier id,
  List<PaymentProvider> providers,
) => _kindLine(context, id, providers);

String _kindLine(
  BuildContext context,
  AccountIdentifier id,
  List<PaymentProvider> providers,
) {
  final l = AppLocalizations.of(context)!;
  final lang = Localizations.localeOf(context).languageCode;
  final bank = identifierHasBank(id.kind) ? _bankOf(id, providers) : null;
  return [
    identifierKindLabel(l, id.kind),
    if (bank != null)
      bank.label(lang)
    else if (identifierHasBank(id.kind))
      ?id.bankCode,
  ].join(' · ');
}

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
    return DetailRow(
      leading: _mark(context, identifier, providers),
      label: _kindLine(context, identifier, providers),
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
            AppIconButton.close(
              tooltip: l.identifierDelete,
              dense: true,
              color: scheme.error,
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class IdentifierEditRow extends StatefulWidget {
  const IdentifierEditRow({
    required this.identifier,
    required this.providers,
    required this.onChanged,
    required this.onRemove,
    this.autofocus = false,
    super.key,
  });

  final AccountIdentifier identifier;
  final List<PaymentProvider> providers;

  final ValueChanged<AccountIdentifier> onChanged;
  final VoidCallback onRemove;
  final bool autofocus;

  @override
  State<IdentifierEditRow> createState() => _IdentifierEditRowState();
}

class _IdentifierEditRowState extends State<IdentifierEditRow> {
  late final TextEditingController _number = TextEditingController(
    text: _display(widget.identifier),
  );

  static String _display(AccountIdentifier id) =>
      IdentifierInputFormatter.format(id.kind, id.value);

  @override
  void didUpdateWidget(covariant IdentifierEditRow old) {
    super.didUpdateWidget(old);
    if (AccountIdentifier.normalize(_number.text) != widget.identifier.value ||
        old.identifier.kind != widget.identifier.kind) {
      _number.text = _display(widget.identifier);
    }
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _pickKind() async {
    final next = await showIdentifierKindSheet(
      context,
      identifier: widget.identifier,
      providers: widget.providers,
    );
    if (next == null || !mounted) return;
    final value = IdentifierInputFormatter.clip(next.kind, next.value);
    widget.onChanged(
      AccountIdentifier(kind: next.kind, value: value, bankCode: next.bankCode),
    );
  }

  String? _validate(String? v, AppLocalizations l) {
    final norm = AccountIdentifier.normalize(v ?? '');
    if (norm.isEmpty) return null;
    switch (widget.identifier.kind) {
      case IdentifierKind.promptPay when norm.length != 10 && norm.length != 13:
        return l.identifierPromptPayLength;
      case IdentifierKind.card when norm.length != 4:
        return l.identifierCardLength;
      default:
        if (AccountIdentifier.digitCount(norm) < AccountIdentifier.minDigits) {
          return l.identifierValueTooShort;
        }
        if (norm.length > 32) return l.identifierValueTooLong;
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final id = widget.identifier;
    return ListRow(
      leading: AppChip(
        label: _kindLine(context, id, widget.providers),
        leading: _mark(context, id, widget.providers, size: 18),
        trailing: AppChipTrailing.dropdown,
        onTap: _pickKind,
      ),
      body: AppInput(
        controller: _number,
        autofocus: widget.autofocus,
        dense: true,
        keyboardType: id.kind == IdentifierKind.other
            ? TextInputType.visiblePassword
            : TextInputType.number,
        inputFormatters: [IdentifierInputFormatter(id.kind)],
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        hint: _hint(l, id.kind),
        validator: (v) => _validate(v, l),
        onChanged: (v) => widget.onChanged(
          AccountIdentifier(
            kind: id.kind,
            value: AccountIdentifier.normalize(v),
            bankCode: id.bankCode,
          ),
        ),
      ),
      trailing: AppIconButton.close(
        tooltip: l.identifierDelete,
        iconSize: AppIconSize.md,
        dense: true,
        color: scheme.onSurfaceVariant,
        onPressed: widget.onRemove,
      ),
    );
  }

  static String _hint(AppLocalizations l, IdentifierKind k) => switch (k) {
    IdentifierKind.bankAccount => l.identifierHintBankAccount,
    IdentifierKind.promptPay => l.identifierHintPromptPay,
    IdentifierKind.card => l.identifierHintCard,
    IdentifierKind.other => l.identifierValueLabel,
  };
}

class IdentifierInputFormatter extends TextInputFormatter {
  IdentifierInputFormatter(this.kind);

  final IdentifierKind kind;

  static int maxLength(IdentifierKind k) => switch (k) {
    IdentifierKind.bankAccount => 15,
    IdentifierKind.promptPay => 13,
    IdentifierKind.card => 4,
    IdentifierKind.other => 32,
  };

  static String clip(IdentifierKind kind, String value) {
    final max = maxLength(kind);
    if (value.length <= max) return value;
    return kind == IdentifierKind.card
        ? value.substring(value.length - max)
        : value.substring(0, max);
  }

  /// The text for a normalized [value] — as typed, never grouped.
  static String format(IdentifierKind kind, String value) => value;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var raw = AccountIdentifier.normalize(newValue.text);
    final max = maxLength(kind);
    if (raw.length > max) raw = raw.substring(0, max);
    final text = format(kind, raw);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

Future<AccountIdentifier?> showIdentifierKindSheet(
  BuildContext context, {
  required AccountIdentifier identifier,
  required List<PaymentProvider> providers,
}) async {
  final l = AppLocalizations.of(context)!;
  final lang = Localizations.localeOf(context).languageCode;
  final choice = await showIdentifierKindSelectSheet(
    context,
    kinds: [
      for (final k in IdentifierKind.values)
        IdentifierKindOption(
          id: k.name,
          label: identifierKindLabel(l, k),
          icon: identifierKindIcon(k),
          hasBank: identifierHasBank(k),
        ),
    ],
    currentKindId: identifier.kind.name,
    currentBankCode: identifier.bankCode,
    banks: rankedBankItems(providers, lang),
    strings: IdentifierKindStrings(
      title: l.identifierKindLabel,
      bankLabel: l.identifierBankLabel,
      bankNoneLabel: l.identifierBankNone,
    ),
  );
  if (choice == null) return null;
  return AccountIdentifier(
    kind: IdentifierKind.values.firstWhere((k) => k.name == choice.kindId),
    value: identifier.value,
    bankCode: choice.bankCode,
  );
}

class IdentifiersVisibility extends StatelessWidget {
  const IdentifiersVisibility({this.show = true, super.key});

  final bool show;

  @override
  Widget build(BuildContext context) => show && kMoneyPrivacyEnabled
      ? const MoneyVisibilityToggle()
      : const SizedBox(height: 40);
}
