import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';
import '../core/constants/app_spacing.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../features/accounts/domain/account.dart';
import '../features/accounts/domain/account_identifier.dart';
import '../features/accounts/domain/account_type.dart';
import '../features/accounts/presentation/widgets/account_card.dart';
import '../features/accounts/presentation/widgets/identifier_widgets.dart';
import '../features/tags/domain/tag.dart';
import '../features/transactions/domain/transaction_type.dart';
import '../features/transactions/presentation/widgets/draft_form.dart'
    show TxTagStrip;
import '../features/transactions/presentation/widgets/event_pick.dart';
import '../features/transactions/presentation/widgets/splits_section.dart';
import '../features/transactions/presentation/widgets/tx_hero_card.dart';
import '../shared/icon_maker/icon_display.dart';
import '../shared/icon_maker/icon_type.dart';
import '../shared/widgets/ui.dart';
import 'compact_hero_demo.dart';
import 'app_chip_tab.dart';

/// /dev/widgets → "รายละเอียด" (owner 2026-10-11): THE reference for
/// detail pages. Any new or one-off detail pattern from any FE lands here
/// first for the owner's review, then goes into a page.
///
/// Part 1 — one sample detail page built only from kit pieces, [ดู | แก้ไข].
/// Part 2 — a catalogue of every variant the app has today, side by side,
/// each labelled with the page(s) using it, so divergences show.
class DetailPatternsTab extends StatefulWidget {
  const DetailPatternsTab({super.key});

  @override
  State<DetailPatternsTab> createState() => _DetailPatternsTabState();
}

class _DetailPatternsTabState extends State<DetailPatternsTab> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        bottom: 96 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const _Intro(),
        const _Rules(),
        _Part(
          title: '1 · หน้าตัวอย่าง (kit ล้วน)',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final v in const [false, true]) ...[
                if (v) const SizedBox(width: AppSpacing.xs),
                AppChip(
                  label: v ? 'แก้ไข' : 'ดู',
                  selected: _editing == v,
                  onTap: () => setState(() => _editing = v),
                ),
              ],
            ],
          ),
        ),
        _SampleDetail(
          editing: _editing,
          onEnterEdit: () => setState(() => _editing = true),
        ),
        const _Part(title: '1b · Hero มาตรฐาน (ผู้ติดต่อ · หมวดหมู่ · …)'),
        const _StandardHeroes(),
        const _Part(title: '2 · แคตตาล็อก — ของที่มีในแอปวันนี้'),
        const _HeroCatalogue(),
        const _CompactHeroCatalogue(),
        const _RowCatalogue(),
        const _ListCatalogue(),
        const _TextCatalogue(),
        const _ManageCatalogue(),
        const _MetaCatalogue(),
        const _StateCatalogue(),
        const _ChipCatalogue(),
      ],
    );
  }
}

// ─── Chrome ───────────────────────────────────────────────────────────

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: MessageBanner(
        tone: Tone.info,
        message:
            'ที่เดียวสำหรับดีไซน์หน้ารายละเอียด: pattern ใหม่หรือแบบเฉพาะจาก '
            'FE ไหนก็ตาม ต้องมาลงหน้านี้ก่อนให้เจ้าของดู แล้วค่อยใช้จริง',
      ),
    );
  }
}

/// A part's heading (+ an optional control on the right).
class _Part extends StatelessWidget {
  const _Part({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A catalogue group: a band title, then its variants.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionBand(bleed: 0),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        for (final c in children) ...[c, const SizedBox(height: AppSpacing.lg)],
      ],
    );
  }
}

/// The owner's detail-page standard (2026-10-11) applied to every Part 2
/// variant: "= standard" (the sample already does it) or "→ migrates to X".
/// Looked up by the start of the variant's name; the migration split per
/// page is in the FE-B report (ai/inbox/fe-b.md).
const _verdicts = <String, String>{
  // Hero
  'tx — TxHeroCard': '= standard (the reference hero)',
  'wallet — AccountCardSurface':
      '= standard (the wallet colour is its surface); → amount into the '
      'footer slot like the others',
  'category — HeaderCard': '→ migrates to the rebuilt category hero (Part 1)',
  'contact — HeaderCard':
      '→ migrates to the rebuilt contact hero: ✏️ + status chips in the top row',
  'debt — HeaderCard':
      '→ migrates to: status chip + ✏️ in the top row (not the subtitle)',
  'event — HeaderCard':
      '→ migrates to: status + type chips + ✏️ in the top row',
  'budget — HeaderCard':
      '→ migrates to: period chip + ✏️ in the top row, subtitle = category',
  'goal — HeaderCard':
      '→ migrates to: status AppChip (ครบเป้าแล้ว) + ✏️ in the top row',
  'scheduled — HeaderCard':
      '→ migrates to: status + variant AppChips + ✏️ in the top row',
  // Rows
  'text — DetailRow': '= standard',
  'picker › — DetailRow': '= standard (DetailRow.pick: empty → "ไม่ได้เลือก")',
  'picker card — PickCard': '→ migrates to DetailRow.pick › on detail pages',
  'picker tile — PickerTile':
      '→ migrates to DetailRow ›; PickerTile retires (event resolve sheet · '
      'event member splits, the events round)',
  'switch — DetailRow': '= standard',
  'chip — TxTagStrip': '= standard',
  'identifier — IdentifierRow': '= standard',
  'empty — EventRow': '= standard (every picker keeps its row)',
  'locked — 🔒':
      '→ migrates to a 🔒 leading icon (DetailRow.locked), no dimming',
  // Lists
  'split people': '= standard',
  'a person, three looks': '= standard',
  'a person as an avatar': '= standard',
  'identifiers — SectionCard': '= standard',
  // Text
  'DetailStacked + InlineField — view': '= standard (note always shown)',
  'DetailStacked + InlineField — edit': '= standard',
  'grey label + field': '→ migrates to DetailStacked + InlineField',
  // การจัดการ
  'archive amber + delete red': '= standard',
  'archive + delete, both red': '→ migrates to archive amber, delete red',
  'archive only, red': '→ migrates to archive amber (in การจัดการ)',
  'delete only, red': '= standard (entities with no archive)',
  // Meta
  'DetailMeta — muted': '= standard (every page)',
  'a DetailRow inside': '→ migrates to DetailMeta (not a row)',
  'none': '→ migrates to DetailMeta on every page',
  // States
  'loading — LoadingView': '= standard',
  'error — ErrorView': '= standard (every detail page)',
  'not found — EmptyView': '= standard',
  'long-press hint': '= standard',
  'empty value': '→ migrates to "ไม่ได้เลือก" on every empty picker row',
  // AppChip / compact
  'hero top row — type': '= standard (AppChip, normal 32)',
  'labels in a header': '= standard (AppChip, normal 32)',
  'playground': '= standard',
  'CompactHeroBar': '= standard (planned)',
};

