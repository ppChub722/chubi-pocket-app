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

void main() {
  group('LinkPerson', () {
    test('a contact is its id, a typed name its text', () {
      expect(_boss.key, 'c:c1');
      expect(const LinkPerson(name: ' มาตาก ').key, _mtk.key);
      expect(_boss == const LinkPerson(name: 'Boss', contactId: 'c1'), isTrue);
      expect(_boss.toJson(), {'contact_id': 'c1'});
      expect(_mtk.toJson(), {'person_name': 'มาตาก'});
    });
  });

  group('already an event member?', () {
    test('a contact: by the member contact_id, or its linked user', () {
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
    });

    test('a typed name: by name, any case', () {
      expect(_mtk.isMember(name: ' มาตาก '), isTrue);
      expect(
        const LinkPerson(name: 'Ann').isMember(name: 'ANN', contactId: 'c5'),
        isTrue,
      );
      expect(_mtk.isMember(name: 'บอส'), isFalse);
    });
  });

  group('จ่ายแทน', () {
    test('they paid it all: nothing from my wallet, ✓', () {
      final d = LinkDraft()..paidBy = _lee;
      expect(d.paidAmountFor(123), 123);
      expect(d.myPaid(123), 0);
      expect(d.payDiff(123), 0);
      expect(d.walletOut(LinkMode.paid, 123), 0);
      expect(d.paidByJson(123), {'contact_id': 'c2', 'amount': 123});
    });

    test('they paid part: A fills mine with the rest', () {
      final d = LinkDraft()
        ..paidBy = _lee
        ..paidAmount = 13;
      expect(d.myPaid(123), 110);
      expect(d.payDiff(123), 0);
      expect(d.walletOut(LinkMode.paid, 123), 110);
    });

    test('mine typed: ยังขาด / เกินยอด', () {
      final d = LinkDraft()
        ..paidAmount = 13
        ..myPaidAuto = false
        ..myPaidTyped = 100;
      expect(d.payDiff(123), -10);
      d.myPaidTyped = 120;
      expect(d.payDiff(123), 10);
    });

    test('they paid more than the bill: mine stays at 0', () {
      final d = LinkDraft()..paidAmount = 150;
      expect(d.myPaid(123), 0);
      expect(d.payDiff(123), 27);
    });

    test('หารเท่ากัน: half each, mine back on auto', () {
      final d = LinkDraft()
        ..myPaidAuto = false
        ..myPaidTyped = 5
        ..paidEqually(123);
      expect(d.paidAmount, 61.5);
      expect(d.myPaidAuto, isTrue);
      expect(d.myPaid(123), 61.5);
    });
  });

  group('อีเวนต์', () {
    test(
      'members: แบ่ง people + the one who paid for me + the payer, once',
      () {
        final d = LinkDraft()
          ..paidBy = _lee
          ..eventPayer = _boss;
        expect(d.eventMembers([_boss, _mtk]), [_boss, _mtk, _lee]);
      },
    );

    test('equal shares; ฉัน on A takes the rounding rest', () {
      final d = LinkDraft();
      final m = [_boss, _mtk];
      expect(d.eventEqualShare(100, m), 33.33);
      expect(d.eventOthers(100, m), 66.66);
      expect(d.eventMine(100, m), 33.34);
      expect(d.eventDiff(100, m), 0);
    });

    test('a typed share stays; ฉัน on A absorbs the difference', () {
      final d = LinkDraft()..eventShares[_boss.key] = 50;
      final m = [_boss, _mtk];
      expect(d.eventShareOf(_mtk, 120, m), 40);
      expect(d.eventMine(120, m), 30);
      expect(d.eventDiff(120, m), 0);
    });

    test('ฉัน typed: the status shows the gap', () {
      final d = LinkDraft()
        ..eventMeAuto = false
        ..eventMeTyped = 10;
      expect(d.eventDiff(90, [_boss]), -35);
    });

    test('หารเท่ากัน drops typed shares and puts ฉัน back on A', () {
      final d = LinkDraft()
        ..eventShares[_boss.key] = 70
        ..eventMeAuto = false
        ..eventEqually();
      expect(d.eventShares, isEmpty);
      expect(d.eventMeAuto, isTrue);
    });

    test('the wallet pays only while I am the payer', () {
      final d = LinkDraft();
      expect(d.walletOut(LinkMode.event, 90), 90);
      d.eventPayer = _lee;
      expect(d.walletOut(LinkMode.event, 90), 0);
    });

    test('the wire (B2): payer, everyone in the bill with a share, me too', () {
      final d = LinkDraft();
      expect(d.eventJson(90, [_boss, _mtk]), {
        'payer': {'me': true},
        'members': [
          {'me': true, 'share': 30.0},
          {'contact_id': 'c1', 'share': 30.0},
          {'person_name': 'มาตาก', 'share': 30.0},
        ],
      });
      d.eventPayer = _boss;
      expect(d.eventJson(90, [_boss])['payer'], {'contact_id': 'c1'});
    });
  });

  group('switching tabs (carry-over)', () {
    test('จ่ายแทน → อีเวนต์: the one who paid pays the event bill', () {
      final d = LinkDraft()..paidBy = _lee;
      d.switchTo(LinkMode.event, from: LinkMode.paid);
      expect(d.eventPayer, _lee);
      expect(d.mode, LinkMode.event);
    });

    test('แบ่ง → อีเวนต์: I pay', () {
      final d = LinkDraft()..eventPayer = _lee;
      d.switchTo(LinkMode.event, from: LinkMode.split);
      expect(d.eventPayer, isNull);
    });

    test('leaving อีเวนต์ keeps its data (only the active tab saves)', () {
      final d = LinkDraft()
        ..eventPayer = _boss
        ..eventShares[_mtk.key] = 20;
      d.switchTo(LinkMode.personal, from: LinkMode.event);
      expect(d.eventPayer, _boss);
      expect(d.eventShares, isNotEmpty);
    });
  });

  group('DraftFormController', () {
    late DraftFormController c;
    setUp(() => c = DraftFormController()..amount.text = '120');
    tearDown(() => c.dispose());

    SplitDraft split(String name, double owed, {String? id}) =>
        SplitDraft(personName: name, contactId: id, owedAmount: owed);

    test('the tab is inferred until one is picked', () {
      expect(c.linkMode(hasEvent: false), LinkMode.personal);
      expect(c.linkMode(hasEvent: true), LinkMode.event);
      c.setSplits([split('บอส', 40, id: 'c1')]);
      expect(c.linkMode(hasEvent: false), LinkMode.split);
      c.setLinkMode(LinkMode.paid, hasEvent: false);
      expect(c.linkMode(hasEvent: true), LinkMode.paid);
    });

    test('my share per tab', () {
      c.setSplits([split('บอส', 40, id: 'c1')]);
      expect(c.myShareFor(LinkMode.personal), 120);
      expect(c.myShareFor(LinkMode.split), 80);
      expect(c.myShareFor(LinkMode.paid), 120);
      // อีเวนต์ reads the same people: 120 / 2.
      expect(c.myShareFor(LinkMode.event), 60);
    });

    test('A toggles freeze the auto value when switched off', () {
      c
        ..setPaidAmount(20)
        ..setMyPaidAuto(false);
      expect(c.link.myPaidTyped, 100);
      c.amount.text = '150';
      expect(c.link.myPaid(c.amountValue), 100);
      expect(c.linkBalanced(LinkMode.paid), isFalse); // no payer + ยังขาด
      c
        ..setPaidBy(_lee)
        ..setMyPaidAuto(true);
      expect(c.linkBalanced(LinkMode.paid), isTrue);
    });

    test('removing a member leaves every view', () {
      c
        ..setSplits([split('บอส', 40, id: 'c1'), split('มาตาก', 40)])
        ..setLinkMode(LinkMode.paid, hasEvent: false)
        ..setPaidBy(_boss)
        ..setLinkMode(LinkMode.event, hasEvent: false);
      expect(c.link.eventPayer, _boss);
      c.removeEventMember(_boss);
      expect(c.link.eventPayer, isNull);
      expect(c.link.paidBy, isNull);
      expect(c.splitPeople, [_mtk]);
    });

    group('linkSave', () {
      test('no tab picked: today\'s body (splits, wallet, no link)', () {
        c.setSplits([split('บอส', 40, id: 'c1')]);
        final s = c.linkSave(c.linkMode(hasEvent: false));
        expect(s.splits, hasLength(1));
        expect(s.useWallet, isTrue);
        expect(s.link, isNull);
      });

      test('ส่วนตัว: a plain tx, the แบ่ง rows stay home', () {
        c
          ..setSplits([split('บอส', 40, id: 'c1')])
          ..setLinkMode(LinkMode.personal, hasEvent: false);
        final s = c.linkSave(LinkMode.personal);
        expect(s.splits, isEmpty);
        expect(s.link, isNull);
      });

      test('แบ่ง: the complete rows', () {
        c
          ..setSplits([split('บอส', 40, id: 'c1'), SplitDraft()])
          ..setLinkMode(LinkMode.split, hasEvent: false);
        final s = c.linkSave(LinkMode.split);
        expect(s.splits.single['contact_id'], 'c1');
        expect(s.link, isNull);
      });

      test('จ่ายแทน all: no wallet, paid_by', () {
        c
          ..setLinkMode(LinkMode.paid, hasEvent: false)
          ..setPaidBy(_lee);
        final s = c.linkSave(LinkMode.paid);
        expect(s.useWallet, isFalse);
        expect(s.splits, isEmpty);
        expect(s.link, {
          'paid_by': {'contact_id': 'c2', 'amount': 120.0},
        });
      });

      test('จ่ายแทน part: my wallet pays the rest', () {
        c
          ..setLinkMode(LinkMode.paid, hasEvent: false)
          ..setPaidBy(_lee)
          ..setPaidAmount(13);
        expect(c.linkSave(LinkMode.paid).useWallet, isTrue);
        expect(c.walletOutFor(LinkMode.paid), 107);
      });

      test('อีเวนต์, I pay: wallet, no splits, payer + members (B2)', () {
        c
          ..setSplits([split('บอส', 40, id: 'c1')])
          ..setLinkMode(LinkMode.event, hasEvent: true);
        final s = c.linkSave(LinkMode.event);
        expect(s.useWallet, isTrue);
        expect(s.splits, isEmpty);
        expect(s.link, {
          'payer': {'me': true},
          'members': [
            {'me': true, 'share': 60.0},
            {'contact_id': 'c1', 'share': 60.0},
          ],
        });
      });

      test('อีเวนต์, someone else pays: no wallet, no splits', () {
        c
          ..setLinkMode(LinkMode.event, hasEvent: true)
          ..setEventPayer(_lee);
        final s = c.linkSave(LinkMode.event);
        expect(s.useWallet, isFalse);
        expect(s.splits, isEmpty);
        expect(s.link!['payer'], {'contact_id': 'c2'});
      });

      test('a tab picked on an expense is ignored once it is income', () {
        c
          ..setSplits([split('บอส', 40, id: 'c1')])
          ..setLinkMode(LinkMode.paid, hasEvent: false)
          ..setType(TransactionType.income);
        expect(c.linkMode(hasEvent: false), LinkMode.split);
        expect(c.linkSave(LinkMode.split).link, isNull);
      });

      test('the read-only link_mode parses (B1)', () {
        expect(LinkMode.parse('paid'), LinkMode.paid);
        expect(LinkMode.parse('event'), LinkMode.event);
        expect(LinkMode.parse('paid_by'), isNull);
        expect(LinkMode.parse(null), isNull);
      });

      test('a transfer never carries link data', () {
        c
          ..setType(TransactionType.transfer)
          ..setLinkMode(LinkMode.paid, hasEvent: false);
        final s = c.linkSave(LinkMode.paid);
        expect(s.link, isNull);
        expect(s.useWallet, isTrue);
      });
    });

    group('editing a saved tx (B3)', () {
      Transaction tx(Map<String, dynamic> extra) => Transaction.fromJson({
        'id': 't1',
        'type': 'expense',
        'amount': 120,
        'date': '2026-10-21',
        ...extra,
      });

      test('จ่ายแทน: opens on that tab with the payer and amount', () {
        c.prefillLink(
          tx({
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
        expect(c.pickedTab, LinkMode.paid);
        expect(c.link.paidBy, _lee);
        expect(c.link.myPaid(120), 100);
        expect(c.linkEditJson(LinkMode.paid), {
          'link_mode': 'paid',
          'paid_by': {'contact_id': 'c2', 'amount': 20.0},
        });
      });

      test('อีเวนต์: the bill people come back as members (member_id)', () {
        c.prefillLink(
          tx({
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
        expect(c.pickedTab, LinkMode.event);
        expect(c.link.eventPayer, isNull);
        expect(c.myShareFor(LinkMode.event), 80);
        expect(c.linkEditJson(LinkMode.event, projectId: 'p1'), {
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

      test('the snapshot moves only when the tab data does', () {
        c.prefillLink(tx({'link_mode': 'personal'}));
        final base = c.linkSnapshot(LinkMode.paid);
        expect(c.linkSnapshot(LinkMode.paid), base);
        c.setPaidBy(_lee);
        expect(c.linkSnapshot(LinkMode.paid), isNot(base));
        expect(c.linkEditJson(LinkMode.personal), {'link_mode': 'personal'});
      });

      test('แบ่ง sends the split edits (debt ids kept)', () {
        c
          ..prefillLink(tx({'link_mode': 'personal'}))
          ..setSplits([split('บอส', 40, id: 'c1')]);
        final json = c.linkEditJson(LinkMode.split);
        expect(json['link_mode'], 'split');
        expect((json['splits'] as List).single['contact_id'], 'c1');
      });
    });
  });
}
