import 'package:drift/drift.dart';

class ObjectPassports extends Table {
  TextColumn get id          => text()();
  TextColumn get customerId  => text()();
  TextColumn get name        => text()();
  TextColumn get address     => text().withDefault(const Constant(''))();
  TextColumn get mapKind     => text().withDefault(const Constant('floor'))();
  TextColumn get basePlanUrl => text().nullable()();
  IntColumn  get riadVersion => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  TextColumn get payload     => text().withDefault(const Constant('{}'))();
  DateTimeColumn get cachedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
