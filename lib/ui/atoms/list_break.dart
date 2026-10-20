import 'package:flutter/widgets.dart';

abstract interface class ListBreak {}

/// Wraps a [ListBreak] that heads a card of rows (cardedRows), so it lines up
/// with a card's title instead of with the rows' text.
class CardedListBreak extends InheritedWidget {
  const CardedListBreak({required super.child, super.key});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardedListBreak>() != null;

  @override
  bool updateShouldNotify(CardedListBreak old) => false;
}
