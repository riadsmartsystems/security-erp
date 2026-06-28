import 'package:drift/drift.dart';

class ServiceRequests extends Table {
  TextColumn get id           => text()();
  TextColumn get objectId     => text()();
  TextColumn get requestType  => text()();
  TextColumn get status       => text().withDefault(const Constant('новий'))();
  TextColumn get assignedTo   => text().nullable()();
  IntColumn  get riadVersion  => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted  => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  TextColumn get payload      => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
