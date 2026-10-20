import 'package:drift/drift.dart';

/// Durable record of storage roots the app has been pointed at.
///
/// Only one row has [isActive] = true at a time; that row's [path] is the
/// destination new imports use. Historic rows stay for auditing and for
/// the future safe-relocation flow (implementation_plan_feat.md Phase
/// 1.2), which will mark the previous root inactive once the swap is
/// verified.
///
/// [path] is stored as a native absolute path (Windows: `D:\\...`, POSIX:
/// `/mnt/...`). It is intentionally NOT stored in the portable library
/// backup archive (see LibraryBackupService manifest); a backup restore
/// rebases paths to the destination device's active root.
class StorageRoots extends Table {
  TextColumn get id => text()(); // UUID v4
  TextColumn get path => text()();
  TextColumn get label => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
