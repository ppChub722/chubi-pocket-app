import 'package:flutter/widgets.dart';

/// Marks a [DetailStacked]'s value area: fields that pad their text
/// inside a box (an [InlineField]) shift left by that padding here, so the
/// text lines up with the label above.
class DetailStackedValue extends InheritedWidget {
  const DetailStackedValue({required super.child, super.key});

  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DetailStackedValue>() != null;

  @override
  bool updateShouldNotify(DetailStackedValue old) => false;
}
