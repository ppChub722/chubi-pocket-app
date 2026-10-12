import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// The AppInput redesign PROPOSAL, on the owner's rule (2026-10-12):
///
///   anything editable has a FRAME; the only exception is editing INSIDE a
///   card (hero / quick-create / draft card), which uses an underline.
///
/// Three looks — **Field** (framed), **In-card** (underline) and **Search**
/// (capsule) — and data TYPES that layer on them (Amount, Number, Percent,
/// Reference). View mode on a detail page is plain text, not an input; a
/// locked 🔒 row has no frame. Nothing in the app changes until the owner
/// adopts it; "Current" is the real [AppInput], "Proposed" a hub-only
/// prototype ([_P]).
class InputProposalSection extends StatelessWidget {
  const InputProposalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _Banner(),
        _Inventory(),
        _Proposal(),
        _Mapping(),
        _FieldText(),
        _FieldTypes(),
        _CardMatrix(),
        _SearchMatrix(),
        _ViewMode(),
      ],
    );
  }
}

// ── Text blocks ──────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        'PROPOSAL — not adopted. The rule: anything editable has a FRAME; the '
        'only exception is editing inside a card, which uses an underline. '
        'AppInput today: 4 kinds × 5 looks (9 distinct renderings in 79 call '
        'sites). Proposed: 3 looks (Field · In-card · Search) + 4 data types. '
        'Use the toolbar (theme / mode / language / text scale) to check '
        'every theme.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _Row3 extends StatelessWidget {
  const _Row3(this.a, this.b, this.c, {this.head = false});
  final String a;
  final String b;
  final String c;
  final bool head;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = head ? text.labelMedium : text.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              a,
              style: style?.copyWith(
                fontWeight: head ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          Expanded(flex: 2, child: Text(b, style: style)),
          Expanded(flex: 6, child: Text(c, style: style)),
        ],
      ),
    );
  }
}

class _Inventory extends StatelessWidget {
  const _Inventory();

  @override
  Widget build(BuildContext context) {
    return const HubDemo(
      title: '1 · Inventory — what is in the app today',
      note: 'Counted from every call site (lib/features + lib/ui).',
      child: Column(
        children: [
          _Row3('Kind / look', 'Uses', 'Where · why it differs', head: true),
          _Row3(
            'field · filled (theme)',
            '36',
            'Forms (login, register, contact, project, debt, scheduled, '
                'adjust balance) — the theme\'s filled box + floating label. '
                '1 of these is the hero card\'s description.',
          ),
          _Row3(
            'field · outlined',
            '4',
            'Small boxes edited in place: tag name, event amount, icon-maker '
                'name, split-row typed name. Dense, no label.',
          ),
          _Row3(
            'field · underline',
            '1',
            'An account identifier (reference) number.',
          ),
          _Row3(
            'field · bare',
            '3',
            'No chrome: hero amount, split amount, chat dial.',
          ),
          _Row3(
            'inline (view ⇄ edit)',
            '17',
            'Detail-page values: plain in view, long-press, outlined in edit.',
          ),
          _Row3(
            'title (view ⇄ edit)',
            '8',
            'A hero\'s name: plain in view, underlined in edit.',
          ),
          _Row3(
            'search · default / pill',
            '9 / 1',
            'List pages: outlined box; picker sheet: grey capsule.',
          ),
        ],
      ),
    );
  }
}

class _Proposal extends StatelessWidget {
  const _Proposal();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget item(String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleSmall),
          Text(body, style: text.bodySmall),
        ],
      ),
    );
    return HubDemo(
      title: '2 · Proposal — three looks, four data types',
      note:
          'States on every look: empty / placeholder (faint), focused, filled, '
          'error + message, disabled, read-only / locked 🔒 (no frame), '
          'counter, prefix / suffix, multiline.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          item(
            'Field — framed',
            'Outlined box, 12 radius. Floating label optional (no label = a '
                'framed box + placeholder, which is what "Value" was); `dense` '
                'for in-row. Used for all forms, detail pages in EDIT mode, the '
                'split-row name / amount, the chat input, the reference number.',
          ),
          item(
            'In-card — underline, no frame',
            'Only for editing inside a card: hero title / amount, the '
                'quick-create / draft card ("what for?" + ฿). Focused = primary '
                'underline, error = red underline + message.',
          ),
          item(
            'Search — the capsule',
            'One grey pill, 🔍 and ✕, one height on lists and sheets.',
          ),
          item(
            'View mode & locked',
            'A detail page in view mode is plain text, not an input. A locked '
                '🔒 row is plain text + 🔒, no frame.',
          ),
          item(
            'Data types (layer on the looks, not looks)',
            'Amount — the user\'s single currency symbol stuck to the number, '
                'numeric keyboard, thousands separators, right-aligned, optional '
                'quick fills. Number — right-aligned. Percent — % suffix, '
                '0–100. Reference — digits only, unformatted, left-aligned. '
                'Amount and Number apply to both Field and In-card; Percent and '
                'Reference to Field.',
          ),
        ],
      ),
    );
  }
}

