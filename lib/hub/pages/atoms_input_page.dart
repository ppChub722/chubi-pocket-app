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
              child: AppInput(label: 'Name', hint: 'Wallet name'),
            ),
            HubUse(
              label: 'Filled',
              page: 'Forms',
              child: _filled(
                'กสิกร',
                (c) => AppInput(controller: c, label: 'Name'),
              ),
            ),
            const HubUse(
              label: 'Error + message',
              page: 'Register, change password',
              child: AppInput(label: 'Email', errorText: 'Enter a valid email'),
            ),
            const HubUse(
              label: 'Disabled',
              page: 'Forms while saving',
              child: AppInput(label: 'Name', enabled: false),
            ),
            HubUse(
              label: 'Locked 🔒 — no frame',
              page: 'A linked email, a system row',
              child: _filled(
                'aom@mail.com',
                (c) => AppInput(
                  controller: c,
                  label: 'Linked email',
                  locked: true,
                ),
              ),
            ),
            const HubUse(
              label: 'Password — icon + toggle + helper',
              page: 'Login, register',
              child: AppInput(
                label: 'Password',
                obscurable: true,
                prefixIcon: AppIcons.lock,
                helper: 'At least 8 characters',
              ),
            ),
            const HubUse(
              label: 'Dense, no label',
              page: 'Tag name, split-row name, icon maker',
              child: AppInput(hint: 'Tag name', dense: true),
            ),
            HubUse(
              label: 'Multiline + counter',
              page: 'Contact note, debt note',
              wide: true,
              child: _filled(
                'บัญชีรับเงินเดือน',
                (c) => AppInput(
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
                (c) => AppInput(
                  controller: c,
                  label: 'Amount',
                  type: AppInputType.amount,
                ),
              ),
            ),
            const HubUse(
              label: 'Number',
              page: 'Installments, statement day',
              child: AppInput(label: 'Quantity', type: AppInputType.number),
            ),
            HubUse(
              label: 'Percent',
              page: 'Goal allocation, interest',
              child: _filled(
                '33.5',
                (c) => AppInput(
                  controller: c,
                  label: 'Rate',
                  type: AppInputType.percent,
                ),
              ),
            ),
            const HubUse(
              label: 'Reference number',
              page: 'Wallet identifiers',
              child: AppInput(
                label: 'Account no.',
                type: AppInputType.reference,
                hint: '0000000000',
              ),
            ),
            const HubUse(
              label: 'Reference — letters allowed',
              page: 'Wallet identifier (other)',
              child: AppInput(
                label: 'Identifier',
                type: AppInputType.reference,
                allowLetters: true,
              ),
            ),
            const HubUse(
              label: 'Amount — dense, no label',
              page: 'Split row amount',
              child: AppInput(
                type: AppInputType.amount,
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
                  const AppInput.card(hint: 'What for?'),
                  const SizedBox(height: AppSpacing.lg),
                  AppInput.card(
                    type: AppInputType.amount,
                    hint: '0',
                    hideHintOnFocus: true,
                    symbolScale: 0.7,
                    focusColor: scheme.error,
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppInput.card(
                    hint: 'A note (plain text until focused)',
                    underline: false,
                    minLines: 2,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Token geometry — AppInputSize, side by side',
              page: 'Tx hero + EntryCard (description · amount), entity heroes',
              wide: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final size in AppInputSize.values) ...[
                    Text(
                      'size: ${size.name}  (value row ${size.valueRow.round()}, '
                      'baseline ${size.valueBaseline.round()})',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppInput.card(
                            size: size,
                            label: 'คำอธิบาย',
                            labelPlacement: AppInputLabelPlacement.above,
                            hint: 'ค่าอะไร?',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppInput.card(
                            size: size,
                            label: 'จำนวนเงิน',
                            labelPlacement: AppInputLabelPlacement.above,
                            type: AppInputType.amount,
                            currencySymbol: '฿',
                            textAlign: TextAlign.end,
                            hint: '0',
                            style: TextStyle(
                              fontSize: switch (size) {
                                AppInputSize.regular => 18,
                                AppInputSize.title => 22,
                                AppInputSize.hero => 28,
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                  const AppInput.card(
                    label: 'ชื่อ',
                    labelWidth: 96,
                    hint: 'e.g. Savings',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const AppInput.card(
                    label: 'คำอธิบาย',
                    labelWidth: 96,
                    hint: 'ค่าอะไร?',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppInput.card(
                    label: 'จำนวนเงิน',
                    labelPlacement: AppInputLabelPlacement.above,
                    type: AppInputType.amount,
                    hint: '0',
                    currencySymbol: '฿',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppInput.title(
                    editing: true,
                    controller: _title,
                    label: 'ชื่อ',
                    hint: 'Name',
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Detail value — view ⇄ edit (AppInput.inline)',
              page: 'Every detail page: note, description',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: _editing ? 'Switch to view' : 'Switch to edit',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => setState(() => _editing = !_editing),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DetailStacked(
                    label: 'Note',
                    child: AppInput.inline(
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
                    child: AppInput.inline(
                      editing: false,
                      controller: TextEditingController(text: 'Aom Chan'),
                    ),
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Hero name — view ⇄ edit (AppInput.title)',
              page: 'Detail page heroes',
              child: AppInput.title(
                editing: _editing,
                controller: _title,
                hint: 'Name',
                onEnterEdit: () => setState(() => _editing = true),
              ),
            ),
            HubUse(
              label: 'Search capsule',
              page: 'Lists (transactions, contacts, tags), pickers',
              child: AppInput.search(
                onChanged: (_) {},
                hint: 'Search',
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        HubPlayground(
          title: 'AppInput',
          note: 'The Field: every option AppInput(...) has.',
          controls: [
            const PlayText('label', initialValue: 'Name'),
            const PlayText('hint', initialValue: 'Placeholder'),
            const PlayText('helper'),
            const PlayText('errorText'),
            const PlayText('prefixText'),
            PlayChoice<AppInputType>('type', [
              for (final t in AppInputType.values) (t.name, t),
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
            return AppInput(
              label: text('label'),
              hint: text('hint'),
              helper: text('helper'),
              errorText: text('errorText'),
              prefixText: text('prefixText'),
              type: v<AppInputType>('type'),
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
