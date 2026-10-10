import 'package:chubi_pocket/app/shell/shell_chrome.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/shared/edit_mode/edit_mode_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Page extends StatefulWidget {
  const _Page();
  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> with EditModeMixin<_Page, String> {
  int restored = 0;

  @override
  void initState() {
    super.initState();
    initDraft('a');
  }

  @override
  void onDraftRestored() => restored++;

  @override
  Widget build(BuildContext context) => editScope(
    Scaffold(
      body: Text(working),
      bottomNavigationBar: isEditing
          ? editActionBar(onSave: () => commitSaved(working))
          : null,
    ),
  );
}

void main() {
  late ShellChromeController chrome;

  Future<_PageState> pump(WidgetTester t) async {
    chrome = ShellChromeController();
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShellChrome(controller: chrome, child: const _Page()),
      ),
    );
    return t.state<_PageState>(find.byType(_Page));
  }

  testWidgets('discrete changes undo step by step, back to view mode', (
    t,
  ) async {
    final s = await pump(t);
    s.applyChange('b');
    s.applyChange('c');
    await t.pump();
    expect(s.isEditing, isTrue);
    expect(s.isDirty, isTrue);
    expect(chrome.hidden, isTrue);

    s.undo();
    expect(s.working, 'b');
    s.undo();
    await t.pump();
    expect(s.working, 'a');
    expect(s.isEditing, isFalse, reason: 'undo to original leaves edit');
    expect(chrome.hidden, isFalse);
  });

  testWidgets('typing burst in one field is a single undo step', (t) async {
    final s = await pump(t);
    s.enterEdit();
    s.applyTextChange(#name, 'ab');
    s.applyTextChange(#name, 'abc');
    await t.pump(const Duration(milliseconds: 600));
    s.applyTextChange(#note, 'abcX');
    s.undo(); // reverts the open #note burst
    expect(s.working, 'abc');
    s.undo(); // reverts the whole #name burst
    expect(s.working, 'a');
  });

  testWidgets('commitSaved rebases and closes edit mode', (t) async {
    final s = await pump(t);
    s.applyChange('z');
    s.commitSaved('z');
    await t.pump();
    expect(s.original, 'z');
    expect(s.isDirty, isFalse);
    expect(s.isEditing, isFalse);
    expect(s.canUndo, isFalse);
  });

  testWidgets('back while dirty = Cancel: drops changes, no prompt', (t) async {
    final s = await pump(t);
    s.applyChange('b');
    await t.pump();
    s.handleBack();
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(s.working, 'a');
    expect(s.isEditing, isFalse);
  });

  testWidgets('system back while editing = Cancel too', (t) async {
    final s = await pump(t);
    s.applyChange('b');
    await t.pump();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(s.working, 'a');
    expect(s.isEditing, isFalse);
  });
}
