import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/contacts/domain/contact.dart';
import 'package:chubi_pocket/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/splits_section.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
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
    name: 'บี',
    displayName: 'บี',
    status: ContactStatus.active,
  );
  const linked = Contact(
    id: 'c-linked',
    name: 'ต้น',
    displayName: 'ต้น',
    status: ContactStatus.active,
    linkedUser: LinkedUser(id: 'u2', displayName: 'ต้น'),
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
        savedPerson: const EmbeddedPerson(
          name: 'ต้น',
          contactId: 'c-linked',
          linked: true,
        ),
        owedAmount: 20,
      ),
    ];
  });

  testWidgets('ฉัน heads the list; the line shows what is still to split', (
    t,
  ) async {
    await pump(t);
    expect(find.text('ส่วนของฉัน'), findsOneWidget);
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

  testWidgets('no row is locked: typed, plain and linked can all change', (
    t,
  ) async {
    await pump(t);
    expect(find.byIcon(PpForgeIcons.lock), findsNothing);
    // The contacts' names are tappable (→ the picker); the typed one is an
    // input.
    expect(find.text('บี'), findsWidgets);
    expect(find.text('ต้น'), findsWidgets);
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

  testWidgets('the ⟳ อัตโนมัติ icon: tap → on; typing ฉัน → off', (t) async {
    await pump(t);
    // Icon only, in the ✕ slot of the ฉัน row.
    expect(find.text('อัตโนมัติ'), findsNothing);
    expect(find.byTooltip('อัตโนมัติ'), findsOneWidget);
    await t.tap(find.byTooltip('อัตโนมัติ'));
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
    await t.tap(find.byTooltip('อัตโนมัติ'));
    await t.pump();
    await t.tap(find.text('หารเท่ากัน'));
    await t.pump();
    expect(drafts.map((d) => d.owedAmount), everyElement(25));
    expect(meTyped, 0);
    expect(auto, isTrue);
  });

  testWidgets('a typed name is an input; a contact name is read-only text', (
    t,
  ) async {
    await pump(t);
    // ฉัน amount + ลี name + 3 amounts: บี and ต้น are plain text.
    expect(find.byType(TextField), findsNWidgets(5));
    expect(find.widgetWithText(TextField, 'ลี'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'บี'), findsNothing);
    expect(find.text('บี'), findsWidgets); // the name (+ the avatar's initials)

    await t.enterText(find.widgetWithText(TextField, 'ลี'), 'ลีลา');
    await t.pump();
    expect(drafts[0].personName, 'ลีลา');
    expect(drafts[0].contactId, isNull);
  });

  testWidgets('+ เพิ่มคน adds an empty typed row, its name focused', (t) async {
    await pump(t);
    await t.tap(find.text('เพิ่มคน'));
    await t.pump();
    expect(drafts, hasLength(4));
    expect(drafts.last.personName, isEmpty);
    expect(drafts.last.contactId, isNull);
    // ฉัน amount, then per person name + amount: the new name is at 5.
    final name = t.widget<TextField>(find.byType(TextField).at(5));
    expect(name.focusNode!.hasFocus, isTrue);
  });
}
