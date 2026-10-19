import 'dart:ui' as ui;

import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// AppInput.card geometry is fixed by TOKENS ([AppInputSize]), not by the
/// value's font: two sized fields side by side — a big amount and a normal
/// description — share their label top and their DRAWN underline row, empty,
/// filled or focused, at text scale 1.0 and 1.3.
void main() {
  for (final size in AppInputSize.values) {
    for (final scale in const [1.0, 1.3]) {
      for (final state in const [
        'empty',
        'filled',
        'focus-left',
        'focus-right',
      ]) {
        testWidgets('${size.name} | ×$scale | $state', (t) async {
          final left = TextEditingController();
          final right = TextEditingController();
          final leftFocus = FocusNode();
          final rightFocus = FocusNode();
          addTearDown(() {
            left.dispose();
            right.dispose();
            leftFocus.dispose();
            rightFocus.dispose();
          });
          if (state != 'empty') {
            left.text = 'ข้าวมันไก่ Lunch';
            right.text = '1,250';
          }
          final key = GlobalKey();
          await t.pumpWidget(
            MaterialApp(
              theme: ThemeData(extensions: [sweetTheme.lightColors]),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                backgroundColor: Colors.white,
                body: RepaintBoundary(
                  key: key,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppInput.card(
                            controller: left,
                            focusNode: leftFocus,
                            size: size,
                            label: 'Description',
                            labelPlacement: AppInputLabelPlacement.above,
                            hint: 'What for?',
                            focusColor: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppInput.card(
                            controller: right,
                            focusNode: rightFocus,
                            size: size,
                            label: 'Amount',
                            labelPlacement: AppInputLabelPlacement.above,
                            type: AppInputType.amount,
                            currencySymbol: '฿',
                            textAlign: TextAlign.end,
                            // The big value of that size class.
                            style: TextStyle(
                              fontSize: switch (size) {
                                AppInputSize.regular => 18,
                                AppInputSize.title => 22,
                                AppInputSize.hero => 28,
                              },
                            ),
                            hint: '0',
                            focusColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          if (state == 'focus-left') leftFocus.requestFocus();
          if (state == 'focus-right') rightFocus.requestFocus();
          await t.pumpAndSettle();

          // 1. the two labels share one top.
          expect(
            t.getTopLeft(find.text('Description')).dy,
            closeTo(t.getTopLeft(find.text('Amount')).dy, 0.5),
            reason: 'label tops',
          );

          // 2. the DRAWN underlines share one row: the lowest non-white pixel
          //    of each field's column.
          final fields = find.byType(AppInput);
          final image = (await t.runAsync(() async {
            final b =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            return b.toImage(pixelRatio: 1);
          }))!;
          final data = (await t.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
          ))!;
          int lowest(int field) {
            final r = t.getRect(fields.at(field));
            final x = (r.left + 8).round();
            for (var y = r.bottom.round() + 2; y >= r.top.round(); y--) {
              final o = (y * image.width + x) * 4;
              if (data.getUint8(o) < 250 ||
                  data.getUint8(o + 1) < 250 ||
                  data.getUint8(o + 2) < 250) {
                return y;
              }
            }
            return -1;
          }

          final a = lowest(0);
          final b = lowest(1);
          expect(a, greaterThan(0), reason: 'left underline drawn');
          expect(a, b, reason: 'underline rows');
          // and the fields themselves are the same height.
          expect(
            t.getSize(fields.at(0)).height,
            t.getSize(fields.at(1)).height,
            reason: 'field heights',
          );
        });
      }
    }
  }
}