String? _verdictFor(String name) {
  for (final e in _verdicts.entries) {
    if (name.startsWith(e.key)) return e.value;
  }
  return null;
}

/// One variant: what it is, which page(s) use it, what differs — then the
/// widget itself.
class _Variant extends StatelessWidget {
  const _Variant({
    required this.name,
    required this.usedIn,
    required this.child,
    this.note,
    this.padded = true,
  });

  final String name;
  final String usedIn;

  /// Where it diverges from the sample (shown in the warning colour).
  final String? note;
  final Widget child;

  /// False = full width (sections bring their own side padding).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final warn = Theme.of(context).extension<AppColors>()!.warning;
    final side = padded ? AppSpacing.lg : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: textTheme.titleSmall),
              Text(
                usedIn,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontFamily: 'monospace',
                ),
              ),
              if (note != null)
                Text(
                  '≠ $note',
                  style: textTheme.labelSmall?.copyWith(color: warn),
                ),
              if (_verdictFor(name) case final v?)
                Text(
                  v,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: v.startsWith('=')
                        ? Theme.of(context).extension<AppColors>()!.success
                        : Theme.of(context).extension<AppColors>()!.info,
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: side),
          child: child,
        ),
      ],
    );
  }
}

// ─── Part 1: the sample ───────────────────────────────────────────────

/// One detail page from kit pieces only, both modes:
///   hero (chips top row · ✏️ · title / sub · amount) → tag strip →
///   rows (text / picker › / switch) → an editable list (+ pills, ✕) →
///   คำอธิบาย / โน้ต (โน้ต always shown) → การจัดการ (edit only) → meta.
/// View mode: long-press any row / field → edit.
class _SampleDetail extends StatefulWidget {
  const _SampleDetail({required this.editing, required this.onEnterEdit});
  final bool editing;
  final VoidCallback onEnterEdit;

  @override
  State<_SampleDetail> createState() => _SampleDetailState();
}

