/// A-Z a-z 0-9 _ - . , 3–50 characters; a dot never first, last or doubled.
/// Case counts: "Alice" and "alice" are two names. Same rule as the BE.
bool isValidUsername(String s) =>
    _username.hasMatch(s) &&
    !s.startsWith('.') &&
    !s.endsWith('.') &&
    !s.contains('..');

final _username = RegExp(r'^[A-Za-z0-9_.-]{3,50}$');
