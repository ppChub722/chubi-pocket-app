import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/archived/cubit/archived_cubit.dart';
import 'package:chubi_pocket/features/archived/data/archived_repository.dart';
import 'package:chubi_pocket/features/archived/domain/archived_hub.dart';
import 'package:chubi_pocket/features/archived/presentation/archived_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _item(
  String id,
  String name, {
  bool? canRestore,
  Map<String, dynamic>? secondary,
}) => {
  'id': id,
  'name': name,
  'icon_code': null,
  'archived_at': '2026-10-01T08:30:00Z',
  'can_restore': ?canRestore,
  'secondary': secondary,
};

Map<String, dynamic> _group(List<Map<String, dynamic>> items) => {
  'count': items.length,
  'items': items,
};

/// Prod-shaped: five groups filled, one (contacts) empty.
final _json = {
  'total': 6,
  'wallets': _group([_item('w1', 'บัญชีเก่า')]),
  'budgets': _group([_item('b1', 'งบกาแฟ')]),
  'goals': _group([_item('g1', 'ซื้อรถ'), _item('g2', 'ทริปญี่ปุ่น')]),
  'events': _group([_item('e1', 'งานเลี้ยง')]),
  'contacts': _group([]),
  'recurring': _group([_item('r1', 'ค่าเน็ต')]),
};

class _Fake extends Fake implements ArchivedRepository {
  _Fake({this.failLoad = false, Map<String, dynamic>? json})
    : json = json ?? _json;
  final Map<String, dynamic> json;
  bool failLoad;
  int fetches = 0;
  final restores = <String>[];

  @override
  Future<ArchivedHub> fetch() async {
    fetches++;
    if (failLoad) {
      throw const ApiException(code: 'X', message: 'boom', statusCode: 500);
    }
    return ArchivedHub.fromJson(json);
  }

  @override
  Future<void> restore(ArchivedKind kind, String id) async =>
      restores.add('${kind.key}:$id');
}

void main() {
  Future<ArchivedCubit> pump(WidgetTester t, _Fake repo) async {
    final cubit = ArchivedCubit(repository: repo);
    addTearDown(cubit.close);
    await t.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        locale: const Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => AppUiConfig(child: child!),
        home: ArchivedPage(
          cubit: cubit..load(),
          topBar: const PreferredSize(
            preferredSize: Size.zero,
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    return cubit;
  }

  testWidgets('groups render, empty group hidden, one GET', (t) async {
    final repo = _Fake();
    await pump(t, repo);
    expect(find.text('กระเป๋า'), findsOneWidget);
    expect(find.text('งบประมาณ'), findsOneWidget);
    expect(find.text('เป้าหมาย'), findsOneWidget);
    expect(find.text('อีเวนต์'), findsOneWidget);
    expect(find.text('รายการประจำ'), findsOneWidget);
    expect(find.text('ผู้ติดต่อ'), findsNothing);
    expect(find.text('ซื้อรถ'), findsOneWidget);
    expect(find.textContaining('เก็บถาวรเมื่อ'), findsNWidgets(6));
    expect(find.text('กู้คืน'), findsNWidgets(6));
    expect(repo.fetches, 1);
  });

  testWidgets('can_restore false hides กู้คืน; secondary line shows', (
    t,
  ) async {
    final repo = _Fake(
      json: {
        ..._json,
        'total': 4,
        'wallets': _group([
          _item(
            'w1',
            'บัญชีร่วม',
            canRestore: false,
            secondary: {'kind': 'balance', 'amount': 1250.5},
          ),
        ]),
        'budgets': _group([
          _item(
            'b1',
            'งบกาแฟ',
            canRestore: true,
            secondary: {'kind': 'limit', 'amount': 3000},
          ),
        ]),
        'goals': _group([
          _item('g1', 'ซื้อรถ', secondary: {'kind': 'target', 'amount': 4000}),
        ]),
        'events': _group([]),
        'contacts': _group([_item('c1', 'พี่บี')]),
        'recurring': _group([]),
      },
    );
    await pump(t, repo);
    // Owner-only wallet: no restore chip; the others (and an absent flag) keep it.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('archived-wallets-w1')),
        matching: find.text('กู้คืน'),
      ),
      findsNothing,
    );
    expect(find.text('กู้คืน'), findsNWidgets(3));
    // No signed-in user: the default money style (always 2 decimals).
    expect(find.textContaining('คงเหลือ ฿1,250.50'), findsOneWidget);
    expect(find.textContaining('วงเงิน ฿3,000.00 |'), findsOneWidget);
    expect(find.textContaining('เป้าหมาย ฿4,000.00 |'), findsOneWidget);
    // A contact has no secondary line: only the archived date.
    expect(find.text('พี่บี'), findsOneWidget);
    expect(find.textContaining('฿', findRichText: true), findsNWidgets(3));
  });

  testWidgets('restore = one call, the row leaves, no re-fetch', (t) async {
    final repo = _Fake();
    await pump(t, repo);
    await t.tap(
      find.descendant(
        of: find.byKey(const ValueKey('archived-goals-g1')),
        matching: find.text('กู้คืน'),
      ),
    );
    await t.pumpAndSettle();
    expect(repo.restores, ['goals:g1']);
    expect(repo.fetches, 1);
    expect(find.text('ซื้อรถ'), findsNothing);
    expect(find.text('ทริปญี่ปุ่น'), findsOneWidget);
  });

  testWidgets('restoring the last row shows the empty state', (t) async {
    final repo = _Fake();
    final cubit = await pump(t, repo);
    for (final k in ArchivedKind.values) {
      for (final i in [...cubit.state.hub!.of(k)]) {
        await cubit.restore(k, i.id);
      }
    }
    await t.pumpAndSettle();
    expect(find.text('ไม่มีที่เก็บถาวร'), findsOneWidget);
  });

  testWidgets('failing load: full-page error, retry loads', (t) async {
    final repo = _Fake(failLoad: true);
    await pump(t, repo);
    expect(find.text('กระเป๋า'), findsNothing);
    expect(find.byType(ErrorView), findsOneWidget);
    repo.failLoad = false;
    await t.tap(find.byIcon(AppIcons.refresh));
    await t.pumpAndSettle();
    expect(find.text('ซื้อรถ'), findsOneWidget);
  });
}
