import 'package:chubi_pocket/ui/templates/edit_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('discrete changes undo step by step, back to the original', () {
    final d = EditDraft('a');
    expect(d.change('b'), isTrue);
    expect(d.change('c'), isTrue);
    expect(d.change('c'), isFalse, reason: 'same value is not a step');
    expect(d.isDirty, isTrue);
    d.undo();
    expect(d.working, 'b');
    expect(d.fullyUndone, isFalse);
    d.undo();
    expect(d.working, 'a');
    expect(d.fullyUndone, isTrue, reason: 'undo to original leaves edit');
    expect(d.canUndo, isFalse);
  });

  test('typing burst in one field is a single undo step', () {
    final d = EditDraft('a');
    d.textChange(#name, 'ab');
    d.textChange(#name, 'abc');
    d.commitSession();
    d.textChange(#note, 'abcX');
    d.undo();
    expect(d.working, 'abc', reason: 'reverts the open #note burst');
    d.undo();
    expect(d.working, 'a', reason: 'reverts the whole #name burst');
  });

  test('another field closes the open burst as its own step', () {
    final d = EditDraft('a');
    d.textChange(#name, 'ab');
    d.textChange(#note, 'abX');
    d.undo();
    expect(d.working, 'ab');
    d.undo();
    expect(d.working, 'a');
  });

  test('saved / discarded / rebased drafts start a clean history', () {
    final d = EditDraft('a');
    d.change('z');
    d.commitSaved('z');
    expect(d.original, 'z');
    expect(d.isDirty, isFalse);
    expect(d.canUndo, isFalse);

    d.change('y');
    d.discard();
    expect(d.working, 'z');
    expect(d.canUndo, isFalse);

    d.change('y');
    d.rebase(original: 'p', working: 'q');
    expect(d.original, 'p');
    expect(d.working, 'q');
    expect(d.isDirty, isTrue);
    expect(d.canUndo, isFalse);
  });

  test('back asks only for unsaved changes or an open typing burst', () {
    final d = EditDraft('a');
    expect(d.needsDiscardPrompt, isFalse, reason: 'nothing changed');
    d.textChange(#name, 'ab');
    expect(d.needsDiscardPrompt, isTrue, reason: 'burst open and dirty');
    d.commitSession();
    expect(d.needsDiscardPrompt, isTrue, reason: 'dirty');
    d.textChange(#name, 'a');
    expect(d.isDirty, isFalse);
    expect(d.needsDiscardPrompt, isTrue, reason: 'a burst is still open');
    d.commitSession();
    d.discard();
    expect(d.needsDiscardPrompt, isFalse);
  });
}
