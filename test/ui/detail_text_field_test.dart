import 'dart:io';

import 'package:pp_forge/pp_forge.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The contact page's email row and the profile page's email row are the SAME
/// widget with the same config (owner 2026-10-12).
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: ThemeData(extensions: [sweetTheme.lightColors]),
    home: Scaffold(body: Material(child: child)),
  );

  Widget field(TextEditingController c, {required bool editing}) =>
      DetailTextField(
        label: 'Email',
        controller: c,
        editing: editing,
        placeholderWhenEmpty: true,
        notSetLabel: 'Not set',
        onEnterEdit: () {},
      );

  testWidgets('view + empty: ONE row, label left, "Not set" right', (t) async {
    final c = TextEditingController();
    await t.pumpWidget(host(field(c, editing: false)));
    expect(find.byType(DetailRow), findsOneWidget);
    expect(find.byType(DetailStacked), findsNothing);
    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('view + filled, and edit: stacked label + inline value', (
    t,
  ) async {
    final c = TextEditingController(text: 'a@b.co');
    await t.pumpWidget(host(field(c, editing: false)));
    expect(find.byType(DetailStacked), findsOneWidget);
    await t.pumpWidget(host(field(TextEditingController(), editing: true)));
    expect(find.byType(DetailStacked), findsOneWidget);
    expect(find.byType(DetailRow), findsNothing);
  });

  test('profile and contact pages both build their email row with it', () {
    final profile = File(
      'lib/features/settings/presentation/pages/edit_profile_page.dart',
    ).readAsStringSync();
    final contact = File(
      'lib/features/contacts/presentation/pages/contact_detail_page.dart',
    ).readAsStringSync();
    expect(profile, contains('DetailTextField('));
    expect(profile, contains('label: l.editProfileEmailLabel'));
    expect(profile, contains('placeholderWhenEmpty: true'));
    // The contact page routes every text field (email included) through it.
    expect(contact, contains('DetailTextField('));
    expect(contact, contains('l.contactEmailLabel'));
    expect(contact, isNot(contains('DetailStacked(\n        label: label')));
  });
}
