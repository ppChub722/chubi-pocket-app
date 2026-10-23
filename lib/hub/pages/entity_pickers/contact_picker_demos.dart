import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/contacts/data/contacts_repository.dart';
import '../../../features/contacts/domain/contact.dart';
import '../../../features/contacts/presentation/cubit/contacts_cubit.dart';
import '../../../features/contacts/presentation/widgets/contact_picker.dart';
import '../../../features/personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../hub_kit.dart';

/// The people pickers as each page opens them, on the real caches.
class ContactPickerDemos extends StatelessWidget {
  const ContactPickerDemos({required this.onResult, super.key});

  final ValueChanged<String> onResult;

  static const _sampleNames = [
    UnlinkedName(name: 'mata', count: 3),
    UnlinkedName(name: 'Mat', count: 1),
    UnlinkedName(name: 'M.', count: 2),
  ];

  static String _pick(ContactPick? r) => switch (r) {
    null => 'closed',
    ContactPicked(:final contact) => 'contact ${contact.name}',
    ContactNamePicked(:final name) => 'known name "$name"',
    ContactNameTyped(:final name) => 'typed "$name"',
  };

  static String _wired(Set<String>? r) =>
      r == null ? 'closed' : 'wired ${r.join(', ')}';

  /// The real unlinked names, or a few made up when there are none.
  static Future<List<UnlinkedName>> _unlinked(BuildContext context) async {
    final repo = context.read<ContactsRepository>();
    try {
      final names = await repo.unlinkedNames();
      if (names.isNotEmpty) return names;
    } catch (_) {}
    return _sampleNames;
  }

  Widget _new(String label, Future<String> Function() run) => AppButton(
    label: label,
    variant: AppButtonVariant.outlined,
    onPressed: () async => onResult(await run()),
  );

  Widget _demo(String title, String note, List<Widget> buttons) => HubDemo(
    title: title,
    note: note,
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: buttons,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final contacts = context.watch<ContactsCubit>().state.contacts;
    final people = context.watch<DebtDirectoryCubit>().state.people;
    final first = contacts.firstOrNull;
    final owing = people.where((p) => p.net != 0).firstOrNull?.key;
    final debtSelected = owing == null
        ? null
        : (owing.startsWith('c:') ? owing.substring(2) : owing);
    final wireFor = first?.name ?? 'Mata';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _demo(
          'ContactPicker.one — split person',
          'Splits: the name typed on the split is in the name row at the '
              'bottom (not highlighted until tapped; save keeps that name, not '
              'linked); add a contact takes it. Opens on the first contact.',
          [
            _new(
              'New',
              () async => _pick(
                await ContactPicker.one(
                  context,
                  selectedId: first?.id,
                  allowFreeText: true,
                  allowCreate: true,
                  initialName: first?.name,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'ContactPicker.people — event bill "เพิ่มคน"',
          'Many at once: the event\'s members in their own section on top '
              '(ticked = already in the bill), then contacts / debt names. A typed '
              'name answers just that name.',
          [
            _new('New', () async {
              final r = await ContactPicker.people(
                context,
                membersLabel: 'คนในอีเวนต์',
                confirmLabel: (n) => 'เพิ่ม $n คน',
                selectedMemberIds: const {'m1'},
                members: const [
                  PickerMember(id: 'm1', name: 'ฉัน'),
                  PickerMember(id: 'm2', name: 'ฝน'),
                  PickerMember(id: 'm3', name: 'ต้น'),
                ],
              );
              if (r == null) return 'cancelled';
              return 'members ${r.memberIds} + ${r.picks.length} people';
            }),
          ],
        ),
        _demo(
          'ContactPicker.one — debt person (กับใคร)',
          'Debt form / debt detail: balances on the right, people still owing '
              'first, 4 tabs, a typed name, add a contact. Opens on the first '
              'person still owing.',
          [
            _new(
              'New',
              () async => _pick(
                await ContactPicker.one(
                  context,
                  mode: ContactPickerMode.debts,
                  selectedId: debtSelected,
                  allowFreeText: true,
                  allowCreate: true,
                  title: l.debtPersonPickerTitle,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'ContactPicker.one — link a debt name to a contact',
          'Debt person page: no free text, starts on the ผู้ติดต่อ tab.',
          [
            _new(
              'New',
              () async => _pick(
                await ContactPicker.one(
                  context,
                  initialFilter: ContactPickerTabs.contactsContacts,
                ),
              ),
            ),
          ],
        ),
        _demo(
          'ContactPicker.one — add an event member',
          'Add member "from contacts": no free text, nothing else.',
          [_new('New', () async => _pick(await ContactPicker.one(context)))],
        ),
        _demo(
          'ContactPicker.walletInvite',
          'Wallet members: linked, active contacts only; the hint on top, the '
              'empty line when nobody is left; search from 9 people.',
          [
            _new('New', () async {
              final c = await ContactPicker.walletInvite(
                context,
                excludeUserIds: const {},
              );
              return c == null ? 'closed' : 'invite ${c.name}';
            }),
          ],
        ),
        _demo(
          'ContactPicker.wireNames',
          'Contact detail: tick the typed split names that are this person '
              '(the real unlinked names, or made-up ones). Saving here only '
              'echoes the ticks; with "save fails once" the sheet stays open '
              'with its ticks.',
          [
            _new('New', () async {
              final names = await _unlinked(context);
              if (!context.mounted) return 'closed';
              return _wired(
                await ContactPicker.wireNames<Set<String>>(
                  context,
                  contactName: wireFor,
                  names: names,
                  onSave: (picked) async => picked,
                ),
              );
            }),
            _new('New, save fails once', () async {
              final names = await _unlinked(context);
              if (!context.mounted) return 'closed';
              var failed = false;
              return _wired(
                await ContactPicker.wireNames<Set<String>>(
                  context,
                  contactName: wireFor,
                  names: names,
                  onSave: (picked) async {
                    if (failed) return picked;
                    failed = true;
                    if (context.mounted) {
                      showAppSnackBar(
                        context,
                        'Save failed (demo)',
                        tone: Tone.danger,
                      );
                    }
                    return null;
                  },
                ),
              );
            }),
          ],
        ),
        if (contacts.isEmpty)
          const HubDemo(
            title: 'No contacts',
            child: AppText('The contacts cache is empty: sign in first.'),
          ),
      ],
    );
  }
}
