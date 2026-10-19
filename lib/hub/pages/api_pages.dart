import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/ui.dart';
import '../api/openapi_model.dart';
import '../api/openapi_source.dart';
import '../api/page_flows.dart';

/// The API section of the developer portal (`/dev/api/...`), read from the
/// BE's `GET /api/v1/openapi.json`. View-only: nothing here calls an endpoint.

/// `/dev/api/pages` — THE API view: page → trigger (on open / a button) →
/// endpoint rows, each expandable in place; then the endpoints no page calls.
/// The coverage counter sits on top.
Widget buildApiPagesPage(BuildContext context) =>
    ApiDocLoader(builder: (context, doc) => _PagesView(doc: doc));

/// `/dev/api/schemas` — the shared component schemas (the response types on
/// the Pages view link here).
Widget buildApiSchemasPage(BuildContext context) =>
    ApiDocLoader(builder: (context, doc) => _SchemasView(doc: doc));

// ── Shared bits ──────────────────────────────────────────────────────────────

AppChipTone _methodTone(String method) => switch (method) {
  'GET' => AppChipTone.info,
  'POST' => AppChipTone.success,
  'DELETE' => AppChipTone.danger,
  _ => AppChipTone.warning,
};

class _MethodChip extends StatelessWidget {
  const _MethodChip(this.method, {this.muted = false});
  final String method;
  final bool muted;

  @override
  Widget build(BuildContext context) => AppChip(
    label: method,
    size: ChipSize.mini,
    tone: muted ? AppChipTone.neutral : _methodTone(method),
    selected: !muted,
  );
}

class _BreakingChip extends StatelessWidget {
  const _BreakingChip();

  @override
  Widget build(BuildContext context) => const AppChip(
    label: 'breaking',
    size: ChipSize.mini,
    tone: AppChipTone.danger,
    selected: true,
  );
}

TextStyle? _mono(BuildContext context, {double? size}) => Theme.of(
  context,
).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: size);

/// Pretty JSON in a scrollable, selectable box.
class _Json extends StatelessWidget {
  const _Json(this.value);
  final Object value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = value is String
        ? value as String
        : const JsonEncoder.withIndent('  ').convert(value);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(text, style: _mono(context, size: 12)),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// A bordered, collapsible card — one page / schema.
class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.children,
    this.subtitle,
    this.initiallyExpanded = false,
  });

  final bool initiallyExpanded;

  final Widget title;
  final Widget? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            initiallyExpanded: initiallyExpanded,
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            title: title,
            subtitle: subtitle,
            children: children,
          ),
        ),
      ),
    );
  }
}

// ── Pages → triggers → endpoints ─────────────────────────────────────────────

class _PagesView extends StatefulWidget {
  const _PagesView({required this.doc});
  final ApiDoc doc;

  @override
  State<_PagesView> createState() => _PagesViewState();
}

class _PagesViewState extends State<_PagesView> {
  String _query = '';

  bool _flowMatches(PageFlow f) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (f.page.toLowerCase().contains(q) ||
        f.purpose.toLowerCase().contains(q)) {
      return true;
    }
    return f.steps.any(
      (s) => s.calls.any((c) {
        final e = c.operationId == null
            ? null
            : widget.doc.byOperation(c.operationId!);
        final path = e?.path ?? c.path ?? '';
        return path.toLowerCase().contains(q) ||
            (e?.summary?.toLowerCase().contains(q) ?? false);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final flows = HubOpenApi.testFlows ?? pageFlows;
    final shown = flows.where(_flowMatches).toList();
    final unused = doc.unused;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CoverageCard(doc: doc, flows: flows),
        const SizedBox(height: AppSpacing.md),
        AppInput.search(
          hint: 'Search pages, paths, summaries',
          onChanged: (v) => setState(() => _query = v),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        if (shown.isEmpty) const _Muted('No page matches.'),
        for (final f in shown) _FlowCard(flow: f, doc: doc),
        if (unused.isNotEmpty && _query.trim().isEmpty)
          _Card(
            title: Text(
              'Not used by any page',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: _Muted(
              '${unused.length} spec endpoints no page flow lists yet',
            ),
            children: [
              for (final e in unused) _EndpointRow(endpoint: e, doc: doc),
            ],
          ),
      ],
    );
  }
}

/// "The spec covers X of Y registered routes", a bar, and the page targets.
class _CoverageCard extends StatelessWidget {
  const _CoverageCard({required this.doc, required this.flows});
  final ApiDoc doc;
  final List<PageFlow> flows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = doc.registeredRoutes;
    final spec = doc.specified;
    final breaking = doc.endpoints.where((e) => e.breaking != null).length;
    final overOpen = flows.where((f) => f.overOpen).length;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total == null
                ? 'Spec: $spec endpoints'
                : 'Spec covers $spec of $total registered routes',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (total != null && total > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: (spec / total).clamp(0, 1).toDouble(),
                minHeight: 8,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _Muted(
            '${flows.length} pages | $overOpen over the '
            '1-call-on-open target | $breaking endpoints marked breaking',
          ),
        ],
      ),
    );
  }
}

