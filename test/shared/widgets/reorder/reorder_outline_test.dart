import 'package:chubi_pocket/ui/organisms/reorder/reorder_outline.dart';
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

typedef _Case = (String name, Object? got, Object? want);

void _check(List<_Case> cases) {
  for (final (name, got, want) in cases) {
    expect(got, want, reason: name);
  }
}

(int, int)? _levels(
  String spec,
  String cut,
  int index, {
  required int height,
  Set<String> collapsed = const {},
}) {
  final (_, rest) = ReorderOutline.cut(o(spec), at(o(spec), cut));
  return ReorderOutline.validLevels(
    rest,
    index,
    section: null,
    height: height,
    maxDepth: 3,
    collapsed: collapsed,
  );
}

void main() {
  test('↑ ↓ and reading the outline', () {
    final tree = o('A:1 A1:2 A1a:3 A2:2 B:1');
    final collapsedItems = o('Z:1 Z1:2 A:1 A1:2 B:1 B1:2');
    final sections = [...o('a:1 b:1', section: 'x'), ...o('c:1', section: 'y')];
    String up(String spec, String id, {Set<String> collapsed = const {}}) {
      final items = o(spec);
      return s(
        ReorderOutline.moveUp(
          items,
          at(items, id),
          maxDepth: 3,
          collapsed: collapsed,
        ),
      );
    }

    String down(String spec, String id) {
      final items = o(spec);
      return s(ReorderOutline.moveDown(items, at(items, id), maxDepth: 3));
    }

    _check([
      ('blockEnd', ReorderOutline.blockEnd(tree, 0), 4),
      ('heightOf a 3-level block', ReorderOutline.heightOf(tree, 0), 3),
      ('heightOf a leaf', ReorderOutline.heightOf(tree, 4), 1),
      ('parentIndex of a grandchild', ReorderOutline.parentIndex(tree, 2), 1),
      ('parentIndex at the top', ReorderOutline.parentIndex(tree, 4), null),
      (
        'visible skips a collapsed child',
        s(ReorderOutline.visible(tree, {'A1'})),
        'A:1 A1:2 A2:2 B:1',
      ),
      (
        'visible skips a collapsed parent',
        s(ReorderOutline.visible(tree, {'A'})),
        'A:1 B:1',
      ),
      (
        'a first child crosses up into the previous parent, keeping depth',
        up('A:1 A1:2 B:1 B1:2 B2:2', 'B1'),
        'A:1 A1:2 B1:2 B:1 B2:2',
      ),
      (
        'a last child crosses down into the next parent as first child',
        down('A:1 A1:2 B:1 B1:2', 'A1'),
        'A:1 B:1 A1:2 B1:2',
      ),
      (
        'no valid parent up there → depth drops',
        up('G:1 P:2 B:3', 'B'),
        'G:1 B:2 P:2',
      ),
      (
        'a parent moves up as a block, skipping a whole sibling block',
        up('A:1 A1:2 B:1 B1:2 C:1', 'B'),
        'B:1 B1:2 A:1 A1:2 C:1',
      ),
      (
        'a parent moves down as a block, skipping a whole sibling block',
        down('A:1 A1:2 B:1 B1:2 C:1', 'A'),
        'B:1 B1:2 A:1 A1:2 C:1',
      ),
      (
        'a leaf skips an expanded sibling block (depth kept)',
        up('A:1 A1:2 A1a:3 A2:2', 'A2'),
        'A:1 A2:2 A1:2 A1a:3',
      ),
      (
        'a collapsed block is one slot — never moved into',
        s(
          ReorderOutline.moveUp(
            collapsedItems,
            at(collapsedItems, 'B1'),
            maxDepth: 3,
            collapsed: {'A'},
          ),
        ),
        'Z:1 Z1:2 A:1 A1:2 B1:1 B:1',
      ),
      (
        'the first row cannot move up',
        ReorderOutline.moveUp(o('A:1 B:1'), 0, maxDepth: 3),
        null,
      ),
      (
        'the last row cannot move down',
        ReorderOutline.moveDown(o('A:1 B:1'), 1, maxDepth: 3),
        null,
      ),
      (
        'a flat list swaps neighbours down',
        s(ReorderOutline.moveDown(o('a:1 b:1 c:1'), 0, maxDepth: 1)),
        'b:1 a:1 c:1',
      ),
      (
        'a flat list swaps neighbours up',
        s(ReorderOutline.moveUp(o('a:1 b:1 c:1'), 2, maxDepth: 1)),
        'a:1 c:1 b:1',
      ),
      (
        'rows never leave their section (down)',
        ReorderOutline.moveDown(sections, 1, maxDepth: 1),
        null,
      ),
      (
        'rows never leave their section (up)',
        ReorderOutline.moveUp(sections, 2, maxDepth: 1),
        null,
      ),
    ]);
  });

  test('← →', () {
    String indent(String spec, String id) {
      final items = o(spec);
      return s(ReorderOutline.indent(items, at(items, id), maxDepth: 3));
    }

    final nested = o('A:1 A1:2');
    final deep = o('A:1 B:1 B1:2 B1a:3');
    final outdented = o('A:1 A1:2 A2:2 A2a:3 B:1');
    _check([
      (
        '→ makes it the last child of the sibling above',
        indent('A:1 A1:2 B:1 B1:2', 'B'),
        'A:1 A1:2 B:2 B1:3',
      ),
      (
        '→ needs a sibling above (top)',
        ReorderOutline.indent(nested, 0, maxDepth: 3),
        null,
      ),
      (
        '→ needs a sibling above (only child)',
        ReorderOutline.indent(nested, 1, maxDepth: 3),
        null,
      ),
      (
        '→ refuses to push the block past 3 levels',
        ReorderOutline.indent(deep, at(deep, 'B'), maxDepth: 3),
        null,
      ),
      (
        '← places it right after the old parent block',
        s(ReorderOutline.outdent(outdented, at(outdented, 'A1'))),
        'A:1 A2:2 A2a:3 A1:1 B:1',
      ),
      (
        '← is not possible at top level',
        ReorderOutline.outdent(o('A:1'), 0),
        null,
      ),
    ]);
  });

  test('drop levels', () {
    final inPlace = o('A:1 A1:2 B:1');
    final rest = o('A:1 A1:2');
    _check([
      (
        'depth clamp: max one below the row above, block within 3',
        _levels('A:1 A1:2 B:1 B1:2', 'B', 2, height: 2),
        (1, 2),
      ),
      (
        'no stealing: never between a row and its first child',
        _levels('A:1 A1:2 L:1', 'L', 1, height: 1),
        (2, 2),
      ),
      (
        'a 3-level block cannot drop under anything',
        _levels('A:1 B:1 B1:2 B1a:3', 'B', 1, height: 3),
        (1, 1),
      ),
      (
        'not inside a collapsed row',
        _levels('A:1 A1:2 L:1', 'L', 2, height: 1, collapsed: {'A'}),
        (1, 1),
      ),
      (
        'moveTo in place at the same level is a no-op',
        s(ReorderOutline.moveTo(inPlace, 1, 1, 2, maxDepth: 3)),
        s(inPlace),
      ),
      (
        'moveTo rejects an invalid level',
        ReorderOutline.moveTo(o('A:1 B:1'), 1, 1, 3, maxDepth: 3),
        null,
      ),
      (
        'moveTo takes a valid level',
        s(ReorderOutline.moveTo(o('A:1 B:1'), 1, 1, 2, maxDepth: 3)),
        'A:1 B:2',
      ),
      (
        'parentAt: a child',
        ReorderOutline.parentAt(rest, 2, 2, section: null),
        'A',
      ),
      (
        'parentAt: a grandchild',
        ReorderOutline.parentAt(rest, 2, 3, section: null),
        'A1',
      ),
      (
        'parentAt: the top',
        ReorderOutline.parentAt(rest, 2, 1, section: null),
        null,
      ),
    ]);
  });
}
