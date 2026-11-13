import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/logger/app_logger.dart';
import 'pkce.dart';

/// What a Telegram login is for: signing in (or up), or linking Telegram to
/// the signed-in account.
enum TelegramOidcPurpose { login, link }

class TelegramOidcException implements Exception {
  const TelegramOidcException(this.message);
  final String message;

  @override
  String toString() => 'TelegramOidcException: $message';
}

/// Telegram did not open (no Telegram app and no browser tab).
class TelegramOidcOpenFailed extends TelegramOidcException {
  const TelegramOidcOpenFailed() : super('could not open Telegram');
}

/// Log In With Telegram (OIDC, public client + PKCE, client_id = the bot id),
/// as Telegram's Android SDK does it: ask oauth.telegram.org for a `tg://`
/// link that opens the Telegram app (a browser tab when that fails), catch
/// the redirect back (`TelegramLoginActivity`), then trade the code for an
/// `id_token`. The BE verifies it; it lives 30 s, so send it at once.
///
/// One instance for the app: it owns the native channel. The verifier is
/// kept on disk until the redirect, because Android may kill the app while
/// Telegram is open; [resume] then finishes the login.
class TelegramOidc {
  TelegramOidc({
    this.clientId = defaultClientId,
    this.redirectUri = defaultRedirect,
    Dio? dio,
  }) : _oauth = dio ?? Dio(BaseOptions(baseUrl: _base)) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'redirect') return;
      final waiting = _redirect;
      if (waiting != null && !waiting.isCompleted) waiting.complete();
    });
  }

  /// @chubiPocket_bot (BotFather → Login Widget).
  static const defaultClientId = '9059620815';

  /// The App Link Telegram made for this app (package + signing key are
  /// registered in BotFather: a new signing key must be registered again).
  static const defaultRedirect = 'https://app3272567738-login.tg.dev/tglogin';
  static const scopes = ['openid', 'profile', 'telegram:bot_access'];

  static const _base = 'https://oauth.telegram.org';
  static const _channel = MethodChannel('chubi_pocket/telegram_login');
  static const _sessionKey = 'telegram_oidc_session';

  final String clientId;
  final String redirectUri;
  final Dio _oauth;
  Completer<void>? _redirect;

  /// The whole round trip: the id_token, or null when the user did not come
  /// back from Telegram within [timeout] (or [cancel] was called).
  Future<String?> signIn(
    TelegramOidcPurpose purpose, {
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final verifier = Pkce.newVerifier();
    final query = {
      'client_id': clientId,
      'response_type': 'code',
      'scope': scopes.join(' '),
      'redirect_uri': redirectUri,
      'code_challenge': Pkce.challengeFor(verifier),
      'code_challenge_method': 'S256',
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionKey,
      jsonEncode({'purpose': purpose.name, 'verifier': verifier}),
    );
    await _channel.invokeMethod<String>('takeRedirect'); // drop a stale one
    final waiting = _redirect = Completer<void>();

    final tgUrl = await _inAppUrl(query);
    var opened =
        tgUrl != null &&
        await launchUrl(
          Uri.parse(tgUrl),
          mode: LaunchMode.externalNonBrowserApplication,
        );
    if (!opened) {
      opened = await launchUrl(
        Uri.parse('$_base/auth').replace(queryParameters: query),
        mode: LaunchMode.inAppBrowserView,
      );
    }
    if (!opened) {
      _redirect = null;
      await prefs.remove(_sessionKey);
      throw const TelegramOidcOpenFailed();
    }

    try {
      await waiting.future.timeout(timeout);
    } on TimeoutException {
      return null;
    } finally {
      _redirect = null;
    }
    return (await resume())?.token;
  }

  /// Finishes a login whose redirect has arrived, also after the app was
  /// killed meanwhile; null = no redirect waiting.
  Future<({TelegramOidcPurpose purpose, String token})?> resume() async {
    final uri = await _channel.invokeMethod<String>('takeRedirect');
    if (uri == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    await prefs.remove(_sessionKey);
    if (raw == null) return null;
    final session = (jsonDecode(raw) as Map).cast<String, String>();
    final purpose = TelegramOidcPurpose.values.firstWhere(
      (p) => p.name == session['purpose'],
      orElse: () => TelegramOidcPurpose.login,
    );

    final back = Uri.parse(uri);
    final error = back.queryParameters['error'];
    if (error != null) {
      throw TelegramOidcException(
        back.queryParameters['error_description'] ?? error,
      );
    }
    final code = back.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const TelegramOidcException('no code in the redirect');
    }
    final token = await _token(code, session['verifier']!);
    return (purpose: purpose, token: token);
  }

  /// Stops waiting; [signIn] then returns null.
  void cancel() {
    final waiting = _redirect;
    if (waiting != null && !waiting.isCompleted) {
      waiting.completeError(TimeoutException('cancelled'));
    }
  }

  /// The `tg://` link that opens the consent sheet inside the Telegram app.
  Future<String?> _inAppUrl(Map<String, String> query) async {
    try {
      final res = await _oauth.get<String>(
        '/crossapp',
        queryParameters: {...query, 'android_sdk': '1'},
        options: Options(responseType: ResponseType.plain),
      );
      final body = jsonDecode(res.data ?? '{}');
      if (body is! Map) return null;
      final url = body['url'] ?? (body['result'] as Map?)?['url'];
      return url is String && url.isNotEmpty ? url : null;
    } catch (e) {
      AppLogger.instance.warn('auth.telegram_crossapp_failed error=$e');
      return null;
    }
  }

  Future<String> _token(String code, String verifier) async {
    try {
      final res = await _oauth.post<Map<String, dynamic>>(
        '/token',
        data: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': verifier,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final token = res.data?['id_token'];
      if (token is String && token.isNotEmpty) return token;
      throw const TelegramOidcException('no id_token');
    } on DioException catch (e) {
      throw TelegramOidcException('token HTTP ${e.response?.statusCode}');
    }
  }
}
