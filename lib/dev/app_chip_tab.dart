import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_icons.dart';
import '../core/constants/app_spacing.dart';
import '../core/theme/app_colors.dart';
import '../features/categories/domain/category_tree.dart';
import '../features/categories/presentation/cubit/categories_cubit.dart';
import '../features/categories/presentation/widgets/category_chip.dart';
import '../features/contacts/presentation/widgets/contact_linked_mark.dart';
import '../features/projects/domain/project.dart';
import '../features/projects/presentation/widgets/project_common.dart';
import '../features/tags/domain/tag.dart';
import '../features/tags/presentation/widgets/tag_chip.dart';
import '../features/transactions/domain/transaction_type.dart';
import '../features/transactions/presentation/widgets/tx_hero_card.dart';
import '../shared/icon_maker/icon_registry.dart';
import '../shared/widgets/type_indicator.dart';
import '../shared/widgets/ui.dart';

/// /dev/widgets → "AppChip" (owner 2026-10-11, step 1): every chip the app
/// has today on the left, the same thing as an [AppChip] on the right — so
/// the owner can judge one chip for all before anything migrates. Then a
/// playground with every [AppChip] option.
class AppChipTab extends StatelessWidget {
  const AppChipTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        bottom: 96 + MediaQuery.paddingOf(context).bottom,
      ),
      children: const [
        _Heading('เทียบ: เดิม (ซ้าย) · AppChip (ขวา)'),
        _ColumnTitles(),
        _KitRows(),
        _FeatureRows(),
        _MaterialRows(),
        _Heading('Playground'),
        AppChipPlayground(),
      ],
    );
  }
}

// ─── Chrome ───────────────────────────────────────────────────────────

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.lg,
      AppSpacing.sm,
    ),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _ColumnTitles extends StatelessWidget {
  const _ColumnTitles();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(child: Text('เดิม', style: style)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text('AppChip', style: style)),
        ],
      ),
    );
  }
}

/// One variant: its name + where it's used, then old | AppChip.
class _Compare extends StatelessWidget {
  const _Compare({
    required this.name,
    required this.usedIn,
    required this.old,
    required this.chip,
  });

