import 'package:drift/drift.dart';

class PendingMediaUploads extends Table {
  IntColumn  get id          => integer().autoIncrement()();
  TextColumn get clientUuid  => text()();
  TextColumn get localPath   => text()();
  TextColumn get mediaType   => text()();
  TextColumn get parentDoctype => text()();
  TextColumn get parentName  => text()();
  TextColumn get tag         => text().withDefault(const Constant(''))();
  TextColumn get status      =>
      text().withDefault(const Constant('pending'))();
  IntColumn  get attempts    => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
