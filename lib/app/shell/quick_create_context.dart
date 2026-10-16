import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../features/accounts/domain/account.dart';
import '../../features/categories/domain/category.dart';
import '../../features/personal_debts/domain/debt_ledger.dart';
import '../../features/tags/domain/tag.dart';
import '../../features/transactions/domain/refs.dart';
import '../../ui/ui.dart';
import 'fade_branch_container.dart';

/// What the shell's centre + opens over the page on screen (owner
/// 2026-10-12: quick create = ONE sheet with a per-page default): the
/// [mode], and what to preset in it. A page that offers nothing gets
/// [QuickCreatePreset.none] — tx mode, nothing preset. The + takes its
/// colour from [mode] ([QuickCreateModeColors]); pages never pass a colour.
///
/// Per page (one [QuickCreatePresetScope] line each): wallet detail →
/// [account]; category detail → [category]; debts list → debt mode; debt
/// person page / contact detail → debt mode + [person].
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

  /// Saving mode (ออม), optionally with the goal selected (a goal page);
  /// null = into the spare pool.
  const QuickCreatePreset.saving({this.goalId})
    : mode = QuickCreateMode.saving,
      account = null,
      category = null,
      tag = null,
      person = null,
      debtDirection = null;

  /// Debt mode, optionally with the person and the direction to start on
  /// (null = the form's default).
  const QuickCreatePreset.debt({this.person, this.debtDirection})
    : mode = QuickCreateMode.debt,
      account = null,
      category = null,
      tag = null,
      goalId = null;

  /// Tx mode, nothing preset.
  static const none = QuickCreatePreset();

  final QuickCreateMode mode;
  final Account? account;
  final Category? category;
  final Tag? tag;

  /// Debt mode's person.
  final EmbeddedPerson? person;

  /// Saving mode's goal (null = spare).
  final String? goalId;

  /// Debt mode's starting direction.
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

/// The shell's list of pages that offer a [QuickCreatePreset] — one per
/// mounted [QuickCreatePresetScope]. The page on screen is the newest one
/// whose route is the top of its tab and whose tab is the visible one
/// ([currentBranch]); a page underneath another, or in a tab left behind,
/// offers nothing.
///
/// [preset] is kept current for the + colour: it is re-read after every
/// change that can move it — a scope added / removed / changed, a tab switch
/// ([currentBranch]), a push / pop in any tab ([QuickCreateRouteObserver]) —
/// once the frame has settled, and listeners hear only real changes.
class QuickCreateContext extends ChangeNotifier {
  QuickCreateContext() {
    QuickCreateRouteObserver.changes.addListener(refresh);
  }

  final List<_Entry> _entries = [];
  QuickCreatePreset _preset = QuickCreatePreset.none;
  int? _currentBranch;
  bool _scheduled = false;
  bool _disposed = false;

  /// The preset of the page on screen (as of the last settled frame).
  QuickCreatePreset get preset => _preset;

  /// The shell's visible tab (branch index).
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

  /// The preset of the page on screen right now, or null (a plain quick
  /// create).
  QuickCreatePreset? active() {
    for (final e in _entries.reversed) {
      if (e.isShowing()) return e.preset;
    }
    return null;
  }

  /// Re-read [preset] once the current frame is done (routes and tabs have
  /// settled by then).
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

/// Tells [QuickCreateContext] that a tab's stack changed (push / pop /
/// replace / remove), so the + colour follows. One per tab navigator (an
/// observer serves one navigator); they share [changes].
class QuickCreateRouteObserver extends NavigatorObserver {
  static final _Changes _changes = _Changes();

  /// Fires on any push / pop in any tab.
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

/// Hands the shell's [QuickCreateContext] down to the tabs' pages.
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

/// Wrap a page's body: while this page is on screen, the shell's + opens
/// the quick create with [preset] (and wears its mode's colour). Mounted =
/// registered; disposed = gone. Outside the shell (a root-navigator page)
/// it does nothing.
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

  /// The top page of its tab, in the tab that's showing.
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
