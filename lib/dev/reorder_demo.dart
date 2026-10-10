import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';
import '../core/constants/app_spacing.dart';
import '../shared/widgets/ui.dart';

/// Widget gallery → "จัดลำดับ": the kit's reorder mode on sample data —
/// a 3-level tree (categories) or a flat list in two groups (wallets).
/// Touch ⠿ to drag (sideways = level), tap a row for the ← ↑ ↓ → bar,
/// ▾ / ▴ to collapse, ↶ to undo.
class ReorderModeDemo extends StatefulWidget {
  const ReorderModeDemo({super.key});

  @override
  State<ReorderModeDemo> createState() => _ReorderModeDemoState();
}

const _names = {
  'food': 'อาหาร',
  'rice': 'ข้าว',
  'noodle': 'ก๋วยเตี๋ยว',
  'snack': 'ขนม',
  'cake': 'เค้ก',
  'drink': 'เครื่องดื่ม',
  'coffee': 'กาแฟ',
  'travel': 'เดินทาง',
  'bts': 'BTS',
  'taxi': 'แท็กซี่',
  'bills': 'บิล',
  'cash': 'เงินสด',
  'kbank': 'กสิกร',
  'card': 'บัตรเครดิต',
  'trip': 'ทริปญี่ปุ่น',
  'home': 'บ้าน',
};

List<OutlineItem> _tree() => const [
  OutlineItem('food', 1),
  OutlineItem('rice', 2),
  OutlineItem('noodle', 2),
  OutlineItem('snack', 2),
  OutlineItem('cake', 3),
  OutlineItem('drink', 1),
  OutlineItem('coffee', 2),
  OutlineItem('travel', 1),
  OutlineItem('bts', 2),
  OutlineItem('taxi', 2),
  OutlineItem('bills', 1),
];

List<OutlineItem> _flat() => const [
  OutlineItem('cash', 1, section: 'mine'),
  OutlineItem('kbank', 1, section: 'mine'),
  OutlineItem('card', 1, section: 'mine'),
  OutlineItem('trip', 1, section: 'shared'),
  OutlineItem('home', 1, section: 'shared'),
];

class _ReorderModeDemoState extends State<ReorderModeDemo> {
  bool _flatMode = false;
  final _scroll = ScrollController();
  final Set<String> _collapsed = {'travel'};
  late ReorderController _c = _make();

  ReorderController _make() => ReorderController(
    items: _flatMode ? _flat() : _tree(),
    maxDepth: _flatMode ? 1 : 3,
    collapsed: _collapsed,
  )..addListener(_changed);

  void _changed() => setState(() {});

  void _reset() {
    final old = _c;
    setState(() => _c = _make());
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              ChoicePill(
                label: 'ต้นไม้ 3 ระดับ',
                selected: !_flatMode,
                onTap: () {
                  _flatMode = false;
                  _reset();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              ChoicePill(
                label: 'รายการเดียว 2 กลุ่ม',
                selected: _flatMode,
                onTap: () {
                  _flatMode = true;
                  _reset();
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'ReorderController · ReorderListScope · ReorderRow · '
            'ReorderMoveBar — ⠿ ลากทันที (ซ้าย-ขวา = ระดับ) · แตะแถว = '
            'แถบ ← ↑ ↓ → · ค้างบนหมวดที่ยุบ ~0.6 วิ = กาง',
            style: textTheme.labelSmall?.copyWith(color: scheme.primary),
          ),
        ),
        Expanded(
          child: ReorderListScope(
            controller: _c,
            scrollController: _scroll,
            dropLabel: _flatMode
                ? null
                : (id) => id == null ? 'หมวดหลัก' : 'ใต้ ${_names[id]}',
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              children: _flatMode ? _flatRows() : _treeRows(),
            ),
          ),
        ),
        ReorderMoveBar(controller: _c),
        ModeActionBar(
          canUndo: _c.canUndo,
          canSave: _c.dirty,
          cancelLabel: 'รีเซ็ต',
          saveLabel: _c.dirty ? 'มีการเปลี่ยน' : 'ยังไม่เปลี่ยน',
          undoTooltip: 'ย้อนกลับ',
          onCancel: _reset,
          onUndo: _c.undo,
          onSave: _reset,
        ),
      ],
    );
  }

  List<Widget> _treeRows() => [
    for (final (i, item) in _c.visible().indexed) ...[
      if (i > 0) const RowDivider(),
      ReorderRow(
        key: ValueKey(item.id),
        id: item.id,
        child: ListRow(
          indent: (item.level - 1) * AppSpacing.xxl,
          leading: CircleAvatar(
            radius: 20,
            child: Text(_names[item.id]!.characters.first),
          ),
          title: _names[item.id]!,
          subtitle: 'ระดับ ${item.level}',
          trailing: _c.hasChildren(item.id)
              ? IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    _c.isCollapsed(item.id)
                        ? AppIcons.expand
                        : AppIcons.collapse,
                  ),
                  onPressed: () => _c.toggleCollapsed(item.id),
                )
              : null,
        ),
      ),
    ],
  ];

  List<Widget> _flatRows() => [
    for (final (title, section) in [
      ('ของฉัน', 'mine'),
      ('กระเป๋าร่วม', 'shared'),
    ]) ...[
      SectionHeader(
        title: title,
        count: _c.visible(section: section).length,
      ),
      for (final item in _c.visible(section: section))
        ReorderRow(
          key: ValueKey(item.id),
          id: item.id,
          child: ListRow(
            leading: const CircleAvatar(
              radius: 20,
              child: Icon(AppIcons.wallet),
            ),
            title: _names[item.id]!,
          ),
        ),
    ],
  ];
}
