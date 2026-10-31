import 'package:equatable/equatable.dart';

import 'auth_token.dart';
import 'user.dart';

/// `POST /auth/telegram/token`: signed in; [isNew] = the account was made
/// by this login (a new member).
class TelegramTokenLogin extends Equatable {
  const TelegramTokenLogin({
    required this.user,
    required this.token,
    required this.isNew,
  });

  factory TelegramTokenLogin.fromJson(Map<String, dynamic> json) {
    final auth = json['auth'] as Map<String, dynamic>;
    return TelegramTokenLogin(
      user: User.fromJson(auth['user'] as Map<String, dynamic>),
      token: AuthToken.fromJson(auth['token'] as Map<String, dynamic>),
      isNew: json['status'] == 'signup',
    );
  }

  final User user;
  final AuthToken token;
  final bool isNew;

  @override
  List<Object?> get props => [user, token, isNew];
}
