import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'SavingChartGeometry: points stay in the plot, the top follows the data',
    () {
      final g = SavingChartGeometry.forSeries(
        size: const Size(330, 135),
        actual: const [10, 20, 40],
        projection: const [50, 60],
        target: 80,
        slots: 8,
      );
      expect(g.slots, 8);
      expect(g.maxValue, 80);
      for (var i = 0; i < 8; i++) {
        for (final v in const [0.0, 40.0, 80.0, 500.0, -5.0]) {
          final p = g.point(i, v);
          expect(g.plot.inflate(0.001).contains(p), isTrue, reason: '$i/$v');
        }
      }
      expect(g.x(0), g.plot.left);
      expect(g.x(7), g.plot.right);
      expect(g.y(80), g.plot.top);
      expect(g.y(0), g.plot.bottom);

      final above = SavingChartGeometry.forSeries(
        size: const Size(300, 100),
        actual: const [120],
        projection: const [],
        target: 80,
      );
      expect(above.maxValue, 120);

      final empty = SavingChartGeometry.forSeries(
        size: const Size(300, 100),
        actual: const [],
        projection: const [],
        target: 0,
      );
      expect(empty.slots, 1);
      expect(empty.maxValue, 1);
      expect(empty.plot.inflate(0.001).contains(empty.point(0, 0)), isTrue);
      expect(empty.y(double.nan), empty.plot.bottom);
    },
  );
}
