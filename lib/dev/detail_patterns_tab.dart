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
import '../features/contacts/presentation/widgets/contact_linked_mark.dart';
import '../features/personal_debts/domain/personal_debt.dart';
import '../features/personal_debts/presentation/widgets/debt_widgets.dart';
import '../features/projects/domain/project.dart';
import '../features/projects/presentation/widgets/project_common.dart';
import '../features/tags/domain/tag.dart';
import '../features/tags/presentation/widgets/tag_chip.dart';
import '../features/transactions/domain/transaction_type.dart';
import '../features/transactions/presentation/widgets/draft_form.dart'
    show TxTagStrip;
import '../features/transactions/presentation/widgets/event_pick.dart';
import '../features/transactions/presentation/widgets/splits_section.dart';
import '../features/transactions/presentation/widgets/tx_hero_card.dart';
import '../shared/icon_maker/icon_display.dart';
import '../shared/icon_maker/icon_type.dart';
import '../shared/widgets/type_indicator.dart';
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
        _Part(
          title: '1 · หน้าตัวอย่าง (kit ล้วน)',
          trailing: ChoicePillRow<bool>(
            values: const [false, true],
            selected: _editing,
            label: (v) => v ? 'แก้ไข' : 'ดู',
            onSelected: (v) => setState(() => _editing = v),
          ),
        ),
        _SampleDetail(
          editing: _editing,
          onEnterEdit: () => setState(() => _editing = true),
        ),
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
              LabelPill(
                label: 'ธนาคาร',
                icon: AppIcons.bank,
                color: AccountType.bank.colorOf(context),
                outlined: true,
              ),
              const StatusPill(label: 'ใช้งาน', tone: Tone.success),
            ],
            topActions: [
              if (!editing)
                ActionPill(
                  icon: AppIcons.reset,
                  label: 'ปรับยอด',
                  style: ActionPillStyle.raised,
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
              ? ChipRow(
                  icon: AppIcons.tag,
                  moreLabel: 'เพิ่มเติม',
                  onMore: () {},
                  chips: [
                    for (final t in tagNames)
                      TagChip(
                        tag: Tag(id: t, name: t),
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
                  child: ChipRow(
                    icon: AppIcons.tag,
                    chips: [
                      for (final t in _tags)
                        TagChip(
                          tag: Tag(id: t, name: t),
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
              DetailRow(
                label: 'หมวดแม่',
                trailing: const Text('ท่องเที่ยว'),
                showChevron: editing,
                onTap: editing ? () {} : null,
                onLongPress: enter,
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
                      ActionPill(
                        icon: AppIcons.add,
                        label: 'เพิ่มคน',
                        onTap: () => setState(() => _items.add(('ใหม่', 0))),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      ActionPill(
                        icon: AppIcons.split,
                        label: 'หารเท่ากัน',
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
            SectionCard(
              title: 'การจัดการ',
              dividers: false,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      DangerRow(
                        icon: AppIcons.archive,
                        label: 'เก็บถาวร',
                        caution: true,
                        padding: EdgeInsets.zero,
                        onTap: () {},
                      ),
                      DangerRow(
                        icon: AppIcons.delete,
                        label: 'ลบ',
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
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
                    LabelPill(
                      label: 'ธนาคาร',
                      icon: AppIcons.bank,
                      color: AccountType.bank.colorOf(context),
                      outlined: true,
                    ),
                  ],
                  trailing: [
                    ActionPill(
                      icon: AppIcons.reset,
                      label: 'ปรับยอด',
                      style: ActionPillStyle.raised,
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
            topRow: const [TypeIndicator(isIncome: false)],
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
              children: [ContactLinkedPill()],
            ),
          ),
        ),
        _Variant(
          name: 'debt — HeaderCard + footer (outstanding · progress)',
          usedIn: 'personal_debt_detail_page.dart _header',
          note: 'status as the subtitle (StatusPill); ✏️ in the title row',
          child: HeaderCard(
            onEdit: noop,
            leading: const UserAvatar(displayName: 'ต้น', size: 52),
            title: const Text('ต้น ติดคุณ'),
            subtitle: Align(
              alignment: Alignment.centerLeft,
              child: debtStatusPill(context, DebtStatus.open),
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
              'status (ProjectStatusPill) + plain type text in the subtitle; '
              'planned amount only in edit (footer field)',
          child: HeaderCard(
            onEdit: noop,
            leading: const IconDisplay(type: IconType.project, size: 48),
            title: const Text('ทริปเชียงใหม่'),
            subtitle: const Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ProjectStatusPill(status: ProjectStatus.active),
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
          note: '"completed" is an AppBadge (other heroes use pills)',
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
                  child: AppBadge(
                    label: 'ครบเป้าแล้ว',
                    icon: AppIcons.success,
                    tone: Tone.success,
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
                const StatusPill(label: 'ทำงานอยู่', tone: Tone.success),
                LabelPill(label: 'ประจำ', onTap: null),
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
          name: 'chip — TxTagStrip (view) / ChipRow (edit)',
          usedIn:
              'tx view (🏷 strip right under the hero) · tx edit (🏷 ChipRow '
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
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ChipRow(
                  icon: AppIcons.tag,
                  moreLabel: 'เพิ่มเติม',
                  onMore: noop,
                  chips: const [
                    TagChip(
                      tag: Tag(id: 't', name: 'เที่ยว'),
                      selected: true,
                    ),
                    TagChip(
                      tag: Tag(id: 'u', name: 'งาน'),
                      selected: false,
                    ),
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
          name: 'a person, three looks — PersonMark in a RowChip',
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
              RowChip(
                label: 'ลี (พิมพ์ชื่อ)',
                leading: const PersonMark(name: 'ลี', level: PersonLevel.name),
                onTap: () {},
              ),
              RowChip(
                label: 'บี (ผู้ติดต่อ)',
                leading: const PersonMark(
                  name: 'บี',
                  level: PersonLevel.contact,
                ),
                onTap: () {},
              ),
              const RowChip(
                label: 'ต้น (ลิงก์บัญชีแอป)',
                leading: PersonMark(name: 'ต้น', level: PersonLevel.linked),
                trailingIcon: AppIcons.lock,
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
          name: 'hero top row — type · status · date (PillSize.normal)',
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
          name: 'labels in a header — PillSize.normal',
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
