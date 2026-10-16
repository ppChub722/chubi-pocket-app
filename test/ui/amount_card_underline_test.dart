import 'package:pp_forge/pp_forge.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'amount card: symbol takes the text colour; field spans the cell',
    (t) async {
      final c = TextEditingController(text: '120');
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [sweetTheme.lightColors]),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: PpForgeInput.card(
                  controller: c,
                  type: PpForgeInputType.amount,
                  currencySymbol: '฿',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 24, color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      );
      final sym = t.widget<Text>(find.text('฿'));
      expect(sym.style?.color, Colors.red);
      expect(t.getSize(find.byType(InputDecorator).first).width, 300);
    },
  );
}
