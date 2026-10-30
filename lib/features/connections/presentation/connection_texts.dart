import '../../../l10n/gen/app_localizations.dart';

/// The words for a connection permission key (the BE sends keys only); an
/// unknown key shows as itself.
String connectionPermissionLabel(AppLocalizations l, String key) =>
    switch (key) {
      'chat' => l.connectionsPermissionChat,
      'ask' => l.connectionsPermissionAsk,
      'slip' => l.connectionsPermissionSlip,
      'notify' => l.connectionsPermissionNotify,
      'login' => l.connectionsPermissionLogin,
      'sheets' => l.connectionsPermissionSheets,
      'calendar' => l.connectionsPermissionCalendar,
      _ => key,
    };
