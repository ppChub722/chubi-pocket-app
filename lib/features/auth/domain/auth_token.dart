import 'package:equatable/equatable.dart';

class AuthToken extends Equatable {
  const AuthToken({required this.accessToken, required this.expiresIn});

  final String accessToken;

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
