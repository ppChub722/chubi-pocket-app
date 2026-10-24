import 'package:chubi_pocket/ui/organisms/reorder/reorder.dart';
import 'package:flutter_test/flutter_test.dart';

List<OutlineItem> o(String spec) => [
  for (final t in spec.split(' '))
    OutlineItem(t.split(':')[0], int.parse(t.split(':')[1])),
];

String s(List<OutlineItem> items) =>
    items.map((r) => '${r.id}:${r.level}').join(' ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a move is one undo step; undo restores, dirty follows', () {
    final c = ReorderController(items: o('A:1 B:1 C:1'));
    c.select('C');
    expect(c.canMoveUp, isTrue);
    expect(c.canMoveDown, isFalse);
    c.moveUp();
    expect(s(c.items), 'A:1 C:1 B:1');
    expect(c.dirty, isTrue);
    expect(c.canUndo, isTrue);
    c.undo();
    expect(s(c.items), 'A:1 B:1 C:1');
    expect(c.dirty, isFalse);
  });

  test('dropping where it was picked up changes nothing (QA F2)', () {
    final c = ReorderController(items: o('A:1 A1:2 B:1'));
    expect(c.drop('A1', 1, 2), isFalse);
    expect(c.dirty, isFalse);
    expect(c.canUndo, isFalse);
  });
}
