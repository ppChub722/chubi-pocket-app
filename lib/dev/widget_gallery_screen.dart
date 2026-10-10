import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/shell/app_top_bar.dart';
import '../app/shell/top_bar_crumbs.dart';
import '../core/constants/app_icons.dart';
import '../core/theme/module_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/date_formatter.dart';
import '../features/accounts/domain/account.dart';
import '../features/app_version/domain/app_version_info.dart';
import '../features/app_version/presentation/pages/update_required_page.dart';
import '../features/app_version/presentation/widgets/update_banner.dart';
import '../features/accounts/domain/account_type.dart';
import '../features/accounts/presentation/widgets/wallet_summary_title.dart';
import '../features/categories/domain/category.dart';
import '../features/categories/domain/category_type.dart';
import '../features/categories/presentation/cubit/categories_cubit.dart';
import '../features/categories/presentation/widgets/category_chip.dart';
import '../features/categories/presentation/widgets/category_picker_sheet.dart';
import '../features/preferences/presentation/cubit/theme_mode_cubit.dart';
import '../features/contacts/presentation/widgets/contact_picker_sheet.dart';
import '../features/transactions/presentation/widgets/account_picker_sheet.dart';
import '../features/tags/domain/tag.dart';
import '../features/tags/presentation/widgets/tag_chip.dart';
import '../features/tags/presentation/widgets/tag_picker_sheet.dart';
import '../features/transactions/domain/transaction.dart';
import '../features/transactions/domain/transaction_type.dart';
import '../features/transactions/presentation/widgets/event_pick.dart';
import '../features/transactions/presentation/widgets/period_summary_card.dart';
import '../features/transactions/presentation/widgets/pick_chip_rows.dart';
import '../features/transactions/presentation/widgets/transaction_tile.dart';
import '../features/transactions/presentation/widgets/tx_hero_card.dart';
import '../features/transactions/presentation/widgets/tx_summary_title.dart';
import '../features/transactions/presentation/widgets/tx_period_pill.dart';
import '../features/transactions/presentation/tx_list_filters.dart';
import '../shared/icon_maker/icon_code.dart';
import '../shared/icon_maker/icon_display.dart';
import '../shared/icon_maker/icon_code_widget.dart';
import '../shared/icon_maker/icon_maker_sheet.dart';
import '../shared/icon_maker/icon_shape.dart';
import '../l10n/gen/app_localizations.dart';
import '../shared/icon_maker/icon_type.dart';
import '../shared/widgets/type_indicator.dart';
import '../shared/widgets/ui.dart';

/// `/dev/widgets` — live catalogue of the shared UI kit
/// (`shared/widgets/ui.dart`). Every widget is interactive so behaviour
/// (loading, disabled, edit mode, sheets, privacy) can be poked at on a
/// real device. Dev-only strings are hard-coded on purpose.
class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

enum _Section {
  buttons,
  inputs,
  chips,
  layout,
  feedback,
  data,
  domain,
  appIcons,
  icons,
  edit,
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  _Section _section = _Section.buttons;
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final editTab = _section == _Section.edit;
    return Scaffold(
      appBar: AppTopBar(
        title: editTab && _editing ? 'แก้ไขตัวอย่าง' : 'Widget gallery',
        showBack: true,
        editing: editTab && _editing,
        onBack: editTab && _editing
            ? () => setState(() => _editing = false)
            : null,
        // No page actions on the top bar (owner rule 2026-10-09): theme
        // toggle sits next to the tabs; edit / delete live in the demo body.
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 10 * 96,
                    child: AppTabBar<_Section>(
                      selected: _section,
                      onChanged: (s) => setState(() {
                        _section = s;
                        _editing = false;
                      }),
                      tabs: const [
                        AppTab(value: _Section.buttons, label: 'ปุ่ม'),
                        AppTab(value: _Section.inputs, label: 'ช่องกรอก'),
                        AppTab(value: _Section.chips, label: 'Chip'),
                        AppTab(value: _Section.layout, label: 'Layout'),
                        AppTab(value: _Section.feedback, label: 'Feedback'),
                        AppTab(value: _Section.data, label: 'ข้อมูล'),
                        AppTab(value: _Section.domain, label: 'โดเมน'),
                        AppTab(value: _Section.appIcons, label: 'ไอคอน'),
                        AppTab(value: _Section.icons, label: 'Icon maker'),
                        AppTab(value: _Section.edit, label: 'โหมดแก้ไข'),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'สลับธีม',
                icon: const Icon(Icons.brightness_6_outlined),
                onPressed: () => context.read<ThemeModeCubit>().toggle(),
              ),
            ],
          ),
          Expanded(
            child: switch (_section) {
              _Section.buttons => const _ButtonsDemo(),
              _Section.inputs => const _InputsDemo(),
              _Section.chips => const _ChipsDemo(),
              _Section.layout => const _LayoutDemo(),
              _Section.feedback => const _FeedbackDemo(),
              _Section.data => const _DataDemo(),
              _Section.domain => const _DomainDemo(),
              _Section.appIcons => const _AppIconsDemo(),
              _Section.icons => const _IconMakerDemo(),
              _Section.edit => _EditModeDemo(
                editing: _editing,
                onEnterEdit: () => setState(() => _editing = true),
                onDelete: () => _confirmDelete(context),
              ),
            },
          ),
        ],
      ),
      bottomNavigationBar: editTab && _editing
          ? ModeActionBar(
              canSave: true,
              canUndo: true,
              undoTooltip: 'เลิกทำ',
              cancelLabel: 'ยกเลิก',
              saveLabel: 'บันทึก',
              onCancel: () => setState(() => _editing = false),
              onUndo: () => showAppSnackBar(context, 'Undo'),
              onSave: () {
                setState(() => _editing = false);
                showAppSnackBar(context, 'บันทึกแล้ว', tone: Tone.success);
              },
            )
          : null,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'ลบรายการนี้?',
      message: 'การลบไม่สามารถย้อนกลับได้',
      confirmLabel: 'ลบ',
      destructive: true,
    );
    if (!context.mounted) return;
    if (ok) {
      setState(() => _editing = false);
      showAppSnackBar(context, 'ลบแล้ว', tone: Tone.danger);
    }
  }
}

// ── Shared demo chrome ─────────────────────────────────────────────────

/// Labelled block in the gallery: title + caption (widget name) + content.
class _Demo extends StatelessWidget {
  const _Demo({required this.title, required this.name, required this.child});

