import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/constants/app_icons.dart';
import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/contacts/domain/contact.dart';
import 'package:chubi_pocket/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/splits_section.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/shared/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Contacts extends MockCubit<ContactsState> implements ContactsCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

/// The split editor (owner 2026-10-11): ฉัน + a "still to split" line,
/// หารเท่ากัน counting me in, the three person looks, and only an
/// app-linked saved row locked.
void main() {
  const plain = Contact(
    id: 'c-plain',
    userId: 'me',
    displayName: 'บี',
    status: ContactStatus.active,
  );
  const linked = Contact(
    id: 'c-linked',
    userId: 'me',
    displayName: 'ต้น',
    status: ContactStatus.active,
    linkedUserId: 'u2',
  );

  late List<SplitDraft> drafts;
  double? me;
  var auto = false;
  var meTyped = 0;

  Future<void> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(800 * 3, 1200 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final contacts = _Contacts();
    when(() => contacts.state).thenReturn(
      const ContactsState(
        contacts: [plain, linked],
        status: ContactsStatus.loaded,
      ),
    );
    when(contacts.loadIfNeeded).thenAnswer((_) async {});
    final auth = _Auth();
    when(() => auth.state).thenReturn(const AuthInitial());
    await t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ContactsCubit>.value(value: contacts),
          BlocProvider<AuthCubit>.value(value: auth),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [sweetTheme.lightColors]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('th'),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: SplitsSection(
                  label: 'หารกับ',
                  totalAmount: 100,
                  drafts: drafts,
                  me: me,
                  // As the controller: typing ฉัน turns auto off.
                  onMeChanged: (v) => setState(() {
                    me = v;
                    auto = false;
                    meTyped++;
                  }),
                  meAuto: auto,
                  onMeAutoChanged: (v) => setState(() => auto = v),
                  onChanged: (d) => setState(() => drafts = d),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
  }

  setUp(() {
    me = null;
    auto = false;
    meTyped = 0;
    drafts = [
      SplitDraft(debtId: 'd1', personName: 'ลี', owedAmount: 20),
      SplitDraft(
        debtId: 'd2',
        personName: 'บี',
        contactId: 'c-plain',
        owedAmount: 20,
      ),
      SplitDraft(
        debtId: 'd3',
        personName: 'ต้น',
        contactId: 'c-linked',
        owedAmount: 20,
      ),
    ];
  });

  testWidgets('ฉัน heads the list; the line shows what is still to split', (
    t,
  ) async {
    await pump(t);
    expect(find.text('ฉัน'), findsOneWidget);
    expect(find.textContaining('ยังไม่ได้แบ่ง'), findsOneWidget);
  });

  testWidgets('หารเท่ากัน: me in, remainder on me → balanced', (t) async {
    await pump(t);
    await t.tap(find.text('หารเท่ากัน'));
    await t.pump();
    // 100 / 4 = 25 each.
    expect(drafts.map((d) => d.owedAmount), everyElement(25));
    expect(me, 25);
    expect(find.text('แบ่งครบแล้ว'), findsOneWidget);
  });

  testWidgets('only the app-linked saved row is locked', (t) async {
    await pump(t);
    expect(drafts[0].identityLocked, isFalse); // typed name
    expect(drafts[1].identityLocked, isFalse); // plain contact
    expect(drafts[2].identityLocked, isTrue); // linked to an app user
    // One 🔒, on ต้น's chip.
    final locks = find.byIcon(AppIcons.lock);
    expect(locks, findsOneWidget);
    expect(
      find.ancestor(of: locks, matching: find.widgetWithText(RowChip, 'ต้น')),
      findsOneWidget,
    );
  });

  testWidgets('three looks: 👤 · avatar · avatar + 🔗', (t) async {
    await pump(t);
    final marks = t.widgetList<PersonMark>(find.byType(PersonMark)).toList();
    expect(marks.map((m) => m.level), [
      PersonLevel.name,
      PersonLevel.contact,
      PersonLevel.linked,
    ]);
  });

  testWidgets('the อัตโนมัติ chip: tap → on; typing ฉัน → off', (t) async {
    await pump(t);
    expect(find.text('อัตโนมัติ'), findsOneWidget);
    await t.tap(find.text('อัตโนมัติ'));
    await t.pump();
    expect(auto, isTrue);

    // Typing in ฉัน (the first amount field) turns it off.
    await t.enterText(find.byType(TextField).first, '10');
    await t.pump();
    expect(auto, isFalse);
    expect(me, 10);
  });

  testWidgets('หารเท่ากัน on auto leaves ฉัน to follow (nothing typed)', (
    t,
  ) async {
    await pump(t);
    await t.tap(find.text('อัตโนมัติ'));
    await t.pump();
    await t.tap(find.text('หารเท่ากัน'));
    await t.pump();
    expect(drafts.map((d) => d.owedAmount), everyElement(25));
    expect(meTyped, 0);
    expect(auto, isTrue);
  });
}
