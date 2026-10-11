import 'package:flutter/material.dart';

import '../core/constants/app_icons.dart';
import '../core/constants/app_spacing.dart';
import '../shared/widgets/ui.dart';

/// /dev/widgets → "AppChip": the one chip of the app — the three sizes
/// (mini 20 · chip 28 · control 32) with every trailing, then a playground
/// with every option live.
class AppChipTab extends StatelessWidget {
  const AppChipTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        bottom: 96 + MediaQuery.paddingOf(context).bottom,
      ),
      children: const [
        _Heading('3 ขนาด × ท้ายทุกแบบ (mini 20 · chip 28 · control 32)'),
        _SizeMatrix(),
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

class AppChipPlayground extends StatefulWidget {
  const AppChipPlayground({super.key});

  @override
  State<AppChipPlayground> createState() => _AppChipPlaygroundState();
}

class _AppChipPlaygroundState extends State<AppChipPlayground> {
  AppChipTone? _tone;
  PillSize _size = PillSize.control;
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
          title('ขนาด — mini 20 · chip 28 (เสนอใหม่) · normal/control 32'),
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

// ─── Size matrix ──────────────────────────────────────────────────────

/// The proposed 3 sizes (owner review, 2026-10-11) × every trailing, with
/// the leading variants (icon / avatar / dot) and count 0 / 3 / 120.
class _SizeMatrix extends StatelessWidget {
  const _SizeMatrix();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget row(PillSize s, String name, List<Widget> chips) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '$name ${s.height.round()}',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          ...chips,
        ],
      ),
    );
    final sizes = [
      (PillSize.mini, 'mini'),
      (PillSize.chip, 'chip'),
      (PillSize.control, 'control'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final selected in [false, true]) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                selected ? 'เลือกอยู่' : 'ไม่ได้เลือก',
                style: textTheme.labelLarge,
              ),
            ),
            for (final (s, name) in sizes)
              row(s, name, [
                AppChip(label: 'อาหาร', size: s, selected: selected),
                AppChip(
                  label: 'ไอคอน',
                  icon: AppIcons.category,
                  size: s,
                  selected: selected,
                ),
                AppChip(
                  label: 'avatar',
                  leading: const UserAvatar(displayName: 'ลี'),
                  size: s,
                  selected: selected,
                ),
                AppChip(label: 'dot', dot: true, size: s, selected: selected),
                AppChip(
                  label: 'ฟิลเตอร์',
                  size: s,
                  selected: selected,
                  trailing: AppChipTrailing.dropdown,
                  onTap: () {},
                ),
                AppChip(
                  label: 'ลบได้',
                  size: s,
                  selected: selected,
                  trailing: AppChipTrailing.remove,
                  onRemove: () {},
                ),
                AppChip(
                  label: 'ล็อก',
                  size: s,
                  selected: selected,
                  trailing: AppChipTrailing.lock,
                ),
                AppChip(
                  label: 'จำนวน',
                  size: s,
                  selected: selected,
                  trailing: AppChipTrailing.count,
                  count: 3,
                ),
                AppChip(
                  label: 'จำนวน',
                  size: s,
                  selected: selected,
                  trailing: AppChipTrailing.count,
                  count: 120,
                ),
                AppChip(
                  label: 'จำนวน 0 (ไม่แสดง)',
                  size: s,
                  selected: selected,
                  trailing: AppChipTrailing.count,
                  count: 0,
                ),
              ]),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
