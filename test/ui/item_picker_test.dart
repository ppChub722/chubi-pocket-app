import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

// food ─ cafe ─ latte
//      └ market
// rent
final _tree = PickerTree([
  (id: 'food', parentId: null),
  (id: 'cafe', parentId: 'food'),
  (id: 'latte', parentId: 'cafe'),
  (id: 'market', parentId: 'food'),
  (id: 'rent', parentId: null),
]);

void main() {
  test('separate: every id on its own', () {
    final s = PickerSelection(mode: PickerChildren.separate)
      ..toggle('food', _tree);
    expect(s.shownTicked('cafe', _tree), isFalse);
    expect(s.shownCount(_tree), 1);
    s.toggle('food', _tree);
    expect(s.ids, isEmpty);
  });

  test('toggle: the box takes sub-items in; unticking one keeps the parent', () {
    final box = PickerSelection(mode: PickerChildren.toggle)
      ..toggle('food', _tree);
    expect(box.takesChildren('food'), isFalse);
    box.setTakesChildren('food', true, _tree);
    expect(box.shownTicked('latte', _tree), isTrue);
    expect(box.shownCount(_tree), 4);
    expect(box.withChildren, {'food'});

    final untick = PickerSelection(
      mode: PickerChildren.toggle,
      withChildren: const ['food'],
    )..toggle('cafe', _tree);
    expect(untick.takesChildren('food'), isFalse);
    expect(untick.isPicked('food'), isTrue);
    expect(untick.isPicked('market'), isTrue);
    expect(untick.shownTicked('cafe', _tree), isFalse);
    expect(untick.shownTicked('latte', _tree), isFalse);

    final folded = PickerSelection(mode: PickerChildren.toggle)
      ..toggle('food', _tree)
      ..toggle('cafe', _tree)
      ..toggle('latte', _tree)
      ..toggle('market', _tree);
    expect(folded.ids, ['food']);
    expect(folded.takesChildren('food'), isTrue);
  });

  test('normalize drops stored sub-items a pick takes in', () {
    final s = PickerSelection(
      mode: PickerChildren.toggle,
      ids: const ['cafe', 'rent'],
      withChildren: const ['food'],
    )..normalize(_tree);
    expect(s.ids.toSet(), {'food', 'rent'});
  });

  test('always: a parent takes sub-items in; unticking one drops the parent', () {
    final s = PickerSelection(mode: PickerChildren.always)
      ..toggle('food', _tree);
    expect(s.withChildren, {'food'});
    expect(s.shownTicked('latte', _tree), isTrue);

    final untick = PickerSelection(
      mode: PickerChildren.always,
      withChildren: const ['food'],
    )..toggle('latte', _tree);
    expect(untick.isPicked('food'), isFalse);
    expect(untick.isPicked('cafe'), isFalse);
    expect(untick.isPicked('market'), isTrue);
    expect(untick.shownTicked('latte', _tree), isFalse);
  });
}
