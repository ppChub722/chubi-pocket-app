import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared by the row geometry baselines (AppRow plan step 0): pumps one row
/// at a width and text scale, then records rects, a sampled fill pixel and
/// the opacity above a piece as one comparable string.
///
/// The expected strings are literals in each test, recorded at app main
/// `8e28650` before the rows moved onto AppRow. To print fresh values
/// (only when a change is meant and explained), run with
/// `GEOMETRY_OUT=<file>`: each case appends `'<id>': '<snapshot>',`.
const geometryWidths = [320.0, 420.0, 800.0];
const geometryScales = [1.0, 1.3];

/// The page behind the rows: a grey that no row fill uses.
const geometryPage = Color(0xFFE0E0E0);

final _boundary = GlobalKey(debugLabel: 'geometry-boundary');

ThemeData geometryTheme() {
  final colors = sweetTheme.lightColors;
  return ThemeData(colorScheme: colors.toColorScheme(), extensions: [colors]);
}

typedef GeometryCase = ({
  Widget Function() build,
  Future<void> Function(WidgetTester t, GeometrySnap s) measure,
});

class GeometrySnap {
  GeometrySnap(this.t);

  final WidgetTester t;
  final _parts = <String>[];

  static String _n(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  static String hex(Color c) =>
      c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();

  void rect(String name, Finder f) {
    final r = t.getRect(f);
    _parts.add(
      '$name=${_n(r.left)},${_n(r.top)},${_n(r.width)},${_n(r.height)}',
    );
  }

  void value(String name, Object v) => _parts.add('$name=$v');

  /// The product of every opacity between [f]'s render object and the root.
  void opacity(String name, Finder f) {
    RenderObject? o = t.renderObject(f);
    var a = 1.0;
    while (o != null) {
      if (o is RenderOpacity) a *= o.opacity;
      if (o is RenderAnimatedOpacity) a *= o.opacity.value;
      o = o.parent;
    }
    _parts.add('$name=${a.toStringAsFixed(2)}');
  }

  /// The colour of the first text span under [f] as laid out.
  void textColor(String name, Finder f) {
    final p = t.renderObject<RenderParagraph>(
      find.descendant(of: f, matching: find.byType(RichText)).first,
    );
    final c = p.text.style?.color;
    _parts.add('$name=${c == null ? '-' : hex(c)}');
  }

  /// The painted pixel at [global] inside the boundary: the row's own fill
  /// (the page behind it is not captured, so no fill reads 00000000).
  Future<void> pixel(String name, Offset global) async =>
      _parts.add('$name=${hex(await samplePixel(t, global))}');

  @override
  String toString() => _parts.join(' ');
}

/// The painted pixel at [global] inside the pumped row's boundary (raw
/// RGBA as the engine stores it).
Future<Color> samplePixel(WidgetTester t, Offset global) async {
  final ro = t.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  final origin = ro.localToGlobal(Offset.zero);
  late ByteData data;
  late int width;
  await t.runAsync(() async {
    final image = await ro.toImage();
    width = image.width;
    data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    image.dispose();
  });
  final x = (global.dx - origin.dx).floor();
  final y = (global.dy - origin.dy).floor();
  final i = (y * width + x) * 4;
  final c = Color.fromARGB(
    data.getUint8(i + 3),
    data.getUint8(i),
    data.getUint8(i + 1),
    data.getUint8(i + 2),
  );
  return c;
}

Future<void> pumpGeometryRow(
  WidgetTester t,
  Widget row, {
  required double width,
  required double scale,
}) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: geometryTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: geometryPage,
        body: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: _boundary,
            child: SizedBox(width: width, child: row),
          ),
        ),
      ),
    ),
  );
  await t.pump(const Duration(milliseconds: 300));
}

/// One test per case × width × scale, each compared with [expected].
void geometryMatrix(
  Map<String, GeometryCase> cases,
  Map<String, String> expected,
) {
  final out = Platform.environment['GEOMETRY_OUT'];
  for (final MapEntry(key: name, value: c) in cases.entries) {
    for (final width in geometryWidths) {
      for (final scale in geometryScales) {
        final id = '$name@${width.round()}@$scale';
        testWidgets(id, (t) async {
          addTearDown(t.view.reset);
          await pumpGeometryRow(t, c.build(), width: width, scale: scale);
          final snap = GeometrySnap(t);
          await c.measure(t, snap);
          final got = snap.toString();
          if (out != null) {
            File(out).writeAsStringSync(
              "    '$id':\n        '$got',\n",
              mode: FileMode.append,
            );
            return;
          }
          expect(got, expected[id], reason: id);
        });
      }
    }
  }
}
