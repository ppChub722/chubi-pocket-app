import 'package:flutter/material.dart';

import '../ui/ui.dart';

/// Storybook-style CONTROLS for a hub page (owner 2026-10-12): a live
/// instance on top, typed controls generated from the widget's REAL options
/// below. Only expose options the widget really has — no fake knobs.
///
/// ```dart
/// HubPlayground(
///   title: 'AppCard',
///   controls: [
///     PlayChoice<AppCardStyle>('style', AppCardStyle.values.map((s) => (s.name, s))),
///     PlayBool('selected'),
///     PlayNum('padding', min: 0, max: 32, step: 4, initial: 16),
///   ],
///   builder: (context, v) => AppCard(style: v<AppCardStyle>('style'), …),
/// )
/// ```
///
/// It follows the global toolbar (theme / mode / language / text scale): the
/// preview is built under the page's own Theme, so a toolbar change re-draws
/// it. Below the playground a page lists "In the app" ([HubInApp]) — the
/// real presets, each labelled with the page that uses it.
class HubPlayground extends StatefulWidget {
  const HubPlayground({
    required this.controls,
    required this.builder,
    this.title = 'Playground',
    this.note,
    this.hug,
    super.key,
  });

  /// Non-null = the live instance HUGS its content (a pill, a button, a chip)
  /// and is placed at this alignment; null = it fills the frame's width (a
  /// card, a banner, an input). The frame is a stretched column: without this
  /// a pill would be forced to the full width.
  final Alignment? hug;

  final String title;
  final String? note;
  final List<PlayControl> controls;

  /// Builds the live instance from the current values.
  final Widget Function(BuildContext context, PlayValues values) builder;

  @override
  State<HubPlayground> createState() => _HubPlaygroundState();
}

class _HubPlaygroundState extends State<HubPlayground> {
  late Map<String, Object?> _v = _initial();

  Map<String, Object?> _initial() => {
    for (final c in widget.controls) c.name: c.initial,
  };

  void _set(String name, Object? value) =>
      setState(() => _v = {..._v, name: value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // Collapsible, CLOSED by default (owner 2026-10-12): the real examples
    // lead the page ("In the app"); the controls are for fully custom tweaks.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            maintainState: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            leading: const Icon(Icons.tune),
            title: Text('Customize · ${widget.title}', style: text.titleSmall),
            subtitle: Text(
              'Live instance + controls, for fully custom tweaks',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(widget.title, style: text.titleMedium),
                      ),
                      AppChip(
                        icon: AppIcons.reset,
                        label: 'Reset',
                        size: ChipSize.control,
                        onTap: () => setState(() => _v = _initial()),
                      ),
                    ],
                  ),
                  if (widget.note != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.note!,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  // The live instance.
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: widget.hug == null
                        ? widget.builder(context, PlayValues._(_v))
                        : Align(
                            alignment: widget.hug!,
                            child: widget.builder(context, PlayValues._(_v)),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // The controls.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        for (final c in widget.controls)
                          _ControlRow(
                            control: c,
                            value: _v[c.name],
                            onChanged: (x) => _set(c.name, x),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The current values: `v<T>('name')`.
class PlayValues {
  const PlayValues._(this._v);
  final Map<String, Object?> _v;

  T call<T>(String name) => _v[name] as T;
}

/// One control. [name] is the widget option it drives.
sealed class PlayControl {
  const PlayControl(this.name);
  final String name;
  Object? get initial;
}

/// One of a few labelled values — an enum, a tone, a colour: shown as chips.
class PlayChoice<T> extends PlayControl {
  PlayChoice(super.name, Iterable<(String, T)> options, {T? initial})
    : options = options.toList(),
      _initial = initial;

  final List<(String, T)> options;
  final T? _initial;

  @override
  Object? get initial => _initial ?? options.first.$2;
}

/// An on / off option — a switch.
class PlayBool extends PlayControl {
  const PlayBool(super.name, {this.initialValue = false});
  final bool initialValue;

  @override
  Object? get initial => initialValue;
}

/// A free text option.
class PlayText extends PlayControl {
  const PlayText(super.name, {this.initialValue = ''});
  final String initialValue;

  @override
  Object? get initial => initialValue;
}

/// A number / size: a − + stepper for a short range, a slider for a long one.
class PlayNum extends PlayControl {
  const PlayNum(
    super.name, {
    required this.min,
    required this.max,
    this.step = 1,
    required this.initialValue,
  });
  final double min;
  final double max;
  final double step;
  final double initialValue;

  @override
  Object? get initial => initialValue;
}

class _ControlRow extends StatefulWidget {
  const _ControlRow({
    required this.control,
    required this.value,
    required this.onChanged,
  });

  final PlayControl control;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  State<_ControlRow> createState() => _ControlRowState();
}

class _ControlRowState extends State<_ControlRow> {
  TextEditingController? _text;

  @override
  void dispose() {
    _text?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.control;
    final scheme = Theme.of(context).colorScheme;
    final label = SizedBox(
      width: 96,
      child: Text(
        c.name,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontFamily: 'monospace',
        ),
      ),
    );
    final Widget control;
    switch (c) {
      case PlayChoice():
        control = Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (name, value) in c.options)
              AppChip(
                label: name,
                size: ChipSize.control,
                selected: widget.value == value,
                onTap: () => widget.onChanged(value),
              ),
          ],
        );
      case PlayBool():
        control = Align(
          alignment: Alignment.centerLeft,
          child: AppSwitch(
            value: widget.value as bool,
            semanticLabel: c.name,
            onChanged: widget.onChanged,
          ),
        );
      case PlayText():
        _text ??= TextEditingController(text: widget.value as String);
        control = AppInput(controller: _text, onChanged: widget.onChanged);
      case PlayNum():
        final v = widget.value as double;
        final steps = (c.max - c.min) / c.step;
        control = steps > 8
            ? Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: v.clamp(c.min, c.max),
                      min: c.min,
                      max: c.max,
                      divisions: steps.round(),
                      onChanged: widget.onChanged,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  AppIconButton.flat(
                    icon: Icons.remove,
                    dense: true,
                    onPressed: v <= c.min
                        ? null
                        : () => widget.onChanged(
                            (v - c.step).clamp(c.min, c.max),
                          ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AppIconButton.flat(
                    icon: Icons.add,
                    dense: true,
                    onPressed: v >= c.max
                        ? null
                        : () => widget.onChanged(
                            (v + c.step).clamp(c.min, c.max),
                          ),
                  ),
                ],
              );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          label,
          Expanded(child: control),
        ],
      ),
    );
  }
}

