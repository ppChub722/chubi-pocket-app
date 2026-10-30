import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/link_draft.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/splits_section.dart';
import 'package:flutter_test/flutter_test.dart';

const _boss = LinkPerson(name: 'บอส', contactId: 'c1');
const _lee = LinkPerson(name: 'ลี', contactId: 'c2');
const _mtk = LinkPerson(name: 'มาตาก');

DraftFormController _form() {
  final c = DraftFormController()..amount.text = '120';
  addTearDown(c.dispose);
  return c;
}

SplitDraft _split(String name, double owed, {String? id}) =>
    SplitDraft(personName: name, contactId: id, owedAmount: owed);

Transaction _tx(Map<String, dynamic> extra) => Transaction.fromJson({
  'id': 't1',
  'type': 'expense',
  'amount': 120,
  'date': '2026-10-21',
  ...extra,
});

void main() {
  test('LinkPerson: identity, the wire, already an event member', () {
    expect(_boss.key, 'c:c1');
    expect(const LinkPerson(name: ' มาตาก ').key, _mtk.key);
    expect(_boss == const LinkPerson(name: 'Boss', contactId: 'c1'), isTrue);
    expect(_boss.toJson(), {'contact_id': 'c1'});
    expect(_mtk.toJson(), {'person_name': 'มาตาก'});

    expect(_boss.isMember(name: 'X', contactId: 'c1'), isTrue);
    expect(_boss.isMember(name: 'บอส', contactId: 'c9'), isFalse);
    const linked = LinkPerson(
      name: 'Lee',
      contactId: 'c2',
      person: EmbeddedPerson(
        name: 'Lee',
        contactId: 'c2',
        linked: true,
        linkedUserId: 'u7',
      ),
    );
    expect(linked.isMember(name: 'Lee L.', userId: 'u7'), isTrue);
    expect(linked.isMember(name: 'Lee', userId: 'u8'), isFalse);
    expect(_mtk.isMember(name: ' มาตาก '), isTrue);
    expect(
      const LinkPerson(name: 'Ann').isMember(name: 'ANN', contactId: 'c5'),
      isTrue,
    );
    expect(_mtk.isMember(name: 'บอส'), isFalse);
  });

  test('จ่ายแทน math', () {
    final all = LinkDraft()..paidBy = _lee;
    expect(all.paidAmountFor(123), 123);
    expect(all.myPaid(123), 0);
    expect(all.payDiff(123), 0);
    expect(all.walletOut(LinkMode.paid, 123), 0);
    expect(all.paidByJson(123), {'contact_id': 'c2', 'amount': 123});

    final part = LinkDraft()
      ..paidBy = _lee
      ..paidAmount = 13;
    expect(part.myPaid(123), 110);
    expect(part.payDiff(123), 0);
    expect(part.walletOut(LinkMode.paid, 123), 110);

    final typed = LinkDraft()
      ..paidAmount = 13
      ..myPaidAuto = false
      ..myPaidTyped = 100;
    expect(typed.payDiff(123), -10);
    typed.myPaidTyped = 120;
    expect(typed.payDiff(123), 10);

    final more = LinkDraft()..paidAmount = 150;
    expect(more.myPaid(123), 0);
    expect(more.payDiff(123), 27);

    final equally = LinkDraft()
      ..myPaidAuto = false
      ..myPaidTyped = 5
      ..paidEqually(123);
    expect(equally.paidAmount, 61.5);
    expect(equally.myPaidAuto, isTrue);
    expect(equally.myPaid(123), 61.5);
  });

  test('อีเวนต์ shares and members', () {
    final members = LinkDraft()
      ..paidBy = _lee
      ..eventPayer = _boss;
    expect(members.eventMembers([_boss, _mtk]), [_boss, _mtk, _lee]);

    final equal = LinkDraft();
    final m = [_boss, _mtk];
    expect(equal.eventEqualShare(100, m), 33.33);
    expect(equal.eventOthers(100, m), 66.66);
    expect(equal.eventMine(100, m), 33.34);
    expect(equal.eventDiff(100, m), 0);

    final typedShare = LinkDraft()..eventShares[_boss.key] = 50;
    expect(typedShare.eventShareOf(_mtk, 120, m), 40);
    expect(typedShare.eventMine(120, m), 30);
    expect(typedShare.eventDiff(120, m), 0);

    final meTyped = LinkDraft()
      ..eventMeAuto = false
      ..eventMeTyped = 10;
    expect(meTyped.eventDiff(90, [_boss]), -35);

    final reset = LinkDraft()
      ..eventShares[_boss.key] = 70
      ..eventMeAuto = false
      ..eventEqually();
    expect(reset.eventShares, isEmpty);
    expect(reset.eventMeAuto, isTrue);
  });

  test('อีเวนต์ wallet and the wire (B2)', () {
    final d = LinkDraft();
    expect(d.walletOut(LinkMode.event, 90), 90);
    expect(d.eventJson(90, [_boss, _mtk]), {
      'payer': {'me': true},
      'members': [
        {'me': true, 'share': 30.0},
        {'contact_id': 'c1', 'share': 30.0},
        {'person_name': 'มาตาก', 'share': 30.0},
      ],
    });
    d.eventPayer = _lee;
    expect(d.walletOut(LinkMode.event, 90), 0);
    d.eventPayer = _boss;
    expect(d.eventJson(90, [_boss])['payer'], {'contact_id': 'c1'});
  });

  test('switching tabs carries the payer; leaving อีเวนต์ keeps its data', () {
    final fromPaid = LinkDraft()..paidBy = _lee;
    fromPaid.switchTo(LinkMode.event, from: LinkMode.paid);
    expect(fromPaid.eventPayer, _lee);
    expect(fromPaid.mode, LinkMode.event);

    final fromSplit = LinkDraft()..eventPayer = _lee;
    fromSplit.switchTo(LinkMode.event, from: LinkMode.split);
    expect(fromSplit.eventPayer, isNull);

    final leaving = LinkDraft()
      ..eventPayer = _boss
      ..eventShares[_mtk.key] = 20;
    leaving.switchTo(LinkMode.personal, from: LinkMode.event);
    expect(leaving.eventPayer, _boss);
    expect(leaving.eventShares, isNotEmpty);
  });

  test('form: tab inferred, my share, A toggles, removing a member', () {
    final inferred = _form();
    expect(inferred.linkMode(hasEvent: false), LinkMode.personal);
    expect(inferred.linkMode(hasEvent: true), LinkMode.event);
    inferred.setSplits([_split('บอส', 40, id: 'c1')]);
    expect(inferred.linkMode(hasEvent: false), LinkMode.split);
    inferred.setLinkMode(LinkMode.paid, hasEvent: false);
    expect(inferred.linkMode(hasEvent: true), LinkMode.paid);

    final share = _form()..setSplits([_split('บอส', 40, id: 'c1')]);
    expect(share.myShareFor(LinkMode.personal), 120);
    expect(share.myShareFor(LinkMode.split), 80);
    // Someone else paid: only my share (the bill less บอส's 40) is saved.
    expect(share.myShareFor(LinkMode.paid), 80);
    expect(share.myShareFor(LinkMode.event), 60);

    final toggles = _form()
      ..setPaidAmount(20)
      ..setMyPaidAuto(false);
    expect(toggles.link.myPaidTyped, 100);
    toggles.amount.text = '150';
    expect(toggles.link.myPaid(toggles.amountValue), 100);
    expect(toggles.linkBalanced(LinkMode.paid), isFalse);
    toggles
      ..setPaidBy(_lee)
      ..setMyPaidAuto(true);
    expect(toggles.linkBalanced(LinkMode.paid), isTrue);

    final removing = _form()
      ..setSplits([_split('บอส', 40, id: 'c1'), _split('มาตาก', 40)])
      ..setLinkMode(LinkMode.paid, hasEvent: false)
      ..setPaidBy(_boss)
      ..setLinkMode(LinkMode.event, hasEvent: false);
    expect(removing.link.eventPayer, _boss);
    removing.removeEventMember(_boss);
    expect(removing.link.eventPayer, isNull);
    expect(removing.link.paidBy, isNull);
    expect(removing.splitPeople, [_mtk]);
  });

  test('linkSave: ส่วนตัว / แบ่ง / no tab picked', () {
    final none = _form()..setSplits([_split('บอส', 40, id: 'c1')]);
    final today = none.linkSave(none.linkMode(hasEvent: false));
    expect(today.splits, hasLength(1));
    expect(today.useWallet, isTrue);
    expect(today.link, isNull);

    final personal = _form()
      ..setSplits([_split('บอส', 40, id: 'c1')])
      ..setLinkMode(LinkMode.personal, hasEvent: false);
    final p = personal.linkSave(LinkMode.personal);
    expect(p.splits, isEmpty);
    expect(p.link, isNull);

    final split = _form()
      ..setSplits([_split('บอส', 40, id: 'c1'), SplitDraft()])
      ..setLinkMode(LinkMode.split, hasEvent: false);
    final s = split.linkSave(LinkMode.split);
    expect(s.splits.single['contact_id'], 'c1');
    expect(s.link, isNull);
  });

  test('linkSave: จ่ายแทน and อีเวนต์', () {
    final all = _form()
      ..setLinkMode(LinkMode.paid, hasEvent: false)
      ..setPaidBy(_lee);
    final a = all.linkSave(LinkMode.paid);
    expect(a.useWallet, isFalse);
    expect(a.splits, isEmpty);
    expect(a.link, {
      'paid_by': {'contact_id': 'c2', 'amount': 120.0},
    });

    final part = _form()
      ..setLinkMode(LinkMode.paid, hasEvent: false)
      ..setPaidBy(_lee)
      ..setPaidAmount(13);
    expect(part.linkSave(LinkMode.paid).useWallet, isTrue);
    expect(part.walletOutFor(LinkMode.paid), 107);

    final mine = _form()
      ..setSplits([_split('บอส', 40, id: 'c1')])
      ..setLinkMode(LinkMode.event, hasEvent: true);
    final e = mine.linkSave(LinkMode.event);
    expect(e.useWallet, isTrue);
    expect(e.splits, isEmpty);
    expect(e.link, {
      'payer': {'me': true},
      'members': [
        {'me': true, 'share': 60.0},
        {'contact_id': 'c1', 'share': 60.0},
      ],
    });

    final theirs = _form()
      ..setLinkMode(LinkMode.event, hasEvent: true)
      ..setEventPayer(_lee);
    final t = theirs.linkSave(LinkMode.event);
    expect(t.useWallet, isFalse);
    expect(t.splits, isEmpty);
    expect(t.link!['payer'], {'contact_id': 'c2'});
  });

  test(
    'linkSave: income keeps the tab (รับแทน), a transfer carries no link',
    () {
      final income = _form()
        ..setType(TransactionType.income)
        ..setLinkMode(LinkMode.split, hasEvent: false)
        ..setPaidBy(_lee);
      expect(income.linkMode(hasEvent: false), LinkMode.paid);
      expect(
        (income.linkSave(LinkMode.paid).link!['paid_by'] as Map)['contact_id'],
        'c2',
      );

      final transfer = _form()
        ..setType(TransactionType.transfer)
        ..setLinkMode(LinkMode.paid, hasEvent: false);
      final s = transfer.linkSave(LinkMode.paid);
      expect(s.link, isNull);
      expect(s.useWallet, isTrue);

      expect(LinkMode.parse('paid'), LinkMode.paid);
      expect(LinkMode.parse('event'), LinkMode.event);
      expect(LinkMode.parse('paid_by'), isNull);
      expect(LinkMode.parse(null), isNull);
    },
  );

  test('toDraft: only the active tab goes in', () {
    final c = _form()
      ..setSplits([_split('บอส', 40, id: 'c1')])
      ..setLinkMode(LinkMode.paid, hasEvent: false)
      ..setPaidBy(_lee);
    var d = c.toDraft();
    expect(d.splits, isEmpty);
    // paid_by carries only my share: the bill 120 less บอส's 40.
    expect(d.paidBy, {'contact_id': 'c2', 'amount': 80.0});
    expect(d.toJson()['paid_by'], isNotNull);

    c.setLinkMode(LinkMode.event, hasEvent: true);
    d = c.toDraft(eventProjectId: 'p1');
    expect(d.paidBy, isNull);
    expect(d.projectId, 'p1');
    expect(d.payer, {'contact_id': 'c2'});
    expect(d.members.first, {'me': true, 'share': 40.0});
    expect(d.members, hasLength(3));

    // The แบ่ง tab is จ่ายแทน while someone else is the payer: back to me.
    c
      ..setPaidBy(null)
      ..setLinkMode(LinkMode.split, hasEvent: false);
    d = c.toDraft();
    expect(d.splits.single['contact_id'], 'c1');
    expect(d.projectId, isNull);
    expect(d.payer, isNull);

    final plain = _form()
      ..projectId = 'p1'
      ..setSplits([_split('บอส', 40, id: 'c1')]);
    final before = plain.toDraft();
    expect(before.splits, hasLength(1));
    expect(before.projectId, 'p1');
    expect(before.paidBy, isNull);
  });

  test('a draft reopens on its tab', () {
    final event = PendingTransaction.fromJson({
      'id': 'd1',
      'source': 'manual',
      'status': 'pending',
      'created_at': '2026-10-22T08:00:00Z',
      'draft': {
        'type': 'expense',
        'amount': 120,
        'project_id': 'p1',
        'payer': {'member_id': 'm2'},
        'members': [
          {'me': true, 'share': 60},
          {'member_id': 'm2', 'share': 60},
        ],
      },
      'resolved': {
        'link_mode': 'event',
        'bill_people': {
          'payer': {
            'me': false,
            'member_id': 'm2',
            'contact_id': null,
            'name': 'Ann',
          },
          'members': [
            {
              'me': true,
              'member_id': 'm1',
              'contact_id': null,
              'name': '',
              'share': 60,
            },
            {
              'me': false,
              'member_id': 'm2',
              'contact_id': null,
              'name': 'Ann',
              'share': 60,
            },
          ],
        },
      },
    });
    expect(event.draft.payer, {'member_id': 'm2'});
    expect(event.draft.members, hasLength(2));
    expect(event.resolved.linkMode, LinkMode.event);
    final c = _form()..prefillLinkFromDraft(event.draft, event.resolved);
    expect(c.pickedTab, LinkMode.event);
    expect(c.link.eventPayer!.memberId, 'm2');
    expect(c.myShareFor(LinkMode.event), 60);
    final again = c.toDraft(eventProjectId: 'p1');
    expect(again.payer, {'member_id': 'm2'});
    expect(again.members.last, {'member_id': 'm2', 'share': 60.0});

    final paid = PendingTransaction.fromJson({
      'id': 'd2',
      'source': 'manual',
      'status': 'pending',
      'created_at': '2026-10-22T08:00:00Z',
      'draft': {
        'type': 'expense',
        'amount': 120,
        'paid_by': {'contact_id': 'c2', 'amount': 20},
      },
      'resolved': {
        'link_mode': 'paid',
        'paid_by': {
          'person': {'name': 'ลี', 'contact_id': 'c2'},
          'amount': 20,
          'my_paid': 100,
        },
      },
    });
    final p = _form()..prefillLinkFromDraft(paid.draft, paid.resolved);
    expect(p.pickedTab, LinkMode.paid);
    expect(p.link.paidBy, _lee);
    expect(p.walletOutFor(LinkMode.paid), 100);
  });

  test('editing a saved tx opens on its tab (B3)', () {
    final paid = _form()
      ..prefillLink(
        _tx({
          'link_mode': 'paid',
          'paid_by': {
            'debt_id': 'd1',
            'key': 'c:c2',
            'person': {'name': 'ลี', 'contact_id': 'c2'},
            'amount': 20,
            'my_paid': 100,
            'source': 'me',
            'paid': false,
          },
        }),
      );
    expect(paid.pickedTab, LinkMode.paid);
    expect(paid.link.paidBy, _lee);
    expect(paid.link.myPaid(120), 100);
    expect(paid.linkEditJson(LinkMode.paid), {
      'link_mode': 'paid',
      'paid_by': {'contact_id': 'c2', 'amount': 20.0},
    });

    final event = _form()
      ..prefillLink(
        _tx({
          'link_mode': 'event',
          'event_bill': {
            'event': {'id': 'p1', 'name': 'Trip'},
            'bill_id': 'b1',
            'linked': true,
            'kind': 'origin',
            'payer': {'id': 'm1', 'name': 'Me', 'is_me': true},
            'bill_amount': 120,
            'members': [
              {
                'member': {'id': 'm1', 'name': 'Me', 'is_me': true},
                'share': 80,
              },
              {
                'member': {'id': 'm2', 'name': 'Ann', 'is_me': false},
                'share': 40,
              },
            ],
          },
        }),
      );
    expect(event.pickedTab, LinkMode.event);
    expect(event.link.eventPayer, isNull);
    expect(event.myShareFor(LinkMode.event), 80);
    expect(event.linkEditJson(LinkMode.event, projectId: 'p1'), {
      'link_mode': 'event',
      'event': {
        'project_id': 'p1',
        'payer': {'me': true},
        'members': [
          {'me': true, 'share': 80.0},
          {'member_id': 'm2', 'share': 40.0},
        ],
      },
    });
  });

  test('the snapshot moves only with the tab data; แบ่ง keeps debt ids', () {
    final c = _form()..prefillLink(_tx({'link_mode': 'personal'}));
    final base = c.linkSnapshot(LinkMode.paid);
    expect(c.linkSnapshot(LinkMode.paid), base);
    c.setPaidBy(_lee);
    expect(c.linkSnapshot(LinkMode.paid), isNot(base));
    expect(c.linkEditJson(LinkMode.personal), {'link_mode': 'personal'});

    c.setSplits([_split('บอส', 40, id: 'c1')]);
    final json = c.linkEditJson(LinkMode.split);
    expect(json['link_mode'], 'split');
    expect((json['splits'] as List).single['contact_id'], 'c1');
  });

  test(
    'an event added to / taken off แบ่ง flips the tab and carries amounts',
    () {
      final c = _form()
        ..setSplits([_split('บอส', 40, id: 'c1')])
        ..setLinkMode(LinkMode.split, hasEvent: false)
        ..setPaidBy(_lee);
      expect(c.linkMode(hasEvent: false), LinkMode.paid);

      c.eventChanged(hasEvent: true);
      expect(c.linkMode(hasEvent: true), LinkMode.event);
      expect(c.link.eventPayer, _lee);
      expect(c.link.eventShares[_boss.key], 40);

      c.link.eventShares[_boss.key] = 50;
      c.eventChanged(hasEvent: false);
      expect(c.linkMode(hasEvent: false), LinkMode.paid);
      expect(c.splits.single.owedAmount, 50);
      expect(c.link.paidBy, _lee);

      // Not on the bill tab (ส่วนตัว): the event changes nothing.
      final personal = _form()..setLinkMode(LinkMode.personal, hasEvent: false);
      personal.eventChanged(hasEvent: true);
      expect(personal.linkMode(hasEvent: false), LinkMode.personal);
    },
  );

  test('the bill tab opens with an empty person; people go after the rest', () {
    final c = _form()..setLinkMode(LinkMode.split, hasEvent: false);
    expect(c.splits, hasLength(1));
    expect(c.splits.single.personName, isEmpty);

    // Nothing entered yet: the event's people take the empty row's place.
    c.addPeople([_boss, _mtk]);
    expect(c.splitPeople, [_boss, _mtk]);
    expect(c.splits, hasLength(2));

    // Something entered: new people follow, nobody twice.
    c.splits.first.owedAmount = 30;
    c.addPeople([_boss, _lee]);
    expect(c.splitPeople, [_boss, _mtk, _lee]);
  });

  test('renaming a typed row keeps its share and the payer mark', () {
    final c = _form()
      ..setSplits([_split('มา', 40)])
      ..setLinkMode(LinkMode.split, hasEvent: false);
    final row = c.splits.single;
    c.link.eventShares[const LinkPerson(name: 'มา').key] = 25;
    c.setPaidBy(const LinkPerson(name: 'มา'));

    c.renameDraft(row, 'มาตาก');
    expect(c.link.eventShares[_mtk.key], 25);
    expect(c.link.paidBy, _mtk);
    expect(c.link.eventShares.containsKey('n:มา'), isFalse);
  });

  test(
    '"คืนแล้ว": who paid back and what they owe, on แบ่ง and on an event',
    () {
      final c = _form()
        ..setSplits([_split('บอส', 40, id: 'c1'), _split('มาตาก', 30)])
        ..setLinkMode(LinkMode.split, hasEvent: false);
      expect(c.paidBackShares(event: false), isEmpty);

      c.togglePaidBack(_boss);
      expect(c.isPaidBack(_boss), isTrue);
      final back = c.paidBackShares(event: false);
      expect(back.single.person, _boss);
      expect(back.single.amount, 40);

      // The payer can't have paid back, a rename keeps the mark, × drops it.
      c.renameDraft(c.splits.last, 'มาตาก ๒');
      c.togglePaidBack(const LinkPerson(name: 'มาตาก ๒'));
      expect(c.paidBackShares(event: false), hasLength(2));
      c.setPaidBy(_boss);
      expect(c.isPaidBack(_boss), isFalse);
      c.removeDraft(c.splits.last);
      expect(c.link.paidBack, isEmpty);

      // On an event bill the share is the event share (equal when not typed).
      final e = _form()
        ..setSplits([_split('บอส', 40, id: 'c1')])
        ..setLinkMode(LinkMode.event, hasEvent: true)
        ..togglePaidBack(_boss);
      expect(e.paidBackShares(event: true).single.amount, 60);
    },
  );

  test(
    '"จดหนี้ด้วย" on an event bill: who owes me, or what I owe the payer',
    () {
      final c = _form()
        ..setSplits([_split('บอส', 40, id: 'c1'), _split('มาตาก', 30)])
        ..setLinkMode(LinkMode.event, hasEvent: true);
      var d = c.eventDebts();
      expect(d.payer, isNull);
      expect(d.owedToMe.map((r) => r.person), [_boss, _mtk]);

      // Paid back on the spot: no debt for that one.
      c.togglePaidBack(_mtk);
      expect(c.eventDebts().owedToMe.map((r) => r.person), [_boss]);

      // Someone else paid: nobody owes me; my share is owed to them.
      c.setEventPayer(_lee);
      d = c.eventDebts();
      expect(d.owedToMe, isEmpty);
      expect(d.payer, _lee);
      expect(d.myShare, greaterThan(0));
    },
  );

  test(
    '"จ่าย" / "คืนแล้ว" on a row with no name can be pressed, not saved',
    () {
      final c = _form()..setLinkMode(LinkMode.split, hasEvent: false);
      final blank = c.splits.single;
      expect(c.markedWithoutName(LinkMode.split), isFalse);

      c.togglePaidBack(const LinkPerson(name: ''));
      expect(c.markedWithoutName(LinkMode.split), isTrue);

      // The name arrives: the mark follows it and the bill can be saved.
      c.renameDraft(blank, 'มาตาก');
      expect(c.isPaidBack(_mtk), isTrue);
      expect(c.markedWithoutName(LinkMode.split), isFalse);

      c.setPaidBy(const LinkPerson(name: ''));
      expect(c.markedWithoutName(LinkMode.paid), isTrue);
      expect(c.eventMembers.where((p) => p.name.isEmpty), isEmpty);
    },
  );
}
