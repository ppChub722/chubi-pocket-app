import 'dart:ui' as ui;

import 'package:pp_forge/pp_forge.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The list toolbar (contacts, categories, tags, projects, transactions all
/// use it): the search capsule PAINTS 40 high, the chips are 28 (one size down), and the gap
/// between them is 8 — so the owner's "search looks short" can't come back.
void main() {
  testWidgets('ListToolbar: search 40 high, chips 28, gap 8', (t) async {
    final key = GlobalKey();
    final theme = ThemeData(extensions: [sweetTheme.lightColors]);
    final fill = theme.colorScheme.surfaceContainerHighest;
    await t.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          body: RepaintBoundary(
            key: key,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 360,
                child: ListToolbar(
                  searchController: TextEditingController(),
                  chips: [
                    PpForgeChip(label: 'All', selected: true, onTap: () {}),
                    PpForgeChip(label: 'Friends', onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final search = t.getRect(find.byType(TextField));
    final chip = t.getRect(find.byType(PpForgeChip).first);
    expect(search.height, 40);
    expect(chip.height, 28);
    expect(chip.top - search.bottom, 8);

    // What is really painted: the grey capsule's rows at the centre column.
    await t.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await boundary.toImage();
      final data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      final x = (search.left + search.width * 0.6).round();
      var rows = 0;
      for (var y = 0; y < img.height; y++) {
        final o = (y * img.width + x) * 4;
        if (data.getUint8(o) == (fill.r * 255).round() &&
            data.getUint8(o + 1) == (fill.g * 255).round() &&
            data.getUint8(o + 2) == (fill.b * 255).round()) {
          rows++;
        }
      }
      expect(rows, 40, reason: 'the filled capsule is 40 px high');
    });
  });
}
