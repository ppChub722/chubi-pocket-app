import 'dart:io';

/// The addresses this device's DNS gives for [host] right now.
Future<List<String>> lookupHost(String host) async => [
  for (final a in await InternetAddress.lookup(host)) a.address,
];