  final String name;
  final String usedIn;
  final List<Widget> old;
  final List<Widget> chip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    Widget side(List<Widget> items) => Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RowDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                name,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                usedIn,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: side(old)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: side(chip)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _noop() {}

// ─── Kit chips ────────────────────────────────────────────────────────

class _KitRows extends StatelessWidget {
  const _KitRows();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return Column(
      children: [
        _Compare(
          name: 'RowChip',
          usedIn: 'ตัวกรอง · ฟอร์มรายการ (หมวด / แท็ก / กระเป๋า)',
          old: [
            const RowChip(label: 'ทั้งหมด', selected: true, onTap: _noop),
            RowChip(
              label: 'อาหาร',
              icon: AppIcons.category,
              color: palette.expense,
              onTap: _noop,
            ),
          ],
          chip: [
            const AppChip(label: 'ทั้งหมด', selected: true, onTap: _noop),
            AppChip(
              label: 'อาหาร',
              icon: AppIcons.category,
              color: palette.expense,
              onTap: _noop,
            ),
          ],
        ),
        const _Compare(
          name: 'ChoicePill',
          usedIn: 'ช่วงเวลา · เรียงตาม (ตัวกรอง) · ดู / แก้ไข',
          old: [
            ChoicePill(label: 'เดือน', selected: true, onTap: _noop),
            ChoicePill(label: 'สัปดาห์', selected: false, onTap: _noop),
          ],
          chip: [
            AppChip(label: 'เดือน', selected: true, onTap: _noop),
            AppChip(label: 'สัปดาห์', onTap: _noop),
          ],
        ),
        const _Compare(
          name: 'FilterDropdownChip',
          usedIn: 'แถบตัวกรอง (ผู้ติดต่อ · อีเวนต์ · …)',
          old: [
            FilterDropdownChip(label: 'กระเป๋า', onTap: _noop),
            FilterDropdownChip(
              label: 'สถานะ',
              valueLabel: 'ใช้งาน',
              onTap: _noop,
            ),
            FilterDropdownChip(label: 'สี', count: 2, onTap: _noop),
          ],
          chip: [
            AppChip(
              label: 'กระเป๋า',
              trailing: AppChipTrailing.dropdown,
              onTap: _noop,
            ),
            AppChip(
              label: 'สถานะ: ใช้งาน',
              selected: true,
              trailing: AppChipTrailing.dropdown,
              onTap: _noop,
            ),
            AppChip(
              label: 'สี',
              selected: true,
              trailing: AppChipTrailing.count,
              count: 2,
              onTap: _noop,
            ),
          ],
        ),
        _Compare(
          name: 'SortChip',
          usedIn: 'แถบตัวกรอง (ขวาสุด)',
          old: [
            SortChip<int>(
              options: const [SortOption(0, 'ชื่อ')],
              selected: 0,
              onSelected: (_) {},
            ),
          ],
          chip: const [
            AppChip(
              label: 'ชื่อ',
              icon: AppIcons.sort,
              trailing: AppChipTrailing.dropdown,
              onTap: _noop,
            ),
          ],
        ),
        const _Compare(
          name: 'LabelPill',
          usedIn: 'ประเภทกระเป๋า · ป้ายใน hero',
          old: [
            LabelPill(label: 'ธนาคาร', icon: AppIcons.bank),
            LabelPill(label: 'ผ่อน', tone: Tone.warning),
          ],
          chip: [
            AppChip(
              label: 'ธนาคาร',
              icon: AppIcons.bank,
              tone: AppChipTone.neutral,
              selected: true,
            ),
            AppChip(label: 'ผ่อน', tone: AppChipTone.warning, selected: true),
          ],
        ),
        const _Compare(
          name: 'StatusPill (● dot)',
          usedIn: 'สถานะทุกหน้า · แตะได้ = เปิดตัวเลือก ⌄',
          old: [
            StatusPill(label: 'ใช้งาน', tone: Tone.success),
            StatusPill(label: 'ค้างอยู่', tone: Tone.warning, onTap: _noop),
          ],
          chip: [
            AppChip(
              label: 'ใช้งาน',
              dot: true,
              tone: AppChipTone.success,
              selected: true,
            ),
            AppChip(
              label: 'ค้างอยู่',
              dot: true,
              tone: AppChipTone.warning,
              selected: true,
              trailing: AppChipTrailing.dropdown,
              onTap: _noop,
            ),
          ],
        ),
        const _Compare(
          name: 'ActionPill',
          usedIn: 'แถบเลือก · ปรับยอด (hero กระเป๋า)',
          old: [
            ActionPill(label: 'ปรับยอด', icon: AppIcons.edit, onTap: _noop),
            ActionPill(
              label: 'ลบ',
              icon: AppIcons.delete,
              destructive: true,
              onTap: _noop,
            ),
          ],
          chip: [
            AppChip(
              label: 'ปรับยอด',
              icon: AppIcons.edit,
              selected: true,
              onTap: _noop,
            ),
            AppChip(
              label: 'ลบ',
              icon: AppIcons.delete,
              tone: AppChipTone.danger,
              selected: true,
              onTap: _noop,
            ),
          ],
        ),
        _Compare(
          name: 'TagPill (mini)',
          usedIn: 'แท็กบนแถวรายการ (ทดลอง)',
          old: [
            TagPill(name: 'เที่ยว', color: palette.info, glyph: AppIcons.tag),
          ],
          chip: [
            AppChip(
              label: '#เที่ยว',
              icon: AppIcons.tag,
              color: palette.info,
              selected: true,
              size: PillSize.mini,
            ),
          ],
        ),
        const _Compare(
          name: 'TypeIndicator',
          usedIn: 'ประเภทหมวด · งบ',
          old: [TypeIndicator(isIncome: false), TypeIndicator(isIncome: true)],
          chip: [
            AppChip(
              label: 'รายจ่าย',
              icon: AppIcons.expense,
              tone: AppChipTone.expense,
              selected: true,
            ),
            AppChip(
              label: 'รายรับ',
              icon: AppIcons.income,
              tone: AppChipTone.income,
              selected: true,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Feature chips ────────────────────────────────────────────────────

class _FeatureRows extends StatelessWidget {
  const _FeatureRows();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final categories = context.watch<CategoriesCubit>().state.categories;
    final category = categories
        .where((c) => !c.isSystem && c.parentId == null)
        .firstOrNull;
    final categoryCode = category == null
        ? null
        : CategoryTree.resolveIconCode(category, categories);
    const tag = Tag(id: 'demo', name: 'เที่ยว');
    final tagTint = tagColor(tag.iconCode, palette);
    return Column(
      children: [
        _Compare(
          name: 'TxTypeChip (🔒)',
          usedIn: 'hero รายการ · ตัวกรองประเภท',
          old: const [
            TxTypeChip(
              type: TransactionType.expense,
              selected: true,
              onTap: _noop,
            ),
            TxTypeChip(type: TransactionType.income, selected: false),
            TxTypeChip(
              type: TransactionType.transfer,
              selected: true,
              locked: true,
            ),
          ],
          chip: const [
            AppChip(
              label: 'รายจ่าย',
              icon: AppIcons.expense,
              tone: AppChipTone.expense,
              selected: true,
              onTap: _noop,
            ),
            AppChip(
              label: 'รายรับ',
              icon: AppIcons.income,
              tone: AppChipTone.income,
              onTap: _noop,
            ),
            AppChip(
              label: 'โอนเงิน',
              icon: AppIcons.transfer,
              tone: AppChipTone.transfer,
              selected: true,
              trailing: AppChipTrailing.lock,
              tooltip: 'เปลี่ยนประเภทหลังบันทึกไม่ได้',
            ),
          ],
        ),
        _Compare(
          name: 'hero _DatePill (สำเนา)',
          usedIn: 'hero รายการ — มุมขวาบน',
          old: [_OldDatePill(scheme: scheme)],
          chip: const [
            AppChip(label: 'วันนี้', icon: AppIcons.date, onTap: _noop),
          ],
        ),
        _Compare(
          name: 'CategoryChip',
          usedIn: 'ฟอร์มสร้างเร็ว — หมวดล่าสุด',
          old: [
            if (category == null)
              const Text('— ยังไม่มีหมวด (โหลดหมวดก่อน) —')
            else ...[
              CategoryChip(category: category, selected: true, onTap: _noop),
              CategoryChip(category: category, onTap: _noop),
            ],
          ],
          chip: [
            if (category != null) ...[
              for (final on in [true, false])
                AppChip(
                  label: category.name,
                  icon: IconRegistry.get(
                    categoryCode?.icon,
                    fallback: AppIcons.category,
                  ),
                  color:
                      categoryCode?.accentColorFor(palette) ?? palette.primary,
                  selected: on,
                  onTap: _noop,
                ),
            ],
          ],
        ),
        _Compare(
          name: 'TagChip',
          usedIn: 'detail / ฟอร์มรายการ · ตัวเลือกแท็ก',
          old: const [
            TagChip(tag: tag),
            TagChip(tag: tag, selected: false, onTap: _noop),
          ],
          chip: [
            AppChip(
              label: tag.name,
              icon: AppIcons.tag,
              color: tagTint,
              selected: true,
            ),
            AppChip(
              label: tag.name,
              icon: AppIcons.tag,
              color: tagTint,
              onTap: _noop,
            ),
          ],
        ),
        _Compare(
          name: 'ลิสต์รายการ _ActiveFilterChip (สำเนา · ✕)',
          usedIn: 'ตัวกรองที่ใช้อยู่ ใต้ช่องค้นหา',
          old: [_OldActiveFilterChip(scheme: scheme)],
          chip: [
            AppChip(
              label: 'กระเป๋า: KBank',
              selected: true,
              trailing: AppChipTrailing.remove,
              onRemove: () {},
            ),
          ],
        ),
        const _Compare(
          name: 'ProjectStatusPill',
          usedIn: 'อีเวนต์ — hero / ลิสต์',
          old: [
            ProjectStatusPill(status: ProjectStatus.active, onTap: _noop),
            ProjectStatusPill(status: ProjectStatus.completed),
          ],
          chip: [
            AppChip(
              label: 'กำลังดำเนินการ',
              dot: true,
              selected: true,
              trailing: AppChipTrailing.dropdown,
              onTap: _noop,
            ),
            AppChip(
              label: 'เสร็จแล้ว',
              dot: true,
              tone: AppChipTone.success,
              selected: true,
            ),
          ],
        ),
        _Compare(
          name: 'รายการตั้งเวลา _VariantPill (สำเนา)',
          usedIn: 'การ์ด + หน้า detail รายการตั้งเวลา',
          old: [_OldVariantPill(scheme: scheme)],
          chip: const [
            AppChip(
              label: 'ผ่อนชำระ',
              tone: AppChipTone.neutral,
              selected: true,
            ),
          ],
        ),
        const _Compare(
          name: 'ContactLinkedPill',
          usedIn: 'หน้า detail ผู้ติดต่อ',
          old: [ContactLinkedPill()],
          chip: [
            AppChip(label: 'ผูกแล้ว', icon: AppIcons.link, selected: true),
          ],
        ),
      ],
    );
  }
}

/// A copy of tx_hero_card's private `_DatePill`, for the comparison.
class _OldDatePill extends StatelessWidget {
  const _OldDatePill({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Material(
    color: scheme.surface,
    shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: _noop,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.date, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text('วันนี้', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    ),
  );
}

/// A copy of transactions_list_page's private `_ActiveFilterChip`.
class _OldActiveFilterChip extends StatelessWidget {
  const _OldActiveFilterChip({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => PillShell(
    size: PillSize.normal,
    background: scheme.primary.withValues(alpha: 0.12),
    border: scheme.primary.withValues(alpha: 0.5),
    onTap: _noop,
    child: PillContent(
      label: 'กระเป๋า: KBank',
      color: scheme.primary,
      size: PillSize.normal,
      trailing: Icon(AppIcons.close, size: 16, color: scheme.primary),
    ),
  );
}

/// A copy of the scheduled pages' private `_VariantPill`.
class _OldVariantPill extends StatelessWidget {
  const _OldVariantPill({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
    decoration: BoxDecoration(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      'ผ่อนชำระ',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// ─── Material chips ───────────────────────────────────────────────────

class _MaterialRows extends StatelessWidget {
  const _MaterialRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Compare(
          name: 'ActionChip — จ่ายหนี้ ทั้งหมด / ครึ่งหนึ่ง',
          usedIn: 'sheet จ่ายหนี้',
          old: [
            ActionChip(label: const Text('ทั้งหมด'), onPressed: () {}),
            ActionChip(label: const Text('ครึ่งหนึ่ง'), onPressed: () {}),
          ],
          chip: const [
            AppChip(label: 'ทั้งหมด', onTap: _noop),
            AppChip(label: 'ครึ่งหนึ่ง', onTap: _noop),
          ],
        ),
        _Compare(
          name: 'ActionChip — + แท็กใหม่',
          usedIn: 'รายการในอีเวนต์ — แท็ก',
          old: [
            ActionChip(
              avatar: const Icon(AppIcons.add, size: 16),
              label: const Text('แท็กใหม่'),
              onPressed: () {},
            ),
          ],
          chip: const [
            AppChip(label: 'แท็กใหม่', icon: AppIcons.add, onTap: _noop),
          ],
        ),
        const _Compare(
          name: 'FilterChip — เฉพาะฉัน',
          usedIn: 'อีเวนต์ — tab รายการ',
          old: [_OldOnlyMine()],
          chip: [_NewOnlyMine()],
        ),
        _Compare(
          name: 'ActionChip — เติมจำนวนเงินเร็ว',
          usedIn: 'AmountField quickFills',
          old: [
            ActionChip(label: const Text('฿100'), onPressed: () {}),
            ActionChip(label: const Text('฿500'), onPressed: () {}),
          ],
          chip: const [
            AppChip(label: '฿100', onTap: _noop),
            AppChip(label: '฿500', onTap: _noop),
          ],
        ),
        _Compare(
          name: 'ChoiceChip — ชุดไอคอน (icon maker)',
          usedIn: 'icon maker — ตัวกรองชุด',
          old: [
            ChoiceChip(
              label: const Text('ทั้งหมด'),
              selected: true,
              onSelected: (_) {},
            ),
            ChoiceChip(
              label: const Text('material'),
              selected: false,
              onSelected: (_) {},
            ),
          ],
          chip: const [
            AppChip(label: 'ทั้งหมด', selected: true, onTap: _noop),
            AppChip(label: 'material', onTap: _noop),
          ],
        ),
      ],
    );
  }
}

class _OldOnlyMine extends StatefulWidget {
  const _OldOnlyMine();

  @override
  State<_OldOnlyMine> createState() => _OldOnlyMineState();
}

class _OldOnlyMineState extends State<_OldOnlyMine> {
  bool _on = true;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: const Text('เฉพาะฉัน'),
    selected: _on,
    onSelected: (v) => setState(() => _on = v),
    showCheckmark: false,
    shape: const StadiumBorder(),
  );
}

class _NewOnlyMine extends StatefulWidget {
  const _NewOnlyMine();

  @override
  State<_NewOnlyMine> createState() => _NewOnlyMineState();
}

class _NewOnlyMineState extends State<_NewOnlyMine> {
  bool _on = true;

  @override
  Widget build(BuildContext context) => AppChip(
    label: 'เฉพาะฉัน',
    selected: _on,
    onTap: () => setState(() => _on = !_on),
  );
}

// ─── Playground ───────────────────────────────────────────────────────

/// Every [AppChip] option, live. Also embedded in "รายละเอียด".
class AppChipPlayground extends StatefulWidget {
  const AppChipPlayground({super.key});

  @override
  State<AppChipPlayground> createState() => _AppChipPlaygroundState();
}

class _AppChipPlaygroundState extends State<AppChipPlayground> {
  AppChipTone? _tone;
  PillSize _size = PillSize.normal;
  AppChipTrailing _trailing = AppChipTrailing.none;
  bool _icon = true;
  bool _avatar = false;
  bool _dot = false;
  bool _selected = true;
  bool _interactive = true;
  bool _enabled = true;
  bool _longLabel = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget title(String t) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Text(t, style: textTheme.labelLarge),
    );
    Widget toggle(String label, bool value, ValueChanged<bool> set) => AppChip(
      label: label,
      selected: value,
      onTap: () => setState(() => set(!value)),
    );
    final chip = AppChip(
      label: _longLabel ? 'ชื่อยาวมากจนต้องตัดด้วยจุดสามจุดตรงท้าย' : 'อาหาร',
      icon: _icon && !_avatar ? AppIcons.category : null,
      leading: _avatar ? const UserAvatar(displayName: 'ลี') : null,
      dot: _dot,
      tone: _tone,
      selected: _selected,
      onTap: _interactive ? () => setState(() => _selected = !_selected) : null,
      trailing: _trailing,
      onRemove: () => setState(() => _trailing = AppChipTrailing.none),
      count: 3,
      size: _size,
      enabled: _enabled,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: chip,
          ),
          title('สี (tone)'),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppChip(
                label: 'ค่าเริ่มต้น',
                selected: _tone == null,
                onTap: () => setState(() => _tone = null),
              ),
              for (final t in AppChipTone.values)
                AppChip(
                  label: t.name,
                  dot: true,
                  tone: t,
                  selected: _tone == t,
                  onTap: () => setState(() => _tone = t),
                ),
            ],
          ),
          title('ขนาด — มีแค่ 2: ปกติ 32 · mini 20 (แท็กในแถวรายการ)'),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final s in PillSize.values)
                AppChip(
                  label: '${s.name} · ${s.height.round()}',
                  selected: _size == s,
                  onTap: () => setState(() => _size = s),
                ),
            ],
          ),
          title('ท้าย (trailing)'),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final t in AppChipTrailing.values)
                AppChip(
                  label: t.name,
                  selected: _trailing == t,
                  onTap: () => setState(() => _trailing = t),
                ),
            ],
          ),
          title('ตัวเลือก'),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              toggle('ไอคอน', _icon, (v) => _icon = v),
              toggle('avatar', _avatar, (v) => _avatar = v),
              toggle('● dot', _dot, (v) => _dot = v),
              toggle('เลือกอยู่', _selected, (v) => _selected = v),
              toggle('แตะได้', _interactive, (v) => _interactive = v),
              toggle('ใช้ได้', _enabled, (v) => _enabled = v),
              toggle('ชื่อยาว', _longLabel, (v) => _longLabel = v),
            ],
          ),
        ],
      ),
    );
  }
}
