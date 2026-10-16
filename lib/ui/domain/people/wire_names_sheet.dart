import 'package:flutter/material.dart';

import 'package:pp_forge/pp_forge.dart';

/// One typed name of [WireNamesSheet] — plain values, not a model.
@immutable
class WireNameRow {
  const WireNameRow({required this.name, required this.subtitle});

  final String name;

  /// e.g. "in 3 splits".
  final String subtitle;
}

/// The words of [WireNamesSheet] — passed localised by the caller.
class WireNamesLabels {
  const WireNamesLabels({
    required this.title,
    required this.body,
    required this.searchHint,
    required this.saveLabel,
  });

  final String title;

  /// The caption above the search.
  final String body;
  final String searchHint;

  /// The primary button for [n] checked names.
  final String Function(int n) saveLabel;
}

/// Opens [WireNamesSheet]. [onSave] gets the checked names and returns what
/// the sheet answers with (it closes), or null when saving failed (the sheet
/// stays; the caller says why). Dismissed = null.
Future<T?> showWireNamesSheet<T>(
  BuildContext context, {
  required WireNamesLabels labels,
  required List<WireNameRow> rows,
  required Future<T?> Function(Set<String> picked) onSave,
}) => showPpForgeSheetCustom<T>(
  context,
  builder: (_) => WireNamesSheet<T>(labels: labels, rows: rows, onSave: onSave),
);

/// "Match names" — a [FormSheet] with a caption, a search and checkable name
/// rows; the primary button wires the checked ones. Presentational: rows and
/// words in, the save outcome out through [onSave].
class WireNamesSheet<T> extends StatefulWidget {
  const WireNamesSheet({
    required this.labels,
    required this.rows,
    required this.onSave,
    super.key,
  });

  final WireNamesLabels labels;
  final List<WireNameRow> rows;
  final Future<T?> Function(Set<String> picked) onSave;

  @override
  State<WireNamesSheet<T>> createState() => _WireNamesSheetState<T>();
}

class _WireNamesSheetState<T> extends State<WireNamesSheet<T>> {
  final Set<String> _picked = {};
  String _query = '';
  bool _saving = false;

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final result = await widget.onSave(_picked.toSet());
    if (!mounted) return;
    if (result == null) {
      setState(() => _saving = false);
      return;
    }
    navigator.pop(result);
  }

  void _toggle(String name) => setState(
    () => _picked.contains(name) ? _picked.remove(name) : _picked.add(name),
  );

  @override
  Widget build(BuildContext context) {
    final l = widget.labels;
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? widget.rows
        : widget.rows.where((n) => n.name.toLowerCase().contains(q)).toList();
    return FormSheet(
      title: l.title,
      primaryLabel: l.saveLabel(_picked.length),
      onPrimary: _picked.isEmpty ? null : _save,
      saving: _saving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PpForgeText(l.body, role: PpForgeTextRole.caption),
          PpForgeInput.search(
            hint: l.searchHint,
            onChanged: (v) => setState(() => _query = v),
          ),
          if (shown.isNotEmpty)
            SectionCard(
              first: true,
              children: [
                for (final n in shown)
                  ListRow(
                    title: n.name,
                    subtitle: n.subtitle,
                    checked: _picked.contains(n.name),
                    onCheck: () => _toggle(n.name),
                    onTap: () => _toggle(n.name),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
