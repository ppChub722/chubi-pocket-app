import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/dev/detail_patterns_tab.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Contacts extends MockCubit<ContactsState> implements ContactsCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

/// The gallery's detail reference renders end to end, in both modes,
/// with no layout errors (it mixes every detail-page piece).
void main() {
  testWidgets('detail patterns: view ⇄ edit, then the whole catalogue', (
    t,
  ) async {
    // Wide: the test font draws every Thai glyph a full em (about twice a
    // real one), so a 412dp phone would "overflow" on labels alone — this
    // checks structure (unbounded / flex / overflow-box errors), not fit.
    t.view.physicalSize = const Size(800 * 3, 915 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    final contacts = _Contacts();
    when(() => contacts.state).thenReturn(const ContactsState());
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
          theme: ThemeData(
            extensions: [sweetTheme.lightColors, sweetTheme.lightModules!],
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('th'),
          home: const Scaffold(body: DetailPatternsTab()),
        ),
      ),
    );
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.text('การจัดการ'), findsNothing);

    await t.tap(find.text('แก้ไข').first);
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.text('การจัดการ'), findsOneWidget);

    // Scroll the whole catalogue through.
    await t.drag(find.byType(ListView).first, const Offset(0, -20000));
    await t.pump();
    expect(t.takeException(), isNull);
  });
}
