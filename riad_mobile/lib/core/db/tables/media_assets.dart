import 'package:drift/drift.dart';

class MediaAssets extends Table {
  TextColumn get id             => text()();
  TextColumn get clientUuid     => text()();
  TextColumn get parentDoctype  => text()();
  TextColumn get parentName     => text()();
  TextColumn get mediaType      => text()();
  TextColumn get tag            => text().withDefault(const Constant(''))();
  BoolColumn get aiAllowed      =>
      boolean().withDefault(const Constant(false))();
  TextColumn get localPath      => text().nullable()();
  TextColumn get driveId        => text().nullable()();
  TextColumn get transcriptionStatus =>
      text().withDefault(const Constant('pending'))();
  TextColumn get transcription  => text().nullable()();
  IntColumn  get riadVersion    => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted    => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt  =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
