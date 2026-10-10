import 'package:flutter/material.dart';

import '../app/shell/app_top_bar.dart';
import '../core/constants/app_icons.dart';
import '../core/constants/app_spacing.dart';
import '../core/theme/app_colors.dart';
import '../shared/widgets/ui.dart';

/// `/dev/detail-playground` — one mock detail page (a wallet) that uses
/// every detail-page building block, to settle the row-divider (#16) and
/// section-separator (#17) rules on a real phone (owner 2026-10-10).
///
/// ⚙ (bottom right) switches, live:
/// - **เส้นคั่นแถว** — between rows (today) · under every row · none.
/// - **ตัวคั่น section** — today's mixed gaps · 24 px gap · full-width
///   line · tinted band.
/// - **โหมด** — view / edit (field outlines, locked action sections,
///   delete row, Cancel · Save bar).
///
/// The picked combo (between · band) renders the real `SectionCard`; the
/// other variants use a local stand-in, kept for comparison.
class DetailPlaygroundScreen extends StatefulWidget {
  const DetailPlaygroundScreen({super.key});

  @override
  State<DetailPlaygroundScreen> createState() => _DetailPlaygroundScreenState();
}

/// #16 — where row hairlines go.
enum _Dividers { between, underEvery, none }

/// #17 — what sits above each section after the first.
enum _Separator { today, gap, line, band }

class _DetailPlaygroundScreenState extends State<DetailPlaygroundScreen> {
  // The owner's pick (2026-10-10) — now the real SectionCard.
  _Dividers _dividers = _Dividers.between;
  _Separator _separator = _Separator.band;
  bool _editing = false;
  bool _inReport = true;

  final _name = TextEditingController(text: 'กสิกร เงินเดือน');
  final _description = TextEditingController(
    text: 'บัญชีรับเงินเดือน ใช้จ่ายประจำ',
  );
  final _note = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    void enterEdit() => setState(() => _editing = true);

