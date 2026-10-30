import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/tone.dart';
import 'app_message.dart';

/// The one place snacks live (owner 2026-10-30): bottom only, never a top
/// banner. The first snack sits at the bottom, newer ones push the older ones
/// up. A page with a bottom bar or a floating bottom button shows the stack
/// above it; a page without rises from the very bottom (a Scaffold's own
/// SnackBar placement does both).
///
/// Rules: at most [maxTransient] auto-dismissing snacks at once (a new one
/// pushes the oldest out); the same message again replaces its older copy
/// instead of stacking; a sticky snack (the connection one) is never pushed
/// out and stays until it is cleared or closed.
///
/// One stack per [ScaffoldMessengerState] ([SnackStack.of]) and one per
/// [OverlayState] for snacks raised over a sheet ([SnackStack.over]).
class SnackStack extends ChangeNotifier {
  SnackStack._(this._host);

  static const maxTransient = 3;
  static const defaultDuration = Duration(seconds: 4);
  static const withActionDuration = Duration(seconds: 6);

  static final _messengers = Expando<SnackStack>('messenger snack stack');
  static final _overlays = Expando<SnackStack>('overlay snack stack');

  /// The stack of this messenger: shown by the Scaffold under it.
  static SnackStack of(ScaffoldMessengerState messenger) =>
      _messengers[messenger] ??= SnackStack._(_ScaffoldHost(messenger));

  /// The stack over the routes of this overlay (a snack raised from a sheet,
  /// which has no Scaffold): shown above the sheet, above the keyboard.
  static SnackStack over(OverlayState overlay) =>
      _overlays[overlay] ??= SnackStack._(_OverlayHost(overlay));

  final _Host _host;
  final _entries = <SnackEntry>[];
  var _nextId = 0;

  /// Oldest first (the view shows the oldest at the bottom).
  List<SnackEntry> get entries => List.unmodifiable(_entries);

  /// A snack that goes by itself after [duration].
  void show(
    String message, {
    Tone tone = Tone.neutral,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    // The same message again replaces its older copy.
    _remove(
      (e) =>
          !e.sticky &&
          e.message == message &&
          e.tone == tone &&
          e.actionLabel == actionLabel,
    );
    final hasAction = actionLabel != null && onAction != null;
    final entry = SnackEntry._(
      id: _nextId++,
      message: message,
      tone: tone,
      actionLabel: hasAction ? actionLabel : null,
      onAction: hasAction ? onAction : null,
    );
    entry._timer = Timer(
      duration ?? (hasAction ? withActionDuration : defaultDuration),
      () => dismiss(entry.id),
    );
    _entries.add(entry);
    // The oldest auto-dismissing ones make room.
    final transient = _entries.where((e) => !e.sticky).toList();
    for (var i = 0; i < transient.length - maxTransient; i++) {
      _dismissEntry(transient[i]);
    }
    _changed();
  }

  /// A snack that stays until [clearSticky] (or its own close): the content
  /// is a widget the caller keeps up to date by calling this again with the
  /// same [key] (the connection snack). The newest sticky is shown on top.
  void setSticky(String key, WidgetBuilder content) {
    final existing = _entries.where((e) => e.key == key).firstOrNull;
    if (existing != null) {
      existing._content = content;
      notifyListeners();
      return;
    }
    _entries.add(SnackEntry._(id: _nextId++, key: key, content: content));
    _changed();
  }

  /// [show]: false when the widget that owns the snack is being torn down
  /// (its Scaffold may already be gone, so the bar is left alone).
  void clearSticky(String key, {bool show = true}) {
    if (!_remove((e) => e.key == key)) return;
    if (show) {
      _changed();
    } else {
      notifyListeners();
    }
  }

  /// Drops every auto-dismissing snack (a page change that must not carry
  /// an error with it); sticky ones stay.
  void clearTransient() {
    if (_remove((e) => !e.sticky)) _changed();
  }

  void dismiss(int id) {
    if (_remove((e) => e.id == id)) _changed();
  }

  void _dismissEntry(SnackEntry e) {
    e._timer?.cancel();
    _entries.remove(e);
  }

  bool _remove(bool Function(SnackEntry e) test) {
    final gone = _entries.where(test).toList();
    for (final e in gone) {
      e._timer?.cancel();
      _entries.remove(e);
    }
    return gone.isNotEmpty;
  }

  void _changed() {
    notifyListeners();
    _host.sync(this);
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e._timer?.cancel();
    }
    super.dispose();
  }
}

class SnackEntry {
  SnackEntry._({
    required this.id,
    this.key,
    this.message = '',
    this.tone = Tone.neutral,
    this.actionLabel,
    this.onAction,
    WidgetBuilder? content,
  }) : _content = content;

  final int id;
  final String? key;
  final String message;
  final Tone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  WidgetBuilder? _content;
  Timer? _timer;

  bool get sticky => key != null;
}

abstract class _Host {
  void sync(SnackStack stack);
}

/// Shows the stack as ONE SnackBar of the messenger's Scaffold; the Scaffold
/// places it above its bottom bar / floating button.
class _ScaffoldHost implements _Host {
  _ScaffoldHost(this.messenger);

  final ScaffoldMessengerState messenger;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _bar;

  @override
  void sync(SnackStack stack) {
    if (stack.entries.isEmpty) {
      final bar = _bar;
      _bar = null;
      bar?.close();
      return;
    }
    if (_bar != null) return;
    final bar = messenger.showSnackBar(
      SnackBar(
        // The stack owns the lifetimes; the bar just stays.
        duration: const Duration(days: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(AppSpacing.md),
        content: SnackStackView(stack: stack),
      ),
    );
    _bar = bar;
    unawaited(
      bar.closed.then((_) {
        if (_bar != bar) return;
        // Closed from outside (hideCurrentSnackBar): auto-dismissing snacks
        // go with it, a sticky one comes back.
        _bar = null;
        stack.clearTransient();
        if (stack.entries.isNotEmpty) sync(stack);
      }),
    );
  }
}

/// Shows the stack as an overlay entry above the sheet and the keyboard.
class _OverlayHost implements _Host {
  _OverlayHost(this.overlay);

  final OverlayState overlay;
  OverlayEntry? _entry;

  @override
  void sync(SnackStack stack) {
    if (stack.entries.isEmpty) {
      _entry?.remove();
      _entry?.dispose();
      _entry = null;
      return;
    }
    if (_entry != null) return; // the view listens to the stack itself
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom:
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.viewPaddingOf(context).bottom +
            AppSpacing.md,
        child: SnackStackView(stack: stack),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

/// The stack's snacks, oldest at the bottom.
class SnackStackView extends StatelessWidget {
  const SnackStackView({required this.stack, super.key});

  final SnackStack stack;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: stack,
      builder: (context, _) {
        final newestFirst = stack.entries.reversed.toList();
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, e) in newestFirst.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _SnackTile(key: ValueKey(e.id), entry: e, stack: stack),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SnackTile extends StatelessWidget {
  const _SnackTile({required this.entry, required this.stack, super.key});

  final SnackEntry entry;
  final SnackStack stack;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    final content =
        entry._content?.call(context) ??
        AppMessage(
          message: entry.message,
          tone: entry.tone,
          floating: true,
          actions: [
            if (entry.actionLabel != null && entry.onAction != null)
              AppMessageAction(
                label: entry.actionLabel!,
                onPressed: () {
                  stack.dismiss(entry.id);
                  entry.onAction!();
                },
              ),
          ],
        );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: content,
    );
  }
}