class _SampleDetailState extends State<_SampleDetail> {
  final _name = TextEditingController(text: 'ทริปเชียงใหม่');
  final _description = TextEditingController(text: 'ค่าที่พัก 3 คืน');
  final _note = TextEditingController();
  bool _inReport = true;
  final Set<String> _tags = {'เที่ยว'};
  final List<(String, double)> _items = [('บี', 1200), ('ต้น', 800)];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing;
    final enter = editing ? null : widget.onEnterEdit;
    final palette = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    const tagNames = ['เที่ยว', 'ครอบครัว', 'งาน'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero: HeaderCard with its top row.
          HeaderCard(
            accent: palette.primary,
            topRow: [
              AppChip(
                label: 'ธนาคาร',
                icon: AppIcons.bank,
                color: AccountType.bank.colorOf(context),
              ),
              const AppChip(
                label: 'ใช้งาน',
                dot: true,
                tone: AppChipTone.success,
                selected: true,
              ),
            ],
            topActions: [
              if (!editing)
                AppChip(
                  icon: AppIcons.reset,
                  label: 'ปรับยอด',
                  tone: AppChipTone.primary,
                  selected: true,
                  onTap: () {},
                ),
            ],
            onEdit: enter,
            leading: EditableCircle(
              size: 52,
              onTap: editing ? () {} : null,
              child: const IconDisplay(type: IconType.category, size: 52),
            ),
            title: InlineTitleField(
              editing: editing,
              controller: _name,
              hint: 'ชื่อ',
              onEnterEdit: enter,
            ),
            subtitle: const Text('ท่องเที่ยว › ที่พัก'),
            footer: MoneyText(
              12450,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.primary,
              ),
            ),
          ),
          // Chip strip under the hero (16 below it).
          const SizedBox(height: HeroSpacing.after),
          editing
              ? _TagStrip(
                  tags: [
                    for (final t in tagNames)
                      AppChip(
                        label: '#$t',
                        icon: AppIcons.tag,
                        selected: _tags.contains(t),
                        onTap: () => setState(
                          () => _tags.contains(t)
                              ? _tags.remove(t)
                              : _tags.add(t),
                        ),
                      ),
                  ],
                )
              : GestureDetector(
                  onLongPress: enter,
                  child: _TagStrip(
                    tags: [
                      for (final t in _tags)
                        AppChip(
                          label: '#$t',
                          icon: AppIcons.tag,
                          size: PillSize.chip,
                          selected: true,
                        ),
                    ],
                  ),
                ),
          const SizedBox(height: HeroSpacing.after),
          // Rows: text · picker › · switch.
          SectionCard(
            first: true,
            children: [
              DetailRow(
                label: 'สกุลเงิน',
                trailing: const Text('THB'),
                onLongPress: enter,
              ),
              // Pickers: DetailRow › only; empty keeps its row (muted).
              DetailRow.pick(
                label: 'หมวดแม่',
                value: 'ท่องเที่ยว',
                emptyText: 'ไม่ได้เลือก',
                onTap: editing ? () {} : null,
                onLongPress: enter,
              ),
              DetailRow.pick(
                label: 'อีเวนต์',
                value: null,
                emptyText: 'ไม่ได้เลือก',
                onTap: editing ? () {} : null,
                onLongPress: enter,
              ),
              // Locked: a 🔒 leading icon, the row not dimmed.
              const DetailRow(
                label: 'ประเภท',
                trailing: Text('ธนาคาร'),
                locked: true,
              ),
              DetailRow(
                label: 'นับในรายงาน',
                helper: 'ปิด = ไม่นับในสรุป',
                trailing: Switch(
                  value: _inReport,
                  onChanged: (v) => setState(() => _inReport = v),
                ),
              ),
            ],
          ),
          // An editable list: + pills in the title row, rows, ✕.
          SectionCard(
            title: 'หารกับ',
            trailing: editing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppChip(
                        icon: AppIcons.add,
                        label: 'เพิ่มคน',
                        tone: AppChipTone.primary,
                        selected: true,
                        onTap: () => setState(() => _items.add(('ใหม่', 0))),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AppChip(
                        icon: AppIcons.split,
                        label: 'หารเท่ากัน',
                        tone: AppChipTone.primary,
                        selected: true,
                        onTap: () {},
                      ),
                    ],
                  )
                : null,
            children: [
              for (final (i, (who, amount)) in _items.indexed)
                DetailRow(
                  leading: UserAvatar(displayName: who, size: 32),
                  label: who,
                  onLongPress: enter,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: MoneyText(amount)),
                      if (editing)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(AppIcons.close),
                          onPressed: () => setState(() => _items.removeAt(i)),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          // Long text: คำอธิบาย, and โน้ต ALWAYS (even empty — owner rule).
          SectionCard(
            children: [
              DetailStacked(
                label: 'คำอธิบาย',
                child: InlineField(
                  editing: editing,
                  controller: _description,
                  maxLines: 3,
                  onEnterEdit: enter,
                ),
              ),
              DetailStacked(
                label: 'โน้ต',
                child: InlineField(
                  editing: editing,
                  controller: _note,
                  maxLines: 5,
                  hint: 'เพิ่มโน้ต…',
                  onEnterEdit: enter,
                ),
              ),
            ],
          ),
          // การจัดการ — edit mode only, last: archive amber, delete red,
          // same shape.
          if (editing)
            ManageSection(
              archiveLabel: 'เก็บถาวร',
              onArchive: () {},
              deleteLabel: 'ลบ',
              onDelete: () {},
            ),
          const DetailMeta(
            lines: [
              'บันทึกโดย มิ้นท์',
              'บันทึกเมื่อ 10 ต.ค. 2026 14:05',
              'แก้ไขล่าสุด 11 ต.ค. 2026 09:12',
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Part 2: the catalogue ────────────────────────────────────────────

/// Every page's hero, as each page builds it today (private page widgets
/// are mirrored from the same kit pieces, file:line in the label).
class _HeroCatalogue extends StatefulWidget {
  const _HeroCatalogue();

  @override
  State<_HeroCatalogue> createState() => _HeroCatalogueState();
}

class _HeroCatalogueState extends State<_HeroCatalogue> {
  final _amount = TextEditingController(text: '1,250');
  final _title = TextEditingController(text: 'ข้าวมันไก่');
  final _name = TextEditingController(text: 'อาหาร');

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _name.dispose();
    super.dispose();
  }

  static const _wallet = Account(
    id: 'w',
    name: 'กสิกร',
    type: AccountType.bank,
    balance: 48200,
    currency: 'THB',
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final big = textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800);
    void noop() {}
    return _Group(
      title: 'Hero',
      children: [
        _Variant(
          name: 'tx — TxHeroCard (inline, view)',
          usedIn: 'transaction_detail_page · quick_create_sheet',
          note: 'own card (not HeaderCard); type chips + date in the top row',
          child: TxHeroCard(
            type: TransactionType.expense,
            amount: _amount,
            title: _title,
            dateLabel: 'วันนี้',
            editing: false,
            inline: true,
            onEdit: noop,
          ),
        ),
        _Variant(
          name: 'wallet — AccountCardSurface + HeroContent',
          usedIn: 'account_detail_page.dart _HeroHeader',
          note:
              'own surface (the wallet card); amount is a row, not a footer; '
              'ปรับยอด in the top row',
          child: AccountCardSurface(
            account: _wallet,
            margin: EdgeInsets.zero,
            glyphSize: 132,
            child: HeroContent(
              rows: [
                HeroTopRow(
                  leading: [
                    AppChip(
                      label: 'ธนาคาร',
                      icon: AppIcons.bank,
                      color: AccountType.bank.colorOf(context),
                    ),
                  ],
                  trailing: [
                    AppChip(
                      icon: AppIcons.reset,
                      label: 'ปรับยอด',
                      tone: AppChipTone.primary,
                      selected: true,
                      onTap: noop,
                    ),
                    AppIconButton(
                      icon: AppIcons.edit,
                      size: HeroSpacing.controlHeight,
                      onPressed: noop,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const AccountIconCircle(account: _wallet, size: 52),
                    const SizedBox(width: AppSpacing.md),
                    Text('กสิกร', style: textTheme.titleMedium),
                  ],
                ),
                MoneyText(48200, style: big),
              ],
            ),
          ),
        ),
        _Variant(
          name: 'category — HeaderCard(topRow)',
          usedIn: 'category_detail_page.dart _Header',
          child: HeaderCard(
            topRow: const [
              AppChip(
                label: 'รายจ่าย',
                icon: AppIcons.expense,
                tone: AppChipTone.expense,
                selected: true,
              ),
            ],
            onEdit: noop,
            leading: const IconDisplay(type: IconType.category, size: 44),
            title: InlineTitleField(editing: false, controller: _name),
            subtitle: const Text('อาหาร › มื้อหลัก'),
          ),
        ),
        _Variant(
          name: 'contact — HeaderCard, ✏️ in the title row',
          usedIn: 'contact_detail_page.dart _header',
          note: 'no top row; status pills as the subtitle',
          child: HeaderCard(
            onEdit: noop,
            leading: const UserAvatar(displayName: 'บี', size: 52),
            title: const Text('บี'),
            subtitle: const Wrap(
              spacing: HeroSpacing.itemGap,
              children: [
                AppChip(
                  label: 'ผูกบัญชีแอป',
                  icon: AppIcons.link,
                  tone: AppChipTone.success,
                  selected: true,
                ),
              ],
            ),
          ),
        ),
        _Variant(
          name: 'debt — HeaderCard + footer (outstanding · progress)',
          usedIn: 'personal_debt_detail_page.dart _header',
          note: 'status as the subtitle (a chip); ✏️ in the title row',
          child: HeaderCard(
            onEdit: noop,
            leading: const UserAvatar(displayName: 'ต้น', size: 52),
            title: const Text('ต้น ติดคุณ'),
            subtitle: Align(
              alignment: Alignment.centerLeft,
              child: const AppChip(
                label: 'ค้างอยู่',
                dot: true,
                tone: AppChipTone.warning,
                selected: true,
              ),
            ),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ค้างอยู่', style: textTheme.labelMedium),
                MoneyText(800, tone: MoneyTone.income, style: big),
                const SizedBox(height: AppSpacing.sm),
                const ProgressRow(value: 0.2, label: 'คืนแล้ว ฿200 จาก ฿1,000'),
              ],
            ),
          ),
        ),
        _Variant(
          name: 'event — HeaderCard, status + type text',
          usedIn: 'project_detail_page.dart _header',
          note:
              'status chip + plain type text in the subtitle; '
              'planned amount only in edit (footer field)',
          child: HeaderCard(
            onEdit: noop,
            leading: const IconDisplay(type: IconType.project, size: 48),
            title: const Text('ทริปเชียงใหม่'),
            subtitle: const Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppChip(
                  label: 'ใช้งาน',
                  dot: true,
                  tone: AppChipTone.success,
                  selected: true,
                ),
                Text('เที่ยว'),
              ],
            ),
          ),
        ),
        _Variant(
          name: 'budget — HeaderCard + footer (spent · progress)',
          usedIn: 'budget_detail_page.dart _header',
          note: 'subtitle = "category · period" text',
          child: HeaderCard(
            accent: palette.expense,
            onEdit: noop,
            leading: const IconDisplay(type: IconType.category, size: 52),
            title: const Text('อาหาร'),
            subtitle: const Text('รายเดือน'),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MoneyText(6200, style: big),
                const SizedBox(height: AppSpacing.sm),
                const ProgressRow(
                  value: 0.62,
                  label: 'จาก ฿10,000',
                  trailing: '62%',
                ),
              ],
            ),
          ),
        ),
        _Variant(
          name: 'goal — HeaderCard + footer (saved · progress · badge)',
          usedIn: 'saving_goal_detail_page.dart _header',
          note: '"completed" is a badge in the footer (other heroes use chips)',
          child: HeaderCard(
            accent: palette.success,
            onEdit: noop,
            leading: const IconDisplay(type: IconType.account, size: 52),
            title: const Text('เที่ยวญี่ปุ่น'),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MoneyText(30000, style: big?.copyWith(color: palette.success)),
                Text('จากเป้า ฿30,000', style: textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                ProgressRow(value: 1, color: palette.success, trailing: '100%'),
                const SizedBox(height: AppSpacing.sm),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AppChip(
                    label: 'ครบเป้าแล้ว',
                    icon: AppIcons.success,
                    tone: AppChipTone.success,
                    selected: true,
                    size: PillSize.chip,
                  ),
                ),
              ],
            ),
          ),
        ),
        _Variant(
          name: 'scheduled — HeaderCard, status + variant pill',
          usedIn: 'scheduled_transaction_detail_page.dart _Header',
          note: 'the variant pill is hand-made (_VariantPill, not kit)',
          child: HeaderCard(
            onEdit: noop,
            leading: const IconDisplay(type: IconType.category, size: 52),
            title: const Text('ค่าเน็ตบ้าน'),
            subtitle: Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const AppChip(
                  label: 'ทำงานอยู่',
                  dot: true,
                  tone: AppChipTone.success,
                  selected: true,
                ),
                const AppChip(label: 'ประจำ', tone: AppChipTone.neutral),
              ],
            ),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyText(599, style: big),
                Text('ครั้งถัดไป 1 พ.ย.', style: textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Row types.
class _RowCatalogue extends StatefulWidget {
  const _RowCatalogue();

  @override
  State<_RowCatalogue> createState() => _RowCatalogueState();
}

class _RowCatalogueState extends State<_RowCatalogue> {
  bool _on = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    void noop() {}
    return _Group(
      title: 'แถว',
      children: [
        _Variant(
          name: 'text — DetailRow(trailing: Text)',
          usedIn: 'every detail page',
          padded: false,
          child: const SectionCard(
            first: true,
            children: [DetailRow(label: 'สกุลเงิน', trailing: Text('THB'))],
          ),
        ),
        _Variant(
          name: 'picker › — DetailRow(showChevron, onTap)',
          usedIn: 'category (หมวดแม่) · contact (อีเมล) · debt (ที่มา)',
          padded: false,
          child: SectionCard(
            first: true,
            children: [
              DetailRow(
                label: 'หมวดแม่',
                trailing: const Text('ท่องเที่ยว'),
                showChevron: true,
                onTap: noop,
              ),
            ],
          ),
        ),
        _Variant(
          name: 'picker card — PickCard',
          usedIn: 'tx form (หมวด · กระเป๋า) · budget (หมวด) · goal (กระเป๋า)',
          note: 'a card, not a row',
          child: PickCard(
            label: 'หมวดหมู่',
            value: 'อาหาร',
            leading: const PickCardEmptyIcon(AppIcons.category),
            onTap: noop,
          ),
        ),
        _Variant(
          name: 'picker tile — PickerTile (older)',
          usedIn: 'event resolve sheet · event member splits',
          note: 'outlined field look — predates DetailRow ›',
          child: PickerTile(
            label: 'กระเป๋า',
            value: 'กสิกร',
            leading: const Icon(AppIcons.bank),
            onTap: noop,
          ),
        ),
        _Variant(
          name: 'switch — DetailRow(trailing: Switch)',
          usedIn: 'category (นับในรายงาน · ค่าธรรมเนียม) · wallet (รายงาน)',
          padded: false,
          child: SectionCard(
            first: true,
            children: [
              DetailRow(
                label: 'นับในรายงาน',
                helper: 'ปิด = ไม่นับในสรุป',
                trailing: Switch(
                  value: _on,
                  onChanged: (v) => setState(() => _on = v),
                ),
              ),
            ],
          ),
        ),
        _Variant(
          name: 'chip — TxTagStrip (view) / chip row (edit)',
          usedIn:
              'tx view (🏷 strip right under the hero) · tx edit (🏷 chip row '
              'under หมวด)',
          note:
              'no "แท็ก" labelled row: both modes are icon-led chips '
              '(owner 2026-10-11)',
          padded: false,
          child: SectionCard(
            first: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: TxTagStrip(
                  tags: [
                    Tag(id: 't', name: 'เที่ยว'),
                    Tag(id: 'u', name: 'งาน'),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: _TagStrip(
                  tags: [
                    AppChip(label: '#เที่ยว', selected: true),
                    AppChip(label: '#งาน'),
                  ],
                ),
              ),
            ],
          ),
        ),
        _Variant(
          name: 'identifier — IdentifierRow',
          usedIn: 'account_detail_page (เลขบัญชี / พร้อมเพย์)',
          padded: false,
          child: SectionCard(
            first: true,
            title: 'เลขที่ใช้รับเงิน',
            trailing: const IdentifiersVisibility(),
            children: [
              IdentifierRow(
                identifier: const AccountIdentifier(
                  kind: IdentifierKind.promptPay,
                  value: '0812345678',
                ),
                providers: const [],
                onDelete: noop,
              ),
            ],
          ),
        ),
        _Variant(
          name: 'empty — EventRow(name: null)',
          usedIn: 'tx detail / quick create (อีเวนต์)',
          note: 'muted "ไม่ได้เลือก"; other pages hide an empty row instead',
          padded: false,
          child: SectionCard(
            first: true,
            children: [EventRow(name: null, onTap: noop)],
          ),
        ),
        _Variant(
          name: 'locked — 🔒 row / LockedInEdit',
          usedIn:
              'tx detail (event of a locked row) · debt (บันทึกเมื่อ, edit)',
          note: 'two looks: a 🔒 leading icon vs. the whole row dimmed',
          padded: false,
          child: SectionCard(
            first: true,
            children: [
              const EventRow(name: 'ทริปเชียงใหม่', locked: true),
              const LockedInEdit(
                locked: true,
                child: DetailRow(
                  label: 'บันทึกเมื่อ',
                  trailing: Text('10 ต.ค. 2026'),
                ),
              ),
              DetailRow(
                label: 'ประเภท',
                trailing: Icon(AppIcons.lock, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Editable lists: + pills in the title row, rows, ✕.
class _ListCatalogue extends StatefulWidget {
  const _ListCatalogue();

  @override
  State<_ListCatalogue> createState() => _ListCatalogueState();
}

class _ListCatalogueState extends State<_ListCatalogue> {
  List<SplitDraft> _drafts = [
    SplitDraft(personName: 'ลี', owedAmount: 300),
    SplitDraft(personName: 'บี', contactId: 'demo-contact', owedAmount: 300),
    SplitDraft(
      debtId: 'demo-debt',
      personName: 'ต้น',
      contactId: 'demo-linked',
      owedAmount: 200,
    ),
  ];
  double? _typedMe;
  bool _auto = true;

  /// As the form's controller: on auto, ฉัน is what's left (never < 0).
  double get _me {
    if (!_auto) return _typedMe ?? 0;
    final left = splitLeft(1250, 0, _drafts);
    return left < 0 ? 0 : left;
  }

  @override
  Widget build(BuildContext context) {
    return _Group(
      title: 'รายการแก้ไขได้',
      children: [
        _Variant(
          name: 'split people — SplitsSection(sectioned, ฉัน)',
          usedIn: 'tx detail (edit) · quick create',
          note:
              'ฉัน heads the list with "อัตโนมัติ" (on = ฉัน is what is left, '
              'live; typing ฉัน turns it off, the chip back on); the line '
              'under it must reach "แบ่งครบแล้ว" to save; หารเท่ากัน counts me '
              'in (the remainder is mine). Demo people are not real contacts, '
              'so the chips here show the plain-contact look — the three '
              'looks are below',
          padded: false,
          child: SplitsSection(
            label: 'หารกับ',
            totalAmount: 1250,
            drafts: _drafts,
            sectioned: true,
            me: _me,
            onMeChanged: (v) => setState(() {
              _typedMe = v;
              _auto = false;
            }),
            meAuto: _auto,
            onMeAutoChanged: (on) => setState(() {
              if (!on) _typedMe = _me;
              _auto = on;
            }),
            onChanged: (d) => setState(() => _drafts = d),
          ),
        ),
        _Variant(
          name: 'a person, three looks — PersonMark in an AppChip',
          usedIn:
              'splits (now) · debts · contact picker rows (same look asked '
              'for there)',
          note:
              'only the 3rd locks a SAVED row (🔒, remove + add); the 1st '
              'and 2nd can change who in place',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChip(
                label: 'ลี (พิมพ์ชื่อ)',
                leading: const PersonMark(name: 'ลี', level: PersonLevel.name),
                onTap: () {},
              ),
              AppChip(
                label: 'บี (ผู้ติดต่อ)',
                leading: const PersonMark(
                  name: 'บี',
                  level: PersonLevel.contact,
                ),
                onTap: () {},
              ),
              const AppChip(
                label: 'ต้น (ลิงก์บัญชีแอป)',
                leading: PersonMark(name: 'ต้น', level: PersonLevel.linked),
                trailing: AppChipTrailing.lock,
              ),
            ],
          ),
        ),
        const _Variant(
          name:
              'a person as an avatar — PersonMark · PersonLinkBadge (fixed '
              '16)',
          usedIn:
              'contacts list (40) · contact picker (36, 👤 for a typed name) · '
              'contact header (52)',
          note:
              'one 🔗, right after the avatar, the same size at every avatar '
              'size; no trailing 🔗 on rows. In a list, reserveLinkSlot keeps '
              'the 🔗 space on unlinked rows so every name starts at the same x '
              '(chips: off)',
          padded: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListRow(
                leading: PersonMark(
                  name: 'มาตาก',
                  level: PersonLevel.linked,
                  size: 40,
                  reserveLinkSlot: true,
                ),
                title: 'มาตาก',
                subtitle: 'ลิงก์บัญชีแอป',
              ),
              RowDivider(),
              ListRow(
                leading: PersonMark(
                  name: 'บี',
                  level: PersonLevel.contact,
                  size: 40,
                  reserveLinkSlot: true,
                ),
                title: 'บี',
                subtitle: 'ผู้ติดต่อ — ช่อง 🔗 ว่างไว้',
              ),
              RowDivider(),
              ListRow(
                leading: PersonMark(
                  name: 'ลี',
                  level: PersonLevel.name,
                  size: 40,
                  reserveLinkSlot: true,
                ),
                title: 'ลี',
                subtitle: 'พิมพ์ชื่อ',
              ),
            ],
          ),
        ),
        _Variant(
          name: 'identifiers — SectionCard + IdentifierRow ✕ + AddTile',
          usedIn: 'account_detail_page (edit)',
          note: 'add is an AddTile under the rows, not a pill in the title',
          padded: false,
          child: SectionCard(
            first: true,
            title: 'เลขที่ใช้รับเงิน',
            children: [
              IdentifierRow(
                identifier: const AccountIdentifier(
                  kind: IdentifierKind.bankAccount,
                  value: '1234567890',
                ),
                providers: const [],
                onTap: () {},
                onDelete: () {},
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AddTile(
                  label: 'เพิ่มเลข',
                  variant: AddTileVariant.row,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Long text: description / note.
class _TextCatalogue extends StatefulWidget {
  const _TextCatalogue();

  @override
  State<_TextCatalogue> createState() => _TextCatalogueState();
}

class _TextCatalogueState extends State<_TextCatalogue> {
  final _filled = TextEditingController(text: 'มื้อเที่ยงกับทีม');
  final _empty = TextEditingController();

  @override
  void dispose() {
    _filled.dispose();
    _empty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Group(
      title: 'ข้อความยาว',
      children: [
        _Variant(
          name: 'DetailStacked + InlineField — view (filled / empty)',
          usedIn:
              'category · contact · debt · event · budget · goal · wallet · tx',
          note:
              'empty note: shown on category/contact/tx, hidden when empty on '
              'event / wallet (non-owner) — owner rule: ALWAYS show',
          padded: false,
          child: SectionCard(
            first: true,
            children: [
              DetailStacked(
                label: 'คำอธิบาย',
                child: InlineField(
                  editing: false,
                  controller: _filled,
                  onEnterEdit: () {},
                ),
              ),
              DetailStacked(
                label: 'โน้ต',
                child: InlineField(
                  editing: false,
                  controller: _empty,
                  onEnterEdit: () {},
                ),
              ),
            ],
          ),
        ),
        _Variant(
          name: 'DetailStacked + InlineField — edit',
          usedIn: 'same pages, edit mode',
          padded: false,
          child: SectionCard(
            first: true,
            children: [
              DetailStacked(
                label: 'โน้ต',
                child: InlineField(
                  editing: true,
                  controller: _filled,
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ),
        _Variant(
          name: 'grey label + field (no section)',
          usedIn: 'event form (_EventForm โน้ต) · non-sectioned DraftForm',
          note: 'labelLarge grey label, not the bold detail label',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'โน้ต',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              InlineField(editing: true, controller: _empty, maxLines: 3),
            ],
          ),
        ),
      ],
    );
  }
}

/// การจัดการ: archive / delete at the bottom, edit mode.
class _ManageCatalogue extends StatelessWidget {
  const _ManageCatalogue();

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return _Group(
      title: 'การจัดการ (archive / delete)',
      children: [
        _Variant(
          name: 'archive amber + delete red (the sample)',
          usedIn: '— proposed (none yet)',
          child: Column(
            children: [
              DangerRow(
                icon: AppIcons.archive,
                label: 'เก็บถาวร',
                caution: true,
                padding: EdgeInsets.zero,
                onTap: noop,
              ),
              DangerRow(
                icon: AppIcons.delete,
                label: 'ลบ',
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                onTap: noop,
              ),
            ],
          ),
        ),
        _Variant(
          name: 'archive + delete, both red',
          usedIn: 'budget_detail_page · saving_goal_detail_page',
          note: 'archive is red too — reads as destructive',
          child: Column(
            children: [
              DangerRow(
                icon: AppIcons.archive,
                label: 'เก็บถาวร',
                padding: EdgeInsets.zero,
                onTap: noop,
              ),
              DangerRow(
                icon: AppIcons.delete,
                label: 'ลบ',
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                onTap: noop,
              ),
            ],
          ),
        ),
        _Variant(
          name: 'archive only, red',
          usedIn: 'account_detail_page (wallet) · contact (in the menu)',
          child: DangerRow(
            icon: AppIcons.archive,
            label: 'เก็บกระเป๋านี้ถาวร',
            padding: EdgeInsets.zero,
            onTap: noop,
          ),
        ),
        _Variant(
          name: 'delete only, red',
          usedIn: 'category · event · contact · scheduled · debt',
          child: DangerRow(
            icon: AppIcons.delete,
            label: 'ลบ',
            padding: EdgeInsets.zero,
            onTap: noop,
          ),
        ),
      ],
    );
  }
}

/// Record info at the bottom.
class _MetaCatalogue extends StatelessWidget {
  const _MetaCatalogue();

  @override
  Widget build(BuildContext context) {
    return const _Group(
      title: 'ข้อมูลการบันทึก',
      children: [
        _Variant(
          name: 'DetailMeta — muted lines at the very bottom',
          usedIn: 'transaction_detail_page',
          child: DetailMeta(
            lines: [
              'บันทึกโดย มิ้นท์',
              'บันทึกเมื่อ 10 ต.ค. 2026 14:05',
              'แก้ไขล่าสุด 11 ต.ค. 2026 09:12',
            ],
          ),
        ),
        _Variant(
          name: 'a DetailRow inside the last section',
          usedIn: 'personal_debt_detail_page (บันทึกเมื่อ)',
          note: 'a row, not the footer',
          padded: false,
          child: SectionCard(
            first: true,
            children: [
              DetailRow(label: 'บันทึกเมื่อ', trailing: Text('10 ต.ค. 2026')),
            ],
          ),
        ),
        _Variant(
          name: 'none',
          usedIn:
              'category · contact · wallet · event · budget · goal · scheduled',
          child: SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Page states.
class _StateCatalogue extends StatelessWidget {
  const _StateCatalogue();

  @override
  Widget build(BuildContext context) {
    return _Group(
      title: 'สถานะ',
      children: [
        const _Variant(
          name: 'loading — LoadingView',
          usedIn: 'every detail page (first load)',
          child: SizedBox(height: 120, child: LoadingView()),
        ),
        _Variant(
          name: 'error — ErrorView(+ retry)',
          usedIn: 'contact · debt · event · budget · scheduled',
          child: SizedBox(
            height: 260,
            child: ErrorView(
              error: const ApiException(
                code: 'NETWORK_ERROR',
                message: 'offline',
              ),
              onRetry: () {},
            ),
          ),
        ),
        const _Variant(
          name: 'not found — EmptyView',
          usedIn: 'contact · budget · goal · scheduled · category',
          child: SizedBox(
            height: 220,
            child: EmptyView(
              icon: AppIcons.empty,
              title: 'ไม่พบรายการนี้',
              message: 'อาจถูกลบไปแล้ว',
            ),
          ),
        ),
        _Variant(
          name: 'long-press hint — an empty InlineField in view',
          usedIn: 'every DetailStacked field',
          padded: false,
          child: SectionCard(
            first: true,
            children: [
              DetailStacked(
                label: 'คำอธิบาย',
                child: InlineField(
                  editing: false,
                  controller: TextEditingController(),
                  onEnterEdit: () {},
                ),
              ),
            ],
          ),
        ),
        _Variant(
          name: 'empty value — a picker row with nothing set',
          usedIn: 'tx (อีเวนต์) shows "ไม่ได้เลือก"; others hide the row',
          padded: false,
          child: SectionCard(
            first: true,
            children: [
              EventRow(name: null, onTap: () {}),
              const DetailRow(label: 'หมวดแม่', trailing: Text('ไม่มี')),
            ],
          ),
        ),
      ],
    );
  }
}

/// AppChip (owner 2026-10-11, step 1 — for review, nothing migrated): the
/// one chip as it would sit on a detail page. Full comparison: the AppChip
/// tab.
class _ChipCatalogue extends StatelessWidget {
  const _ChipCatalogue();

  @override
  Widget build(BuildContext context) {
    return const _Group(
      title: 'AppChip (ทดลอง)',
      children: [
        _Variant(
          name: 'hero top row — type · status · date (PillSize.control)',
          usedIn: 'tx · wallet · event heroes, once migrated',
          child: Wrap(
            spacing: HeroSpacing.itemGap,
            runSpacing: HeroSpacing.itemGap,
            children: [
              AppChip(
                label: 'รายจ่าย',
                icon: AppIcons.expense,
                tone: AppChipTone.expense,
                selected: true,
                trailing: AppChipTrailing.lock,
              ),
              AppChip(
                label: 'ใช้งาน',
                dot: true,
                tone: AppChipTone.success,
                selected: true,
                trailing: AppChipTrailing.dropdown,
                onTap: _noop,
              ),
              AppChip(label: 'วันนี้', icon: AppIcons.date, onTap: _noop),
            ],
          ),
        ),
        _Variant(
          name: 'labels in a header — PillSize.control',
          usedIn: 'contact · scheduled · wallet headers, once migrated',
          child: Wrap(
            spacing: HeroSpacing.itemGap,
            runSpacing: HeroSpacing.itemGap,
            children: [
              AppChip(label: 'ผูกแล้ว', icon: AppIcons.link, selected: true),
              AppChip(
                label: 'ผ่อนชำระ',
                tone: AppChipTone.neutral,
                selected: true,
              ),
              AppChip(
                label: 'สินทรัพย์',
                tone: AppChipTone.walletAsset,
                selected: true,
              ),
              AppChip(
                label: 'หนี้สิน',
                tone: AppChipTone.walletLiability,
                selected: true,
              ),
            ],
          ),
        ),
        _Variant(
          name: 'playground — every option',
          usedIn: 'gallery → AppChip tab has old vs new per variant',
          padded: false,
          child: AppChipPlayground(),
        ),
      ],
    );
  }
}

void _noop() {}

/// The hero in one row, under the top bar once the hero scrolls away
/// ([CompactHeroBar] + [CompactHeroScope]). Proposed: no page uses it yet.
class _CompactHeroCatalogue extends StatelessWidget {
  const _CompactHeroCatalogue();

  @override
  Widget build(BuildContext context) {
    return const _Group(
      title: 'Hero ย่อ (ใต้ top bar)',
      children: [
        _Variant(
          name: 'CompactHeroBar — presets: tx · wallet · liability wallet',
          usedIn: '— proposed (tx detail · wallet detail, not wired yet)',
          note: 'detail pages only, never quick create',
          child: CompactHeroDemo(),
        ),
      ],
    );
  }
}

// ─── The standard: rules + heroes ─────────────────────────────────────

/// The owner's 10 detail-page rules (2026-10-11), above the sample.
class _Rules extends StatelessWidget {
  const _Rules();

  static const rules = [
    '✏️ อยู่ใน top row ของ hero เสมอ ด้านขวา — ถ้า top row ไม่มี chip เลย '
        'แถวนั้นยุบ: ไอคอน + ชื่ออยู่บนสุด ✏️ อยู่ขวาสุดระดับเดียวกับชื่อ',
    'สถานะ = chip ใน top row ไม่ใช่ subtitle',
    'Hero ตาม hero ของ tx: top row + ไอคอน/avatar + ชื่อ/subtitle '
        '(+ ยอด/footer ถ้ามี) ที่เหลือเป็นแถวข้างล่าง ขอบสีของ entity',
    'ห้ามทำ chip เอง — ใช้ AppChip',
    'การจัดการ (โหมดแก้ไข ท้ายสุด): เก็บถาวร = เหลือง, ลบ = แดง รูปทรงเดียวกัน; '
        'เก็บถาวรเฉพาะที่มี archive',
    'ข้อมูลการบันทึก = DetailMeta ข้อความจางท้ายสุดทุกหน้า (ไม่ใช่แถว)',
    'โน้ตแสดงเสมอ แม้ว่าง',
    'ตัวเลือกในหน้ารายละเอียด = DetailRow › เท่านั้น (ไม่ใช้ PickerTile / PickCard)',
    'ค่าที่ยังไม่เลือก: คงแถวไว้ แสดง "ไม่ได้เลือก" สีจาง ไม่ซ่อน',
    'ล็อก = ไอคอน 🔒 นำหน้า (ไม่ทำแถวจาง)',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'มาตรฐานหน้ารายละเอียด — 10 ข้อ',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final (i, r) in rules.indexed)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('${i + 1}. $r', style: textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Part 1b — the hero as the standard has it, for the entities the owner
/// asked to see rebuilt (contact, category) next to tx and wallet, plus the
/// two that had hand-made chips (scheduled, goal) now with [AppChip].
/// ✏️ + status chips in the top row, icon / avatar + title / subtitle,
/// amount / footer where the entity has one, border in the entity's colour.
class _StandardHeroes extends StatefulWidget {
  const _StandardHeroes();

  @override
  State<_StandardHeroes> createState() => _StandardHeroesState();
}

class _StandardHeroesState extends State<_StandardHeroes> {
  final _amount = TextEditingController(text: '1,250');
  final _title = TextEditingController(text: 'ข้าวมันไก่');

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    super.dispose();
  }

  static const _wallet = Account(
    id: 'w',
    name: 'กสิกร',
    type: AccountType.bank,
    balance: 48200,
    currency: 'THB',
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final big = textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800);
    void noop() {}
    return _Group(
      title: 'Hero มาตรฐาน',
      children: [
        _Variant(
          name: 'tx — TxHeroCard (the reference)',
          usedIn: 'transaction_detail_page',
          child: TxHeroCard(
            type: TransactionType.expense,
            amount: _amount,
            title: _title,
            dateLabel: 'วันนี้',
            editing: false,
            inline: true,
            onEdit: noop,
          ),
        ),
        _Variant(
          name: 'wallet — wallet card surface + top row',
          usedIn: 'account_detail_page',
          child: AccountCardSurface(
            account: _wallet,
            margin: EdgeInsets.zero,
            glyphSize: 132,
            child: HeroContent(
              rows: [
                HeroTopRow(
                  leading: [
                    AppChip(
                      label: 'ธนาคาร',
                      icon: AppIcons.bank,
                      color: AccountType.bank.colorOf(context),
                    ),
                    const AppChip(
                      label: 'ใช้งาน',
                      dot: true,
                      tone: AppChipTone.success,
                      selected: true,
                    ),
                  ],
                  trailing: [
                    AppChip(
                      icon: AppIcons.reset,
                      label: 'ปรับยอด',
                      tone: AppChipTone.primary,
                      selected: true,
                      onTap: noop,
                    ),
                    AppIconButton(
                      icon: AppIcons.edit,
                      size: HeroSpacing.controlHeight,
                      onPressed: noop,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const AccountIconCircle(account: _wallet, size: 52),
                    const SizedBox(width: AppSpacing.md),
                    Text('กสิกร', style: textTheme.titleMedium),
                  ],
                ),
                MoneyText(48200, style: big),
              ],
            ),
          ),
        ),
        _Variant(
          name: 'contact — rebuilt (✏️ + status chips in the top row)',
          usedIn: 'contact_detail_page (migrates)',
          note: 'was: no top row, ✏️ in the title row, status pill as subtitle',
          child: HeaderCard(
            accent: palette.primary,
            topRow: const [
              AppChip(
                label: 'ผูกบัญชีแอป',
                icon: AppIcons.link,
                tone: AppChipTone.success,
                selected: true,
              ),
            ],
            onEdit: noop,
            leading: const UserAvatar(displayName: 'บี', size: 52),
            title: const Text('บี'),
            subtitle: const Text('ผู้ติดต่อ'),
          ),
        ),
        _Variant(
          name: 'no chips — the top row collapses (contact, unlinked)',
          usedIn: 'contact_detail_page (unlinked) · any hero with no status',
          note:
              'icon + title at the top, ✏️ level with the title; with chips '
              'the top row stays as in the heroes above',
          child: HeaderCard(
            accent: palette.primary,
            topRow: const [],
            onEdit: noop,
            leading: const UserAvatar(displayName: 'ลี', size: 52),
            title: const Text('ลี'),
            subtitle: const Text('ผู้ติดต่อ'),
          ),
        ),
        _Variant(
          name: 'category — rebuilt (type chip + ✏️ in the top row)',
          usedIn: 'category_detail_page (migrates)',
          note:
              "border = the category type's colour (expense here); the "
              'parent path is the subtitle',
          child: HeaderCard(
            accent: palette.expense,
            topRow: const [
              AppChip(
                label: 'รายจ่าย',
                icon: AppIcons.expense,
                tone: AppChipTone.expense,
                selected: true,
              ),
            ],
            onEdit: noop,
            leading: const IconDisplay(type: IconType.category, size: 52),
            title: const Text('อาหาร'),
            subtitle: const Text('อาหาร › มื้อหลัก'),
          ),
        ),
        _Variant(
          name: 'scheduled — status + variant as AppChip',
          usedIn: 'scheduled_transaction_detail_page (migrates)',
          note: 'was: a hand-made _VariantPill and the status as the subtitle',
          child: HeaderCard(
            accent: palette.primary,
            topRow: const [
              AppChip(
                label: 'ทำงานอยู่',
                dot: true,
                tone: AppChipTone.success,
                selected: true,
              ),
              AppChip(
                label: 'ประจำ',
                tone: AppChipTone.neutral,
                selected: true,
              ),
            ],
            onEdit: noop,
            leading: const IconDisplay(type: IconType.category, size: 52),
            title: const Text('ค่าเน็ตบ้าน'),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyText(599, style: big),
                Text('ครั้งถัดไป 1 พ.ย.', style: textTheme.bodySmall),
              ],
            ),
          ),
        ),
        _Variant(
          name: 'goal — "ครบเป้าแล้ว" as an AppChip in the top row',
          usedIn: 'saving_goal_detail_page (migrates)',
          note: 'was: a badge inside the footer',
          child: HeaderCard(
            accent: palette.success,
            topRow: const [
              AppChip(
                label: 'ครบเป้าแล้ว',
                icon: AppIcons.success,
                tone: AppChipTone.success,
                selected: true,
              ),
            ],
            onEdit: noop,
            leading: const IconDisplay(type: IconType.account, size: 52),
            title: const Text('เที่ยวญี่ปุ่น'),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MoneyText(30000, style: big?.copyWith(color: palette.success)),
                Text('จากเป้า ฿30,000', style: textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                ProgressRow(value: 1, color: palette.success, trailing: '100%'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 🏷 + a wrapping row of tag [AppChip]s (the gallery's stand-in for the tag
/// strip / chip row, built from AppChip directly).
class _TagStrip extends StatelessWidget {
  const _TagStrip({required this.tags});

  final List<Widget> tags;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Icon(
            AppIcons.tag,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: tags,
          ),
        ),
      ],
    );
  }
}
