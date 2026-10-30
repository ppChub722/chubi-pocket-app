import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/top_bar_crumbs.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/connections_repository.dart';
import '../../domain/connection.dart';
import '../connection_actions.dart';
import '../connection_texts.dart';
import '../connection_view.dart';
import '../cubit/connections_cubit.dart';

/// One outside app (0.4.2 1b; the same page for every provider): linked =
/// tinted hero, permission switches, its picture, เปลี่ยนบัญชี /
/// ยกเลิกการเชื่อม; not linked = grey hero, permissions dimmed and the big
/// `เชื่อม <App>` button. Linking opens the app; the page re-reads the row
/// when the app comes back to the front.
class ConnectionPage extends StatefulWidget {
  const ConnectionPage({required this.provider, super.key});

  final String provider;

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  Connection? _row;
  Object? _error;
  bool _loading = false;

  /// A button's call is running (one at a time).
  bool _busy = false;

  /// Sent to the outside app to link: re-read on resume.
  bool _awaitingLink = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _row = context.read<ConnectionsCubit>().state.of(widget.provider);
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    _load();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onResume() {
    if (!_awaitingLink || !mounted) return;
    _awaitingLink = false;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final row = await context.read<ConnectionsRepository>().get(
        widget.provider,
      );
      if (!mounted) return;
      context.read<ConnectionsCubit>().put(row);
      setState(() {
        _row = row;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
      // Data on screen stays; the failure is a toast.
      if (_row != null) showErrorSnackBar(context, e);
    }
  }

  void _apply(Connection row) {
    context.read<ConnectionsCubit>().put(row);
    setState(() => _row = row);
  }

  /// One button = one call; its answer replaces the row.
  Future<void> _run(Future<Connection> Function() call) async {
    final c = _row;
    if (c == null || _busy) return;
    setState(() => _busy = true);
    try {
      final row = await call();
      if (mounted) _apply(row);
    } on ApiException catch (e) {
      if (mounted) showConnectionError(context, c, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// เชื่อม / เปลี่ยนบัญชี: the link URL, opened in the outside app.
  Future<void> _link() async {
    final c = _row;
    if (c == null || _busy) return;
    final l = AppLocalizations.of(context)!;
    final repo = context.read<ConnectionsRepository>();
    setState(() => _busy = true);
    try {
      final start = await repo.startLink(c.provider);
      final uri = Uri.tryParse(start.url);
      final opened =
          uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (opened) {
        _awaitingLink = true;
      } else {
        showAppSnackBar(
          context,
          l.connectionsOpenFailed(c.name),
          tone: Tone.danger,
        );
      }
    } on ApiException catch (e) {
      if (mounted) showConnectionError(context, c, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink() async {
    final c = _row;
    if (c == null) return;
    final l = AppLocalizations.of(context)!;
    final repo = context.read<ConnectionsRepository>();
    final ok = await showConfirmDialog(
      context,
      title: l.connectionsUnlinkTitle(c.name),
      confirmLabel: l.connectionsUnlink,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run(() => repo.unlink(c.provider));
  }

  Future<void> _deletePhoto() async {
    final c = _row;
    if (c == null || _busy) return;
    final done = await deleteConnectionPhoto(context, c);
    if (done && mounted) setState(() => _row = c.withoutPhoto());
  }

  String _date(DateTime? d) => d == null
      ? ''
      : DateFormatter.medium(
          d.toLocal(),
          locale: Localizations.localeOf(context).toLanguageTag(),
        );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = _row;
    return Scaffold(
      appBar: AppTopBar(
        title: c?.name ?? '',
        showBack: true,
        parent: TopBarCrumb(
          label: l.profileTitle,
          path: '/settings/profile',
          routeName: 'settings-profile',
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AsyncStateView(
        loading: c == null && _loading,
        error: c == null ? _error : null,
        isEmpty: false,
        onRetry: _load,
        builder: (context) => _body(context, l, _row!),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, Connection c) {
    // The Scaffold's body context: its top padding already holds the bar.
    final inset = MediaQuery.paddingOf(context);
    final repo = context.read<ConnectionsRepository>();
    return DetailPageBody(
      onRefresh: _load,
      physics: const AlwaysScrollableScrollPhysics(),
      bottomInset: AppSpacing.huge + inset.bottom,
      hero: ConnectionHeroCard(
        name: c.name,
        logoUrl: c.logoUrl,
        linked: c.linked,
        brand: c.brand,
        photoUrl: c.photo?.url,
        account: c.account,
        linkedAtText: c.linkedAt == null
            ? null
            : l.connectionsLinkedAt(_date(c.linkedAt)),
        notLinkedLabel: l.connectionsNotLinked,
      ),
      sections: [
        (first) => c.permissions.isEmpty
            ? null
            : SectionCard(
                first: first,
                title: l.connectionsSectionPermissions,
                children: [
                  for (final p in c.permissions) _permission(l, c, p, repo),
                ],
              ),
        if (!c.linked)
          (first) => Padding(
            padding: EdgeInsets.only(top: first ? 0 : AppSpacing.xxl),
            child: ConnectionLinkButton(
              label: l.connectionsLink(c.name),
              brand: c.brand,
              loading: _busy,
              onPressed: c.available ? _link : null,
            ),
          ),
        if (c.linked) ...[
          (first) => SectionCard(
            first: first,
            title: l.profileSectionPicture,
            children: [
              AvatarSourceRow(
                title: l.connectionsPhotoFrom(c.name),
                subtitle: c.photo == null
                    ? l.connectionsPhotoNotImported
                    : l.profilePictureImportedAt(_date(c.photo!.importedAt)),
                thumb: c.photo == null
                    ? null
                    : Avatar(
                        AvatarData(
                          kind: AvatarKind.photo,
                          photoUrl: c.photo!.url,
                          initials: AvatarData.initialsOf(c.name),
                          colors: [AvatarData.nameColorHex(c.name)],
                        ),
                        size: AvatarSourceRow.thumbSize,
                      ),
                actions: [
                  AppButton(
                    label: c.photo == null
                        ? l.connectionsPhotoImport
                        : l.connectionsPhotoUpdate,
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.chip,
                    submits: true,
                    onPressed: _busy
                        ? null
                        : () => _run(() => repo.importPhoto(c.provider)),
                  ),
                  if (c.photo != null)
                    AppButton(
                      label: l.commonDelete,
                      variant: AppButtonVariant.destructiveOutlined,
                      size: AppButtonSize.chip,
                      submits: true,
                      onPressed: _busy ? null : _deletePhoto,
                    ),
                ],
              ),
            ],
          ),
          (first) => SectionCard(
            first: first,
            title: l.profileSectionAccount,
            children: [
              AppDetailRow(
                icon: AppIcons.transfer,
                label: l.connectionsChangeAccount(c.name),
                showChevron: true,
                onTap: _busy ? null : _link,
              ),
              AppDetailRow(
                icon: AppIcons.unlink,
                label: l.connectionsUnlink,
                destructive: true,
                onTap: _busy ? null : _unlink,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _permission(
    AppLocalizations l,
    Connection c,
    ConnectionPermission p,
    ConnectionsRepository repo,
  ) {
    final label = connectionPermissionLabel(l, p.key);
    return switch (permissionRowState(c, p)) {
      PermissionRowState.comingSoon => AppDetailRow(
        label: label,
        comingSoon: true,
      ),
      PermissionRowState.dimmed => AppDetailRow(label: label, dimmed: true),
      PermissionRowState.toggle => LiveSetting<bool>(
        key: ValueKey('perm-${p.key}'),
        value: p.on,
        save: (v) async {
          final row = await repo.setPermissions(c.provider, {p.key: v});
          if (mounted) _apply(row);
          return true;
        },
        failedMessage: (e) =>
            e is ApiException ? e.message : ErrorView.titleFor(context, e),
        builder: (context, value, onChanged) =>
            SettingToggleRow(label: label, value: value, onChanged: onChanged),
      ),
    };
  }
}
