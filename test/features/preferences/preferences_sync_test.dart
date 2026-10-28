import 'dart:async';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/core/storage/secure_token_storage.dart';
import 'package:chubi_pocket/features/auth/data/auth_repository.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/preferences/presentation/cubit/font_id_cubit.dart';
import 'package:chubi_pocket/features/preferences/presentation/cubit/locale_cubit.dart';
import 'package:chubi_pocket/features/preferences/presentation/cubit/preferences_sync_cubit.dart';
import 'package:chubi_pocket/features/preferences/presentation/cubit/theme_id_cubit.dart';
import 'package:chubi_pocket/features/preferences/presentation/cubit/theme_mode_cubit.dart';
import 'package:chubi_pocket/features/users/data/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthRepo extends Mock implements AuthRepository {}

class _Tokens extends Mock implements SecureTokenStorage {}

class _Client extends Fake implements ApiClient {
  @override
  Stream<void> get onUnauthorized => const Stream.empty();
}

/// `/users/me` with the given server preferences (null = never saved).
User _me(Map<String, Object?> prefs) => User.fromJson({
  'id': 'u1',
  'username': 'ppond',
  'display_name': 'ppOnd',
  'currency': 'THB',
  'preferences': prefs,
});

/// PUT /users/me: merges into the server prefs and answers the user.
class _Users extends Fake implements UsersRepository {
  _Users(this.server);

  Map<String, Object?> server;
  final puts = <Map<String, Object?>>[];
  var fail = false;

  @override
  Future<User> updatePreferences(Map<String, Object?> prefs) async {
    puts.add(prefs);
    if (fail) throw const ApiException(code: 'NETWORK_ERROR', message: 'x');
    server = {...server, ...prefs};
    return _me(server);
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late SharedPreferences prefs;
  late AuthCubit auth;
  late _Users users;
  late ThemeIdCubit themeId;
  late ThemeModeCubit themeMode;
  late LocaleCubit locale;
  late FontIdCubit font;
  late PreferencesSyncCubit sync;

  Future<void> start(
    Map<String, Object?> server, {
    Map<String, Object> device = const {},
  }) async {
    SharedPreferences.setMockInitialValues(device);
    prefs = await SharedPreferences.getInstance();
    users = _Users(server);
    final repo = _AuthRepo();
    final tokens = _Tokens();
    when(() => tokens.readAuthToken()).thenAnswer((_) async => 'tok');
    when(() => repo.getCurrentUser()).thenAnswer((_) async => _me(server));
    auth = AuthCubit(
      repository: repo,
      tokenStorage: tokens,
      apiClient: _Client(),
    );
    themeId = ThemeIdCubit(prefs);
    themeMode = ThemeModeCubit(prefs);
    locale = LocaleCubit(prefs);
    font = FontIdCubit(prefs, locale);
    sync = PreferencesSyncCubit(
      auth: auth,
      users: users,
      themeId: themeId,
      themeMode: themeMode,
      locale: locale,
      font: font,
      retryAfter: const Duration(milliseconds: 20),
    );
    await auth.init();
    await _settle();
  }

  tearDown(() async {
    await sync.close();
    await font.close();
    await auth.close();
  });

  test('after login the server wins; keys it never got come from this '
      'device in ONE PUT', () async {
    await start(
      {'theme_id': 'sweet', 'theme_mode': null, 'language': 'th'},
      device: {'pref.theme_id': 'mint', 'pref.theme_mode': 'dark'},
    );
    expect(themeId.state, 'sweet', reason: 'server value applied');
    expect(users.puts, hasLength(1));
    expect(users.puts.single, {
      'theme_mode': 'dark',
      'font_th': font.fontFor('th'),
      'font_en': font.fontFor('en'),
    });
    expect(sync.state, 0);
  });

  test(
    'a change here is one PUT of that key; the echo sends nothing',
    () async {
      await start({
        'theme_id': 'mint',
        'theme_mode': 'system',
        'language': 'th',
        'font_th': 'IBM Plex Sans Thai',
        'font_en': 'Inter',
      });
      expect(users.puts, isEmpty, reason: 'all in step already');

      await themeMode.set(ThemeMode.light);
      await _settle();
      expect(users.puts.single, {'theme_mode': 'light'});

      // A font of the language not in use is saved too.
      await font.setFor('en', 'Poppins');
      await _settle();
      expect(users.puts.last, {'font_en': 'Poppins'});
      expect(users.puts, hasLength(2));
    },
  );

  test('a failed save is kept: the server does not overwrite it and it is '
      'sent again on the next profile answer', () async {
    await start({
      'theme_id': 'mint',
      'theme_mode': 'system',
      'language': 'th',
      'font_th': 'IBM Plex Sans Thai',
      'font_en': 'Inter',
    });
    users.fail = true;
    await themeMode.set(ThemeMode.dark);
    await _settle();
    expect(sync.state, 1, reason: 'one key waiting');

    // Another device changes the theme meanwhile: that answer still carries
    // the old theme_mode, which must not overwrite the waiting one.
    auth.updateUser(_me({...users.server, 'theme_id': 'sweet'}));
    await _settle();
    expect(themeId.state, 'sweet');
    expect(themeMode.state, ThemeMode.dark, reason: 'not overwritten');

    users.fail = false;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(users.puts.last, {'theme_mode': 'dark'});
    expect(users.server['theme_mode'], 'dark', reason: 'retried and saved');
    expect(sync.state, 0);
  });

  const inStep = {
    'theme_id': 'mint',
    'theme_mode': 'system',
    'language': 'th',
    'font_th': 'IBM Plex Sans Thai',
    'font_en': 'Inter',
  };

  test('saveNow (the settings page): shows at once, ONE PUT of that key, '
      'no second save from the echo', () async {
    await start(inStep);
    await sync.saveNow(PreferencesSyncCubit.themeModeKey, 'dark');
    await _settle();
    expect(themeMode.state, ThemeMode.dark);
    expect(users.puts, [
      {'theme_mode': 'dark'},
    ]);
    expect(sync.state, 0);
  });

  test('saveNow failing: the old value comes back, it throws, and nothing '
      'is kept for a retry', () async {
    await start(inStep);
    users.fail = true;
    await expectLater(
      sync.saveNow(PreferencesSyncCubit.themeIdKey, 'sweet'),
      throwsA(isA<ApiException>()),
    );
    await _settle();
    expect(themeId.state, 'mint', reason: 'rolled back');
    users.fail = false;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(users.puts, hasLength(1), reason: 'no background retry');
    expect(users.server['theme_id'], 'mint');
    expect(sync.state, 0);
  });
}
