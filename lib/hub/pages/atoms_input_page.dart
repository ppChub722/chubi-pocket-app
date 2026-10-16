import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_playground.dart';

/// `/dev/ui/atoms/input` — the one text input: the Field (one outlined frame),
/// its data types, In-card (underline), view ⇄ edit values, search.
Widget buildInputPage(BuildContext context) => const _InputPage();

class _InputPage extends StatefulWidget {
  const _InputPage();

  @override
  State<_InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<_InputPage> {
  final _note = TextEditingController();
  final _title = TextEditingController(text: 'ข้าวมันไก่');
  bool _editing = false;

  @override
  void dispose() {
    _note.dispose();
    _title.dispose();
    super.dispose();
  }

  Widget _filled(String initial, Widget Function(TextEditingController c) b) =>
      HubWithController(initial: initial, builder: (context, c) => b(c));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubInApp(
          columns: 2,
          note:
              'THE Field: anything editable has a frame — one outlined box, no '
              'fill, the label (optional) notched on the border. empty = muted '
              'outline + faint placeholder · focused = primary · filled = '
              'neutral · error = red + message · disabled = dimmed · locked 🔒 '
              '= no frame.',
          uses: [
            const HubUse(
              label: 'Empty — label + placeholder',
              page: 'Forms: contact, project, debt',
              child: PpForgeInput(label: 'Name', hint: 'Wallet name'),
            ),
            HubUse(
              label: 'Filled',
              page: 'Forms',
              child: _filled(
                'กสิกร',
                (c) => PpForgeInput(controller: c, label: 'Name'),
              ),
            ),
            const HubUse(
              label: 'Error + message',
              page: 'Register, change password',
              child: PpForgeInput(
                label: 'Email',
                errorText: 'Enter a valid email',
              ),
            ),
            const HubUse(
              label: 'Disabled',
              page: 'Forms while saving',
              child: PpForgeInput(label: 'Name', enabled: false),
            ),
            HubUse(
              label: 'Locked 🔒 — no frame',
              page: 'A linked email, a system row',
              child: _filled(
                'aom@mail.com',
                (c) => PpForgeInput(
                  controller: c,
                  label: 'Linked email',
                  locked: true,
                ),
              ),
            ),
            const HubUse(
              label: 'Password — icon + toggle + helper',
              page: 'Login, register',
              child: PpForgeInput(
                label: 'Password',
                obscurable: true,
                prefixIcon: PpForgeIcons.lock,
                helper: 'At least 8 characters',
              ),
            ),
            const HubUse(
              label: 'Dense, no label',
              page: 'Tag name, split-row name, icon maker',
              child: PpForgeInput(hint: 'Tag name', dense: true),
            ),
            HubUse(
              label: 'Multiline + counter',
              page: 'Contact note, debt note',
              wide: true,
              child: _filled(
                'บัญชีรับเงินเดือน',
                (c) => PpForgeInput(
                  controller: c,
                  label: 'Note',
                  maxLines: 3,
                  maxLength: 200,
                  showCounter: true,
                ),
              ),
            ),
          ],
        ),
        HubInApp(
          title: 'Data types',
          columns: 2,
          note:
              'Types layer on the looks (Field and In-card), they are not looks '
              'of their own. Amount: the currency symbol stuck to the number, '
              'thousands, right-aligned. Number: right-aligned. Percent: % '
              'suffix, 0–100, up to 2 decimals. Reference: digits only, left.',
          uses: [
            HubUse(
              label: 'Amount',
              page: 'Adjust balance, settle, goal target',
              child: _filled(
                '1250',
                (c) => PpForgeInput(
                  controller: c,
                  label: 'Amount',
                  type: PpForgeInputType.amount,
                ),
              ),
            ),
            const HubUse(
              label: 'Number',
              page: 'Installments, statement day',
              child: PpForgeInput(
                label: 'Quantity',
                type: PpForgeInputType.number,
              ),
            ),
            HubUse(
              label: 'Percent',
              page: 'Goal allocation, interest',
              child: _filled(
                '33.5',
                (c) => PpForgeInput(
                  controller: c,
                  label: 'Rate',
                  type: PpForgeInputType.percent,
                ),
              ),
            ),
            const HubUse(
              label: 'Reference number',
              page: 'Wallet identifiers',
              child: PpForgeInput(
                label: 'Account no.',
                type: PpForgeInputType.reference,
                hint: '0000000000',
              ),
            ),
            const HubUse(
              label: 'Reference — letters allowed',
              page: 'Wallet identifier (other)',
              child: PpForgeInput(
                label: 'Identifier',
                type: PpForgeInputType.reference,
                allowLetters: true,
              ),
            ),
            const HubUse(
              label: 'Amount — dense, no label',
              page: 'Split row amount',
              child: PpForgeInput(
                type: PpForgeInputType.amount,
                dense: true,
                hint: '0',
              ),
            ),
          ],
        ),
        HubInApp(
          title: 'In a card · view ⇄ edit · search',
          columns: 1,
          note:
              'The one exception to "a frame": editing INSIDE a card is an '
              'underline. Detail pages show plain text in view and the dense '
              'Field in edit (the editable-text indent rule: the frame lines '
              'up with the title, the text is indented by the frame padding in '
              'both modes; a read-only value is flush, no frame). Search is the '
              'grey capsule.',
          uses: [
            HubUse(
              label: 'In-card — title, hero amount, note',
              page: 'Transaction hero, quick-create card, draft card',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PpForgeInput.card(hint: 'What for?'),
                  const SizedBox(height: PpForgeSpacing.lg),
                  PpForgeInput.card(
                    type: PpForgeInputType.amount,
                    hint: '0',
                    hideHintOnFocus: true,
                    symbolScale: 0.7,
                    focusColor: scheme.error,
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: PpForgeSpacing.lg),
                  const PpForgeInput.card(
                    hint: 'A note (plain text until focused)',
                    underline: false,
                    minLines: 2,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Token geometry — PpForgeInputSize, side by side',
              page: 'Tx hero + EntryCard (description · amount), entity heroes',
              wide: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final size in PpForgeInputSize.values) ...[
                    Text(
                      'size: ${size.name}  (value row ${size.valueRow.round()}, '
                      'baseline ${size.valueBaseline.round()})',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PpForgeInput.card(
                            size: size,
                            label: 'คำอธิบาย',
                            labelPlacement: PpForgeInputLabelPlacement.above,
                            hint: 'ค่าอะไร?',
                          ),
                        ),
                        const SizedBox(width: PpForgeSpacing.md),
                        Expanded(
                          child: PpForgeInput.card(
                            size: size,
                            label: 'จำนวนเงิน',
                            labelPlacement: PpForgeInputLabelPlacement.above,
                            type: PpForgeInputType.amount,
                            currencySymbol: '฿',
                            textAlign: TextAlign.end,
                            hint: '0',
                            style: TextStyle(
                              fontSize: switch (size) {
                                PpForgeInputSize.regular => 18,
                                PpForgeInputSize.title => 22,
                                PpForgeInputSize.hero => 28,
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: PpForgeSpacing.lg),
                  ],
                ],
              ),
            ),
            HubUse(
              label: 'Field-name labels — left of the underline / above it',
              page:
                  'Entity heroes (left); transaction hero + EntryCard (above)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PpForgeInput.card(
                    label: 'ชื่อ',
                    labelWidth: 96,
                    hint: 'e.g. Savings',
                  ),
                  const SizedBox(height: PpForgeSpacing.md),
                  const PpForgeInput.card(
                    label: 'คำอธิบาย',
                    labelWidth: 96,
                    hint: 'ค่าอะไร?',
                  ),
                  const SizedBox(height: PpForgeSpacing.lg),
                  const PpForgeInput.card(
                    label: 'จำนวนเงิน',
                    labelPlacement: PpForgeInputLabelPlacement.above,
                    type: PpForgeInputType.amount,
                    hint: '0',
                    currencySymbol: '฿',
                  ),
                  const SizedBox(height: PpForgeSpacing.lg),
                  PpForgeInput.title(
                    editing: true,
                    controller: _title,
                    label: 'ชื่อ',
                    hint: 'Name',
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Detail value — view ⇄ edit (PpForgeInput.inline)',
              page: 'Every detail page: note, description',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PpForgeButton(
                    label: _editing ? 'Switch to view' : 'Switch to edit',
                    variant: PpForgeButtonVariant.outlined,
                    onPressed: () => setState(() => _editing = !_editing),
                  ),
                  const SizedBox(height: PpForgeSpacing.sm),
                  DetailStacked(
                    label: 'Note',
                    child: PpForgeInput.inline(
                      editing: _editing,
                      controller: _note,
                      hint: 'Add a note',
                      viewHint: 'Long-press to edit',
                      onEnterEdit: () => setState(() => _editing = true),
                      maxLines: 5,
                    ),
                  ),
                  DetailStacked(
                    label: 'Created by (read-only)',
                    child: PpForgeInput.inline(
                      editing: false,
                      controller: TextEditingController(text: 'Aom Chan'),
                    ),
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Hero name — view ⇄ edit (PpForgeInput.title)',
              page: 'Detail page heroes',
              child: PpForgeInput.title(
                editing: _editing,
                controller: _title,
                hint: 'Name',
                onEnterEdit: () => setState(() => _editing = true),
              ),
            ),
            HubUse(
              label: 'Search capsule',
              page: 'Lists (transactions, contacts, tags), pickers',
              child: PpForgeInput.search(
                onChanged: (_) {},
                hint: 'Search',
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        HubPlayground(
          title: 'PpForgeInput',
          note: 'The Field: every option PpForgeInput(...) has.',
          controls: [
            const PlayText('label', initialValue: 'Name'),
            const PlayText('hint', initialValue: 'Placeholder'),
            const PlayText('helper'),
            const PlayText('errorText'),
            const PlayText('prefixText'),
            PlayChoice<PpForgeInputType>('type', [
              for (final t in PpForgeInputType.values) (t.name, t),
            ]),
            const PlayBool('dense'),
            const PlayBool('enabled', initialValue: true),
            const PlayBool('readOnly'),
            const PlayBool('locked'),
            const PlayBool('obscurable'),
            const PlayBool('showCounter'),
            const PlayNum(
              'maxLength',
              min: 0,
              max: 100,
              step: 10,
              initialValue: 0,
            ),
            const PlayNum('maxLines', min: 1, max: 4, step: 1, initialValue: 1),
            PlayChoice<TextAlign?>('textAlign', [
              ('default', null),
              ('start', TextAlign.start),
              ('end', TextAlign.end),
              ('center', TextAlign.center),
            ]),
          ],
          builder: (context, v) {
            String? text(String k) =>
                v<String>(k).isEmpty ? null : v<String>(k);
            final max = v<double>('maxLength').round();
            return PpForgeInput(
              label: text('label'),
              hint: text('hint'),
              helper: text('helper'),
              errorText: text('errorText'),
              prefixText: text('prefixText'),
              type: v<PpForgeInputType>('type'),
              dense: v<bool>('dense'),
              enabled: v<bool>('enabled'),
              readOnly: v<bool>('readOnly'),
              locked: v<bool>('locked'),
              obscurable: v<bool>('obscurable'),
              showCounter: v<bool>('showCounter'),
              maxLength: max == 0 ? null : max,
              maxLines: v<double>('maxLines').round(),
              textAlign: v<TextAlign?>('textAlign'),
            );
          },
        ),
      ],
    );
  }
}
