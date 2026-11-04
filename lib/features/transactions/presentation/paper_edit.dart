import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../categories/presentation/cubit/categories_cubit.dart';
import '../../projects/data/projects_repository.dart';
import '../../projects/domain/paper.dart';
import '../../tags/domain/tag.dart';
import '../domain/link_draft.dart';
import '../domain/transaction.dart';
import '../domain/transaction_type.dart';
import 'cubit/transactions_cubit.dart';
import 'quick_create_bodies.dart';
import 'widgets/draft_form.dart';
import 'widgets/splits_section.dart' show SplitDraft;

/// Editing one bill in the form (owner 2026-11-03: quick create's bill form
/// and the transaction page share it): the bill into the form, and the save
/// that sends it back. Each person keeps their row (`person_id`).
class PaperEditSession {
  PaperEditSession(this.paper);

  final PaperView paper;

  /// [LinkPerson.key] → the person's row id on the bill.
  final personIds = <String, String>{};

  /// "คืนแล้ว" as the bill was opened (only the changes are sent).
  final paidBackAtOpen = <String>{};

  /// A payback's who paid / who got it (event members).
  String? fromMemberId;
  String? toMemberId;

  bool get isEvent => paper.projectId != null;

  /// My transaction of the bill; null = none in my books.
  Transaction? get myTransaction => switch (paper.myTransaction) {
    final Map<String, dynamic> j => Transaction.fromJson(j),
    _ => null,
  };

  /// A bill's person as the form keys them: by my contact when I have one
  /// (its shown name and avatar, as the members page; the event matches a
  /// bound member by it), else by the typed name.
  static LinkPerson personOf(PaperPersonView x) {
    final p = x.person;
    return p == null
        ? LinkPerson(name: x.name)
        : LinkPerson(name: p.name, contactId: p.contactId, person: p);
  }