class _Mapping extends StatelessWidget {
  const _Mapping();

  @override
  Widget build(BuildContext context) {
    return const HubDemo(
      title: '3 · Mapping — each current use → its new look',
      child: Column(
        children: [
          _Row3('Current', 'Uses', 'Proposed', head: true),
          _Row3('field · filled (forms)', '35', 'Field'),
          _Row3('field · outlined', '4', 'Field · dense'),
          _Row3('field · underline (reference no.)', '1', 'Field · Reference'),
          _Row3(
            'field · bare — split amount, chat',
            '2',
            'Field · dense (Amount / no label)',
          ),
          _Row3(
            'inline (edit mode)',
            '17',
            'Field · dense; view mode = plain text',
          ),
          _Row3('title', '8', 'In-card'),
          _Row3(
            'hero amount + hero description',
            '2',
            'In-card · Amount / text',
          ),
          _Row3('search default + pill', '10', 'Search'),
          _Row3('Total', '79', '3 looks, 4 data types, 1 flag (dense)'),
        ],
      ),
    );
  }
}

// ── Matrix helpers ───────────────────────────────────────────────────────────

class _StateRow extends StatelessWidget {
  const _StateRow({
    required this.state,
    required this.current,
    required this.proposed,
    this.note,
  });

  final String state;
  final Widget current;
  final Widget proposed;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(state, style: text.labelLarge),
          if (note != null)
            Text(
              note!,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Cell('Current', current)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _Cell('Proposed', proposed, accent: true)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.caption, this.child, {this.accent = false});
  final String caption;
  final Widget child;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          caption,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: accent ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        child,
      ],
    );
  }
}

