import 'package:drift/drift.dart';

class ChecklistInstances extends Table {
  TextColumn get id          => text()();
  TextColumn get visitId     => text()();
  TextColumn get templateId  => text()();
  TextColumn get status      => text().withDefault(const Constant('draft'))();
  IntColumn  get riadVersion => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  TextColumn get payload     => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
