import 'package:flutter/material.dart';

import '../../features/accounts/domain/account.dart';
import '../../features/accounts/domain/account_identifier.dart';
import '../../features/accounts/domain/account_type.dart';
import '../../features/accounts/domain/payment_provider.dart';
import '../../features/accounts/domain/wallet_member.dart';
import '../../features/accounts/presentation/widgets/account_card.dart';
import '../../features/accounts/presentation/widgets/bank_picker_sheet.dart';
import '../../features/accounts/presentation/widgets/identifier_widgets.dart';
import '../../features/accounts/presentation/widgets/member_avatar_stack.dart';
import '../../features/accounts/presentation/widgets/wallet_pick_card.dart';
import '../../ui/ui.dart';
import '../hub_playground.dart';

/// `/dev/domain/people-accounts` — the three looks of a person, member
/// strips and stacks, and the wallet pieces (card, icon, pick card, banks,
/// numbers).
///
/// Gate pieces: PersonMark, PersonLevel, PersonLinkBadge, PersonRef,
/// AvatarStack, MemberStrip, UserProfilePreview. Feature pieces (shown from
/// sample models, no cubit): AccountCard, AccountCardSurface,
/// AccountIconCircle, SharedWalletIconBadge, MemberAvatarStack, WalletPickCard,
/// BankMark, IdentifierRow. Skipped (need cubits / repositories):
/// OtherMembersStack, WalletMembersView, IdentifierEditRow, bank picker sheet.
Widget buildPeopleAccountsPage(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;

  const people = [
    PersonRef(name: 'ppOnd', caption: 'You', isOwner: true),
    PersonRef(name: 'Aom Chan'),
    PersonRef(name: 'Bank', caption: 'Pending', pending: true),
    PersonRef(name: 'Cat'),
    PersonRef(name: 'Dao'),
  ];

  const members = [
    WalletMember(id: '1', userId: 'u1', name: 'ppOnd', role: WalletRole.owner),
    WalletMember(
      id: '2',
      userId: 'u2',
      name: 'Aom Chan',
      role: WalletRole.member,
    ),
    WalletMember(id: '3', userId: 'u3', name: 'Bee', role: WalletRole.member),
    WalletMember(id: '4', userId: 'u4', name: 'Cat', role: WalletRole.member),
  ];

  const bank = Account(
    id: 'a1',
    name: 'กสิกร',
    type: AccountType.bank,
    balance: 48200,
    currency: 'THB',
    description: 'Salary account',
    iconCode: IconCode(icon: 'account_balance', iconColors: ['#138F2D']),
  );
  const cash = Account(
    id: 'a2',
    name: 'เงินสด',
    type: AccountType.cash,
    balance: 1250.5,
    currency: 'THB',
    note: 'Wallet in the bag',
  );
  const card = Account(
    id: 'a3',
    name: 'บัตรเครดิต',
    type: AccountType.creditCard,
    balance: -12400,
    currency: 'THB',
    creditLimit: 50000,
    iconCode: IconCode(icon: 'credit_card', iconColors: ['#EF4444']),
  );
  const overpaid = Account(
    id: 'a4',
    name: 'ShopeePay Later',
    type: AccountType.payLater,
    balance: 300,
    currency: 'THB',
    creditLimit: 20000,
  );
  final untracked = bank.copyWith(name: 'ออมทรัพย์', trackBalance: false);
  final shared = bank.copyWith(
    name: 'บัญชีบ้าน',
    isShared: true,
    members: members,
  );

  const providers = [
    PaymentProvider(
      kind: 'bank',
      scheme: 'bot',
      code: '004',
      nameTh: 'ธนาคารกสิกรไทย',
      nameEn: 'Kasikornbank',
      shortName: 'KBANK',
    ),
    PaymentProvider(
      kind: 'bank',
      scheme: 'bot',
      code: '014',
      nameTh: 'ธนาคารไทยพาณิชย์',
      nameEn: 'Siam Commercial Bank',
      shortName: 'SCB',
    ),
    PaymentProvider(
      kind: 'bank',
      scheme: 'bot',
      code: '025',
      nameTh: 'ธนาคารกรุงศรีอยุธยา',
      nameEn: 'Bank of Ayudhya',
      shortName: 'BAY',
    ),
    PaymentProvider(
      kind: 'bank',
      scheme: 'bot',
      code: '999',
      nameTh: 'ธนาคารตัวอย่าง',
      nameEn: 'Sample Bank',
    ),
  ];

  Widget gridCard(Account a) =>
      SizedBox(width: 168, child: AccountCard(account: a, horizontal: false));

  Widget mark(String name, PersonLevel level, [double? size]) => size == null
      ? PersonMark(name: name, level: level)
      : PersonMark(name: name, level: level, size: size);

  Widget idRow(
    AccountIdentifier id, {
    List<PaymentProvider>? provs,
    bool hidden = false,
    VoidCallback? onDelete,
  }) => PpForgeCard(
    padding: EdgeInsets.zero,
    child: IdentifierRow(
      identifier: id,
      providers: provs ?? providers,
      hidden: hidden,
      onDelete: onDelete,
    ),
  );

  final text = Theme.of(context).textTheme;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HubInApp(
        columns: 2,
        note:
            'Real people and wallet pieces from sample models (no cubit), '
            'many variants side by side. Wide ones take a whole row.',
        uses: [
          // ── PersonMark: levels, sizes, slot, chips ──
          HubUse(
            label: 'PersonMark · name — a typed name',
            page: 'Transaction detail splits',
            child: mark('ลี', PersonLevel.name),
          ),
          HubUse(
            label: 'PersonMark · contact — own avatar',
            page: 'Contact picker, Contact detail',
            child: mark('บี', PersonLevel.contact),
          ),
          HubUse(
            label: 'PersonMark · linked — avatar + link badge',
            page: 'Contact picker, Contact detail',
            child: mark('ต้น', PersonLevel.linked),
          ),
          HubUse(
            label: 'size 20 — in a chip',
            page: 'Chips (payer, split)',
            child: mark('ต้น', PersonLevel.linked),
          ),
          HubUse(
            label: 'size 36 — picker row',
            page: 'Contact picker sheet',
            child: mark('ต้น', PersonLevel.linked, 36),
          ),
          HubUse(
            label: 'size 40 — list row',
            page: 'Splits section',
            child: mark('ต้น', PersonLevel.linked, 40),
          ),
          HubUse(
            label: 'size 52 — header',
            page: 'Contact detail header',
            child: mark('ต้น', PersonLevel.linked, 52),
          ),
          HubUse(
            label: 'PersonLinkBadge — 16 (fixed) and 24',
            page: 'Next to a linked avatar',
            child: const Wrap(
              spacing: PpForgeSpacing.sm,
              children: [PersonLinkBadge(), PersonLinkBadge(size: 24)],
            ),
          ),
          HubUse(
            wide: true,
            label:
                'reserveLinkSlot — unlinked marks keep the badge space so '
                'every name starts at the same x',
            page: 'Contact picker sheet, Splits section',
            child: const PpForgeCard(
              padding: EdgeInsets.zero,
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
                    subtitle: 'linked',
                  ),
                  PpForgeDivider.row(),
                  ListRow(
                    leading: PersonMark(
                      name: 'บี',
                      level: PersonLevel.contact,
                      size: 40,
                      reserveLinkSlot: true,
                    ),
                    title: 'บี',
                    subtitle: 'contact — slot kept empty',
                  ),
                  PpForgeDivider.row(),
                  ListRow(
                    leading: PersonMark(
                      name: 'ลี',
                      level: PersonLevel.name,
                      size: 40,
                      reserveLinkSlot: true,
                    ),
                    title: 'ลี',
                    subtitle: 'typed name — slot kept empty',
                  ),
                ],
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'PersonMark in a chip — name · contact · linked',
            page: 'Split / payer chips',
            child: const Wrap(
              spacing: PpForgeSpacing.sm,
              runSpacing: PpForgeSpacing.sm,
              children: [
                PpForgeChip(
                  label: 'ลี',
                  leading: PersonMark(name: 'ลี', level: PersonLevel.name),
                ),
                PpForgeChip(
                  label: 'บี',
                  leading: PersonMark(name: 'บี', level: PersonLevel.contact),
                ),
                PpForgeChip(
                  label: 'ต้น',
                  leading: PersonMark(name: 'ต้น', level: PersonLevel.linked),
                ),
              ],
            ),
          ),

          // ── Member strips and stacks ──
          HubUse(
            wide: true,
            label: 'MemberStrip — with the dashed invite circle',
            page: 'Project dashboard tab',
            child: MemberStrip(members: people, onInvite: () {}),
          ),
          const HubUse(
            wide: true,
            label: 'MemberStrip — no invite, avatarSize 36',
            page: 'Project dashboard tab (viewer)',
            child: MemberStrip(members: people, avatarSize: 36),
          ),
          const HubUse(
            label: 'AvatarStack — 3 of 5, size 32 (+N bubble)',
            page: 'Account detail, Account cards',
            child: AvatarStack(people: people, maxVisible: 3, size: 32),
          ),
          const HubUse(
            label: 'AvatarStack — all fit',
            page: 'Account detail',
            child: AvatarStack(people: people, maxVisible: 5),
          ),
          const HubUse(
            label: 'MemberAvatarStack — 3 of 4, size 20',
            page: 'Account cards',
            child: MemberAvatarStack(members: members),
          ),
          HubUse(
            label: 'MemberAvatarStack — 2 members, size 28',
            page: 'Account detail',
            child: MemberAvatarStack(members: [...members.take(2)], size: 28),
          ),
          const HubUse(
            label: 'UserAvatar — 28',
            page: 'Edit profile page',
            child: UserAvatar(displayName: 'Aom Chan', size: 28),
          ),
          const HubUse(
            label: 'UserAvatar — 40',
            page: 'Edit profile page',
            child: UserAvatar(displayName: 'Aom Chan'),
          ),
          const HubUse(
            label: 'UserAvatar — with its own icon',
            page: 'Edit profile page',
            child: UserAvatar(
              displayName: 'Bee',
              iconCode: IconCode(icon: 'favorite', iconColors: ['#EF4444']),
            ),
          ),
          const HubUse(
            wide: true,
            label: 'UserProfilePreview — the compact profile row',
            page: 'Edit profile page',
            child: UserProfilePreview(displayName: 'Aom Chan'),
          ),

          // ── Wallet cards ──
          HubUse(
            label: 'AccountCard grid — bank, own icon colour',
            page: 'Accounts page, Account picker sheet',
            child: gridCard(bank),
          ),
          HubUse(
            label: 'AccountCard grid — cash, no icon set',
            page: 'Accounts page',
            child: gridCard(cash),
          ),
          HubUse(
            label: 'AccountCard grid — credit card: owed + used-credit bar',
            page: 'Accounts page',
            child: gridCard(card),
          ),
          HubUse(
            label: 'AccountCard grid — overpaid: no bar',
            page: 'Accounts page',
            child: gridCard(overpaid),
          ),
          HubUse(
            label: 'AccountCard grid — untracked: no balance, no credit bar',
            page: 'Accounts page, Account picker sheet',
            child: gridCard(untracked),
          ),
          HubUse(
            label: 'Hidden balance — symbol + bullets (privacy off)',
            page: 'Accounts page (privacy mode)',
            child: SizedBox(
              width: 168,
              child: AccountCardSurface(
                account: bank,
                child: Padding(
                  padding: const EdgeInsets.all(PpForgeSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AccountIconCircle(account: bank, size: 40),
                      const SizedBox(height: PpForgeSpacing.sm),
                      Text(bank.name, style: text.titleMedium),
                      const PpForgeText('฿••••', role: PpForgeTextRole.money),
                    ],
                  ),
                ),
              ),
            ),
          ),
          HubUse(
            label: 'Shared wallet — link badge + the OTHER members',
            page: 'Accounts page, Account detail',
            child: SizedBox(
              width: 168,
              child: AccountCardSurface(
                account: shared,
                child: Padding(
                  padding: const EdgeInsets.all(PpForgeSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccountIconCircle(account: shared, size: 40),
                      const SizedBox(height: PpForgeSpacing.sm),
                      Text(shared.name, style: text.titleMedium),
                      const SizedBox(height: PpForgeSpacing.xs),
                      MemberAvatarStack(members: members.skip(1).toList()),
                      const SizedBox(height: PpForgeSpacing.xs),
                      MoneyText(
                        shared.balance,
                        style: text.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'AccountCard horizontal — bank with description',
            page: 'Accounts page (reorder), Account picker sheet',
            child: AccountCard(account: bank, horizontal: true),
          ),
          HubUse(
            wide: true,
            label: 'AccountCard horizontal — cash with an italic note',
            page: 'Accounts page (reorder)',
            child: AccountCard(account: cash, horizontal: true),
          ),
          HubUse(
            wide: true,
            label: 'AccountCard horizontal — credit card with the credit bar',
            page: 'Accounts page (reorder)',
            child: AccountCard(account: card, horizontal: true),
          ),
          HubUse(
            wide: true,
            label: 'AccountCard horizontal — untracked: no balance',
            page: 'Accounts page (reorder)',
            child: AccountCard(account: untracked, horizontal: true),
          ),

          // ── Wallet icon, pick card ──
          HubUse(
            label: 'AccountIconCircle — personal 44',
            page: 'Account detail',
            child: const AccountIconCircle(account: bank, size: 44),
          ),
          HubUse(
            label: 'AccountIconCircle — shared 44 (badge)',
            page: 'Account detail',
            child: AccountIconCircle(account: shared, size: 44),
          ),
          HubUse(
            label: 'AccountIconCircle — editable (pencil badge)',
            page: 'Account detail (edit), Wallet compact hero',
            child: AccountIconCircle(account: card, size: 44, onTap: () {}),
          ),
          HubUse(
            label: 'SharedWalletIconBadge — around any icon, 32',
            page: 'Wallet compact hero',
            child: SharedWalletIconBadge(
              size: 32,
              child: IconTile(
                icon: PpForgeIcons.cash,
                color: scheme.primary,
                size: 32,
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'WalletPickCard — picked, personal',
            page: 'Transaction / debt / scheduled draft forms',
            child: WalletPickCard(
              account: bank,
              label: 'Wallet',
              placeholder: 'Choose a wallet',
              onTap: () {},
            ),
          ),
          HubUse(
            wide: true,
            label: 'WalletPickCard — picked, untracked (no balance)',
            page: 'Transaction / debt / scheduled draft forms',
            child: WalletPickCard(
              account: untracked,
              label: 'Wallet',
              placeholder: 'Choose a wallet',
              onTap: () {},
            ),
          ),
          HubUse(
            wide: true,
            label: 'WalletPickCard — picked, shared (badge)',
            page: 'Transaction / debt / scheduled draft forms',
            child: WalletPickCard(
              account: shared,
              label: 'Wallet · shared',
              placeholder: 'Choose a wallet',
              onTap: () {},
            ),
          ),
          HubUse(
            wide: true,
            label: 'WalletPickCard — empty (dashed)',
            page: 'Transaction / debt / scheduled draft forms',
            child: WalletPickCard(
              account: null,
              label: 'Wallet · empty',
              placeholder: 'Choose a wallet',
              onTap: () {},
            ),
          ),
          HubUse(
            wide: true,
            label: 'WalletPickCard — empty + errorText (required pick)',
            page: 'Transaction draft form (save pressed)',
            child: WalletPickCard(
              account: null,
              label: 'Wallet · error',
              placeholder: 'Choose a wallet',
              errorText: 'Required',
              onTap: () {},
            ),
          ),
          HubUse(
            label: 'WalletPickCard dense — From',
            page: 'Transfer form (two on a row)',
            child: WalletPickCard(
              account: cash,
              label: 'From',
              placeholder: 'Choose',
              dense: true,
              onTap: () {},
            ),
          ),
          HubUse(
            label: 'WalletPickCard dense — To',
            page: 'Transfer form (two on a row)',
            child: WalletPickCard(
              account: card,
              label: 'To',
              placeholder: 'Choose',
              dense: true,
              onTap: () {},
            ),
          ),

          // ── Banks and numbers ──
          for (final p in providers)
            HubUse(
              label: 'BankMark — ${p.label('en')}',
              page: p.shortName == null
                  ? 'Unknown bank: colour from its code'
                  : 'Bank picker sheet, Account detail numbers',
              child: BankMark(provider: p),
            ),
          const HubUse(
            label: 'BankMark — size 24',
            page: 'Account detail numbers',
            child: BankMark(provider: _kbank, size: 24),
          ),
          HubUse(
            wide: true,
            label: 'IdentifierRow — bank account (bank mark + number)',
            page: 'Account detail (wallet numbers)',
            child: idRow(
              const AccountIdentifier(
                kind: IdentifierKind.bankAccount,
                value: '1234527806',
                bankCode: '004',
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'IdentifierRow — PromptPay (kind icon)',
            page: 'Account detail (wallet numbers)',
            child: idRow(
              const AccountIdentifier(
                kind: IdentifierKind.promptPay,
                value: '0812345678',
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'IdentifierRow — card (bank mark)',
            page: 'Account detail (wallet numbers)',
            child: idRow(
              const AccountIdentifier(
                kind: IdentifierKind.card,
                value: 'xxxxxxxxxxxx2780',
                bankCode: '014',
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'IdentifierRow — other (kind icon)',
            page: 'Account detail (wallet numbers)',
            child: idRow(
              const AccountIdentifier(
                kind: IdentifierKind.other,
                value: '99887766',
              ),
            ),
          ),
          HubUse(
            wide: true,
            label: 'IdentifierRow — hidden number',
            page: 'Account detail (privacy)',
            child: idRow(
              const AccountIdentifier(
                kind: IdentifierKind.bankAccount,
                value: '1234527806',
                bankCode: '014',
              ),
              hidden: true,
            ),
          ),
          HubUse(
            wide: true,
            label: 'IdentifierRow — with delete',
            page: 'Account detail (edit)',
            child: idRow(
              const AccountIdentifier(
                kind: IdentifierKind.promptPay,
                value: '0812345678',
              ),
              onDelete: () {},
            ),
          ),
          HubUse(
            wide: true,
            label: 'IdentifierRow — unknown bank code',
            page: 'Account detail (provider list missing the bank)',
            child: idRow(
              const AccountIdentifier(
                kind: IdentifierKind.bankAccount,
                value: '5550001234',
                bankCode: '777',
              ),
              provs: const [],
            ),
          ),
        ],
      ),
      HubPlayground(
        title: 'PersonMark',
        note:
            'level = who the person is to me; size; reserveLinkSlot keeps the '
            'link badge\'s space empty on unlinked marks (lists).',
        controls: [
          PlayChoice<PersonLevel>('level', [
            for (final l in PersonLevel.values) (l.name, l),
          ], initial: PersonLevel.linked),
          const PlayNum('size', min: 16, max: 56, step: 4, initialValue: 40),
          const PlayBool('reserveLinkSlot'),
        ],
        builder: (context, v) => Align(
          alignment: Alignment.centerLeft,
          child: PersonMark(
            name: 'ต้น',
            level: v<PersonLevel>('level'),
            size: v<double>('size'),
            reserveLinkSlot: v<bool>('reserveLinkSlot'),
          ),
        ),
      ),
      HubPlayground(
        title: 'AvatarStack · MemberStrip',
        note:
            'AvatarStack: maxVisible and size. MemberStrip: avatarSize and '
            'onInvite (the dashed invite circle).',
        controls: [
          const PlayNum('maxVisible', min: 1, max: 5, initialValue: 3),
          const PlayNum('size', min: 20, max: 44, step: 4, initialValue: 32),
          const PlayBool('onInvite', initialValue: true),
        ],
        builder: (context, v) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AvatarStack(
              people: people,
              maxVisible: v<double>('maxVisible').round(),
              size: v<double>('size'),
            ),
            const SizedBox(height: PpForgeSpacing.md),
            MemberStrip(
              members: people,
              avatarSize: v<double>('size'),
              onInvite: v<bool>('onInvite') ? () {} : null,
            ),
          ],
        ),
      ),
      HubPlayground(
        title: 'AccountCard',
        note:
            'account (type / shared / credit), horizontal (list row) or '
            'vertical (grid), onTap, onIconTap (editable icon).',
        controls: [
          PlayChoice<Account>('account', [
            ('bank', bank),
            ('cash', cash),
            ('credit card', card),
            ('overpaid', overpaid),
          ]),
          const PlayBool('horizontal'),
          const PlayBool('onTap'),
          const PlayBool('onIconTap'),
        ],
        builder: (context, v) {
          final horizontal = v<bool>('horizontal');
          final c = AccountCard(
            account: v<Account>('account'),
            horizontal: horizontal,
            onTap: v<bool>('onTap') ? () {} : null,
            onIconTap: v<bool>('onIconTap') ? () {} : null,
          );
          return horizontal
              ? c
              : Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(width: 168, child: c),
                );
        },
      ),
      HubPlayground(
        title: 'AccountIconCircle',
        note:
            'account (personal or shared = badge), size, onTap (pencil badge).',
        controls: [
          PlayChoice<Account>('account', [
            ('personal', bank),
            ('shared', shared),
          ]),
          const PlayNum('size', min: 24, max: 64, step: 8, initialValue: 44),
          const PlayBool('onTap'),
        ],
        builder: (context, v) => Align(
          alignment: Alignment.centerLeft,
          child: AccountIconCircle(
            account: v<Account>('account'),
            size: v<double>('size'),
            onTap: v<bool>('onTap') ? () {} : null,
          ),
        ),
      ),
      HubPlayground(
        title: 'WalletPickCard',
        note:
            'account (null = the dashed empty card), dense, errorText '
            '(required pick).',
        controls: [
          PlayChoice<Account?>('account', [
            ('none', null),
            ('bank', bank),
            ('shared', shared),
            ('credit card', card),
          ], initial: bank),
          const PlayBool('dense'),
          const PlayBool('errorText'),
        ],
        builder: (context, v) => WalletPickCard(
          account: v<Account?>('account'),
          label: 'Wallet',
          placeholder: 'Choose a wallet',
          dense: v<bool>('dense'),
          errorText: v<bool>('errorText') ? 'Required' : null,
          onTap: () {},
        ),
      ),
      HubPlayground(
        title: 'BankMark · IdentifierRow',
        note:
            'BankMark: provider and size. IdentifierRow: kind, hidden, '
            'onDelete.',
        controls: [
          PlayChoice<PaymentProvider>('provider', [
            for (final p in providers) (p.label('en'), p),
          ]),
          const PlayNum('size', min: 20, max: 48, step: 4, initialValue: 32),
          PlayChoice<IdentifierKind>('kind', [
            for (final k in IdentifierKind.values) (k.name, k),
          ]),
          const PlayBool('hidden'),
          const PlayBool('onDelete'),
        ],
        builder: (context, v) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: BankMark(
                provider: v<PaymentProvider>('provider'),
                size: v<double>('size'),
              ),
            ),
            const SizedBox(height: PpForgeSpacing.sm),
            PpForgeCard(
              padding: EdgeInsets.zero,
              child: IdentifierRow(
                identifier: AccountIdentifier(
                  kind: v<IdentifierKind>('kind'),
                  value: '1234527806',
                  bankCode: '004',
                ),
                providers: providers,
                hidden: v<bool>('hidden'),
                onDelete: v<bool>('onDelete') ? () {} : null,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

const _kbank = PaymentProvider(
  kind: 'bank',
  scheme: 'bot',
  code: '004',
  nameTh: 'ธนาคารกสิกรไทย',
  nameEn: 'Kasikornbank',
  shortName: 'KBANK',
);
