import 'package:chubi_pocket/shared/widgets/reorder/reorder_outline.dart';
import 'package:flutter_test/flutter_test.dart';

/// `'A:1 A1:2 B:1'` → an outline (one section).
List<OutlineItem> o(String spec, {Object? section}) => [
  for (final t in spec.split(' '))
    OutlineItem(t.split(':')[0], int.parse(t.split(':')[1]), section: section),
];

/// Back to the spec form, for readable expectations.
String s(List<OutlineItem>? items) =>
    items == null ? 'null' : items.map((r) => '${r.id}:${r.level}').join(' ');

int at(List<OutlineItem> items, String id) =>
    items.indexWhere((r) => r.id == id);

void main() {
  group('reading', () {
    final items = o('A:1 A1:2 A1a:3 A2:2 B:1');

    test('blockEnd / heightOf / parentIndex', () {
      expect(ReorderOutline.blockEnd(items, 0), 4);
      expect(ReorderOutline.heightOf(items, 0), 3);
      expect(ReorderOutline.heightOf(items, 1), 2);
      expect(ReorderOutline.heightOf(items, 4), 1);
      expect(ReorderOutline.parentIndex(items, 2), 1);
      expect(ReorderOutline.parentIndex(items, 3), 0);
      expect(ReorderOutline.parentIndex(items, 4), isNull);
    });

    test('visible skips collapsed blocks', () {
      expect(s(ReorderOutline.visible(items, {'A1'})), 'A:1 A1:2 A2:2 B:1');
      expect(s(ReorderOutline.visible(items, {'A'})), 'A:1 B:1');
    });
  });

  group('↑ ↓', () {
    test(
      'a first child crosses up into the previous parent, keeping depth',
      () {
        final items = o('A:1 A1:2 B:1 B1:2 B2:2');
        expect(
          s(ReorderOutline.moveUp(items, at(items, 'B1'), maxDepth: 3)),
          'A:1 A1:2 B1:2 B:1 B2:2',
        );
      },
    );

    test('a last child crosses down into the next parent as first child', () {
      final items = o('A:1 A1:2 B:1 B1:2');
      expect(
        s(ReorderOutline.moveDown(items, at(items, 'A1'), maxDepth: 3)),
        'A:1 B:1 A1:2 B1:2',
      );
    });

    test('no valid parent up there → depth drops', () {
      final items = o('G:1 P:2 B:3');
      expect(
        s(ReorderOutline.moveUp(items, at(items, 'B'), maxDepth: 3)),
        'G:1 B:2 P:2',
      );
    });

    test('a parent moves as a block and skips a whole sibling block', () {
      final items = o('A:1 A1:2 B:1 B1:2 C:1');
      expect(
        s(ReorderOutline.moveUp(items, at(items, 'B'), maxDepth: 3)),
        'B:1 B1:2 A:1 A1:2 C:1',
      );
      expect(
        s(ReorderOutline.moveDown(items, at(items, 'A'), maxDepth: 3)),
        'B:1 B1:2 A:1 A1:2 C:1',
      );
    });

    test('a leaf skips an expanded sibling block (depth kept)', () {
      final items = o('A:1 A1:2 A1a:3 A2:2');
      expect(
        s(ReorderOutline.moveUp(items, at(items, 'A2'), maxDepth: 3)),
        'A:1 A2:2 A1:2 A1a:3',
      );
    });

    test('a collapsed block is one slot — never moved into', () {
      final items = o('Z:1 Z1:2 A:1 A1:2 B:1 B1:2');
      // Into collapsed A would hide B1: it lands between A and B instead,
      // top level (no visible parent there).
      expect(
        s(
          ReorderOutline.moveUp(
            items,
            at(items, 'B1'),
            maxDepth: 3,
            collapsed: {'A'},
          ),
        ),
        'Z:1 Z1:2 A:1 A1:2 B1:1 B:1',
      );
    });

    test('the first / last row of a section cannot move further', () {
      final items = o('A:1 B:1');
      expect(ReorderOutline.moveUp(items, 0, maxDepth: 3), isNull);
      expect(ReorderOutline.moveDown(items, 1, maxDepth: 3), isNull);
    });

    test('a flat list swaps neighbours', () {
      final items = o('a:1 b:1 c:1');
      expect(s(ReorderOutline.moveDown(items, 0, maxDepth: 1)), 'b:1 a:1 c:1');
      expect(s(ReorderOutline.moveUp(items, 2, maxDepth: 1)), 'a:1 c:1 b:1');
    });

    test('rows never leave their section', () {
      final items = [...o('a:1 b:1', section: 'x'), ...o('c:1', section: 'y')];
      expect(ReorderOutline.moveDown(items, 1, maxDepth: 1), isNull);
      expect(ReorderOutline.moveUp(items, 2, maxDepth: 1), isNull);
    });
  });

  group('← →', () {
    test('→ makes it the last child of the sibling above', () {
      final items = o('A:1 A1:2 B:1 B1:2');
      expect(
        s(ReorderOutline.indent(items, at(items, 'B'), maxDepth: 3)),
        'A:1 A1:2 B:2 B1:3',
      );
    });

    test('→ needs a sibling above', () {
      final items = o('A:1 A1:2');
      expect(ReorderOutline.indent(items, 0, maxDepth: 3), isNull);
      expect(ReorderOutline.indent(items, 1, maxDepth: 3), isNull);
    });

    test('→ refuses to push the block past 3 levels', () {
      final items = o('A:1 B:1 B1:2 B1a:3');
      expect(ReorderOutline.indent(items, at(items, 'B'), maxDepth: 3), isNull);
    });

    test('← places it right after the old parent block', () {
      final items = o('A:1 A1:2 A2:2 A2a:3 B:1');
      expect(
        s(ReorderOutline.outdent(items, at(items, 'A1'))),
        'A:1 A2:2 A2a:3 A1:1 B:1',
      );
    });

    test('← is not possible at top level', () {
      expect(ReorderOutline.outdent(o('A:1'), 0), isNull);
    });
  });

  group('drop levels', () {
    test('depth clamp: max one below the row above, block within 3', () {
      final items = o('A:1 A1:2 B:1 B1:2');
      final (block, rest) = ReorderOutline.cut(items, at(items, 'B'));
      expect(block.length, 2);
      // After A1 (L2): a 2-level block can go to L1 or L2, not L3.
      expect(
        ReorderOutline.validLevels(
          rest,
          2,
          section: null,
          height: 2,
          maxDepth: 3,
          collapsed: const {},
        ),
        (1, 2),
      );
    });

    test('no stealing: never between a row and its first child', () {
      final items = o('A:1 A1:2 L:1');
      final (_, rest) = ReorderOutline.cut(items, at(items, 'L'));
      // Between A and A1 only L2 keeps A1 under A.
      expect(
        ReorderOutline.validLevels(
          rest,
          1,
          section: null,
          height: 1,
          maxDepth: 3,
          collapsed: const {},
        ),
        (2, 2),
      );
    });

    test('a 3-level block cannot drop under anything', () {
      final items = o('A:1 B:1 B1:2 B1a:3');
      final (_, rest) = ReorderOutline.cut(items, at(items, 'B'));
      expect(
        ReorderOutline.validLevels(
          rest,
          1,
          section: null,
          height: 3,
          maxDepth: 3,
          collapsed: const {},
        ),
        (1, 1),
      );
    });

    test('not inside a collapsed row', () {
      final items = o('A:1 A1:2 L:1');
      final (_, rest) = ReorderOutline.cut(items, at(items, 'L'));
      // After A1 inside collapsed A: only top level.
      expect(
        ReorderOutline.validLevels(
          rest,
          2,
          section: null,
          height: 1,
          maxDepth: 3,
          collapsed: const {'A'},
        ),
        (1, 1),
      );
    });

    test('moveTo in place at the same level is a no-op', () {
      final items = o('A:1 A1:2 B:1');
      expect(s(ReorderOutline.moveTo(items, 1, 1, 2, maxDepth: 3)), s(items));
    });

    test('moveTo rejects an invalid level', () {
      final items = o('A:1 B:1');
      expect(ReorderOutline.moveTo(items, 1, 1, 3, maxDepth: 3), isNull);
      expect(s(ReorderOutline.moveTo(items, 1, 1, 2, maxDepth: 3)), 'A:1 B:2');
    });

    test('parentAt names the drop parent', () {
      final rest = o('A:1 A1:2');
      expect(ReorderOutline.parentAt(rest, 2, 2, section: null), 'A');
      expect(ReorderOutline.parentAt(rest, 2, 3, section: null), 'A1');
      expect(ReorderOutline.parentAt(rest, 2, 1, section: null), isNull);
    });
  });
}
