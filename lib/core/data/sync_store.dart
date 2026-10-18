import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'sync_set.dart';

class SyncEntry {
  const SyncEntry({required this.v, required this.body, required this.savedAt});

  final String v;
  final Map<String, dynamic> body;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'v': v,
    'body': body,
    'saved_at': savedAt.toIso8601String(),
  };

  static SyncEntry? tryParse(Object? json) {
    if (json is! Map) return null;
    final v = json['v'];
    final body = json['body'];
    final savedAt = DateTime.tryParse('${json['saved_at']}');
    if (v is! String || body is! Map || savedAt == null) return null;
    return SyncEntry(
      v: v,
      body: Map<String, dynamic>.from(body),
      savedAt: savedAt,
    );
  }
}

/// `<appDocuments>/sync/<userId>/<set>.json`, one folder per user. Where files
/// are unavailable (web) it keeps nothing and every read comes back empty.
class SyncStore {
  SyncStore({Future<Directory> Function()? root})
    : _root = root ?? _documentsRoot;

  final Future<Directory> Function() _root;

  static Future<Directory> _documentsRoot() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}${Platform.pathSeparator}sync');
  }

  Future<Directory?> _userDir(String userId, {bool create = false}) async {
    if (kIsWeb) return null;
    try {
      final dir = Directory(
        '${(await _root()).path}${Platform.pathSeparator}$userId',
      );
      if (create && !await dir.exists()) await dir.create(recursive: true);
      return dir;
    } catch (_) {
      return null;
    }
  }

  File _file(Directory dir, SyncSet set) =>
      File('${dir.path}${Platform.pathSeparator}${set.wire}.json');

  Future<Map<SyncSet, SyncEntry>> readAll(String userId) async {
    final out = <SyncSet, SyncEntry>{};
    final dir = await _userDir(userId);
    if (dir == null) return out;
    for (final set in SyncSet.values) {
      try {
        final file = _file(dir, set);
        if (!await file.exists()) continue;
        final entry = SyncEntry.tryParse(jsonDecode(await file.readAsString()));
        if (entry != null) out[set] = entry;
      } catch (_) {
        // A damaged file is just a dataset the device doesn't hold yet.
      }
    }
    return out;
  }

  Future<void> write(String userId, SyncSet set, SyncEntry entry) async {
    final dir = await _userDir(userId, create: true);
    if (dir == null) return;
    try {
      final file = _file(dir, set);
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(entry.toJson()), flush: true);
      await tmp.rename(file.path);
    } catch (_) {
      // Nothing saved: the next start fetches the dataset again.
    }
  }

  /// Deletes this user's folder.
  Future<void> clear(String userId) async {
    final dir = await _userDir(userId);
    if (dir == null) return;
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  /// Deletes every folder except [keepUserId]'s (data left by another account).
  Future<void> clearOthers(String keepUserId) async {
    if (kIsWeb) return;
    try {
      final root = await _root();
      if (!await root.exists()) return;
      await for (final e in root.list()) {
        if (e is Directory &&
            e.uri.pathSegments.where((s) => s.isNotEmpty).last != keepUserId) {
          await e.delete(recursive: true);
        }
      }
    } catch (_) {}
  }
}
