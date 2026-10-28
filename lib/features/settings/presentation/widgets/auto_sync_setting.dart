import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../users/data/users_repository.dart';
import '../pages/settings_money_page.dart' show signedInUser;

enum AutoSyncKind { events, debts }

/// Which account switch: ซิงก์อัตโนมัติ (another member's EDIT changes my
/// copy) or รับบิลใหม่อัตโนมัติ (a NEW shared bill lands in my book; owner
/// 2026-10-28).
enum AutoSyncSwitch { sync, accept }

/// One of the four account switches (0.4.1-2 S4 / SA14 + auto-accept). There
/// is ONE value per switch (on the account), so the settings page, the event
/// page and the person page all show this same row: it reads the signed-in
/// user and a flip is one `PUT /users/me` whose answer updates every place at
/// once.
///
/// [named]: the row says what the switch does ("ซิงก์อัตโนมัติ" /
/// "รับบิลใหม่อัตโนมัติ"), for a page that is already about one kind (the
/// event / person page); otherwise it names the kind (the settings page,
/// where a section title says what the switches do).
class AutoSyncSetting extends StatelessWidget {
  const AutoSyncSetting({
    required this.kind,
    this.which = AutoSyncSwitch.sync,
    this.named = false,
    super.key,
  });

  final AutoSyncKind kind;
  final AutoSyncSwitch which;
  final bool named;

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
    final events = kind == AutoSyncKind.events;
    final sync = which == AutoSyncSwitch.sync;
    final label = named
        ? (sync ? l.settingsGroupSync : l.settingsAcceptTitle)
        : (events ? l.settingsSyncEvents : l.settingsSyncDebts);
    final caption = named
        ? (sync ? l.settingsSyncShortHint : l.settingsAcceptShortHint)
        : sync
        ? (events ? l.settingsSyncEventsHint : l.settingsSyncDebtsHint)
        : (events ? l.settingsAcceptEventsHint : l.settingsAcceptDebtsHint);
    return LiveSetting<bool>(
      value: _value(user),
      failedMessage: (_) => l.notifSettingsSaveFailed,
      save: (on) async {
        final auth = context.read<AuthCubit>();
        auth.updateUser(await _save(context.read<UsersRepository>(), on));
        return true;
      },
      builder: (context, value, onChanged) => SettingToggleRow(
        label: label,
        caption: caption,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

/// The event / person page's switches for [kind]: รับบิลใหม่อัตโนมัติ, then
/// ซิงก์อัตโนมัติ, each saying what it does. Put them in one SectionCard.
List<Widget> autoSyncRows(AutoSyncKind kind) => [
  AutoSyncSetting(kind: kind, which: AutoSyncSwitch.accept, named: true),
  AutoSyncSetting(kind: kind, named: true),
];
