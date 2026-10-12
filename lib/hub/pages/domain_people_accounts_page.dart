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
import '../hub_kit.dart';
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
    WalletMember(
      id: '1',
      userId: 'u1',
      displayName: 'ppOnd',
      role: WalletRole.owner,
    ),
    WalletMember(
      id: '2',
      userId: 'u2',
      displayName: 'Aom Chan',
      role: WalletRole.member,
    ),
    WalletMember(
      id: '3',
      userId: 'u3',
      displayName: 'Bee',
      role: WalletRole.member,
    ),
    WalletMember(
      id: '4',
      userId: 'u4',
      displayName: 'Cat',
      role: WalletRole.member,
    ),
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

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
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
            const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.sm),
            AppCard(
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
      HubDemo(
        title: 'PersonMark — three levels',
        note:
            'Used in: Contact detail, Contact picker, Transaction detail splits. '
            'Who a person is to me: a typed name (generic person), a contact '
            '(own avatar), a contact linked to an app user (avatar + link '
            'badge).',
        child: const HubRow(
          cells: [
            HubCell(
              caption: 'name',
              child: PersonMark(name: 'ลี', level: PersonLevel.name),
            ),
            HubCell(
              caption: 'contact',
              child: PersonMark(name: 'บี', level: PersonLevel.contact),
            ),
            HubCell(
              caption: 'linked',
              child: PersonMark(name: 'ต้น', level: PersonLevel.linked),
            ),
          ],
        ),
      ),
      HubDemo(
        title: 'PersonMark — sizes',
        note:
            'Used in: Contact picker (36/40), Contact detail header (52), chips (20). '
            'The link badge keeps one fixed size (16) whatever the avatar '
            'beside it. The gap is 2 under 32 and 4 from 32 up.',
        child: const HubRow(
          cells: [
            HubCell(
              caption: '20 (chip)',
              child: PersonMark(name: 'ต้น', level: PersonLevel.linked),
            ),
            HubCell(
              caption: '36 (picker)',
              child: PersonMark(
                name: 'ต้น',
                level: PersonLevel.linked,
                size: 36,
              ),
            ),
            HubCell(
              caption: '40 (list)',
              child: PersonMark(
                name: 'ต้น',
                level: PersonLevel.linked,
                size: 40,
              ),
            ),
            HubCell(
              caption: '52 (header)',
              child: PersonMark(
                name: 'ต้น',
                level: PersonLevel.linked,
                size: 52,
              ),
            ),
          ],
        ),
      ),
      HubDemo(
        title: 'PersonMark — reserveLinkSlot',
        note:
            'Used in: Contact picker sheet, Splits section. '
            'In a list, unlinked marks keep the badge\'s space empty so every '
            'name starts at the same x. Off for a mark standing alone.',
        child: AppCard(
          padding: EdgeInsets.zero,
          child: const Column(
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
              AppDivider.row(),
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
              AppDivider.row(),
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
      HubDemo(
        title: 'PersonMark in a chip · PersonLinkBadge',
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const AppChip(
              label: 'ลี',
              leading: PersonMark(name: 'ลี', level: PersonLevel.name),
            ),
            const AppChip(
              label: 'บี',
              leading: PersonMark(name: 'บี', level: PersonLevel.contact),
            ),
            const AppChip(
              label: 'ต้น',
              leading: PersonMark(name: 'ต้น', level: PersonLevel.linked),
            ),
            const PersonLinkBadge(),
            const PersonLinkBadge(size: 24),
          ],
        ),
      ),
      HubDemo(
        title: 'MemberStrip',
        note:
            'Used in: Project dashboard tab. '
            'Horizontal member row: avatar and name, a crown on the owner, a '
            'caption under the name, faded pending members, and a dashed '
            'invite circle at the end when onInvite is set.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MemberStrip(members: people, onInvite: () {}),
            const SizedBox(height: AppSpacing.md),
            const Text('Without invite, avatarSize 36'),
            const SizedBox(height: AppSpacing.xs),
            const MemberStrip(members: people, avatarSize: 36),
          ],
        ),
      ),
      HubDemo(
        title: 'AvatarStack · MemberAvatarStack',
        note:
            'Used in: Account detail, Account cards. '
            'Overlapping avatars with a "+N" overflow bubble. AvatarStack takes '
            'PersonRef; MemberAvatarStack (wallet feature) takes WalletMember.',
        child: HubRow(
          cells: [
            const HubCell(
              caption: 'AvatarStack 3 of 5 · 32',
              child: AvatarStack(people: people, maxVisible: 3, size: 32),
            ),
            const HubCell(
              caption: 'AvatarStack all fit',
              child: AvatarStack(people: people, maxVisible: 5),
            ),
            const HubCell(
              caption: 'MemberAvatarStack 3 of 4 · 20',
              child: MemberAvatarStack(members: members),
            ),
            HubCell(
              caption: 'MemberAvatarStack 2 · 28',
              child: MemberAvatarStack(members: [...members.take(2)], size: 28),
            ),
          ],
        ),
      ),
      HubDemo(
        title: 'UserAvatar · UserProfilePreview',
        note:
            'Used in: Edit profile page. '
            'A user\'s avatar in context: alone, inside a stack, and as the '
            'compact preview row used on profile screens.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HubRow(
              cells: [
                HubCell(
                  caption: '28',
                  child: UserAvatar(displayName: 'Aom Chan', size: 28),
                ),
                HubCell(
                  caption: '40',
                  child: UserAvatar(displayName: 'Aom Chan'),
                ),
                HubCell(
                  caption: 'with icon',
                  child: UserAvatar(
                    displayName: 'Bee',
                    iconCode: IconCode(
                      icon: 'favorite',
                      iconColors: ['#EF4444'],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const UserProfilePreview(displayName: 'Aom Chan'),
          ],
        ),
      ),
      HubDemo(
        title: 'AccountCard — vertical (grid)',
        note:
            'Used in: Accounts page, Account picker sheet. '
            'The wallet-card look: accent wash, type glyph in the corner. '
            'Balance colour: a credit-type wallet shows what you owe in the '
            'liability colour; others use the wallet\'s own icon colour. A '
            'credit card also shows its used-credit bar; an overpaid card '
            'shows none.',
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            gridCard(bank),
            gridCard(cash),
            gridCard(card),
            gridCard(overpaid),
          ],
        ),
      ),
      HubDemo(
        title: 'AccountCard — horizontal (list row)',
        note:
            'Used in: Accounts page (reorder), Account picker sheet. '
            'The reorder-list / icon-maker form. Description (else the type '
            'name), optional italic note, credit bar.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final a in [bank, cash, card])
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AccountCard(account: a, horizontal: true),
              ),
          ],
        ),
      ),
      HubDemo(
        title: 'Account card — hidden balance',
        note:
            'Used in: Accounts page (privacy mode, currently off). '
            'kMoneyPrivacyEnabled is a const false right now, so the card '
            'never hides its balance. The hidden look is the symbol plus '
            'four bullets, drawn here as a static copy of the card surface.',
        child: SizedBox(
          width: 168,
          child: AccountCardSurface(
            account: bank,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AccountIconCircle(account: bank, size: 40),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    bank.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const AppText('฿••••', role: AppTextRole.money),
                ],
              ),
            ),
          ),
        ),
      ),
      HubDemo(
        title: 'Shared wallet — AccountCardSurface + member stack',
        note:
            'Used in: Accounts page, Account detail. '
            'A shared wallet adds the link badge on its icon and the stack of '
            'the OTHER members. AccountCard itself reads the signed-in user '
            'to drop "self", which needs a running cubit, so the parts are '
            'composed here by hand.',
        child: SizedBox(
          width: 220,
          child: AccountCardSurface(
            account: shared,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccountIconCircle(account: shared, size: 40),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    shared.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  MemberAvatarStack(members: members.skip(1).toList()),
                  const SizedBox(height: AppSpacing.xs),
                  MoneyText(
                    shared.balance,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
      HubDemo(
        title: 'AccountIconCircle · SharedWalletIconBadge',
        note:
            'Used in: Account detail, Wallet compact hero. '
            'The wallet icon (pencil badge while onTap is set) with the shared '
            'badge when the wallet is shared. Constant footprint either way.',
        child: HubRow(
          cells: [
            const HubCell(
              caption: 'personal 44',
              child: AccountIconCircle(account: bank, size: 44),
            ),
            HubCell(
              caption: 'shared 44',
              child: AccountIconCircle(account: shared, size: 44),
            ),
            HubCell(
              caption: 'editable 44',
              child: AccountIconCircle(account: card, size: 44, onTap: () {}),
            ),
            HubCell(
              caption: 'SharedWalletIconBadge 32',
              child: SharedWalletIconBadge(
                size: 32,
                child: IconTile(
                  icon: AppIcons.cash,
                  color: scheme.primary,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
      HubDemo(
        title: 'WalletPickCard',
        note:
            'Used in: Transaction / debt / scheduled draft forms. '
            'A wallet as a PickCard: wash, icon (+ shared badge), balance in '
            'its accent colour. Nothing picked shows the dashed empty card; '
            'dense fits two cards on a row; errorText marks a required pick.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WalletPickCard(
              account: bank,
              label: 'Wallet',
              placeholder: 'Choose a wallet',
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            WalletPickCard(
              account: shared,
              label: 'Wallet · shared',
              placeholder: 'Choose a wallet',
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            WalletPickCard(
              account: null,
              label: 'Wallet · empty',
              placeholder: 'Choose a wallet',
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            WalletPickCard(
              account: null,
              label: 'Wallet · error',
              placeholder: 'Choose a wallet',
              errorText: 'Required',
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: WalletPickCard(
                    account: cash,
                    label: 'From',
                    placeholder: 'Choose',
                    dense: true,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: WalletPickCard(
                    account: card,
                    label: 'To',
                    placeholder: 'Choose',
                    dense: true,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      HubDemo(
        title: 'BankMark',
        note:
            'Used in: Bank picker sheet, Account detail numbers. '
            'A circle in the bank\'s colour with its short code. Unknown banks '
            'get a stable colour from their code and the English name\'s '
            'initials.',
        child: HubRow(
          cells: [
            for (final p in providers)
              HubCell(
                caption: p.label('en'),
                child: BankMark(provider: p),
              ),
            const HubCell(
              caption: 'size 24',
              child: BankMark(provider: _kbank, size: 24),
            ),
          ],
        ),
      ),
      HubDemo(
        title: 'IdentifierRow — kinds',
        note:
            'Used in: Account detail (wallet numbers). '
            'A wallet number, read-only: kind (+ bank) on the left, the '
            'number on the right. Bank account and card show the bank mark; '
            'PromptPay and other show the kind icon.',
        child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              IdentifierRow(
                identifier: const AccountIdentifier(
                  kind: IdentifierKind.bankAccount,
                  value: '1234527806',
                  bankCode: '004',
                ),
                providers: providers,
              ),
              IdentifierRow(
                identifier: const AccountIdentifier(
                  kind: IdentifierKind.promptPay,
                  value: '0812345678',
                ),
                providers: providers,
              ),
              IdentifierRow(
                identifier: const AccountIdentifier(
                  kind: IdentifierKind.card,
                  value: 'xxxxxxxxxxxx2780',
                  bankCode: '014',
                ),
                providers: providers,
              ),
              IdentifierRow(
                identifier: const AccountIdentifier(
                  kind: IdentifierKind.other,
                  value: '99887766',
                ),
                providers: providers,
              ),
            ],
          ),
        ),
      ),
      HubDemo(
        title: 'IdentifierRow — hidden · with delete · unknown bank',
        child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              IdentifierRow(
                identifier: const AccountIdentifier(
                  kind: IdentifierKind.bankAccount,
                  value: '1234527806',
                  bankCode: '014',
                ),
                providers: providers,
                hidden: true,
              ),
              IdentifierRow(
                identifier: const AccountIdentifier(
                  kind: IdentifierKind.promptPay,
                  value: '0812345678',
                ),
                providers: providers,
                onDelete: () {},
              ),
              IdentifierRow(
                identifier: const AccountIdentifier(
                  kind: IdentifierKind.bankAccount,
                  value: '5550001234',
                  bankCode: '777',
                ),
                providers: const [],
              ),
            ],
          ),
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
