import 'package:drift/drift.dart';

class RemoteInspections extends Table {
  TextColumn get id          => text()();
  TextColumn get objectId    => text()();
  TextColumn get status      => text().withDefault(const Constant('draft'))();
  TextColumn get engineerId  => text()();
  TextColumn get transcriptionStatus =>
      text().withDefault(const Constant('pending'))();
  IntColumn  get riadVersion => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  TextColumn get payload     => text().withDefault(const Constant('{}'))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