/// "In the app" — the real presets, each labelled with the page that uses it.
class HubInApp extends StatelessWidget {
  const HubInApp({
    required this.uses,
    this.note,
    this.columns = 1,
    this.title = 'In the app',
    super.key,
  });

  /// The heading (default "In the app").
  final String title;

  /// Examples per row (1 by default — safe for wide pieces; pass 2–3 for
  /// small variants so they sit SIDE BY SIDE; a [HubUse.wide] one takes a whole
  /// row).
  final int columns;
  final List<HubUse> uses;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: text.titleMedium),
          if (note != null)
            Text(
              note!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          const SizedBox(height: AppSpacing.md),
          // Many real examples SIDE BY SIDE (owner 2026-10-12), so the
          // differences read at a glance: [columns] per row, each labelled
          // with what differs and the page that uses it.
          LayoutBuilder(
            builder: (context, c) {
              const gap = AppSpacing.md;
              final cols = columns.clamp(1, 4);
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: AppSpacing.lg,
                children: [
                  for (final u in uses)
                    SizedBox(
                      width: u.wide ? c.maxWidth : w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(u.label, style: text.labelLarge),
                          const SizedBox(height: AppSpacing.xxs),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AppChip(label: u.page, size: ChipSize.mini),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          u.child,
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One real preset: what it is, the page that uses it, and the widget.
class HubUse {
  const HubUse({
    required this.label,
    required this.page,
    required this.child,
    this.wide = false,
  });

  /// Takes a whole row (a full-width banner, a form).
  final bool wide;
  final String label;
  final String page;
  final Widget child;
}

/// A heading that splits a page into "Playground" and "In the app".
class HubSubheading extends StatelessWidget {
  const HubSubheading(this.text, {this.note, super.key});

  final String text;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: t.titleLarge),
          if (note != null)
            Text(
              note!,
              style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          const SizedBox(height: AppSpacing.xs),
          Divider(color: scheme.outlineVariant, height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Holds one value for a playground instance that edits itself (a stepper
/// that steps, a toggle that toggles): `builder(context, value, set)`.
class HubStateful<T> extends StatefulWidget {
  const HubStateful({required this.initial, required this.builder, super.key});

  final T initial;
  final Widget Function(BuildContext context, T value, ValueChanged<T> set)
  builder;

  @override
  State<HubStateful<T>> createState() => _HubStatefulState<T>();
}

class _HubStatefulState<T> extends State<HubStateful<T>> {
  late T _v = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _v, (x) => setState(() => _v = x));
}

/// Holds a [TextEditingController] for a playground instance.
class HubWithController extends StatefulWidget {
  const HubWithController({
    required this.builder,
    this.initial = '',
    super.key,
  });

  final String initial;
  final Widget Function(BuildContext context, TextEditingController c) builder;

  @override
  State<HubWithController> createState() => _HubWithControllerState();
}

class _HubWithControllerState extends State<HubWithController> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _c);
}
