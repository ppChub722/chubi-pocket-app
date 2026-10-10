import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/account_identifier.dart';
import '../../domain/payment_provider.dart';
import 'bank_picker_sheet.dart';

/// Wallet numbers (spec 15 §5) — the rows on the wallet page, read-only in
/// view mode and edited inline in edit mode like the splits section
/// (owner 2026-10-11): `[kind · bank ▾] [number] ✕`. Feature widgets, not
/// shared UI kit.

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

/// Kinds that belong to a bank (account number, card issuer).
bool identifierHasBank(IdentifierKind k) =>
    k == IdentifierKind.bankAccount || k == IdentifierKind.card;

PaymentProvider? _bankOf(
  AccountIdentifier id,
  List<PaymentProvider> providers,
) => id.bankCode == null
    ? null
    : providers.where((p) => p.code == id.bankCode).firstOrNull;

/// The leading mark: the bank's [BankMark] when known, else the kind's
/// icon.
Widget _mark(
  BuildContext context,
  AccountIdentifier id,
  List<PaymentProvider> providers, {
  double size = 24,
}) {
  final bank = identifierHasBank(id.kind) ? _bankOf(id, providers) : null;
  if (bank != null) return BankMark(provider: bank, size: size);
  return Icon(
    identifierKindIcon(id.kind),
    size: size * 0.9,
    color: Theme.of(context).colorScheme.primary,
  );
}

/// "เลขบัญชี · KBANK".
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

/// One wallet number, read-only: kind (+ bank) on the left, the number on
/// the right — "•••• 2780" while money is hidden (the app-wide 👁).
/// [onTap] / [onDelete] are kept for older callers (gallery).
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

/// One wallet number in edit mode: `[kind · bank ▾] [number] ✕`. The chip
/// opens [showIdentifierKindSheet]; the number is typed in place,
/// formatted for its kind as it's typed ([IdentifierInputFormatter]).
/// Its validator runs with the page's form (an empty row is dropped on
/// save, not an error).
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

  /// A new kind / bank / number.
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
    // Compare values, not text (undo, a removed row above, a new kind).
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
    // A shorter kind (card = 4 digits) trims what's there.
    final value = IdentifierInputFormatter.clip(next.kind, next.value);
    widget.onChanged(
      AccountIdentifier(kind: next.kind, value: value, bankCode: next.bankCode),
    );
  }

  String? _validate(String? v, AppLocalizations l) {
    final norm = AccountIdentifier.normalize(v ?? '');
    if (norm.isEmpty) return null; // dropped on save
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: RowChip(
              label: _kindLine(context, id, widget.providers),
              leading: _mark(context, id, widget.providers, size: 18),
              trailingIcon: AppIcons.dropdown,
              onTap: _pickKind,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              controller: _number,
              autofocus: widget.autofocus,
              keyboardType: id.kind == IdentifierKind.other
                  ? TextInputType.visiblePassword
                  : TextInputType.number,
              inputFormatters: [IdentifierInputFormatter(id.kind)],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                hintText: _hint(l, id.kind),
                isDense: true,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: scheme.primary),
                ),
              ),
              validator: (v) => _validate(v, l),
              onChanged: (v) => widget.onChanged(
                AccountIdentifier(
                  kind: id.kind,
                  value: AccountIdentifier.normalize(v),
                  bankCode: id.bankCode,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l.identifierDelete,
            icon: const Icon(AppIcons.close, size: 18),
            visualDensity: VisualDensity.compact,
            color: scheme.onSurfaceVariant,
            onPressed: widget.onRemove,
          ),
        ],
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

/// Formats a wallet number for its kind as it's typed: digits (and `x`
/// for digits a slip hid) only —
/// - เลขบัญชี: 123-4-56789-0 (10 digits; longer ones as typed, max 15)
/// - พร้อมเพย์: phone 081-234-5678, or ID 1-2345-67890-12-3 (max 13)
/// - บัตร: the last 4 digits only
/// - อื่น ๆ: as typed, max 32
class IdentifierInputFormatter extends TextInputFormatter {
  IdentifierInputFormatter(this.kind);

  final IdentifierKind kind;

