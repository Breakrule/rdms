import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

/// Owns the durable "active storage root" record.
///
/// [LocalStorageService] reads through this service (via a callback the
/// provider wires) so the app remembers the user's chosen folder across
/// restarts. The in-session cache in LocalStorageService is a fast path;
/// the DB row is the source of truth.
///
/// [setActivePath] only changes WHERE NEW imports go. Relocating the
/// existing library is a separate operation (see
/// [relocateLibrary]) that must verify every managed file's checksum
/// before flipping the active root, so a half-finished move cannot
/// present the user with a mix of old and new locations.
class StorageRootService {
  final AppDatabase _db;
  static const _uuid = Uuid();

  StorageRootService(this._db);

  /// Absolute path of the currently active storage root, or null if the
  /// user has not configured one and the app should fall back to its
  /// documents directory.
  Future<String?> activePath() async {
    final row = await (_db.select(_db.storageRoots)
          ..where((t) => t.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
    return row?.path;
  }

  /// Points future imports at [path]. Does NOT move existing files. If
  /// [path] does not exist yet, create it before switching so a typo
  /// fails loudly instead of silently accepting a non-existent target.
  Future<StorageRoot> setActivePath(String path, {String? label}) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _db.transaction(() async {
      await (_db.update(_db.storageRoots)
            ..where((t) => t.isActive.equals(true)))
          .write(const StorageRootsCompanion(isActive: Value(false)));
      final entry = StorageRootsCompanion.insert(
        id: _uuid.v4(),
        path: path,
        label: Value(label),
        isActive: const Value(true),
      );
      await _db.into(_db.storageRoots).insert(entry);
      return (_db.select(_db.storageRoots)
            ..where((t) => t.path.equals(path)))
          .getSingle();
    });
  }

  Future<List<StorageRoot>> listAll() => (_db.select(_db.storageRoots)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();
}
