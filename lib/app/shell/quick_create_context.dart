import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../features/accounts/domain/account.dart';
import '../../features/categories/domain/category.dart';
import '../../features/personal_debts/domain/debt_ledger.dart';
import '../../features/tags/domain/tag.dart';
import '../../features/transactions/domain/refs.dart';
import '../../ui/ui.dart';
import 'fade_branch_container.dart';

class QuickCreatePreset {
  const QuickCreatePreset({
    this.mode = QuickCreateMode.tx,
    this.account,
    this.category,
    this.tag,
    this.person,
    this.goalId,
    this.debtDirection,
    this.debtSub,
    this.amount,
  }) : word = null,
       color = null,
       icon = null,
       onCreate = null;

  const QuickCreatePreset.saving({this.goalId})
    : mode = QuickCreateMode.saving,
      account = null,
      category = null,
      tag = null,
      person = null,
      debtDirection = null,
      debtSub = null,
      amount = null,
      word = null,
      color = null,
      icon = null,
      onCreate = null;

  /// [debtSub] repay + [person] + [amount]: "รับคืนแล้ว ฿82" on a person page.
  const QuickCreatePreset.debt({
    this.person,
    this.debtDirection,
    this.debtSub,
    this.amount,
  }) : mode = QuickCreateMode.debt,
       account = null,
       category = null,
       tag = null,
       goalId = null,
       word = null,
       color = null,
       icon = null,
       onCreate = null;

  /// A page's OWN create action in the centre capsule (owner 2026-10-23: an
  /// event's "เพิ่มบิล" in its tint opens the event bill sheet): [word],
  /// [color] and [icon] in place of the mode's; [onCreate] runs instead of
  /// quick create. The page builds the closure, so it reaches its own state.
  const QuickCreatePreset.custom({
    required String this.word,
    required Color this.color,
    required VoidCallback this.onCreate,
    this.icon,
  }) : mode = QuickCreateMode.tx,
       account = null,
       category = null,
       tag = null,
       person = null,
       goalId = null,
       debtDirection = null,
       debtSub = null,
       amount = null;

  static const none = QuickCreatePreset();

  final String? word;
  final Color? color;
  final IconData? icon;

  /// Not part of equality: a page rebuilds its closure on every build.
  final VoidCallback? onCreate;

  final QuickCreateMode mode;
  final Account? account;
  final Category? category;
  final Tag? tag;

  final EmbeddedPerson? person;

  final String? goalId;

  final DebtEntryDirection? debtDirection;

  /// Debt mode's side: record a debt (default) or repay.
  final DebtEntrySub? debtSub;
  final double? amount;

  @override
  bool operator ==(Object other) =>
      other is QuickCreatePreset &&
      other.mode == mode &&
      other.account?.id == account?.id &&
      other.category?.id == category?.id &&
      other.tag?.id == tag?.id &&
      other.person == person &&
      other.goalId == goalId &&
      other.debtDirection == debtDirection &&
      other.debtSub == debtSub &&
      other.amount == amount &&
      other.word == word &&
      other.color == color &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(
    mode,
    account?.id,
    category?.id,
    tag?.id,
    person,
    goalId,
    debtDirection,
    debtSub,
    amount,
    word,
    color,
    icon,
  );
}

class QuickCreateContext extends ChangeNotifier {
  QuickCreateContext() {
    QuickCreateRouteObserver.changes.addListener(refresh);
  }

  final List<QuickCreateEntry> _entries = [];
  QuickCreatePreset _preset = QuickCreatePreset.none;
  int? _currentBranch;
  bool _scheduled = false;
  bool _disposed = false;

  QuickCreatePreset get preset => _preset;

  int? get currentBranch => _currentBranch;
  set currentBranch(int? i) {
    if (i == _currentBranch) return;
    _currentBranch = i;
    refresh();
  }

  void add(QuickCreateEntry e) {
    _entries.add(e);
    refresh();
  }

  void remove(QuickCreateEntry e) {
    _entries.remove(e);
    refresh();
  }

  QuickCreatePreset? active() {
    for (final e in _entries.reversed) {
      if (e.isShowing()) return e.preset;
    }
    return null;
  }

  void refresh() {
    if (_scheduled || _disposed) return;
    _scheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _scheduled = false;
        if (_disposed) return;
        final next = active() ?? QuickCreatePreset.none;
        if (next == _preset) return;
        _preset = next;
        notifyListeners();
      })
      ..scheduleFrame();
  }

  @override
  void dispose() {
    _disposed = true;
    QuickCreateRouteObserver.changes.removeListener(refresh);
    super.dispose();
  }
}

class QuickCreateEntry {
  QuickCreateEntry(this.preset, this.isShowing);
  QuickCreatePreset preset;
  final bool Function() isShowing;
}

class QuickCreateRouteObserver extends NavigatorObserver {
  static final _Changes _changes = _Changes();

  static Listenable get changes => _changes;

  void _changed() => _changes.ping();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _changed();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _changed();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _changed();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _changed();
}

class _Changes extends ChangeNotifier {
  void ping() => notifyListeners();
}

class QuickCreateContextScope extends InheritedWidget {
  const QuickCreateContextScope({
    required this.registry,
    required super.child,
    super.key,
  });

  final QuickCreateContext registry;

  static QuickCreateContext? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<QuickCreateContextScope>()
      ?.registry;

  @override
  bool updateShouldNotify(QuickCreateContextScope old) =>
      registry != old.registry;
}

class QuickCreatePresetScope extends StatefulWidget {
  const QuickCreatePresetScope({
    required this.preset,
    required this.child,
    super.key,
  });

  final QuickCreatePreset preset;
  final Widget child;

  @override
  State<QuickCreatePresetScope> createState() => _QuickCreatePresetScopeState();
}

class _QuickCreatePresetScopeState extends State<QuickCreatePresetScope> {
  QuickCreateContext? _registry;
  late final QuickCreateEntry _entry = QuickCreateEntry(
    widget.preset,
    _isShowing,
  );

  bool _isShowing() {
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return false;
    }
    final branch = TabSwitchScope.branchOf(context);
    final current = _registry?.currentBranch;
    if (branch != null && current != null) return branch == current;
    return TickerMode.valuesOf(context).enabled;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registry = QuickCreateContextScope.maybeOf(context);
    if (registry == _registry) return;
    _registry?.remove(_entry);
    _registry = registry?..add(_entry);
  }

  @override
  void didUpdateWidget(QuickCreatePresetScope old) {
    super.didUpdateWidget(old);
    if (widget.preset == _entry.preset) return;
    _entry.preset = widget.preset;
    _registry?.refresh();
  }

  @override
  void dispose() {
    _registry?.remove(_entry);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
