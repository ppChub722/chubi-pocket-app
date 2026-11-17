import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurrence_rule.dart';
import '../../domain/recurring.dart';
import '../../domain/recurring_page.dart';
import '../recurring_draft.dart';

/// The หนี้ item form's plan section (0.4.3): มีแผนผ่อน on / off, principal,
/// count, first installment, interest (none / flat / reducing / fixed /
/// manual), ผ่อนผ่านบัตร with its card; then the BE's preview (ค่างวด / ดอก
/// รวม / จ่ายรวม) and the table ("ตารางงวด"). The controllers live here.
class RecurringPlanForm extends StatefulWidget {
  const RecurringPlanForm({
    required this.plan,
    required this.onChanged,
    super.key,
  });

  /// Null = no plan.
  final RecurringPlanDraft? plan;
  final ValueChanged<RecurringPlanDraft?> onChanged;

  @override
  State<RecurringPlanForm> createState() => _RecurringPlanFormState();
}

class _RecurringPlanFormState extends State<RecurringPlanForm> {
  final _principal = TextEditingController();
  final _count = TextEditingController();
  final _rate = TextEditingController();
  final _installment = TextEditingController();

  List<PlanInstallment>? _preview;
  bool _previewing = false;
  ApiException? _previewError;
  Timer? _debounce;
  RecurringPlanWrite? _asked;

  @override
  void initState() {
    super.initState();
    _sync();
    _schedulePreview();
  }

  @override
  void didUpdateWidget(RecurringPlanForm old) {
    super.didUpdateWidget(old);
    _sync();
    if (old.plan != widget.plan) _schedulePreview();
  }

  void _sync() {
    final p = widget.plan;
    void set(TextEditingController c, String v) {
      if (c.text != v) c.text = v;
    }

    if (p == null) return;
    set(_principal, p.principal);
    set(_count, p.count <= 0 ? '' : '${p.count}');
    set(_rate, p.rate);
    set(_installment, p.installmentAmount);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _principal.dispose();
    _count.dispose();
    _rate.dispose();
    _installment.dispose();
    super.dispose();
  }

  /// The BE works the installments out; asked again 600 ms after the last
  /// change, only for a complete plan.
  void _schedulePreview() {
    _debounce?.cancel();
    final write = widget.plan?.toWrite();
    if (write == null) {
      if (_preview != null) setState(() => _preview = null);
      return;
    }
    if (write == _asked) return;
    _debounce = Timer(const Duration(milliseconds: 600), () => _run(write));
  }