  static int maxLength(IdentifierKind k) => switch (k) {
    IdentifierKind.bankAccount => 15,
    IdentifierKind.promptPay => 13,
    IdentifierKind.card => 4,
    IdentifierKind.other => 32,
  };

  /// [value] (normalized) cut to what [kind] holds — a card keeps its last
  /// four.
  static String clip(IdentifierKind kind, String value) {
    final max = maxLength(kind);
    if (value.length <= max) return value;
    return kind == IdentifierKind.card
        ? value.substring(value.length - max)
        : value.substring(0, max);
  }

  /// The grouped text for a normalized [value].
  static String format(IdentifierKind kind, String value) {
    final List<int>? groups = switch (kind) {
      IdentifierKind.bankAccount when value.length <= 10 => [3, 1, 5, 1],
      IdentifierKind.promptPay when value.length <= 10 => [3, 3, 4],
      IdentifierKind.promptPay => [1, 4, 5, 2, 1],
      _ => null,
    };
    if (groups == null) return value;
    final parts = <String>[];
    var i = 0;
    for (final g in groups) {
      if (i >= value.length) break;
      final end = (i + g).clamp(0, value.length);
      parts.add(value.substring(i, end));
      i = end;
    }
    return parts.join('-');
  }

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

/// The edit row's chip sheet (kit [PickerSheet]): the kind — เลขบัญชี /
/// พร้อมเพย์ / บัตร / อื่น ๆ, the current one highlighted (no ✓) — and,
/// for an account or a card, its bank (the bank picker). Returns the
/// identifier with the new kind / bank, or null when dismissed.
Future<AccountIdentifier?> showIdentifierKindSheet(
  BuildContext context, {
  required AccountIdentifier identifier,
  required List<PaymentProvider> providers,
}) {
  return showAppSheetCustom<AccountIdentifier>(
    context,
    builder: (_) => _KindSheet(identifier: identifier, providers: providers),
  );
}

class _KindSheet extends StatelessWidget {
  const _KindSheet({required this.identifier, required this.providers});

  final AccountIdentifier identifier;
  final List<PaymentProvider> providers;

  Future<void> _pickBank(BuildContext context, IdentifierKind kind) async {
    final l = AppLocalizations.of(context)!;
    final pick = await showBankPicker(
      context,
      providers: providers,
      selectedCode: identifier.bankCode,
      title: l.identifierBankLabel,
    );
    if (!context.mounted) return;
    Navigator.of(context).pop(
      AccountIdentifier(
        kind: kind,
        value: identifier.value,
        // Dismissed: the bank stays as it was.
        bankCode: pick == null ? identifier.bankCode : pick.bank?.code,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final current = identifier.kind;
    final bank = _bankOf(identifier, providers);
    return PickerSheet(
      title: l.identifierKindLabel,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final k in IdentifierKind.values)
            PickerRow(
              leading: Icon(identifierKindIcon(k)),
              title: identifierKindLabel(l, k),
              selected: k == current,
              onTap: () {
                // Account / card: on to its bank; the others are done.
                if (identifierHasBank(k) && k != current) {
                  _pickBank(context, k);
                  return;
                }
                Navigator.of(context).pop(
                  AccountIdentifier(
                    kind: k,
                    value: identifier.value,
                    bankCode: identifierHasBank(k) ? identifier.bankCode : null,
                  ),
                );
              },
            ),
          if (identifierHasBank(current)) ...[
            const Divider(height: 1),
            PickerRow(
              leading: bank == null
                  ? const Icon(AppIcons.bank)
                  : BankMark(provider: bank, size: 24),
              title: l.identifierBankLabel,
              subtitle: bank?.name(lang) ?? l.identifierBankNone,
              trailing: const Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: Icon(AppIcons.chevronRight),
              ),
              onTap: () => _pickBank(context, current),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// The numbers section's title-row action ([SectionCard.trailing]): the
/// app-wide 👁 (the same toggle that hides money). Hidden ([show] false) it
/// keeps the toggle's height, so the title row doesn't jump.
class IdentifiersVisibility extends StatelessWidget {
  const IdentifiersVisibility({this.show = true, super.key});

  final bool show;

  @override
  Widget build(BuildContext context) => show && kMoneyPrivacyEnabled
      ? const MoneyVisibilityToggle()
      : const SizedBox(height: 40);
}