/// A caption where today has nothing to show.
class _None extends StatelessWidget {
  const _None(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontStyle: FontStyle.italic,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

enum _S { empty, focused, filled, error, disabled, locked }

const _stateNames = {
  _S.empty: 'Empty — placeholder',
  _S.focused: 'Focused',
  _S.filled: 'Filled',
  _S.error: 'Error + message',
  _S.disabled: 'Disabled',
  _S.locked: 'Read-only / locked 🔒',
};

enum _T { text, amount, number, percent, reference }

class _Sample {
  const _Sample(this.label, this.hint, this.filled, this.error);
  final String label;
  final String hint;
  final String filled;
  final String error;
}

const _samples = {
  _T.text: _Sample('Name', 'Placeholder', 'Aom Chan', 'Required'),
  _T.amount: _Sample('Amount', '0', '1,250', 'Enter an amount'),
  _T.number: _Sample('Quantity', '0', '12', 'Enter a number'),
  _T.percent: _Sample('Rate', '0', '7', 'Enter 0–100'),
  _T.reference: _Sample(
    'Reference no.',
    '0000000000',
    '0123456789',
    'Digits only',
  ),
};

/// The six states of one look × type, Current vs Proposed.
List<Widget> _states({
  required _Look look,
  required _T type,
  required Widget Function(_S) current,
  Set<_S> skip = const {},
}) {
  return [
    for (final s in _S.values)
      if (!skip.contains(s))
        _StateRow(
          state: _stateNames[s]!,
          current: current(s),
          proposed: _P(look: look, type: type, state: s),
        ),
  ];
}

class _Matrix extends StatelessWidget {
  const _Matrix({required this.title, required this.note, required this.rows});
  final String title;
  final String note;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => HubDemo(
    title: title,
    note: note,
    child: Column(children: rows),
  );
}

/// The current AppInput standing in for [s] (null controller text per state).
Widget _current({required _S s, required _T type, required _Look look}) {
  final sample = _samples[type]!;
  if (s == _S.locked) {
    return const _None('Today: readOnly only stops typing — no locked look.');
  }
  final text = s == _S.empty || s == _S.focused ? '' : sample.filled;
  final c = TextEditingController(text: text);
  final enabled = s != _S.disabled;
  final error = s == _S.error ? sample.error : null;
  final numeric = type != _T.text && type != _T.reference;
  if (look == _Look.card) {
    if (type == _T.text) {
      if (s == _S.error) return const _None('Today: a title shows no error.');
      return AppInput.title(editing: true, controller: c, hint: 'Name');
    }
    return AppInput(
      look: AppInputLook.bare,
      controller: c,
      hint: sample.hint,
      enabled: enabled,
      textAlign: TextAlign.end,
      prefixText: type == _T.amount ? '฿ ' : null,
      keyboardType: numeric ? TextInputType.number : null,
      errorText: error,
    );
  }
  return AppInput(
    controller: c,
    label: sample.label,
    hint: sample.hint,
    enabled: enabled,
    errorText: error,
    textAlign: numeric ? TextAlign.end : TextAlign.start,
    prefixText: type == _T.amount ? '฿ ' : null,
    suffix: type == _T.percent
        ? const Padding(padding: EdgeInsets.only(right: 12), child: Text('%'))
        : null,
    keyboardType: numeric ? TextInputType.number : null,
    inputFormatters: type == _T.reference
        ? [FilteringTextInputFormatter.digitsOnly]
        : null,
  );
}

// ── Field ────────────────────────────────────────────────────────────────────

class _FieldText extends StatelessWidget {
  const _FieldText();

  @override
  Widget build(BuildContext context) {
    TextEditingController c([String t = '']) => TextEditingController(text: t);
    return _Matrix(
      title: '4 · Field — framed, text',
      note:
          'Both columns are live: tap to focus. Today a text field is the '
          'theme-filled AppInput; the proposal draws every state the same way.',
      rows: [
        ..._states(
          look: _Look.field,
          type: _T.text,
          current: (s) => _current(s: s, type: _T.text, look: _Look.field),
        ),
        _StateRow(
          state: 'No label — a framed box + placeholder',
          note: 'This is the old "Value": split amount, chat input.',
          current: AppInput(look: AppInputLook.outlined, hint: 'Placeholder'),
          proposed: const _P(
            look: _Look.field,
            type: _T.text,
            state: _S.empty,
            noLabel: true,
          ),
        ),
        _StateRow(
          state: 'Counter',
          current: AppInput(
            label: 'Note',
            controller: c('Lunch with the team'),
            maxLength: 50,
            showCounter: true,
          ),
          proposed: const _P(
            look: _Look.field,
            type: _T.text,
            state: _S.filled,
            custom: 'Lunch with the team',
            label: 'Note',
            max: 50,
          ),
        ),
        _StateRow(
          state: 'Prefix · suffix',
          current: AppInput(
            label: 'Website',
            controller: c('chubi'),
            prefixText: 'https://',
            suffix: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Text('.com'),
            ),
          ),
          proposed: const _P(
            look: _Look.field,
            type: _T.text,
            state: _S.filled,
            custom: 'chubi',
            label: 'Website',
            prefix: 'https://',
            suffix: '.com',
          ),
        ),
        _StateRow(
          state: 'Multiline',
          current: AppInput(
            label: 'Description',
            controller: c('Line one\nLine two'),
            minLines: 3,
            maxLines: 5,
          ),
          proposed: const _P(
            look: _Look.field,
            type: _T.text,
            state: _S.filled,
            custom: 'Line one\nLine two',
            label: 'Description',
            multiline: true,
          ),
        ),
        _StateRow(
          state: 'Dense (in-row / detail edit mode)',
          current: AppInput(controller: c('Food'), look: AppInputLook.outlined),
          proposed: const _P(
            look: _Look.field,
            type: _T.text,
            state: _S.filled,
            custom: 'Food',
            noLabel: true,
            dense: true,
          ),
        ),
      ],
    );
  }
}

class _FieldTypes extends StatelessWidget {
  const _FieldTypes();

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    void group(
      String name,
      String rule,
      _T type, {
      List<Widget> extra = const [],
    }) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            '$name — $rule',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      );
      rows.addAll(
        _states(
          look: _Look.field,
          type: type,
          current: (s) => _current(s: s, type: type, look: _Look.field),
        ),
      );
      rows.addAll(extra);
    }

    group(
      'Amount',
      'currency symbol stuck to the number, thousands, right-aligned',
      _T.amount,
      extra: [
        _StateRow(
          state: 'Amount · with quick fills',
          current: AmountInput(
            controller: TextEditingController(text: '500'),
            quickFills: const [
              AmountQuickFill(label: '+100', amount: 100),
              AmountQuickFill(label: '+500', amount: 500),
            ],
          ),
          proposed: const _P(
            look: _Look.field,
            type: _T.amount,
            state: _S.filled,
            custom: '500',
            quickFills: true,
          ),
        ),
      ],
    );
    group('Number', 'right-aligned', _T.number);
    group('Percent', '% suffix, 0–100', _T.percent);
    group(
      'Reference number',
      'digits only, unformatted, left-aligned',
      _T.reference,
    );
    return _Matrix(
      title: '5 · Field — data types',
      note:
          'Each type on the Field look, every state. Today only Amount is a '
          'kit type (AmountInput); the others are an AppInput with a keyboard '
          'type and a formatter.',
      rows: rows,
    );
  }
}