  final String title;
  final String name;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(
            name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _Gap extends StatelessWidget {
  const _Gap();
  @override
  Widget build(BuildContext context) => const SizedBox(height: AppSpacing.sm);
}

// ── Buttons ────────────────────────────────────────────────────────────

class _ButtonsDemo extends StatefulWidget {
  const _ButtonsDemo();
  @override
  State<_ButtonsDemo> createState() => _ButtonsDemoState();
}

class _ButtonsDemoState extends State<_ButtonsDemo> {
  bool _loading = false;
  bool _disabled = false;
  IconChipActivity _chipActivity = IconChipActivity.progress;

  Future<void> _fakeLoad() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    VoidCallback? tap(String what) =>
        _disabled ? null : () => showAppSnackBar(context, 'กด $what');
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
      children: [
        SwitchListTile(
          title: const Text('ปิดการใช้งานทุกปุ่ม'),
          value: _disabled,
          onChanged: (v) => setState(() => _disabled = v),
        ),
        _Demo(
          title: 'ปุ่มทุกแบบ',
          name: 'AppButton(variant: …)',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(label: 'Primary', onPressed: tap('primary')),
              AppButton(
                label: 'Tonal',
                variant: AppButtonVariant.tonal,
                onPressed: tap('tonal'),
              ),
              AppButton(
                label: 'Outlined',
                variant: AppButtonVariant.outlined,
                onPressed: tap('outlined'),
              ),
              AppButton(
                label: 'Text',
                variant: AppButtonVariant.text,
                onPressed: tap('text'),
              ),
              AppButton(
                label: 'ลบ',
                icon: Icons.delete_outline,
                variant: AppButtonVariant.destructive,
                onPressed: tap('destructive'),
              ),
              AppButton(
                label: 'ออกจากระบบ',
                icon: Icons.logout,
                variant: AppButtonVariant.destructiveOutlined,
                onPressed: tap('destructiveOutlined'),
              ),
            ],
          ),
        ),
        _Demo(
          title: 'ขนาดใหญ่ เต็มความกว้าง + loading',
          name: 'AppButton(size: large, expand: true, loading: …)',
          child: Column(
            children: [
              AppButton(
                label: 'กดเพื่อโหลด 2 วินาที',
                icon: Icons.save_outlined,
                size: AppButtonSize.large,
                expand: true,
                loading: _loading,
                onPressed: _disabled ? null : _fakeLoad,
              ),
              const _Gap(),
              AppButton(
                label: 'ยกเลิก',
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.large,
                expand: true,
                onPressed: tap('cancel'),
              ),
            ],
          ),
        ),
        _Demo(
          title: 'ปุ่มไอคอนวงกลม',
          name: 'AppIconButton',
          child: Row(
            children: [
              AppIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'แก้ไข',
                onPressed: tap('edit'),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIconButton(
                icon: Icons.notifications_outlined,
                badgeCount: 3,
                onPressed: tap('bell'),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIconButton(
                icon: Icons.delete_outline,
                destructive: true,
                onPressed: tap('delete'),
              ),
              const SizedBox(width: AppSpacing.sm),
              const AppIconButton(
                icon: Icons.palette_outlined,
                onPressed: null,
              ),
            ],
          ),
        ),
        _Demo(
          title:
              'ไอคอนที่มีงานเบื้องหลัง (เช่น ชิป Pending ตอนอ่านสลิป): ปกติ · กำลังทำ · เสร็จ',
          name: 'AppIconButton(activity: none | progress | done)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<IconChipActivity>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: IconChipActivity.none,
                    label: Text('ปกติ'),
                  ),
                  ButtonSegment(
                    value: IconChipActivity.progress,
                    label: Text('กำลังอ่าน'),
                  ),
                  ButtonSegment(
                    value: IconChipActivity.done,
                    label: Text('เสร็จ'),
                  ),
                ],
                selected: {_chipActivity},
                onSelectionChanged: (s) =>
                    setState(() => _chipActivity = s.first),
              ),
              const _Gap(),
              Row(
                children: [
                  AppIconButton(
                    icon: AppIcons.pending,
                    badgeCount: 5,
                    activity: _chipActivity,
                    progress: 0.4,
                    onPressed: () =>
                        setState(() => _chipActivity = IconChipActivity.none),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text(
                      'กำลังอ่าน: ซ่อน badge + แถบความคืบหน้าใต้ไอคอน · เสร็จ: ติ๊ก + badge กลับมา · กดชิป = กลับเป็นปกติ',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _Demo(
          title: 'ปุ่มลอยที่เปิดเป็นช่องพิมพ์แบบแชต (ยังไม่ทำอะไรตอนกดส่ง)',
          name: 'ChatDial',
          child: SizedBox(
            height: 72,
            child: Align(
              alignment: Alignment.centerRight,
              child: ChatDial(
                hint: 'เช่น กาแฟ 65',
                tooltip: 'พิมพ์เอง',
                sendTooltip: 'ส่ง',
                closeTooltip: 'ปิด',
                openWidth: 300,
                onSend: (t) => showAppSnackBar(context, 'ส่ง: $t'),
              ),
            ),
          ),
        ),
        _Demo(
          title: 'ปุ่มเพิ่มแบบเส้นประ',
          name: 'AddTile(variant: card | row | circle)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AddTile(label: 'เพิ่มกระเป๋า', onTap: tap('add card')),
              const _Gap(),
              AddTile(
                label: 'เพิ่มการหาร',
                variant: AddTileVariant.row,
                onTap: tap('add row'),
              ),
              const _Gap(),
              AddTile(
                label: 'เชิญ',
                variant: AddTileVariant.circle,
                onTap: tap('invite'),
              ),
            ],
          ),
        ),
        _Demo(
          title: 'ทางเข้าลับ (แตะ 5 ครั้งภายใน 2 วินาที)',
          name: 'SecretTapDetector · TapUnlockCounter',
          child: SecretTapDetector(
            onUnlock: () =>
                showAppSnackBar(context, 'ปลดล็อกแล้ว', tone: Tone.success),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('แตะตรงนี้เร็วๆ 5 ครั้ง'),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Inputs ─────────────────────────────────────────────────────────────

class _InputsDemo extends StatefulWidget {
  const _InputsDemo();
  @override
  State<_InputsDemo> createState() => _InputsDemoState();
}

enum _Dir { iOwe, owedToMe }

class _InputsDemoState extends State<_InputsDemo> {
  final _amount = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _query = '';
  Account? _account;
  Category? _category;
  DateTime _date = DateTime.now();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  _Dir _dir = _Dir.owedToMe;
  AccountType _walletType = AccountType.bank;
  final Set<int> _checks = {1};

  static const _sampleAccounts = [
    Account(
      id: 'a1',
      name: 'โดราเอมอน',
      type: AccountType.bank,
      balance: 1999818,
      currency: 'THB',
    ),
    Account(
      id: 'a2',
      name: 'เงินสด',
      type: AccountType.cash,
      balance: 3250,
      currency: 'THB',
    ),
    Account(
      id: 'a3',
      name: 'TrueMoney',
      type: AccountType.eWallet,
      balance: 480.5,
      currency: 'THB',
    ),
    Account(
      id: 'a4',
      name: 'KTC',
      type: AccountType.creditCard,
      balance: -3200,
      currency: 'THB',
      creditLimit: 50000,
    ),
  ];

  Future<void> _pickAccount() async {
    final r = await showAccountPickerSheet(
      context: context,
      accounts: _sampleAccounts,
      selected: _account,
      allowNone: true,
    );
    if (r == null) return;
    setState(
      () => _account = switch (r) {
        AccountPickerSelected(:final account) => account,
        AccountPickerCleared() => null,
      },
    );
  }

  Future<void> _pickCategory() async {
    final cubit = context.read<CategoriesCubit>();
    await cubit.loadIfNeeded();
    if (!mounted) return;
    final cats = cubit.state.categories;
    if (cats.isEmpty) {
      showAppSnackBar(
        context,
        'ยังไม่มีหมวดหมู่ — ต้องล็อกอินก่อน',
        tone: Tone.warning,
      );
      return;
    }
    final r = await showCategoryPickerSheet(
      context: context,
      categories: cats,
      type: CategoryType.expense,
      selected: _category,
    );
    if (r == null) return;
    setState(
      () => _category = switch (r) {
        CategoryPickerSelected(:final category) => category,
        CategoryPickerCleared() => null,
      },
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.huge),
        children: [
          _Demo(
            title: 'ช่องค้นหา',
            name: 'AppSearchBar',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSearchBar(
                  padding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const _Gap(),
                Text('คำค้น: "$_query"'),
              ],
            ),
          ),
          _Demo(
            title: 'เลือกหลายรายการ (สี่เหลี่ยมมน · ซ้าย = เลือกทั้งหมด n/N)',
            name: 'SelectCheck · SelectAllCount',
            child: Row(
              children: [
                SelectAllCount(
                  selected: _checks.length,
                  total: 3,
                  onTap: () => setState(
                    () => _checks.length == 3
                        ? _checks.clear()
                        : _checks.addAll([0, 1, 2]),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                for (var i = 0; i < 3; i++)
                  SelectCheck(
                    value: _checks.contains(i),
                    onTap: () => setState(
                      () => _checks.contains(i)
                          ? _checks.remove(i)
                          : _checks.add(i),
                    ),
                  ),
              ],
            ),
          ),
          _Demo(
            title: 'เลือกทิศทาง (การ์ดใหญ่)',
            name: 'SelectCardGroup',
            child: SelectCardGroup<_Dir>(
              selected: _dir,
              onChanged: (v) => setState(() => _dir = v),
              options: [
                SelectCardOption(
                  value: _Dir.iOwe,
                  label: 'ฉันติดเขา',
                  icon: Icons.call_made,
                  color: palette.expense,
                ),
                SelectCardOption(
                  value: _Dir.owedToMe,
                  label: 'เขาติดฉัน',
                  icon: Icons.call_received,
                  color: palette.income,
                ),
              ],
            ),
          ),
          _Demo(
            title: 'เลือกประเภท (การ์ดใหญ่ แบบตาราง 3+2)',
            name: 'SelectCardGroup(columns: 3)',
            child: SelectCardGroup<AccountType>(
              columns: 3,
              selected: _walletType,
              onChanged: (v) => setState(() => _walletType = v),
              options: [
                for (final (t, label) in const [
                  (AccountType.cash, 'เงินสด'),
                  (AccountType.bank, 'ธนาคาร'),
                  (AccountType.eWallet, 'อีวอลเล็ท'),
                  (AccountType.creditCard, 'บัตรเครดิต'),
                  (AccountType.payLater, 'ผ่อนทีหลัง'),
                ])
                  SelectCardOption(value: t, label: label, icon: t.icon),
              ],
            ),
          ),
          _Demo(
            title: 'ช่องจำนวนเงิน + ปุ่มลัด',
            name: 'AmountField(quickFills: …)',
            child: AmountField(
              controller: _amount,
              accent: _dir == _Dir.iOwe ? palette.expense : palette.income,
              quickFills: const [
                AmountQuickFill(label: 'ทั้งหมด ฿500', amount: 500),
                AmountQuickFill(label: 'ครึ่งหนึ่ง', amount: 250),
              ],
              validator: (v) {
                final n = AmountField.parse(v);
                if (n == null || n <= 0) return 'กรอกจำนวนเงินที่มากกว่า 0';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'ค่าที่อ่านได้: AmountField.parse → '
              '${AmountField.parse(_amount.text)}',
            ),
          ),
          _Demo(
            title: 'Tile เลือกค่า',
            name: 'PickerTile',
            child: Column(
              children: [
                PickerTile(
                  label: 'กระเป๋า · showAccountPickerSheet',
                  value: _account?.name,
                  placeholder: 'ไม่ระบุกระเป๋า',
                  leading: _account == null
                      ? const Icon(Icons.account_balance_wallet_outlined)
                      : IconDisplay(
                          type: IconType.account,
                          size: 28,
                          iconCode: _account!.iconCode,
                        ),
                  trailing: _account == null
                      ? null
                      : MoneyText(_account!.balance),
                  onTap: _pickAccount,
                ),
                const _Gap(),
                PickerTile(
                  label: 'หมวดหมู่ · showCategoryPickerSheet',
                  value: _category?.name,
                  placeholder: 'เลือกหมวดหมู่',
                  errorText: _category == null ? 'กรุณาเลือกหมวดหมู่' : null,
                  leading: _category == null
                      ? const Icon(AppIcons.category)
                      : IconDisplay(
                          type: IconType.category,
                          size: 28,
                          iconCode: _category!.iconCode,
                        ),
                  onTap: _pickCategory,
                ),
                const _Gap(),
                PickerTile(
                  label: 'วันที่',
                  value: DateFormatter.friendly(
                    _date,
                    today: 'วันนี้',
                    yesterday: 'เมื่อวาน',
                  ),
                  leading: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                ),
                const _Gap(),
                const PickerTile(
                  label: 'หมวดหมู่ (อ่านอย่างเดียว)',
                  value: 'Opening Balance',
                  leading: Icon(Icons.lock_outline),
                  readOnly: true,
                  onTap: null,
                ),
              ],
            ),
          ),
          _Demo(
            title: 'การ์ดเลือกค่า (quick create · งบประมาณ)',
            name: 'PickCard',
            child: Column(
              children: [
                PickCard(
                  label: 'หมวดหมู่',
                  value: _category?.name,
                  placeholder: 'ไม่ระบุหมวด',
                  leading: IconDisplay(
                    type: IconType.category,
                    size: 40,
                    iconCode: _category?.iconCode,
                  ),
                  accent: _category?.iconCode?.accentColorFor(
                    Theme.of(context).extension<AppColors>()!,
                  ),
                  onTap: _pickCategory,
                ),
                const _Gap(),
                PickCard(
                  label: 'กระเป๋า',
                  value: _account?.name,
                  placeholder: 'ไม่มีกระเป๋า',
                  leading: IconDisplay(
                    type: IconType.account,
                    size: 40,
                    iconCode: _account?.iconCode,
                  ),
                  subtitle: _account == null
                      ? null
                      : MoneyText(_account!.balance),
                  accent: _account?.iconCode?.accentColorFor(
                    Theme.of(context).extension<AppColors>()!,
                  ),
                  onTap: _pickAccount,
                ),
                const _Gap(),
                PickCard(
                  label: 'หมวดหมู่ (บังคับ)',
                  placeholder: 'เลือกหมวดหมู่',
                  leading: const Icon(AppIcons.category),
                  errorText: 'กรุณาเลือกหมวดหมู่',
                  onTap: _pickCategory,
                ),
                const _Gap(),
                // trailing: a picked optional value that clears in place
                // (any card whose value can be taken off right there).
                PickCard(
                  label: 'อีเวนต์',
                  value: 'ทริปเชียงใหม่',
                  leading: const PickCardEmptyIcon(AppIcons.project, size: 32),
                  accent: ModuleColors.of(context).people,
                  watermark: AppIcons.project,
                  dense: true,
                  trailing: IconButton(
                    icon: const Icon(AppIcons.clear, size: 18),
                    onPressed: () {},
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          _Demo(
            title: 'เลือกเดือน (dashboard) — แตะชื่อเดือนเปิดตัวเลือก',
            name: 'MonthPill · showMonthPicker(last: now)',
            child: Center(
              child: MonthPill(
                month: _month,
                last: DateTime.now(),
                onChanged: (m) => setState(() => _month = m),
              ),
            ),
          ),
          const _Demo(
            title: 'ช่องข้อความมาตรฐาน',
            name: 'AppTextField(obscurable: …)',
            child: Column(
              children: [
                AppTextField(
                  label: 'อีเมล',
                  helper: 'ใช้เป็นรหัสบัญชีของคุณ',
                  prefixIcon: Icons.mail_outline,
                ),
                _Gap(),
                AppTextField(label: 'รหัสผ่าน', obscurable: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppButton(
              label: 'ทดสอบ validate ฟอร์ม',
              variant: AppButtonVariant.tonal,
              expand: true,
              onPressed: () => _formKey.currentState?.validate(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chips ──────────────────────────────────────────────────────────────

/// The pick rows the transaction form and the filter sheet share: the kit
/// ([ChoicePillRow], [ChipRow] + [RowChip], [ChipOrder]) and the feature
/// rows on top of it (หมวด / แท็ก / กระเป๋า, ranked from the real caches).
class _PickRowsDemo extends StatefulWidget {
  const _PickRowsDemo();

  @override
  State<_PickRowsDemo> createState() => _PickRowsDemoState();
}

/// The shared picker shell: header + ✕, optional compact search, rows with
/// a highlight (no ✓), loading / error + retry, a create row — and the
/// event sheet built on it.
class _PickerShellDemo extends StatefulWidget {
  const _PickerShellDemo();

  @override
  State<_PickerShellDemo> createState() => _PickerShellDemoState();
}

class _PickerShellDemoState extends State<_PickerShellDemo> {
  String? _picked = 'มะม่วง';
  String? _event;

  static const _fruits = [
    'มะม่วง',
    'ทุเรียน',
    'มังคุด',
    'เงาะ',
    'ลำไย',
    'สับปะรด',
    'กล้วย',
    'ส้มโอ',
    'แตงโม',
    'ฝรั่ง',
  ];

  Future<void> _open({bool loading = false, bool error = false}) async {
    final picked = await showAppSheetCustom<String>(
      context,
      builder: (ctx) => PickerSheet(
        title: 'เลือกผลไม้',
        searchable: true,
        loading: loading,
        error: error
            ? const ApiException(code: 'NETWORK', message: 'โหลดไม่สำเร็จ')
            : null,
        onRetry: () => Navigator.of(ctx).pop(),
        footer: PickerCreateRow(
          label: 'สร้างผลไม้ใหม่',
          onTap: () => Navigator.of(ctx).pop('ผลไม้ใหม่'),
        ),
        builder: (context, q) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in _fruits)
              if (q.isEmpty || f.contains(q))
                PickerRow(
                  leading: const Icon(AppIcons.category),
                  title: f,
                  subtitle: f == _picked ? 'เลือกอยู่' : null,
                  selected: f == _picked,
                  onTap: () => Navigator.of(context).pop(f),
                ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _picked = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Demo(
          title: 'Picker shell — หัว + ✕ · ค้นหาเล็ก · ไฮไลต์ (ไม่มี ✓)',
          name:
              'PickerSheet · PickerRow · PickerCreateRow · CompactSearchField',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActionPill(label: 'เปิด ($_picked)', onTap: () => _open()),
              ActionPill(label: 'กำลังโหลด', onTap: () => _open(loading: true)),
              ActionPill(label: 'error', onTap: () => _open(error: true)),
            ],
          ),
        ),
        _Demo(
          title: 'อีเวนต์ — แถวในฟอร์ม + sheet เลือก (อีเวนต์จริง)',
          name: 'EventRow · showEventTargetSheet',
          child: SectionCard(
            first: true,
            children: [
              EventRow(
                name: _event,
                onTap: () async {
                  final t = await showEventTargetSheet(
                    context,
                    suggestedName: 'อีเวนต์ · ทดลอง',
                  );
                  if (t != null && mounted) {
                    setState(
                      () => _event = eventTargetName(
                        AppLocalizations.of(context)!,
                        t,
                      ),
                    );
                  }
                },
                onClear: () => setState(() => _event = null),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickRowsDemoState extends State<_PickRowsDemo> {
  TransactionType? _type;
  String _unit = 'เดือน';
  bool _all = true;
  Category? _category;
  final Set<String> _tags = {};
  String? _wallet;
  final _categoryOrder = ChipOrder();
  final _tagOrder = ChipOrder();
  final _walletOrder = ChipOrder();
  TxPeriod _period = TxPeriod.month(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Demo(
          title: 'ช่วงเวลา — ‹ › ทีละหน่วย, แตะชื่อ → sheet (วัน…กำหนดเอง)',
          name: 'TxPeriodPill · showPeriodSheet · PeriodPicker',
          child: Center(
            child: TxPeriodPill(
              period: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
          ),
        ),
        _Demo(
          title: 'ประเภท (ฟอร์ม + ตัวกรอง) — null = ทั้งหมด สีกลาง',
          name: 'TxTypeChip(type: null | expense | income | transfer)',
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final t in const [
                null,
                TransactionType.expense,
                TransactionType.income,
                TransactionType.transfer,
              ])
                TxTypeChip(
                  type: t,
                  selected: t == _type,
                  onTap: () => setState(() => _type = t),
                ),
            ],
          ),
        ),
        _Demo(
          title: 'เลือกหนึ่งอย่าง (ช่วงเวลา · เรียงตาม ในตัวกรอง)',
          name: 'ChoicePillRow · ChoicePill (pill kit, ไม่ใช่ ChoiceChip)',
          child: ChoicePillRow<String>(
            values: const ['เดือน', 'สัปดาห์', 'ปี', 'ทั้งหมด', 'กำหนดเอง'],
            selected: _unit,
            size: PillSize.medium,
            label: (v) => v,
            onSelected: (v) => setState(() => _unit = v),
          ),
        ),
        _Demo(
          title: 'แถวเลือก: [ไอคอน] ชิป … [เพิ่มเติม]',
          name: 'ChipRow · RowChip (ขนาดเท่าชิปหมวด / แท็ก)',
          child: ChipRow(
            icon: AppIcons.wallet,
            moreLabel: 'เพิ่มเติม',
            onMore: () {},
            chips: [
              RowChip(
                label: 'ทั้งหมด',
                selected: _all,
                onTap: () => setState(() => _all = true),
              ),
              RowChip(
                label: 'กสิกร',
                icon: AppIcons.bank,
                color: Colors.green,
                selected: !_all,
                onTap: () => setState(() => _all = false),
              ),
            ],
          ),
        ),
        _Demo(
          title: 'หมวด · แท็ก · กระเป๋า (ฟอร์ม + ตัวกรอง) — ลำดับคงที่',
          name: 'CategoryChipRow · TagChipRow · WalletChipRow (ChipOrder)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CategoryChipRow(
                type: TransactionType.expense,
                selected: _category,
                order: _categoryOrder,
                onPick: (c) => setState(() => _category = c),
                onMore: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              TagChipRow(
                selected: _tags,
                order: _tagOrder,
                onToggle: (id) => setState(() {
                  if (!_tags.remove(id)) _tags.add(id);
                }),
                onMore: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              WalletChipRow(
                selectedId: _wallet,
                order: _walletOrder,
                onPick: (a) => setState(() => _wallet = a.id),
                onMore: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipsDemo extends StatefulWidget {
  const _ChipsDemo();
  @override
  State<_ChipsDemo> createState() => _ChipsDemoState();
}

enum _Sort { name, usage, color }

class _ChipsDemoState extends State<_ChipsDemo> {
  final Set<int> _colors = {};
  Set<String> _icons = {};
  final Set<String> _glyphs = {};
  int _tab = 0;
  final _tabPages = PageController();
  String? _status;
  _Sort _sort = _Sort.name;
  String _projectStatus = 'active';

  @override
  void dispose() {
    _tabPages.dispose();
    super.dispose();
  }

  static const _swatches = [
    Color(0xFFE57373),
    Color(0xFFF06292),
    Color(0xFFBA68C8),
    Color(0xFF7986CB),
    Color(0xFF4FC3F7),
    Color(0xFF4DB6AC),
    Color(0xFFAED581),
    Color(0xFFFFD54F),
    Color(0xFFFFB74D),
  ];

  static const _statusLabels = {
    'active': ('ใช้งาน', Tone.success),
    'completed': ('เสร็จสิ้น', Tone.info),
    'cancelled': ('ยกเลิก', Tone.danger),
    'archived': ('เก็บถาวร', Tone.neutral),
  };

  @override
  Widget build(BuildContext context) {
    final current = _statusLabels[_projectStatus]!;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
      children: [
        const _PickRowsDemo(),
        const _PickerShellDemo(),
        _Demo(
          title: 'แถวตัวกรอง + เรียงลำดับ (popover)',
          name:
              'FilterBar · FilterDropdownChip · PopoverAnchor · '
              'MultiOptionMenuAnchor · OptionMenuAnchor · SortChip',
          child: FilterBar(
            chips: [
              // Colour — custom popover content (swatch grid, multi).
              PopoverAnchor(
                builder: (context, toggle) => FilterDropdownChip(
                  label: 'สี',
                  icon: Icons.palette_outlined,
                  count: _colors.length,
                  onTap: toggle,
                ),
                contentBuilder: (context, close) => ColorSwatchGrid(
                  colors: _swatches,
                  selected: _colors,
                  onToggle: (i) => setState(
                    () => _colors.contains(i)
                        ? _colors.remove(i)
                        : _colors.add(i),
                  ),
                  onClear: () => setState(_colors.clear),
                ),
              ),
              // Icon — multi-select checkbox popover.
              MultiOptionMenuAnchor<String>(
                selected: _icons,
                onChanged: (v) => setState(() => _icons = v),
                options: const [
                  SheetOption(
                    value: 'sell',
                    label: 'ป้าย',
                    leading: Icon(Icons.sell_outlined, size: 18),
                  ),
                  SheetOption(
                    value: 'work',
                    label: 'งาน',
                    leading: Icon(Icons.work_outline, size: 18),
                  ),
                  SheetOption(
                    value: 'swap',
                    label: 'โอน',
                    leading: Icon(Icons.swap_horiz, size: 18),
                  ),
                ],
                builder: (context, toggle) => FilterDropdownChip(
                  label: 'ไอคอน',
                  icon: AppIcons.iconPicker,
                  count: _icons.length,
                  onTap: toggle,
                ),
              ),
              // Status — single-select popover.
              OptionMenuAnchor<String?>(
                selected: _status,
                onSelected: (v) => setState(() => _status = v),
                options: const [
                  SheetOption(value: null, label: 'ทั้งหมด'),
                  SheetOption(value: 'ค้างอยู่', label: 'ค้างอยู่'),
                  SheetOption(value: 'คืนครบ', label: 'คืนครบ'),
                  SheetOption(value: 'ยกเลิก', label: 'ยกเลิก'),
                ],
                builder: (context, toggle) => FilterDropdownChip(
                  label: 'สถานะ',
                  valueLabel: _status,
                  onTap: toggle,
                ),
              ),
              const FilterDropdownChip(label: 'ปิดอยู่', onTap: null),
            ],
            trailing: SortChip<_Sort>(
              selected: _sort,
              onSelected: (s) => setState(() => _sort = s),
              options: const [
                SortOption(_Sort.name, 'ชื่อ'),
                SortOption(_Sort.usage, 'ใช้บ่อย'),
                SortOption(_Sort.color, 'สี'),
              ],
            ),
          ),
        ),
        const _Gap(),
        _Demo(
          title: 'ตัวกรองไอคอน (popover แบบช่องไอคอน — แท็ก / หมวดหมู่)',
          name: 'PopoverAnchor + IconSwatchGrid',
          child: Align(
            alignment: Alignment.centerLeft,
            child: PopoverAnchor(
              builder: (context, toggle) => FilterDropdownChip(
                label: 'ไอคอน',
                icon: AppIcons.iconPicker,
                count: _glyphs.length,
                onTap: toggle,
              ),
              contentBuilder: (context, close) => StatefulBuilder(
                builder: (context, setPopover) => IconSwatchGrid(
                  glyphs: const ['label', 'flag', 'star', 'bolt', 'savings'],
                  selected: _glyphs,
                  onToggle: (g) {
                    setState(
                      () => _glyphs.contains(g)
                          ? _glyphs.remove(g)
                          : _glyphs.add(g),
                    );
                    setPopover(() {});
                  },
                  onClear: () {
                    setState(_glyphs.clear);
                    setPopover(() {});
                  },
                ),
              ),
            ),
          ),
        ),
        const _Gap(),
        _Demo(
          title:
              'แท็บ — ปัดเนื้อหาตามนิ้ว · เส้นใต้เลื่อนตาม · แตะ = ช้า-เร็ว-ช้า',
          name: 'AppTabBar(pager:) + AppTabPager',
          child: Column(
            children: [
              AppTabBar<int>(
                selected: _tab,
                onChanged: (v) => setState(() => _tab = v),
                pager: _tabPages,
                tabs: const [
                  AppTab(value: 0, label: 'รายจ่าย'),
                  AppTab(value: 1, label: 'รายรับ'),
                  AppTab(value: 2, label: 'โอน', badgeCount: 2),
                ],
              ),
              SizedBox(
                height: 96,
                child: AppTabPager<int>(
                  controller: _tabPages,
                  values: const [0, 1, 2],
                  selected: _tab,
                  onChanged: (v) => setState(() => _tab = v),
                  builder: (context, v) => Center(
                    child: Text(
                      'เนื้อหาแท็บ ${v + 1} — ปัดตรงนี้',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const _Gap(),
        _Demo(
          title: 'Pill สถานะ (กดเพื่อเปลี่ยน — popover)',
          name: 'OptionMenuAnchor + StatusPill(onTap)',
          child: Align(
            alignment: Alignment.centerLeft,
            child: OptionMenuAnchor<String>(
              selected: _projectStatus,
              onSelected: (v) => setState(() => _projectStatus = v),
              options: [
                for (final e in _statusLabels.entries)
                  SheetOption(
                    value: e.key,
                    label: e.value.$1,
                    leading: _Dot(color: e.value.$2.color(context)),
                  ),
              ],
              builder: (context, toggle) => StatusPill(
                label: current.$1,
                tone: current.$2,
                onTap: toggle,
              ),
            ),
          ),
        ),
        _Demo(
          title: 'รายการยาว/ต้องค้นหา → bottom sheet',
          name: 'showOptionSheet(searchable: true)',
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilterDropdownChip(
              label: 'สกุลเงิน',
              icon: Icons.currency_exchange,
              onTap: () => showOptionSheet<String>(
                context,
                title: 'สกุลเงิน',
                searchable: true,
                options: const [
                  SheetOption(value: 'THB', label: 'THB', subtitle: 'บาทไทย'),
                  SheetOption(
                    value: 'USD',
                    label: 'USD',
                    subtitle: 'ดอลลาร์สหรัฐ',
                  ),
                  SheetOption(value: 'JPY', label: 'JPY', subtitle: 'เยน'),
                ],
              ),
            ),
          ),
        ),
        _Demo(
          title: 'แถบการเลือก (แทนตัวกรองเมื่อเลือก ≥1)',
          name: 'SelectCheck + ActionPill',
          child: Row(
            children: [
              const SelectCheck(value: true, onTap: null),
              Text('3', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(width: AppSpacing.sm),
              ActionPill(
                icon: AppIcons.colorPicker,
                label: 'สี',
                onTap: () => showAppSnackBar(context, 'เปลี่ยนสี'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ActionPill(
                icon: AppIcons.iconPicker,
                label: 'ไอคอน',
                onTap: () => showAppSnackBar(context, 'เปลี่ยนไอคอน'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ActionPill(
                icon: AppIcons.delete,
                label: 'ลบ',
                destructive: true,
                onTap: () => showAppSnackBar(context, 'ลบ'),
              ),
            ],
          ),
        ),
        const _Demo(
          title: 'Pill ทุก tone',
          name: 'StatusPill(tone: …)',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusPill(label: 'neutral'),
              StatusPill(label: 'primary', tone: Tone.primary),
              StatusPill(label: 'success', tone: Tone.success),
              StatusPill(label: 'warning', tone: Tone.warning),
              StatusPill(label: 'danger', tone: Tone.danger),
              StatusPill(label: 'info', tone: Tone.info),
              StatusPill(label: 'รายรับ', tone: Tone.income, icon: Icons.add),
              StatusPill(
                label: 'รายจ่าย',
                tone: Tone.expense,
                icon: Icons.remove,
              ),
              StatusPill(label: 'dense', tone: Tone.primary, dense: true),
            ],
          ),
        ),
        const _Demo(
          title: 'Badge เล็ก',
          name: 'AppBadge',
          child: Wrap(
            spacing: AppSpacing.sm,
            children: [
              AppBadge(label: 'ไม่มีกระเป๋า'),
              AppBadge(label: 'เจ้าของ', tone: Tone.primary),
              AppBadge(label: 'รอตอบรับ', tone: Tone.warning),
              AppBadge(label: '3', icon: Icons.sell_outlined),
            ],
          ),
        ),
        // ── Period pill + side sheet (transactions list, 2026-10-10) ──
        _Demo(
          title: 'Pill ช่วงเวลา (สัปดาห์ · ปี · กำหนดเอง · ทั้งหมด)',
          name: 'PeriodPill(label, onPrev, onNext, onTap)',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              PeriodPill(
                label: '6 ต.ค. – 12 ต.ค. 2569',
                onPrev: () => showAppSnackBar(context, 'ก่อนหน้า'),
                onTap: () => showAppSnackBar(context, 'เปิดตัวกรอง'),
              ),
              PeriodPill(
                label: '2569',
                onPrev: () => showAppSnackBar(context, 'ก่อนหน้า'),
                onNext: () => showAppSnackBar(context, 'ถัดไป'),
              ),
              PeriodPill(
                label: 'ทั้งหมด',
                onTap: () => showAppSnackBar(context, 'เปิดตัวกรอง'),
              ),
            ],
          ),
        ),
        _Demo(
          title: 'Side sheet จากขวา (ตัวกรอง — ปัดขวา / แตะพื้นหลังเพื่อปิด)',
          name: 'showSideSheet · SideSheetScaffold · SideSheetSection',
          child: AppButton(
            label: 'เปิด side sheet',
            icon: Icons.tune,
            variant: AppButtonVariant.outlined,
            onPressed: () => showSideSheet<void>(
              context,
              builder: (sheet) => SideSheetScaffold(
                title: 'ตัวกรอง',
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SideSheetSection(
                      title: 'ประเภท',
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          for (final t in ['ทั้งหมด', 'รายจ่าย', 'รายรับ'])
                            ChoiceChip(
                              label: Text(t),
                              selected: t == 'ทั้งหมด',
                              showCheckmark: false,
                            ),
                        ],
                      ),
                    ),
                    SideSheetSection(
                      title: 'กระเป๋า',
                      child: PickerTile(
                        label: 'กระเป๋า',
                        placeholder: 'ทั้งหมด',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                footer: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'ล้าง',
                        variant: AppButtonVariant.outlined,
                        expand: true,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'ใช้ตัวกรอง',
                        expand: true,
                        onPressed: () => Navigator.of(sheet).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // ── App version gate (owner 2026-10-10) ────────────────────────
        _Demo(
          title: 'มีเวอร์ชันใหม่ — แถบบนสุด (ปิดแล้วไม่โผล่อีก 1 วัน)',
          name: 'UpdateBannerStrip (UpdateBanner)',
          child: UpdateBannerStrip(
            onUpdate: () => showAppSnackBar(context, 'เปิดลิงก์ดาวน์โหลด'),
            onDismiss: () => showAppSnackBar(context, 'ไว้ทีหลัง'),
          ),
        ),
        const _Demo(
          title:
              'ต้องอัปเดตก่อนใช้งาน — หน้าบล็อก (ผ่านไม่ได้ · back = ปิดแอป)',
          name: 'UpdateRequiredView (/update-required)',
          child: SizedBox(
            height: 560,
            child: UpdateRequiredView(
              info: AppVersionInfo(
                minBuild: 44,
                latestBuild: 44,
                downloadUrl: 'https://example.com/apk',
              ),
              currentBuild: 43,
              exitOnBack: false,
            ),
          ),
        ),
        // ── The pill family (owner 2026-10-10) ─────────────────────────
        _Demo(
          title: 'ตระกูล pill — ขนาด (mini · small · medium · large)',
          name: 'PillSize · StatusPill · LabelPill · ActionPill · TagPill',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in PillSize.values) ...[
                Text(
                  '${s.name} · ${s.height.toInt()}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(label: 'ค้างอยู่', tone: Tone.warning, size: s),
                    LabelPill(label: 'ผ่อน', size: s),
                    ActionPill(
                      label: 'ปรับยอด',
                      icon: AppIcons.reset,
                      size: s,
                      onTap: () => showAppSnackBar(context, 'ปรับยอด'),
                    ),
                    TagPill(
                      name: 'เที่ยว',
                      color: const Color(0xFF26A69A),
                      size: s,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
        _Demo(
          title: 'Label pill — บอกว่าเป็นอะไร (ไม่มีจุด)',
          name: 'LabelPill(tone | color, outlined, icon) · TypeIndicator',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              const LabelPill(label: 'ผ่อน', size: PillSize.small),
              const LabelPill(label: 'กู้ยืม', size: PillSize.small),
              const LabelPill(label: 'ประจำ', tone: Tone.info),
              // Wallet type — the wallet's own accent, outlined.
              const LabelPill(
                label: 'ธนาคาร',
                icon: AppIcons.bank,
                color: Color(0xFF5C6BC0),
                outlined: true,
                size: PillSize.large,
              ),
              const TypeIndicator(isIncome: false),
              const TypeIndicator(isIncome: true),
              // Category create: the one not picked dims.
              Opacity(
                opacity: 0.4,
                child: TypeIndicator(
                  isIncome: true,
                  size: PillSize.medium,
                  label: AppLocalizations.of(context)!.categoryTypeIncome,
                ),
              ),
            ],
          ),
        ),
        _Demo(
          title: 'Action pill — ปุ่มเล็ก',
          name: 'ActionPill(style: tinted | raised, destructive, size)',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActionPill(
                label: 'สี',
                icon: Icons.palette_outlined,
                onTap: () => showAppSnackBar(context, 'สี'),
              ),
              ActionPill(
                label: 'ลบ',
                icon: AppIcons.delete,
                destructive: true,
                onTap: () => showAppSnackBar(context, 'ลบ'),
              ),
              ActionPill(
                label: 'ปรับยอด',
                icon: AppIcons.reset,
                style: ActionPillStyle.raised,
                size: PillSize.medium,
                onTap: () => showAppSnackBar(context, 'ปรับยอด'),
              ),
              const ActionPill(label: 'ปิดอยู่', onTap: null),
            ],
          ),
        ),
        _Demo(
          title: 'Tag pill — สีของแท็ก · ไอคอน (ถ้ามี) · #ชื่อ',
          name: 'TagPill · PillOverflowRow(maxVisible)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final (name, color, glyph) in _demoTags)
                    TagPill(
                      name: name,
                      color: color,
                      glyph: glyph,
                      size: PillSize.small,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 240,
                child: Row(
                  children: [
                    Flexible(
                      child: PillOverflowRow(
                        pills: [
                          for (final (name, color, _) in _demoTags)
                            TagPill(name: name, color: color),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _Demo(
          title: 'แท็กบนแถวรายการ — เลือกแบบไหน?',
          name: 'today: #tag text line · try: mini TagPill + "+n"',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (label, tags) in [
                ('1 แท็ก', _demoTags.take(1).toList()),
                ('2 แท็ก', _demoTags.take(2).toList()),
                ('5 แท็ก', _demoTags),
              ]) ...[
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                _MockTxRow(caption: 'ตอนนี้ · ข้อความ #แท็ก', tags: tags),
                _MockTxRow(
                  caption: 'ลอง · pill เล็ก สูงสุด 2',
                  tags: tags,
                  pills: 2,
                ),
                _MockTxRow(
                  caption: 'ลอง · pill เล็ก สูงสุด 3',
                  tags: tags,
                  pills: 3,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ── Layout ─────────────────────────────────────────────────────────────

/// `AppTopBar(titleSlot: …)` — a page's own title widget in place of the
/// title text; the button swaps it in / out (it cross-fades like a title
/// change). The tx detail's edit mode shows this summary once the amount
/// scrolls away.
class _TitleSlotBar extends StatefulWidget {
  const _TitleSlotBar();

  @override
  State<_TitleSlotBar> createState() => _TitleSlotBarState();
}

class _TitleSlotBarState extends State<_TitleSlotBar> {
  bool _on = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: kToolbarHeight,
          child: AppTopBar(
            title: 'แก้ไขรายการ',
            showBack: true,
            editing: true,
            showParent: false,
            titleSlot: _on
                ? TxSummaryTitle(
                    type: TransactionType.expense,
                    amount: 1250,
                    onTap: () => setState(() => _on = false),
                  )
                : null,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _on = !_on),
            child: Text('titleSlot: ${_on ? 'on' : 'off'}'),
          ),
        ),
      ],
    );
  }
}

class _LayoutDemo extends StatelessWidget {
  const _LayoutDemo();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
      children: [
        const _Demo(
          title: 'Top bar breadcrumb (หน้าแม่ › หน้านี้)',
          name: 'AppTopBar(parent: TopBarCrumb(…)) · ค่าเริ่มต้นหาจาก route',
          // The bar's parts are Heroes — demos beside the page's own bar
          // would share their tags.
          child: HeroMode(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: kToolbarHeight,
                  child: AppTopBar(
                    title: 'ทริปญี่ปุ่น',
                    showBack: true,
                    showUniversal: false,
                    parent: TopBarCrumb(
                      label: 'โปรเจกต์ & อีเวนต์',
                      path: '/projects',
                      routeName: 'projects',
                    ),
                  ),
                ),
                SizedBox(
                  height: kToolbarHeight,
                  child: AppTopBar(
                    title: 'ชื่อยาวมากจนต้องตัดด้วยจุดสามจุดตรงท้าย',
                    showBack: true,
                    editing: true,
                    parent: TopBarCrumb(
                      label: 'ผู้ติดต่อ',
                      path: '/contacts',
                      routeName: 'contacts',
                    ),
                  ),
                ),
                _TitleSlotBar(),
              ],
            ),
          ),
        ),
        _Demo(
          title: 'การ์ดสีกลุ่ม (กระเป๋า · เพิ่มเติม · แดชบอร์ด)',
          name: 'TintedCard(tint, glyph, onTap) · TintedIconBadge',
          child: Builder(
            builder: (context) {
              final groups = ModuleColors.of(context);
              Widget card(Color tint, IconData icon, String label) => Expanded(
                child: SizedBox(
                  height: 110,
                  child: TintedCard(
                    tint: tint,
                    glyph: icon,
                    glyphSize: 64,
                    onTap: () => showAppSnackBar(context, label),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TintedIconBadge(icon: icon, tint: tint, size: 28),
                          TintedIconBadge.gap,
                          Text(label),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              return Row(
                children: [
                  card(groups.library, AppIcons.category, 'คลัง'),
                  const SizedBox(width: AppSpacing.sm),
                  card(groups.people, AppIcons.debt, 'คน'),
                  const SizedBox(width: AppSpacing.sm),
                  card(groups.planning, AppIcons.budget, 'วางแผน'),
                ],
              );
            },
          ),
        ),
        const _Demo(
          title: 'โลโก้แอป (splash 128 · หัว login 88 · register 56)',
          name: 'BrandLogo',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [BrandLogo(), BrandLogo(size: 88), BrandLogo(size: 56)],
          ),
        ),
        _Demo(
          title: 'Header card',
          name: 'HeaderCard(leading, title, subtitle, trailing, footer)',
          child: HeaderCard(
            accent: palette.income,
            leading: const UserAvatar(displayName: 'Aom Chan', size: 44),
            title: const Text('Aom ติดคุณ'),
            subtitle: const Text('2 รายการค้างอยู่'),
            trailing: const StatusPill(label: 'ค้างอยู่', tone: Tone.warning),
            footer: const ProgressRow(
              value: 0.6,
              label: 'คืนแล้ว ฿300 จาก ฿500',
              trailing: '60%',
            ),
          ),
        ),
        const _Demo(
          title: 'กรอบเลือก (แตะเพื่อเลือก)',
          name: 'SelectableFrame',
          child: _SelectableDemo(),
        ),
        const _HeroSpacingDemo(),
        const _Demo(
          title:
              'แถวรายการคลัง (หมวดหมู่ · แท็ก · ผู้ติดต่อ): ไอคอน · ชื่อ · '
              'คำอธิบาย · ข้อมูลท้าย — ย่อยเยื้อง · เก็บถาวรจาง · โหมดเลือก',
          name: 'ListRow(indent, dimmed, checked, body)',
          child: _ListRowDemo(),
        ),
        _Demo(
          title: 'หัวข้อ section',
          name: 'SectionHeader(count, actionLabel | trailing)',
          child: Column(
            children: [
              SectionHeader(
                title: 'รายการล่าสุด',
                count: 12,
                actionLabel: 'ดูทั้งหมด',
                padding: EdgeInsets.zero,
                onAction: () => showAppSnackBar(context, 'ดูทั้งหมด'),
              ),
              // trailing: an icon action (the wallet groups' ⇅ จัดลำดับ).
              SectionHeader(
                title: 'ของฉัน',
                count: 4,
                padding: EdgeInsets.zero,
                trailing: IconButton(
                  tooltip: 'จัดลำดับ',
                  icon: const Icon(AppIcons.reorder),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        _Demo(
          title: 'กระเป๋าในบรรทัดเดียว (top bar ตอนเลื่อนผ่าน hero)',
          name: 'WalletSummaryTitle — AppTopBar.titleSlot',
          child: Align(
            alignment: Alignment.centerLeft,
            child: WalletSummaryTitle(
              account: const Account(
                id: 'demo',
                name: 'กสิกร ออมทรัพย์',
                type: AccountType.bank,
                balance: 12345,
                currency: 'THB',
              ),
            ),
          ),
        ),
        _Demo(
          title: 'แถวรายละเอียด',
          name:
              'SectionCard(first, title, trailing, locked) · DetailRow · '
              'DetailStacked · DetailAddRow · SectionBand',
          // Clipped to the demo box, padded like a detail page, so the band
          // shows how it reaches the screen edges.
          child: ClipRect(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hairlines between rows come from the section itself.
                  SectionCard(
                    first: true,
                    title: 'การรับเงิน',
                    trailing: AppIconButton(
                      icon: AppIcons.share,
                      size: 32,
                      tooltip: 'แชร์',
                      onPressed: () => showAppSnackBar(context, 'แชร์'),
                    ),
                    children: [
                      DetailRow(
                        label: 'บันทึกรับเงินอัตโนมัติ',
                        helper: 'เมื่อมีคนแจ้งว่าจ่ายแล้ว',
                        trailing: Switch(value: true, onChanged: (_) {}),
                      ),
                      DetailRow(
                        label: 'กระเป๋าที่รับเงิน',
                        leading: const Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                        trailing: const Text('โดราเอมอน'),
                        showChevron: true,
                        onTap: () => showAppSnackBar(context, 'เปิดตัวเลือก'),
                      ),
                      const DetailStacked(
                        label: 'บันทึก',
                        child: Text('ข้อความยาวจะอยู่ใต้ label เต็มความกว้าง'),
                      ),
                      DetailAddRow(
                        label: 'เพิ่มกระเป๋ารับเงิน',
                        onTap: () => showAppSnackBar(context, 'เพิ่ม'),
                      ),
                    ],
                  ),
                  // Not first → a tinted band above it. locked = edit mode.
                  SectionCard(
                    title: 'การจัดการ (locked)',
                    locked: true,
                    children: [
                      const DetailRow(
                        label: 'ชื่อผู้ใช้',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('@ppond '),
                            Icon(Icons.lock_outline, size: 16),
                          ],
                        ),
                      ),
                      DetailRow(
                        leading: const Icon(Icons.archive_outlined),
                        label: 'เก็บถาวร',
                        onTap: () => showAppSnackBar(context, 'เก็บถาวร'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        _Demo(
          title: 'แถบปุ่มติดล่าง',
          name: 'PinnedBar(bottomGap, keyboardGap)',
          // Clears the gesture bar on a real phone; sits just above the
          // keyboard while it's open.
          child: PinnedBar(
            child: AppButton(
              label: 'บันทึก',
              expand: true,
              onPressed: () => showAppSnackBar(context, 'บันทึก'),
            ),
          ),
        ),
        _Demo(
          title: 'ล็อกในโหมดแก้ไข',
          name: 'LockedInEdit(locked: true)',
          child: LockedInEdit(
            locked: true,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SummaryStats(stats: _sampleStats),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The library-list row in its uses: a category tree (indent, ▾ on a
/// parent, a status pill), a tag (×usage), an archived contact (dimmed,
/// 🔗), and batch-edit mode (tap toggles the check).
class _ListRowDemo extends StatefulWidget {
  const _ListRowDemo();

  @override
  State<_ListRowDemo> createState() => _ListRowDemoState();
}

class _ListRowDemoState extends State<_ListRowDemo> {
  final Set<int> _checked = {1};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const food = IconCode(icon: 'food');
    Widget check(int i, String name) => ListRow(
      checked: _checked.contains(i),
      onTap: () => setState(
        () => _checked.contains(i) ? _checked.remove(i) : _checked.add(i),
      ),
      leading: const IconDisplay(type: IconType.tag, size: 40),
      title: name,
    );
    return SectionCard(
      first: true,
      children: [
        ListRow(
          leading: const IconDisplay(
            type: IconType.category,
            size: 40,
            iconCode: food,
          ),
          title: 'อาหาร',
          subtitle: 'มื้อหลัก ขนม เครื่องดื่ม',
          trailing: IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(AppIcons.collapse),
            onPressed: () {},
          ),
          onTap: () {},
        ),
        ListRow(
          indent: AppSpacing.xxl,
          leading: const IconDisplay(
            type: IconType.category,
            size: 40,
            iconCode: food,
          ),
          title: 'กาแฟ',
          trailing: const LabelPill(
            label: 'ซ่อนจากรายงาน',
            icon: AppIcons.hidden,
            size: PillSize.small,
          ),
          onTap: () {},
        ),
        ListRow(
          leading: const IconDisplay(type: IconType.tag, size: 40),
          title: 'ทริปเชียงใหม่',
          trailing: Text(
            '×12',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          onTap: () {},
        ),
        ListRow(
          leading: const UserAvatar(displayName: 'Aom Chan'),
          title: 'Aom Chan',
          subtitle: 'aom@example.com · 081-234-5678',
          dimmed: true,
          trailing: Icon(AppIcons.link, size: 18, color: scheme.primary),
          onTap: () {},
        ),
        check(0, 'งาน'),
        check(1, 'บ้าน'),
      ],
    );
  }
}

class _SelectableDemo extends StatefulWidget {
  const _SelectableDemo();
  @override
  State<_SelectableDemo> createState() => _SelectableDemoState();
}

class _SelectableDemoState extends State<_SelectableDemo> {
  int _picked = 0;

  @override
  Widget build(BuildContext context) {
    const labels = ['รายเดือน', 'รายสัปดาห์', 'รายปี'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: SelectableFrame(
              selected: _picked == i,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => setState(() => _picked = i),
                  child: SizedBox(
                    height: 64,
                    child: Center(child: Text(labels[i])),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

const _sampleStats = [
  SummaryStat(label: 'รายรับ', amount: 3000, tone: MoneyTone.income),
  SummaryStat(label: 'รายจ่าย', amount: 12400, tone: MoneyTone.expense),
  SummaryStat(label: 'สุทธิ', amount: -9400, tone: MoneyTone.signed),
];

// ── Feedback ───────────────────────────────────────────────────────────

/// [CoinDropIndicator]'s refreshing loop, running forever.
class _CoinLoopDemo extends StatefulWidget {
  const _CoinLoopDemo();
  @override
  State<_CoinLoopDemo> createState() => _CoinLoopDemoState();
}

class _CoinLoopDemoState extends State<_CoinLoopDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    // Refreshing rests 24 px down — pull it back into the box.
    builder: (context, _) => Transform.translate(
      offset: const Offset(0, -24),
      child: CoinDropIndicator(pull: 1, drop: _c.value),
    ),
  );
}

class _FeedbackDemo extends StatefulWidget {
  const _FeedbackDemo();
  @override
  State<_FeedbackDemo> createState() => _FeedbackDemoState();
}

class _FeedbackDemoState extends State<_FeedbackDemo> {
  double _progress = 0.45;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
      children: [
        _Demo(
          title: 'Pull to refresh — เหรียญ ฿ หย่อนลงกระเป๋า',
          name: 'PullToRefresh(onRefresh, enabled) · CoinDropIndicator',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Pull phases, frozen (dy offset zeroed by pull = 0.5).
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CoinDropIndicator(pull: 0.5),
                  ),
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CoinDropIndicator(pull: 0.75),
                  ),
                  SizedBox(width: 64, height: 64, child: _CoinLoopDemo()),
                ],
              ),
              const _Gap(),
              // The real thing — pull this box down.
              SizedBox(
                height: 200,
                child: ClipRect(
                  child: PullToRefresh(
                    onRefresh: () =>
                        Future<void>.delayed(const Duration(seconds: 2)),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 200,
                          child: Center(child: Text('ดึงกล่องนี้ลง ↓')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _Demo(
          title: 'แถบข้อความในหน้า (เหนือฟอร์ม)',
          name: 'MessageBanner(tone, onClose)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MessageBanner(
                message: 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง',
                onClose: () => showAppSnackBar(context, 'ปิด'),
              ),
              const _Gap(),
              const MessageBanner(
                message: 'ไม่มีการเชื่อมต่อ',
                tone: Tone.warning,
              ),
              const _Gap(),
              const MessageBanner(
                message: 'ยังไม่ได้ยืนยันอีเมล',
                tone: Tone.info,
              ),
            ],
          ),
        ),
        _Demo(
          title: 'Dialog ยืนยัน',
          name: 'showConfirmDialog(destructive: …)',
          child: Wrap(
            spacing: AppSpacing.sm,
            children: [
              AppButton(
                label: 'ยืนยันปกติ',
                variant: AppButtonVariant.outlined,
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'เปลี่ยนเป็นเสร็จสิ้น?',
                    message: 'จะเพิ่มรายการไม่ได้อีก',
                    confirmLabel: 'ยืนยัน',
                  );
                  if (context.mounted) showAppSnackBar(context, 'ผล: $ok');
                },
              ),
              AppButton(
                label: 'ยืนยันลบ',
                variant: AppButtonVariant.destructiveOutlined,
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'ลบผู้ติดต่อ?',
                    message: 'การลบไม่สามารถย้อนกลับได้',
                    confirmLabel: 'ลบ',
                    destructive: true,
                  );
                  if (context.mounted) showAppSnackBar(context, 'ผล: $ok');
                },
              ),
            ],
          ),
        ),
        _Demo(
          title: 'Dialog หลายทางเลือก (> 2 ปุ่ม)',
          name: 'showChoiceDialog(choices: [DialogChoice…])',
          child: AppButton(
            label: 'ปิดฟอร์มที่มีของค้าง',
            variant: AppButtonVariant.outlined,
            onPressed: () async {
              final r = await showChoiceDialog<String>(
                context,
                title: 'ทิ้งรายการนี้?',
                message: 'ยังไม่ได้บันทึก',
                choices: const [
                  DialogChoice(
                    value: 'draft',
                    label: 'เก็บเป็นร่าง',
                    variant: AppButtonVariant.primary,
                  ),
                  DialogChoice(value: 'keep', label: 'แก้ต่อ'),
                  DialogChoice(
                    value: 'discard',
                    label: 'ทิ้ง',
                    variant: AppButtonVariant.destructive,
                  ),
                ],
              );
              if (context.mounted) showAppSnackBar(context, 'ผล: $r');
            },
          ),
        ),
        _Demo(
          title: 'Sheet เมนูของสิ่งที่แตะ',
          name:
              'showActionSheet(header: ActionSheetHeader, actions: [SheetAction…])',
          child: AppButton(
            label: 'แตะแถวสมาชิก',
            variant: AppButtonVariant.outlined,
            onPressed: () async {
              final r = await showActionSheet<String>(
                context,
                header: const ActionSheetHeader(
                  leading: CircleAvatar(child: Text('ก')),
                  title: 'กุ้ง',
                  subtitle: 'มีบัญชีในแอป',
                ),
                actions: const [
                  SheetAction(
                    value: 'role',
                    icon: AppIcons.visible,
                    label: 'ให้ดูอย่างเดียว',
                  ),
                  SheetAction(
                    value: 'transfer',
                    icon: AppIcons.member,
                    label: 'โอนความเป็นเจ้าของ',
                    subtitle: 'ต้องมีบัญชีในแอปก่อน',
                    enabled: false,
                  ),
                  SheetAction(
                    value: 'remove',
                    icon: AppIcons.delete,
                    label: 'นำออกจากโปรเจกต์',
                    destructive: true,
                  ),
                ],
              );
              if (context.mounted) showAppSnackBar(context, 'ผล: $r');
            },
          ),
        ),
        _Demo(
          title: 'Snackbar ทุก tone',
          name: 'showAppSnackBar(tone: …)',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in [
                Tone.neutral,
                Tone.success,
                Tone.danger,
                Tone.warning,
                Tone.info,
              ])
                AppButton(
                  label: t.name,
                  variant: AppButtonVariant.tonal,
                  onPressed: () => showAppSnackBar(
                    context,
                    'ข้อความแบบ ${t.name}',
                    tone: t,
                    actionLabel: 'เลิกทำ',
                    onAction: () {},
                  ),
                ),
            ],
          ),
        ),
        _Demo(
          title: 'แถบความคืบหน้า (ลากเพื่อลอง เกิน 100% = แดง)',
          name: 'ProgressRow',
          child: Column(
            children: [
              ProgressRow(
                value: _progress,
                label: 'ใช้ไป ฿${(_progress * 20000).round()} / ฿20,000',
                trailing: '${(_progress * 100).round()}%',
              ),
              Slider(
                value: _progress,
                max: 1.3,
                onChanged: (v) => setState(() => _progress = v),
              ),
            ],
          ),
        ),
        _Demo(
          title: 'Bottom sheet มาตรฐาน',
          name: 'showAppSheet(title, footer)',
          child: AppButton(
            label: 'เปิด sheet',
            variant: AppButtonVariant.outlined,
            onPressed: () => showAppSheet<void>(
              context,
              title: 'รับเงินคืนจาก Aom',
              builder: (ctx) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('เนื้อหา sheet — ฟอร์ม, รายการ, ฯลฯ'),
              ),
              footer: Builder(
                builder: (ctx) => AppButton(
                  label: 'ยืนยัน',
                  size: AppButtonSize.large,
                  expand: true,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ),
        ),
        _Demo(
          title: 'Option sheet ค้นหาได้',
          name: 'showOptionSheet(searchable: true)',
          child: AppButton(
            label: 'เลือกสกุลเงิน',
            variant: AppButtonVariant.outlined,
            onPressed: () async {
              final v = await showOptionSheet<String>(
                context,
                title: 'สกุลเงิน',
                searchable: true,
                selected: 'THB',
                options: const [
                  SheetOption(value: 'THB', label: 'THB', subtitle: 'บาทไทย'),
                  SheetOption(
                    value: 'USD',
                    label: 'USD',
                    subtitle: 'ดอลลาร์สหรัฐ',
                  ),
                  SheetOption(value: 'JPY', label: 'JPY', subtitle: 'เยน'),
                  SheetOption(value: 'EUR', label: 'EUR', subtitle: 'ยูโร'),
                ],
              );
              if (context.mounted && v != null) {
                showAppSnackBar(context, 'เลือก $v');
              }
            },
          ),
        ),
        const _Demo(
          title: 'Empty state + AddTile เป็น CTA',
          name: 'EmptyView(cta: AddTile)',
          child: SizedBox(
            height: 320,
            child: EmptyView(
              icon: Icons.people_outline,
              title: 'ยังไม่มีผู้ติดต่อ',
              message: 'คนที่คุณเพิ่มจะแสดงที่นี่',
              cta: AddTile(label: 'เพิ่มผู้ติดต่อคนแรก', onTap: null),
            ),
          ),
        ),
        const _Demo(
          title: 'โหลด / error + ลองอีกครั้ง / ว่าง / มีข้อมูล (ทุกหน้า list)',
          name: 'AsyncStateView · ErrorView',
          child: _AsyncStateDemo(),
        ),
      ],
    );
  }
}

enum _AsyncCase { loading, network, server, empty, data }

class _AsyncStateDemo extends StatefulWidget {
  const _AsyncStateDemo();

  @override
  State<_AsyncStateDemo> createState() => _AsyncStateDemoState();
}

class _AsyncStateDemoState extends State<_AsyncStateDemo> {
  _AsyncCase _case = _AsyncCase.server;
  ApiException? _refreshError;

  static const _network = ApiException(
    code: 'NETWORK_ERROR',
    message: 'No connection',
  );
  static const _server = ApiException(
    code: 'INTERNAL_ERROR',
    message: 'List failed',
    statusCode: 500,
  );

  @override
  Widget build(BuildContext context) {
    final hasData = _case == _AsyncCase.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final c in _AsyncCase.values)
              ChoiceChip(
                label: Text(c.name),
                selected: _case == c,
                onSelected: (_) => setState(() {
                  _case = c;
                  _refreshError = null;
                }),
              ),
          ],
        ),
        if (hasData)
          TextButton(
            // A fresh instance each tap → the snackbar fires each time.
            onPressed: () => setState(
              () => _refreshError = ApiException(
                code: _server.code,
                message: _server.message,
                statusCode: _server.statusCode,
              ),
            ),
            child: const Text('จำลอง refresh ไม่สำเร็จ → snackbar'),
          ),
        SizedBox(
          height: 360,
          child: AsyncStateView(
            loading: _case == _AsyncCase.loading,
            error: switch (_case) {
              _AsyncCase.network => _network,
              _AsyncCase.server => _server,
              _AsyncCase.data => _refreshError,
              _ => null,
            },
            isEmpty: !hasData,
            onRetry: () => setState(() => _case = _AsyncCase.loading),
            skeleton: ListView(
              children: [for (var i = 0; i < 4; i++) const SkeletonListTile()],
            ),
            empty: const EmptyView(
              icon: Icons.handshake_outlined,
              title: 'ยังไม่มีหนี้',
              message: 'แต่ละหน้าส่ง empty ของตัวเองมา',
              cta: AddTile(label: 'บันทึกหนี้', onTap: null),
            ),
            builder: (context) => ListView(
              children: [
                for (final n in ['Aom', 'Bank', 'Cat'])
                  ListTile(
                    title: Text(n),
                    subtitle: const Text('ค้าง 1 รายการ'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Data display ───────────────────────────────────────────────────────

class _DataDemo extends StatelessWidget {
  const _DataDemo();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    const members = [
      PersonRef(name: 'ppOnd', caption: 'คุณ', isOwner: true),
      PersonRef(name: 'Aom Chan'),
      PersonRef(name: 'Bank', caption: 'รอตอบรับ', pending: true),
      PersonRef(name: 'Cat'),
      PersonRef(name: 'Dao'),
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
      children: [
        _Demo(
          title: 'ยอดเงิน + ปุ่มซ่อนยอด 👁 (ปิดอยู่ — kMoneyPrivacyEnabled)',
          name: 'MoneyText · MoneyVisibilityToggle',
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MoneyText(
                      1999818,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const MoneyText(2000, tone: MoneyTone.income),
                    const MoneyText(182, tone: MoneyTone.expense),
                    const MoneyText(-540, tone: MoneyTone.signed),
                  ],
                ),
              ),
              const MoneyVisibilityToggle(size: 28),
            ],
          ),
        ),
        const _Demo(
          title: 'ตัวเลขสรุป',
          name: 'SummaryStats(compact: false | true)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SummaryStats(stats: _sampleStats),
              _Gap(),
              SummaryStats(stats: _sampleStats, compact: true),
            ],
          ),
        ),
        const _ChartsDemo(),
        _Demo(
          title: 'แถวเงิน + หัวข้อกลุ่มวันที่',
          name: 'DateGroupHeader · MoneyListTile · IconBubble',
          child: Card(
            child: Column(
              children: [
                const DateGroupHeader(label: 'วันนี้', total: -540),
                MoneyListTile(
                  leading: IconBubble(
                    icon: Icons.delivery_dining,
                    color: palette.warning,
                  ),
                  title: 'Food Delivery',
                  subtitle: const Row(
                    children: [
                      Flexible(child: Text('อาหาร · โดราเอมอน ')),
                      Icon(Icons.sell_outlined),
                      Text(' 2'),
                    ],
                  ),
                  amount: -182,
                  onTap: () {},
                ),
                MoneyListTile(
                  leading: IconBubble(
                    icon: Icons.restaurant,
                    color: palette.info,
                  ),
                  title: 'ข้าวซอย',
                  subtitle: const Row(
                    children: [AppBadge(label: 'ไม่มีกระเป๋า')],
                  ),
                  amount: -358,
                  amountCaption: 'หาร 3',
                  onTap: () {},
                ),
                const DateGroupHeader(label: 'เมื่อวาน', total: 2000000),
                MoneyListTile(
                  leading: IconBubble(
                    icon: Icons.flag_outlined,
                    color: palette.income,
                  ),
                  title: 'Opening Balance',
                  subtitle: const Text('โดราเอมอน'),
                  amount: 2000000,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        _Demo(
          title: 'แถวสมาชิก + ปุ่มเชิญ',
          name: 'MemberStrip(onInvite)',
          child: MemberStrip(
            members: members,
            onMemberTap: (i) =>
                showAppSnackBar(context, 'แตะ ${members[i].name}'),
            onInvite: () => showAppSnackBar(context, 'เชิญสมาชิก'),
          ),
        ),
        const _Demo(
          title: 'Avatar ซ้อน',
          name: 'AvatarStack(maxVisible: 3)',
          child: Align(
            alignment: Alignment.centerLeft,
            child: AvatarStack(people: members, maxVisible: 3, size: 32),
          ),
        ),
        _Demo(
          title: 'Avatar + badge มุม (notification)',
          name: 'CornerBadge · UserAvatar',
          child: Row(
            children: [
              CornerBadge(
                badge: IconBubble(
                  icon: Icons.receipt_long_outlined,
                  color: palette.primary,
                  size: 20,
                ),
                child: const UserAvatar(displayName: 'Aom Chan', size: 44),
              ),
              const SizedBox(width: AppSpacing.lg),
              const EditableCircle(
                size: 44,
                onTap: _noop,
                child: UserAvatar(displayName: 'ppOnd', size: 44),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _noop() {}

// ── App icons ──────────────────────────────────────────────────────────

/// Every `AppIcons` entry with its semantic name — the single place to see
/// (and change) which glyph means what.
class _AppIconsDemo extends StatefulWidget {
  const _AppIconsDemo();
  @override
  State<_AppIconsDemo> createState() => _AppIconsDemoState();
}

class _AppIconsDemoState extends State<_AppIconsDemo> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = _query.trim().toLowerCase();
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
      children: [
        AppSearchBar(
          hint: 'ค้นหาชื่อไอคอน เช่น debt, edit',
          onChanged: (v) => setState(() => _query = v),
        ),
        for (final group in AppIcons.catalog.entries)
          if (group.value.keys.any((k) => k.toLowerCase().contains(q)))
            _Demo(
              title: group.key,
              name: 'AppIcons.*',
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final e in group.value.entries)
                    if (e.key.toLowerCase().contains(q))
                      Container(
                        width: 96,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Icon(e.value, size: 28),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              e.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
      ],
    );
  }
}

// ── Icon maker ─────────────────────────────────────────────────────────

/// One way of opening `showIconMakerSheet` — a mode demo or a real call
/// site copied 1:1 from the page that uses it.
class _MakerPreset {
  const _MakerPreset({
    required this.label,
    required this.note,
    required this.type,
    this.layers = IconMakerLayers.all,
    this.iconPicker = true,
    this.colorPicker = true,
    this.colorSection = true,
    this.removable = false,
    this.useThisLabel,
  });

  final String label;

  /// Flags (modes) or source file (real call sites).
  final String note;
  final IconType type;
  final IconMakerLayers layers;
  final bool iconPicker;
  final bool colorPicker;
  final bool colorSection;
  final bool removable;
  final String? useThisLabel;
}

/// Every layer combination + edit-scope variant, opened directly.
const _modePresets = [
  _MakerPreset(
    label: 'ไอคอน + พื้น + ขอบ',
    note: 'ค่าเริ่มต้น',
    type: IconType.category,
  ),
  _MakerPreset(
    label: 'ไอคอน + พื้น',
    note: 'showBorder: false',
    type: IconType.category,
    layers: IconMakerLayers.iconBackground,
  ),
  _MakerPreset(
    label: 'ไอคอน + ขอบ',
    note: 'showBackground: false',
    type: IconType.category,
    layers: IconMakerLayers.iconBorder,
  ),
  _MakerPreset(
    label: 'พื้น + ขอบ',
    note: 'showIcon: false',
    type: IconType.category,
    layers: IconMakerLayers.backgroundBorder,
  ),
  _MakerPreset(
    label: 'ไอคอนอย่างเดียว',
    note: 'showBackground/showBorder: false',
    type: IconType.category,
    layers: IconMakerLayers.iconOnly,
  ),
  _MakerPreset(
    label: 'พื้นอย่างเดียว',
    note: 'showIcon/showBorder: false',
    type: IconType.category,
    layers: IconMakerLayers.backgroundOnly,
  ),
  _MakerPreset(
    label: 'ขอบอย่างเดียว',
    note: 'showIcon/showBackground: false',
    type: IconType.category,
    layers: IconMakerLayers.borderOnly,
  ),
  _MakerPreset(
    label: 'รูปแบบอย่างเดียว (ไม่แก้สี)',
    note: 'showColorPicker: false',
    type: IconType.category,
    colorPicker: false,
  ),
  _MakerPreset(
    label: 'สีอย่างเดียว (ไม่แก้รูปแบบ)',
    note: 'showIconPicker: false',
    type: IconType.category,
    iconPicker: false,
  ),
  _MakerPreset(
    label: 'มีปุ่มลบไอคอน',
    note: 'removeLabel',
    type: IconType.category,
    removable: true,
  ),
];

/// The real call sites — same type + flags as the page that opens it.
const _usagePresets = [
  _MakerPreset(
    label: 'กระเป๋า',
    note: 'account_detail_page · saving_goal_detail_page',
    type: IconType.account,
  ),
  _MakerPreset(
    label: 'หมวดหมู่',
    note: 'category_detail_page (หมวดลูกล็อกสีตามหมวดแม่)',
    type: IconType.category,
  ),
  _MakerPreset(
    label: 'หมวดหมู่ย่อย (สีล็อก)',
    note: 'category_detail_page · showColorSection: false',
    type: IconType.category,
    colorSection: false,
  ),
  _MakerPreset(
    label: 'รายการตั้งเวลา',
    note: 'quick create · scheduled mode',
    type: IconType.category,
  ),
  _MakerPreset(
    label: 'โปรเจกต์',
    note: 'project_form_page',
    type: IconType.project,
  ),
  _MakerPreset(
    label: 'รายการในโปรเจกต์',
    note: 'project_transaction_form/edit_page',
    type: IconType.projectTransaction,
  ),
  _MakerPreset(
    label: 'โปรไฟล์',
    note: 'edit_profile_page · useThis + remove',
    type: IconType.userProfile,
    removable: true,
    useThisLabel: 'ใช้รูปนี้',
  ),
  _MakerPreset(
    label: 'แท็ก (แก้ทีละอัน)',
    note: 'tags_page · ไอคอน+สี ไม่มีพื้น/ขอบ',
    type: IconType.tag,
    layers: IconMakerLayers.iconOnly,
  ),
  _MakerPreset(
    label: 'แท็ก · เปลี่ยนสีหลายอัน',
    note: 'tags_page bulk · showIconPicker: false',
    type: IconType.tag,
    layers: IconMakerLayers.iconOnly,
    iconPicker: false,
  ),
  _MakerPreset(
    label: 'แท็ก · เปลี่ยนไอคอนหลายอัน',
    note: 'tags_page bulk · showColorPicker: false',
    type: IconType.tag,
    layers: IconMakerLayers.iconOnly,
    colorPicker: false,
  ),
  _MakerPreset(
    label: 'ผู้ติดต่อ (แผน)',
    note: 'contact detail ใหม่ · pack_contact',
    type: IconType.contact,
  ),
];

class _IconMakerDemo extends StatefulWidget {
  const _IconMakerDemo();
  @override
  State<_IconMakerDemo> createState() => _IconMakerDemoState();
}

class _IconMakerDemoState extends State<_IconMakerDemo> {
  final Map<_MakerPreset, IconCode?> _results = {};

  Future<void> _open(_MakerPreset p) async {
    final r = await showIconMakerSheet(
      context: context,
      type: p.type,
      initial: _results[p],
      showIcon: p.layers.icon,
      showBackground: p.layers.background,
      showBorder: p.layers.border,
      showIconPicker: p.iconPicker,
      showColorPicker: p.colorPicker,
      showColorSection: p.colorSection,
      useThisLabel: p.useThisLabel,
      removeLabel: p.removable ? 'ลบไอคอน' : null,
    );
    if (!mounted || r == null) return;
    setState(
      () => _results[p] = switch (r) {
        IconMakerSelected(:final iconCode) => iconCode,
        IconMakerRemoved() => null,
      },
    );
  }

  Widget _rows(List<_MakerPreset> presets) {
    return Card(
      child: SectionCard(
        first: true,
        children: [
          for (final p in presets)
            DetailRow(
              label: p.label,
              helper: p.note,
              leading: IconDisplay(
                type: p.type,
                size: 40,
                iconCode: _results[p],
              ),
              showChevron: true,
              onTap: () => _open(p),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
      children: [
        _Demo(
          title: 'ทรงพื้นหลังทั้งหมด (ขอบเปลี่ยนตามทรง)',
          name: 'IconShape · IconCode(shape:) · IconCodeWidget',
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in IconShape.values)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconCodeWidget(
                      size: 48,
                      iconCode: IconCode(
                        icon: 'shopping_basket',
                        background: 'solid',
                        bgColors: const ['#00BFA6'],
                        border: 'thick',
                        borderColors: const ['#0E7C7B'],
                        shape: s.name,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      s.label(AppLocalizations.of(context)!),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
            ],
          ),
        ),
        _Demo(
          title: 'ทุกโหมด (แตะเพื่อเปิด)',
          name:
              'showIconMakerSheet(showIcon / showBackground / showBorder · '
              'showIconPicker / showColorPicker · removeLabel)',
          child: _rows(_modePresets),
        ),
        _Demo(
          title: 'ตามที่ใช้จริงในแอป',
          name: 'ค่าเดียวกับหน้าที่เรียกใช้',
          child: _rows(_usagePresets),
        ),
      ],
    );
  }
}

// ── Edit mode ──────────────────────────────────────────────────────────

class _EditModeDemo extends StatefulWidget {
  const _EditModeDemo({
    required this.editing,
    required this.onEnterEdit,
    required this.onDelete,
  });

  final bool editing;
  final VoidCallback onEnterEdit;
  final VoidCallback onDelete;

  @override
  State<_EditModeDemo> createState() => _EditModeDemoState();
}

class _EditModeDemoState extends State<_EditModeDemo> {
  final _name = TextEditingController(text: 'Aom Chan');
  final _email = TextEditingController(text: 'aom@example.com');
  final _note = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.huge,
      ),
      children: [
        Text(
          editing
              ? 'โหมดแก้ไข: top bar เป็น ✕ (ไม่มีปุ่มของหน้า) · ส่วนที่แก้ไม่ได้จาง · ลบอยู่แถวแดงท้ายหน้า · แถบล่างเป็น ยกเลิก/↶/บันทึก'
              : 'โหมดดู: กด ✏️ บนการ์ดหัว (HeaderCard onEdit) หรือกดค้างที่ช่องข้อความเพื่อเข้าโหมดแก้ไข',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        HeaderCard(
          leading: EditableCircle(
            size: 44,
            onTap: editing
                ? () => showAppSnackBar(context, 'เปิด icon maker')
                : null,
            child: const UserAvatar(displayName: 'Aom Chan', size: 44),
          ),
          title: InlineTitleField(
            editing: editing,
            controller: _name,
            onEnterEdit: widget.onEnterEdit,
            hint: 'ชื่อ',
          ),
          subtitle: const Text('เชื่อมบัญชีแล้ว 🔗'),
          // The page's way into edit mode (no ✏️ on the top bar).
          onEdit: editing ? null : widget.onEnterEdit,
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          first: true,
          children: [
            DetailStacked(
              label: 'อีเมล',
              child: InlineField(
                editing: editing,
                controller: _email,
                onEnterEdit: widget.onEnterEdit,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            DetailStacked(
              label: 'บันทึก',
              child: InlineField(
                editing: editing,
                controller: _note,
                maxLines: 3,
                onEnterEdit: widget.onEnterEdit,
              ),
            ),
          ],
        ),
        SectionCard(
          locked: editing,
          title: 'การดำเนินการ',
          children: [
            DetailRow(
              label: 'เชื่อมกับบัญชีผู้ใช้',
              leading: const Icon(Icons.link),
              trailing: AppButton(
                label: 'ส่งคำขอ',
                variant: AppButtonVariant.text,
                onPressed: () => showAppSnackBar(context, 'ส่งคำขอแล้ว'),
              ),
            ),
            DetailRow(
              label: 'หนี้กับคนนี้',
              leading: const Icon(Icons.account_balance_outlined),
              trailing: const MoneyText(1500, tone: MoneyTone.income),
              showChevron: true,
              onTap: () => showAppSnackBar(context, 'ไปหน้าหนี้'),
            ),
            DetailRow(
              label: 'เก็บถาวร',
              leading: const Icon(Icons.archive_outlined),
              onTap: () => showAppSnackBar(context, 'เก็บถาวร'),
            ),
          ],
        ),
        // Delete lives here, only in edit mode (no 🗑 on the top bar).
        if (editing)
          DangerRow(
            icon: AppIcons.delete,
            label: 'ลบรายการนี้',
            onTap: widget.onDelete,
          ),
      ],
    );
  }
}

// ── Domain widgets ─────────────────────────────────────────────────────

class _DomainDemo extends StatefulWidget {
  const _DomainDemo();

  @override
  State<_DomainDemo> createState() => _DomainDemoState();
}

class _DomainDemoState extends State<_DomainDemo> {
  String _currency = 'THB';
  String _picked = '—';
  String? _pickedId;
  TransactionType _heroType = TransactionType.expense;
  String? _chipCategoryId;
  Set<String> _pickedTags = {};
  final _heroAmount = TextEditingController();
  final _heroNote = TextEditingController();
  final _heroViewAmount = TextEditingController(text: '1,250');
  final _heroViewNote = TextEditingController(text: 'ข้าวมันไก่');

  @override
  void dispose() {
    _heroAmount.dispose();
    _heroNote.dispose();
    _heroViewAmount.dispose();
    _heroViewNote.dispose();
    super.dispose();
  }

  static const _txs = [
    Transaction(
      id: 'demo-1',
      accountId: 'a1',
      type: TransactionType.expense,
      amount: 185,
      date: '2026-10-06',
      account: EmbeddedRef(id: 'a1', name: 'KBank'),
      category: EmbeddedRef(id: 'c-food', name: 'อาหาร'),
      note: 'ข้าวมันไก่',
      tags: [
        EmbeddedTag(
          id: 't1',
          name: 'งาน',
          iconCode: IconCode(icon: 'work_outline', iconColors: ['#0EA5E9']),
        ),
        EmbeddedTag(
          id: 't2',
          name: 'กิน',
          iconCode: IconCode(icon: 'favorite', iconColors: ['#EF4444']),
        ),
      ],
    ),
    Transaction(
      id: 'demo-2',
      accountId: 'a2',
      type: TransactionType.income,
      amount: 42000,
      date: '2026-10-05',
      account: EmbeddedRef(id: 'a2', name: 'เงินเดือน'),
      category: EmbeddedRef(id: 'c-salary', name: 'เงินเดือน'),
    ),
    Transaction(
      id: 'demo-3',
      accountId: null,
      type: TransactionType.expense,
      amount: 1240,
      date: '2026-09-28',
      note: 'หารค่าหมูกระทะ',
      hasSplits: true,
    ),
    Transaction(
      id: 'demo-4',
      accountId: 'a1',
      type: TransactionType.transfer,
      amount: 5000,
      date: '2026-09-27',
      account: EmbeddedRef(id: 'a1', name: 'KBank'),
    ),
  ];

  Future<void> _pickContact() async {
    final r = await showContactPickerSheet(
      context,
      selectedContactId: _pickedId,
    );
    if (r == null || !mounted) return;
    setState(() {
      switch (r) {
        case ContactPicked(:final contact):
          _picked = 'contact: ${contact.effectiveName}';
          _pickedId = contact.id;
        case ContactNameTyped(:final name):
          _picked = 'ชื่อพิมพ์เอง: $name';
          _pickedId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        _Demo(
          title: 'สกุลเงิน',
          name: 'CurrencyTile',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CurrencyTile(
                value: _currency,
                onChanged: (c) => setState(() => _currency = c),
              ),
              const _Gap(),
              CurrencyTile(
                value: _currency,
                onChanged: null,
                label: 'อ่านอย่างเดียว',
              ),
            ],
          ),
        ),
        _Demo(
          title:
              'การ์ดหัวรายการ (ชิปประเภท + วันที่ · ปัดซ้าย/ขวาเปลี่ยนประเภท · '
              'ค่าอะไร | ยอด) — สร้าง / ดู · แบบซ้อน (อีเวนต์ / รายการประจำ)',
          name: 'TxHeroCard',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TxHeroCard(
                type: _heroType,
                onTypeChanged: (t) => setState(() => _heroType = t),
                amount: _heroAmount,
                title: _heroNote,
                dateLabel: 'วันนี้',
                onPickDate: () => showAppSnackBar(context, 'เลือกวันที่'),
                inline: true,
              ),
              const _Gap(),
              TxHeroCard(
                type: TransactionType.expense,
                amount: _heroViewAmount,
                title: _heroViewNote,
                dateLabel: 'เมื่อวาน',
                editing: false,
                onEdit: () => showAppSnackBar(context, '✏️ เข้าโหมดแก้ไข'),
                onLongPressField: (_) =>
                    showAppSnackBar(context, 'กดค้าง → เข้าโหมดแก้ไข'),
                inline: true,
              ),
              const _Gap(),
              TxHeroCard(
                type: TransactionType.income,
                allowTransfer: false,
                onTypeChanged: (_) {},
                amount: _heroAmount,
                title: _heroNote,
                dateLabel: 'วันนี้',
              ),
            ],
          ),
        ),
        _Demo(
          title: 'ชิปหมวด (หมวดล่าสุดใน quick create — แตะเพื่อเลือก)',
          name: 'CategoryChip',
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c
                  in context
                      .watch<CategoriesCubit>()
                      .state
                      .categories
                      .where((c) => !c.isSystem && c.parentId == null)
                      .take(5))
                CategoryChip(
                  category: c,
                  selected: c.id == _chipCategoryId,
                  onTap: () => setState(() => _chipCategoryId = c.id),
                ),
            ],
          ),
        ),
        _Demo(
          title: 'เลือกแท็ก (ค้นหา · เลือกหลายอัน · + แท็กใหม่)',
          name: 'showTagPickerSheet',
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'เลือกแท็ก (${_pickedTags.length})',
              variant: AppButtonVariant.outlined,
              onPressed: () async {
                final next = await showTagPickerSheet(
                  context,
                  selected: _pickedTags,
                );
                if (next != null) setState(() => _pickedTags = next);
              },
            ),
          ),
        ),
        _Demo(
          title: 'แถวรายการ (ข้อมูลตัวอย่าง — แตะไม่เปิด)',
          name: 'TransactionTile',
          child: Card(
            child: Column(
              children: [
                for (final (i, tx) in _txs.indexed)
                  TransactionTile(
                    transaction: tx,
                    showDate: i.isEven,
                    onTap: () => showAppSnackBar(context, 'tap ${tx.id}'),
                  ),
              ],
            ),
          ),
        ),
        _Demo(
          title: 'แท็ก — แบบเต็ม · ตัวเลือก (เลือก/ไม่เลือก) · แบบย่อ',
          name: 'TagChip · TagShortList',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final t in _txs.first.tags) TagChip(tag: t.asTag),
                  const TagChip(
                    tag: Tag(id: 't0', name: 'ไม่มีไอคอน'),
                  ),
                ],
              ),
              const _Gap(),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final (i, t) in _txs.first.tags.indexed)
                    TagChip(tag: t.asTag, selected: i == 0, onTap: () {}),
                ],
              ),
              const _Gap(),
              TagShortList(
                tags: [for (final t in _txs.first.tags) t.asTag],
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const _Demo(
          title: 'สรุปช่วงเวลา (ข้อมูลจริง — ทุกบัญชี)',
          name: 'PeriodSummaryCard',
          child: PeriodSummaryCard(),
        ),
        _Demo(
          title: 'เลือกผู้ติดต่อ (ข้อมูลจริง)',
          name: 'showContactPickerSheet',
          child: PickerTile(
            label: 'กับใคร',
            value: _picked,
            leading: const Icon(AppIcons.contact),
            onTap: _pickContact,
          ),
        ),
      ],
    );
  }
}

// ── Charts ─────────────────────────────────────────────────────────────

class _ChartsDemo extends StatefulWidget {
  const _ChartsDemo();
  @override
  State<_ChartsDemo> createState() => _ChartsDemoState();
}

class _ChartsDemoState extends State<_ChartsDemo> {
  int _slices = 5;
  int? _selected = 5;

  static const _values = [6200.0, 3100.0, 2400.0, 1800.0, 6880.0];
  static const _months = [
    BarPair(label: 'พ.ค.', a: 30000, b: 21000),
    BarPair(label: 'มิ.ย.', a: 30000, b: 26500),
    BarPair(label: 'ก.ค.', a: 32000, b: 18000),
    BarPair(label: 'ส.ค.', a: 30000, b: 31200),
    BarPair(label: 'ก.ย.', a: 30000, b: 24000),
    BarPair(label: 'ต.ค.', a: 32000, b: 18580),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ChartPalette.categorical(context);
    final palette = Theme.of(context).extension<AppColors>()!;
    final segments = [
      for (var i = 0; i < _slices; i++)
        DonutSegment(
          value: _values[i],
          color: i < colors.length ? colors[i] : ChartPalette.other(context),
        ),
    ];
    return Column(
      children: [
        _Demo(
          title: 'โดนัทสัดส่วน (แตะเพื่อเปลี่ยนจำนวนชิ้น · 0 = ว่าง)',
          name: 'DonutChart · ChartPalette',
          child: GestureDetector(
            onTap: () => setState(() => _slices = (_slices + 1) % 6),
            child: Row(
              children: [
                DonutChart(segments: segments, center: Text('$_slices ชิ้น')),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final c in [...colors, ChartPalette.other(context)])
                        Container(width: 24, height: 24, color: c),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _Demo(
          title: 'แท่งคู่ รายรับ vs รายจ่าย (แตะเดือน)',
          name: 'PairedBarChart',
          child: PairedBarChart(
            groups: _months,
            colorA: palette.income,
            colorB: palette.expense,
            selected: _selected,
            onSelect: (i) => setState(() => _selected = i),
          ),
        ),
      ],
    );
  }
}

// ── Pill family demos ──────────────────────────────────────────────────

/// Sample tags for the pill demos: (name, colour, glyph).
const _demoTags = <(String, Color, IconData?)>[
  ('เที่ยว', Color(0xFF26A69A), Icons.flight_takeoff),
  ('ครอบครัว', Color(0xFFEF6C00), null),
  ('งานบริษัท', Color(0xFF5C6BC0), Icons.work_outline),
  ('ของขวัญ', Color(0xFFD81B60), null),
  ('สุขภาพ', Color(0xFF43A047), null),
];

/// A transaction row mock-up for picking the tag look (owner 2026-10-10):
/// [pills] null = today's coloured `#tag` text line (TagShortList's look),
/// otherwise mini [TagPill]s, at most [pills], then `+n`.
class _MockTxRow extends StatelessWidget {
  const _MockTxRow({required this.caption, required this.tags, this.pills});

  final String caption;
  final List<(String, Color, IconData?)> tags;
  final int? pills;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final max = pills;
    final Widget tagLine = max == null
        ? Text.rich(
            TextSpan(
              children: [
                for (final (i, (name, color, _)) in tags.indexed)
                  TextSpan(
                    text: '${i > 0 ? '  ' : ''}#$name',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            style: textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : PillOverflowRow(
            maxVisible: max,
            pills: [
              for (final (name, color, glyph) in tags)
                TagPill(name: name, color: color, glyph: glyph),
            ],
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const TintedIconBadge(
            icon: Icons.restaurant,
            tint: Color(0xFFEF6C00),
            size: 40,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ข้าวมันไก่', style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Row(children: [Flexible(child: tagLine)]),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const MoneyText(-60, tone: MoneyTone.expense),
        ],
      ),
    );
  }
}

/// The hero spacing rules made visible (owner 2026-10-10): 16 inside,
/// 12 between rows, 8 between controls, controls 32 high, nested cards
/// 12 inside with 8 between, 16 to the next block.
class _HeroSpacingDemo extends StatelessWidget {
  const _HeroSpacingDemo();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget nested(String label, String value) => Expanded(
      child: PickCard(
        label: label,
        value: value,
        leading: const PickCardEmptyIcon(AppIcons.category, size: 32),
        accent: scheme.primary,
        dense: true,
        onTap: () {},
      ),
    );
    return _Demo(
      title:
          'ระยะของ hero (ทุกการ์ดหัวหน้า): ใน 16 · ระหว่างแถว 12 · '
          'ระหว่างปุ่ม 8 · ปุ่มสูง 32 · การ์ดซ้อน ใน 12 ห่าง 8 · ถึงบล็อกถัดไป 16',
      name: 'HeroSpacing · HeroContent · HeroTopRow · PillSize.control',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.06),
              border: Border.all(color: scheme.primary, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: HeroContent(
              rows: [
                HeroTopRow(
                  leading: [
                    LabelPill(
                      label: 'ธนาคาร',
                      icon: AppIcons.bank,
                      color: scheme.primary,
                      outlined: true,
                      size: PillSize.control,
                    ),
                    LabelPill(
                      label: 'แชร์ 3 คน',
                      icon: AppIcons.link,
                      color: scheme.primary,
                      size: PillSize.control,
                    ),
                  ],
                  trailing: [
                    AppIconButton(
                      icon: AppIcons.edit,
                      size: HeroSpacing.controlHeight,
                      onPressed: () {},
                    ),
                  ],
                ),
                Text(
                  'แถวชื่อ / ยอด',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      nested('หมวดหมู่', 'อาหาร'),
                      const SizedBox(width: HeroSpacing.nestedGap),
                      nested('กระเป๋า', 'กสิกร'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: HeroSpacing.after),
          Text(
            'บล็อกถัดไป (ห่าง 16)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
