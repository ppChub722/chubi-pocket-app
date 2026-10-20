import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:chubi_pocket/features/projects/presentation/cubit/projects_cubit.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction_type.dart';
import 'package:chubi_pocket/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/category_pick_card.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/splits_section.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../shared/fake_sync.dart';

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Contacts extends MockCubit<ContactsState> implements ContactsCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Txs extends MockCubit<TransactionsState> implements TransactionsCubit {}

class _Projects extends MockCubit<ProjectsState> implements ProjectsCubit {}

/// The pending drafts' layout (owner 2026-10-11, "เพิ่มร่าง" + "แก้ร่าง"):
/// dashed pick chips lead a wallet row above a category row, the note is
/// inline, and ผูกกับ is always open. A draft keeps
/// half-filled splits and its event.
void main() {
  late DraftFormController c;

  setUp(() => c = DraftFormController());
  tearDown(() => c.dispose());

  Future<void> pump(WidgetTester t) {
    t.view.physicalSize = const Size(800 * 3, 2000 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final accounts = _Accounts();
    final categories = _Categories();
    final contacts = _Contacts();
    final tags = _Tags();
    final txs = _Txs();
    final projects = _Projects();
    when(() => accounts.state).thenReturn(const AccountsState());
    when(() => categories.state).thenReturn(const CategoriesState());
    when(() => contacts.state).thenReturn(const ContactsState());
    when(() => tags.state).thenReturn(const TagsState());
    when(() => txs.state).thenReturn(const TransactionsState());
    when(() => projects.state).thenReturn(const ProjectsState());
    for (final loader in [
      accounts.loadIfNeeded,
      categories.loadIfNeeded,
      contacts.loadIfNeeded,
      tags.loadIfNeeded,
    ]) {
      when(loader).thenAnswer((_) async {});
    }
    return t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AccountsCubit>.value(value: accounts),
          BlocProvider<CategoriesCubit>.value(value: categories),
          BlocProvider<ContactsCubit>.value(value: contacts),
          BlocProvider<TagsCubit>.value(value: tags),
          BlocProvider<TransactionsCubit>.value(value: txs),
          projectDirectoryProvider(),
          BlocProvider<ProjectsCubit>.value(value: projects),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [sweetTheme.lightColors]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('th'),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DraftForm(controller: c, autofocus: false, chipLayout: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('category and wallet are two cards side by side', (t) async {
    await pump(t);
    await t.pump();
    final wallet = find.byType(WalletPickCard);
    final category = find.byType(CategoryPickCard);
    expect(wallet, findsOneWidget);
    expect(category, findsOneWidget);
    // Same row, category first.
    expect(t.getTopLeft(category).dy, t.getTopLeft(wallet).dy);
    expect(t.getTopLeft(category).dx, lessThan(t.getTopLeft(wallet).dx));
  });

  testWidgets('the note is one inline row', (t) async {
    await pump(t);
    expect(find.text('โน้ต'), findsOneWidget);
    expect(find.byType(DraftFieldRow), findsWidgets);
  });

  testWidgets('ผูกกับ is always open: its editors show without a tap', (
    t,
  ) async {
    c.setProject('p1', name: 'ทริปเชียงใหม่');
    await pump(t);
    expect(find.text('ผูกกับ'), findsOneWidget);
    expect(find.text('ทริปเชียงใหม่'), findsOneWidget);
    expect(find.byType(SplitsSection), findsOneWidget);
    expect(find.byType(EventRow), findsOneWidget);
  });

  testWidgets('a transfer has two wallet rows and no category / extras', (
    t,
  ) async {
    await pump(t);
    c.setType(TransactionType.transfer);
    await t.pump();
    // Two wallet cards, [จาก] → [ไป] (no suggested chips), no description.
    expect(find.byType(FlowCards), findsOneWidget);
    expect(find.byType(WalletPickCard), findsNWidgets(2));
    expect(find.text('จาก'), findsOneWidget);
    expect(find.text('ไป'), findsOneWidget);
    expect(find.text('เลือกหมวด'), findsNothing);
    expect(find.text('ผูกกับ'), findsNothing);
  });

  test('a draft keeps half-filled splits and its event; confirm does not', () {
    c.amount.text = '100';
    c.setProject('p1', name: 'ทริป');
    c.setSplits([
      SplitDraft(personName: 'ลี', owedAmount: 30),
      SplitDraft(personName: 'บี'), // no amount
      SplitDraft(owedAmount: 20), // no name
      SplitDraft(), // nothing
    ]);
    final saved = c.toDraft(keepIncomplete: true);
    expect(saved.splits, hasLength(3));
    expect(saved.projectId, 'p1');
    expect(saved.toJson()['project_id'], 'p1');
    // Confirming sends only whole rows.
    expect(c.toDraft().splits, hasLength(1));
  });

  test('project_id round-trips through the draft JSON; absent = none', () {
    final d = PendingDraft.fromJson({'amount': 5, 'project_id': 'p9'});
    expect(d.projectId, 'p9');
    expect(d.toJson()['project_id'], 'p9');
    final none = PendingDraft.fromJson({'amount': 5});
    expect(none.projectId, isNull);
    expect(none.toJson().containsKey('project_id'), isFalse);
  });
}
