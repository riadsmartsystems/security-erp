import 'package:drift/drift.dart';

class InstallationPoints extends Table {
  TextColumn  get id          => text()();
  TextColumn  get mapId       => text()();
  TextColumn  get pointUuid   => text()();
  TextColumn  get mapKind     => text()();
  RealColumn  get x           => real().nullable()();
  RealColumn  get y           => real().nullable()();
  RealColumn  get lat         => real().nullable()();
  RealColumn  get lng         => real().nullable()();
  TextColumn  get label       => text().withDefault(const Constant(''))();
  TextColumn  get payload     => text().withDefault(const Constant('{}'))();
  IntColumn   get riadVersion => integer().withDefault(const Constant(0))();
  BoolColumn  get riadDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