// ── In-card ──────────────────────────────────────────────────────────────────

class _CardMatrix extends StatelessWidget {
  const _CardMatrix();

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    void group(String name, _T type) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(name, style: Theme.of(context).textTheme.titleSmall),
        ),
      );
      rows.addAll(
        _states(
          look: _Look.card,
          type: type,
          current: (s) => _current(s: s, type: type, look: _Look.card),
        ),
      );
    }

    group('Hero title / "what for?" (text)', _T.text);
    group('Hero amount (฿)', _T.amount);
    group('Number in a card', _T.number);
    return _Matrix(
      title: '6 · In-card — an underline, no frame',
      note:
          'Only for editing inside a card: the hero, the quick-create / draft '
          'card. Percent and Reference do not apply here (they live in '
          'forms).',
      rows: rows,
    );
  }
}

// ── Search ───────────────────────────────────────────────────────────────────

class _SearchMatrix extends StatelessWidget {
  const _SearchMatrix();

  @override
  Widget build(BuildContext context) {
    return _Matrix(
      title: '7 · Search — the capsule',
      note: 'One capsule, one height, on lists and in sheets.',
      rows: [
        _StateRow(
          state: 'Empty',
          current: AppInput.search(onChanged: (_) {}),
          proposed: const _P(
            look: _Look.search,
            type: _T.text,
            state: _S.empty,
          ),
        ),
        _StateRow(
          state: 'Pill today (picker sheet)',
          current: AppInput.search(look: AppInputLook.pill, onChanged: (_) {}),
          proposed: const _P(
            look: _Look.search,
            type: _T.text,
            state: _S.empty,
          ),
        ),
        _StateRow(
          state: 'Focused',
          current: AppInput.search(onChanged: (_) {}),
          proposed: const _P(
            look: _Look.search,
            type: _T.text,
            state: _S.focused,
          ),
        ),
        _StateRow(
          state: 'Filled (✕ clears)',
          current: AppInput.search(
            controller: TextEditingController(text: 'coffee'),
            onChanged: (_) {},
          ),
          proposed: const _P(
            look: _Look.search,
            type: _T.text,
            state: _S.filled,
            custom: 'coffee',
          ),
        ),
        const _StateRow(
          state: 'Disabled',
          note: 'Today: no disabled state.',
          current: _None('—'),
          proposed: _P(look: _Look.search, type: _T.text, state: _S.disabled),
        ),
      ],
    );
  }
}

// ── View mode ────────────────────────────────────────────────────────────────

class _ViewMode extends StatelessWidget {
  const _ViewMode();

