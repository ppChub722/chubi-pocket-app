import 'package:equatable/equatable.dart';

import 'auth_token.dart';
import 'user.dart';

/// `POST /auth/telegram/start`: open [url] in Telegram.
class TelegramLoginStart extends Equatable {
  const TelegramLoginStart({
    required this.code,
    required this.url,
    required this.expiresAt,
  });

  factory TelegramLoginStart.fromJson(Map<String, dynamic> json) =>
      TelegramLoginStart(
        code: json['code'] as String,
        url: json['url'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );

  final String code;
  final String url;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [code, url, expiresAt];
}

/// The sign-up page prefill (Telegram's name, @username and photo).
class TelegramSignupInfo extends Equatable {
  const TelegramSignupInfo({
    required this.displayName,
    required this.usernameSuggestion,
    required this.hasPhoto,
  });

  factory TelegramSignupInfo.fromJson(Map<String, dynamic> json) =>
      TelegramSignupInfo(
        displayName: (json['display_name'] as String?) ?? '',
        usernameSuggestion: (json['username_suggestion'] as String?) ?? '',
        hasPhoto: (json['has_photo'] as bool?) ?? false,
      );

  final String displayName;
  final String usernameSuggestion;
  final bool hasPhoto;

  @override
  List<Object?> get props => [displayName, usernameSuggestion, hasPhoto];
}

/// `POST /auth/telegram/exchange`.
sealed class TelegramExchange {
  const TelegramExchange();

  factory TelegramExchange.fromJson(Map<String, dynamic> json) {
    switch (json['status']) {
      case 'login':
        final auth = json['auth'] as Map<String, dynamic>;
        return TelegramLoggedIn(
          user: User.fromJson(auth['user'] as Map<String, dynamic>),
          token: AuthToken.fromJson(auth['token'] as Map<String, dynamic>),
        );
      case 'signup':
        return TelegramNeedsSignup(
          TelegramSignupInfo.fromJson(json['signup'] as Map<String, dynamic>),
        );
      default:
        return const TelegramPending();
    }
  }
}

/// Not confirmed in Telegram yet (202).
class TelegramPending extends TelegramExchange {
  const TelegramPending();
}

/// Confirmed by a linked chat: the same answer as a login.
class TelegramLoggedIn extends TelegramExchange {
  const TelegramLoggedIn({required this.user, required this.token});
  final User user;
  final AuthToken token;
}

/// The chat has no account and the user asked for one.
class TelegramNeedsSignup extends TelegramExchange {
  const TelegramNeedsSignup(this.info);
  final TelegramSignupInfo info;
}
