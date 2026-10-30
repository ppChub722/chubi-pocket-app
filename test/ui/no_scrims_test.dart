import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No scrims (owner 2026-10-28): a running call fades the controls it locks
/// and spins the pressed one ([BusyScope]); nothing dims the page or puts a
/// spinner over it.
void main() {
  test('no scrim widgets in lib', () {
    final bad = <String>[];
    final banned = RegExp(r'\b(SavingOverlay|LoadingView|ModalBarrier)\b');
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (final (i, line) in lines.indexed) {
        if (banned.hasMatch(line)) bad.add('${f.path}:${i + 1}');
      }
    }
    expect(bad, isEmpty);
  });
}
