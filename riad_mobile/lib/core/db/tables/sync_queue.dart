import 'package:drift/drift.dart';

class SyncQueue extends Table {
  IntColumn  get id          => integer().autoIncrement()();
  TextColumn get docType     => text()();
  TextColumn get name        => text()();
  TextColumn get operation   => text()();
  TextColumn get payload     => text()();
  TextColumn get status      =>
      text().withDefault(const Constant('pending'))();
  IntColumn  get attempts    => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
