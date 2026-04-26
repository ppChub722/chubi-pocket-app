import 'package:equatable/equatable.dart';

/// Bearer access token returned by `POST /v1/auth/login` and `/register`.
///
/// Phase 0/1: 30-day token, no refresh token.
/// Phase 2+:  short-lived access token + sibling `refresh_token`.
class AuthToken extends Equatable {
  const AuthToken({
    required this.accessToken,
    required this.expiresIn,
  });

  final String accessToken;

  /// Seconds until the token expires.
  final int expiresIn;

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
    );
  }

  @override
  List<Object?> get props => [accessToken, expiresIn];
}