/// One page: its purpose, the "on open: N · actions: M" badges, then its
/// triggers with their endpoint rows.
class _FlowCard extends StatelessWidget {
  const _FlowCard({required this.flow, required this.doc});
  final PageFlow flow;
  final ApiDoc doc;

  @override
  Widget build(BuildContext context) {
    final open = flow.openCalls;
    final overActions = flow.overActions;
    return _Card(
      title: Text(flow.page, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Muted(flow.purpose),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                AppChip(
                  label: open == 0
                      ? 'on open: none'
                      : 'on open: $open ${open == 1 ? 'call' : 'calls'}',
                  size: ChipSize.mini,
                  tone: flow.overOpen
                      ? AppChipTone.danger
                      : AppChipTone.neutral,
                  selected: flow.overOpen,
                ),
                AppChip(
                  label: 'actions: ${flow.actions.length}',
                  size: ChipSize.mini,
                ),
                if (overActions > 0)
                  AppChip(
                    label: '$overActions over target',
                    size: ChipSize.mini,
                    tone: AppChipTone.danger,
                    selected: true,
                  ),
              ],
            ),
          ],
        ),
      ),
      children: [
        for (final step in flow.steps) ...[
          _Label(step.label),
          if (step.today != null) _Muted('today: ${step.today}'),
          for (final call in step.calls) _CallRow(call: call, doc: doc),
        ],
      ],
    );
  }
}

/// One call of a trigger: a spec endpoint (expandable) or one the spec does
/// not have yet (grey).
class _CallRow extends StatelessWidget {
  const _CallRow({required this.call, required this.doc});
  final FlowCall call;
  final ApiDoc doc;

  @override
  Widget build(BuildContext context) {
    if (!call.inSpec) {
      return _RowShell(
        muted: true,
        method: call.method!,
        path: call.path!,
        subtitle: call.note,
        badges: const [AppChip(label: 'not in spec yet', size: ChipSize.mini)],
      );
    }
    final e = doc.byOperation(call.operationId!);
    if (e == null) {
      return _RowShell(
        muted: true,
        method: '?',
        path: call.operationId!,
        subtitle: 'unknown operation — not in the spec',
        badges: const [],
      );
    }
    return _EndpointRow(endpoint: e, doc: doc, note: call.note);
  }
}

/// A spec endpoint as a row; tap expands the full detail in place.
class _EndpointRow extends StatefulWidget {
  const _EndpointRow({required this.endpoint, required this.doc, this.note});
  final ApiEndpoint endpoint;
  final ApiDoc doc;
  final String? note;

  @override
  State<_EndpointRow> createState() => _EndpointRowState();
}

class _EndpointRowState extends State<_EndpointRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.endpoint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RowShell(
          method: e.method,
          path: e.path,
          subtitle: widget.note ?? e.summary,
          badges: [if (e.breaking != null) const _BreakingChip()],
          open: _open,
          onTap: () => setState(() => _open = !_open),
        ),
        if (_open) _EndpointDetail(endpoint: e),
      ],
    );
  }
}

class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.method,
    required this.path,
    required this.badges,
    this.subtitle,
    this.muted = false,
    this.open,
    this.onTap,
  });

  final String method;
  final String path;
  final String? subtitle;
  final List<Widget> badges;
  final bool muted;

  /// Null = not expandable.
  final bool? open;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = muted ? scheme.onSurfaceVariant.withValues(alpha: 0.7) : null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MethodChip(method, muted: muted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path,
                    style: _mono(context, size: 13)?.copyWith(color: color),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (badges.isNotEmpty && muted)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Wrap(spacing: AppSpacing.xs, children: badges),
                    ),
                ],
              ),
            ),
            if (!muted && badges.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.xs),
              ...badges,
            ],
            if (open != null)
              Icon(
                open! ? AppIcons.collapse : AppIcons.expand,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// The detail of one endpoint, shown in place under its row.
class _EndpointDetail extends StatelessWidget {
  const _EndpointDetail({required this.endpoint});
  final ApiEndpoint endpoint;

  @override
  Widget build(BuildContext context) {
    final e = endpoint;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (e.summary != null)
            Text(e.summary!, style: Theme.of(context).textTheme.titleSmall),
          Text(
            '${e.method} ${e.path} | ${e.module}',
            style: _mono(context, size: 12),
          ),
          if (e.breaking != null && e.breaking!.isNotEmpty) ...[
            const _Label('Breaking'),
            Text(e.breaking!),
          ],
          if (e.description != null) ...[
            const _Label('Description'),
            Text(e.description!),
          ],
          if (e.params.isNotEmpty) ...[
            const _Label('Parameters'),
            for (final p in e.params) _ParamRow(p),
          ],
          if (e.request != null) ...[
            const _Label('Request'),
            _PayloadView(e.request!),
          ],
          if (e.responses.isNotEmpty) ...[
            const _Label('Responses'),
            for (final r in e.responses) _PayloadView(r),
          ],
          const _Label('Used by'),
          if (e.usedBy.isEmpty)
            const _Muted('No page flow lists this yet.')
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final u in e.usedBy)
                  AppChip(
                    label: u.calls > 1 ? '${u.page} ×${u.calls}' : u.page,
                    size: ChipSize.chip,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ParamRow extends StatelessWidget {
  const _ParamRow(this.p);
  final ApiParam p;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Wrap(
      spacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          p.name,
          style: _mono(context)?.copyWith(fontWeight: FontWeight.w700),
        ),
        AppChip(label: p.where, size: ChipSize.mini),
        AppChip(label: p.type, size: ChipSize.mini),
        if (p.required)
          const AppChip(
            label: 'required',
            size: ChipSize.mini,
            tone: AppChipTone.warning,
            selected: true,
          ),
        if (p.description != null) _Muted(p.description!),
      ],
    ),
  );
}