    return Scaffold(
      appBar: AppTopBar(
        title: _editing ? 'แก้ไขกระเป๋า' : 'Detail playground',
        showBack: true,
        editing: _editing,
        showUniversal: false,
        onBack: _editing
            ? () => setState(() => _editing = false)
            : () => Navigator.of(context).maybePop(),
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: _editing
          ? null
          : FloatingActionButton.small(
              tooltip: 'ตัวเลือก',
              onPressed: _openOptions,
              child: const Icon(Icons.tune),
            ),
      bottomNavigationBar: _editing
          ? ModeActionBar(
              canSave: true,
              cancelLabel: 'ยกเลิก',
              saveLabel: 'บันทึก',
              onCancel: () => setState(() => _editing = false),
              onSave: () => setState(() => _editing = false),
            )
          : null,
      body: Builder(
        builder: (context) => ListView(
          // No side padding here: each section pads itself, so the tinted
          // band (#17) can run edge to edge.
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + AppSpacing.lg,
            bottom: AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _side(
              HeaderCard(
                accent: palette.primary,
                onEdit: _editing ? null : enterEdit,
                leading: EditableCircle(
                  size: 48,
                  onTap: _editing ? () {} : null,
                  child: TintedIconBadge(
                    icon: AppIcons.bank,
                    tint: palette.primary,
                    size: 48,
                  ),
                ),
                title: InlineTitleField(
                  editing: _editing,
                  controller: _name,
                  onEnterEdit: enterEdit,
                ),
                subtitle: const Text('บัญชีธนาคาร · แชร์กับ 2 คน'),
                footer: MoneyText(
                  12500.75,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            // 1 · no title — label ↔ value rows of every kind.
            ..._section(
              first: true,
              rows: [
                DetailRow(
                  label: 'ประเภท',
                  trailing: StatusPill(label: 'ธนาคาร', tone: Tone.info),
                ),
                DetailRow(
                  label: 'สกุลเงิน',
                  trailing: const Text('THB · ฿'),
                  showChevron: true,
                  onTap: () {},
                ),
                DetailRow(
                  label: 'นับในรายงาน',
                  helper: 'รวมยอดนี้ในแดชบอร์ดและสรุป',
                  trailing: Switch(
                    value: _inReport,
                    onChanged: (v) => setState(() => _inReport = v),
                  ),
                ),
                DetailStacked(
                  label: 'คำอธิบาย',
                  child: InlineField(
                    editing: _editing,
                    controller: _description,
                    onEnterEdit: enterEdit,
                    maxLines: 3,
                  ),
                ),
                DetailStacked(
                  label: 'โน้ต',
                  child: InlineField(
                    editing: _editing,
                    controller: _note,
                    onEnterEdit: enterEdit,
                    hint: 'ยังไม่มีโน้ต',
                    maxLines: 3,
                  ),
                ),
                DetailStacked(
                  label: 'แท็ก',
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: const [
                      StatusPill(label: 'เงินเดือน'),
                      StatusPill(label: 'ค่าใช้จ่ายประจำ'),
                    ],
                  ),
                ),
              ],
            ),

            // 2 · title — money / progress values.
            ..._section(
              title: 'บัตรเครดิต',
              rows: [
                DetailRow(label: 'วงเงิน', trailing: MoneyText(50000)),
                const DetailRow(
                  label: 'วันตัดรอบ',
                  trailing: Text('ทุกวันที่ 25'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: ProgressRow(
                    value: 0.62,
                    label: 'ใช้ไปแล้ว ฿31,000',
                    trailing: '62%',
                  ),
                ),
              ],
            ),

            // 3 · title + trailing action — a list, then an add row.
            ..._section(
              title: 'เลขบัญชี · พร้อมเพย์ · บัตร',
              trailing: AppIconButton(
                icon: AppIcons.share,
                size: 32,
                tooltip: 'แชร์',
                onPressed: () {},
              ),
              rows: [
                DetailRow(
                  leading: const Icon(AppIcons.accountNumber),
                  label: 'กสิกรไทย',
                  helper: '123-4-56789-0',
                  trailing: AppIconButton(
                    icon: AppIcons.copy,
                    size: 32,
                    tooltip: 'คัดลอก',
                    onPressed: () {},
                  ),
                ),
                DetailRow(
                  leading: const Icon(AppIcons.accountNumber),
                  label: 'พร้อมเพย์',
                  helper: '081-234-5678',
                  trailing: AppIconButton(
                    icon: AppIcons.copy,
                    size: 32,
                    tooltip: 'คัดลอก',
                    onPressed: () {},
                  ),
                ),
                if (_editing) DetailAddRow(label: 'เพิ่มเลข', onTap: () {}),
              ],
            ),

            // 4 · title — rows that open things / pick a value.
            ..._section(
              title: 'การแชร์และรายงาน',
              locked: _editing,
              rows: [
                DetailRow(
                  label: 'สมาชิก',
                  helper: '3 คน',
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UserAvatar(displayName: 'ปอนด์', size: 28),
                      SizedBox(width: AppSpacing.xxs),
                      UserAvatar(displayName: 'มิว', size: 28),
                    ],
                  ),
                  showChevron: true,
                  onTap: () {},
                ),
                DetailRow(
                  label: 'นับในรายงานของฉัน',
                  helper: 'ยอดไหนของกระเป๋านี้เข้ารายงานคุณ',
                  trailing: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(AppIcons.dropdown),
                    iconAlignment: IconAlignment.end,
                    label: const Text('ทั้งหมด'),
                  ),
                ),
              ],
            ),

            // 5 · buttons only, as rows (today's "การจัดการ" style).
            ..._section(
              title: 'การจัดการ',
              locked: _editing,
              rows: [
                DetailRow(
                  leading: const Icon(AppIcons.transactions),
                  label: 'ดูรายการทั้งหมด',
                  showChevron: true,
                  onTap: () {},
                ),
                DetailRow(
                  leading: const Icon(AppIcons.reset),
                  label: 'ปรับยอด',
                  helper: 'ตั้งยอดให้ตรงกับธนาคาร',
                  showChevron: true,
                  onTap: () {},
                ),
                DetailRow(
                  leading: const Icon(AppIcons.link),
                  label: 'เชื่อมบัญชีผู้ใช้',
                  helper: 'เชื่อมแล้วกับ mew@example.com',
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('เลิกเชื่อม'),
                  ),
                ),
              ],
            ),

            // 6 · buttons only, as a button grid (the other way to do it).
            ..._section(
              title: 'ทางลัด',
              locked: _editing,
              rows: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'โอนเงิน',
                          icon: AppIcons.transfer,
                          variant: AppButtonVariant.outlined,
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(
                          label: 'จ่ายบิล',
                          icon: AppIcons.expense,
                          variant: AppButtonVariant.outlined,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_editing)
              _side(
                DangerRow(
                  icon: AppIcons.archive,
                  label: 'เก็บกระเป๋านี้ถาวร',
                  onTap: () {},
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                '#16 ${_dividerLabel(_dividers)} · '
                '#17 ${_separatorLabel(_separator)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The page's side inset (what the real pages' ListView pads).
  Widget _side(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: child,
  );

  /// One section: separator (per #17) · title row · rows with hairlines
  /// (per #16). [locked] = an action section dimmed in edit mode.
  List<Widget> _section({
    required List<Widget> rows,
    String? title,
    Widget? trailing,
    bool first = false,
    bool locked = false,
  }) {
    // The picked rules are the kit's SectionCard — show the real thing.
    if (_dividers == _Dividers.between && _separator == _Separator.band) {
      return [
        _side(
          SectionCard(
            first: first,
            title: title,
            trailing: trailing,
            locked: locked,
            children: rows,
          ),
        ),
      ];
    }
    final scheme = Theme.of(context).colorScheme;
    const hairline = RowDivider();
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            // The old SectionCard title: md above, xs below.
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              _separator == _Separator.today ? AppSpacing.md : 0,
              trailing == null ? AppSpacing.lg : AppSpacing.sm,
              AppSpacing.xs,
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
                ?trailing,
              ],
            ),
          ),
        for (final (i, row) in rows.indexed) ...[
          if (i > 0 && _dividers != _Dividers.none) hairline,
          row,
        ],
        if (_dividers == _Dividers.underEvery) hairline,
      ],
    );
    return [
      if (!first) _separatorWidget(),
      _side(LockedInEdit(locked: locked, child: body)),
    ];
  }

  Widget _separatorWidget() {
    final scheme = Theme.of(context).colorScheme;
    return switch (_separator) {
      // Before: pages put lg (16) or md (12) before a section.
      _Separator.today => const SizedBox(height: AppSpacing.lg),
      _Separator.gap => const SizedBox(height: AppSpacing.xxl),
      _Separator.line => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
      ),
      _Separator.band => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Container(
          height: AppSpacing.sm,
          color: scheme.surfaceContainerHighest,
        ),
      ),
    };
  }

