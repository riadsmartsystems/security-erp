// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $VisitsTable extends Visits with TableInfo<$VisitsTable, Visit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _objectIdMeta =
      const VerificationMeta('objectId');
  @override
  late final GeneratedColumn<String> objectId = GeneratedColumn<String>(
      'object_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _engineerIdMeta =
      const VerificationMeta('engineerId');
  @override
  late final GeneratedColumn<String> engineerId = GeneratedColumn<String>(
      'engineer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _riadVersionMeta =
      const VerificationMeta('riadVersion');
  @override
  late final GeneratedColumn<int> riadVersion = GeneratedColumn<int>(
      'riad_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _riadDeletedMeta =
      const VerificationMeta('riadDeleted');
  @override
  late final GeneratedColumn<bool> riadDeleted = GeneratedColumn<bool>(
      'riad_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("riad_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _riadDeletedAtMeta =
      const VerificationMeta('riadDeletedAt');
  @override
  late final GeneratedColumn<DateTime> riadDeletedAt =
      GeneratedColumn<DateTime>('riad_deleted_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        objectId,
        status,
        engineerId,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        payload,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visits';
  @override
  VerificationContext validateIntegrity(Insertable<Visit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('object_id')) {
      context.handle(_objectIdMeta,
          objectId.isAcceptableOrUnknown(data['object_id']!, _objectIdMeta));
    } else if (isInserting) {
      context.missing(_objectIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('engineer_id')) {
      context.handle(
          _engineerIdMeta,
          engineerId.isAcceptableOrUnknown(
              data['engineer_id']!, _engineerIdMeta));
    } else if (isInserting) {
      context.missing(_engineerIdMeta);
    }
    if (data.containsKey('riad_version')) {
      context.handle(
          _riadVersionMeta,
          riadVersion.isAcceptableOrUnknown(
              data['riad_version']!, _riadVersionMeta));
    }
    if (data.containsKey('riad_deleted')) {
      context.handle(
          _riadDeletedMeta,
          riadDeleted.isAcceptableOrUnknown(
              data['riad_deleted']!, _riadDeletedMeta));
    }
    if (data.containsKey('riad_deleted_at')) {
      context.handle(
          _riadDeletedAtMeta,
          riadDeletedAt.isAcceptableOrUnknown(
              data['riad_deleted_at']!, _riadDeletedAtMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Visit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Visit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      objectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}object_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      engineerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}engineer_id'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $VisitsTable createAlias(String alias) {
    return $VisitsTable(attachedDatabase, alias);
  }
}

class Visit extends DataClass implements Insertable<Visit> {
  final String id;
  final String objectId;
  final String status;
  final String engineerId;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Visit(
      {required this.id,
      required this.objectId,
      required this.status,
      required this.engineerId,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      required this.payload,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['object_id'] = Variable<String>(objectId);
    map['status'] = Variable<String>(status);
    map['engineer_id'] = Variable<String>(engineerId);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      id: Value(id),
      objectId: Value(objectId),
      status: Value(status),
      engineerId: Value(engineerId),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Visit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Visit(
      id: serializer.fromJson<String>(json['id']),
      objectId: serializer.fromJson<String>(json['objectId']),
      status: serializer.fromJson<String>(json['status']),
      engineerId: serializer.fromJson<String>(json['engineerId']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'objectId': serializer.toJson<String>(objectId),
      'status': serializer.toJson<String>(status),
      'engineerId': serializer.toJson<String>(engineerId),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Visit copyWith(
          {String? id,
          String? objectId,
          String? status,
          String? engineerId,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          String? payload,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Visit(
        id: id ?? this.id,
        objectId: objectId ?? this.objectId,
        status: status ?? this.status,
        engineerId: engineerId ?? this.engineerId,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Visit copyWithCompanion(VisitsCompanion data) {
    return Visit(
      id: data.id.present ? data.id.value : this.id,
      objectId: data.objectId.present ? data.objectId.value : this.objectId,
      status: data.status.present ? data.status.value : this.status,
      engineerId:
          data.engineerId.present ? data.engineerId.value : this.engineerId,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Visit(')
          ..write('id: $id, ')
          ..write('objectId: $objectId, ')
          ..write('status: $status, ')
          ..write('engineerId: $engineerId, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, objectId, status, engineerId, riadVersion,
      riadDeleted, riadDeletedAt, payload, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Visit &&
          other.id == this.id &&
          other.objectId == this.objectId &&
          other.status == this.status &&
          other.engineerId == this.engineerId &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VisitsCompanion extends UpdateCompanion<Visit> {
  final Value<String> id;
  final Value<String> objectId;
  final Value<String> status;
  final Value<String> engineerId;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VisitsCompanion({
    this.id = const Value.absent(),
    this.objectId = const Value.absent(),
    this.status = const Value.absent(),
    this.engineerId = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitsCompanion.insert({
    required String id,
    required String objectId,
    this.status = const Value.absent(),
    required String engineerId,
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        objectId = Value(objectId),
        engineerId = Value(engineerId);
  static Insertable<Visit> custom({
    Expression<String>? id,
    Expression<String>? objectId,
    Expression<String>? status,
    Expression<String>? engineerId,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (objectId != null) 'object_id': objectId,
      if (status != null) 'status': status,
      if (engineerId != null) 'engineer_id': engineerId,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitsCompanion copyWith(
      {Value<String>? id,
      Value<String>? objectId,
      Value<String>? status,
      Value<String>? engineerId,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String>? payload,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return VisitsCompanion(
      id: id ?? this.id,
      objectId: objectId ?? this.objectId,
      status: status ?? this.status,
      engineerId: engineerId ?? this.engineerId,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (objectId.present) {
      map['object_id'] = Variable<String>(objectId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (engineerId.present) {
      map['engineer_id'] = Variable<String>(engineerId.value);
    }
    if (riadVersion.present) {
      map['riad_version'] = Variable<int>(riadVersion.value);
    }
    if (riadDeleted.present) {
      map['riad_deleted'] = Variable<bool>(riadDeleted.value);
    }
    if (riadDeletedAt.present) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitsCompanion(')
          ..write('id: $id, ')
          ..write('objectId: $objectId, ')
          ..write('status: $status, ')
          ..write('engineerId: $engineerId, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChecklistInstancesTable extends ChecklistInstances
    with TableInfo<$ChecklistInstancesTable, ChecklistInstance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistInstancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _visitIdMeta =
      const VerificationMeta('visitId');
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
      'visit_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _templateIdMeta =
      const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
      'template_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _riadVersionMeta =
      const VerificationMeta('riadVersion');
  @override
  late final GeneratedColumn<int> riadVersion = GeneratedColumn<int>(
      'riad_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _riadDeletedMeta =
      const VerificationMeta('riadDeleted');
  @override
  late final GeneratedColumn<bool> riadDeleted = GeneratedColumn<bool>(
      'riad_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("riad_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _riadDeletedAtMeta =
      const VerificationMeta('riadDeletedAt');
  @override
  late final GeneratedColumn<DateTime> riadDeletedAt =
      GeneratedColumn<DateTime>('riad_deleted_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        visitId,
        templateId,
        status,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        payload,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_instances';
  @override
  VerificationContext validateIntegrity(Insertable<ChecklistInstance> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(_visitIdMeta,
          visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta));
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
          _templateIdMeta,
          templateId.isAcceptableOrUnknown(
              data['template_id']!, _templateIdMeta));
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('riad_version')) {
      context.handle(
          _riadVersionMeta,
          riadVersion.isAcceptableOrUnknown(
              data['riad_version']!, _riadVersionMeta));
    }
    if (data.containsKey('riad_deleted')) {
      context.handle(
          _riadDeletedMeta,
          riadDeleted.isAcceptableOrUnknown(
              data['riad_deleted']!, _riadDeletedMeta));
    }
    if (data.containsKey('riad_deleted_at')) {
      context.handle(
          _riadDeletedAtMeta,
          riadDeletedAt.isAcceptableOrUnknown(
              data['riad_deleted_at']!, _riadDeletedAtMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChecklistInstance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistInstance(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      visitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}visit_id'])!,
      templateId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ChecklistInstancesTable createAlias(String alias) {
    return $ChecklistInstancesTable(attachedDatabase, alias);
  }
}

class ChecklistInstance extends DataClass
    implements Insertable<ChecklistInstance> {
  final String id;
  final String visitId;
  final String templateId;
  final String status;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ChecklistInstance(
      {required this.id,
      required this.visitId,
      required this.templateId,
      required this.status,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      required this.payload,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visit_id'] = Variable<String>(visitId);
    map['template_id'] = Variable<String>(templateId);
    map['status'] = Variable<String>(status);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChecklistInstancesCompanion toCompanion(bool nullToAbsent) {
    return ChecklistInstancesCompanion(
      id: Value(id),
      visitId: Value(visitId),
      templateId: Value(templateId),
      status: Value(status),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChecklistInstance.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistInstance(
      id: serializer.fromJson<String>(json['id']),
      visitId: serializer.fromJson<String>(json['visitId']),
      templateId: serializer.fromJson<String>(json['templateId']),
      status: serializer.fromJson<String>(json['status']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitId': serializer.toJson<String>(visitId),
      'templateId': serializer.toJson<String>(templateId),
      'status': serializer.toJson<String>(status),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChecklistInstance copyWith(
          {String? id,
          String? visitId,
          String? templateId,
          String? status,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          String? payload,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ChecklistInstance(
        id: id ?? this.id,
        visitId: visitId ?? this.visitId,
        templateId: templateId ?? this.templateId,
        status: status ?? this.status,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ChecklistInstance copyWithCompanion(ChecklistInstancesCompanion data) {
    return ChecklistInstance(
      id: data.id.present ? data.id.value : this.id,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      templateId:
          data.templateId.present ? data.templateId.value : this.templateId,
      status: data.status.present ? data.status.value : this.status,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistInstance(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('templateId: $templateId, ')
          ..write('status: $status, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, visitId, templateId, status, riadVersion,
      riadDeleted, riadDeletedAt, payload, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistInstance &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.templateId == this.templateId &&
          other.status == this.status &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChecklistInstancesCompanion extends UpdateCompanion<ChecklistInstance> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<String> templateId;
  final Value<String> status;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChecklistInstancesCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.templateId = const Value.absent(),
    this.status = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistInstancesCompanion.insert({
    required String id,
    required String visitId,
    required String templateId,
    this.status = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        visitId = Value(visitId),
        templateId = Value(templateId);
  static Insertable<ChecklistInstance> custom({
    Expression<String>? id,
    Expression<String>? visitId,
    Expression<String>? templateId,
    Expression<String>? status,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (templateId != null) 'template_id': templateId,
      if (status != null) 'status': status,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistInstancesCompanion copyWith(
      {Value<String>? id,
      Value<String>? visitId,
      Value<String>? templateId,
      Value<String>? status,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String>? payload,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ChecklistInstancesCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      templateId: templateId ?? this.templateId,
      status: status ?? this.status,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (riadVersion.present) {
      map['riad_version'] = Variable<int>(riadVersion.value);
    }
    if (riadDeleted.present) {
      map['riad_deleted'] = Variable<bool>(riadDeleted.value);
    }
    if (riadDeletedAt.present) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistInstancesCompanion(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('templateId: $templateId, ')
          ..write('status: $status, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChecklistItemsTable extends ChecklistItems
    with TableInfo<$ChecklistItemsTable, ChecklistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _instanceIdMeta =
      const VerificationMeta('instanceId');
  @override
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
      'instance_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemUuidMeta =
      const VerificationMeta('itemUuid');
  @override
  late final GeneratedColumn<String> itemUuid = GeneratedColumn<String>(
      'item_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _checkedMeta =
      const VerificationMeta('checked');
  @override
  late final GeneratedColumn<bool> checked = GeneratedColumn<bool>(
      'checked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("checked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _photoIdMeta =
      const VerificationMeta('photoId');
  @override
  late final GeneratedColumn<String> photoId = GeneratedColumn<String>(
      'photo_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serialNoMeta =
      const VerificationMeta('serialNo');
  @override
  late final GeneratedColumn<String> serialNo = GeneratedColumn<String>(
      'serial_no', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _riadVersionMeta =
      const VerificationMeta('riadVersion');
  @override
  late final GeneratedColumn<int> riadVersion = GeneratedColumn<int>(
      'riad_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _riadDeletedMeta =
      const VerificationMeta('riadDeleted');
  @override
  late final GeneratedColumn<bool> riadDeleted = GeneratedColumn<bool>(
      'riad_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("riad_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _riadDeletedAtMeta =
      const VerificationMeta('riadDeletedAt');
  @override
  late final GeneratedColumn<DateTime> riadDeletedAt =
      GeneratedColumn<DateTime>('riad_deleted_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        instanceId,
        itemUuid,
        label,
        checked,
        photoId,
        serialNo,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_items';
  @override
  VerificationContext validateIntegrity(Insertable<ChecklistItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('instance_id')) {
      context.handle(
          _instanceIdMeta,
          instanceId.isAcceptableOrUnknown(
              data['instance_id']!, _instanceIdMeta));
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    if (data.containsKey('item_uuid')) {
      context.handle(_itemUuidMeta,
          itemUuid.isAcceptableOrUnknown(data['item_uuid']!, _itemUuidMeta));
    } else if (isInserting) {
      context.missing(_itemUuidMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('checked')) {
      context.handle(_checkedMeta,
          checked.isAcceptableOrUnknown(data['checked']!, _checkedMeta));
    }
    if (data.containsKey('photo_id')) {
      context.handle(_photoIdMeta,
          photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta));
    }
    if (data.containsKey('serial_no')) {
      context.handle(_serialNoMeta,
          serialNo.isAcceptableOrUnknown(data['serial_no']!, _serialNoMeta));
    }
    if (data.containsKey('riad_version')) {
      context.handle(
          _riadVersionMeta,
          riadVersion.isAcceptableOrUnknown(
              data['riad_version']!, _riadVersionMeta));
    }
    if (data.containsKey('riad_deleted')) {
      context.handle(
          _riadDeletedMeta,
          riadDeleted.isAcceptableOrUnknown(
              data['riad_deleted']!, _riadDeletedMeta));
    }
    if (data.containsKey('riad_deleted_at')) {
      context.handle(
          _riadDeletedAtMeta,
          riadDeletedAt.isAcceptableOrUnknown(
              data['riad_deleted_at']!, _riadDeletedAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChecklistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      instanceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}instance_id'])!,
      itemUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_uuid'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      checked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}checked'])!,
      photoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_id']),
      serialNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}serial_no']),
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ChecklistItemsTable createAlias(String alias) {
    return $ChecklistItemsTable(attachedDatabase, alias);
  }
}

class ChecklistItem extends DataClass implements Insertable<ChecklistItem> {
  final String id;
  final String instanceId;
  final String itemUuid;
  final String label;
  final bool checked;
  final String? photoId;
  final String? serialNo;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final DateTime updatedAt;
  const ChecklistItem(
      {required this.id,
      required this.instanceId,
      required this.itemUuid,
      required this.label,
      required this.checked,
      this.photoId,
      this.serialNo,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['instance_id'] = Variable<String>(instanceId);
    map['item_uuid'] = Variable<String>(itemUuid);
    map['label'] = Variable<String>(label);
    map['checked'] = Variable<bool>(checked);
    if (!nullToAbsent || photoId != null) {
      map['photo_id'] = Variable<String>(photoId);
    }
    if (!nullToAbsent || serialNo != null) {
      map['serial_no'] = Variable<String>(serialNo);
    }
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChecklistItemsCompanion toCompanion(bool nullToAbsent) {
    return ChecklistItemsCompanion(
      id: Value(id),
      instanceId: Value(instanceId),
      itemUuid: Value(itemUuid),
      label: Value(label),
      checked: Value(checked),
      photoId: photoId == null && nullToAbsent
          ? const Value.absent()
          : Value(photoId),
      serialNo: serialNo == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNo),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistItem(
      id: serializer.fromJson<String>(json['id']),
      instanceId: serializer.fromJson<String>(json['instanceId']),
      itemUuid: serializer.fromJson<String>(json['itemUuid']),
      label: serializer.fromJson<String>(json['label']),
      checked: serializer.fromJson<bool>(json['checked']),
      photoId: serializer.fromJson<String?>(json['photoId']),
      serialNo: serializer.fromJson<String?>(json['serialNo']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'instanceId': serializer.toJson<String>(instanceId),
      'itemUuid': serializer.toJson<String>(itemUuid),
      'label': serializer.toJson<String>(label),
      'checked': serializer.toJson<bool>(checked),
      'photoId': serializer.toJson<String?>(photoId),
      'serialNo': serializer.toJson<String?>(serialNo),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChecklistItem copyWith(
          {String? id,
          String? instanceId,
          String? itemUuid,
          String? label,
          bool? checked,
          Value<String?> photoId = const Value.absent(),
          Value<String?> serialNo = const Value.absent(),
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          DateTime? updatedAt}) =>
      ChecklistItem(
        id: id ?? this.id,
        instanceId: instanceId ?? this.instanceId,
        itemUuid: itemUuid ?? this.itemUuid,
        label: label ?? this.label,
        checked: checked ?? this.checked,
        photoId: photoId.present ? photoId.value : this.photoId,
        serialNo: serialNo.present ? serialNo.value : this.serialNo,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ChecklistItem copyWithCompanion(ChecklistItemsCompanion data) {
    return ChecklistItem(
      id: data.id.present ? data.id.value : this.id,
      instanceId:
          data.instanceId.present ? data.instanceId.value : this.instanceId,
      itemUuid: data.itemUuid.present ? data.itemUuid.value : this.itemUuid,
      label: data.label.present ? data.label.value : this.label,
      checked: data.checked.present ? data.checked.value : this.checked,
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      serialNo: data.serialNo.present ? data.serialNo.value : this.serialNo,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItem(')
          ..write('id: $id, ')
          ..write('instanceId: $instanceId, ')
          ..write('itemUuid: $itemUuid, ')
          ..write('label: $label, ')
          ..write('checked: $checked, ')
          ..write('photoId: $photoId, ')
          ..write('serialNo: $serialNo, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, instanceId, itemUuid, label, checked,
      photoId, serialNo, riadVersion, riadDeleted, riadDeletedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistItem &&
          other.id == this.id &&
          other.instanceId == this.instanceId &&
          other.itemUuid == this.itemUuid &&
          other.label == this.label &&
          other.checked == this.checked &&
          other.photoId == this.photoId &&
          other.serialNo == this.serialNo &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.updatedAt == this.updatedAt);
}

class ChecklistItemsCompanion extends UpdateCompanion<ChecklistItem> {
  final Value<String> id;
  final Value<String> instanceId;
  final Value<String> itemUuid;
  final Value<String> label;
  final Value<bool> checked;
  final Value<String?> photoId;
  final Value<String?> serialNo;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChecklistItemsCompanion({
    this.id = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.itemUuid = const Value.absent(),
    this.label = const Value.absent(),
    this.checked = const Value.absent(),
    this.photoId = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistItemsCompanion.insert({
    required String id,
    required String instanceId,
    required String itemUuid,
    required String label,
    this.checked = const Value.absent(),
    this.photoId = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        instanceId = Value(instanceId),
        itemUuid = Value(itemUuid),
        label = Value(label);
  static Insertable<ChecklistItem> custom({
    Expression<String>? id,
    Expression<String>? instanceId,
    Expression<String>? itemUuid,
    Expression<String>? label,
    Expression<bool>? checked,
    Expression<String>? photoId,
    Expression<String>? serialNo,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instanceId != null) 'instance_id': instanceId,
      if (itemUuid != null) 'item_uuid': itemUuid,
      if (label != null) 'label': label,
      if (checked != null) 'checked': checked,
      if (photoId != null) 'photo_id': photoId,
      if (serialNo != null) 'serial_no': serialNo,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? instanceId,
      Value<String>? itemUuid,
      Value<String>? label,
      Value<bool>? checked,
      Value<String?>? photoId,
      Value<String?>? serialNo,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ChecklistItemsCompanion(
      id: id ?? this.id,
      instanceId: instanceId ?? this.instanceId,
      itemUuid: itemUuid ?? this.itemUuid,
      label: label ?? this.label,
      checked: checked ?? this.checked,
      photoId: photoId ?? this.photoId,
      serialNo: serialNo ?? this.serialNo,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (itemUuid.present) {
      map['item_uuid'] = Variable<String>(itemUuid.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (checked.present) {
      map['checked'] = Variable<bool>(checked.value);
    }
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (serialNo.present) {
      map['serial_no'] = Variable<String>(serialNo.value);
    }
    if (riadVersion.present) {
      map['riad_version'] = Variable<int>(riadVersion.value);
    }
    if (riadDeleted.present) {
      map['riad_deleted'] = Variable<bool>(riadDeleted.value);
    }
    if (riadDeletedAt.present) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItemsCompanion(')
          ..write('id: $id, ')
          ..write('instanceId: $instanceId, ')
          ..write('itemUuid: $itemUuid, ')
          ..write('label: $label, ')
          ..write('checked: $checked, ')
          ..write('photoId: $photoId, ')
          ..write('serialNo: $serialNo, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ObjectPassportsTable extends ObjectPassports
    with TableInfo<$ObjectPassportsTable, ObjectPassport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ObjectPassportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _riadVersionMeta =
      const VerificationMeta('riadVersion');
  @override
  late final GeneratedColumn<int> riadVersion = GeneratedColumn<int>(
      'riad_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _riadDeletedMeta =
      const VerificationMeta('riadDeleted');
  @override
  late final GeneratedColumn<bool> riadDeleted = GeneratedColumn<bool>(
      'riad_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("riad_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _riadDeletedAtMeta =
      const VerificationMeta('riadDeletedAt');
  @override
  late final GeneratedColumn<DateTime> riadDeletedAt =
      GeneratedColumn<DateTime>('riad_deleted_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        customerId,
        name,
        address,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        payload,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'object_passports';
  @override
  VerificationContext validateIntegrity(Insertable<ObjectPassport> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('riad_version')) {
      context.handle(
          _riadVersionMeta,
          riadVersion.isAcceptableOrUnknown(
              data['riad_version']!, _riadVersionMeta));
    }
    if (data.containsKey('riad_deleted')) {
      context.handle(
          _riadDeletedMeta,
          riadDeleted.isAcceptableOrUnknown(
              data['riad_deleted']!, _riadDeletedMeta));
    }
    if (data.containsKey('riad_deleted_at')) {
      context.handle(
          _riadDeletedAtMeta,
          riadDeletedAt.isAcceptableOrUnknown(
              data['riad_deleted_at']!, _riadDeletedAtMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ObjectPassport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ObjectPassport(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $ObjectPassportsTable createAlias(String alias) {
    return $ObjectPassportsTable(attachedDatabase, alias);
  }
}

class ObjectPassport extends DataClass implements Insertable<ObjectPassport> {
  final String id;
  final String customerId;
  final String name;
  final String address;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String payload;
  final DateTime cachedAt;
  const ObjectPassport(
      {required this.id,
      required this.customerId,
      required this.name,
      required this.address,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      required this.payload,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    map['payload'] = Variable<String>(payload);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  ObjectPassportsCompanion toCompanion(bool nullToAbsent) {
    return ObjectPassportsCompanion(
      id: Value(id),
      customerId: Value(customerId),
      name: Value(name),
      address: Value(address),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      payload: Value(payload),
      cachedAt: Value(cachedAt),
    );
  }

  factory ObjectPassport.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ObjectPassport(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      payload: serializer.fromJson<String>(json['payload']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'payload': serializer.toJson<String>(payload),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  ObjectPassport copyWith(
          {String? id,
          String? customerId,
          String? name,
          String? address,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          String? payload,
          DateTime? cachedAt}) =>
      ObjectPassport(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        name: name ?? this.name,
        address: address ?? this.address,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        payload: payload ?? this.payload,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  ObjectPassport copyWithCompanion(ObjectPassportsCompanion data) {
    return ObjectPassport(
      id: data.id.present ? data.id.value : this.id,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      payload: data.payload.present ? data.payload.value : this.payload,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ObjectPassport(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, customerId, name, address, riadVersion,
      riadDeleted, riadDeletedAt, payload, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ObjectPassport &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.name == this.name &&
          other.address == this.address &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.payload == this.payload &&
          other.cachedAt == this.cachedAt);
}

class ObjectPassportsCompanion extends UpdateCompanion<ObjectPassport> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<String> name;
  final Value<String> address;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String> payload;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const ObjectPassportsCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ObjectPassportsCompanion.insert({
    required String id,
    required String customerId,
    required String name,
    this.address = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        customerId = Value(customerId),
        name = Value(name);
  static Insertable<ObjectPassport> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<String>? name,
    Expression<String>? address,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? payload,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (payload != null) 'payload': payload,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ObjectPassportsCompanion copyWith(
      {Value<String>? id,
      Value<String>? customerId,
      Value<String>? name,
      Value<String>? address,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String>? payload,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return ObjectPassportsCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      address: address ?? this.address,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      payload: payload ?? this.payload,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (riadVersion.present) {
      map['riad_version'] = Variable<int>(riadVersion.value);
    }
    if (riadDeleted.present) {
      map['riad_deleted'] = Variable<bool>(riadDeleted.value);
    }
    if (riadDeletedAt.present) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObjectPassportsCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstallationPointsTable extends InstallationPoints
    with TableInfo<$InstallationPointsTable, InstallationPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstallationPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mapIdMeta = const VerificationMeta('mapId');
  @override
  late final GeneratedColumn<String> mapId = GeneratedColumn<String>(
      'map_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pointUuidMeta =
      const VerificationMeta('pointUuid');
  @override
  late final GeneratedColumn<String> pointUuid = GeneratedColumn<String>(
      'point_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mapKindMeta =
      const VerificationMeta('mapKind');
  @override
  late final GeneratedColumn<String> mapKind = GeneratedColumn<String>(
      'map_kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
      'x', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
      'y', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
      'lng', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _riadVersionMeta =
      const VerificationMeta('riadVersion');
  @override
  late final GeneratedColumn<int> riadVersion = GeneratedColumn<int>(
      'riad_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _riadDeletedMeta =
      const VerificationMeta('riadDeleted');
  @override
  late final GeneratedColumn<bool> riadDeleted = GeneratedColumn<bool>(
      'riad_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("riad_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _riadDeletedAtMeta =
      const VerificationMeta('riadDeletedAt');
  @override
  late final GeneratedColumn<DateTime> riadDeletedAt =
      GeneratedColumn<DateTime>('riad_deleted_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        mapId,
        pointUuid,
        mapKind,
        x,
        y,
        lat,
        lng,
        label,
        payload,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installation_points';
  @override
  VerificationContext validateIntegrity(Insertable<InstallationPoint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('map_id')) {
      context.handle(
          _mapIdMeta, mapId.isAcceptableOrUnknown(data['map_id']!, _mapIdMeta));
    } else if (isInserting) {
      context.missing(_mapIdMeta);
    }
    if (data.containsKey('point_uuid')) {
      context.handle(_pointUuidMeta,
          pointUuid.isAcceptableOrUnknown(data['point_uuid']!, _pointUuidMeta));
    } else if (isInserting) {
      context.missing(_pointUuidMeta);
    }
    if (data.containsKey('map_kind')) {
      context.handle(_mapKindMeta,
          mapKind.isAcceptableOrUnknown(data['map_kind']!, _mapKindMeta));
    } else if (isInserting) {
      context.missing(_mapKindMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    }
    if (data.containsKey('lng')) {
      context.handle(
          _lngMeta, lng.isAcceptableOrUnknown(data['lng']!, _lngMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('riad_version')) {
      context.handle(
          _riadVersionMeta,
          riadVersion.isAcceptableOrUnknown(
              data['riad_version']!, _riadVersionMeta));
    }
    if (data.containsKey('riad_deleted')) {
      context.handle(
          _riadDeletedMeta,
          riadDeleted.isAcceptableOrUnknown(
              data['riad_deleted']!, _riadDeletedMeta));
    }
    if (data.containsKey('riad_deleted_at')) {
      context.handle(
          _riadDeletedAtMeta,
          riadDeletedAt.isAcceptableOrUnknown(
              data['riad_deleted_at']!, _riadDeletedAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstallationPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstallationPoint(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      mapId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}map_id'])!,
      pointUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}point_uuid'])!,
      mapKind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}map_kind'])!,
      x: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}x']),
      y: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}y']),
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat']),
      lng: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lng']),
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $InstallationPointsTable createAlias(String alias) {
    return $InstallationPointsTable(attachedDatabase, alias);
  }
}

class InstallationPoint extends DataClass
    implements Insertable<InstallationPoint> {
  final String id;
  final String mapId;
  final String pointUuid;
  final String mapKind;
  final double? x;
  final double? y;
  final double? lat;
  final double? lng;
  final String label;
  final String payload;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final DateTime updatedAt;
  const InstallationPoint(
      {required this.id,
      required this.mapId,
      required this.pointUuid,
      required this.mapKind,
      this.x,
      this.y,
      this.lat,
      this.lng,
      required this.label,
      required this.payload,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['map_id'] = Variable<String>(mapId);
    map['point_uuid'] = Variable<String>(pointUuid);
    map['map_kind'] = Variable<String>(mapKind);
    if (!nullToAbsent || x != null) {
      map['x'] = Variable<double>(x);
    }
    if (!nullToAbsent || y != null) {
      map['y'] = Variable<double>(y);
    }
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    map['label'] = Variable<String>(label);
    map['payload'] = Variable<String>(payload);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InstallationPointsCompanion toCompanion(bool nullToAbsent) {
    return InstallationPointsCompanion(
      id: Value(id),
      mapId: Value(mapId),
      pointUuid: Value(pointUuid),
      mapKind: Value(mapKind),
      x: x == null && nullToAbsent ? const Value.absent() : Value(x),
      y: y == null && nullToAbsent ? const Value.absent() : Value(y),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      label: Value(label),
      payload: Value(payload),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InstallationPoint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstallationPoint(
      id: serializer.fromJson<String>(json['id']),
      mapId: serializer.fromJson<String>(json['mapId']),
      pointUuid: serializer.fromJson<String>(json['pointUuid']),
      mapKind: serializer.fromJson<String>(json['mapKind']),
      x: serializer.fromJson<double?>(json['x']),
      y: serializer.fromJson<double?>(json['y']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      label: serializer.fromJson<String>(json['label']),
      payload: serializer.fromJson<String>(json['payload']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mapId': serializer.toJson<String>(mapId),
      'pointUuid': serializer.toJson<String>(pointUuid),
      'mapKind': serializer.toJson<String>(mapKind),
      'x': serializer.toJson<double?>(x),
      'y': serializer.toJson<double?>(y),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'label': serializer.toJson<String>(label),
      'payload': serializer.toJson<String>(payload),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InstallationPoint copyWith(
          {String? id,
          String? mapId,
          String? pointUuid,
          String? mapKind,
          Value<double?> x = const Value.absent(),
          Value<double?> y = const Value.absent(),
          Value<double?> lat = const Value.absent(),
          Value<double?> lng = const Value.absent(),
          String? label,
          String? payload,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          DateTime? updatedAt}) =>
      InstallationPoint(
        id: id ?? this.id,
        mapId: mapId ?? this.mapId,
        pointUuid: pointUuid ?? this.pointUuid,
        mapKind: mapKind ?? this.mapKind,
        x: x.present ? x.value : this.x,
        y: y.present ? y.value : this.y,
        lat: lat.present ? lat.value : this.lat,
        lng: lng.present ? lng.value : this.lng,
        label: label ?? this.label,
        payload: payload ?? this.payload,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  InstallationPoint copyWithCompanion(InstallationPointsCompanion data) {
    return InstallationPoint(
      id: data.id.present ? data.id.value : this.id,
      mapId: data.mapId.present ? data.mapId.value : this.mapId,
      pointUuid: data.pointUuid.present ? data.pointUuid.value : this.pointUuid,
      mapKind: data.mapKind.present ? data.mapKind.value : this.mapKind,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      label: data.label.present ? data.label.value : this.label,
      payload: data.payload.present ? data.payload.value : this.payload,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstallationPoint(')
          ..write('id: $id, ')
          ..write('mapId: $mapId, ')
          ..write('pointUuid: $pointUuid, ')
          ..write('mapKind: $mapKind, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('label: $label, ')
          ..write('payload: $payload, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mapId, pointUuid, mapKind, x, y, lat, lng,
      label, payload, riadVersion, riadDeleted, riadDeletedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstallationPoint &&
          other.id == this.id &&
          other.mapId == this.mapId &&
          other.pointUuid == this.pointUuid &&
          other.mapKind == this.mapKind &&
          other.x == this.x &&
          other.y == this.y &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.label == this.label &&
          other.payload == this.payload &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.updatedAt == this.updatedAt);
}

class InstallationPointsCompanion extends UpdateCompanion<InstallationPoint> {
  final Value<String> id;
  final Value<String> mapId;
  final Value<String> pointUuid;
  final Value<String> mapKind;
  final Value<double?> x;
  final Value<double?> y;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<String> label;
  final Value<String> payload;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InstallationPointsCompanion({
    this.id = const Value.absent(),
    this.mapId = const Value.absent(),
    this.pointUuid = const Value.absent(),
    this.mapKind = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.label = const Value.absent(),
    this.payload = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstallationPointsCompanion.insert({
    required String id,
    required String mapId,
    required String pointUuid,
    required String mapKind,
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.label = const Value.absent(),
    this.payload = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        mapId = Value(mapId),
        pointUuid = Value(pointUuid),
        mapKind = Value(mapKind);
  static Insertable<InstallationPoint> custom({
    Expression<String>? id,
    Expression<String>? mapId,
    Expression<String>? pointUuid,
    Expression<String>? mapKind,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? label,
    Expression<String>? payload,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mapId != null) 'map_id': mapId,
      if (pointUuid != null) 'point_uuid': pointUuid,
      if (mapKind != null) 'map_kind': mapKind,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (label != null) 'label': label,
      if (payload != null) 'payload': payload,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstallationPointsCompanion copyWith(
      {Value<String>? id,
      Value<String>? mapId,
      Value<String>? pointUuid,
      Value<String>? mapKind,
      Value<double?>? x,
      Value<double?>? y,
      Value<double?>? lat,
      Value<double?>? lng,
      Value<String>? label,
      Value<String>? payload,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return InstallationPointsCompanion(
      id: id ?? this.id,
      mapId: mapId ?? this.mapId,
      pointUuid: pointUuid ?? this.pointUuid,
      mapKind: mapKind ?? this.mapKind,
      x: x ?? this.x,
      y: y ?? this.y,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      label: label ?? this.label,
      payload: payload ?? this.payload,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mapId.present) {
      map['map_id'] = Variable<String>(mapId.value);
    }
    if (pointUuid.present) {
      map['point_uuid'] = Variable<String>(pointUuid.value);
    }
    if (mapKind.present) {
      map['map_kind'] = Variable<String>(mapKind.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (riadVersion.present) {
      map['riad_version'] = Variable<int>(riadVersion.value);
    }
    if (riadDeleted.present) {
      map['riad_deleted'] = Variable<bool>(riadDeleted.value);
    }
    if (riadDeletedAt.present) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstallationPointsCompanion(')
          ..write('id: $id, ')
          ..write('mapId: $mapId, ')
          ..write('pointUuid: $pointUuid, ')
          ..write('mapKind: $mapKind, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('label: $label, ')
          ..write('payload: $payload, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaAssetsTable extends MediaAssets
    with TableInfo<$MediaAssetsTable, MediaAsset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientUuidMeta =
      const VerificationMeta('clientUuid');
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
      'client_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentDoctypeMeta =
      const VerificationMeta('parentDoctype');
  @override
  late final GeneratedColumn<String> parentDoctype = GeneratedColumn<String>(
      'parent_doctype', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentNameMeta =
      const VerificationMeta('parentName');
  @override
  late final GeneratedColumn<String> parentName = GeneratedColumn<String>(
      'parent_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediaTypeMeta =
      const VerificationMeta('mediaType');
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
      'media_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
      'tag', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _aiAllowedMeta =
      const VerificationMeta('aiAllowed');
  @override
  late final GeneratedColumn<bool> aiAllowed = GeneratedColumn<bool>(
      'ai_allowed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ai_allowed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _driveIdMeta =
      const VerificationMeta('driveId');
  @override
  late final GeneratedColumn<String> driveId = GeneratedColumn<String>(
      'drive_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transcriptionStatusMeta =
      const VerificationMeta('transcriptionStatus');
  @override
  late final GeneratedColumn<String> transcriptionStatus =
      GeneratedColumn<String>('transcription_status', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('pending'));
  static const VerificationMeta _transcriptionMeta =
      const VerificationMeta('transcription');
  @override
  late final GeneratedColumn<String> transcription = GeneratedColumn<String>(
      'transcription', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _riadVersionMeta =
      const VerificationMeta('riadVersion');
  @override
  late final GeneratedColumn<int> riadVersion = GeneratedColumn<int>(
      'riad_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _riadDeletedMeta =
      const VerificationMeta('riadDeleted');
  @override
  late final GeneratedColumn<bool> riadDeleted = GeneratedColumn<bool>(
      'riad_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("riad_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _riadDeletedAtMeta =
      const VerificationMeta('riadDeletedAt');
  @override
  late final GeneratedColumn<DateTime> riadDeletedAt =
      GeneratedColumn<DateTime>('riad_deleted_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        clientUuid,
        parentDoctype,
        parentName,
        mediaType,
        tag,
        aiAllowed,
        localPath,
        driveId,
        transcriptionStatus,
        transcription,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_assets';
  @override
  VerificationContext validateIntegrity(Insertable<MediaAsset> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_uuid')) {
      context.handle(
          _clientUuidMeta,
          clientUuid.isAcceptableOrUnknown(
              data['client_uuid']!, _clientUuidMeta));
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('parent_doctype')) {
      context.handle(
          _parentDoctypeMeta,
          parentDoctype.isAcceptableOrUnknown(
              data['parent_doctype']!, _parentDoctypeMeta));
    } else if (isInserting) {
      context.missing(_parentDoctypeMeta);
    }
    if (data.containsKey('parent_name')) {
      context.handle(
          _parentNameMeta,
          parentName.isAcceptableOrUnknown(
              data['parent_name']!, _parentNameMeta));
    } else if (isInserting) {
      context.missing(_parentNameMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(_mediaTypeMeta,
          mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta));
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
          _tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
    }
    if (data.containsKey('ai_allowed')) {
      context.handle(_aiAllowedMeta,
          aiAllowed.isAcceptableOrUnknown(data['ai_allowed']!, _aiAllowedMeta));
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('drive_id')) {
      context.handle(_driveIdMeta,
          driveId.isAcceptableOrUnknown(data['drive_id']!, _driveIdMeta));
    }
    if (data.containsKey('transcription_status')) {
      context.handle(
          _transcriptionStatusMeta,
          transcriptionStatus.isAcceptableOrUnknown(
              data['transcription_status']!, _transcriptionStatusMeta));
    }
    if (data.containsKey('transcription')) {
      context.handle(
          _transcriptionMeta,
          transcription.isAcceptableOrUnknown(
              data['transcription']!, _transcriptionMeta));
    }
    if (data.containsKey('riad_version')) {
      context.handle(
          _riadVersionMeta,
          riadVersion.isAcceptableOrUnknown(
              data['riad_version']!, _riadVersionMeta));
    }
    if (data.containsKey('riad_deleted')) {
      context.handle(
          _riadDeletedMeta,
          riadDeleted.isAcceptableOrUnknown(
              data['riad_deleted']!, _riadDeletedMeta));
    }
    if (data.containsKey('riad_deleted_at')) {
      context.handle(
          _riadDeletedAtMeta,
          riadDeletedAt.isAcceptableOrUnknown(
              data['riad_deleted_at']!, _riadDeletedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaAsset(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      clientUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_uuid'])!,
      parentDoctype: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_doctype'])!,
      parentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_name'])!,
      mediaType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_type'])!,
      tag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag'])!,
      aiAllowed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ai_allowed'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      driveId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}drive_id']),
      transcriptionStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transcription_status'])!,
      transcription: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transcription']),
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MediaAssetsTable createAlias(String alias) {
    return $MediaAssetsTable(attachedDatabase, alias);
  }
}

class MediaAsset extends DataClass implements Insertable<MediaAsset> {
  final String id;
  final String clientUuid;
  final String parentDoctype;
  final String parentName;
  final String mediaType;
  final String tag;
  final bool aiAllowed;
  final String? localPath;
  final String? driveId;
  final String transcriptionStatus;
  final String? transcription;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final DateTime createdAt;
  const MediaAsset(
      {required this.id,
      required this.clientUuid,
      required this.parentDoctype,
      required this.parentName,
      required this.mediaType,
      required this.tag,
      required this.aiAllowed,
      this.localPath,
      this.driveId,
      required this.transcriptionStatus,
      this.transcription,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_uuid'] = Variable<String>(clientUuid);
    map['parent_doctype'] = Variable<String>(parentDoctype);
    map['parent_name'] = Variable<String>(parentName);
    map['media_type'] = Variable<String>(mediaType);
    map['tag'] = Variable<String>(tag);
    map['ai_allowed'] = Variable<bool>(aiAllowed);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || driveId != null) {
      map['drive_id'] = Variable<String>(driveId);
    }
    map['transcription_status'] = Variable<String>(transcriptionStatus);
    if (!nullToAbsent || transcription != null) {
      map['transcription'] = Variable<String>(transcription);
    }
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MediaAssetsCompanion toCompanion(bool nullToAbsent) {
    return MediaAssetsCompanion(
      id: Value(id),
      clientUuid: Value(clientUuid),
      parentDoctype: Value(parentDoctype),
      parentName: Value(parentName),
      mediaType: Value(mediaType),
      tag: Value(tag),
      aiAllowed: Value(aiAllowed),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      driveId: driveId == null && nullToAbsent
          ? const Value.absent()
          : Value(driveId),
      transcriptionStatus: Value(transcriptionStatus),
      transcription: transcription == null && nullToAbsent
          ? const Value.absent()
          : Value(transcription),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      createdAt: Value(createdAt),
    );
  }

  factory MediaAsset.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaAsset(
      id: serializer.fromJson<String>(json['id']),
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      parentDoctype: serializer.fromJson<String>(json['parentDoctype']),
      parentName: serializer.fromJson<String>(json['parentName']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      tag: serializer.fromJson<String>(json['tag']),
      aiAllowed: serializer.fromJson<bool>(json['aiAllowed']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      driveId: serializer.fromJson<String?>(json['driveId']),
      transcriptionStatus:
          serializer.fromJson<String>(json['transcriptionStatus']),
      transcription: serializer.fromJson<String?>(json['transcription']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientUuid': serializer.toJson<String>(clientUuid),
      'parentDoctype': serializer.toJson<String>(parentDoctype),
      'parentName': serializer.toJson<String>(parentName),
      'mediaType': serializer.toJson<String>(mediaType),
      'tag': serializer.toJson<String>(tag),
      'aiAllowed': serializer.toJson<bool>(aiAllowed),
      'localPath': serializer.toJson<String?>(localPath),
      'driveId': serializer.toJson<String?>(driveId),
      'transcriptionStatus': serializer.toJson<String>(transcriptionStatus),
      'transcription': serializer.toJson<String?>(transcription),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MediaAsset copyWith(
          {String? id,
          String? clientUuid,
          String? parentDoctype,
          String? parentName,
          String? mediaType,
          String? tag,
          bool? aiAllowed,
          Value<String?> localPath = const Value.absent(),
          Value<String?> driveId = const Value.absent(),
          String? transcriptionStatus,
          Value<String?> transcription = const Value.absent(),
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          DateTime? createdAt}) =>
      MediaAsset(
        id: id ?? this.id,
        clientUuid: clientUuid ?? this.clientUuid,
        parentDoctype: parentDoctype ?? this.parentDoctype,
        parentName: parentName ?? this.parentName,
        mediaType: mediaType ?? this.mediaType,
        tag: tag ?? this.tag,
        aiAllowed: aiAllowed ?? this.aiAllowed,
        localPath: localPath.present ? localPath.value : this.localPath,
        driveId: driveId.present ? driveId.value : this.driveId,
        transcriptionStatus: transcriptionStatus ?? this.transcriptionStatus,
        transcription:
            transcription.present ? transcription.value : this.transcription,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  MediaAsset copyWithCompanion(MediaAssetsCompanion data) {
    return MediaAsset(
      id: data.id.present ? data.id.value : this.id,
      clientUuid:
          data.clientUuid.present ? data.clientUuid.value : this.clientUuid,
      parentDoctype: data.parentDoctype.present
          ? data.parentDoctype.value
          : this.parentDoctype,
      parentName:
          data.parentName.present ? data.parentName.value : this.parentName,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      tag: data.tag.present ? data.tag.value : this.tag,
      aiAllowed: data.aiAllowed.present ? data.aiAllowed.value : this.aiAllowed,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      driveId: data.driveId.present ? data.driveId.value : this.driveId,
      transcriptionStatus: data.transcriptionStatus.present
          ? data.transcriptionStatus.value
          : this.transcriptionStatus,
      transcription: data.transcription.present
          ? data.transcription.value
          : this.transcription,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaAsset(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('parentDoctype: $parentDoctype, ')
          ..write('parentName: $parentName, ')
          ..write('mediaType: $mediaType, ')
          ..write('tag: $tag, ')
          ..write('aiAllowed: $aiAllowed, ')
          ..write('localPath: $localPath, ')
          ..write('driveId: $driveId, ')
          ..write('transcriptionStatus: $transcriptionStatus, ')
          ..write('transcription: $transcription, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      clientUuid,
      parentDoctype,
      parentName,
      mediaType,
      tag,
      aiAllowed,
      localPath,
      driveId,
      transcriptionStatus,
      transcription,
      riadVersion,
      riadDeleted,
      riadDeletedAt,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaAsset &&
          other.id == this.id &&
          other.clientUuid == this.clientUuid &&
          other.parentDoctype == this.parentDoctype &&
          other.parentName == this.parentName &&
          other.mediaType == this.mediaType &&
          other.tag == this.tag &&
          other.aiAllowed == this.aiAllowed &&
          other.localPath == this.localPath &&
          other.driveId == this.driveId &&
          other.transcriptionStatus == this.transcriptionStatus &&
          other.transcription == this.transcription &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.createdAt == this.createdAt);
}

class MediaAssetsCompanion extends UpdateCompanion<MediaAsset> {
  final Value<String> id;
  final Value<String> clientUuid;
  final Value<String> parentDoctype;
  final Value<String> parentName;
  final Value<String> mediaType;
  final Value<String> tag;
  final Value<bool> aiAllowed;
  final Value<String?> localPath;
  final Value<String?> driveId;
  final Value<String> transcriptionStatus;
  final Value<String?> transcription;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MediaAssetsCompanion({
    this.id = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.parentDoctype = const Value.absent(),
    this.parentName = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.tag = const Value.absent(),
    this.aiAllowed = const Value.absent(),
    this.localPath = const Value.absent(),
    this.driveId = const Value.absent(),
    this.transcriptionStatus = const Value.absent(),
    this.transcription = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaAssetsCompanion.insert({
    required String id,
    required String clientUuid,
    required String parentDoctype,
    required String parentName,
    required String mediaType,
    this.tag = const Value.absent(),
    this.aiAllowed = const Value.absent(),
    this.localPath = const Value.absent(),
    this.driveId = const Value.absent(),
    this.transcriptionStatus = const Value.absent(),
    this.transcription = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        clientUuid = Value(clientUuid),
        parentDoctype = Value(parentDoctype),
        parentName = Value(parentName),
        mediaType = Value(mediaType);
  static Insertable<MediaAsset> custom({
    Expression<String>? id,
    Expression<String>? clientUuid,
    Expression<String>? parentDoctype,
    Expression<String>? parentName,
    Expression<String>? mediaType,
    Expression<String>? tag,
    Expression<bool>? aiAllowed,
    Expression<String>? localPath,
    Expression<String>? driveId,
    Expression<String>? transcriptionStatus,
    Expression<String>? transcription,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (parentDoctype != null) 'parent_doctype': parentDoctype,
      if (parentName != null) 'parent_name': parentName,
      if (mediaType != null) 'media_type': mediaType,
      if (tag != null) 'tag': tag,
      if (aiAllowed != null) 'ai_allowed': aiAllowed,
      if (localPath != null) 'local_path': localPath,
      if (driveId != null) 'drive_id': driveId,
      if (transcriptionStatus != null)
        'transcription_status': transcriptionStatus,
      if (transcription != null) 'transcription': transcription,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaAssetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? clientUuid,
      Value<String>? parentDoctype,
      Value<String>? parentName,
      Value<String>? mediaType,
      Value<String>? tag,
      Value<bool>? aiAllowed,
      Value<String?>? localPath,
      Value<String?>? driveId,
      Value<String>? transcriptionStatus,
      Value<String?>? transcription,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return MediaAssetsCompanion(
      id: id ?? this.id,
      clientUuid: clientUuid ?? this.clientUuid,
      parentDoctype: parentDoctype ?? this.parentDoctype,
      parentName: parentName ?? this.parentName,
      mediaType: mediaType ?? this.mediaType,
      tag: tag ?? this.tag,
      aiAllowed: aiAllowed ?? this.aiAllowed,
      localPath: localPath ?? this.localPath,
      driveId: driveId ?? this.driveId,
      transcriptionStatus: transcriptionStatus ?? this.transcriptionStatus,
      transcription: transcription ?? this.transcription,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (parentDoctype.present) {
      map['parent_doctype'] = Variable<String>(parentDoctype.value);
    }
    if (parentName.present) {
      map['parent_name'] = Variable<String>(parentName.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (aiAllowed.present) {
      map['ai_allowed'] = Variable<bool>(aiAllowed.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (driveId.present) {
      map['drive_id'] = Variable<String>(driveId.value);
    }
    if (transcriptionStatus.present) {
      map['transcription_status'] = Variable<String>(transcriptionStatus.value);
    }
    if (transcription.present) {
      map['transcription'] = Variable<String>(transcription.value);
    }
    if (riadVersion.present) {
      map['riad_version'] = Variable<int>(riadVersion.value);
    }
    if (riadDeleted.present) {
      map['riad_deleted'] = Variable<bool>(riadDeleted.value);
    }
    if (riadDeletedAt.present) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaAssetsCompanion(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('parentDoctype: $parentDoctype, ')
          ..write('parentName: $parentName, ')
          ..write('mediaType: $mediaType, ')
          ..write('tag: $tag, ')
          ..write('aiAllowed: $aiAllowed, ')
          ..write('localPath: $localPath, ')
          ..write('driveId: $driveId, ')
          ..write('transcriptionStatus: $transcriptionStatus, ')
          ..write('transcription: $transcription, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingMediaUploadsTable extends PendingMediaUploads
    with TableInfo<$PendingMediaUploadsTable, PendingMediaUpload> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingMediaUploadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _clientUuidMeta =
      const VerificationMeta('clientUuid');
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
      'client_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediaTypeMeta =
      const VerificationMeta('mediaType');
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
      'media_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentDoctypeMeta =
      const VerificationMeta('parentDoctype');
  @override
  late final GeneratedColumn<String> parentDoctype = GeneratedColumn<String>(
      'parent_doctype', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentNameMeta =
      const VerificationMeta('parentName');
  @override
  late final GeneratedColumn<String> parentName = GeneratedColumn<String>(
      'parent_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
      'tag', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        clientUuid,
        localPath,
        mediaType,
        parentDoctype,
        parentName,
        tag,
        status,
        attempts,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_media_uploads';
  @override
  VerificationContext validateIntegrity(Insertable<PendingMediaUpload> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_uuid')) {
      context.handle(
          _clientUuidMeta,
          clientUuid.isAcceptableOrUnknown(
              data['client_uuid']!, _clientUuidMeta));
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(_mediaTypeMeta,
          mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta));
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('parent_doctype')) {
      context.handle(
          _parentDoctypeMeta,
          parentDoctype.isAcceptableOrUnknown(
              data['parent_doctype']!, _parentDoctypeMeta));
    } else if (isInserting) {
      context.missing(_parentDoctypeMeta);
    }
    if (data.containsKey('parent_name')) {
      context.handle(
          _parentNameMeta,
          parentName.isAcceptableOrUnknown(
              data['parent_name']!, _parentNameMeta));
    } else if (isInserting) {
      context.missing(_parentNameMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
          _tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingMediaUpload map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingMediaUpload(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      clientUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_uuid'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      mediaType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_type'])!,
      parentDoctype: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_doctype'])!,
      parentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_name'])!,
      tag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PendingMediaUploadsTable createAlias(String alias) {
    return $PendingMediaUploadsTable(attachedDatabase, alias);
  }
}

class PendingMediaUpload extends DataClass
    implements Insertable<PendingMediaUpload> {
  final int id;
  final String clientUuid;
  final String localPath;
  final String mediaType;
  final String parentDoctype;
  final String parentName;
  final String tag;
  final String status;
  final int attempts;
  final DateTime createdAt;
  const PendingMediaUpload(
      {required this.id,
      required this.clientUuid,
      required this.localPath,
      required this.mediaType,
      required this.parentDoctype,
      required this.parentName,
      required this.tag,
      required this.status,
      required this.attempts,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_uuid'] = Variable<String>(clientUuid);
    map['local_path'] = Variable<String>(localPath);
    map['media_type'] = Variable<String>(mediaType);
    map['parent_doctype'] = Variable<String>(parentDoctype);
    map['parent_name'] = Variable<String>(parentName);
    map['tag'] = Variable<String>(tag);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingMediaUploadsCompanion toCompanion(bool nullToAbsent) {
    return PendingMediaUploadsCompanion(
      id: Value(id),
      clientUuid: Value(clientUuid),
      localPath: Value(localPath),
      mediaType: Value(mediaType),
      parentDoctype: Value(parentDoctype),
      parentName: Value(parentName),
      tag: Value(tag),
      status: Value(status),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
    );
  }

  factory PendingMediaUpload.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingMediaUpload(
      id: serializer.fromJson<int>(json['id']),
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      localPath: serializer.fromJson<String>(json['localPath']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      parentDoctype: serializer.fromJson<String>(json['parentDoctype']),
      parentName: serializer.fromJson<String>(json['parentName']),
      tag: serializer.fromJson<String>(json['tag']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientUuid': serializer.toJson<String>(clientUuid),
      'localPath': serializer.toJson<String>(localPath),
      'mediaType': serializer.toJson<String>(mediaType),
      'parentDoctype': serializer.toJson<String>(parentDoctype),
      'parentName': serializer.toJson<String>(parentName),
      'tag': serializer.toJson<String>(tag),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingMediaUpload copyWith(
          {int? id,
          String? clientUuid,
          String? localPath,
          String? mediaType,
          String? parentDoctype,
          String? parentName,
          String? tag,
          String? status,
          int? attempts,
          DateTime? createdAt}) =>
      PendingMediaUpload(
        id: id ?? this.id,
        clientUuid: clientUuid ?? this.clientUuid,
        localPath: localPath ?? this.localPath,
        mediaType: mediaType ?? this.mediaType,
        parentDoctype: parentDoctype ?? this.parentDoctype,
        parentName: parentName ?? this.parentName,
        tag: tag ?? this.tag,
        status: status ?? this.status,
        attempts: attempts ?? this.attempts,
        createdAt: createdAt ?? this.createdAt,
      );
  PendingMediaUpload copyWithCompanion(PendingMediaUploadsCompanion data) {
    return PendingMediaUpload(
      id: data.id.present ? data.id.value : this.id,
      clientUuid:
          data.clientUuid.present ? data.clientUuid.value : this.clientUuid,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      parentDoctype: data.parentDoctype.present
          ? data.parentDoctype.value
          : this.parentDoctype,
      parentName:
          data.parentName.present ? data.parentName.value : this.parentName,
      tag: data.tag.present ? data.tag.value : this.tag,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingMediaUpload(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('localPath: $localPath, ')
          ..write('mediaType: $mediaType, ')
          ..write('parentDoctype: $parentDoctype, ')
          ..write('parentName: $parentName, ')
          ..write('tag: $tag, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, clientUuid, localPath, mediaType,
      parentDoctype, parentName, tag, status, attempts, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingMediaUpload &&
          other.id == this.id &&
          other.clientUuid == this.clientUuid &&
          other.localPath == this.localPath &&
          other.mediaType == this.mediaType &&
          other.parentDoctype == this.parentDoctype &&
          other.parentName == this.parentName &&
          other.tag == this.tag &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt);
}

class PendingMediaUploadsCompanion extends UpdateCompanion<PendingMediaUpload> {
  final Value<int> id;
  final Value<String> clientUuid;
  final Value<String> localPath;
  final Value<String> mediaType;
  final Value<String> parentDoctype;
  final Value<String> parentName;
  final Value<String> tag;
  final Value<String> status;
  final Value<int> attempts;
  final Value<DateTime> createdAt;
  const PendingMediaUploadsCompanion({
    this.id = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.localPath = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.parentDoctype = const Value.absent(),
    this.parentName = const Value.absent(),
    this.tag = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingMediaUploadsCompanion.insert({
    this.id = const Value.absent(),
    required String clientUuid,
    required String localPath,
    required String mediaType,
    required String parentDoctype,
    required String parentName,
    this.tag = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : clientUuid = Value(clientUuid),
        localPath = Value(localPath),
        mediaType = Value(mediaType),
        parentDoctype = Value(parentDoctype),
        parentName = Value(parentName);
  static Insertable<PendingMediaUpload> custom({
    Expression<int>? id,
    Expression<String>? clientUuid,
    Expression<String>? localPath,
    Expression<String>? mediaType,
    Expression<String>? parentDoctype,
    Expression<String>? parentName,
    Expression<String>? tag,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (localPath != null) 'local_path': localPath,
      if (mediaType != null) 'media_type': mediaType,
      if (parentDoctype != null) 'parent_doctype': parentDoctype,
      if (parentName != null) 'parent_name': parentName,
      if (tag != null) 'tag': tag,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingMediaUploadsCompanion copyWith(
      {Value<int>? id,
      Value<String>? clientUuid,
      Value<String>? localPath,
      Value<String>? mediaType,
      Value<String>? parentDoctype,
      Value<String>? parentName,
      Value<String>? tag,
      Value<String>? status,
      Value<int>? attempts,
      Value<DateTime>? createdAt}) {
    return PendingMediaUploadsCompanion(
      id: id ?? this.id,
      clientUuid: clientUuid ?? this.clientUuid,
      localPath: localPath ?? this.localPath,
      mediaType: mediaType ?? this.mediaType,
      parentDoctype: parentDoctype ?? this.parentDoctype,
      parentName: parentName ?? this.parentName,
      tag: tag ?? this.tag,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (parentDoctype.present) {
      map['parent_doctype'] = Variable<String>(parentDoctype.value);
    }
    if (parentName.present) {
      map['parent_name'] = Variable<String>(parentName.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingMediaUploadsCompanion(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('localPath: $localPath, ')
          ..write('mediaType: $mediaType, ')
          ..write('parentDoctype: $parentDoctype, ')
          ..write('parentName: $parentName, ')
          ..write('tag: $tag, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RemoteInspectionsTable extends RemoteInspections
    with TableInfo<$RemoteInspectionsTable, RemoteInspection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteInspectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _objectIdMeta =
      const VerificationMeta('objectId');
  @override
  late final GeneratedColumn<String> objectId = GeneratedColumn<String>(
      'object_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _engineerIdMeta =
      const VerificationMeta('engineerId');
  @override
  late final GeneratedColumn<String> engineerId = GeneratedColumn<String>(
      'engineer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _transcriptionStatusMeta =
      const VerificationMeta('transcriptionStatus');
  @override
  late final GeneratedColumn<String> transcriptionStatus =
      GeneratedColumn<String>('transcription_status', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('pending'));
  static const VerificationMeta _riadVersionMeta =
      const VerificationMeta('riadVersion');
  @override
  late final GeneratedColumn<int> riadVersion = GeneratedColumn<int>(
      'riad_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _riadDeletedMeta =
      const VerificationMeta('riadDeleted');
  @override
  late final GeneratedColumn<bool> riadDeleted = GeneratedColumn<bool>(
      'riad_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("riad_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _riadDeletedAtMeta =
      const VerificationMeta('riadDeletedAt');
  @override
  late final GeneratedColumn<DateTime> riadDeletedAt =
      GeneratedColumn<DateTime>('riad_deleted_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        objectId,
        status,
        engineerId,
        transcriptionStatus,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        payload,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_inspections';
  @override
  VerificationContext validateIntegrity(Insertable<RemoteInspection> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('object_id')) {
      context.handle(_objectIdMeta,
          objectId.isAcceptableOrUnknown(data['object_id']!, _objectIdMeta));
    } else if (isInserting) {
      context.missing(_objectIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('engineer_id')) {
      context.handle(
          _engineerIdMeta,
          engineerId.isAcceptableOrUnknown(
              data['engineer_id']!, _engineerIdMeta));
    } else if (isInserting) {
      context.missing(_engineerIdMeta);
    }
    if (data.containsKey('transcription_status')) {
      context.handle(
          _transcriptionStatusMeta,
          transcriptionStatus.isAcceptableOrUnknown(
              data['transcription_status']!, _transcriptionStatusMeta));
    }
    if (data.containsKey('riad_version')) {
      context.handle(
          _riadVersionMeta,
          riadVersion.isAcceptableOrUnknown(
              data['riad_version']!, _riadVersionMeta));
    }
    if (data.containsKey('riad_deleted')) {
      context.handle(
          _riadDeletedMeta,
          riadDeleted.isAcceptableOrUnknown(
              data['riad_deleted']!, _riadDeletedMeta));
    }
    if (data.containsKey('riad_deleted_at')) {
      context.handle(
          _riadDeletedAtMeta,
          riadDeletedAt.isAcceptableOrUnknown(
              data['riad_deleted_at']!, _riadDeletedAtMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemoteInspection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteInspection(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      objectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}object_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      engineerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}engineer_id'])!,
      transcriptionStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transcription_status'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $RemoteInspectionsTable createAlias(String alias) {
    return $RemoteInspectionsTable(attachedDatabase, alias);
  }
}

class RemoteInspection extends DataClass
    implements Insertable<RemoteInspection> {
  final String id;
  final String objectId;
  final String status;
  final String engineerId;
  final String transcriptionStatus;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String payload;
  final DateTime updatedAt;
  const RemoteInspection(
      {required this.id,
      required this.objectId,
      required this.status,
      required this.engineerId,
      required this.transcriptionStatus,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      required this.payload,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['object_id'] = Variable<String>(objectId);
    map['status'] = Variable<String>(status);
    map['engineer_id'] = Variable<String>(engineerId);
    map['transcription_status'] = Variable<String>(transcriptionStatus);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RemoteInspectionsCompanion toCompanion(bool nullToAbsent) {
    return RemoteInspectionsCompanion(
      id: Value(id),
      objectId: Value(objectId),
      status: Value(status),
      engineerId: Value(engineerId),
      transcriptionStatus: Value(transcriptionStatus),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory RemoteInspection.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteInspection(
      id: serializer.fromJson<String>(json['id']),
      objectId: serializer.fromJson<String>(json['objectId']),
      status: serializer.fromJson<String>(json['status']),
      engineerId: serializer.fromJson<String>(json['engineerId']),
      transcriptionStatus:
          serializer.fromJson<String>(json['transcriptionStatus']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'objectId': serializer.toJson<String>(objectId),
      'status': serializer.toJson<String>(status),
      'engineerId': serializer.toJson<String>(engineerId),
      'transcriptionStatus': serializer.toJson<String>(transcriptionStatus),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RemoteInspection copyWith(
          {String? id,
          String? objectId,
          String? status,
          String? engineerId,
          String? transcriptionStatus,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          String? payload,
          DateTime? updatedAt}) =>
      RemoteInspection(
        id: id ?? this.id,
        objectId: objectId ?? this.objectId,
        status: status ?? this.status,
        engineerId: engineerId ?? this.engineerId,
        transcriptionStatus: transcriptionStatus ?? this.transcriptionStatus,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        payload: payload ?? this.payload,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  RemoteInspection copyWithCompanion(RemoteInspectionsCompanion data) {
    return RemoteInspection(
      id: data.id.present ? data.id.value : this.id,
      objectId: data.objectId.present ? data.objectId.value : this.objectId,
      status: data.status.present ? data.status.value : this.status,
      engineerId:
          data.engineerId.present ? data.engineerId.value : this.engineerId,
      transcriptionStatus: data.transcriptionStatus.present
          ? data.transcriptionStatus.value
          : this.transcriptionStatus,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteInspection(')
          ..write('id: $id, ')
          ..write('objectId: $objectId, ')
          ..write('status: $status, ')
          ..write('engineerId: $engineerId, ')
          ..write('transcriptionStatus: $transcriptionStatus, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      objectId,
      status,
      engineerId,
      transcriptionStatus,
      riadVersion,
      riadDeleted,
      riadDeletedAt,
      payload,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteInspection &&
          other.id == this.id &&
          other.objectId == this.objectId &&
          other.status == this.status &&
          other.engineerId == this.engineerId &&
          other.transcriptionStatus == this.transcriptionStatus &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class RemoteInspectionsCompanion extends UpdateCompanion<RemoteInspection> {
  final Value<String> id;
  final Value<String> objectId;
  final Value<String> status;
  final Value<String> engineerId;
  final Value<String> transcriptionStatus;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RemoteInspectionsCompanion({
    this.id = const Value.absent(),
    this.objectId = const Value.absent(),
    this.status = const Value.absent(),
    this.engineerId = const Value.absent(),
    this.transcriptionStatus = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemoteInspectionsCompanion.insert({
    required String id,
    required String objectId,
    this.status = const Value.absent(),
    required String engineerId,
    this.transcriptionStatus = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        objectId = Value(objectId),
        engineerId = Value(engineerId);
  static Insertable<RemoteInspection> custom({
    Expression<String>? id,
    Expression<String>? objectId,
    Expression<String>? status,
    Expression<String>? engineerId,
    Expression<String>? transcriptionStatus,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (objectId != null) 'object_id': objectId,
      if (status != null) 'status': status,
      if (engineerId != null) 'engineer_id': engineerId,
      if (transcriptionStatus != null)
        'transcription_status': transcriptionStatus,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemoteInspectionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? objectId,
      Value<String>? status,
      Value<String>? engineerId,
      Value<String>? transcriptionStatus,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String>? payload,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return RemoteInspectionsCompanion(
      id: id ?? this.id,
      objectId: objectId ?? this.objectId,
      status: status ?? this.status,
      engineerId: engineerId ?? this.engineerId,
      transcriptionStatus: transcriptionStatus ?? this.transcriptionStatus,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (objectId.present) {
      map['object_id'] = Variable<String>(objectId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (engineerId.present) {
      map['engineer_id'] = Variable<String>(engineerId.value);
    }
    if (transcriptionStatus.present) {
      map['transcription_status'] = Variable<String>(transcriptionStatus.value);
    }
    if (riadVersion.present) {
      map['riad_version'] = Variable<int>(riadVersion.value);
    }
    if (riadDeleted.present) {
      map['riad_deleted'] = Variable<bool>(riadDeleted.value);
    }
    if (riadDeletedAt.present) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteInspectionsCompanion(')
          ..write('id: $id, ')
          ..write('objectId: $objectId, ')
          ..write('status: $status, ')
          ..write('engineerId: $engineerId, ')
          ..write('transcriptionStatus: $transcriptionStatus, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ServiceRequestsTable extends ServiceRequests
    with TableInfo<$ServiceRequestsTable, ServiceRequest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServiceRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _objectIdMeta =
      const VerificationMeta('objectId');
  @override
  late final GeneratedColumn<String> objectId = GeneratedColumn<String>(
      'object_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requestTypeMeta =
      const VerificationMeta('requestType');
  @override
  late final GeneratedColumn<String> requestType = GeneratedColumn<String>(
      'request_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('новий'));
  static const VerificationMeta _assignedToMeta =
      const VerificationMeta('assignedTo');
  @override
  late final GeneratedColumn<String> assignedTo = GeneratedColumn<String>(
      'assigned_to', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _riadVersionMeta =
      const VerificationMeta('riadVersion');
  @override
  late final GeneratedColumn<int> riadVersion = GeneratedColumn<int>(
      'riad_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _riadDeletedMeta =
      const VerificationMeta('riadDeleted');
  @override
  late final GeneratedColumn<bool> riadDeleted = GeneratedColumn<bool>(
      'riad_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("riad_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _riadDeletedAtMeta =
      const VerificationMeta('riadDeletedAt');
  @override
  late final GeneratedColumn<DateTime> riadDeletedAt =
      GeneratedColumn<DateTime>('riad_deleted_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        objectId,
        requestType,
        status,
        assignedTo,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        payload,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'service_requests';
  @override
  VerificationContext validateIntegrity(Insertable<ServiceRequest> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('object_id')) {
      context.handle(_objectIdMeta,
          objectId.isAcceptableOrUnknown(data['object_id']!, _objectIdMeta));
    } else if (isInserting) {
      context.missing(_objectIdMeta);
    }
    if (data.containsKey('request_type')) {
      context.handle(
          _requestTypeMeta,
          requestType.isAcceptableOrUnknown(
              data['request_type']!, _requestTypeMeta));
    } else if (isInserting) {
      context.missing(_requestTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('assigned_to')) {
      context.handle(
          _assignedToMeta,
          assignedTo.isAcceptableOrUnknown(
              data['assigned_to']!, _assignedToMeta));
    }
    if (data.containsKey('riad_version')) {
      context.handle(
          _riadVersionMeta,
          riadVersion.isAcceptableOrUnknown(
              data['riad_version']!, _riadVersionMeta));
    }
    if (data.containsKey('riad_deleted')) {
      context.handle(
          _riadDeletedMeta,
          riadDeleted.isAcceptableOrUnknown(
              data['riad_deleted']!, _riadDeletedMeta));
    }
    if (data.containsKey('riad_deleted_at')) {
      context.handle(
          _riadDeletedAtMeta,
          riadDeletedAt.isAcceptableOrUnknown(
              data['riad_deleted_at']!, _riadDeletedAtMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServiceRequest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServiceRequest(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      objectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}object_id'])!,
      requestType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_type'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      assignedTo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}assigned_to']),
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ServiceRequestsTable createAlias(String alias) {
    return $ServiceRequestsTable(attachedDatabase, alias);
  }
}

class ServiceRequest extends DataClass implements Insertable<ServiceRequest> {
  final String id;
  final String objectId;
  final String requestType;
  final String status;
  final String? assignedTo;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ServiceRequest(
      {required this.id,
      required this.objectId,
      required this.requestType,
      required this.status,
      this.assignedTo,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      required this.payload,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['object_id'] = Variable<String>(objectId);
    map['request_type'] = Variable<String>(requestType);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || assignedTo != null) {
      map['assigned_to'] = Variable<String>(assignedTo);
    }
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ServiceRequestsCompanion toCompanion(bool nullToAbsent) {
    return ServiceRequestsCompanion(
      id: Value(id),
      objectId: Value(objectId),
      requestType: Value(requestType),
      status: Value(status),
      assignedTo: assignedTo == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedTo),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ServiceRequest.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServiceRequest(
      id: serializer.fromJson<String>(json['id']),
      objectId: serializer.fromJson<String>(json['objectId']),
      requestType: serializer.fromJson<String>(json['requestType']),
      status: serializer.fromJson<String>(json['status']),
      assignedTo: serializer.fromJson<String?>(json['assignedTo']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'objectId': serializer.toJson<String>(objectId),
      'requestType': serializer.toJson<String>(requestType),
      'status': serializer.toJson<String>(status),
      'assignedTo': serializer.toJson<String?>(assignedTo),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ServiceRequest copyWith(
          {String? id,
          String? objectId,
          String? requestType,
          String? status,
          Value<String?> assignedTo = const Value.absent(),
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          String? payload,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ServiceRequest(
        id: id ?? this.id,
        objectId: objectId ?? this.objectId,
        requestType: requestType ?? this.requestType,
        status: status ?? this.status,
        assignedTo: assignedTo.present ? assignedTo.value : this.assignedTo,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ServiceRequest copyWithCompanion(ServiceRequestsCompanion data) {
    return ServiceRequest(
      id: data.id.present ? data.id.value : this.id,
      objectId: data.objectId.present ? data.objectId.value : this.objectId,
      requestType:
          data.requestType.present ? data.requestType.value : this.requestType,
      status: data.status.present ? data.status.value : this.status,
      assignedTo:
          data.assignedTo.present ? data.assignedTo.value : this.assignedTo,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServiceRequest(')
          ..write('id: $id, ')
          ..write('objectId: $objectId, ')
          ..write('requestType: $requestType, ')
          ..write('status: $status, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, objectId, requestType, status, assignedTo,
      riadVersion, riadDeleted, riadDeletedAt, payload, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServiceRequest &&
          other.id == this.id &&
          other.objectId == this.objectId &&
          other.requestType == this.requestType &&
          other.status == this.status &&
          other.assignedTo == this.assignedTo &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ServiceRequestsCompanion extends UpdateCompanion<ServiceRequest> {
  final Value<String> id;
  final Value<String> objectId;
  final Value<String> requestType;
  final Value<String> status;
  final Value<String?> assignedTo;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ServiceRequestsCompanion({
    this.id = const Value.absent(),
    this.objectId = const Value.absent(),
    this.requestType = const Value.absent(),
    this.status = const Value.absent(),
    this.assignedTo = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServiceRequestsCompanion.insert({
    required String id,
    required String objectId,
    required String requestType,
    this.status = const Value.absent(),
    this.assignedTo = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        objectId = Value(objectId),
        requestType = Value(requestType);
  static Insertable<ServiceRequest> custom({
    Expression<String>? id,
    Expression<String>? objectId,
    Expression<String>? requestType,
    Expression<String>? status,
    Expression<String>? assignedTo,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (objectId != null) 'object_id': objectId,
      if (requestType != null) 'request_type': requestType,
      if (status != null) 'status': status,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServiceRequestsCompanion copyWith(
      {Value<String>? id,
      Value<String>? objectId,
      Value<String>? requestType,
      Value<String>? status,
      Value<String?>? assignedTo,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String>? payload,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ServiceRequestsCompanion(
      id: id ?? this.id,
      objectId: objectId ?? this.objectId,
      requestType: requestType ?? this.requestType,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (objectId.present) {
      map['object_id'] = Variable<String>(objectId.value);
    }
    if (requestType.present) {
      map['request_type'] = Variable<String>(requestType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (assignedTo.present) {
      map['assigned_to'] = Variable<String>(assignedTo.value);
    }
    if (riadVersion.present) {
      map['riad_version'] = Variable<int>(riadVersion.value);
    }
    if (riadDeleted.present) {
      map['riad_deleted'] = Variable<bool>(riadDeleted.value);
    }
    if (riadDeletedAt.present) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServiceRequestsCompanion(')
          ..write('id: $id, ')
          ..write('objectId: $objectId, ')
          ..write('requestType: $requestType, ')
          ..write('status: $status, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _docTypeMeta =
      const VerificationMeta('docType');
  @override
  late final GeneratedColumn<String> docType = GeneratedColumn<String>(
      'doc_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        docType,
        name,
        operation,
        payload,
        status,
        attempts,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('doc_type')) {
      context.handle(_docTypeMeta,
          docType.isAcceptableOrUnknown(data['doc_type']!, _docTypeMeta));
    } else if (isInserting) {
      context.missing(_docTypeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      docType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doc_type'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String docType;
  final String name;
  final String operation;
  final String payload;
  final String status;
  final int attempts;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncQueueData(
      {required this.id,
      required this.docType,
      required this.name,
      required this.operation,
      required this.payload,
      required this.status,
      required this.attempts,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['doc_type'] = Variable<String>(docType);
    map['name'] = Variable<String>(name);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      docType: Value(docType),
      name: Value(name),
      operation: Value(operation),
      payload: Value(payload),
      status: Value(status),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      docType: serializer.fromJson<String>(json['docType']),
      name: serializer.fromJson<String>(json['name']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'docType': serializer.toJson<String>(docType),
      'name': serializer.toJson<String>(name),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncQueueData copyWith(
          {int? id,
          String? docType,
          String? name,
          String? operation,
          String? payload,
          String? status,
          int? attempts,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SyncQueueData(
        id: id ?? this.id,
        docType: docType ?? this.docType,
        name: name ?? this.name,
        operation: operation ?? this.operation,
        payload: payload ?? this.payload,
        status: status ?? this.status,
        attempts: attempts ?? this.attempts,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      docType: data.docType.present ? data.docType.value : this.docType,
      name: data.name.present ? data.name.value : this.name,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('docType: $docType, ')
          ..write('name: $name, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, docType, name, operation, payload, status,
      attempts, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.docType == this.docType &&
          other.name == this.name &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> docType;
  final Value<String> name;
  final Value<String> operation;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> attempts;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.docType = const Value.absent(),
    this.name = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String docType,
    required String name,
    required String operation,
    required String payload,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : docType = Value(docType),
        name = Value(name),
        operation = Value(operation),
        payload = Value(payload);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? docType,
    Expression<String>? name,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (docType != null) 'doc_type': docType,
      if (name != null) 'name': name,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? docType,
      Value<String>? name,
      Value<String>? operation,
      Value<String>? payload,
      Value<String>? status,
      Value<int>? attempts,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      docType: docType ?? this.docType,
      name: name ?? this.name,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (docType.present) {
      map['doc_type'] = Variable<String>(docType.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('docType: $docType, ')
          ..write('name: $name, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncConflictsTable extends SyncConflicts
    with TableInfo<$SyncConflictsTable, SyncConflict> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _docTypeMeta =
      const VerificationMeta('docType');
  @override
  late final GeneratedColumn<String> docType = GeneratedColumn<String>(
      'doc_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverPayloadMeta =
      const VerificationMeta('serverPayload');
  @override
  late final GeneratedColumn<String> serverPayload = GeneratedColumn<String>(
      'server_payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientPayloadMeta =
      const VerificationMeta('clientPayload');
  @override
  late final GeneratedColumn<String> clientPayload = GeneratedColumn<String>(
      'client_payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, docType, name, serverPayload, clientPayload, status, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_conflicts';
  @override
  VerificationContext validateIntegrity(Insertable<SyncConflict> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('doc_type')) {
      context.handle(_docTypeMeta,
          docType.isAcceptableOrUnknown(data['doc_type']!, _docTypeMeta));
    } else if (isInserting) {
      context.missing(_docTypeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('server_payload')) {
      context.handle(
          _serverPayloadMeta,
          serverPayload.isAcceptableOrUnknown(
              data['server_payload']!, _serverPayloadMeta));
    } else if (isInserting) {
      context.missing(_serverPayloadMeta);
    }
    if (data.containsKey('client_payload')) {
      context.handle(
          _clientPayloadMeta,
          clientPayload.isAcceptableOrUnknown(
              data['client_payload']!, _clientPayloadMeta));
    } else if (isInserting) {
      context.missing(_clientPayloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncConflict map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConflict(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      docType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doc_type'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      serverPayload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_payload'])!,
      clientPayload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_payload'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncConflictsTable createAlias(String alias) {
    return $SyncConflictsTable(attachedDatabase, alias);
  }
}

class SyncConflict extends DataClass implements Insertable<SyncConflict> {
  final String id;
  final String docType;
  final String name;
  final String serverPayload;
  final String clientPayload;
  final String status;
  final DateTime createdAt;
  const SyncConflict(
      {required this.id,
      required this.docType,
      required this.name,
      required this.serverPayload,
      required this.clientPayload,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['doc_type'] = Variable<String>(docType);
    map['name'] = Variable<String>(name);
    map['server_payload'] = Variable<String>(serverPayload);
    map['client_payload'] = Variable<String>(clientPayload);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncConflictsCompanion toCompanion(bool nullToAbsent) {
    return SyncConflictsCompanion(
      id: Value(id),
      docType: Value(docType),
      name: Value(name),
      serverPayload: Value(serverPayload),
      clientPayload: Value(clientPayload),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory SyncConflict.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConflict(
      id: serializer.fromJson<String>(json['id']),
      docType: serializer.fromJson<String>(json['docType']),
      name: serializer.fromJson<String>(json['name']),
      serverPayload: serializer.fromJson<String>(json['serverPayload']),
      clientPayload: serializer.fromJson<String>(json['clientPayload']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'docType': serializer.toJson<String>(docType),
      'name': serializer.toJson<String>(name),
      'serverPayload': serializer.toJson<String>(serverPayload),
      'clientPayload': serializer.toJson<String>(clientPayload),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncConflict copyWith(
          {String? id,
          String? docType,
          String? name,
          String? serverPayload,
          String? clientPayload,
          String? status,
          DateTime? createdAt}) =>
      SyncConflict(
        id: id ?? this.id,
        docType: docType ?? this.docType,
        name: name ?? this.name,
        serverPayload: serverPayload ?? this.serverPayload,
        clientPayload: clientPayload ?? this.clientPayload,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  SyncConflict copyWithCompanion(SyncConflictsCompanion data) {
    return SyncConflict(
      id: data.id.present ? data.id.value : this.id,
      docType: data.docType.present ? data.docType.value : this.docType,
      name: data.name.present ? data.name.value : this.name,
      serverPayload: data.serverPayload.present
          ? data.serverPayload.value
          : this.serverPayload,
      clientPayload: data.clientPayload.present
          ? data.clientPayload.value
          : this.clientPayload,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflict(')
          ..write('id: $id, ')
          ..write('docType: $docType, ')
          ..write('name: $name, ')
          ..write('serverPayload: $serverPayload, ')
          ..write('clientPayload: $clientPayload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, docType, name, serverPayload, clientPayload, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflict &&
          other.id == this.id &&
          other.docType == this.docType &&
          other.name == this.name &&
          other.serverPayload == this.serverPayload &&
          other.clientPayload == this.clientPayload &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class SyncConflictsCompanion extends UpdateCompanion<SyncConflict> {
  final Value<String> id;
  final Value<String> docType;
  final Value<String> name;
  final Value<String> serverPayload;
  final Value<String> clientPayload;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SyncConflictsCompanion({
    this.id = const Value.absent(),
    this.docType = const Value.absent(),
    this.name = const Value.absent(),
    this.serverPayload = const Value.absent(),
    this.clientPayload = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncConflictsCompanion.insert({
    required String id,
    required String docType,
    required String name,
    required String serverPayload,
    required String clientPayload,
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        docType = Value(docType),
        name = Value(name),
        serverPayload = Value(serverPayload),
        clientPayload = Value(clientPayload);
  static Insertable<SyncConflict> custom({
    Expression<String>? id,
    Expression<String>? docType,
    Expression<String>? name,
    Expression<String>? serverPayload,
    Expression<String>? clientPayload,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (docType != null) 'doc_type': docType,
      if (name != null) 'name': name,
      if (serverPayload != null) 'server_payload': serverPayload,
      if (clientPayload != null) 'client_payload': clientPayload,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncConflictsCompanion copyWith(
      {Value<String>? id,
      Value<String>? docType,
      Value<String>? name,
      Value<String>? serverPayload,
      Value<String>? clientPayload,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SyncConflictsCompanion(
      id: id ?? this.id,
      docType: docType ?? this.docType,
      name: name ?? this.name,
      serverPayload: serverPayload ?? this.serverPayload,
      clientPayload: clientPayload ?? this.clientPayload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (docType.present) {
      map['doc_type'] = Variable<String>(docType.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (serverPayload.present) {
      map['server_payload'] = Variable<String>(serverPayload.value);
    }
    if (clientPayload.present) {
      map['client_payload'] = Variable<String>(clientPayload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictsCompanion(')
          ..write('id: $id, ')
          ..write('docType: $docType, ')
          ..write('name: $name, ')
          ..write('serverPayload: $serverPayload, ')
          ..write('clientPayload: $clientPayload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskCacheTable extends TaskCache
    with TableInfo<$TaskCacheTable, TaskCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taskTypeMeta =
      const VerificationMeta('taskType');
  @override
  late final GeneratedColumn<String> taskType = GeneratedColumn<String>(
      'task_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _objectNameMeta =
      const VerificationMeta('objectName');
  @override
  late final GeneratedColumn<String> objectName = GeneratedColumn<String>(
      'object_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _assignedToMeta =
      const VerificationMeta('assignedTo');
  @override
  late final GeneratedColumn<String> assignedTo = GeneratedColumn<String>(
      'assigned_to', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        taskType,
        entityId,
        objectName,
        status,
        assignedTo,
        dueDate,
        payload,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_cache';
  @override
  VerificationContext validateIntegrity(Insertable<TaskCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_type')) {
      context.handle(_taskTypeMeta,
          taskType.isAcceptableOrUnknown(data['task_type']!, _taskTypeMeta));
    } else if (isInserting) {
      context.missing(_taskTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('object_name')) {
      context.handle(
          _objectNameMeta,
          objectName.isAcceptableOrUnknown(
              data['object_name']!, _objectNameMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('assigned_to')) {
      context.handle(
          _assignedToMeta,
          assignedTo.isAcceptableOrUnknown(
              data['assigned_to']!, _assignedToMeta));
    } else if (isInserting) {
      context.missing(_assignedToMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      taskType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      objectName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}object_name'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      assignedTo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}assigned_to'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $TaskCacheTable createAlias(String alias) {
    return $TaskCacheTable(attachedDatabase, alias);
  }
}

class TaskCacheData extends DataClass implements Insertable<TaskCacheData> {
  final String id;
  final String taskType;
  final String entityId;
  final String objectName;
  final String status;
  final String assignedTo;
  final DateTime? dueDate;
  final String payload;
  final DateTime cachedAt;
  const TaskCacheData(
      {required this.id,
      required this.taskType,
      required this.entityId,
      required this.objectName,
      required this.status,
      required this.assignedTo,
      this.dueDate,
      required this.payload,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_type'] = Variable<String>(taskType);
    map['entity_id'] = Variable<String>(entityId);
    map['object_name'] = Variable<String>(objectName);
    map['status'] = Variable<String>(status);
    map['assigned_to'] = Variable<String>(assignedTo);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['payload'] = Variable<String>(payload);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  TaskCacheCompanion toCompanion(bool nullToAbsent) {
    return TaskCacheCompanion(
      id: Value(id),
      taskType: Value(taskType),
      entityId: Value(entityId),
      objectName: Value(objectName),
      status: Value(status),
      assignedTo: Value(assignedTo),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      payload: Value(payload),
      cachedAt: Value(cachedAt),
    );
  }

  factory TaskCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskCacheData(
      id: serializer.fromJson<String>(json['id']),
      taskType: serializer.fromJson<String>(json['taskType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      objectName: serializer.fromJson<String>(json['objectName']),
      status: serializer.fromJson<String>(json['status']),
      assignedTo: serializer.fromJson<String>(json['assignedTo']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      payload: serializer.fromJson<String>(json['payload']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskType': serializer.toJson<String>(taskType),
      'entityId': serializer.toJson<String>(entityId),
      'objectName': serializer.toJson<String>(objectName),
      'status': serializer.toJson<String>(status),
      'assignedTo': serializer.toJson<String>(assignedTo),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'payload': serializer.toJson<String>(payload),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  TaskCacheData copyWith(
          {String? id,
          String? taskType,
          String? entityId,
          String? objectName,
          String? status,
          String? assignedTo,
          Value<DateTime?> dueDate = const Value.absent(),
          String? payload,
          DateTime? cachedAt}) =>
      TaskCacheData(
        id: id ?? this.id,
        taskType: taskType ?? this.taskType,
        entityId: entityId ?? this.entityId,
        objectName: objectName ?? this.objectName,
        status: status ?? this.status,
        assignedTo: assignedTo ?? this.assignedTo,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        payload: payload ?? this.payload,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  TaskCacheData copyWithCompanion(TaskCacheCompanion data) {
    return TaskCacheData(
      id: data.id.present ? data.id.value : this.id,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      objectName:
          data.objectName.present ? data.objectName.value : this.objectName,
      status: data.status.present ? data.status.value : this.status,
      assignedTo:
          data.assignedTo.present ? data.assignedTo.value : this.assignedTo,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      payload: data.payload.present ? data.payload.value : this.payload,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskCacheData(')
          ..write('id: $id, ')
          ..write('taskType: $taskType, ')
          ..write('entityId: $entityId, ')
          ..write('objectName: $objectName, ')
          ..write('status: $status, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('dueDate: $dueDate, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskType, entityId, objectName, status,
      assignedTo, dueDate, payload, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskCacheData &&
          other.id == this.id &&
          other.taskType == this.taskType &&
          other.entityId == this.entityId &&
          other.objectName == this.objectName &&
          other.status == this.status &&
          other.assignedTo == this.assignedTo &&
          other.dueDate == this.dueDate &&
          other.payload == this.payload &&
          other.cachedAt == this.cachedAt);
}

class TaskCacheCompanion extends UpdateCompanion<TaskCacheData> {
  final Value<String> id;
  final Value<String> taskType;
  final Value<String> entityId;
  final Value<String> objectName;
  final Value<String> status;
  final Value<String> assignedTo;
  final Value<DateTime?> dueDate;
  final Value<String> payload;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const TaskCacheCompanion({
    this.id = const Value.absent(),
    this.taskType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.objectName = const Value.absent(),
    this.status = const Value.absent(),
    this.assignedTo = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.payload = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskCacheCompanion.insert({
    required String id,
    required String taskType,
    required String entityId,
    this.objectName = const Value.absent(),
    required String status,
    required String assignedTo,
    this.dueDate = const Value.absent(),
    this.payload = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        taskType = Value(taskType),
        entityId = Value(entityId),
        status = Value(status),
        assignedTo = Value(assignedTo);
  static Insertable<TaskCacheData> custom({
    Expression<String>? id,
    Expression<String>? taskType,
    Expression<String>? entityId,
    Expression<String>? objectName,
    Expression<String>? status,
    Expression<String>? assignedTo,
    Expression<DateTime>? dueDate,
    Expression<String>? payload,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskType != null) 'task_type': taskType,
      if (entityId != null) 'entity_id': entityId,
      if (objectName != null) 'object_name': objectName,
      if (status != null) 'status': status,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (dueDate != null) 'due_date': dueDate,
      if (payload != null) 'payload': payload,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? taskType,
      Value<String>? entityId,
      Value<String>? objectName,
      Value<String>? status,
      Value<String>? assignedTo,
      Value<DateTime?>? dueDate,
      Value<String>? payload,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return TaskCacheCompanion(
      id: id ?? this.id,
      taskType: taskType ?? this.taskType,
      entityId: entityId ?? this.entityId,
      objectName: objectName ?? this.objectName,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      payload: payload ?? this.payload,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<String>(taskType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (objectName.present) {
      map['object_name'] = Variable<String>(objectName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (assignedTo.present) {
      map['assigned_to'] = Variable<String>(assignedTo.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskCacheCompanion(')
          ..write('id: $id, ')
          ..write('taskType: $taskType, ')
          ..write('entityId: $entityId, ')
          ..write('objectName: $objectName, ')
          ..write('status: $status, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('dueDate: $dueDate, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VisitsTable visits = $VisitsTable(this);
  late final $ChecklistInstancesTable checklistInstances =
      $ChecklistInstancesTable(this);
  late final $ChecklistItemsTable checklistItems = $ChecklistItemsTable(this);
  late final $ObjectPassportsTable objectPassports =
      $ObjectPassportsTable(this);
  late final $InstallationPointsTable installationPoints =
      $InstallationPointsTable(this);
  late final $MediaAssetsTable mediaAssets = $MediaAssetsTable(this);
  late final $PendingMediaUploadsTable pendingMediaUploads =
      $PendingMediaUploadsTable(this);
  late final $RemoteInspectionsTable remoteInspections =
      $RemoteInspectionsTable(this);
  late final $ServiceRequestsTable serviceRequests =
      $ServiceRequestsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SyncConflictsTable syncConflicts = $SyncConflictsTable(this);
  late final $TaskCacheTable taskCache = $TaskCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        visits,
        checklistInstances,
        checklistItems,
        objectPassports,
        installationPoints,
        mediaAssets,
        pendingMediaUploads,
        remoteInspections,
        serviceRequests,
        syncQueue,
        syncConflicts,
        taskCache
      ];
}

typedef $$VisitsTableCreateCompanionBuilder = VisitsCompanion Function({
  required String id,
  required String objectId,
  Value<String> status,
  required String engineerId,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$VisitsTableUpdateCompanionBuilder = VisitsCompanion Function({
  Value<String> id,
  Value<String> objectId,
  Value<String> status,
  Value<String> engineerId,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$VisitsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get objectId => $composableBuilder(
      column: $table.objectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get engineerId => $composableBuilder(
      column: $table.engineerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$VisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get objectId => $composableBuilder(
      column: $table.objectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get engineerId => $composableBuilder(
      column: $table.engineerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$VisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get objectId =>
      $composableBuilder(column: $table.objectId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get engineerId => $composableBuilder(
      column: $table.engineerId, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VisitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VisitsTable,
    Visit,
    $$VisitsTableFilterComposer,
    $$VisitsTableOrderingComposer,
    $$VisitsTableAnnotationComposer,
    $$VisitsTableCreateCompanionBuilder,
    $$VisitsTableUpdateCompanionBuilder,
    (Visit, BaseReferences<_$AppDatabase, $VisitsTable, Visit>),
    Visit,
    PrefetchHooks Function()> {
  $$VisitsTableTableManager(_$AppDatabase db, $VisitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> objectId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> engineerId = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VisitsCompanion(
            id: id,
            objectId: objectId,
            status: status,
            engineerId: engineerId,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            payload: payload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String objectId,
            Value<String> status = const Value.absent(),
            required String engineerId,
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VisitsCompanion.insert(
            id: id,
            objectId: objectId,
            status: status,
            engineerId: engineerId,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            payload: payload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VisitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VisitsTable,
    Visit,
    $$VisitsTableFilterComposer,
    $$VisitsTableOrderingComposer,
    $$VisitsTableAnnotationComposer,
    $$VisitsTableCreateCompanionBuilder,
    $$VisitsTableUpdateCompanionBuilder,
    (Visit, BaseReferences<_$AppDatabase, $VisitsTable, Visit>),
    Visit,
    PrefetchHooks Function()>;
typedef $$ChecklistInstancesTableCreateCompanionBuilder
    = ChecklistInstancesCompanion Function({
  required String id,
  required String visitId,
  required String templateId,
  Value<String> status,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$ChecklistInstancesTableUpdateCompanionBuilder
    = ChecklistInstancesCompanion Function({
  Value<String> id,
  Value<String> visitId,
  Value<String> templateId,
  Value<String> status,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ChecklistInstancesTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistInstancesTable> {
  $$ChecklistInstancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get visitId => $composableBuilder(
      column: $table.visitId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ChecklistInstancesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistInstancesTable> {
  $$ChecklistInstancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get visitId => $composableBuilder(
      column: $table.visitId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ChecklistInstancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistInstancesTable> {
  $$ChecklistInstancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get visitId =>
      $composableBuilder(column: $table.visitId, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChecklistInstancesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChecklistInstancesTable,
    ChecklistInstance,
    $$ChecklistInstancesTableFilterComposer,
    $$ChecklistInstancesTableOrderingComposer,
    $$ChecklistInstancesTableAnnotationComposer,
    $$ChecklistInstancesTableCreateCompanionBuilder,
    $$ChecklistInstancesTableUpdateCompanionBuilder,
    (
      ChecklistInstance,
      BaseReferences<_$AppDatabase, $ChecklistInstancesTable, ChecklistInstance>
    ),
    ChecklistInstance,
    PrefetchHooks Function()> {
  $$ChecklistInstancesTableTableManager(
      _$AppDatabase db, $ChecklistInstancesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistInstancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistInstancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistInstancesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> visitId = const Value.absent(),
            Value<String> templateId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChecklistInstancesCompanion(
            id: id,
            visitId: visitId,
            templateId: templateId,
            status: status,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            payload: payload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String visitId,
            required String templateId,
            Value<String> status = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChecklistInstancesCompanion.insert(
            id: id,
            visitId: visitId,
            templateId: templateId,
            status: status,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            payload: payload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChecklistInstancesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChecklistInstancesTable,
    ChecklistInstance,
    $$ChecklistInstancesTableFilterComposer,
    $$ChecklistInstancesTableOrderingComposer,
    $$ChecklistInstancesTableAnnotationComposer,
    $$ChecklistInstancesTableCreateCompanionBuilder,
    $$ChecklistInstancesTableUpdateCompanionBuilder,
    (
      ChecklistInstance,
      BaseReferences<_$AppDatabase, $ChecklistInstancesTable, ChecklistInstance>
    ),
    ChecklistInstance,
    PrefetchHooks Function()>;
typedef $$ChecklistItemsTableCreateCompanionBuilder = ChecklistItemsCompanion
    Function({
  required String id,
  required String instanceId,
  required String itemUuid,
  required String label,
  Value<bool> checked,
  Value<String?> photoId,
  Value<String?> serialNo,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$ChecklistItemsTableUpdateCompanionBuilder = ChecklistItemsCompanion
    Function({
  Value<String> id,
  Value<String> instanceId,
  Value<String> itemUuid,
  Value<String> label,
  Value<bool> checked,
  Value<String?> photoId,
  Value<String?> serialNo,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ChecklistItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get instanceId => $composableBuilder(
      column: $table.instanceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemUuid => $composableBuilder(
      column: $table.itemUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get checked => $composableBuilder(
      column: $table.checked, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoId => $composableBuilder(
      column: $table.photoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serialNo => $composableBuilder(
      column: $table.serialNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ChecklistItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get instanceId => $composableBuilder(
      column: $table.instanceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemUuid => $composableBuilder(
      column: $table.itemUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get checked => $composableBuilder(
      column: $table.checked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoId => $composableBuilder(
      column: $table.photoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serialNo => $composableBuilder(
      column: $table.serialNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ChecklistItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get instanceId => $composableBuilder(
      column: $table.instanceId, builder: (column) => column);

  GeneratedColumn<String> get itemUuid =>
      $composableBuilder(column: $table.itemUuid, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get checked =>
      $composableBuilder(column: $table.checked, builder: (column) => column);

  GeneratedColumn<String> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<String> get serialNo =>
      $composableBuilder(column: $table.serialNo, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChecklistItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChecklistItemsTable,
    ChecklistItem,
    $$ChecklistItemsTableFilterComposer,
    $$ChecklistItemsTableOrderingComposer,
    $$ChecklistItemsTableAnnotationComposer,
    $$ChecklistItemsTableCreateCompanionBuilder,
    $$ChecklistItemsTableUpdateCompanionBuilder,
    (
      ChecklistItem,
      BaseReferences<_$AppDatabase, $ChecklistItemsTable, ChecklistItem>
    ),
    ChecklistItem,
    PrefetchHooks Function()> {
  $$ChecklistItemsTableTableManager(
      _$AppDatabase db, $ChecklistItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> instanceId = const Value.absent(),
            Value<String> itemUuid = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<bool> checked = const Value.absent(),
            Value<String?> photoId = const Value.absent(),
            Value<String?> serialNo = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChecklistItemsCompanion(
            id: id,
            instanceId: instanceId,
            itemUuid: itemUuid,
            label: label,
            checked: checked,
            photoId: photoId,
            serialNo: serialNo,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String instanceId,
            required String itemUuid,
            required String label,
            Value<bool> checked = const Value.absent(),
            Value<String?> photoId = const Value.absent(),
            Value<String?> serialNo = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChecklistItemsCompanion.insert(
            id: id,
            instanceId: instanceId,
            itemUuid: itemUuid,
            label: label,
            checked: checked,
            photoId: photoId,
            serialNo: serialNo,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChecklistItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChecklistItemsTable,
    ChecklistItem,
    $$ChecklistItemsTableFilterComposer,
    $$ChecklistItemsTableOrderingComposer,
    $$ChecklistItemsTableAnnotationComposer,
    $$ChecklistItemsTableCreateCompanionBuilder,
    $$ChecklistItemsTableUpdateCompanionBuilder,
    (
      ChecklistItem,
      BaseReferences<_$AppDatabase, $ChecklistItemsTable, ChecklistItem>
    ),
    ChecklistItem,
    PrefetchHooks Function()>;
typedef $$ObjectPassportsTableCreateCompanionBuilder = ObjectPassportsCompanion
    Function({
  required String id,
  required String customerId,
  required String name,
  Value<String> address,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String> payload,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});
typedef $$ObjectPassportsTableUpdateCompanionBuilder = ObjectPassportsCompanion
    Function({
  Value<String> id,
  Value<String> customerId,
  Value<String> name,
  Value<String> address,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String> payload,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$ObjectPassportsTableFilterComposer
    extends Composer<_$AppDatabase, $ObjectPassportsTable> {
  $$ObjectPassportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$ObjectPassportsTableOrderingComposer
    extends Composer<_$AppDatabase, $ObjectPassportsTable> {
  $$ObjectPassportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$ObjectPassportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ObjectPassportsTable> {
  $$ObjectPassportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ObjectPassportsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ObjectPassportsTable,
    ObjectPassport,
    $$ObjectPassportsTableFilterComposer,
    $$ObjectPassportsTableOrderingComposer,
    $$ObjectPassportsTableAnnotationComposer,
    $$ObjectPassportsTableCreateCompanionBuilder,
    $$ObjectPassportsTableUpdateCompanionBuilder,
    (
      ObjectPassport,
      BaseReferences<_$AppDatabase, $ObjectPassportsTable, ObjectPassport>
    ),
    ObjectPassport,
    PrefetchHooks Function()> {
  $$ObjectPassportsTableTableManager(
      _$AppDatabase db, $ObjectPassportsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ObjectPassportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ObjectPassportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ObjectPassportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> customerId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ObjectPassportsCompanion(
            id: id,
            customerId: customerId,
            name: name,
            address: address,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            payload: payload,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String customerId,
            required String name,
            Value<String> address = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ObjectPassportsCompanion.insert(
            id: id,
            customerId: customerId,
            name: name,
            address: address,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            payload: payload,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ObjectPassportsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ObjectPassportsTable,
    ObjectPassport,
    $$ObjectPassportsTableFilterComposer,
    $$ObjectPassportsTableOrderingComposer,
    $$ObjectPassportsTableAnnotationComposer,
    $$ObjectPassportsTableCreateCompanionBuilder,
    $$ObjectPassportsTableUpdateCompanionBuilder,
    (
      ObjectPassport,
      BaseReferences<_$AppDatabase, $ObjectPassportsTable, ObjectPassport>
    ),
    ObjectPassport,
    PrefetchHooks Function()>;
typedef $$InstallationPointsTableCreateCompanionBuilder
    = InstallationPointsCompanion Function({
  required String id,
  required String mapId,
  required String pointUuid,
  required String mapKind,
  Value<double?> x,
  Value<double?> y,
  Value<double?> lat,
  Value<double?> lng,
  Value<String> label,
  Value<String> payload,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$InstallationPointsTableUpdateCompanionBuilder
    = InstallationPointsCompanion Function({
  Value<String> id,
  Value<String> mapId,
  Value<String> pointUuid,
  Value<String> mapKind,
  Value<double?> x,
  Value<double?> y,
  Value<double?> lat,
  Value<double?> lng,
  Value<String> label,
  Value<String> payload,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$InstallationPointsTableFilterComposer
    extends Composer<_$AppDatabase, $InstallationPointsTable> {
  $$InstallationPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mapId => $composableBuilder(
      column: $table.mapId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pointUuid => $composableBuilder(
      column: $table.pointUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mapKind => $composableBuilder(
      column: $table.mapKind, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get x => $composableBuilder(
      column: $table.x, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get y => $composableBuilder(
      column: $table.y, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lng => $composableBuilder(
      column: $table.lng, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$InstallationPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstallationPointsTable> {
  $$InstallationPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mapId => $composableBuilder(
      column: $table.mapId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pointUuid => $composableBuilder(
      column: $table.pointUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mapKind => $composableBuilder(
      column: $table.mapKind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get x => $composableBuilder(
      column: $table.x, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get y => $composableBuilder(
      column: $table.y, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lng => $composableBuilder(
      column: $table.lng, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$InstallationPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstallationPointsTable> {
  $$InstallationPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mapId =>
      $composableBuilder(column: $table.mapId, builder: (column) => column);

  GeneratedColumn<String> get pointUuid =>
      $composableBuilder(column: $table.pointUuid, builder: (column) => column);

  GeneratedColumn<String> get mapKind =>
      $composableBuilder(column: $table.mapKind, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InstallationPointsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InstallationPointsTable,
    InstallationPoint,
    $$InstallationPointsTableFilterComposer,
    $$InstallationPointsTableOrderingComposer,
    $$InstallationPointsTableAnnotationComposer,
    $$InstallationPointsTableCreateCompanionBuilder,
    $$InstallationPointsTableUpdateCompanionBuilder,
    (
      InstallationPoint,
      BaseReferences<_$AppDatabase, $InstallationPointsTable, InstallationPoint>
    ),
    InstallationPoint,
    PrefetchHooks Function()> {
  $$InstallationPointsTableTableManager(
      _$AppDatabase db, $InstallationPointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstallationPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstallationPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstallationPointsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> mapId = const Value.absent(),
            Value<String> pointUuid = const Value.absent(),
            Value<String> mapKind = const Value.absent(),
            Value<double?> x = const Value.absent(),
            Value<double?> y = const Value.absent(),
            Value<double?> lat = const Value.absent(),
            Value<double?> lng = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InstallationPointsCompanion(
            id: id,
            mapId: mapId,
            pointUuid: pointUuid,
            mapKind: mapKind,
            x: x,
            y: y,
            lat: lat,
            lng: lng,
            label: label,
            payload: payload,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String mapId,
            required String pointUuid,
            required String mapKind,
            Value<double?> x = const Value.absent(),
            Value<double?> y = const Value.absent(),
            Value<double?> lat = const Value.absent(),
            Value<double?> lng = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InstallationPointsCompanion.insert(
            id: id,
            mapId: mapId,
            pointUuid: pointUuid,
            mapKind: mapKind,
            x: x,
            y: y,
            lat: lat,
            lng: lng,
            label: label,
            payload: payload,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InstallationPointsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InstallationPointsTable,
    InstallationPoint,
    $$InstallationPointsTableFilterComposer,
    $$InstallationPointsTableOrderingComposer,
    $$InstallationPointsTableAnnotationComposer,
    $$InstallationPointsTableCreateCompanionBuilder,
    $$InstallationPointsTableUpdateCompanionBuilder,
    (
      InstallationPoint,
      BaseReferences<_$AppDatabase, $InstallationPointsTable, InstallationPoint>
    ),
    InstallationPoint,
    PrefetchHooks Function()>;
typedef $$MediaAssetsTableCreateCompanionBuilder = MediaAssetsCompanion
    Function({
  required String id,
  required String clientUuid,
  required String parentDoctype,
  required String parentName,
  required String mediaType,
  Value<String> tag,
  Value<bool> aiAllowed,
  Value<String?> localPath,
  Value<String?> driveId,
  Value<String> transcriptionStatus,
  Value<String?> transcription,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$MediaAssetsTableUpdateCompanionBuilder = MediaAssetsCompanion
    Function({
  Value<String> id,
  Value<String> clientUuid,
  Value<String> parentDoctype,
  Value<String> parentName,
  Value<String> mediaType,
  Value<String> tag,
  Value<bool> aiAllowed,
  Value<String?> localPath,
  Value<String?> driveId,
  Value<String> transcriptionStatus,
  Value<String?> transcription,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$MediaAssetsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentDoctype => $composableBuilder(
      column: $table.parentDoctype, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get aiAllowed => $composableBuilder(
      column: $table.aiAllowed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get driveId => $composableBuilder(
      column: $table.driveId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcriptionStatus => $composableBuilder(
      column: $table.transcriptionStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcription => $composableBuilder(
      column: $table.transcription, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$MediaAssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentDoctype => $composableBuilder(
      column: $table.parentDoctype,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get aiAllowed => $composableBuilder(
      column: $table.aiAllowed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get driveId => $composableBuilder(
      column: $table.driveId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcriptionStatus => $composableBuilder(
      column: $table.transcriptionStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcription => $composableBuilder(
      column: $table.transcription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$MediaAssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => column);

  GeneratedColumn<String> get parentDoctype => $composableBuilder(
      column: $table.parentDoctype, builder: (column) => column);

  GeneratedColumn<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<bool> get aiAllowed =>
      $composableBuilder(column: $table.aiAllowed, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get driveId =>
      $composableBuilder(column: $table.driveId, builder: (column) => column);

  GeneratedColumn<String> get transcriptionStatus => $composableBuilder(
      column: $table.transcriptionStatus, builder: (column) => column);

  GeneratedColumn<String> get transcription => $composableBuilder(
      column: $table.transcription, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MediaAssetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaAssetsTable,
    MediaAsset,
    $$MediaAssetsTableFilterComposer,
    $$MediaAssetsTableOrderingComposer,
    $$MediaAssetsTableAnnotationComposer,
    $$MediaAssetsTableCreateCompanionBuilder,
    $$MediaAssetsTableUpdateCompanionBuilder,
    (MediaAsset, BaseReferences<_$AppDatabase, $MediaAssetsTable, MediaAsset>),
    MediaAsset,
    PrefetchHooks Function()> {
  $$MediaAssetsTableTableManager(_$AppDatabase db, $MediaAssetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> clientUuid = const Value.absent(),
            Value<String> parentDoctype = const Value.absent(),
            Value<String> parentName = const Value.absent(),
            Value<String> mediaType = const Value.absent(),
            Value<String> tag = const Value.absent(),
            Value<bool> aiAllowed = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String?> driveId = const Value.absent(),
            Value<String> transcriptionStatus = const Value.absent(),
            Value<String?> transcription = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaAssetsCompanion(
            id: id,
            clientUuid: clientUuid,
            parentDoctype: parentDoctype,
            parentName: parentName,
            mediaType: mediaType,
            tag: tag,
            aiAllowed: aiAllowed,
            localPath: localPath,
            driveId: driveId,
            transcriptionStatus: transcriptionStatus,
            transcription: transcription,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String clientUuid,
            required String parentDoctype,
            required String parentName,
            required String mediaType,
            Value<String> tag = const Value.absent(),
            Value<bool> aiAllowed = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String?> driveId = const Value.absent(),
            Value<String> transcriptionStatus = const Value.absent(),
            Value<String?> transcription = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaAssetsCompanion.insert(
            id: id,
            clientUuid: clientUuid,
            parentDoctype: parentDoctype,
            parentName: parentName,
            mediaType: mediaType,
            tag: tag,
            aiAllowed: aiAllowed,
            localPath: localPath,
            driveId: driveId,
            transcriptionStatus: transcriptionStatus,
            transcription: transcription,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaAssetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaAssetsTable,
    MediaAsset,
    $$MediaAssetsTableFilterComposer,
    $$MediaAssetsTableOrderingComposer,
    $$MediaAssetsTableAnnotationComposer,
    $$MediaAssetsTableCreateCompanionBuilder,
    $$MediaAssetsTableUpdateCompanionBuilder,
    (MediaAsset, BaseReferences<_$AppDatabase, $MediaAssetsTable, MediaAsset>),
    MediaAsset,
    PrefetchHooks Function()>;
typedef $$PendingMediaUploadsTableCreateCompanionBuilder
    = PendingMediaUploadsCompanion Function({
  Value<int> id,
  required String clientUuid,
  required String localPath,
  required String mediaType,
  required String parentDoctype,
  required String parentName,
  Value<String> tag,
  Value<String> status,
  Value<int> attempts,
  Value<DateTime> createdAt,
});
typedef $$PendingMediaUploadsTableUpdateCompanionBuilder
    = PendingMediaUploadsCompanion Function({
  Value<int> id,
  Value<String> clientUuid,
  Value<String> localPath,
  Value<String> mediaType,
  Value<String> parentDoctype,
  Value<String> parentName,
  Value<String> tag,
  Value<String> status,
  Value<int> attempts,
  Value<DateTime> createdAt,
});

class $$PendingMediaUploadsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingMediaUploadsTable> {
  $$PendingMediaUploadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentDoctype => $composableBuilder(
      column: $table.parentDoctype, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PendingMediaUploadsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingMediaUploadsTable> {
  $$PendingMediaUploadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentDoctype => $composableBuilder(
      column: $table.parentDoctype,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PendingMediaUploadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingMediaUploadsTable> {
  $$PendingMediaUploadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get parentDoctype => $composableBuilder(
      column: $table.parentDoctype, builder: (column) => column);

  GeneratedColumn<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingMediaUploadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingMediaUploadsTable,
    PendingMediaUpload,
    $$PendingMediaUploadsTableFilterComposer,
    $$PendingMediaUploadsTableOrderingComposer,
    $$PendingMediaUploadsTableAnnotationComposer,
    $$PendingMediaUploadsTableCreateCompanionBuilder,
    $$PendingMediaUploadsTableUpdateCompanionBuilder,
    (
      PendingMediaUpload,
      BaseReferences<_$AppDatabase, $PendingMediaUploadsTable,
          PendingMediaUpload>
    ),
    PendingMediaUpload,
    PrefetchHooks Function()> {
  $$PendingMediaUploadsTableTableManager(
      _$AppDatabase db, $PendingMediaUploadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingMediaUploadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingMediaUploadsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingMediaUploadsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> clientUuid = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<String> mediaType = const Value.absent(),
            Value<String> parentDoctype = const Value.absent(),
            Value<String> parentName = const Value.absent(),
            Value<String> tag = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PendingMediaUploadsCompanion(
            id: id,
            clientUuid: clientUuid,
            localPath: localPath,
            mediaType: mediaType,
            parentDoctype: parentDoctype,
            parentName: parentName,
            tag: tag,
            status: status,
            attempts: attempts,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String clientUuid,
            required String localPath,
            required String mediaType,
            required String parentDoctype,
            required String parentName,
            Value<String> tag = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PendingMediaUploadsCompanion.insert(
            id: id,
            clientUuid: clientUuid,
            localPath: localPath,
            mediaType: mediaType,
            parentDoctype: parentDoctype,
            parentName: parentName,
            tag: tag,
            status: status,
            attempts: attempts,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingMediaUploadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PendingMediaUploadsTable,
    PendingMediaUpload,
    $$PendingMediaUploadsTableFilterComposer,
    $$PendingMediaUploadsTableOrderingComposer,
    $$PendingMediaUploadsTableAnnotationComposer,
    $$PendingMediaUploadsTableCreateCompanionBuilder,
    $$PendingMediaUploadsTableUpdateCompanionBuilder,
    (
      PendingMediaUpload,
      BaseReferences<_$AppDatabase, $PendingMediaUploadsTable,
          PendingMediaUpload>
    ),
    PendingMediaUpload,
    PrefetchHooks Function()>;
typedef $$RemoteInspectionsTableCreateCompanionBuilder
    = RemoteInspectionsCompanion Function({
  required String id,
  required String objectId,
  Value<String> status,
  required String engineerId,
  Value<String> transcriptionStatus,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String> payload,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$RemoteInspectionsTableUpdateCompanionBuilder
    = RemoteInspectionsCompanion Function({
  Value<String> id,
  Value<String> objectId,
  Value<String> status,
  Value<String> engineerId,
  Value<String> transcriptionStatus,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String> payload,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$RemoteInspectionsTableFilterComposer
    extends Composer<_$AppDatabase, $RemoteInspectionsTable> {
  $$RemoteInspectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get objectId => $composableBuilder(
      column: $table.objectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get engineerId => $composableBuilder(
      column: $table.engineerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcriptionStatus => $composableBuilder(
      column: $table.transcriptionStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$RemoteInspectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RemoteInspectionsTable> {
  $$RemoteInspectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get objectId => $composableBuilder(
      column: $table.objectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get engineerId => $composableBuilder(
      column: $table.engineerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcriptionStatus => $composableBuilder(
      column: $table.transcriptionStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$RemoteInspectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemoteInspectionsTable> {
  $$RemoteInspectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get objectId =>
      $composableBuilder(column: $table.objectId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get engineerId => $composableBuilder(
      column: $table.engineerId, builder: (column) => column);

  GeneratedColumn<String> get transcriptionStatus => $composableBuilder(
      column: $table.transcriptionStatus, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RemoteInspectionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RemoteInspectionsTable,
    RemoteInspection,
    $$RemoteInspectionsTableFilterComposer,
    $$RemoteInspectionsTableOrderingComposer,
    $$RemoteInspectionsTableAnnotationComposer,
    $$RemoteInspectionsTableCreateCompanionBuilder,
    $$RemoteInspectionsTableUpdateCompanionBuilder,
    (
      RemoteInspection,
      BaseReferences<_$AppDatabase, $RemoteInspectionsTable, RemoteInspection>
    ),
    RemoteInspection,
    PrefetchHooks Function()> {
  $$RemoteInspectionsTableTableManager(
      _$AppDatabase db, $RemoteInspectionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteInspectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemoteInspectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemoteInspectionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> objectId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> engineerId = const Value.absent(),
            Value<String> transcriptionStatus = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemoteInspectionsCompanion(
            id: id,
            objectId: objectId,
            status: status,
            engineerId: engineerId,
            transcriptionStatus: transcriptionStatus,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            payload: payload,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String objectId,
            Value<String> status = const Value.absent(),
            required String engineerId,
            Value<String> transcriptionStatus = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemoteInspectionsCompanion.insert(
            id: id,
            objectId: objectId,
            status: status,
            engineerId: engineerId,
            transcriptionStatus: transcriptionStatus,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            payload: payload,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RemoteInspectionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RemoteInspectionsTable,
    RemoteInspection,
    $$RemoteInspectionsTableFilterComposer,
    $$RemoteInspectionsTableOrderingComposer,
    $$RemoteInspectionsTableAnnotationComposer,
    $$RemoteInspectionsTableCreateCompanionBuilder,
    $$RemoteInspectionsTableUpdateCompanionBuilder,
    (
      RemoteInspection,
      BaseReferences<_$AppDatabase, $RemoteInspectionsTable, RemoteInspection>
    ),
    RemoteInspection,
    PrefetchHooks Function()>;
typedef $$ServiceRequestsTableCreateCompanionBuilder = ServiceRequestsCompanion
    Function({
  required String id,
  required String objectId,
  required String requestType,
  Value<String> status,
  Value<String?> assignedTo,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$ServiceRequestsTableUpdateCompanionBuilder = ServiceRequestsCompanion
    Function({
  Value<String> id,
  Value<String> objectId,
  Value<String> requestType,
  Value<String> status,
  Value<String?> assignedTo,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ServiceRequestsTableFilterComposer
    extends Composer<_$AppDatabase, $ServiceRequestsTable> {
  $$ServiceRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get objectId => $composableBuilder(
      column: $table.objectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestType => $composableBuilder(
      column: $table.requestType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assignedTo => $composableBuilder(
      column: $table.assignedTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ServiceRequestsTableOrderingComposer
    extends Composer<_$AppDatabase, $ServiceRequestsTable> {
  $$ServiceRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get objectId => $composableBuilder(
      column: $table.objectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestType => $composableBuilder(
      column: $table.requestType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assignedTo => $composableBuilder(
      column: $table.assignedTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ServiceRequestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ServiceRequestsTable> {
  $$ServiceRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get objectId =>
      $composableBuilder(column: $table.objectId, builder: (column) => column);

  GeneratedColumn<String> get requestType => $composableBuilder(
      column: $table.requestType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get assignedTo => $composableBuilder(
      column: $table.assignedTo, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ServiceRequestsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ServiceRequestsTable,
    ServiceRequest,
    $$ServiceRequestsTableFilterComposer,
    $$ServiceRequestsTableOrderingComposer,
    $$ServiceRequestsTableAnnotationComposer,
    $$ServiceRequestsTableCreateCompanionBuilder,
    $$ServiceRequestsTableUpdateCompanionBuilder,
    (
      ServiceRequest,
      BaseReferences<_$AppDatabase, $ServiceRequestsTable, ServiceRequest>
    ),
    ServiceRequest,
    PrefetchHooks Function()> {
  $$ServiceRequestsTableTableManager(
      _$AppDatabase db, $ServiceRequestsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServiceRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServiceRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServiceRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> objectId = const Value.absent(),
            Value<String> requestType = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> assignedTo = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ServiceRequestsCompanion(
            id: id,
            objectId: objectId,
            requestType: requestType,
            status: status,
            assignedTo: assignedTo,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            payload: payload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String objectId,
            required String requestType,
            Value<String> status = const Value.absent(),
            Value<String?> assignedTo = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ServiceRequestsCompanion.insert(
            id: id,
            objectId: objectId,
            requestType: requestType,
            status: status,
            assignedTo: assignedTo,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            payload: payload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ServiceRequestsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ServiceRequestsTable,
    ServiceRequest,
    $$ServiceRequestsTableFilterComposer,
    $$ServiceRequestsTableOrderingComposer,
    $$ServiceRequestsTableAnnotationComposer,
    $$ServiceRequestsTableCreateCompanionBuilder,
    $$ServiceRequestsTableUpdateCompanionBuilder,
    (
      ServiceRequest,
      BaseReferences<_$AppDatabase, $ServiceRequestsTable, ServiceRequest>
    ),
    ServiceRequest,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String docType,
  required String name,
  required String operation,
  required String payload,
  Value<String> status,
  Value<int> attempts,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> docType,
  Value<String> name,
  Value<String> operation,
  Value<String> payload,
  Value<String> status,
  Value<int> attempts,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get docType => $composableBuilder(
      column: $table.docType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get docType => $composableBuilder(
      column: $table.docType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get docType =>
      $composableBuilder(column: $table.docType, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> docType = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            docType: docType,
            name: name,
            operation: operation,
            payload: payload,
            status: status,
            attempts: attempts,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String docType,
            required String name,
            required String operation,
            required String payload,
            Value<String> status = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            docType: docType,
            name: name,
            operation: operation,
            payload: payload,
            status: status,
            attempts: attempts,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()>;
typedef $$SyncConflictsTableCreateCompanionBuilder = SyncConflictsCompanion
    Function({
  required String id,
  required String docType,
  required String name,
  required String serverPayload,
  required String clientPayload,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$SyncConflictsTableUpdateCompanionBuilder = SyncConflictsCompanion
    Function({
  Value<String> id,
  Value<String> docType,
  Value<String> name,
  Value<String> serverPayload,
  Value<String> clientPayload,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SyncConflictsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get docType => $composableBuilder(
      column: $table.docType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverPayload => $composableBuilder(
      column: $table.serverPayload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientPayload => $composableBuilder(
      column: $table.clientPayload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SyncConflictsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get docType => $composableBuilder(
      column: $table.docType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverPayload => $composableBuilder(
      column: $table.serverPayload,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientPayload => $composableBuilder(
      column: $table.clientPayload,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncConflictsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get docType =>
      $composableBuilder(column: $table.docType, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get serverPayload => $composableBuilder(
      column: $table.serverPayload, builder: (column) => column);

  GeneratedColumn<String> get clientPayload => $composableBuilder(
      column: $table.clientPayload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncConflictsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncConflictsTable,
    SyncConflict,
    $$SyncConflictsTableFilterComposer,
    $$SyncConflictsTableOrderingComposer,
    $$SyncConflictsTableAnnotationComposer,
    $$SyncConflictsTableCreateCompanionBuilder,
    $$SyncConflictsTableUpdateCompanionBuilder,
    (
      SyncConflict,
      BaseReferences<_$AppDatabase, $SyncConflictsTable, SyncConflict>
    ),
    SyncConflict,
    PrefetchHooks Function()> {
  $$SyncConflictsTableTableManager(_$AppDatabase db, $SyncConflictsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConflictsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConflictsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncConflictsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> docType = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> serverPayload = const Value.absent(),
            Value<String> clientPayload = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncConflictsCompanion(
            id: id,
            docType: docType,
            name: name,
            serverPayload: serverPayload,
            clientPayload: clientPayload,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String docType,
            required String name,
            required String serverPayload,
            required String clientPayload,
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncConflictsCompanion.insert(
            id: id,
            docType: docType,
            name: name,
            serverPayload: serverPayload,
            clientPayload: clientPayload,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncConflictsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncConflictsTable,
    SyncConflict,
    $$SyncConflictsTableFilterComposer,
    $$SyncConflictsTableOrderingComposer,
    $$SyncConflictsTableAnnotationComposer,
    $$SyncConflictsTableCreateCompanionBuilder,
    $$SyncConflictsTableUpdateCompanionBuilder,
    (
      SyncConflict,
      BaseReferences<_$AppDatabase, $SyncConflictsTable, SyncConflict>
    ),
    SyncConflict,
    PrefetchHooks Function()>;
typedef $$TaskCacheTableCreateCompanionBuilder = TaskCacheCompanion Function({
  required String id,
  required String taskType,
  required String entityId,
  Value<String> objectName,
  required String status,
  required String assignedTo,
  Value<DateTime?> dueDate,
  Value<String> payload,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});
typedef $$TaskCacheTableUpdateCompanionBuilder = TaskCacheCompanion Function({
  Value<String> id,
  Value<String> taskType,
  Value<String> entityId,
  Value<String> objectName,
  Value<String> status,
  Value<String> assignedTo,
  Value<DateTime?> dueDate,
  Value<String> payload,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$TaskCacheTableFilterComposer
    extends Composer<_$AppDatabase, $TaskCacheTable> {
  $$TaskCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskType => $composableBuilder(
      column: $table.taskType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get objectName => $composableBuilder(
      column: $table.objectName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assignedTo => $composableBuilder(
      column: $table.assignedTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$TaskCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskCacheTable> {
  $$TaskCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskType => $composableBuilder(
      column: $table.taskType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get objectName => $composableBuilder(
      column: $table.objectName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assignedTo => $composableBuilder(
      column: $table.assignedTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$TaskCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskCacheTable> {
  $$TaskCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskType =>
      $composableBuilder(column: $table.taskType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get objectName => $composableBuilder(
      column: $table.objectName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get assignedTo => $composableBuilder(
      column: $table.assignedTo, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$TaskCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TaskCacheTable,
    TaskCacheData,
    $$TaskCacheTableFilterComposer,
    $$TaskCacheTableOrderingComposer,
    $$TaskCacheTableAnnotationComposer,
    $$TaskCacheTableCreateCompanionBuilder,
    $$TaskCacheTableUpdateCompanionBuilder,
    (
      TaskCacheData,
      BaseReferences<_$AppDatabase, $TaskCacheTable, TaskCacheData>
    ),
    TaskCacheData,
    PrefetchHooks Function()> {
  $$TaskCacheTableTableManager(_$AppDatabase db, $TaskCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> taskType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> objectName = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> assignedTo = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TaskCacheCompanion(
            id: id,
            taskType: taskType,
            entityId: entityId,
            objectName: objectName,
            status: status,
            assignedTo: assignedTo,
            dueDate: dueDate,
            payload: payload,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String taskType,
            required String entityId,
            Value<String> objectName = const Value.absent(),
            required String status,
            required String assignedTo,
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TaskCacheCompanion.insert(
            id: id,
            taskType: taskType,
            entityId: entityId,
            objectName: objectName,
            status: status,
            assignedTo: assignedTo,
            dueDate: dueDate,
            payload: payload,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TaskCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TaskCacheTable,
    TaskCacheData,
    $$TaskCacheTableFilterComposer,
    $$TaskCacheTableOrderingComposer,
    $$TaskCacheTableAnnotationComposer,
    $$TaskCacheTableCreateCompanionBuilder,
    $$TaskCacheTableUpdateCompanionBuilder,
    (
      TaskCacheData,
      BaseReferences<_$AppDatabase, $TaskCacheTable, TaskCacheData>
    ),
    TaskCacheData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db, _db.visits);
  $$ChecklistInstancesTableTableManager get checklistInstances =>
      $$ChecklistInstancesTableTableManager(_db, _db.checklistInstances);
  $$ChecklistItemsTableTableManager get checklistItems =>
      $$ChecklistItemsTableTableManager(_db, _db.checklistItems);
  $$ObjectPassportsTableTableManager get objectPassports =>
      $$ObjectPassportsTableTableManager(_db, _db.objectPassports);
  $$InstallationPointsTableTableManager get installationPoints =>
      $$InstallationPointsTableTableManager(_db, _db.installationPoints);
  $$MediaAssetsTableTableManager get mediaAssets =>
      $$MediaAssetsTableTableManager(_db, _db.mediaAssets);
  $$PendingMediaUploadsTableTableManager get pendingMediaUploads =>
      $$PendingMediaUploadsTableTableManager(_db, _db.pendingMediaUploads);
  $$RemoteInspectionsTableTableManager get remoteInspections =>
      $$RemoteInspectionsTableTableManager(_db, _db.remoteInspections);
  $$ServiceRequestsTableTableManager get serviceRequests =>
      $$ServiceRequestsTableTableManager(_db, _db.serviceRequests);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SyncConflictsTableTableManager get syncConflicts =>
      $$SyncConflictsTableTableManager(_db, _db.syncConflicts);
  $$TaskCacheTableTableManager get taskCache =>
      $$TaskCacheTableTableManager(_db, _db.taskCache);
}
