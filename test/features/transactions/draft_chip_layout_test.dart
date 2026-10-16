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
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/splits_section.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Contacts extends MockCubit<ContactsState> implements ContactsCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

class _Txs extends MockCubit<TransactionsState> implements TransactionsCubit {}

class _Projects extends MockCubit<ProjectsState> implements ProjectsCubit {}

/// The pending drafts' layout (owner 2026-10-11, "เพิ่มร่าง" + "แก้ร่าง"):
/// dashed pick chips lead a wallet row above a category row, the note is
/// inline, and แบ่งรายการ is collapsed until tapped. A draft keeps
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

  testWidgets('dashed pick chips lead the wallet and category rows', (t) async {
    await pump(t);
    await t.pump();
    final wallet = find.widgetWithText(PpForgeChip, 'เลือกกระเป๋า');
    final category = find.widgetWithText(PpForgeChip, 'เลือกหมวด');
    expect(wallet, findsOneWidget);
    expect(category, findsOneWidget);
    expect(t.widget<PpForgeChip>(wallet).dashed, isTrue);
    expect(t.widget<PpForgeChip>(category).dashed, isTrue);
    // The wallet row sits above the category row; no big cards.
    expect(t.getTopLeft(wallet).dy, lessThan(t.getTopLeft(category).dy));
    expect(find.byType(PickCard), findsNothing);
  });

  testWidgets('the note is one inline row', (t) async {
    await pump(t);
    expect(find.text('โน้ต'), findsOneWidget);
    expect(find.byType(DraftFieldRow), findsWidgets);
  });

  testWidgets('แบ่งรายการ is collapsed; tap opens it, tap closes', (t) async {
    c.setProject('p1', name: 'ทริปเชียงใหม่');
    await pump(t);
    expect(find.text('แบ่งรายการ'), findsOneWidget);
    // Closed: the one-line summary (the event), no editor.
    expect(find.text('ทริปเชียงใหม่'), findsOneWidget);
    expect(find.byType(SplitsSection), findsNothing);

    await t.tap(find.text('แบ่งรายการ'));
    await t.pump();
    expect(find.byType(SplitsSection), findsOneWidget);
    expect(find.byType(EventRow), findsOneWidget);

    await t.tap(find.text('แบ่งรายการ'));
    await t.pump();
    expect(find.byType(SplitsSection), findsNothing);
  });

  testWidgets('a transfer has two wallet rows and no category / extras', (
    t,
  ) async {
    await pump(t);
    c.setType(TransactionType.transfer);
    await t.pump();
    expect(find.text('เลือกกระเป๋าต้นทาง'), findsOneWidget);
    expect(find.text('เลือกกระเป๋าปลายทาง'), findsOneWidget);
    expect(find.text('เลือกหมวด'), findsNothing);
    expect(find.text('แบ่งรายการ'), findsNothing);
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
