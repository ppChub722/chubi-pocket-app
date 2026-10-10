import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/constants/app_icons.dart';
import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/features/categories/domain/category.dart';
import 'package:chubi_pocket/features/categories/domain/category_type.dart';
import 'package:chubi_pocket/features/categories/presentation/widgets/category_picker_sheet.dart';
import 'package:chubi_pocket/features/tags/presentation/cubit/tags_cubit.dart';
import 'package:chubi_pocket/features/tags/presentation/widgets/tag_picker_sheet.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Tags extends MockCubit<TagsState> implements TagsCubit {}

/// The pickers on the kit PickerSheet (brief 12).
void main() {
  Future<void> open(
    WidgetTester t,
    Future<void> Function(BuildContext) show, {
    TagsCubit? tags,
  }) async {
    final app = MaterialApp(
      theme: ThemeData(extensions: [sweetTheme.lightColors]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('th'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.pumpWidget(
      tags == null
          ? app
          : BlocProvider<TagsCubit>.value(value: tags, child: app),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
  }

  group('category picker', () {
    const food = Category(id: 'f', name: 'อาหาร', type: CategoryType.expense);
    const rice = Category(
      id: 'r',
      name: 'ข้าวมันไก่',
      type: CategoryType.expense,
      parentId: 'f',
    );
    const fuel = Category(id: 'g', name: 'น้ำมัน', type: CategoryType.expense);

    Future<void> show(BuildContext context) => showCategoryPickerSheet(
      context: context,
      categories: const [food, rice, fuel],
      type: CategoryType.expense,
    );

    testWidgets('▾ only on a row with children; it opens the level', (t) async {
      await open(t, show);
      // One parent → one ▾; no › chevrons, no ✓.
      expect(find.byIcon(AppIcons.expand), findsOneWidget);
      expect(find.byIcon(AppIcons.chevronRight), findsNothing);
      expect(find.byIcon(AppIcons.check), findsNothing);
      expect(find.text('ข้าวมันไก่'), findsNothing);
      await t.tap(find.byIcon(AppIcons.expand));
      await t.pumpAndSettle();
      expect(find.text('ข้าวมันไก่'), findsOneWidget);
      expect(find.byIcon(AppIcons.collapse), findsOneWidget);
    });

    testWidgets('a search match shows inside its opened parent', (t) async {
      await open(t, show);
      await t.enterText(find.byType(TextField), 'ข้าว');
      await t.pumpAndSettle();
      expect(find.text('ข้าวมันไก่'), findsOneWidget);
      expect(find.text('อาหาร'), findsOneWidget); // its parent, kept open
      expect(find.text('น้ำมัน'), findsNothing);
    });
  });

  testWidgets('tag picker: no tags and no creating → an empty line', (t) async {
    final tags = _Tags();
    when(
      () => tags.state,
    ).thenReturn(const TagsState(status: TagsStatus.loaded));
    when(tags.loadIfNeeded).thenAnswer((_) async {});
    await open(
      t,
      (context) =>
          showTagPickerSheet(context, selected: const {}, allowCreate: false),
      tags: tags,
    );
    expect(find.text('ยังไม่มีแท็ก — สร้างได้ที่หน้าแท็ก'), findsOneWidget);
  });
}
