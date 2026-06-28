import 'package:drift/drift.dart';

class ChecklistItems extends Table {
  TextColumn get id             => text()();
  TextColumn get instanceId     => text()();
  TextColumn get itemUuid       => text()();
  TextColumn get label          => text()();
  BoolColumn get checked        => boolean().withDefault(const Constant(false))();
  TextColumn get photoId        => text().nullable()();
  TextColumn get serialNo       => text().nullable()();
  IntColumn  get riadVersion    => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted    => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt  =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
