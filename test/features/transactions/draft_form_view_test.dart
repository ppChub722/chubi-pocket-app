import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:chubi_pocket/features/tags/domain/tag.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/draft_form.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

class _Contacts extends MockCubit<ContactsState> implements ContactsCubit {}

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

/// The transaction detail's view mode (DraftForm sectioned, owner
/// 2026-10-11): tags as a strip under the hero, the note always there.
void main() {
  const trip = Tag(id: 't', name: 'เที่ยว');
  late DraftFormController c;

  setUp(() => c = DraftFormController());
  tearDown(() => c.dispose());

  Future<void> pump(WidgetTester t, {ValueChanged<FocusNode?>? onEnter}) {
    final accounts = _Accounts();
    final categories = _Categories();
    final contacts = _Contacts();
    final tags = _Tags();
    when(() => accounts.state).thenReturn(const AccountsState());
    when(() => categories.state).thenReturn(const CategoriesState());
    when(() => contacts.state).thenReturn(const ContactsState());
    when(() => tags.state).thenReturn(const TagsState(tags: [trip]));
    return t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AccountsCubit>.value(value: accounts),
          BlocProvider<CategoriesCubit>.value(value: categories),
          BlocProvider<ContactsCubit>.value(value: contacts),
          BlocProvider<TagsCubit>.value(value: tags),
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
                DraftForm(
                  controller: c,
                  autofocus: false,
                  typeLocked: true,
                  editing: false,
                  sectioned: true,
                  onEnterEdit: onEnter,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tags: a strip under the hero, no "แท็ก" row', (t) async {
    c.tagIds.add(trip.id);
    await pump(t, onEnter: (_) {});
    expect(find.byType(TxTagStrip), findsOneWidget);
    expect(find.text('เที่ยว'), findsOneWidget);
    expect(find.text('แท็ก'), findsNothing);
  });

  testWidgets('an empty note shows the long-press hint and enters edit', (
    t,
  ) async {
    FocusNode? focused;
    var calls = 0;
    await pump(
      t,
      onEnter: (f) {
        calls++;
        focused = f;
      },
    );
    expect(find.text('โน้ต'), findsOneWidget);
    final hint = find.text('แตะค้างเพื่อแก้ไข');
    expect(hint, findsOneWidget);
    await t.longPress(hint, warnIfMissed: false);
    expect(calls, 1);
    expect(focused, isNotNull); // the note's own focus node
  });

  testWidgets('a row that can\'t be edited hides an empty note', (t) async {
    await pump(t);
    expect(find.text('โน้ต'), findsNothing);
    expect(find.text('แตะค้างเพื่อแก้ไข'), findsNothing);
  });
}
