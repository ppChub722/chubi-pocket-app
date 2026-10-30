import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../notifications/domain/notification_rows.dart';
import '../../../users/data/users_repository.dart';
import '../pages/settings_money_page.dart' show signedInUser;

enum AutoSyncKind { events, debts }

/// Which account switch: อัปเดตอัตโนมัติ (another member's EDIT changes my
/// copy) or รับบิลใหม่อัตโนมัติ (a NEW shared bill lands in my book; owner
/// 2026-10-28).
enum AutoSyncSwitch { sync, accept }

/// One of the four account auto switches (0.4.1-2 S4 / SA14 + auto-accept).
/// There is ONE value per switch (on the account), so the notification
/// settings page, the event page and the person page all show the same
/// value: this row reads the signed-in user and a flip is one
/// `PUT /users/me` whose answer updates every place at once.
class AutoSyncSetting extends StatelessWidget {
  const AutoSyncSetting({
    required this.kind,
    this.which = AutoSyncSwitch.sync,
    super.key,
  });

  final AutoSyncKind kind;
  final AutoSyncSwitch which;

  bool _value(User u) => switch ((which, kind)) {
    (AutoSyncSwitch.sync, AutoSyncKind.events) => u.autoSyncEvents,
    (AutoSyncSwitch.sync, AutoSyncKind.debts) => u.autoSyncDebts,
    (AutoSyncSwitch.accept, AutoSyncKind.events) => u.autoAcceptEvents,
    (AutoSyncSwitch.accept, AutoSyncKind.debts) => u.autoAcceptDebts,
  };

  Future<User> _save(UsersRepository users, bool on) {
    final events = kind == AutoSyncKind.events;
    return which == AutoSyncSwitch.sync
        ? users.setAutoSync(
            events: events ? on : null,
            debts: events ? null : on,
          )
        : users.setAutoAccept(
            events: events ? on : null,
            debts: events ? null : on,
          );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = signedInUser(context.watch<AuthCubit>().state);
    if (user == null) return const SizedBox.shrink();
    return LiveSetting<bool>(
      value: _value(user),
      failedMessage: (_) => l.notifSettingsSaveFailed,
      save: (on) async {
        final auth = context.read<AuthCubit>();
        auth.updateUser(await _save(context.read<UsersRepository>(), on));
        return true;
      },
      builder: (context, value, onChanged) => SettingToggleRow(
        label: which == AutoSyncSwitch.sync
            ? l.settingsGroupSync
            : l.settingsAcceptTitle,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

/// The event / person page's "อัตโนมัติ" card for [kind] (owner 2026-10-28):
/// says the values are account-wide and where they are set, then
/// รับบิลใหม่อัตโนมัติ and อัปเดตอัตโนมัติ.
Widget autoSyncSection(
  AppLocalizations l,
  AutoSyncKind kind, {
  bool first = false,
}) => SectionCard(
  first: first,
  title: l.settingsAutoTitle,
  description: kind == AutoSyncKind.events
      ? l.settingsAutoEventsDescription
      : l.settingsAutoDebtsDescription,
  children: [
    AutoSyncSetting(kind: kind, which: AutoSyncSwitch.accept),
    AutoSyncSetting(kind: kind),
    if (kind == AutoSyncKind.events)
      const RequestAutoSetting(which: AutoSwitch.acceptEventInvites),
  ],
);

/// A request's own auto-accept switch (0.4.2-3 F2): เชิญเข้าอีเวนต์ (event
/// page), ขอเชื่อมผู้ติดต่อ (contact page), ชวนใช้กระเป๋า (wallet page). One
/// account-wide value, the same as on the notification settings page.
class RequestAutoSetting extends StatelessWidget {
  const RequestAutoSetting({required this.which, super.key});

  final AutoSwitch which;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = signedInUser(context.watch<AuthCubit>().state);
    if (user == null) return const SizedBox.shrink();
    final (value, label) = switch (which) {
      AutoSwitch.acceptContactLinks => (
        user.autoAcceptContactLinks,
        l.settingsAutoContactLinks,
      ),
      AutoSwitch.acceptWalletInvites => (
        user.autoAcceptWalletInvites,
        l.settingsAutoWalletInvites,
      ),
      _ => (user.autoAcceptEventInvites, l.settingsAutoEventInvites),
    };
    return LiveSetting<bool>(
      value: value,
      failedMessage: (_) => l.notifSettingsSaveFailed,
      save: (on) async {
        final auth = context.read<AuthCubit>();
        final users = context.read<UsersRepository>();
        auth.updateUser(await switch (which) {
          AutoSwitch.acceptContactLinks => users.setAutoAcceptRequests(
            contactLinks: on,
          ),
          AutoSwitch.acceptWalletInvites => users.setAutoAcceptRequests(
            walletInvites: on,
          ),
          _ => users.setAutoAcceptRequests(eventInvites: on),
        });
        return true;
      },
      builder: (context, value, onChanged) => SettingToggleRow(
        label: label,
        caption: l.settingsAutoRequestCaption,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
