import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../ui.dart';

/// What to do with a bill that came in higher than recorded.
enum BillDiffBook { other, interest, manual }

/// ยอดบิลจริง of a card bill round: the actual bill against what was
/// recorded ([recorded] = the round's prefill) and, when it is higher, what
/// the user chose to do with the difference. Nothing is booked unless a
/// choice is picked (spec §2.3: asked, never automatic).
class BillDiffController extends ChangeNotifier {
  BillDiffController(this.recorded) : _actual = recorded;

  final double recorded;
  double _actual;
  BillDiffBook? _book;

  double get actual => _actual;
  BillDiffBook? get book => _book;

  /// actual − recorded, to the satang.
  double get diff => ((_actual - recorded) * 100).roundToDouble() / 100;

  set actual(double v) {
    if (v == _actual) return;
    _actual = v;
    notifyListeners();
  }

  set book(BillDiffBook? v) {
    if (v == _book) return;
    _book = v;
    notifyListeners();
  }

  /// The confirm call's `bill_diff` (null = nothing booked).
  Map<String, dynamic>? get billDiff => diff > 0 && _book != null
      ? switch (_book!) {
          BillDiffBook.other => {'amount': diff, 'category': 'other'},
          BillDiffBook.interest => {'amount': diff, 'category': 'interest'},
          BillDiffBook.manual => null,
        }
      : null;

  /// ไปเพิ่มรายการเอง: the user adds the difference themself after saving.
  bool get addByHand => diff > 0 && _book == BillDiffBook.manual;
}

/// The ยอดบิลจริง block of the card bill confirm sheet (mock BillSheet):
/// recorded vs actual; a higher bill asks อื่นๆ / ดอกเบี้ย / ไปเพิ่มรายการเอง /
/// ไม่ต้อง; paying less than the bill is fine. [paid] = the sheet's amount now,
/// [card] / [date] word the summary line.
class BillDiffSection extends StatefulWidget {
  const BillDiffSection({
    required this.controller,
    required this.card,
    required this.date,
    this.paid,
    super.key,
  });

  final BillDiffController controller;
  final String card;
  final DateTime date;
  final double? paid;

  @override
  State<BillDiffSection> createState() => _BillDiffSectionState();
}

class _BillDiffSectionState extends State<BillDiffSection> {
  late final _text = TextEditingController(
    text: AmountInput.format(widget.controller.recorded),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _text.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = widget.controller;
    final scheme = Theme.of(context).colorScheme;
    final diff = c.diff;
    String money(double v) => moneyString(context, v);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final booked = c.billDiff;
    return SectionCard(
      key: const ValueKey('billDiffSection'),
      title: l.billActualTitle,
      children: [
        Padding(
          padding: const EdgeInsets.all(PpForgeSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              PpForgeText(
                l.billRecorded(money(c.recorded)),
                role: PpForgeTextRole.caption,
              ),
              const SizedBox(height: PpForgeSpacing.xs),
              AmountInput(
                key: const ValueKey('billActual'),
                controller: _text,
                onChanged: (v) => c.actual = AmountInput.parse(v) ?? c.recorded,
              ),
              if (diff != 0) ...[
                const SizedBox(height: PpForgeSpacing.sm),
                PpForgeText(
                  l.billDiffWarn(money(diff.abs())),
                  role: PpForgeTextRole.body,
                  color: scheme.error,
                ),
              ],
              if (diff > 0) ...[
                const SizedBox(height: PpForgeSpacing.xs),
                PpForgeText(l.billDiffAsk, role: PpForgeTextRole.caption),
                const SizedBox(height: PpForgeSpacing.xs),
                Wrap(
                  spacing: PpForgeSpacing.xs,
                  runSpacing: PpForgeSpacing.xs,
                  children: [
                    for (final (b, label) in [
                      (BillDiffBook.other, l.billDiffOther),
                      (BillDiffBook.interest, l.billDiffInterest),
                      (BillDiffBook.manual, l.billDiffManual),
                      (null, l.billDiffNone),
                    ])
                      PpForgeChip(
                        key: ValueKey('billDiff:${b?.name ?? 'none'}'),
                        label: label,
                        selected: c.book == b,
                        onTap: () => c.book = b,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: PpForgeSpacing.sm),
              PpForgeText(l.billPayLessOk, role: PpForgeTextRole.caption),
              if (booked != null && widget.paid != null) ...[
                const SizedBox(height: PpForgeSpacing.xs),
                PpForgeText(
                  key: const ValueKey('billDiffSummary'),
                  l.billDiffSummary(
                    money(diff),
                    widget.card,
                    c.book == BillDiffBook.interest
                        ? l.billDiffInterest
                        : l.billDiffOther,
                    DateFormat.MMMd(locale).format(widget.date),
                    money(widget.paid!),
                  ),
                  role: PpForgeTextRole.caption,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