  Future<void> _run(RecurringPlanWrite write) async {
    _asked = write;
    setState(() {
      _previewing = true;
      _previewError = null;
    });
    try {
      final rows = await RecurringRepository.of(context).planPreview(write);
      if (!mounted || _asked != write) return;
      setState(() => _preview = rows);
    } on ApiException catch (e) {
      if (mounted) setState(() => _previewError = e);
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  RecurringPlanDraft get _plan =>
      widget.plan ?? RecurringPlanDraft(start: today());

  void _edit(RecurringPlanDraft next) => widget.onChanged(next);

  Future<void> _pickStart() async {
    final now = today();
    final current = _plan.start;
    final picked = await PpForgeDatePicker.show(
      context,
      initial: current,
      first: DateTime(now.year - 5),
      last: DateTime(now.year + 5, 12, 31),
    );
    if (!mounted || picked is! PpForgeDatePicked) return;
    _edit(_plan.copyWith(start: picked.date));
  }

  Future<void> _pickCard() async {
    final r = await AccountPicker.one(
      context,
      selectedId: _plan.cardAccountId,
      allowNone: true,
    );
    if (!mounted || r == null) return;
    _edit(switch (r) {
      AccountPicked(:final account) => _plan.copyWith(
        cardAccountId: account.id,
      ),
      _ => _plan.copyWith(clearCard: true),
    });
  }

  String _methodLabel(AppLocalizations l, PlanInterestMethod m) => switch (m) {
    PlanInterestMethod.none => l.recurringPlanMethodNone,
    PlanInterestMethod.flat => l.recurringPlanMethodFlat,
    PlanInterestMethod.reducing => l.recurringPlanMethodReducing,
    PlanInterestMethod.fixed => l.recurringPlanMethodFixed,
    PlanInterestMethod.manual => l.recurringPlanMethodManual,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = widget.plan;
    final symbol = context.readUserCurrencySymbol;
    String money(double v) => moneyString(context, v, symbol: symbol);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final rows = _preview;
    final interest = rows?.fold<double>(0, (s, i) => s + i.interest);
    final total = rows?.fold<double>(0, (s, i) => s + i.amount);
    return SectionCard(
      key: const ValueKey('planSection'),
      title: l.recurringPlanSection,
      children: [
        SettingToggleRow(
          key: const ValueKey('planToggle'),
          label: l.recurringPlanToggle,
          value: p != null,
          submits: false,
          onChanged: (on) =>
              widget.onChanged(on ? RecurringPlanDraft(start: today()) : null),
        ),
        if (p != null) ...[
          DetailTextField(
            key: const ValueKey('planPrincipal'),
            label: l.recurringPlanPrincipal,
            controller: _principal,
            editing: true,
            hint: symbol,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => _edit(p.copyWith(principal: v)),
          ),
          DetailTextField(
            key: const ValueKey('planCount'),
            label: l.recurringPlanCount,
            controller: _count,
            editing: true,
            keyboardType: TextInputType.number,
            onChanged: (v) => _edit(p.copyWith(count: int.tryParse(v) ?? 0)),
          ),
          PpForgeDetailRow(
            label: l.recurringPlanFirstDue,
            trailing: Text(DateFormat.yMMMd(locale).format(p.start)),
            showChevron: true,
            onTap: _pickStart,
          ),
          SettingDropdownRow<PlanInterestMethod>(
            key: const ValueKey('planMethod'),
            label: l.recurringPlanMethod,
            value: _methodLabel(l, p.method),
            selected: p.method,
            submits: false,
            onSelected: (m) => _edit(p.copyWith(method: m)),
            options: [
              for (final m in PlanInterestMethod.values)
                SheetOption(value: m, label: _methodLabel(l, m)),
            ],
          ),
          if (p.method == PlanInterestMethod.flat ||
              p.method == PlanInterestMethod.reducing)
            DetailTextField(
              key: const ValueKey('planRate'),
              label: l.recurringPlanRate,
              controller: _rate,
              editing: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (v) => _edit(p.copyWith(rate: v)),
            ),
          if (p.method == PlanInterestMethod.fixed)
            DetailTextField(
              key: const ValueKey('planInstallment'),
              label: l.recurringPlanInstallment,
              controller: _installment,
              editing: true,
              hint: symbol,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (v) => _edit(p.copyWith(installmentAmount: v)),
            ),
          SettingToggleRow(
            key: const ValueKey('planOnCard'),
            label: l.recurringPlanOnCard,
            caption: p.onCard ? l.recurringPlanOnCardNote : null,
            value: p.onCard,
            submits: false,
            onChanged: (on) =>
                on ? _pickCard() : _edit(p.copyWith(clearCard: true)),
          ),
          if (_previewing && rows == null)
            const ListRowSkeleton()
          else if (_previewError != null)
            PpForgeMessage(
              tone: Tone.danger,
              message: errorText(l, _previewError!),
            )
          else if (rows != null && rows.isNotEmpty) ...[
            HeroTiles(
              joined: true,
              children: [
                SummaryTileView(
                  tile: SummaryTile(
                    label: l.recurringPlanInstallment,
                    value: money(rows.first.amount),
                  ),
                ),
                SummaryTileView(
                  tile: SummaryTile(
                    label: l.recurringPlanTotalInterest,
                    value: money(interest ?? 0),
                  ),
                ),
                SummaryTileView(
                  tile: SummaryTile(
                    label: l.recurringPlanTotalPay,
                    value: money(total ?? 0),
                  ),
                ),
              ],
            ),
            PpForgeDetailRow(
              key: const ValueKey('planTable'),
              label: l.recurringPlanTable,
              trailing: Text(l.fpRecurringCountUnit(rows.length)),
              showChevron: true,
              onTap: () => showInstallmentTable(context, rows),
            ),
          ],
        ],
      ],
    );
  }
}