/// A request body or one response; its schema name links to the Schemas page.
class _PayloadView extends StatelessWidget {
  const _PayloadView(this.p);
  final ApiPayload p;

  @override
  Widget build(BuildContext context) {
    final status = p.status;
    final ok = status != null && status.startsWith('2');
    final scheme = Theme.of(context).colorScheme;
    final ref = p.ref;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (status != null)
                AppChip(
                  label: status,
                  size: ChipSize.mini,
                  tone: ok ? AppChipTone.success : AppChipTone.danger,
                  selected: true,
                ),
              if (p.type.isNotEmpty)
                ref == null
                    ? Text(p.type, style: _mono(context))
                    : InkWell(
                        onTap: () {
                          HubOpenApi.pendingSchema = ref;
                          context.push('/dev/api/schemas');
                        },
                        child: Text(
                          p.type,
                          style: _mono(context)?.copyWith(
                            color: scheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
              if (p.description != null) _Muted(p.description!),
            ],
          ),
          if (p.example != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _Json(p.example!),
          ],
        ],
      ),
    );
  }
}

// ── Schemas ──────────────────────────────────────────────────────────────────

class _SchemasView extends StatefulWidget {
  const _SchemasView({required this.doc});
  final ApiDoc doc;

  @override
  State<_SchemasView> createState() => _SchemasViewState();
}

class _SchemasViewState extends State<_SchemasView> {
  String _query = '';

  /// Set by a type link on the Pages view: show only that schema.
  String? _only = HubOpenApi.pendingSchema;

  @override
  void initState() {
    super.initState();
    HubOpenApi.pendingSchema = null;
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final s in widget.doc.schemas)
        if ((_only == null || s.name == _only) &&
            (q.isEmpty ||
                s.name.toLowerCase().contains(q) ||
                s.properties.any((p) => p.name.toLowerCase().contains(q))))
          s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput.search(
          hint: 'Search schemas and fields',
          onChanged: (v) => setState(() => _query = v),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_only != null)
          Align(
            alignment: Alignment.centerLeft,
            child: AppChip(
              label: 'Only $_only — show all',
              size: ChipSize.control,
              selected: true,
              onTap: () => setState(() => _only = null),
            ),
          )
        else
          _Muted('${shown.length} of ${widget.doc.schemas.length} schemas'),
        const SizedBox(height: AppSpacing.md),
        for (final s in shown) _SchemaCard(s, open: _only != null),
      ],
    );
  }
}

class _SchemaCard extends StatelessWidget {
  const _SchemaCard(this.s, {this.open = false});
  final ApiSchema s;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return _Card(
      initiallyExpanded: open,
      title: Row(
        children: [
          Flexible(
            child: Text(s.name, style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppChip(label: s.type, size: ChipSize.mini),
        ],
      ),
      subtitle: s.description == null
          ? null
          : Text(s.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
      children: [
        if (s.description != null) Text(s.description!),
        if (s.enumValues.isNotEmpty) ...[
          const _Label('Values'),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final v in s.enumValues)
                AppChip(label: v, size: ChipSize.chip),
            ],
          ),
        ],
        if (s.properties.isNotEmpty) ...[
          const _Label('Fields'),
          for (final p in s.properties) _PropRow(p),
        ],
        if (s.example != null) ...[const _Label('Example'), _Json(s.example!)],
      ],
    );
  }
}

class _PropRow extends StatelessWidget {
  const _PropRow(this.p);
  final ApiProp p;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              p.name,
              style: _mono(
                context,
                size: 13,
              )?.copyWith(fontWeight: FontWeight.w700),
            ),
            AppChip(label: p.type, size: ChipSize.mini),
            if (p.required)
              const AppChip(
                label: 'required',
                size: ChipSize.mini,
                tone: AppChipTone.warning,
                selected: true,
              ),
          ],
        ),
        if (p.description != null) _Muted(p.description!),
        if (p.example != null)
          Text(
            'e.g. ${jsonEncode(p.example)}',
            style: _mono(context, size: 11),
          ),
      ],
    ),
  );
}
