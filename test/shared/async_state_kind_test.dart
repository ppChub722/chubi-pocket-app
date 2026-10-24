import 'package:chubi_pocket/ui/organisms/async_state_kind.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Case = ({
  String name,
  bool loading,
  bool isEmpty,
  bool hasError,
  bool settled,
  bool slow,
  bool offline,
  AsyncStateKind want,
});

void main() {
  test('a failed load never looks like "no data"', () {
    _Case c(
      String name, {
      bool loading = false,
      bool isEmpty = true,
      bool hasError = false,
      bool settled = true,
      bool slow = false,
      bool offline = false,
      required AsyncStateKind want,
    }) => (
      name: name,
      loading: loading,
      isEmpty: isEmpty,
      hasError: hasError,
      settled: settled,
      slow: slow,
      offline: offline,
      want: want,
    );

    final cases = [
      c(
        'first load running → skeleton',
        loading: true,
        settled: false,
        want: AsyncStateKind.skeleton,
      ),
      c(
        'first load, server unreachable → error',
        loading: true,
        settled: false,
        offline: true,
        want: AsyncStateKind.offline,
      ),
      c(
        'first load, taking too long → error',
        loading: true,
        settled: false,
        slow: true,
        want: AsyncStateKind.slow,
      ),
      c(
        'nothing + error → error with retry, not empty',
        hasError: true,
        want: AsyncStateKind.error,
      ),
      c('nothing + loaded → the empty view', want: AsyncStateKind.empty),
      c(
        'data wins over loading and error',
        loading: true,
        isEmpty: false,
        hasError: true,
        settled: false,
        want: AsyncStateKind.content,
      ),
      c(
        'a refresh after the first load keeps the empty view',
        loading: true,
        want: AsyncStateKind.empty,
      ),
    ];
    for (final k in cases) {
      expect(
        asyncStateKind(
          loading: k.loading,
          isEmpty: k.isEmpty,
          hasError: k.hasError,
          hasEmptyView: true,
          settled: k.settled,
          slow: k.slow,
          isOffline: () => k.offline,
        ),
        k.want,
        reason: k.name,
      );
    }
    expect(
      asyncStateKind(
        loading: false,
        isEmpty: true,
        hasError: false,
        hasEmptyView: false,
        settled: true,
        slow: false,
        isOffline: () => false,
      ),
      AsyncStateKind.content,
      reason: 'no empty view → the page builder',
    );
  });
}