  Future<void> _openOptions() => showAppSheet<void>(
    context,
    title: 'ตัวเลือก playground',
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheet) {
        void update(VoidCallback f) {
          setState(f);
          setSheet(() {});
        }

        Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(text, style: Theme.of(sheetContext).textTheme.titleSmall),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading('#16 เส้นคั่นแถว'),
            _side(
              SegmentedButton<_Dividers>(
                showSelectedIcon: false,
                segments: [
                  for (final d in _Dividers.values)
                    ButtonSegment(value: d, label: Text(_dividerLabel(d))),
                ],
                selected: {_dividers},
                onSelectionChanged: (s) => update(() => _dividers = s.first),
              ),
            ),
            heading('#17 ตัวคั่น section'),
            _side(
              SegmentedButton<_Separator>(
                showSelectedIcon: false,
                segments: [
                  for (final s in _Separator.values)
                    ButtonSegment(value: s, label: Text(_separatorLabel(s))),
                ],
                selected: {_separator},
                onSelectionChanged: (s) => update(() => _separator = s.first),
              ),
            ),
            heading('โหมด'),
            _side(
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('ดู')),
                  ButtonSegment(value: true, label: Text('แก้ไข')),
                ],
                selected: {_editing},
                onSelectionChanged: (s) {
                  update(() => _editing = s.first);
                  if (_editing) Navigator.of(sheetContext).pop();
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    ),
  );

  static String _dividerLabel(_Dividers d) => switch (d) {
    _Dividers.between => 'ระหว่าง (ใช้อยู่)',
    _Dividers.underEvery => 'ใต้ทุกแถว',
    _Dividers.none => 'ไม่มี',
  };

  static String _separatorLabel(_Separator s) => switch (s) {
    _Separator.today => 'เดิม',
    _Separator.gap => 'ช่องว่าง',
    _Separator.line => 'เส้น',
    _Separator.band => 'แถบ (ใช้อยู่)',
  };
}
