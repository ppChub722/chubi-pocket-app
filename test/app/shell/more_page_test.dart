import 'package:chubi_pocket/app/shell/more_page.dart';
import 'package:chubi_pocket/app/shell/tab_nav.dart';
import 'package:chubi_pocket/features/me_counts/cubit/me_counts_cubit.dart';
import 'package:chubi_pocket/features/me_counts/data/me_counts_repository.dart';
import 'package:chubi_pocket/features/me_counts/domain/me_counts.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeCounts extends Fake implements MeCountsRepository {
  @override
  Future<MeCounts> fetch() async =>
      const MeCounts(pendingDrafts: 3, unreadNotifications: 5);
}

const _paths = [
  '/budgets',
  '/saving-goals',
  '/recurring',
  '/personal-debts',
  '/projects',
  '/categories',
  '/tags',
  '/contacts',
  '/',
  '/transactions',
  '/accounts',
  '/pending',
  '/notifications',
  '/settings',
];

void main() {
  Future<void> pump(WidgetTester t, {bool Function(ShellTab)? isOn}) async {
    final cubit = MeCountsCubit(repository: _FakeCounts());
    addTearDown(cubit.close);
    await cubit.load();
    final router = GoRouter(
      initialLocation: '/more',
      routes: [
        GoRoute(
          path: '/more',
          builder: (_, _) => MorePage(
            counts: cubit,
            isOn: isOn,
            topBar: const PreferredSize(
              preferredSize: Size.zero,
              child: SizedBox.shrink(),
            ),
          ),
        ),
        for (final p in _paths)
          GoRoute(
            path: p,
            builder: (_, _) => Scaffold(body: Text('page $p')),
          ),
      ],
    );
    await t.binding.setSurfaceSize(const Size(400, 3000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        locale: const Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => AppUiConfig(child: child!),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('sections run plans → others → setup data → main menu', (
    t,
  ) async {
    await pump(t);
    double y(String s) => t.getTopLeft(find.text(s)).dy;
    final ys = [
      y('แผนการเงิน'),
      y('เงินกับคนอื่น'),
      y('ข้อมูลตั้งต้น'),
      y('เมนูหลัก'),
    ];
    expect([...ys]..sort(), ys);
    // Cards sit under their section.
    expect(y('งบประมาณ'), inInclusiveRange(ys[0], ys[1]));
    expect(y('หนี้สิน'), inInclusiveRange(ys[1], ys[2]));
    expect(y('ผู้ติดต่อ'), inInclusiveRange(ys[2], ys[3]));
    expect(y('รายการ'), greaterThan(ys[3]));
    // Live figures on the main menu.
    expect(find.text('3 รายการ'), findsOneWidget);
    expect(find.text('ยังไม่ได้อ่าน 5 รายการ'), findsOneWidget);
  });

  testWidgets('every entry opens its page', (t) async {
    final cards = {
      'งบประมาณ': '/budgets',
      'หนี้สิน': '/personal-debts',
      'หมวดหมู่': '/categories',
      'ผู้ติดต่อ': '/contacts',
      'แดชบอร์ด': '/',
      'กระเป๋า': '/accounts',
      'รอยืนยัน': '/pending',
      'การแจ้งเตือน': '/notifications',
      'โปรไฟล์และตั้งค่า': '/settings',
    };
    for (final MapEntry(key: title, value: path) in cards.entries) {
      await pump(t);
      await t.tap(find.text(title).first);
      await t.pumpAndSettle();
      expect(find.text('page $path'), findsOneWidget, reason: title);
    }
  });

  testWidgets('a module switched off hides its entry; empty section goes', (
    t,
  ) async {
    await pump(
      t,
      isOn: (tab) => switch (tab) {
        ShellTab.budgets ||
        ShellTab.savingGoals ||
        ShellTab.recurring ||
        ShellTab.pending => false,
        _ => true,
      },
    );
    expect(find.text('แผนการเงิน'), findsNothing);
    expect(find.text('งบประมาณ'), findsNothing);
    expect(find.text('รอยืนยัน'), findsNothing);
    expect(find.text('เงินกับคนอื่น'), findsOneWidget);
    expect(find.text('การแจ้งเตือน'), findsOneWidget);
  });
}
