import 'package:drift/drift.dart';

class SyncConflicts extends Table {
  TextColumn get id            => text()();
  TextColumn get docType       => text()();
  TextColumn get name          => text()();
  TextColumn get serverPayload => text()();
  TextColumn get clientPayload => text()();
  TextColumn get status        =>
      text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