  @override
  Widget build(BuildContext context) {
    return _Matrix(
      title: '8 · View mode — plain text, not an input',
      note:
          'A detail page in view mode shows text (long-press → edit mode = a '
          'Field · dense). Today the inline input is a read-only TextField '
          'under a transparent border.',
      rows: [
        _StateRow(
          state: 'Filled',
          current: AppInput.inline(
            editing: false,
            controller: TextEditingController(text: 'Lunch with the team'),
          ),
          proposed: const _ViewText(text: 'Lunch with the team'),
        ),
        _StateRow(
          state: 'Empty (editable) — faint hint',
          current: AppInput.inline(
            editing: false,
            controller: TextEditingController(),
            onEnterEdit: () {},
            viewHint: 'Long-press to edit',
          ),
          proposed: const _ViewText(hint: 'Long-press to edit'),
        ),
        const _StateRow(
          state: 'Locked 🔒 — no frame',
          note: 'Today: no locked state.',
          current: _None('—'),
          proposed: _ViewText(text: 'Salary', locked: true),
        ),
      ],
    );
  }
}

class _ViewText extends StatelessWidget {
  const _ViewText({this.text = '', this.hint, this.locked = false});
  final String text;
  final String? hint;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: text.isEmpty
                ? Text(
                    hint ?? '',
                    style: style?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  )
                : Text(text, style: style),
          ),
          if (locked)
            Icon(AppIcons.lock, size: 16, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

// ── The prototype ────────────────────────────────────────────────────────────

enum _Look { field, card, search }

/// Hub-only prototype of the proposed AppInput: ONE build for the three looks
/// and the data types. [state] forces the focused / error / disabled / locked
/// drawing so it can be seen without tapping (the field is live too).
class _P extends StatefulWidget {
  const _P({
    required this.look,
    required this.type,
    required this.state,
    this.custom,
    this.label,
    this.noLabel = false,
    this.dense = false,
    this.multiline = false,
    this.max,
    this.prefix,
    this.suffix,
    this.quickFills = false,
  });

  final _Look look;
  final _T type;
  final _S state;

  /// Overrides the sample text.
  final String? custom;
  final String? label;
  final bool noLabel;
  final bool dense;
  final bool multiline;
  final int? max;
  final String? prefix;
  final String? suffix;
  final bool quickFills;

  @override
  State<_P> createState() => _PState();
}

class _PState extends State<_P> {
  late final TextEditingController _c;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    final sample = _samples[widget.type]!;
    final s = widget.state;
    _c = TextEditingController(
      text:
          widget.custom ??
          (s == _S.empty || s == _S.focused ? '' : sample.filled),
    );
    _focus.addListener(() => setState(() {}));
    _c.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _focused => widget.state == _S.focused || _focus.hasFocus;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final sample = _samples[w.type]!;
    final faint = scheme.onSurfaceVariant.withValues(alpha: 0.4);
    final locked = w.state == _S.locked;
    final enabled = w.state != _S.disabled;
    final error = w.state == _S.error ? sample.error : null;
    final isCard = w.look == _Look.card;
    final numeric = w.type != _T.text && w.type != _T.reference;
    final align = numeric ? TextAlign.end : TextAlign.start;
    final label = w.noLabel || isCard ? null : (w.label ?? sample.label);

    // ── Locked: plain text + 🔒, no frame.
    if (locked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null)
            Text(
              label,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          _ViewText(
            text:
                '${w.type == _T.amount ? '฿' : ''}${w.custom ?? sample.filled}'
                '${w.type == _T.percent ? ' %' : ''}',
            locked: true,
          ),
        ],
      );
    }

    // ── Search: the capsule.
    if (w.look == _Look.search) {
      return SizedBox(
        height: 40,
        child: TextField(
          controller: _c,
          focusNode: _focus,
          enabled: enabled,
          style: text.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: text.bodyMedium?.copyWith(color: faint),
            isDense: true,
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(
              alpha: enabled ? 1 : 0.5,
            ),
            prefixIcon: const Icon(AppIcons.search, size: 18),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            suffixIcon: _c.text.isEmpty
                ? null
                : InkResponse(
                    onTap: _c.clear,
                    child: const Icon(AppIcons.close, size: 18),
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: _outline(Colors.transparent, 0, 20),
            enabledBorder: _outline(Colors.transparent, 0, 20),
            focusedBorder: _outline(scheme.primary, 1.5, 20),
            disabledBorder: _outline(Colors.transparent, 0, 20),
          ),
        ),
      );
    }

    // ── Field / In-card: ONE decorator, bare text inside.
    final big = isCard && w.type == _T.amount;
    final style =
        (big
                ? text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)
                : isCard
                ? text.titleMedium
                : text.bodyLarge)
            ?.copyWith(
              fontFeatures: numeric
                  ? const [FontFeature.tabularFigures()]
                  : null,
            );
    final symbol = w.type == _T.amount ? '฿' : null;
    final suffixText = w.suffix ?? (w.type == _T.percent ? '%' : null);
    final inputs = <TextInputFormatter>[
      if (w.type == _T.amount) ThousandsInputFormatter(),
      if (w.type == _T.reference) FilteringTextInputFormatter.digitsOnly,
      if (w.type == _T.number)
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      if (w.type == _T.percent) _Range(0, 100),
    ];
    final hint = isCard && w.type == _T.text ? 'What for?' : sample.hint;
    final inner = TextField(
      controller: _c,
      focusNode: _focus,
      enabled: enabled,
      style: style,
      textAlign: align,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : (w.type == _T.reference ? TextInputType.number : null),
      inputFormatters: inputs,
      minLines: w.multiline ? 3 : 1,
      maxLines: w.multiline ? 5 : 1,
      maxLength: w.max,
      decoration: numeric
          ? InputDecoration.collapsed(
              hintText: hint,
              hintStyle: style?.copyWith(color: faint),
            ).copyWith(counterText: '')
          // Text: the field's own prefix / suffix (they fill the frame).
          : InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: style?.copyWith(color: faint),
              prefixText: w.prefix,
              suffixText: suffixText,
              prefixStyle: style,
              suffixStyle: style,
              counterText: '',
            ),
    );
    // The symbol / prefix stick to the number: a Row hugging the text width,
    // pushed right for numbers.
    Widget content = inner;
    if (numeric && (symbol != null || w.prefix != null || suffixText != null)) {
      final affix = style?.copyWith(
        color: enabled
            ? scheme.onSurface
            : scheme.onSurface.withValues(alpha: 0.4),
      );
      final hasLead = symbol != null || w.prefix != null;
      final lead = Text('${symbol ?? ''}${w.prefix ?? ''}', style: affix);
      // Numbers hug their symbol and sit at the right; text fills the frame.
      final row = numeric
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasLead) lead,
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 12),
                    child: IntrinsicWidth(child: inner),
                  ),
                ),
                if (suffixText != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(suffixText, style: affix),
                  ),
              ],
            )
          : Row(
              children: [
                if (hasLead) lead,
                Expanded(child: inner),
                if (suffixText != null) Text(suffixText, style: affix),
              ],
            );
      content = numeric
          ? Align(alignment: Alignment.centerRight, child: row)
          : row;
    }

    InputBorder border(Color c, double wd) => isCard
        ? UnderlineInputBorder(
            borderSide: BorderSide(color: c, width: wd),
          )
        : _outline(c, wd, 12);
    final idle = scheme.outlineVariant;
    final decorator = InputDecorator(
      isFocused: _focused,
      isEmpty: _c.text.isEmpty,
      baseStyle: style,
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        enabled: enabled,
        isDense: true,
        counterText: w.max == null ? null : '${_c.text.length}/${w.max}',
        filled: !isCard && !enabled,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: isCard
            ? const EdgeInsets.symmetric(vertical: AppSpacing.xs)
            : EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: w.dense ? 10 : 14,
              ),
        border: border(idle, 1),
        enabledBorder: border(idle, 1),
        focusedBorder: border(scheme.primary, 2),
        errorBorder: border(scheme.error, 1),
        focusedErrorBorder: border(scheme.error, 2),
        disabledBorder: border(idle.withValues(alpha: 0.5), 1),
      ),
      child: content,
    );
    if (!w.quickFills) return decorator;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        decorator,
        const SizedBox(height: AppSpacing.xs),
        const Wrap(
          spacing: AppSpacing.xs,
          children: [
            AppChip(label: '+100', size: ChipSize.mini),
            AppChip(label: '+500', size: ChipSize.mini),
            AppChip(label: '+1,000', size: ChipSize.mini),
          ],
        ),
      ],
    );
  }

  static OutlineInputBorder _outline(Color c, double wd, double r) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide: BorderSide(color: c, width: wd),
      );
}

/// Keeps an integer within [min]..[max] while typing (the Percent type).
class _Range extends TextInputFormatter {
  _Range(this.min, this.max);
  final int min;
  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final n = int.parse(digits).clamp(min, max);
    final out = '$n';
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