  static String _amountText(double v) => v <= 0
      ? ''
      : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2));

  static String _draftKey(SplitDraft s) =>
      LinkPerson(name: s.personName.trim(), contactId: s.contactId).key;

  /// The bill into [c]: its fields, its people with their shares, payer and
  /// marks; my own fields (category, wallet, tags, private note) from my
  /// transaction of it, the category / wallet after this frame (their lists
  /// come from [context]).
  void prefill(BuildContext context, DraftFormController c) {
    final p = paper;
    if (!p.isPayback) {
      c.setType(
        p.type == 'income' ? TransactionType.income : TransactionType.expense,
      );
    }
    c.amount.text = _amountText(p.amount);
    c.description.text = p.description ?? '';
    if (DateTime.tryParse(p.date) case final d?) c.setDate(d);
    c.link.eventBookMine = p.myTransaction != null;
    c.link.eventBookDebts = p.myDebtIds.isNotEmpty;
    final tx = myTransaction;
    if (tx != null) {
      c.note.text = tx.privateNote ?? '';
      c.setTagIds({for (final t in tx.tags) t.id});
      for (final t in tx.tags) {
        c.knownTags[t.id] = Tag(id: t.id, name: t.name, iconCode: t.iconCode);
      }
      final categories = context.read<CategoriesCubit>();
      final accounts = context.read<AccountsCubit>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cat = tx.category;
        final acc = tx.account;
        c.setCategory(
          cat == null
              ? null
              : categories.state.categories
                        .where((x) => x.id == cat.id)
                        .firstOrNull ??
                    cat.toCategory(),
        );
        if (acc != null) {
          c.setAccount(
            accounts.state.accounts.where((a) => a.id == acc.id).firstOrNull ??
                acc.toAccount(),
          );
        }
      });
    }
    if (p.isPayback) {
      fromMemberId = p.people.where((x) => x.paid > 0).firstOrNull?.memberId;
      toMemberId = p.people.where((x) => x.share > 0).firstOrNull?.memberId;
      return;
    }
    final me = p.me;
    final others = [
      for (final x in p.people)
        if (!x.isMe) x,
    ];
    final payers = [
      for (final x in others)
        if (x.paid > 0.005) x,
    ]..sort((a, b) => b.paid.compareTo(a.paid));
    final payer = payers.firstOrNull;
    c.addPeople([for (final x in others) personOf(x)]);
    for (final x in others) {
      final key = personOf(x).key;
      personIds[key] = x.id;
      if (x.paidBack) {
        c.link.paidBack.add(key);
        paidBackAtOpen.add(key);
      }
    }
    if (isEvent) {
      c.link.eventPayer = payer == null ? null : personOf(payer);
      for (final x in others) {
        c.link.eventShares[personOf(x).key] = x.share;
      }
      c.link.eventMeAuto = false;
      c.link.eventMeTyped = me?.share ?? 0;
    } else {
      for (final s in c.splits) {
        final x = others
            .where((o) => personOf(o).key == _draftKey(s))
            .firstOrNull;
        if (x != null) s.owedAmount = x.share;
      }
      c.setSplits(List.of(c.splits));
      c.setMeAmount(me?.share ?? 0);
      if (payer != null) {
        c.setPaidBy(personOf(payer));
        c.setPaidAmount(payer.paid);
        if ((me?.paid ?? 0) > 0.005) c.setMyPaid(me!.paid);
      }
      c.setLinkMode(LinkMode.split, hasEvent: false);
    }
  }

  /// Saves the edited bill (`PUT` with the version read: 409 BILL_CHANGED
  /// when someone saved meanwhile), then what my switches add to my books,
  /// my own fields on my transaction, and the "คืนแล้ว" marks that changed.
  /// False = the form has no people to save (nothing sent).
  Future<bool> save({
    required ProjectsRepository projects,
    required TransactionsCubit txs,
    required DraftFormController c,
    required LinkMode mode,
  }) async {
    final edit = paper;
    final body = paperBodies(
      c,
      mode,
      personIds: personIds,
      mePersonId: edit.me?.id,
    );
    if (body == null) return false;
    final saved = await projects.updatePaper(
      edit.id,
      projectId: edit.projectId,
      paper: body.paper,
      version: edit.version,
    );
    final wantTx = c.link.eventBookMine && edit.myTransaction == null;
    final wantDebts = (c.link.eventBookDebts ?? false) && edit.myDebtIds.isEmpty;
    final split = edit.projectId == null;
    if (split ? edit.myTransaction == null : (wantTx || wantDebts)) {
      await projects.claimPaper(
        edit.id,
        projectId: edit.projectId,
        claim: {
          ...body.myBooks,
          if (!split && !wantTx) 'skip_transaction': true,
          if (!split && wantDebts) 'book_debts': true,
        },
      );
    }
    if (edit.myTransaction?['id'] case final String txId) {
      await txs.updateTransaction(
        id: txId,
        categoryId: c.category?.id,
        clearCategory: c.category == null,
        accountId: c.account?.id,
        tagIds: c.tagIds.toList(),
        privateNote: c.note.text.trim(),
      );
    }
    await savePaidBack(projects, c, saved.paperId, edit.projectId);
    return true;
  }

  /// A new bill's "คืนแล้ว" marks, set once its people exist ([paidBack] =
  /// places in `paper.people`, [personIds] = the ids in that order).
  static Future<void> markPaidBack(
    ProjectsRepository projects, {
    required String paperId,
    required String? projectId,
    required List<String> personIds,
    required List<int> paidBack,
  }) async {
    for (final i in paidBack) {
      if (i >= personIds.length) continue;
      await projects.markPaperPaidBack(
        paperId,
        personIds[i],
        projectId: projectId,
      );
    }
  }

  /// The "คืนแล้ว" marks that changed since the bill was opened.
  Future<void> savePaidBack(
    ProjectsRepository projects,
    DraftFormController c,
    String paperId,
    String? projectId,
  ) async {
    for (final key in {...paidBackAtOpen, ...c.link.paidBack}) {
      final now = c.link.paidBack.contains(key);
      if (now == paidBackAtOpen.contains(key)) continue;
      final pid = personIds[key];
      if (pid == null) continue;
      await projects.markPaperPaidBack(
        paperId,
        pid,
        projectId: projectId,
        paidBack: now,
      );
    }
  }
}
