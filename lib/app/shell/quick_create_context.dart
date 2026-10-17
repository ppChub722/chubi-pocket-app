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
  });

  const QuickCreatePreset.saving({this.goalId})
    : mode = QuickCreateMode.saving,
      account = null,
      category = null,
      tag = null,
      person = null,
      debtDirection = null;

  const QuickCreatePreset.debt({this.person, this.debtDirection})
    : mode = QuickCreateMode.debt,
      account = null,
      category = null,
      tag = null,
      goalId = null;

  static const none = QuickCreatePreset();

  final QuickCreateMode mode;
  final Account? account;
  final Category? category;
  final Tag? tag;

  final EmbeddedPerson? person;

  final String? goalId;

  final DebtEntryDirection? debtDirection;

  @override
  bool operator ==(Object other) =>
      other is QuickCreatePreset &&
      other.mode == mode &&
      other.account?.id == account?.id &&
      other.category?.id == category?.id &&
      other.tag?.id == tag?.id &&
      other.person == person &&
      other.goalId == goalId &&
      other.debtDirection == debtDirection;

  @override
  int get hashCode => Object.hash(
    mode,
    account?.id,
    category?.id,
    tag?.id,
    person,
    goalId,
    debtDirection,
  );
}

class QuickCreateContext extends ChangeNotifier {
  QuickCreateContext() {
    QuickCreateRouteObserver.changes.addListener(refresh);
  }

  final List<_Entry> _entries = [];
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

  void _add(_Entry e) {
    _entries.add(e);
    refresh();
  }

  void _remove(_Entry e) {
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

class _Entry {
  _Entry(this.preset, this.isShowing);
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
  late final _Entry _entry = _Entry(widget.preset, _isShowing);

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
    _registry?._remove(_entry);
    _registry = registry?.._add(_entry);
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
    _registry?._remove(_entry);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
