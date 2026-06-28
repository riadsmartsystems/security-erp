import 'package:drift/drift.dart';

class TaskCache extends Table {
  TextColumn get id         => text()();
  TextColumn get taskType   => text()();
  TextColumn get title      => text()();
  TextColumn get objectName => text().withDefault(const Constant(''))();
  TextColumn get address    => text().withDefault(const Constant(''))();
  TextColumn get status     => text()();
  TextColumn get dueTime    => text().nullable()();
  DateTimeColumn get cachedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
