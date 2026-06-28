import 'package:drift/drift.dart';

class TaskCache extends Table {
  TextColumn get id         => text()();
  TextColumn get taskType   => text()();
  TextColumn get entityId   => text()();
  TextColumn get entityName => text().withDefault(const Constant(''))();
  TextColumn get status     => text()();
  TextColumn get assignedTo => text()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get payload    => text().withDefault(const Constant('{}'))();
  DateTimeColumn get cachedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
