/// Web: the browser resolves names itself and doesn't tell the page.
Future<List<String>> lookupHost(String host) async =>
    throw UnsupportedError('not available on web (the browser resolves it)');
