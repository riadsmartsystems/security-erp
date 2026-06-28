// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowidMeta = const VerificationMeta('rowid');
  @override
  late final GeneratedColumn<int> rowid = GeneratedColumn<int>(
      'rowid', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _watermarkMeta =
      const VerificationMeta('watermark');
  @override
  late final GeneratedColumn<String> watermark = GeneratedColumn<String>(
      'watermark', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [rowid, watermark, deviceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(Insertable<SyncMetaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('rowid')) {
      context.handle(
          _rowidMeta, rowid.isAcceptableOrUnknown(data['rowid']!, _rowidMeta));
    }
    if (data.containsKey('watermark')) {
      context.handle(_watermarkMeta,
          watermark.isAcceptableOrUnknown(data['watermark']!, _watermarkMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowid};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      rowid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rowid'])!,
      watermark: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}watermark']),
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final int rowid;
  final String? watermark;
  final String deviceId;
  const SyncMetaData(
      {required this.rowid, this.watermark, required this.deviceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['rowid'] = Variable<int>(rowid);
    if (!nullToAbsent || watermark != null) {
      map['watermark'] = Variable<String>(watermark);
    }
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      rowid: Value(rowid),
      watermark: watermark == null && nullToAbsent
          ? const Value.absent()
          : Value(watermark),
      deviceId: Value(deviceId),
    );
  }

  factory SyncMetaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      rowid: serializer.fromJson<int>(json['rowid']),
      watermark: serializer.fromJson<String?>(json['watermark']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowid': serializer.toJson<int>(rowid),
      'watermark': serializer.toJson<String?>(watermark),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  SyncMetaData copyWith(
          {int? rowid,
          Value<String?> watermark = const Value.absent(),
          String? deviceId}) =>
      SyncMetaData(
        rowid: rowid ?? this.rowid,
        watermark: watermark.present ? watermark.value : this.watermark,
        deviceId: deviceId ?? this.deviceId,
      );
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      rowid: data.rowid.present ? data.rowid.value : this.rowid,
      watermark: data.watermark.present ? data.watermark.value : this.watermark,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('rowid: $rowid, ')
          ..write('watermark: $watermark, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowid, watermark, deviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.rowid == this.rowid &&
          other.watermark == this.watermark &&
          other.deviceId == this.deviceId);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<int> rowid;
  final Value<String?> watermark;
  final Value<String> deviceId;
  const SyncMetaCompanion({
    this.rowid = const Value.absent(),
    this.watermark = const Value.absent(),
    this.deviceId = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    this.rowid = const Value.absent(),
    this.watermark = const Value.absent(),
    required String deviceId,
  }) : deviceId = Value(deviceId);
  static Insertable<SyncMetaData> custom({
    Expression<int>? rowid,
    Expression<String>? watermark,
    Expression<String>? deviceId,
  }) {
    return RawValuesInsertable({
      if (rowid != null) 'rowid': rowid,
      if (watermark != null) 'watermark': watermark,
      if (deviceId != null) 'device_id': deviceId,
    });
  }

  SyncMetaCompanion copyWith(
      {Value<int>? rowid, Value<String?>? watermark, Value<String>? deviceId}) {
    return SyncMetaCompanion(
      rowid: rowid ?? this.rowid,
      watermark: watermark ?? this.watermark,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    if (watermark.present) {
      map['watermark'] = Variable<String>(watermark.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('rowid: $rowid, ')
          ..write('watermark: $watermark, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }
}

class $PendingOpsTable extends PendingOps
    with TableInfo<$PendingOpsTable, PendingOp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _doctypeMeta =
      const VerificationMeta('doctype');
  @override
  late final GeneratedColumn<String> doctype = GeneratedColumn<String>(
      'doctype', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
      'op', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseVersionMeta =
      const VerificationMeta('baseVersion');
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
      'base_version', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
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
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextRetryAtMeta =
      const VerificationMeta('nextRetryAt');
  @override
  late final GeneratedColumn<int> nextRetryAt = GeneratedColumn<int>(
      'next_retry_at', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        doctype,
        name,
        op,
        payload,
        baseVersion,
        status,
        createdAt,
        retryCount,
        nextRetryAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_ops';
  @override
  VerificationContext validateIntegrity(Insertable<PendingOp> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('doctype')) {
      context.handle(_doctypeMeta,
          doctype.isAcceptableOrUnknown(data['doctype']!, _doctypeMeta));
    } else if (isInserting) {
      context.missing(_doctypeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('base_version')) {
      context.handle(
          _baseVersionMeta,
          baseVersion.isAcceptableOrUnknown(
              data['base_version']!, _baseVersionMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
          _nextRetryAtMeta,
          nextRetryAt.isAcceptableOrUnknown(
              data['next_retry_at']!, _nextRetryAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingOp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOp(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      doctype: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doctype'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      op: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}op'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      baseVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_version']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      nextRetryAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_retry_at'])!,
    );
  }

  @override
  $PendingOpsTable createAlias(String alias) {
    return $PendingOpsTable(attachedDatabase, alias);
  }
}

class PendingOp extends DataClass implements Insertable<PendingOp> {
  final int id;
  final String doctype;
  final String name;
  final String op;
  final String payload;
  final int? baseVersion;
  final String status;
  final int createdAt;
  final int retryCount;
  final int nextRetryAt;
  const PendingOp(
      {required this.id,
      required this.doctype,
      required this.name,
      required this.op,
      required this.payload,
      this.baseVersion,
      required this.status,
      required this.createdAt,
      required this.retryCount,
      required this.nextRetryAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['doctype'] = Variable<String>(doctype);
    map['name'] = Variable<String>(name);
    map['op'] = Variable<String>(op);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || baseVersion != null) {
      map['base_version'] = Variable<int>(baseVersion);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    map['next_retry_at'] = Variable<int>(nextRetryAt);
    return map;
  }

  PendingOpsCompanion toCompanion(bool nullToAbsent) {
    return PendingOpsCompanion(
      id: Value(id),
      doctype: Value(doctype),
      name: Value(name),
      op: Value(op),
      payload: Value(payload),
      baseVersion: baseVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseVersion),
      status: Value(status),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      nextRetryAt: Value(nextRetryAt),
    );
  }

  factory PendingOp.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOp(
      id: serializer.fromJson<int>(json['id']),
      doctype: serializer.fromJson<String>(json['doctype']),
      name: serializer.fromJson<String>(json['name']),
      op: serializer.fromJson<String>(json['op']),
      payload: serializer.fromJson<String>(json['payload']),
      baseVersion: serializer.fromJson<int?>(json['baseVersion']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextRetryAt: serializer.fromJson<int>(json['nextRetryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'doctype': serializer.toJson<String>(doctype),
      'name': serializer.toJson<String>(name),
      'op': serializer.toJson<String>(op),
      'payload': serializer.toJson<String>(payload),
      'baseVersion': serializer.toJson<int?>(baseVersion),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextRetryAt': serializer.toJson<int>(nextRetryAt),
    };
  }

  PendingOp copyWith(
          {int? id,
          String? doctype,
          String? name,
          String? op,
          String? payload,
          Value<int?> baseVersion = const Value.absent(),
          String? status,
          int? createdAt,
          int? retryCount,
          int? nextRetryAt}) =>
      PendingOp(
        id: id ?? this.id,
        doctype: doctype ?? this.doctype,
        name: name ?? this.name,
        op: op ?? this.op,
        payload: payload ?? this.payload,
        baseVersion: baseVersion.present ? baseVersion.value : this.baseVersion,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        retryCount: retryCount ?? this.retryCount,
        nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      );
  PendingOp copyWithCompanion(PendingOpsCompanion data) {
    return PendingOp(
      id: data.id.present ? data.id.value : this.id,
      doctype: data.doctype.present ? data.doctype.value : this.doctype,
      name: data.name.present ? data.name.value : this.name,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
      baseVersion:
          data.baseVersion.present ? data.baseVersion.value : this.baseVersion,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOp(')
          ..write('id: $id, ')
          ..write('doctype: $doctype, ')
          ..write('name: $name, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, doctype, name, op, payload, baseVersion,
      status, createdAt, retryCount, nextRetryAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOp &&
          other.id == this.id &&
          other.doctype == this.doctype &&
          other.name == this.name &&
          other.op == this.op &&
          other.payload == this.payload &&
          other.baseVersion == this.baseVersion &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.nextRetryAt == this.nextRetryAt);
}

class PendingOpsCompanion extends UpdateCompanion<PendingOp> {
  final Value<int> id;
  final Value<String> doctype;
  final Value<String> name;
  final Value<String> op;
  final Value<String> payload;
  final Value<int?> baseVersion;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> retryCount;
  final Value<int> nextRetryAt;
  const PendingOpsCompanion({
    this.id = const Value.absent(),
    this.doctype = const Value.absent(),
    this.name = const Value.absent(),
    this.op = const Value.absent(),
    this.payload = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
  });
  PendingOpsCompanion.insert({
    this.id = const Value.absent(),
    required String doctype,
    required String name,
    required String op,
    required String payload,
    this.baseVersion = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
  })  : doctype = Value(doctype),
        name = Value(name),
        op = Value(op),
        payload = Value(payload),
        createdAt = Value(createdAt);
  static Insertable<PendingOp> custom({
    Expression<int>? id,
    Expression<String>? doctype,
    Expression<String>? name,
    Expression<String>? op,
    Expression<String>? payload,
    Expression<int>? baseVersion,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? retryCount,
    Expression<int>? nextRetryAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (doctype != null) 'doctype': doctype,
      if (name != null) 'name': name,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
      if (baseVersion != null) 'base_version': baseVersion,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
    });
  }

  PendingOpsCompanion copyWith(
      {Value<int>? id,
      Value<String>? doctype,
      Value<String>? name,
      Value<String>? op,
      Value<String>? payload,
      Value<int?>? baseVersion,
      Value<String>? status,
      Value<int>? createdAt,
      Value<int>? retryCount,
      Value<int>? nextRetryAt}) {
    return PendingOpsCompanion(
      id: id ?? this.id,
      doctype: doctype ?? this.doctype,
      name: name ?? this.name,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      baseVersion: baseVersion ?? this.baseVersion,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (doctype.present) {
      map['doctype'] = Variable<String>(doctype.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<int>(nextRetryAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOpsCompanion(')
          ..write('id: $id, ')
          ..write('doctype: $doctype, ')
          ..write('name: $name, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt')
          ..write(')'))
        .toString();
  }
}

class $VisitsTable extends Visits with TableInfo<$VisitsTable, Visit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientUuidMeta =
      const VerificationMeta('clientUuid');
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
      'client_uuid', aliasedName, false,
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
  static const VerificationMeta _visitTypeMeta =
      const VerificationMeta('visitType');
  @override
  late final GeneratedColumn<String> visitType = GeneratedColumn<String>(
      'visit_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serviceTicketMeta =
      const VerificationMeta('serviceTicket');
  @override
  late final GeneratedColumn<String> serviceTicket = GeneratedColumn<String>(
      'service_ticket', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _visitDateMeta =
      const VerificationMeta('visitDate');
  @override
  late final GeneratedColumn<DateTime> visitDate = GeneratedColumn<DateTime>(
      'visit_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        clientUuid,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        visitType,
        summary,
        serviceTicket,
        visitDate,
        status
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
    if (data.containsKey('client_uuid')) {
      context.handle(
          _clientUuidMeta,
          clientUuid.isAcceptableOrUnknown(
              data['client_uuid']!, _clientUuidMeta));
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
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
    if (data.containsKey('visit_type')) {
      context.handle(_visitTypeMeta,
          visitType.isAcceptableOrUnknown(data['visit_type']!, _visitTypeMeta));
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    }
    if (data.containsKey('service_ticket')) {
      context.handle(
          _serviceTicketMeta,
          serviceTicket.isAcceptableOrUnknown(
              data['service_ticket']!, _serviceTicketMeta));
    }
    if (data.containsKey('visit_date')) {
      context.handle(_visitDateMeta,
          visitDate.isAcceptableOrUnknown(data['visit_date']!, _visitDateMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  Visit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Visit(
      clientUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_uuid'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      visitType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}visit_type']),
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary']),
      serviceTicket: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}service_ticket']),
      visitDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}visit_date']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status']),
    );
  }

  @override
  $VisitsTable createAlias(String alias) {
    return $VisitsTable(attachedDatabase, alias);
  }
}

class Visit extends DataClass implements Insertable<Visit> {
  final String clientUuid;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String? visitType;
  final String? summary;
  final String? serviceTicket;
  final DateTime? visitDate;
  final String? status;
  const Visit(
      {required this.clientUuid,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      this.visitType,
      this.summary,
      this.serviceTicket,
      this.visitDate,
      this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_uuid'] = Variable<String>(clientUuid);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    if (!nullToAbsent || visitType != null) {
      map['visit_type'] = Variable<String>(visitType);
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || serviceTicket != null) {
      map['service_ticket'] = Variable<String>(serviceTicket);
    }
    if (!nullToAbsent || visitDate != null) {
      map['visit_date'] = Variable<DateTime>(visitDate);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      clientUuid: Value(clientUuid),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      visitType: visitType == null && nullToAbsent
          ? const Value.absent()
          : Value(visitType),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      serviceTicket: serviceTicket == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceTicket),
      visitDate: visitDate == null && nullToAbsent
          ? const Value.absent()
          : Value(visitDate),
      status:
          status == null && nullToAbsent ? const Value.absent() : Value(status),
    );
  }

  factory Visit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Visit(
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      visitType: serializer.fromJson<String?>(json['visitType']),
      summary: serializer.fromJson<String?>(json['summary']),
      serviceTicket: serializer.fromJson<String?>(json['serviceTicket']),
      visitDate: serializer.fromJson<DateTime?>(json['visitDate']),
      status: serializer.fromJson<String?>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientUuid': serializer.toJson<String>(clientUuid),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'visitType': serializer.toJson<String?>(visitType),
      'summary': serializer.toJson<String?>(summary),
      'serviceTicket': serializer.toJson<String?>(serviceTicket),
      'visitDate': serializer.toJson<DateTime?>(visitDate),
      'status': serializer.toJson<String?>(status),
    };
  }

  Visit copyWith(
          {String? clientUuid,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          Value<String?> visitType = const Value.absent(),
          Value<String?> summary = const Value.absent(),
          Value<String?> serviceTicket = const Value.absent(),
          Value<DateTime?> visitDate = const Value.absent(),
          Value<String?> status = const Value.absent()}) =>
      Visit(
        clientUuid: clientUuid ?? this.clientUuid,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        visitType: visitType.present ? visitType.value : this.visitType,
        summary: summary.present ? summary.value : this.summary,
        serviceTicket:
            serviceTicket.present ? serviceTicket.value : this.serviceTicket,
        visitDate: visitDate.present ? visitDate.value : this.visitDate,
        status: status.present ? status.value : this.status,
      );
  Visit copyWithCompanion(VisitsCompanion data) {
    return Visit(
      clientUuid:
          data.clientUuid.present ? data.clientUuid.value : this.clientUuid,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      visitType: data.visitType.present ? data.visitType.value : this.visitType,
      summary: data.summary.present ? data.summary.value : this.summary,
      serviceTicket: data.serviceTicket.present
          ? data.serviceTicket.value
          : this.serviceTicket,
      visitDate: data.visitDate.present ? data.visitDate.value : this.visitDate,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Visit(')
          ..write('clientUuid: $clientUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('visitType: $visitType, ')
          ..write('summary: $summary, ')
          ..write('serviceTicket: $serviceTicket, ')
          ..write('visitDate: $visitDate, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clientUuid, riadVersion, riadDeleted,
      riadDeletedAt, visitType, summary, serviceTicket, visitDate, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Visit &&
          other.clientUuid == this.clientUuid &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.visitType == this.visitType &&
          other.summary == this.summary &&
          other.serviceTicket == this.serviceTicket &&
          other.visitDate == this.visitDate &&
          other.status == this.status);
}

class VisitsCompanion extends UpdateCompanion<Visit> {
  final Value<String> clientUuid;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String?> visitType;
  final Value<String?> summary;
  final Value<String?> serviceTicket;
  final Value<DateTime?> visitDate;
  final Value<String?> status;
  final Value<int> rowid;
  const VisitsCompanion({
    this.clientUuid = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.visitType = const Value.absent(),
    this.summary = const Value.absent(),
    this.serviceTicket = const Value.absent(),
    this.visitDate = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitsCompanion.insert({
    required String clientUuid,
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.visitType = const Value.absent(),
    this.summary = const Value.absent(),
    this.serviceTicket = const Value.absent(),
    this.visitDate = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientUuid = Value(clientUuid);
  static Insertable<Visit> custom({
    Expression<String>? clientUuid,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? visitType,
    Expression<String>? summary,
    Expression<String>? serviceTicket,
    Expression<DateTime>? visitDate,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (visitType != null) 'visit_type': visitType,
      if (summary != null) 'summary': summary,
      if (serviceTicket != null) 'service_ticket': serviceTicket,
      if (visitDate != null) 'visit_date': visitDate,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitsCompanion copyWith(
      {Value<String>? clientUuid,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String?>? visitType,
      Value<String?>? summary,
      Value<String?>? serviceTicket,
      Value<DateTime?>? visitDate,
      Value<String?>? status,
      Value<int>? rowid}) {
    return VisitsCompanion(
      clientUuid: clientUuid ?? this.clientUuid,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      visitType: visitType ?? this.visitType,
      summary: summary ?? this.summary,
      serviceTicket: serviceTicket ?? this.serviceTicket,
      visitDate: visitDate ?? this.visitDate,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
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
    if (visitType.present) {
      map['visit_type'] = Variable<String>(visitType.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (serviceTicket.present) {
      map['service_ticket'] = Variable<String>(serviceTicket.value);
    }
    if (visitDate.present) {
      map['visit_date'] = Variable<DateTime>(visitDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitsCompanion(')
          ..write('clientUuid: $clientUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('visitType: $visitType, ')
          ..write('summary: $summary, ')
          ..write('serviceTicket: $serviceTicket, ')
          ..write('visitDate: $visitDate, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitMaterialsTable extends VisitMaterials
    with TableInfo<$VisitMaterialsTable, VisitMaterial> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitMaterialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientUuidMeta =
      const VerificationMeta('clientUuid');
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
      'client_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _visitUuidMeta =
      const VerificationMeta('visitUuid');
  @override
  late final GeneratedColumn<String> visitUuid = GeneratedColumn<String>(
      'visit_uuid', aliasedName, false,
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
  static const VerificationMeta _itemNameMeta =
      const VerificationMeta('itemName');
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
      'item_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serialNoMeta =
      const VerificationMeta('serialNo');
  @override
  late final GeneratedColumn<String> serialNo = GeneratedColumn<String>(
      'serial_no', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
      'qty', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        clientUuid,
        visitUuid,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        itemName,
        serialNo,
        qty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visit_materials';
  @override
  VerificationContext validateIntegrity(Insertable<VisitMaterial> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_uuid')) {
      context.handle(
          _clientUuidMeta,
          clientUuid.isAcceptableOrUnknown(
              data['client_uuid']!, _clientUuidMeta));
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('visit_uuid')) {
      context.handle(_visitUuidMeta,
          visitUuid.isAcceptableOrUnknown(data['visit_uuid']!, _visitUuidMeta));
    } else if (isInserting) {
      context.missing(_visitUuidMeta);
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
    if (data.containsKey('item_name')) {
      context.handle(_itemNameMeta,
          itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta));
    }
    if (data.containsKey('serial_no')) {
      context.handle(_serialNoMeta,
          serialNo.isAcceptableOrUnknown(data['serial_no']!, _serialNoMeta));
    }
    if (data.containsKey('qty')) {
      context.handle(
          _qtyMeta, qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  VisitMaterial map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitMaterial(
      clientUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_uuid'])!,
      visitUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}visit_uuid'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      itemName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_name']),
      serialNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}serial_no']),
      qty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}qty'])!,
    );
  }

  @override
  $VisitMaterialsTable createAlias(String alias) {
    return $VisitMaterialsTable(attachedDatabase, alias);
  }
}

class VisitMaterial extends DataClass implements Insertable<VisitMaterial> {
  final String clientUuid;
  final String visitUuid;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String? itemName;
  final String? serialNo;
  final int qty;
  const VisitMaterial(
      {required this.clientUuid,
      required this.visitUuid,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      this.itemName,
      this.serialNo,
      required this.qty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_uuid'] = Variable<String>(clientUuid);
    map['visit_uuid'] = Variable<String>(visitUuid);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    if (!nullToAbsent || itemName != null) {
      map['item_name'] = Variable<String>(itemName);
    }
    if (!nullToAbsent || serialNo != null) {
      map['serial_no'] = Variable<String>(serialNo);
    }
    map['qty'] = Variable<int>(qty);
    return map;
  }

  VisitMaterialsCompanion toCompanion(bool nullToAbsent) {
    return VisitMaterialsCompanion(
      clientUuid: Value(clientUuid),
      visitUuid: Value(visitUuid),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      itemName: itemName == null && nullToAbsent
          ? const Value.absent()
          : Value(itemName),
      serialNo: serialNo == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNo),
      qty: Value(qty),
    );
  }

  factory VisitMaterial.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitMaterial(
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      visitUuid: serializer.fromJson<String>(json['visitUuid']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      itemName: serializer.fromJson<String?>(json['itemName']),
      serialNo: serializer.fromJson<String?>(json['serialNo']),
      qty: serializer.fromJson<int>(json['qty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientUuid': serializer.toJson<String>(clientUuid),
      'visitUuid': serializer.toJson<String>(visitUuid),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'itemName': serializer.toJson<String?>(itemName),
      'serialNo': serializer.toJson<String?>(serialNo),
      'qty': serializer.toJson<int>(qty),
    };
  }

  VisitMaterial copyWith(
          {String? clientUuid,
          String? visitUuid,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          Value<String?> itemName = const Value.absent(),
          Value<String?> serialNo = const Value.absent(),
          int? qty}) =>
      VisitMaterial(
        clientUuid: clientUuid ?? this.clientUuid,
        visitUuid: visitUuid ?? this.visitUuid,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        itemName: itemName.present ? itemName.value : this.itemName,
        serialNo: serialNo.present ? serialNo.value : this.serialNo,
        qty: qty ?? this.qty,
      );
  VisitMaterial copyWithCompanion(VisitMaterialsCompanion data) {
    return VisitMaterial(
      clientUuid:
          data.clientUuid.present ? data.clientUuid.value : this.clientUuid,
      visitUuid: data.visitUuid.present ? data.visitUuid.value : this.visitUuid,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      serialNo: data.serialNo.present ? data.serialNo.value : this.serialNo,
      qty: data.qty.present ? data.qty.value : this.qty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitMaterial(')
          ..write('clientUuid: $clientUuid, ')
          ..write('visitUuid: $visitUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('itemName: $itemName, ')
          ..write('serialNo: $serialNo, ')
          ..write('qty: $qty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clientUuid, visitUuid, riadVersion,
      riadDeleted, riadDeletedAt, itemName, serialNo, qty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitMaterial &&
          other.clientUuid == this.clientUuid &&
          other.visitUuid == this.visitUuid &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.itemName == this.itemName &&
          other.serialNo == this.serialNo &&
          other.qty == this.qty);
}

class VisitMaterialsCompanion extends UpdateCompanion<VisitMaterial> {
  final Value<String> clientUuid;
  final Value<String> visitUuid;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String?> itemName;
  final Value<String?> serialNo;
  final Value<int> qty;
  final Value<int> rowid;
  const VisitMaterialsCompanion({
    this.clientUuid = const Value.absent(),
    this.visitUuid = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.itemName = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.qty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitMaterialsCompanion.insert({
    required String clientUuid,
    required String visitUuid,
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.itemName = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.qty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : clientUuid = Value(clientUuid),
        visitUuid = Value(visitUuid);
  static Insertable<VisitMaterial> custom({
    Expression<String>? clientUuid,
    Expression<String>? visitUuid,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? itemName,
    Expression<String>? serialNo,
    Expression<int>? qty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (visitUuid != null) 'visit_uuid': visitUuid,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (itemName != null) 'item_name': itemName,
      if (serialNo != null) 'serial_no': serialNo,
      if (qty != null) 'qty': qty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitMaterialsCompanion copyWith(
      {Value<String>? clientUuid,
      Value<String>? visitUuid,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String?>? itemName,
      Value<String?>? serialNo,
      Value<int>? qty,
      Value<int>? rowid}) {
    return VisitMaterialsCompanion(
      clientUuid: clientUuid ?? this.clientUuid,
      visitUuid: visitUuid ?? this.visitUuid,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      itemName: itemName ?? this.itemName,
      serialNo: serialNo ?? this.serialNo,
      qty: qty ?? this.qty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (visitUuid.present) {
      map['visit_uuid'] = Variable<String>(visitUuid.value);
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
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (serialNo.present) {
      map['serial_no'] = Variable<String>(serialNo.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitMaterialsCompanion(')
          ..write('clientUuid: $clientUuid, ')
          ..write('visitUuid: $visitUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('itemName: $itemName, ')
          ..write('serialNo: $serialNo, ')
          ..write('qty: $qty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitPhotosTable extends VisitPhotos
    with TableInfo<$VisitPhotosTable, VisitPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientUuidMeta =
      const VerificationMeta('clientUuid');
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
      'client_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _visitUuidMeta =
      const VerificationMeta('visitUuid');
  @override
  late final GeneratedColumn<String> visitUuid = GeneratedColumn<String>(
      'visit_uuid', aliasedName, false,
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
  static const VerificationMeta _driveFileIdMeta =
      const VerificationMeta('driveFileId');
  @override
  late final GeneratedColumn<String> driveFileId = GeneratedColumn<String>(
      'drive_file_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        clientUuid,
        visitUuid,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        driveFileId,
        description
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visit_photos';
  @override
  VerificationContext validateIntegrity(Insertable<VisitPhoto> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_uuid')) {
      context.handle(
          _clientUuidMeta,
          clientUuid.isAcceptableOrUnknown(
              data['client_uuid']!, _clientUuidMeta));
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('visit_uuid')) {
      context.handle(_visitUuidMeta,
          visitUuid.isAcceptableOrUnknown(data['visit_uuid']!, _visitUuidMeta));
    } else if (isInserting) {
      context.missing(_visitUuidMeta);
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
    if (data.containsKey('drive_file_id')) {
      context.handle(
          _driveFileIdMeta,
          driveFileId.isAcceptableOrUnknown(
              data['drive_file_id']!, _driveFileIdMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  VisitPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitPhoto(
      clientUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_uuid'])!,
      visitUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}visit_uuid'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      driveFileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}drive_file_id']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
    );
  }

  @override
  $VisitPhotosTable createAlias(String alias) {
    return $VisitPhotosTable(attachedDatabase, alias);
  }
}

class VisitPhoto extends DataClass implements Insertable<VisitPhoto> {
  final String clientUuid;
  final String visitUuid;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String? driveFileId;
  final String? description;
  const VisitPhoto(
      {required this.clientUuid,
      required this.visitUuid,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      this.driveFileId,
      this.description});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_uuid'] = Variable<String>(clientUuid);
    map['visit_uuid'] = Variable<String>(visitUuid);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    if (!nullToAbsent || driveFileId != null) {
      map['drive_file_id'] = Variable<String>(driveFileId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  VisitPhotosCompanion toCompanion(bool nullToAbsent) {
    return VisitPhotosCompanion(
      clientUuid: Value(clientUuid),
      visitUuid: Value(visitUuid),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      driveFileId: driveFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(driveFileId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory VisitPhoto.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitPhoto(
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      visitUuid: serializer.fromJson<String>(json['visitUuid']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      driveFileId: serializer.fromJson<String?>(json['driveFileId']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientUuid': serializer.toJson<String>(clientUuid),
      'visitUuid': serializer.toJson<String>(visitUuid),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'driveFileId': serializer.toJson<String?>(driveFileId),
      'description': serializer.toJson<String?>(description),
    };
  }

  VisitPhoto copyWith(
          {String? clientUuid,
          String? visitUuid,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          Value<String?> driveFileId = const Value.absent(),
          Value<String?> description = const Value.absent()}) =>
      VisitPhoto(
        clientUuid: clientUuid ?? this.clientUuid,
        visitUuid: visitUuid ?? this.visitUuid,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        driveFileId: driveFileId.present ? driveFileId.value : this.driveFileId,
        description: description.present ? description.value : this.description,
      );
  VisitPhoto copyWithCompanion(VisitPhotosCompanion data) {
    return VisitPhoto(
      clientUuid:
          data.clientUuid.present ? data.clientUuid.value : this.clientUuid,
      visitUuid: data.visitUuid.present ? data.visitUuid.value : this.visitUuid,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      driveFileId:
          data.driveFileId.present ? data.driveFileId.value : this.driveFileId,
      description:
          data.description.present ? data.description.value : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitPhoto(')
          ..write('clientUuid: $clientUuid, ')
          ..write('visitUuid: $visitUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('driveFileId: $driveFileId, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clientUuid, visitUuid, riadVersion,
      riadDeleted, riadDeletedAt, driveFileId, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitPhoto &&
          other.clientUuid == this.clientUuid &&
          other.visitUuid == this.visitUuid &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.driveFileId == this.driveFileId &&
          other.description == this.description);
}

class VisitPhotosCompanion extends UpdateCompanion<VisitPhoto> {
  final Value<String> clientUuid;
  final Value<String> visitUuid;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String?> driveFileId;
  final Value<String?> description;
  final Value<int> rowid;
  const VisitPhotosCompanion({
    this.clientUuid = const Value.absent(),
    this.visitUuid = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.driveFileId = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitPhotosCompanion.insert({
    required String clientUuid,
    required String visitUuid,
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.driveFileId = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : clientUuid = Value(clientUuid),
        visitUuid = Value(visitUuid);
  static Insertable<VisitPhoto> custom({
    Expression<String>? clientUuid,
    Expression<String>? visitUuid,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? driveFileId,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (visitUuid != null) 'visit_uuid': visitUuid,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (driveFileId != null) 'drive_file_id': driveFileId,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitPhotosCompanion copyWith(
      {Value<String>? clientUuid,
      Value<String>? visitUuid,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String?>? driveFileId,
      Value<String?>? description,
      Value<int>? rowid}) {
    return VisitPhotosCompanion(
      clientUuid: clientUuid ?? this.clientUuid,
      visitUuid: visitUuid ?? this.visitUuid,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      driveFileId: driveFileId ?? this.driveFileId,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (visitUuid.present) {
      map['visit_uuid'] = Variable<String>(visitUuid.value);
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
    if (driveFileId.present) {
      map['drive_file_id'] = Variable<String>(driveFileId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitPhotosCompanion(')
          ..write('clientUuid: $clientUuid, ')
          ..write('visitUuid: $visitUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('driveFileId: $driveFileId, ')
          ..write('description: $description, ')
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
  static const VerificationMeta _clientUuidMeta =
      const VerificationMeta('clientUuid');
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
      'client_uuid', aliasedName, false,
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
  static const VerificationMeta _templateMeta =
      const VerificationMeta('template');
  @override
  late final GeneratedColumn<String> template = GeneratedColumn<String>(
      'template', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _passportMeta =
      const VerificationMeta('passport');
  @override
  late final GeneratedColumn<String> passport = GeneratedColumn<String>(
      'passport', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _visitMeta = const VerificationMeta('visit');
  @override
  late final GeneratedColumn<String> visit = GeneratedColumn<String>(
      'visit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        clientUuid,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        template,
        passport,
        visit,
        status
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
    if (data.containsKey('client_uuid')) {
      context.handle(
          _clientUuidMeta,
          clientUuid.isAcceptableOrUnknown(
              data['client_uuid']!, _clientUuidMeta));
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
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
    if (data.containsKey('template')) {
      context.handle(_templateMeta,
          template.isAcceptableOrUnknown(data['template']!, _templateMeta));
    }
    if (data.containsKey('passport')) {
      context.handle(_passportMeta,
          passport.isAcceptableOrUnknown(data['passport']!, _passportMeta));
    }
    if (data.containsKey('visit')) {
      context.handle(
          _visitMeta, visit.isAcceptableOrUnknown(data['visit']!, _visitMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  ChecklistInstance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistInstance(
      clientUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_uuid'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      template: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template']),
      passport: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}passport']),
      visit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}visit']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status']),
    );
  }

  @override
  $ChecklistInstancesTable createAlias(String alias) {
    return $ChecklistInstancesTable(attachedDatabase, alias);
  }
}

class ChecklistInstance extends DataClass
    implements Insertable<ChecklistInstance> {
  final String clientUuid;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String? template;
  final String? passport;
  final String? visit;
  final String? status;
  const ChecklistInstance(
      {required this.clientUuid,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      this.template,
      this.passport,
      this.visit,
      this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_uuid'] = Variable<String>(clientUuid);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    if (!nullToAbsent || template != null) {
      map['template'] = Variable<String>(template);
    }
    if (!nullToAbsent || passport != null) {
      map['passport'] = Variable<String>(passport);
    }
    if (!nullToAbsent || visit != null) {
      map['visit'] = Variable<String>(visit);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    return map;
  }

  ChecklistInstancesCompanion toCompanion(bool nullToAbsent) {
    return ChecklistInstancesCompanion(
      clientUuid: Value(clientUuid),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      template: template == null && nullToAbsent
          ? const Value.absent()
          : Value(template),
      passport: passport == null && nullToAbsent
          ? const Value.absent()
          : Value(passport),
      visit:
          visit == null && nullToAbsent ? const Value.absent() : Value(visit),
      status:
          status == null && nullToAbsent ? const Value.absent() : Value(status),
    );
  }

  factory ChecklistInstance.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistInstance(
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      template: serializer.fromJson<String?>(json['template']),
      passport: serializer.fromJson<String?>(json['passport']),
      visit: serializer.fromJson<String?>(json['visit']),
      status: serializer.fromJson<String?>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientUuid': serializer.toJson<String>(clientUuid),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'template': serializer.toJson<String?>(template),
      'passport': serializer.toJson<String?>(passport),
      'visit': serializer.toJson<String?>(visit),
      'status': serializer.toJson<String?>(status),
    };
  }

  ChecklistInstance copyWith(
          {String? clientUuid,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          Value<String?> template = const Value.absent(),
          Value<String?> passport = const Value.absent(),
          Value<String?> visit = const Value.absent(),
          Value<String?> status = const Value.absent()}) =>
      ChecklistInstance(
        clientUuid: clientUuid ?? this.clientUuid,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        template: template.present ? template.value : this.template,
        passport: passport.present ? passport.value : this.passport,
        visit: visit.present ? visit.value : this.visit,
        status: status.present ? status.value : this.status,
      );
  ChecklistInstance copyWithCompanion(ChecklistInstancesCompanion data) {
    return ChecklistInstance(
      clientUuid:
          data.clientUuid.present ? data.clientUuid.value : this.clientUuid,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      template: data.template.present ? data.template.value : this.template,
      passport: data.passport.present ? data.passport.value : this.passport,
      visit: data.visit.present ? data.visit.value : this.visit,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistInstance(')
          ..write('clientUuid: $clientUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('template: $template, ')
          ..write('passport: $passport, ')
          ..write('visit: $visit, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clientUuid, riadVersion, riadDeleted,
      riadDeletedAt, template, passport, visit, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistInstance &&
          other.clientUuid == this.clientUuid &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.template == this.template &&
          other.passport == this.passport &&
          other.visit == this.visit &&
          other.status == this.status);
}

class ChecklistInstancesCompanion extends UpdateCompanion<ChecklistInstance> {
  final Value<String> clientUuid;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String?> template;
  final Value<String?> passport;
  final Value<String?> visit;
  final Value<String?> status;
  final Value<int> rowid;
  const ChecklistInstancesCompanion({
    this.clientUuid = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.template = const Value.absent(),
    this.passport = const Value.absent(),
    this.visit = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistInstancesCompanion.insert({
    required String clientUuid,
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.template = const Value.absent(),
    this.passport = const Value.absent(),
    this.visit = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientUuid = Value(clientUuid);
  static Insertable<ChecklistInstance> custom({
    Expression<String>? clientUuid,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? template,
    Expression<String>? passport,
    Expression<String>? visit,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (template != null) 'template': template,
      if (passport != null) 'passport': passport,
      if (visit != null) 'visit': visit,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistInstancesCompanion copyWith(
      {Value<String>? clientUuid,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String?>? template,
      Value<String?>? passport,
      Value<String?>? visit,
      Value<String?>? status,
      Value<int>? rowid}) {
    return ChecklistInstancesCompanion(
      clientUuid: clientUuid ?? this.clientUuid,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      template: template ?? this.template,
      passport: passport ?? this.passport,
      visit: visit ?? this.visit,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
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
    if (template.present) {
      map['template'] = Variable<String>(template.value);
    }
    if (passport.present) {
      map['passport'] = Variable<String>(passport.value);
    }
    if (visit.present) {
      map['visit'] = Variable<String>(visit.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistInstancesCompanion(')
          ..write('clientUuid: $clientUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('template: $template, ')
          ..write('passport: $passport, ')
          ..write('visit: $visit, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChecklistInstanceItemsTable extends ChecklistInstanceItems
    with TableInfo<$ChecklistInstanceItemsTable, ChecklistInstanceItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistInstanceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemUuidMeta =
      const VerificationMeta('itemUuid');
  @override
  late final GeneratedColumn<String> itemUuid = GeneratedColumn<String>(
      'item_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _instanceUuidMeta =
      const VerificationMeta('instanceUuid');
  @override
  late final GeneratedColumn<String> instanceUuid = GeneratedColumn<String>(
      'instance_uuid', aliasedName, false,
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
  static const VerificationMeta _checkedByMeta =
      const VerificationMeta('checkedBy');
  @override
  late final GeneratedColumn<String> checkedBy = GeneratedColumn<String>(
      'checked_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<String> photo = GeneratedColumn<String>(
      'photo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serialNoMeta =
      const VerificationMeta('serialNo');
  @override
  late final GeneratedColumn<String> serialNo = GeneratedColumn<String>(
      'serial_no', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        itemUuid,
        instanceUuid,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        checkedBy,
        photo,
        value,
        serialNo
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_instance_items';
  @override
  VerificationContext validateIntegrity(
      Insertable<ChecklistInstanceItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_uuid')) {
      context.handle(_itemUuidMeta,
          itemUuid.isAcceptableOrUnknown(data['item_uuid']!, _itemUuidMeta));
    } else if (isInserting) {
      context.missing(_itemUuidMeta);
    }
    if (data.containsKey('instance_uuid')) {
      context.handle(
          _instanceUuidMeta,
          instanceUuid.isAcceptableOrUnknown(
              data['instance_uuid']!, _instanceUuidMeta));
    } else if (isInserting) {
      context.missing(_instanceUuidMeta);
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
    if (data.containsKey('checked_by')) {
      context.handle(_checkedByMeta,
          checkedBy.isAcceptableOrUnknown(data['checked_by']!, _checkedByMeta));
    }
    if (data.containsKey('photo')) {
      context.handle(
          _photoMeta, photo.isAcceptableOrUnknown(data['photo']!, _photoMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('serial_no')) {
      context.handle(_serialNoMeta,
          serialNo.isAcceptableOrUnknown(data['serial_no']!, _serialNoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemUuid};
  @override
  ChecklistInstanceItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistInstanceItem(
      itemUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_uuid'])!,
      instanceUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}instance_uuid'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      checkedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checked_by']),
      photo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo']),
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
      serialNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}serial_no']),
    );
  }

  @override
  $ChecklistInstanceItemsTable createAlias(String alias) {
    return $ChecklistInstanceItemsTable(attachedDatabase, alias);
  }
}

class ChecklistInstanceItem extends DataClass
    implements Insertable<ChecklistInstanceItem> {
  final String itemUuid;
  final String instanceUuid;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String? checkedBy;
  final String? photo;
  final String? value;
  final String? serialNo;
  const ChecklistInstanceItem(
      {required this.itemUuid,
      required this.instanceUuid,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      this.checkedBy,
      this.photo,
      this.value,
      this.serialNo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_uuid'] = Variable<String>(itemUuid);
    map['instance_uuid'] = Variable<String>(instanceUuid);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    if (!nullToAbsent || checkedBy != null) {
      map['checked_by'] = Variable<String>(checkedBy);
    }
    if (!nullToAbsent || photo != null) {
      map['photo'] = Variable<String>(photo);
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    if (!nullToAbsent || serialNo != null) {
      map['serial_no'] = Variable<String>(serialNo);
    }
    return map;
  }

  ChecklistInstanceItemsCompanion toCompanion(bool nullToAbsent) {
    return ChecklistInstanceItemsCompanion(
      itemUuid: Value(itemUuid),
      instanceUuid: Value(instanceUuid),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      checkedBy: checkedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedBy),
      photo:
          photo == null && nullToAbsent ? const Value.absent() : Value(photo),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      serialNo: serialNo == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNo),
    );
  }

  factory ChecklistInstanceItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistInstanceItem(
      itemUuid: serializer.fromJson<String>(json['itemUuid']),
      instanceUuid: serializer.fromJson<String>(json['instanceUuid']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      checkedBy: serializer.fromJson<String?>(json['checkedBy']),
      photo: serializer.fromJson<String?>(json['photo']),
      value: serializer.fromJson<String?>(json['value']),
      serialNo: serializer.fromJson<String?>(json['serialNo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemUuid': serializer.toJson<String>(itemUuid),
      'instanceUuid': serializer.toJson<String>(instanceUuid),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'checkedBy': serializer.toJson<String?>(checkedBy),
      'photo': serializer.toJson<String?>(photo),
      'value': serializer.toJson<String?>(value),
      'serialNo': serializer.toJson<String?>(serialNo),
    };
  }

  ChecklistInstanceItem copyWith(
          {String? itemUuid,
          String? instanceUuid,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          Value<String?> checkedBy = const Value.absent(),
          Value<String?> photo = const Value.absent(),
          Value<String?> value = const Value.absent(),
          Value<String?> serialNo = const Value.absent()}) =>
      ChecklistInstanceItem(
        itemUuid: itemUuid ?? this.itemUuid,
        instanceUuid: instanceUuid ?? this.instanceUuid,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        checkedBy: checkedBy.present ? checkedBy.value : this.checkedBy,
        photo: photo.present ? photo.value : this.photo,
        value: value.present ? value.value : this.value,
        serialNo: serialNo.present ? serialNo.value : this.serialNo,
      );
  ChecklistInstanceItem copyWithCompanion(
      ChecklistInstanceItemsCompanion data) {
    return ChecklistInstanceItem(
      itemUuid: data.itemUuid.present ? data.itemUuid.value : this.itemUuid,
      instanceUuid: data.instanceUuid.present
          ? data.instanceUuid.value
          : this.instanceUuid,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      checkedBy: data.checkedBy.present ? data.checkedBy.value : this.checkedBy,
      photo: data.photo.present ? data.photo.value : this.photo,
      value: data.value.present ? data.value.value : this.value,
      serialNo: data.serialNo.present ? data.serialNo.value : this.serialNo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistInstanceItem(')
          ..write('itemUuid: $itemUuid, ')
          ..write('instanceUuid: $instanceUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('checkedBy: $checkedBy, ')
          ..write('photo: $photo, ')
          ..write('value: $value, ')
          ..write('serialNo: $serialNo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemUuid, instanceUuid, riadVersion,
      riadDeleted, riadDeletedAt, checkedBy, photo, value, serialNo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistInstanceItem &&
          other.itemUuid == this.itemUuid &&
          other.instanceUuid == this.instanceUuid &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.checkedBy == this.checkedBy &&
          other.photo == this.photo &&
          other.value == this.value &&
          other.serialNo == this.serialNo);
}

class ChecklistInstanceItemsCompanion
    extends UpdateCompanion<ChecklistInstanceItem> {
  final Value<String> itemUuid;
  final Value<String> instanceUuid;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String?> checkedBy;
  final Value<String?> photo;
  final Value<String?> value;
  final Value<String?> serialNo;
  final Value<int> rowid;
  const ChecklistInstanceItemsCompanion({
    this.itemUuid = const Value.absent(),
    this.instanceUuid = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.checkedBy = const Value.absent(),
    this.photo = const Value.absent(),
    this.value = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistInstanceItemsCompanion.insert({
    required String itemUuid,
    required String instanceUuid,
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.checkedBy = const Value.absent(),
    this.photo = const Value.absent(),
    this.value = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : itemUuid = Value(itemUuid),
        instanceUuid = Value(instanceUuid);
  static Insertable<ChecklistInstanceItem> custom({
    Expression<String>? itemUuid,
    Expression<String>? instanceUuid,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? checkedBy,
    Expression<String>? photo,
    Expression<String>? value,
    Expression<String>? serialNo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemUuid != null) 'item_uuid': itemUuid,
      if (instanceUuid != null) 'instance_uuid': instanceUuid,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (checkedBy != null) 'checked_by': checkedBy,
      if (photo != null) 'photo': photo,
      if (value != null) 'value': value,
      if (serialNo != null) 'serial_no': serialNo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistInstanceItemsCompanion copyWith(
      {Value<String>? itemUuid,
      Value<String>? instanceUuid,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String?>? checkedBy,
      Value<String?>? photo,
      Value<String?>? value,
      Value<String?>? serialNo,
      Value<int>? rowid}) {
    return ChecklistInstanceItemsCompanion(
      itemUuid: itemUuid ?? this.itemUuid,
      instanceUuid: instanceUuid ?? this.instanceUuid,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      checkedBy: checkedBy ?? this.checkedBy,
      photo: photo ?? this.photo,
      value: value ?? this.value,
      serialNo: serialNo ?? this.serialNo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemUuid.present) {
      map['item_uuid'] = Variable<String>(itemUuid.value);
    }
    if (instanceUuid.present) {
      map['instance_uuid'] = Variable<String>(instanceUuid.value);
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
    if (checkedBy.present) {
      map['checked_by'] = Variable<String>(checkedBy.value);
    }
    if (photo.present) {
      map['photo'] = Variable<String>(photo.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (serialNo.present) {
      map['serial_no'] = Variable<String>(serialNo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistInstanceItemsCompanion(')
          ..write('itemUuid: $itemUuid, ')
          ..write('instanceUuid: $instanceUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('checkedBy: $checkedBy, ')
          ..write('photo: $photo, ')
          ..write('value: $value, ')
          ..write('serialNo: $serialNo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstallationMapsTable extends InstallationMaps
    with TableInfo<$InstallationMapsTable, InstallationMap> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstallationMapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientUuidMeta =
      const VerificationMeta('clientUuid');
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
      'client_uuid', aliasedName, false,
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
  static const VerificationMeta _passportMeta =
      const VerificationMeta('passport');
  @override
  late final GeneratedColumn<String> passport = GeneratedColumn<String>(
      'passport', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _name_Meta = const VerificationMeta('name_');
  @override
  late final GeneratedColumn<String> name_ = GeneratedColumn<String>(
      'name_', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [clientUuid, riadVersion, riadDeleted, riadDeletedAt, passport, name_];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installation_maps';
  @override
  VerificationContext validateIntegrity(Insertable<InstallationMap> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_uuid')) {
      context.handle(
          _clientUuidMeta,
          clientUuid.isAcceptableOrUnknown(
              data['client_uuid']!, _clientUuidMeta));
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
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
    if (data.containsKey('passport')) {
      context.handle(_passportMeta,
          passport.isAcceptableOrUnknown(data['passport']!, _passportMeta));
    }
    if (data.containsKey('name_')) {
      context.handle(
          _name_Meta, name_.isAcceptableOrUnknown(data['name_']!, _name_Meta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  InstallationMap map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstallationMap(
      clientUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_uuid'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      passport: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}passport']),
      name_: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_']),
    );
  }

  @override
  $InstallationMapsTable createAlias(String alias) {
    return $InstallationMapsTable(attachedDatabase, alias);
  }
}

class InstallationMap extends DataClass implements Insertable<InstallationMap> {
  final String clientUuid;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String? passport;
  final String? name_;
  const InstallationMap(
      {required this.clientUuid,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      this.passport,
      this.name_});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_uuid'] = Variable<String>(clientUuid);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    if (!nullToAbsent || passport != null) {
      map['passport'] = Variable<String>(passport);
    }
    if (!nullToAbsent || name_ != null) {
      map['name_'] = Variable<String>(name_);
    }
    return map;
  }

  InstallationMapsCompanion toCompanion(bool nullToAbsent) {
    return InstallationMapsCompanion(
      clientUuid: Value(clientUuid),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      passport: passport == null && nullToAbsent
          ? const Value.absent()
          : Value(passport),
      name_:
          name_ == null && nullToAbsent ? const Value.absent() : Value(name_),
    );
  }

  factory InstallationMap.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstallationMap(
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      passport: serializer.fromJson<String?>(json['passport']),
      name_: serializer.fromJson<String?>(json['name_']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientUuid': serializer.toJson<String>(clientUuid),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'passport': serializer.toJson<String?>(passport),
      'name_': serializer.toJson<String?>(name_),
    };
  }

  InstallationMap copyWith(
          {String? clientUuid,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          Value<String?> passport = const Value.absent(),
          Value<String?> name_ = const Value.absent()}) =>
      InstallationMap(
        clientUuid: clientUuid ?? this.clientUuid,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        passport: passport.present ? passport.value : this.passport,
        name_: name_.present ? name_.value : this.name_,
      );
  InstallationMap copyWithCompanion(InstallationMapsCompanion data) {
    return InstallationMap(
      clientUuid:
          data.clientUuid.present ? data.clientUuid.value : this.clientUuid,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      passport: data.passport.present ? data.passport.value : this.passport,
      name_: data.name_.present ? data.name_.value : this.name_,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstallationMap(')
          ..write('clientUuid: $clientUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('passport: $passport, ')
          ..write('name_: $name_')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      clientUuid, riadVersion, riadDeleted, riadDeletedAt, passport, name_);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstallationMap &&
          other.clientUuid == this.clientUuid &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.passport == this.passport &&
          other.name_ == this.name_);
}

class InstallationMapsCompanion extends UpdateCompanion<InstallationMap> {
  final Value<String> clientUuid;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String?> passport;
  final Value<String?> name_;
  final Value<int> rowid;
  const InstallationMapsCompanion({
    this.clientUuid = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.passport = const Value.absent(),
    this.name_ = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstallationMapsCompanion.insert({
    required String clientUuid,
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.passport = const Value.absent(),
    this.name_ = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientUuid = Value(clientUuid);
  static Insertable<InstallationMap> custom({
    Expression<String>? clientUuid,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? passport,
    Expression<String>? name_,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (passport != null) 'passport': passport,
      if (name_ != null) 'name_': name_,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstallationMapsCompanion copyWith(
      {Value<String>? clientUuid,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String?>? passport,
      Value<String?>? name_,
      Value<int>? rowid}) {
    return InstallationMapsCompanion(
      clientUuid: clientUuid ?? this.clientUuid,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      passport: passport ?? this.passport,
      name_: name_ ?? this.name_,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
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
    if (passport.present) {
      map['passport'] = Variable<String>(passport.value);
    }
    if (name_.present) {
      map['name_'] = Variable<String>(name_.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstallationMapsCompanion(')
          ..write('clientUuid: $clientUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('passport: $passport, ')
          ..write('name_: $name_, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MountPointsTable extends MountPoints
    with TableInfo<$MountPointsTable, MountPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MountPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pointUuidMeta =
      const VerificationMeta('pointUuid');
  @override
  late final GeneratedColumn<String> pointUuid = GeneratedColumn<String>(
      'point_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mapUuidMeta =
      const VerificationMeta('mapUuid');
  @override
  late final GeneratedColumn<String> mapUuid = GeneratedColumn<String>(
      'map_uuid', aliasedName, false,
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _itemMeta = const VerificationMeta('item');
  @override
  late final GeneratedColumn<String> item = GeneratedColumn<String>(
      'item', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serialNoMeta =
      const VerificationMeta('serialNo');
  @override
  late final GeneratedColumn<String> serialNo = GeneratedColumn<String>(
      'serial_no', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<String> photo = GeneratedColumn<String>(
      'photo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        pointUuid,
        mapUuid,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        type,
        label,
        x,
        y,
        status,
        item,
        serialNo,
        photo
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mount_points';
  @override
  VerificationContext validateIntegrity(Insertable<MountPoint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('point_uuid')) {
      context.handle(_pointUuidMeta,
          pointUuid.isAcceptableOrUnknown(data['point_uuid']!, _pointUuidMeta));
    } else if (isInserting) {
      context.missing(_pointUuidMeta);
    }
    if (data.containsKey('map_uuid')) {
      context.handle(_mapUuidMeta,
          mapUuid.isAcceptableOrUnknown(data['map_uuid']!, _mapUuidMeta));
    } else if (isInserting) {
      context.missing(_mapUuidMeta);
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
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('item')) {
      context.handle(
          _itemMeta, item.isAcceptableOrUnknown(data['item']!, _itemMeta));
    }
    if (data.containsKey('serial_no')) {
      context.handle(_serialNoMeta,
          serialNo.isAcceptableOrUnknown(data['serial_no']!, _serialNoMeta));
    }
    if (data.containsKey('photo')) {
      context.handle(
          _photoMeta, photo.isAcceptableOrUnknown(data['photo']!, _photoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pointUuid};
  @override
  MountPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MountPoint(
      pointUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}point_uuid'])!,
      mapUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}map_uuid'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type']),
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label']),
      x: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}x']),
      y: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}y']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status']),
      item: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item']),
      serialNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}serial_no']),
      photo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo']),
    );
  }

  @override
  $MountPointsTable createAlias(String alias) {
    return $MountPointsTable(attachedDatabase, alias);
  }
}

class MountPoint extends DataClass implements Insertable<MountPoint> {
  final String pointUuid;
  final String mapUuid;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String? type;
  final String? label;
  final double? x;
  final double? y;
  final String? status;
  final String? item;
  final String? serialNo;
  final String? photo;
  const MountPoint(
      {required this.pointUuid,
      required this.mapUuid,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      this.type,
      this.label,
      this.x,
      this.y,
      this.status,
      this.item,
      this.serialNo,
      this.photo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['point_uuid'] = Variable<String>(pointUuid);
    map['map_uuid'] = Variable<String>(mapUuid);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || x != null) {
      map['x'] = Variable<double>(x);
    }
    if (!nullToAbsent || y != null) {
      map['y'] = Variable<double>(y);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || item != null) {
      map['item'] = Variable<String>(item);
    }
    if (!nullToAbsent || serialNo != null) {
      map['serial_no'] = Variable<String>(serialNo);
    }
    if (!nullToAbsent || photo != null) {
      map['photo'] = Variable<String>(photo);
    }
    return map;
  }

  MountPointsCompanion toCompanion(bool nullToAbsent) {
    return MountPointsCompanion(
      pointUuid: Value(pointUuid),
      mapUuid: Value(mapUuid),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      label:
          label == null && nullToAbsent ? const Value.absent() : Value(label),
      x: x == null && nullToAbsent ? const Value.absent() : Value(x),
      y: y == null && nullToAbsent ? const Value.absent() : Value(y),
      status:
          status == null && nullToAbsent ? const Value.absent() : Value(status),
      item: item == null && nullToAbsent ? const Value.absent() : Value(item),
      serialNo: serialNo == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNo),
      photo:
          photo == null && nullToAbsent ? const Value.absent() : Value(photo),
    );
  }

  factory MountPoint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MountPoint(
      pointUuid: serializer.fromJson<String>(json['pointUuid']),
      mapUuid: serializer.fromJson<String>(json['mapUuid']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      type: serializer.fromJson<String?>(json['type']),
      label: serializer.fromJson<String?>(json['label']),
      x: serializer.fromJson<double?>(json['x']),
      y: serializer.fromJson<double?>(json['y']),
      status: serializer.fromJson<String?>(json['status']),
      item: serializer.fromJson<String?>(json['item']),
      serialNo: serializer.fromJson<String?>(json['serialNo']),
      photo: serializer.fromJson<String?>(json['photo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pointUuid': serializer.toJson<String>(pointUuid),
      'mapUuid': serializer.toJson<String>(mapUuid),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'type': serializer.toJson<String?>(type),
      'label': serializer.toJson<String?>(label),
      'x': serializer.toJson<double?>(x),
      'y': serializer.toJson<double?>(y),
      'status': serializer.toJson<String?>(status),
      'item': serializer.toJson<String?>(item),
      'serialNo': serializer.toJson<String?>(serialNo),
      'photo': serializer.toJson<String?>(photo),
    };
  }

  MountPoint copyWith(
          {String? pointUuid,
          String? mapUuid,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          Value<String?> type = const Value.absent(),
          Value<String?> label = const Value.absent(),
          Value<double?> x = const Value.absent(),
          Value<double?> y = const Value.absent(),
          Value<String?> status = const Value.absent(),
          Value<String?> item = const Value.absent(),
          Value<String?> serialNo = const Value.absent(),
          Value<String?> photo = const Value.absent()}) =>
      MountPoint(
        pointUuid: pointUuid ?? this.pointUuid,
        mapUuid: mapUuid ?? this.mapUuid,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        type: type.present ? type.value : this.type,
        label: label.present ? label.value : this.label,
        x: x.present ? x.value : this.x,
        y: y.present ? y.value : this.y,
        status: status.present ? status.value : this.status,
        item: item.present ? item.value : this.item,
        serialNo: serialNo.present ? serialNo.value : this.serialNo,
        photo: photo.present ? photo.value : this.photo,
      );
  MountPoint copyWithCompanion(MountPointsCompanion data) {
    return MountPoint(
      pointUuid: data.pointUuid.present ? data.pointUuid.value : this.pointUuid,
      mapUuid: data.mapUuid.present ? data.mapUuid.value : this.mapUuid,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      type: data.type.present ? data.type.value : this.type,
      label: data.label.present ? data.label.value : this.label,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      status: data.status.present ? data.status.value : this.status,
      item: data.item.present ? data.item.value : this.item,
      serialNo: data.serialNo.present ? data.serialNo.value : this.serialNo,
      photo: data.photo.present ? data.photo.value : this.photo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MountPoint(')
          ..write('pointUuid: $pointUuid, ')
          ..write('mapUuid: $mapUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('status: $status, ')
          ..write('item: $item, ')
          ..write('serialNo: $serialNo, ')
          ..write('photo: $photo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pointUuid, mapUuid, riadVersion, riadDeleted,
      riadDeletedAt, type, label, x, y, status, item, serialNo, photo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MountPoint &&
          other.pointUuid == this.pointUuid &&
          other.mapUuid == this.mapUuid &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.type == this.type &&
          other.label == this.label &&
          other.x == this.x &&
          other.y == this.y &&
          other.status == this.status &&
          other.item == this.item &&
          other.serialNo == this.serialNo &&
          other.photo == this.photo);
}

class MountPointsCompanion extends UpdateCompanion<MountPoint> {
  final Value<String> pointUuid;
  final Value<String> mapUuid;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String?> type;
  final Value<String?> label;
  final Value<double?> x;
  final Value<double?> y;
  final Value<String?> status;
  final Value<String?> item;
  final Value<String?> serialNo;
  final Value<String?> photo;
  final Value<int> rowid;
  const MountPointsCompanion({
    this.pointUuid = const Value.absent(),
    this.mapUuid = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.type = const Value.absent(),
    this.label = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.status = const Value.absent(),
    this.item = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.photo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MountPointsCompanion.insert({
    required String pointUuid,
    required String mapUuid,
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.type = const Value.absent(),
    this.label = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.status = const Value.absent(),
    this.item = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.photo = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : pointUuid = Value(pointUuid),
        mapUuid = Value(mapUuid);
  static Insertable<MountPoint> custom({
    Expression<String>? pointUuid,
    Expression<String>? mapUuid,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? type,
    Expression<String>? label,
    Expression<double>? x,
    Expression<double>? y,
    Expression<String>? status,
    Expression<String>? item,
    Expression<String>? serialNo,
    Expression<String>? photo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pointUuid != null) 'point_uuid': pointUuid,
      if (mapUuid != null) 'map_uuid': mapUuid,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (type != null) 'type': type,
      if (label != null) 'label': label,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (status != null) 'status': status,
      if (item != null) 'item': item,
      if (serialNo != null) 'serial_no': serialNo,
      if (photo != null) 'photo': photo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MountPointsCompanion copyWith(
      {Value<String>? pointUuid,
      Value<String>? mapUuid,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String?>? type,
      Value<String?>? label,
      Value<double?>? x,
      Value<double?>? y,
      Value<String?>? status,
      Value<String?>? item,
      Value<String?>? serialNo,
      Value<String?>? photo,
      Value<int>? rowid}) {
    return MountPointsCompanion(
      pointUuid: pointUuid ?? this.pointUuid,
      mapUuid: mapUuid ?? this.mapUuid,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      type: type ?? this.type,
      label: label ?? this.label,
      x: x ?? this.x,
      y: y ?? this.y,
      status: status ?? this.status,
      item: item ?? this.item,
      serialNo: serialNo ?? this.serialNo,
      photo: photo ?? this.photo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pointUuid.present) {
      map['point_uuid'] = Variable<String>(pointUuid.value);
    }
    if (mapUuid.present) {
      map['map_uuid'] = Variable<String>(mapUuid.value);
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (item.present) {
      map['item'] = Variable<String>(item.value);
    }
    if (serialNo.present) {
      map['serial_no'] = Variable<String>(serialNo.value);
    }
    if (photo.present) {
      map['photo'] = Variable<String>(photo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MountPointsCompanion(')
          ..write('pointUuid: $pointUuid, ')
          ..write('mapUuid: $mapUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('status: $status, ')
          ..write('item: $item, ')
          ..write('serialNo: $serialNo, ')
          ..write('photo: $photo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CableRoutesTable extends CableRoutes
    with TableInfo<$CableRoutesTable, CableRoute> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CableRoutesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _routeUuidMeta =
      const VerificationMeta('routeUuid');
  @override
  late final GeneratedColumn<String> routeUuid = GeneratedColumn<String>(
      'route_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mapUuidMeta =
      const VerificationMeta('mapUuid');
  @override
  late final GeneratedColumn<String> mapUuid = GeneratedColumn<String>(
      'map_uuid', aliasedName, false,
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
  static const VerificationMeta _fromPointMeta =
      const VerificationMeta('fromPoint');
  @override
  late final GeneratedColumn<String> fromPoint = GeneratedColumn<String>(
      'from_point', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _toPointMeta =
      const VerificationMeta('toPoint');
  @override
  late final GeneratedColumn<String> toPoint = GeneratedColumn<String>(
      'to_point', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pathJsonMeta =
      const VerificationMeta('pathJson');
  @override
  late final GeneratedColumn<String> pathJson = GeneratedColumn<String>(
      'path_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        routeUuid,
        mapUuid,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        fromPoint,
        toPoint,
        pathJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cable_routes';
  @override
  VerificationContext validateIntegrity(Insertable<CableRoute> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('route_uuid')) {
      context.handle(_routeUuidMeta,
          routeUuid.isAcceptableOrUnknown(data['route_uuid']!, _routeUuidMeta));
    } else if (isInserting) {
      context.missing(_routeUuidMeta);
    }
    if (data.containsKey('map_uuid')) {
      context.handle(_mapUuidMeta,
          mapUuid.isAcceptableOrUnknown(data['map_uuid']!, _mapUuidMeta));
    } else if (isInserting) {
      context.missing(_mapUuidMeta);
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
    if (data.containsKey('from_point')) {
      context.handle(_fromPointMeta,
          fromPoint.isAcceptableOrUnknown(data['from_point']!, _fromPointMeta));
    }
    if (data.containsKey('to_point')) {
      context.handle(_toPointMeta,
          toPoint.isAcceptableOrUnknown(data['to_point']!, _toPointMeta));
    }
    if (data.containsKey('path_json')) {
      context.handle(_pathJsonMeta,
          pathJson.isAcceptableOrUnknown(data['path_json']!, _pathJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {routeUuid};
  @override
  CableRoute map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CableRoute(
      routeUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}route_uuid'])!,
      mapUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}map_uuid'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      fromPoint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_point']),
      toPoint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_point']),
      pathJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path_json']),
    );
  }

  @override
  $CableRoutesTable createAlias(String alias) {
    return $CableRoutesTable(attachedDatabase, alias);
  }
}

class CableRoute extends DataClass implements Insertable<CableRoute> {
  final String routeUuid;
  final String mapUuid;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String? fromPoint;
  final String? toPoint;
  final String? pathJson;
  const CableRoute(
      {required this.routeUuid,
      required this.mapUuid,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      this.fromPoint,
      this.toPoint,
      this.pathJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['route_uuid'] = Variable<String>(routeUuid);
    map['map_uuid'] = Variable<String>(mapUuid);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    if (!nullToAbsent || fromPoint != null) {
      map['from_point'] = Variable<String>(fromPoint);
    }
    if (!nullToAbsent || toPoint != null) {
      map['to_point'] = Variable<String>(toPoint);
    }
    if (!nullToAbsent || pathJson != null) {
      map['path_json'] = Variable<String>(pathJson);
    }
    return map;
  }

  CableRoutesCompanion toCompanion(bool nullToAbsent) {
    return CableRoutesCompanion(
      routeUuid: Value(routeUuid),
      mapUuid: Value(mapUuid),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      fromPoint: fromPoint == null && nullToAbsent
          ? const Value.absent()
          : Value(fromPoint),
      toPoint: toPoint == null && nullToAbsent
          ? const Value.absent()
          : Value(toPoint),
      pathJson: pathJson == null && nullToAbsent
          ? const Value.absent()
          : Value(pathJson),
    );
  }

  factory CableRoute.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CableRoute(
      routeUuid: serializer.fromJson<String>(json['routeUuid']),
      mapUuid: serializer.fromJson<String>(json['mapUuid']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      fromPoint: serializer.fromJson<String?>(json['fromPoint']),
      toPoint: serializer.fromJson<String?>(json['toPoint']),
      pathJson: serializer.fromJson<String?>(json['pathJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'routeUuid': serializer.toJson<String>(routeUuid),
      'mapUuid': serializer.toJson<String>(mapUuid),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'fromPoint': serializer.toJson<String?>(fromPoint),
      'toPoint': serializer.toJson<String?>(toPoint),
      'pathJson': serializer.toJson<String?>(pathJson),
    };
  }

  CableRoute copyWith(
          {String? routeUuid,
          String? mapUuid,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          Value<String?> fromPoint = const Value.absent(),
          Value<String?> toPoint = const Value.absent(),
          Value<String?> pathJson = const Value.absent()}) =>
      CableRoute(
        routeUuid: routeUuid ?? this.routeUuid,
        mapUuid: mapUuid ?? this.mapUuid,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        fromPoint: fromPoint.present ? fromPoint.value : this.fromPoint,
        toPoint: toPoint.present ? toPoint.value : this.toPoint,
        pathJson: pathJson.present ? pathJson.value : this.pathJson,
      );
  CableRoute copyWithCompanion(CableRoutesCompanion data) {
    return CableRoute(
      routeUuid: data.routeUuid.present ? data.routeUuid.value : this.routeUuid,
      mapUuid: data.mapUuid.present ? data.mapUuid.value : this.mapUuid,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      fromPoint: data.fromPoint.present ? data.fromPoint.value : this.fromPoint,
      toPoint: data.toPoint.present ? data.toPoint.value : this.toPoint,
      pathJson: data.pathJson.present ? data.pathJson.value : this.pathJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CableRoute(')
          ..write('routeUuid: $routeUuid, ')
          ..write('mapUuid: $mapUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('fromPoint: $fromPoint, ')
          ..write('toPoint: $toPoint, ')
          ..write('pathJson: $pathJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(routeUuid, mapUuid, riadVersion, riadDeleted,
      riadDeletedAt, fromPoint, toPoint, pathJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CableRoute &&
          other.routeUuid == this.routeUuid &&
          other.mapUuid == this.mapUuid &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.fromPoint == this.fromPoint &&
          other.toPoint == this.toPoint &&
          other.pathJson == this.pathJson);
}

class CableRoutesCompanion extends UpdateCompanion<CableRoute> {
  final Value<String> routeUuid;
  final Value<String> mapUuid;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String?> fromPoint;
  final Value<String?> toPoint;
  final Value<String?> pathJson;
  final Value<int> rowid;
  const CableRoutesCompanion({
    this.routeUuid = const Value.absent(),
    this.mapUuid = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.fromPoint = const Value.absent(),
    this.toPoint = const Value.absent(),
    this.pathJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CableRoutesCompanion.insert({
    required String routeUuid,
    required String mapUuid,
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.fromPoint = const Value.absent(),
    this.toPoint = const Value.absent(),
    this.pathJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : routeUuid = Value(routeUuid),
        mapUuid = Value(mapUuid);
  static Insertable<CableRoute> custom({
    Expression<String>? routeUuid,
    Expression<String>? mapUuid,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? fromPoint,
    Expression<String>? toPoint,
    Expression<String>? pathJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (routeUuid != null) 'route_uuid': routeUuid,
      if (mapUuid != null) 'map_uuid': mapUuid,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (fromPoint != null) 'from_point': fromPoint,
      if (toPoint != null) 'to_point': toPoint,
      if (pathJson != null) 'path_json': pathJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CableRoutesCompanion copyWith(
      {Value<String>? routeUuid,
      Value<String>? mapUuid,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String?>? fromPoint,
      Value<String?>? toPoint,
      Value<String?>? pathJson,
      Value<int>? rowid}) {
    return CableRoutesCompanion(
      routeUuid: routeUuid ?? this.routeUuid,
      mapUuid: mapUuid ?? this.mapUuid,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      fromPoint: fromPoint ?? this.fromPoint,
      toPoint: toPoint ?? this.toPoint,
      pathJson: pathJson ?? this.pathJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (routeUuid.present) {
      map['route_uuid'] = Variable<String>(routeUuid.value);
    }
    if (mapUuid.present) {
      map['map_uuid'] = Variable<String>(mapUuid.value);
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
    if (fromPoint.present) {
      map['from_point'] = Variable<String>(fromPoint.value);
    }
    if (toPoint.present) {
      map['to_point'] = Variable<String>(toPoint.value);
    }
    if (pathJson.present) {
      map['path_json'] = Variable<String>(pathJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CableRoutesCompanion(')
          ..write('routeUuid: $routeUuid, ')
          ..write('mapUuid: $mapUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('fromPoint: $fromPoint, ')
          ..write('toPoint: $toPoint, ')
          ..write('pathJson: $pathJson, ')
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
  static const VerificationMeta _clientUuidMeta =
      const VerificationMeta('clientUuid');
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
      'client_uuid', aliasedName, false,
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
  static const VerificationMeta _driveFileIdMeta =
      const VerificationMeta('driveFileId');
  @override
  late final GeneratedColumn<String> driveFileId = GeneratedColumn<String>(
      'drive_file_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _transcriptionStatusMeta =
      const VerificationMeta('transcriptionStatus');
  @override
  late final GeneratedColumn<String> transcriptionStatus =
      GeneratedColumn<String>('transcription_status', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mediaTypeMeta =
      const VerificationMeta('mediaType');
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
      'media_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
      'tag', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentDoctypeMeta =
      const VerificationMeta('parentDoctype');
  @override
  late final GeneratedColumn<String> parentDoctype = GeneratedColumn<String>(
      'parent_doctype', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentNameMeta =
      const VerificationMeta('parentName');
  @override
  late final GeneratedColumn<String> parentName = GeneratedColumn<String>(
      'parent_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transcriptionMeta =
      const VerificationMeta('transcription');
  @override
  late final GeneratedColumn<String> transcription = GeneratedColumn<String>(
      'transcription', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        clientUuid,
        riadVersion,
        riadDeleted,
        riadDeletedAt,
        driveFileId,
        aiAllowed,
        transcriptionStatus,
        mediaType,
        tag,
        parentDoctype,
        parentName,
        localPath,
        transcription
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
    if (data.containsKey('client_uuid')) {
      context.handle(
          _clientUuidMeta,
          clientUuid.isAcceptableOrUnknown(
              data['client_uuid']!, _clientUuidMeta));
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
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
    if (data.containsKey('drive_file_id')) {
      context.handle(
          _driveFileIdMeta,
          driveFileId.isAcceptableOrUnknown(
              data['drive_file_id']!, _driveFileIdMeta));
    }
    if (data.containsKey('ai_allowed')) {
      context.handle(_aiAllowedMeta,
          aiAllowed.isAcceptableOrUnknown(data['ai_allowed']!, _aiAllowedMeta));
    }
    if (data.containsKey('transcription_status')) {
      context.handle(
          _transcriptionStatusMeta,
          transcriptionStatus.isAcceptableOrUnknown(
              data['transcription_status']!, _transcriptionStatusMeta));
    }
    if (data.containsKey('media_type')) {
      context.handle(_mediaTypeMeta,
          mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta));
    }
    if (data.containsKey('tag')) {
      context.handle(
          _tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
    }
    if (data.containsKey('parent_doctype')) {
      context.handle(
          _parentDoctypeMeta,
          parentDoctype.isAcceptableOrUnknown(
              data['parent_doctype']!, _parentDoctypeMeta));
    }
    if (data.containsKey('parent_name')) {
      context.handle(
          _parentNameMeta,
          parentName.isAcceptableOrUnknown(
              data['parent_name']!, _parentNameMeta));
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('transcription')) {
      context.handle(
          _transcriptionMeta,
          transcription.isAcceptableOrUnknown(
              data['transcription']!, _transcriptionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  MediaAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaAsset(
      clientUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_uuid'])!,
      riadVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}riad_version'])!,
      riadDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}riad_deleted'])!,
      riadDeletedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}riad_deleted_at']),
      driveFileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}drive_file_id']),
      aiAllowed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ai_allowed'])!,
      transcriptionStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transcription_status']),
      mediaType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_type']),
      tag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag']),
      parentDoctype: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_doctype']),
      parentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_name']),
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      transcription: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transcription']),
    );
  }

  @override
  $MediaAssetsTable createAlias(String alias) {
    return $MediaAssetsTable(attachedDatabase, alias);
  }
}

class MediaAsset extends DataClass implements Insertable<MediaAsset> {
  final String clientUuid;
  final int riadVersion;
  final bool riadDeleted;
  final DateTime? riadDeletedAt;
  final String? driveFileId;
  final bool aiAllowed;
  final String? transcriptionStatus;
  final String? mediaType;
  final String? tag;
  final String? parentDoctype;
  final String? parentName;
  final String? localPath;
  final String? transcription;
  const MediaAsset(
      {required this.clientUuid,
      required this.riadVersion,
      required this.riadDeleted,
      this.riadDeletedAt,
      this.driveFileId,
      required this.aiAllowed,
      this.transcriptionStatus,
      this.mediaType,
      this.tag,
      this.parentDoctype,
      this.parentName,
      this.localPath,
      this.transcription});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_uuid'] = Variable<String>(clientUuid);
    map['riad_version'] = Variable<int>(riadVersion);
    map['riad_deleted'] = Variable<bool>(riadDeleted);
    if (!nullToAbsent || riadDeletedAt != null) {
      map['riad_deleted_at'] = Variable<DateTime>(riadDeletedAt);
    }
    if (!nullToAbsent || driveFileId != null) {
      map['drive_file_id'] = Variable<String>(driveFileId);
    }
    map['ai_allowed'] = Variable<bool>(aiAllowed);
    if (!nullToAbsent || transcriptionStatus != null) {
      map['transcription_status'] = Variable<String>(transcriptionStatus);
    }
    if (!nullToAbsent || mediaType != null) {
      map['media_type'] = Variable<String>(mediaType);
    }
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    if (!nullToAbsent || parentDoctype != null) {
      map['parent_doctype'] = Variable<String>(parentDoctype);
    }
    if (!nullToAbsent || parentName != null) {
      map['parent_name'] = Variable<String>(parentName);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || transcription != null) {
      map['transcription'] = Variable<String>(transcription);
    }
    return map;
  }

  MediaAssetsCompanion toCompanion(bool nullToAbsent) {
    return MediaAssetsCompanion(
      clientUuid: Value(clientUuid),
      riadVersion: Value(riadVersion),
      riadDeleted: Value(riadDeleted),
      riadDeletedAt: riadDeletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(riadDeletedAt),
      driveFileId: driveFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(driveFileId),
      aiAllowed: Value(aiAllowed),
      transcriptionStatus: transcriptionStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(transcriptionStatus),
      mediaType: mediaType == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaType),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      parentDoctype: parentDoctype == null && nullToAbsent
          ? const Value.absent()
          : Value(parentDoctype),
      parentName: parentName == null && nullToAbsent
          ? const Value.absent()
          : Value(parentName),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      transcription: transcription == null && nullToAbsent
          ? const Value.absent()
          : Value(transcription),
    );
  }

  factory MediaAsset.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaAsset(
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      riadVersion: serializer.fromJson<int>(json['riadVersion']),
      riadDeleted: serializer.fromJson<bool>(json['riadDeleted']),
      riadDeletedAt: serializer.fromJson<DateTime?>(json['riadDeletedAt']),
      driveFileId: serializer.fromJson<String?>(json['driveFileId']),
      aiAllowed: serializer.fromJson<bool>(json['aiAllowed']),
      transcriptionStatus:
          serializer.fromJson<String?>(json['transcriptionStatus']),
      mediaType: serializer.fromJson<String?>(json['mediaType']),
      tag: serializer.fromJson<String?>(json['tag']),
      parentDoctype: serializer.fromJson<String?>(json['parentDoctype']),
      parentName: serializer.fromJson<String?>(json['parentName']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      transcription: serializer.fromJson<String?>(json['transcription']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientUuid': serializer.toJson<String>(clientUuid),
      'riadVersion': serializer.toJson<int>(riadVersion),
      'riadDeleted': serializer.toJson<bool>(riadDeleted),
      'riadDeletedAt': serializer.toJson<DateTime?>(riadDeletedAt),
      'driveFileId': serializer.toJson<String?>(driveFileId),
      'aiAllowed': serializer.toJson<bool>(aiAllowed),
      'transcriptionStatus': serializer.toJson<String?>(transcriptionStatus),
      'mediaType': serializer.toJson<String?>(mediaType),
      'tag': serializer.toJson<String?>(tag),
      'parentDoctype': serializer.toJson<String?>(parentDoctype),
      'parentName': serializer.toJson<String?>(parentName),
      'localPath': serializer.toJson<String?>(localPath),
      'transcription': serializer.toJson<String?>(transcription),
    };
  }

  MediaAsset copyWith(
          {String? clientUuid,
          int? riadVersion,
          bool? riadDeleted,
          Value<DateTime?> riadDeletedAt = const Value.absent(),
          Value<String?> driveFileId = const Value.absent(),
          bool? aiAllowed,
          Value<String?> transcriptionStatus = const Value.absent(),
          Value<String?> mediaType = const Value.absent(),
          Value<String?> tag = const Value.absent(),
          Value<String?> parentDoctype = const Value.absent(),
          Value<String?> parentName = const Value.absent(),
          Value<String?> localPath = const Value.absent(),
          Value<String?> transcription = const Value.absent()}) =>
      MediaAsset(
        clientUuid: clientUuid ?? this.clientUuid,
        riadVersion: riadVersion ?? this.riadVersion,
        riadDeleted: riadDeleted ?? this.riadDeleted,
        riadDeletedAt:
            riadDeletedAt.present ? riadDeletedAt.value : this.riadDeletedAt,
        driveFileId: driveFileId.present ? driveFileId.value : this.driveFileId,
        aiAllowed: aiAllowed ?? this.aiAllowed,
        transcriptionStatus: transcriptionStatus.present
            ? transcriptionStatus.value
            : this.transcriptionStatus,
        mediaType: mediaType.present ? mediaType.value : this.mediaType,
        tag: tag.present ? tag.value : this.tag,
        parentDoctype:
            parentDoctype.present ? parentDoctype.value : this.parentDoctype,
        parentName: parentName.present ? parentName.value : this.parentName,
        localPath: localPath.present ? localPath.value : this.localPath,
        transcription:
            transcription.present ? transcription.value : this.transcription,
      );
  MediaAsset copyWithCompanion(MediaAssetsCompanion data) {
    return MediaAsset(
      clientUuid:
          data.clientUuid.present ? data.clientUuid.value : this.clientUuid,
      riadVersion:
          data.riadVersion.present ? data.riadVersion.value : this.riadVersion,
      riadDeleted:
          data.riadDeleted.present ? data.riadDeleted.value : this.riadDeleted,
      riadDeletedAt: data.riadDeletedAt.present
          ? data.riadDeletedAt.value
          : this.riadDeletedAt,
      driveFileId:
          data.driveFileId.present ? data.driveFileId.value : this.driveFileId,
      aiAllowed: data.aiAllowed.present ? data.aiAllowed.value : this.aiAllowed,
      transcriptionStatus: data.transcriptionStatus.present
          ? data.transcriptionStatus.value
          : this.transcriptionStatus,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      tag: data.tag.present ? data.tag.value : this.tag,
      parentDoctype: data.parentDoctype.present
          ? data.parentDoctype.value
          : this.parentDoctype,
      parentName:
          data.parentName.present ? data.parentName.value : this.parentName,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      transcription: data.transcription.present
          ? data.transcription.value
          : this.transcription,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaAsset(')
          ..write('clientUuid: $clientUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('driveFileId: $driveFileId, ')
          ..write('aiAllowed: $aiAllowed, ')
          ..write('transcriptionStatus: $transcriptionStatus, ')
          ..write('mediaType: $mediaType, ')
          ..write('tag: $tag, ')
          ..write('parentDoctype: $parentDoctype, ')
          ..write('parentName: $parentName, ')
          ..write('localPath: $localPath, ')
          ..write('transcription: $transcription')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      clientUuid,
      riadVersion,
      riadDeleted,
      riadDeletedAt,
      driveFileId,
      aiAllowed,
      transcriptionStatus,
      mediaType,
      tag,
      parentDoctype,
      parentName,
      localPath,
      transcription);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaAsset &&
          other.clientUuid == this.clientUuid &&
          other.riadVersion == this.riadVersion &&
          other.riadDeleted == this.riadDeleted &&
          other.riadDeletedAt == this.riadDeletedAt &&
          other.driveFileId == this.driveFileId &&
          other.aiAllowed == this.aiAllowed &&
          other.transcriptionStatus == this.transcriptionStatus &&
          other.mediaType == this.mediaType &&
          other.tag == this.tag &&
          other.parentDoctype == this.parentDoctype &&
          other.parentName == this.parentName &&
          other.localPath == this.localPath &&
          other.transcription == this.transcription);
}

class MediaAssetsCompanion extends UpdateCompanion<MediaAsset> {
  final Value<String> clientUuid;
  final Value<int> riadVersion;
  final Value<bool> riadDeleted;
  final Value<DateTime?> riadDeletedAt;
  final Value<String?> driveFileId;
  final Value<bool> aiAllowed;
  final Value<String?> transcriptionStatus;
  final Value<String?> mediaType;
  final Value<String?> tag;
  final Value<String?> parentDoctype;
  final Value<String?> parentName;
  final Value<String?> localPath;
  final Value<String?> transcription;
  final Value<int> rowid;
  const MediaAssetsCompanion({
    this.clientUuid = const Value.absent(),
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.driveFileId = const Value.absent(),
    this.aiAllowed = const Value.absent(),
    this.transcriptionStatus = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.tag = const Value.absent(),
    this.parentDoctype = const Value.absent(),
    this.parentName = const Value.absent(),
    this.localPath = const Value.absent(),
    this.transcription = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaAssetsCompanion.insert({
    required String clientUuid,
    this.riadVersion = const Value.absent(),
    this.riadDeleted = const Value.absent(),
    this.riadDeletedAt = const Value.absent(),
    this.driveFileId = const Value.absent(),
    this.aiAllowed = const Value.absent(),
    this.transcriptionStatus = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.tag = const Value.absent(),
    this.parentDoctype = const Value.absent(),
    this.parentName = const Value.absent(),
    this.localPath = const Value.absent(),
    this.transcription = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientUuid = Value(clientUuid);
  static Insertable<MediaAsset> custom({
    Expression<String>? clientUuid,
    Expression<int>? riadVersion,
    Expression<bool>? riadDeleted,
    Expression<DateTime>? riadDeletedAt,
    Expression<String>? driveFileId,
    Expression<bool>? aiAllowed,
    Expression<String>? transcriptionStatus,
    Expression<String>? mediaType,
    Expression<String>? tag,
    Expression<String>? parentDoctype,
    Expression<String>? parentName,
    Expression<String>? localPath,
    Expression<String>? transcription,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (riadVersion != null) 'riad_version': riadVersion,
      if (riadDeleted != null) 'riad_deleted': riadDeleted,
      if (riadDeletedAt != null) 'riad_deleted_at': riadDeletedAt,
      if (driveFileId != null) 'drive_file_id': driveFileId,
      if (aiAllowed != null) 'ai_allowed': aiAllowed,
      if (transcriptionStatus != null)
        'transcription_status': transcriptionStatus,
      if (mediaType != null) 'media_type': mediaType,
      if (tag != null) 'tag': tag,
      if (parentDoctype != null) 'parent_doctype': parentDoctype,
      if (parentName != null) 'parent_name': parentName,
      if (localPath != null) 'local_path': localPath,
      if (transcription != null) 'transcription': transcription,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaAssetsCompanion copyWith(
      {Value<String>? clientUuid,
      Value<int>? riadVersion,
      Value<bool>? riadDeleted,
      Value<DateTime?>? riadDeletedAt,
      Value<String?>? driveFileId,
      Value<bool>? aiAllowed,
      Value<String?>? transcriptionStatus,
      Value<String?>? mediaType,
      Value<String?>? tag,
      Value<String?>? parentDoctype,
      Value<String?>? parentName,
      Value<String?>? localPath,
      Value<String?>? transcription,
      Value<int>? rowid}) {
    return MediaAssetsCompanion(
      clientUuid: clientUuid ?? this.clientUuid,
      riadVersion: riadVersion ?? this.riadVersion,
      riadDeleted: riadDeleted ?? this.riadDeleted,
      riadDeletedAt: riadDeletedAt ?? this.riadDeletedAt,
      driveFileId: driveFileId ?? this.driveFileId,
      aiAllowed: aiAllowed ?? this.aiAllowed,
      transcriptionStatus: transcriptionStatus ?? this.transcriptionStatus,
      mediaType: mediaType ?? this.mediaType,
      tag: tag ?? this.tag,
      parentDoctype: parentDoctype ?? this.parentDoctype,
      parentName: parentName ?? this.parentName,
      localPath: localPath ?? this.localPath,
      transcription: transcription ?? this.transcription,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
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
    if (driveFileId.present) {
      map['drive_file_id'] = Variable<String>(driveFileId.value);
    }
    if (aiAllowed.present) {
      map['ai_allowed'] = Variable<bool>(aiAllowed.value);
    }
    if (transcriptionStatus.present) {
      map['transcription_status'] = Variable<String>(transcriptionStatus.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (parentDoctype.present) {
      map['parent_doctype'] = Variable<String>(parentDoctype.value);
    }
    if (parentName.present) {
      map['parent_name'] = Variable<String>(parentName.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (transcription.present) {
      map['transcription'] = Variable<String>(transcription.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaAssetsCompanion(')
          ..write('clientUuid: $clientUuid, ')
          ..write('riadVersion: $riadVersion, ')
          ..write('riadDeleted: $riadDeleted, ')
          ..write('riadDeletedAt: $riadDeletedAt, ')
          ..write('driveFileId: $driveFileId, ')
          ..write('aiAllowed: $aiAllowed, ')
          ..write('transcriptionStatus: $transcriptionStatus, ')
          ..write('mediaType: $mediaType, ')
          ..write('tag: $tag, ')
          ..write('parentDoctype: $parentDoctype, ')
          ..write('parentName: $parentName, ')
          ..write('localPath: $localPath, ')
          ..write('transcription: $transcription, ')
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
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
      'tag', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentDoctypeMeta =
      const VerificationMeta('parentDoctype');
  @override
  late final GeneratedColumn<String> parentDoctype = GeneratedColumn<String>(
      'parent_doctype', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentNameMeta =
      const VerificationMeta('parentName');
  @override
  late final GeneratedColumn<String> parentName = GeneratedColumn<String>(
      'parent_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        clientUuid,
        localPath,
        mediaType,
        tag,
        parentDoctype,
        parentName,
        status,
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
    if (data.containsKey('tag')) {
      context.handle(
          _tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
    }
    if (data.containsKey('parent_doctype')) {
      context.handle(
          _parentDoctypeMeta,
          parentDoctype.isAcceptableOrUnknown(
              data['parent_doctype']!, _parentDoctypeMeta));
    }
    if (data.containsKey('parent_name')) {
      context.handle(
          _parentNameMeta,
          parentName.isAcceptableOrUnknown(
              data['parent_name']!, _parentNameMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
      tag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag']),
      parentDoctype: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_doctype']),
      parentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_name']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
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
  final String? tag;
  final String? parentDoctype;
  final String? parentName;
  final String status;
  final int createdAt;
  const PendingMediaUpload(
      {required this.id,
      required this.clientUuid,
      required this.localPath,
      required this.mediaType,
      this.tag,
      this.parentDoctype,
      this.parentName,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_uuid'] = Variable<String>(clientUuid);
    map['local_path'] = Variable<String>(localPath);
    map['media_type'] = Variable<String>(mediaType);
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    if (!nullToAbsent || parentDoctype != null) {
      map['parent_doctype'] = Variable<String>(parentDoctype);
    }
    if (!nullToAbsent || parentName != null) {
      map['parent_name'] = Variable<String>(parentName);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PendingMediaUploadsCompanion toCompanion(bool nullToAbsent) {
    return PendingMediaUploadsCompanion(
      id: Value(id),
      clientUuid: Value(clientUuid),
      localPath: Value(localPath),
      mediaType: Value(mediaType),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      parentDoctype: parentDoctype == null && nullToAbsent
          ? const Value.absent()
          : Value(parentDoctype),
      parentName: parentName == null && nullToAbsent
          ? const Value.absent()
          : Value(parentName),
      status: Value(status),
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
      tag: serializer.fromJson<String?>(json['tag']),
      parentDoctype: serializer.fromJson<String?>(json['parentDoctype']),
      parentName: serializer.fromJson<String?>(json['parentName']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
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
      'tag': serializer.toJson<String?>(tag),
      'parentDoctype': serializer.toJson<String?>(parentDoctype),
      'parentName': serializer.toJson<String?>(parentName),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PendingMediaUpload copyWith(
          {int? id,
          String? clientUuid,
          String? localPath,
          String? mediaType,
          Value<String?> tag = const Value.absent(),
          Value<String?> parentDoctype = const Value.absent(),
          Value<String?> parentName = const Value.absent(),
          String? status,
          int? createdAt}) =>
      PendingMediaUpload(
        id: id ?? this.id,
        clientUuid: clientUuid ?? this.clientUuid,
        localPath: localPath ?? this.localPath,
        mediaType: mediaType ?? this.mediaType,
        tag: tag.present ? tag.value : this.tag,
        parentDoctype:
            parentDoctype.present ? parentDoctype.value : this.parentDoctype,
        parentName: parentName.present ? parentName.value : this.parentName,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  PendingMediaUpload copyWithCompanion(PendingMediaUploadsCompanion data) {
    return PendingMediaUpload(
      id: data.id.present ? data.id.value : this.id,
      clientUuid:
          data.clientUuid.present ? data.clientUuid.value : this.clientUuid,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      tag: data.tag.present ? data.tag.value : this.tag,
      parentDoctype: data.parentDoctype.present
          ? data.parentDoctype.value
          : this.parentDoctype,
      parentName:
          data.parentName.present ? data.parentName.value : this.parentName,
      status: data.status.present ? data.status.value : this.status,
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
          ..write('tag: $tag, ')
          ..write('parentDoctype: $parentDoctype, ')
          ..write('parentName: $parentName, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, clientUuid, localPath, mediaType, tag,
      parentDoctype, parentName, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingMediaUpload &&
          other.id == this.id &&
          other.clientUuid == this.clientUuid &&
          other.localPath == this.localPath &&
          other.mediaType == this.mediaType &&
          other.tag == this.tag &&
          other.parentDoctype == this.parentDoctype &&
          other.parentName == this.parentName &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class PendingMediaUploadsCompanion extends UpdateCompanion<PendingMediaUpload> {
  final Value<int> id;
  final Value<String> clientUuid;
  final Value<String> localPath;
  final Value<String> mediaType;
  final Value<String?> tag;
  final Value<String?> parentDoctype;
  final Value<String?> parentName;
  final Value<String> status;
  final Value<int> createdAt;
  const PendingMediaUploadsCompanion({
    this.id = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.localPath = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.tag = const Value.absent(),
    this.parentDoctype = const Value.absent(),
    this.parentName = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingMediaUploadsCompanion.insert({
    this.id = const Value.absent(),
    required String clientUuid,
    required String localPath,
    required String mediaType,
    this.tag = const Value.absent(),
    this.parentDoctype = const Value.absent(),
    this.parentName = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
  })  : clientUuid = Value(clientUuid),
        localPath = Value(localPath),
        mediaType = Value(mediaType),
        createdAt = Value(createdAt);
  static Insertable<PendingMediaUpload> custom({
    Expression<int>? id,
    Expression<String>? clientUuid,
    Expression<String>? localPath,
    Expression<String>? mediaType,
    Expression<String>? tag,
    Expression<String>? parentDoctype,
    Expression<String>? parentName,
    Expression<String>? status,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (localPath != null) 'local_path': localPath,
      if (mediaType != null) 'media_type': mediaType,
      if (tag != null) 'tag': tag,
      if (parentDoctype != null) 'parent_doctype': parentDoctype,
      if (parentName != null) 'parent_name': parentName,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingMediaUploadsCompanion copyWith(
      {Value<int>? id,
      Value<String>? clientUuid,
      Value<String>? localPath,
      Value<String>? mediaType,
      Value<String?>? tag,
      Value<String?>? parentDoctype,
      Value<String?>? parentName,
      Value<String>? status,
      Value<int>? createdAt}) {
    return PendingMediaUploadsCompanion(
      id: id ?? this.id,
      clientUuid: clientUuid ?? this.clientUuid,
      localPath: localPath ?? this.localPath,
      mediaType: mediaType ?? this.mediaType,
      tag: tag ?? this.tag,
      parentDoctype: parentDoctype ?? this.parentDoctype,
      parentName: parentName ?? this.parentName,
      status: status ?? this.status,
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
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (parentDoctype.present) {
      map['parent_doctype'] = Variable<String>(parentDoctype.value);
    }
    if (parentName.present) {
      map['parent_name'] = Variable<String>(parentName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
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
          ..write('tag: $tag, ')
          ..write('parentDoctype: $parentDoctype, ')
          ..write('parentName: $parentName, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
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
  static const VerificationMeta _conflictIdMeta =
      const VerificationMeta('conflictId');
  @override
  late final GeneratedColumn<String> conflictId = GeneratedColumn<String>(
      'conflict_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _doctypeMeta =
      const VerificationMeta('doctype');
  @override
  late final GeneratedColumn<String> doctype = GeneratedColumn<String>(
      'doctype', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _docnameMeta =
      const VerificationMeta('docname');
  @override
  late final GeneratedColumn<String> docname = GeneratedColumn<String>(
      'docname', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldNameMeta =
      const VerificationMeta('fieldName');
  @override
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
      'field_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverValueMeta =
      const VerificationMeta('serverValue');
  @override
  late final GeneratedColumn<String> serverValue = GeneratedColumn<String>(
      'server_value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientValueMeta =
      const VerificationMeta('clientValue');
  @override
  late final GeneratedColumn<String> clientValue = GeneratedColumn<String>(
      'client_value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _resolvedMeta =
      const VerificationMeta('resolved');
  @override
  late final GeneratedColumn<bool> resolved = GeneratedColumn<bool>(
      'resolved', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("resolved" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        conflictId,
        doctype,
        docname,
        fieldName,
        serverValue,
        clientValue,
        resolved
      ];
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
    if (data.containsKey('conflict_id')) {
      context.handle(
          _conflictIdMeta,
          conflictId.isAcceptableOrUnknown(
              data['conflict_id']!, _conflictIdMeta));
    } else if (isInserting) {
      context.missing(_conflictIdMeta);
    }
    if (data.containsKey('doctype')) {
      context.handle(_doctypeMeta,
          doctype.isAcceptableOrUnknown(data['doctype']!, _doctypeMeta));
    } else if (isInserting) {
      context.missing(_doctypeMeta);
    }
    if (data.containsKey('docname')) {
      context.handle(_docnameMeta,
          docname.isAcceptableOrUnknown(data['docname']!, _docnameMeta));
    } else if (isInserting) {
      context.missing(_docnameMeta);
    }
    if (data.containsKey('field_name')) {
      context.handle(_fieldNameMeta,
          fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta));
    } else if (isInserting) {
      context.missing(_fieldNameMeta);
    }
    if (data.containsKey('server_value')) {
      context.handle(
          _serverValueMeta,
          serverValue.isAcceptableOrUnknown(
              data['server_value']!, _serverValueMeta));
    }
    if (data.containsKey('client_value')) {
      context.handle(
          _clientValueMeta,
          clientValue.isAcceptableOrUnknown(
              data['client_value']!, _clientValueMeta));
    }
    if (data.containsKey('resolved')) {
      context.handle(_resolvedMeta,
          resolved.isAcceptableOrUnknown(data['resolved']!, _resolvedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conflictId};
  @override
  SyncConflict map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConflict(
      conflictId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}conflict_id'])!,
      doctype: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doctype'])!,
      docname: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}docname'])!,
      fieldName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_name'])!,
      serverValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_value']),
      clientValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_value']),
      resolved: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}resolved'])!,
    );
  }

  @override
  $SyncConflictsTable createAlias(String alias) {
    return $SyncConflictsTable(attachedDatabase, alias);
  }
}

class SyncConflict extends DataClass implements Insertable<SyncConflict> {
  final String conflictId;
  final String doctype;
  final String docname;
  final String fieldName;
  final String? serverValue;
  final String? clientValue;
  final bool resolved;
  const SyncConflict(
      {required this.conflictId,
      required this.doctype,
      required this.docname,
      required this.fieldName,
      this.serverValue,
      this.clientValue,
      required this.resolved});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conflict_id'] = Variable<String>(conflictId);
    map['doctype'] = Variable<String>(doctype);
    map['docname'] = Variable<String>(docname);
    map['field_name'] = Variable<String>(fieldName);
    if (!nullToAbsent || serverValue != null) {
      map['server_value'] = Variable<String>(serverValue);
    }
    if (!nullToAbsent || clientValue != null) {
      map['client_value'] = Variable<String>(clientValue);
    }
    map['resolved'] = Variable<bool>(resolved);
    return map;
  }

  SyncConflictsCompanion toCompanion(bool nullToAbsent) {
    return SyncConflictsCompanion(
      conflictId: Value(conflictId),
      doctype: Value(doctype),
      docname: Value(docname),
      fieldName: Value(fieldName),
      serverValue: serverValue == null && nullToAbsent
          ? const Value.absent()
          : Value(serverValue),
      clientValue: clientValue == null && nullToAbsent
          ? const Value.absent()
          : Value(clientValue),
      resolved: Value(resolved),
    );
  }

  factory SyncConflict.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConflict(
      conflictId: serializer.fromJson<String>(json['conflictId']),
      doctype: serializer.fromJson<String>(json['doctype']),
      docname: serializer.fromJson<String>(json['docname']),
      fieldName: serializer.fromJson<String>(json['fieldName']),
      serverValue: serializer.fromJson<String?>(json['serverValue']),
      clientValue: serializer.fromJson<String?>(json['clientValue']),
      resolved: serializer.fromJson<bool>(json['resolved']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conflictId': serializer.toJson<String>(conflictId),
      'doctype': serializer.toJson<String>(doctype),
      'docname': serializer.toJson<String>(docname),
      'fieldName': serializer.toJson<String>(fieldName),
      'serverValue': serializer.toJson<String?>(serverValue),
      'clientValue': serializer.toJson<String?>(clientValue),
      'resolved': serializer.toJson<bool>(resolved),
    };
  }

  SyncConflict copyWith(
          {String? conflictId,
          String? doctype,
          String? docname,
          String? fieldName,
          Value<String?> serverValue = const Value.absent(),
          Value<String?> clientValue = const Value.absent(),
          bool? resolved}) =>
      SyncConflict(
        conflictId: conflictId ?? this.conflictId,
        doctype: doctype ?? this.doctype,
        docname: docname ?? this.docname,
        fieldName: fieldName ?? this.fieldName,
        serverValue: serverValue.present ? serverValue.value : this.serverValue,
        clientValue: clientValue.present ? clientValue.value : this.clientValue,
        resolved: resolved ?? this.resolved,
      );
  SyncConflict copyWithCompanion(SyncConflictsCompanion data) {
    return SyncConflict(
      conflictId:
          data.conflictId.present ? data.conflictId.value : this.conflictId,
      doctype: data.doctype.present ? data.doctype.value : this.doctype,
      docname: data.docname.present ? data.docname.value : this.docname,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      serverValue:
          data.serverValue.present ? data.serverValue.value : this.serverValue,
      clientValue:
          data.clientValue.present ? data.clientValue.value : this.clientValue,
      resolved: data.resolved.present ? data.resolved.value : this.resolved,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflict(')
          ..write('conflictId: $conflictId, ')
          ..write('doctype: $doctype, ')
          ..write('docname: $docname, ')
          ..write('fieldName: $fieldName, ')
          ..write('serverValue: $serverValue, ')
          ..write('clientValue: $clientValue, ')
          ..write('resolved: $resolved')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(conflictId, doctype, docname, fieldName,
      serverValue, clientValue, resolved);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflict &&
          other.conflictId == this.conflictId &&
          other.doctype == this.doctype &&
          other.docname == this.docname &&
          other.fieldName == this.fieldName &&
          other.serverValue == this.serverValue &&
          other.clientValue == this.clientValue &&
          other.resolved == this.resolved);
}

class SyncConflictsCompanion extends UpdateCompanion<SyncConflict> {
  final Value<String> conflictId;
  final Value<String> doctype;
  final Value<String> docname;
  final Value<String> fieldName;
  final Value<String?> serverValue;
  final Value<String?> clientValue;
  final Value<bool> resolved;
  final Value<int> rowid;
  const SyncConflictsCompanion({
    this.conflictId = const Value.absent(),
    this.doctype = const Value.absent(),
    this.docname = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.serverValue = const Value.absent(),
    this.clientValue = const Value.absent(),
    this.resolved = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncConflictsCompanion.insert({
    required String conflictId,
    required String doctype,
    required String docname,
    required String fieldName,
    this.serverValue = const Value.absent(),
    this.clientValue = const Value.absent(),
    this.resolved = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : conflictId = Value(conflictId),
        doctype = Value(doctype),
        docname = Value(docname),
        fieldName = Value(fieldName);
  static Insertable<SyncConflict> custom({
    Expression<String>? conflictId,
    Expression<String>? doctype,
    Expression<String>? docname,
    Expression<String>? fieldName,
    Expression<String>? serverValue,
    Expression<String>? clientValue,
    Expression<bool>? resolved,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conflictId != null) 'conflict_id': conflictId,
      if (doctype != null) 'doctype': doctype,
      if (docname != null) 'docname': docname,
      if (fieldName != null) 'field_name': fieldName,
      if (serverValue != null) 'server_value': serverValue,
      if (clientValue != null) 'client_value': clientValue,
      if (resolved != null) 'resolved': resolved,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncConflictsCompanion copyWith(
      {Value<String>? conflictId,
      Value<String>? doctype,
      Value<String>? docname,
      Value<String>? fieldName,
      Value<String?>? serverValue,
      Value<String?>? clientValue,
      Value<bool>? resolved,
      Value<int>? rowid}) {
    return SyncConflictsCompanion(
      conflictId: conflictId ?? this.conflictId,
      doctype: doctype ?? this.doctype,
      docname: docname ?? this.docname,
      fieldName: fieldName ?? this.fieldName,
      serverValue: serverValue ?? this.serverValue,
      clientValue: clientValue ?? this.clientValue,
      resolved: resolved ?? this.resolved,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conflictId.present) {
      map['conflict_id'] = Variable<String>(conflictId.value);
    }
    if (doctype.present) {
      map['doctype'] = Variable<String>(doctype.value);
    }
    if (docname.present) {
      map['docname'] = Variable<String>(docname.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (serverValue.present) {
      map['server_value'] = Variable<String>(serverValue.value);
    }
    if (clientValue.present) {
      map['client_value'] = Variable<String>(clientValue.value);
    }
    if (resolved.present) {
      map['resolved'] = Variable<bool>(resolved.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictsCompanion(')
          ..write('conflictId: $conflictId, ')
          ..write('doctype: $doctype, ')
          ..write('docname: $docname, ')
          ..write('fieldName: $fieldName, ')
          ..write('serverValue: $serverValue, ')
          ..write('clientValue: $clientValue, ')
          ..write('resolved: $resolved, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$RiadDatabase extends GeneratedDatabase {
  _$RiadDatabase(QueryExecutor e) : super(e);
  $RiadDatabaseManager get managers => $RiadDatabaseManager(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  late final $PendingOpsTable pendingOps = $PendingOpsTable(this);
  late final $VisitsTable visits = $VisitsTable(this);
  late final $VisitMaterialsTable visitMaterials = $VisitMaterialsTable(this);
  late final $VisitPhotosTable visitPhotos = $VisitPhotosTable(this);
  late final $ChecklistInstancesTable checklistInstances =
      $ChecklistInstancesTable(this);
  late final $ChecklistInstanceItemsTable checklistInstanceItems =
      $ChecklistInstanceItemsTable(this);
  late final $InstallationMapsTable installationMaps =
      $InstallationMapsTable(this);
  late final $MountPointsTable mountPoints = $MountPointsTable(this);
  late final $CableRoutesTable cableRoutes = $CableRoutesTable(this);
  late final $MediaAssetsTable mediaAssets = $MediaAssetsTable(this);
  late final $PendingMediaUploadsTable pendingMediaUploads =
      $PendingMediaUploadsTable(this);
  late final $SyncConflictsTable syncConflicts = $SyncConflictsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        syncMeta,
        pendingOps,
        visits,
        visitMaterials,
        visitPhotos,
        checklistInstances,
        checklistInstanceItems,
        installationMaps,
        mountPoints,
        cableRoutes,
        mediaAssets,
        pendingMediaUploads,
        syncConflicts
      ];
}

typedef $$SyncMetaTableCreateCompanionBuilder = SyncMetaCompanion Function({
  Value<int> rowid,
  Value<String?> watermark,
  required String deviceId,
});
typedef $$SyncMetaTableUpdateCompanionBuilder = SyncMetaCompanion Function({
  Value<int> rowid,
  Value<String?> watermark,
  Value<String> deviceId,
});

class $$SyncMetaTableFilterComposer
    extends Composer<_$RiadDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowid => $composableBuilder(
      column: $table.rowid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get watermark => $composableBuilder(
      column: $table.watermark, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$RiadDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowid => $composableBuilder(
      column: $table.rowid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get watermark => $composableBuilder(
      column: $table.watermark, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$RiadDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowid =>
      $composableBuilder(column: $table.rowid, builder: (column) => column);

  GeneratedColumn<String> get watermark =>
      $composableBuilder(column: $table.watermark, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$SyncMetaTableTableManager extends RootTableManager<
    _$RiadDatabase,
    $SyncMetaTable,
    SyncMetaData,
    $$SyncMetaTableFilterComposer,
    $$SyncMetaTableOrderingComposer,
    $$SyncMetaTableAnnotationComposer,
    $$SyncMetaTableCreateCompanionBuilder,
    $$SyncMetaTableUpdateCompanionBuilder,
    (
      SyncMetaData,
      BaseReferences<_$RiadDatabase, $SyncMetaTable, SyncMetaData>
    ),
    SyncMetaData,
    PrefetchHooks Function()> {
  $$SyncMetaTableTableManager(_$RiadDatabase db, $SyncMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> rowid = const Value.absent(),
            Value<String?> watermark = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
          }) =>
              SyncMetaCompanion(
            rowid: rowid,
            watermark: watermark,
            deviceId: deviceId,
          ),
          createCompanionCallback: ({
            Value<int> rowid = const Value.absent(),
            Value<String?> watermark = const Value.absent(),
            required String deviceId,
          }) =>
              SyncMetaCompanion.insert(
            rowid: rowid,
            watermark: watermark,
            deviceId: deviceId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncMetaTableProcessedTableManager = ProcessedTableManager<
    _$RiadDatabase,
    $SyncMetaTable,
    SyncMetaData,
    $$SyncMetaTableFilterComposer,
    $$SyncMetaTableOrderingComposer,
    $$SyncMetaTableAnnotationComposer,
    $$SyncMetaTableCreateCompanionBuilder,
    $$SyncMetaTableUpdateCompanionBuilder,
    (
      SyncMetaData,
      BaseReferences<_$RiadDatabase, $SyncMetaTable, SyncMetaData>
    ),
    SyncMetaData,
    PrefetchHooks Function()>;
typedef $$PendingOpsTableCreateCompanionBuilder = PendingOpsCompanion Function({
  Value<int> id,
  required String doctype,
  required String name,
  required String op,
  required String payload,
  Value<int?> baseVersion,
  Value<String> status,
  required int createdAt,
  Value<int> retryCount,
  Value<int> nextRetryAt,
});
typedef $$PendingOpsTableUpdateCompanionBuilder = PendingOpsCompanion Function({
  Value<int> id,
  Value<String> doctype,
  Value<String> name,
  Value<String> op,
  Value<String> payload,
  Value<int?> baseVersion,
  Value<String> status,
  Value<int> createdAt,
  Value<int> retryCount,
  Value<int> nextRetryAt,
});

class $$PendingOpsTableFilterComposer
    extends Composer<_$RiadDatabase, $PendingOpsTable> {
  $$PendingOpsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get doctype => $composableBuilder(
      column: $table.doctype, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get op => $composableBuilder(
      column: $table.op, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnFilters(column));
}

class $$PendingOpsTableOrderingComposer
    extends Composer<_$RiadDatabase, $PendingOpsTable> {
  $$PendingOpsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get doctype => $composableBuilder(
      column: $table.doctype, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get op => $composableBuilder(
      column: $table.op, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnOrderings(column));
}

class $$PendingOpsTableAnnotationComposer
    extends Composer<_$RiadDatabase, $PendingOpsTable> {
  $$PendingOpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get doctype =>
      $composableBuilder(column: $table.doctype, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<int> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => column);
}

class $$PendingOpsTableTableManager extends RootTableManager<
    _$RiadDatabase,
    $PendingOpsTable,
    PendingOp,
    $$PendingOpsTableFilterComposer,
    $$PendingOpsTableOrderingComposer,
    $$PendingOpsTableAnnotationComposer,
    $$PendingOpsTableCreateCompanionBuilder,
    $$PendingOpsTableUpdateCompanionBuilder,
    (PendingOp, BaseReferences<_$RiadDatabase, $PendingOpsTable, PendingOp>),
    PendingOp,
    PrefetchHooks Function()> {
  $$PendingOpsTableTableManager(_$RiadDatabase db, $PendingOpsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> doctype = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> op = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int?> baseVersion = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int> nextRetryAt = const Value.absent(),
          }) =>
              PendingOpsCompanion(
            id: id,
            doctype: doctype,
            name: name,
            op: op,
            payload: payload,
            baseVersion: baseVersion,
            status: status,
            createdAt: createdAt,
            retryCount: retryCount,
            nextRetryAt: nextRetryAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String doctype,
            required String name,
            required String op,
            required String payload,
            Value<int?> baseVersion = const Value.absent(),
            Value<String> status = const Value.absent(),
            required int createdAt,
            Value<int> retryCount = const Value.absent(),
            Value<int> nextRetryAt = const Value.absent(),
          }) =>
              PendingOpsCompanion.insert(
            id: id,
            doctype: doctype,
            name: name,
            op: op,
            payload: payload,
            baseVersion: baseVersion,
            status: status,
            createdAt: createdAt,
            retryCount: retryCount,
            nextRetryAt: nextRetryAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingOpsTableProcessedTableManager = ProcessedTableManager<
    _$RiadDatabase,
    $PendingOpsTable,
    PendingOp,
    $$PendingOpsTableFilterComposer,
    $$PendingOpsTableOrderingComposer,
    $$PendingOpsTableAnnotationComposer,
    $$PendingOpsTableCreateCompanionBuilder,
    $$PendingOpsTableUpdateCompanionBuilder,
    (PendingOp, BaseReferences<_$RiadDatabase, $PendingOpsTable, PendingOp>),
    PendingOp,
    PrefetchHooks Function()>;
typedef $$VisitsTableCreateCompanionBuilder = VisitsCompanion Function({
  required String clientUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> visitType,
  Value<String?> summary,
  Value<String?> serviceTicket,
  Value<DateTime?> visitDate,
  Value<String?> status,
  Value<int> rowid,
});
typedef $$VisitsTableUpdateCompanionBuilder = VisitsCompanion Function({
  Value<String> clientUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> visitType,
  Value<String?> summary,
  Value<String?> serviceTicket,
  Value<DateTime?> visitDate,
  Value<String?> status,
  Value<int> rowid,
});

class $$VisitsTableFilterComposer
    extends Composer<_$RiadDatabase, $VisitsTable> {
  $$VisitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get visitType => $composableBuilder(
      column: $table.visitType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serviceTicket => $composableBuilder(
      column: $table.serviceTicket, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get visitDate => $composableBuilder(
      column: $table.visitDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$VisitsTableOrderingComposer
    extends Composer<_$RiadDatabase, $VisitsTable> {
  $$VisitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get visitType => $composableBuilder(
      column: $table.visitType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serviceTicket => $composableBuilder(
      column: $table.serviceTicket,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get visitDate => $composableBuilder(
      column: $table.visitDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$VisitsTableAnnotationComposer
    extends Composer<_$RiadDatabase, $VisitsTable> {
  $$VisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get visitType =>
      $composableBuilder(column: $table.visitType, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get serviceTicket => $composableBuilder(
      column: $table.serviceTicket, builder: (column) => column);

  GeneratedColumn<DateTime> get visitDate =>
      $composableBuilder(column: $table.visitDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$VisitsTableTableManager extends RootTableManager<
    _$RiadDatabase,
    $VisitsTable,
    Visit,
    $$VisitsTableFilterComposer,
    $$VisitsTableOrderingComposer,
    $$VisitsTableAnnotationComposer,
    $$VisitsTableCreateCompanionBuilder,
    $$VisitsTableUpdateCompanionBuilder,
    (Visit, BaseReferences<_$RiadDatabase, $VisitsTable, Visit>),
    Visit,
    PrefetchHooks Function()> {
  $$VisitsTableTableManager(_$RiadDatabase db, $VisitsTable table)
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
            Value<String> clientUuid = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> visitType = const Value.absent(),
            Value<String?> summary = const Value.absent(),
            Value<String?> serviceTicket = const Value.absent(),
            Value<DateTime?> visitDate = const Value.absent(),
            Value<String?> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VisitsCompanion(
            clientUuid: clientUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            visitType: visitType,
            summary: summary,
            serviceTicket: serviceTicket,
            visitDate: visitDate,
            status: status,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String clientUuid,
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> visitType = const Value.absent(),
            Value<String?> summary = const Value.absent(),
            Value<String?> serviceTicket = const Value.absent(),
            Value<DateTime?> visitDate = const Value.absent(),
            Value<String?> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VisitsCompanion.insert(
            clientUuid: clientUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            visitType: visitType,
            summary: summary,
            serviceTicket: serviceTicket,
            visitDate: visitDate,
            status: status,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VisitsTableProcessedTableManager = ProcessedTableManager<
    _$RiadDatabase,
    $VisitsTable,
    Visit,
    $$VisitsTableFilterComposer,
    $$VisitsTableOrderingComposer,
    $$VisitsTableAnnotationComposer,
    $$VisitsTableCreateCompanionBuilder,
    $$VisitsTableUpdateCompanionBuilder,
    (Visit, BaseReferences<_$RiadDatabase, $VisitsTable, Visit>),
    Visit,
    PrefetchHooks Function()>;
typedef $$VisitMaterialsTableCreateCompanionBuilder = VisitMaterialsCompanion
    Function({
  required String clientUuid,
  required String visitUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> itemName,
  Value<String?> serialNo,
  Value<int> qty,
  Value<int> rowid,
});
typedef $$VisitMaterialsTableUpdateCompanionBuilder = VisitMaterialsCompanion
    Function({
  Value<String> clientUuid,
  Value<String> visitUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> itemName,
  Value<String?> serialNo,
  Value<int> qty,
  Value<int> rowid,
});

class $$VisitMaterialsTableFilterComposer
    extends Composer<_$RiadDatabase, $VisitMaterialsTable> {
  $$VisitMaterialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get visitUuid => $composableBuilder(
      column: $table.visitUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemName => $composableBuilder(
      column: $table.itemName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serialNo => $composableBuilder(
      column: $table.serialNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnFilters(column));
}

class $$VisitMaterialsTableOrderingComposer
    extends Composer<_$RiadDatabase, $VisitMaterialsTable> {
  $$VisitMaterialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get visitUuid => $composableBuilder(
      column: $table.visitUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemName => $composableBuilder(
      column: $table.itemName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serialNo => $composableBuilder(
      column: $table.serialNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnOrderings(column));
}

class $$VisitMaterialsTableAnnotationComposer
    extends Composer<_$RiadDatabase, $VisitMaterialsTable> {
  $$VisitMaterialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => column);

  GeneratedColumn<String> get visitUuid =>
      $composableBuilder(column: $table.visitUuid, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<String> get serialNo =>
      $composableBuilder(column: $table.serialNo, builder: (column) => column);

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);
}

class $$VisitMaterialsTableTableManager extends RootTableManager<
    _$RiadDatabase,
    $VisitMaterialsTable,
    VisitMaterial,
    $$VisitMaterialsTableFilterComposer,
    $$VisitMaterialsTableOrderingComposer,
    $$VisitMaterialsTableAnnotationComposer,
    $$VisitMaterialsTableCreateCompanionBuilder,
    $$VisitMaterialsTableUpdateCompanionBuilder,
    (
      VisitMaterial,
      BaseReferences<_$RiadDatabase, $VisitMaterialsTable, VisitMaterial>
    ),
    VisitMaterial,
    PrefetchHooks Function()> {
  $$VisitMaterialsTableTableManager(
      _$RiadDatabase db, $VisitMaterialsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitMaterialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitMaterialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitMaterialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> clientUuid = const Value.absent(),
            Value<String> visitUuid = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> itemName = const Value.absent(),
            Value<String?> serialNo = const Value.absent(),
            Value<int> qty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VisitMaterialsCompanion(
            clientUuid: clientUuid,
            visitUuid: visitUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            itemName: itemName,
            serialNo: serialNo,
            qty: qty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String clientUuid,
            required String visitUuid,
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> itemName = const Value.absent(),
            Value<String?> serialNo = const Value.absent(),
            Value<int> qty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VisitMaterialsCompanion.insert(
            clientUuid: clientUuid,
            visitUuid: visitUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            itemName: itemName,
            serialNo: serialNo,
            qty: qty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VisitMaterialsTableProcessedTableManager = ProcessedTableManager<
    _$RiadDatabase,
    $VisitMaterialsTable,
    VisitMaterial,
    $$VisitMaterialsTableFilterComposer,
    $$VisitMaterialsTableOrderingComposer,
    $$VisitMaterialsTableAnnotationComposer,
    $$VisitMaterialsTableCreateCompanionBuilder,
    $$VisitMaterialsTableUpdateCompanionBuilder,
    (
      VisitMaterial,
      BaseReferences<_$RiadDatabase, $VisitMaterialsTable, VisitMaterial>
    ),
    VisitMaterial,
    PrefetchHooks Function()>;
typedef $$VisitPhotosTableCreateCompanionBuilder = VisitPhotosCompanion
    Function({
  required String clientUuid,
  required String visitUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> driveFileId,
  Value<String?> description,
  Value<int> rowid,
});
typedef $$VisitPhotosTableUpdateCompanionBuilder = VisitPhotosCompanion
    Function({
  Value<String> clientUuid,
  Value<String> visitUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> driveFileId,
  Value<String?> description,
  Value<int> rowid,
});

class $$VisitPhotosTableFilterComposer
    extends Composer<_$RiadDatabase, $VisitPhotosTable> {
  $$VisitPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get visitUuid => $composableBuilder(
      column: $table.visitUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get driveFileId => $composableBuilder(
      column: $table.driveFileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));
}

class $$VisitPhotosTableOrderingComposer
    extends Composer<_$RiadDatabase, $VisitPhotosTable> {
  $$VisitPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get visitUuid => $composableBuilder(
      column: $table.visitUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get driveFileId => $composableBuilder(
      column: $table.driveFileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));
}

class $$VisitPhotosTableAnnotationComposer
    extends Composer<_$RiadDatabase, $VisitPhotosTable> {
  $$VisitPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => column);

  GeneratedColumn<String> get visitUuid =>
      $composableBuilder(column: $table.visitUuid, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get driveFileId => $composableBuilder(
      column: $table.driveFileId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);
}

class $$VisitPhotosTableTableManager extends RootTableManager<
    _$RiadDatabase,
    $VisitPhotosTable,
    VisitPhoto,
    $$VisitPhotosTableFilterComposer,
    $$VisitPhotosTableOrderingComposer,
    $$VisitPhotosTableAnnotationComposer,
    $$VisitPhotosTableCreateCompanionBuilder,
    $$VisitPhotosTableUpdateCompanionBuilder,
    (VisitPhoto, BaseReferences<_$RiadDatabase, $VisitPhotosTable, VisitPhoto>),
    VisitPhoto,
    PrefetchHooks Function()> {
  $$VisitPhotosTableTableManager(_$RiadDatabase db, $VisitPhotosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> clientUuid = const Value.absent(),
            Value<String> visitUuid = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> driveFileId = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VisitPhotosCompanion(
            clientUuid: clientUuid,
            visitUuid: visitUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            driveFileId: driveFileId,
            description: description,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String clientUuid,
            required String visitUuid,
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> driveFileId = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VisitPhotosCompanion.insert(
            clientUuid: clientUuid,
            visitUuid: visitUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            driveFileId: driveFileId,
            description: description,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VisitPhotosTableProcessedTableManager = ProcessedTableManager<
    _$RiadDatabase,
    $VisitPhotosTable,
    VisitPhoto,
    $$VisitPhotosTableFilterComposer,
    $$VisitPhotosTableOrderingComposer,
    $$VisitPhotosTableAnnotationComposer,
    $$VisitPhotosTableCreateCompanionBuilder,
    $$VisitPhotosTableUpdateCompanionBuilder,
    (VisitPhoto, BaseReferences<_$RiadDatabase, $VisitPhotosTable, VisitPhoto>),
    VisitPhoto,
    PrefetchHooks Function()>;
typedef $$ChecklistInstancesTableCreateCompanionBuilder
    = ChecklistInstancesCompanion Function({
  required String clientUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> template,
  Value<String?> passport,
  Value<String?> visit,
  Value<String?> status,
  Value<int> rowid,
});
typedef $$ChecklistInstancesTableUpdateCompanionBuilder
    = ChecklistInstancesCompanion Function({
  Value<String> clientUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> template,
  Value<String?> passport,
  Value<String?> visit,
  Value<String?> status,
  Value<int> rowid,
});

class $$ChecklistInstancesTableFilterComposer
    extends Composer<_$RiadDatabase, $ChecklistInstancesTable> {
  $$ChecklistInstancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get template => $composableBuilder(
      column: $table.template, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get passport => $composableBuilder(
      column: $table.passport, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get visit => $composableBuilder(
      column: $table.visit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$ChecklistInstancesTableOrderingComposer
    extends Composer<_$RiadDatabase, $ChecklistInstancesTable> {
  $$ChecklistInstancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get template => $composableBuilder(
      column: $table.template, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get passport => $composableBuilder(
      column: $table.passport, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get visit => $composableBuilder(
      column: $table.visit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$ChecklistInstancesTableAnnotationComposer
    extends Composer<_$RiadDatabase, $ChecklistInstancesTable> {
  $$ChecklistInstancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get template =>
      $composableBuilder(column: $table.template, builder: (column) => column);

  GeneratedColumn<String> get passport =>
      $composableBuilder(column: $table.passport, builder: (column) => column);

  GeneratedColumn<String> get visit =>
      $composableBuilder(column: $table.visit, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$ChecklistInstancesTableTableManager extends RootTableManager<
    _$RiadDatabase,
    $ChecklistInstancesTable,
    ChecklistInstance,
    $$ChecklistInstancesTableFilterComposer,
    $$ChecklistInstancesTableOrderingComposer,
    $$ChecklistInstancesTableAnnotationComposer,
    $$ChecklistInstancesTableCreateCompanionBuilder,
    $$ChecklistInstancesTableUpdateCompanionBuilder,
    (
      ChecklistInstance,
      BaseReferences<_$RiadDatabase, $ChecklistInstancesTable,
          ChecklistInstance>
    ),
    ChecklistInstance,
    PrefetchHooks Function()> {
  $$ChecklistInstancesTableTableManager(
      _$RiadDatabase db, $ChecklistInstancesTable table)
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
            Value<String> clientUuid = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> template = const Value.absent(),
            Value<String?> passport = const Value.absent(),
            Value<String?> visit = const Value.absent(),
            Value<String?> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChecklistInstancesCompanion(
            clientUuid: clientUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            template: template,
            passport: passport,
            visit: visit,
            status: status,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String clientUuid,
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> template = const Value.absent(),
            Value<String?> passport = const Value.absent(),
            Value<String?> visit = const Value.absent(),
            Value<String?> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChecklistInstancesCompanion.insert(
            clientUuid: clientUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            template: template,
            passport: passport,
            visit: visit,
            status: status,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChecklistInstancesTableProcessedTableManager = ProcessedTableManager<
    _$RiadDatabase,
    $ChecklistInstancesTable,
    ChecklistInstance,
    $$ChecklistInstancesTableFilterComposer,
    $$ChecklistInstancesTableOrderingComposer,
    $$ChecklistInstancesTableAnnotationComposer,
    $$ChecklistInstancesTableCreateCompanionBuilder,
    $$ChecklistInstancesTableUpdateCompanionBuilder,
    (
      ChecklistInstance,
      BaseReferences<_$RiadDatabase, $ChecklistInstancesTable,
          ChecklistInstance>
    ),
    ChecklistInstance,
    PrefetchHooks Function()>;
typedef $$ChecklistInstanceItemsTableCreateCompanionBuilder
    = ChecklistInstanceItemsCompanion Function({
  required String itemUuid,
  required String instanceUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> checkedBy,
  Value<String?> photo,
  Value<String?> value,
  Value<String?> serialNo,
  Value<int> rowid,
});
typedef $$ChecklistInstanceItemsTableUpdateCompanionBuilder
    = ChecklistInstanceItemsCompanion Function({
  Value<String> itemUuid,
  Value<String> instanceUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> checkedBy,
  Value<String?> photo,
  Value<String?> value,
  Value<String?> serialNo,
  Value<int> rowid,
});

class $$ChecklistInstanceItemsTableFilterComposer
    extends Composer<_$RiadDatabase, $ChecklistInstanceItemsTable> {
  $$ChecklistInstanceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemUuid => $composableBuilder(
      column: $table.itemUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get instanceUuid => $composableBuilder(
      column: $table.instanceUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkedBy => $composableBuilder(
      column: $table.checkedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photo => $composableBuilder(
      column: $table.photo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serialNo => $composableBuilder(
      column: $table.serialNo, builder: (column) => ColumnFilters(column));
}

class $$ChecklistInstanceItemsTableOrderingComposer
    extends Composer<_$RiadDatabase, $ChecklistInstanceItemsTable> {
  $$ChecklistInstanceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemUuid => $composableBuilder(
      column: $table.itemUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get instanceUuid => $composableBuilder(
      column: $table.instanceUuid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkedBy => $composableBuilder(
      column: $table.checkedBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photo => $composableBuilder(
      column: $table.photo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serialNo => $composableBuilder(
      column: $table.serialNo, builder: (column) => ColumnOrderings(column));
}

class $$ChecklistInstanceItemsTableAnnotationComposer
    extends Composer<_$RiadDatabase, $ChecklistInstanceItemsTable> {
  $$ChecklistInstanceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemUuid =>
      $composableBuilder(column: $table.itemUuid, builder: (column) => column);

  GeneratedColumn<String> get instanceUuid => $composableBuilder(
      column: $table.instanceUuid, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get checkedBy =>
      $composableBuilder(column: $table.checkedBy, builder: (column) => column);

  GeneratedColumn<String> get photo =>
      $composableBuilder(column: $table.photo, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get serialNo =>
      $composableBuilder(column: $table.serialNo, builder: (column) => column);
}

class $$ChecklistInstanceItemsTableTableManager extends RootTableManager<
    _$RiadDatabase,
    $ChecklistInstanceItemsTable,
    ChecklistInstanceItem,
    $$ChecklistInstanceItemsTableFilterComposer,
    $$ChecklistInstanceItemsTableOrderingComposer,
    $$ChecklistInstanceItemsTableAnnotationComposer,
    $$ChecklistInstanceItemsTableCreateCompanionBuilder,
    $$ChecklistInstanceItemsTableUpdateCompanionBuilder,
    (
      ChecklistInstanceItem,
      BaseReferences<_$RiadDatabase, $ChecklistInstanceItemsTable,
          ChecklistInstanceItem>
    ),
    ChecklistInstanceItem,
    PrefetchHooks Function()> {
  $$ChecklistInstanceItemsTableTableManager(
      _$RiadDatabase db, $ChecklistInstanceItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistInstanceItemsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistInstanceItemsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistInstanceItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> itemUuid = const Value.absent(),
            Value<String> instanceUuid = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> checkedBy = const Value.absent(),
            Value<String?> photo = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<String?> serialNo = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChecklistInstanceItemsCompanion(
            itemUuid: itemUuid,
            instanceUuid: instanceUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            checkedBy: checkedBy,
            photo: photo,
            value: value,
            serialNo: serialNo,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String itemUuid,
            required String instanceUuid,
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> checkedBy = const Value.absent(),
            Value<String?> photo = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<String?> serialNo = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChecklistInstanceItemsCompanion.insert(
            itemUuid: itemUuid,
            instanceUuid: instanceUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            checkedBy: checkedBy,
            photo: photo,
            value: value,
            serialNo: serialNo,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChecklistInstanceItemsTableProcessedTableManager
    = ProcessedTableManager<
        _$RiadDatabase,
        $ChecklistInstanceItemsTable,
        ChecklistInstanceItem,
        $$ChecklistInstanceItemsTableFilterComposer,
        $$ChecklistInstanceItemsTableOrderingComposer,
        $$ChecklistInstanceItemsTableAnnotationComposer,
        $$ChecklistInstanceItemsTableCreateCompanionBuilder,
        $$ChecklistInstanceItemsTableUpdateCompanionBuilder,
        (
          ChecklistInstanceItem,
          BaseReferences<_$RiadDatabase, $ChecklistInstanceItemsTable,
              ChecklistInstanceItem>
        ),
        ChecklistInstanceItem,
        PrefetchHooks Function()>;
typedef $$InstallationMapsTableCreateCompanionBuilder
    = InstallationMapsCompanion Function({
  required String clientUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> passport,
  Value<String?> name_,
  Value<int> rowid,
});
typedef $$InstallationMapsTableUpdateCompanionBuilder
    = InstallationMapsCompanion Function({
  Value<String> clientUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> passport,
  Value<String?> name_,
  Value<int> rowid,
});

class $$InstallationMapsTableFilterComposer
    extends Composer<_$RiadDatabase, $InstallationMapsTable> {
  $$InstallationMapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get passport => $composableBuilder(
      column: $table.passport, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name_ => $composableBuilder(
      column: $table.name_, builder: (column) => ColumnFilters(column));
}

class $$InstallationMapsTableOrderingComposer
    extends Composer<_$RiadDatabase, $InstallationMapsTable> {
  $$InstallationMapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get passport => $composableBuilder(
      column: $table.passport, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name_ => $composableBuilder(
      column: $table.name_, builder: (column) => ColumnOrderings(column));
}

class $$InstallationMapsTableAnnotationComposer
    extends Composer<_$RiadDatabase, $InstallationMapsTable> {
  $$InstallationMapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get passport =>
      $composableBuilder(column: $table.passport, builder: (column) => column);

  GeneratedColumn<String> get name_ =>
      $composableBuilder(column: $table.name_, builder: (column) => column);
}

class $$InstallationMapsTableTableManager extends RootTableManager<
    _$RiadDatabase,
    $InstallationMapsTable,
    InstallationMap,
    $$InstallationMapsTableFilterComposer,
    $$InstallationMapsTableOrderingComposer,
    $$InstallationMapsTableAnnotationComposer,
    $$InstallationMapsTableCreateCompanionBuilder,
    $$InstallationMapsTableUpdateCompanionBuilder,
    (
      InstallationMap,
      BaseReferences<_$RiadDatabase, $InstallationMapsTable, InstallationMap>
    ),
    InstallationMap,
    PrefetchHooks Function()> {
  $$InstallationMapsTableTableManager(
      _$RiadDatabase db, $InstallationMapsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstallationMapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstallationMapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstallationMapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> clientUuid = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> passport = const Value.absent(),
            Value<String?> name_ = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InstallationMapsCompanion(
            clientUuid: clientUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            passport: passport,
            name_: name_,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String clientUuid,
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> passport = const Value.absent(),
            Value<String?> name_ = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InstallationMapsCompanion.insert(
            clientUuid: clientUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            passport: passport,
            name_: name_,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InstallationMapsTableProcessedTableManager = ProcessedTableManager<
    _$RiadDatabase,
    $InstallationMapsTable,
    InstallationMap,
    $$InstallationMapsTableFilterComposer,
    $$InstallationMapsTableOrderingComposer,
    $$InstallationMapsTableAnnotationComposer,
    $$InstallationMapsTableCreateCompanionBuilder,
    $$InstallationMapsTableUpdateCompanionBuilder,
    (
      InstallationMap,
      BaseReferences<_$RiadDatabase, $InstallationMapsTable, InstallationMap>
    ),
    InstallationMap,
    PrefetchHooks Function()>;
typedef $$MountPointsTableCreateCompanionBuilder = MountPointsCompanion
    Function({
  required String pointUuid,
  required String mapUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> type,
  Value<String?> label,
  Value<double?> x,
  Value<double?> y,
  Value<String?> status,
  Value<String?> item,
  Value<String?> serialNo,
  Value<String?> photo,
  Value<int> rowid,
});
typedef $$MountPointsTableUpdateCompanionBuilder = MountPointsCompanion
    Function({
  Value<String> pointUuid,
  Value<String> mapUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> type,
  Value<String?> label,
  Value<double?> x,
  Value<double?> y,
  Value<String?> status,
  Value<String?> item,
  Value<String?> serialNo,
  Value<String?> photo,
  Value<int> rowid,
});

class $$MountPointsTableFilterComposer
    extends Composer<_$RiadDatabase, $MountPointsTable> {
  $$MountPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pointUuid => $composableBuilder(
      column: $table.pointUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mapUuid => $composableBuilder(
      column: $table.mapUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get x => $composableBuilder(
      column: $table.x, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get y => $composableBuilder(
      column: $table.y, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get item => $composableBuilder(
      column: $table.item, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serialNo => $composableBuilder(
      column: $table.serialNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photo => $composableBuilder(
      column: $table.photo, builder: (column) => ColumnFilters(column));
}

class $$MountPointsTableOrderingComposer
    extends Composer<_$RiadDatabase, $MountPointsTable> {
  $$MountPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pointUuid => $composableBuilder(
      column: $table.pointUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mapUuid => $composableBuilder(
      column: $table.mapUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get x => $composableBuilder(
      column: $table.x, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get y => $composableBuilder(
      column: $table.y, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get item => $composableBuilder(
      column: $table.item, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serialNo => $composableBuilder(
      column: $table.serialNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photo => $composableBuilder(
      column: $table.photo, builder: (column) => ColumnOrderings(column));
}

class $$MountPointsTableAnnotationComposer
    extends Composer<_$RiadDatabase, $MountPointsTable> {
  $$MountPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pointUuid =>
      $composableBuilder(column: $table.pointUuid, builder: (column) => column);

  GeneratedColumn<String> get mapUuid =>
      $composableBuilder(column: $table.mapUuid, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get item =>
      $composableBuilder(column: $table.item, builder: (column) => column);

  GeneratedColumn<String> get serialNo =>
      $composableBuilder(column: $table.serialNo, builder: (column) => column);

  GeneratedColumn<String> get photo =>
      $composableBuilder(column: $table.photo, builder: (column) => column);
}

class $$MountPointsTableTableManager extends RootTableManager<
    _$RiadDatabase,
    $MountPointsTable,
    MountPoint,
    $$MountPointsTableFilterComposer,
    $$MountPointsTableOrderingComposer,
    $$MountPointsTableAnnotationComposer,
    $$MountPointsTableCreateCompanionBuilder,
    $$MountPointsTableUpdateCompanionBuilder,
    (MountPoint, BaseReferences<_$RiadDatabase, $MountPointsTable, MountPoint>),
    MountPoint,
    PrefetchHooks Function()> {
  $$MountPointsTableTableManager(_$RiadDatabase db, $MountPointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MountPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MountPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MountPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> pointUuid = const Value.absent(),
            Value<String> mapUuid = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> type = const Value.absent(),
            Value<String?> label = const Value.absent(),
            Value<double?> x = const Value.absent(),
            Value<double?> y = const Value.absent(),
            Value<String?> status = const Value.absent(),
            Value<String?> item = const Value.absent(),
            Value<String?> serialNo = const Value.absent(),
            Value<String?> photo = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MountPointsCompanion(
            pointUuid: pointUuid,
            mapUuid: mapUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            type: type,
            label: label,
            x: x,
            y: y,
            status: status,
            item: item,
            serialNo: serialNo,
            photo: photo,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String pointUuid,
            required String mapUuid,
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> type = const Value.absent(),
            Value<String?> label = const Value.absent(),
            Value<double?> x = const Value.absent(),
            Value<double?> y = const Value.absent(),
            Value<String?> status = const Value.absent(),
            Value<String?> item = const Value.absent(),
            Value<String?> serialNo = const Value.absent(),
            Value<String?> photo = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MountPointsCompanion.insert(
            pointUuid: pointUuid,
            mapUuid: mapUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            type: type,
            label: label,
            x: x,
            y: y,
            status: status,
            item: item,
            serialNo: serialNo,
            photo: photo,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MountPointsTableProcessedTableManager = ProcessedTableManager<
    _$RiadDatabase,
    $MountPointsTable,
    MountPoint,
    $$MountPointsTableFilterComposer,
    $$MountPointsTableOrderingComposer,
    $$MountPointsTableAnnotationComposer,
    $$MountPointsTableCreateCompanionBuilder,
    $$MountPointsTableUpdateCompanionBuilder,
    (MountPoint, BaseReferences<_$RiadDatabase, $MountPointsTable, MountPoint>),
    MountPoint,
    PrefetchHooks Function()>;
typedef $$CableRoutesTableCreateCompanionBuilder = CableRoutesCompanion
    Function({
  required String routeUuid,
  required String mapUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> fromPoint,
  Value<String?> toPoint,
  Value<String?> pathJson,
  Value<int> rowid,
});
typedef $$CableRoutesTableUpdateCompanionBuilder = CableRoutesCompanion
    Function({
  Value<String> routeUuid,
  Value<String> mapUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> fromPoint,
  Value<String?> toPoint,
  Value<String?> pathJson,
  Value<int> rowid,
});

class $$CableRoutesTableFilterComposer
    extends Composer<_$RiadDatabase, $CableRoutesTable> {
  $$CableRoutesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get routeUuid => $composableBuilder(
      column: $table.routeUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mapUuid => $composableBuilder(
      column: $table.mapUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromPoint => $composableBuilder(
      column: $table.fromPoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toPoint => $composableBuilder(
      column: $table.toPoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pathJson => $composableBuilder(
      column: $table.pathJson, builder: (column) => ColumnFilters(column));
}

class $$CableRoutesTableOrderingComposer
    extends Composer<_$RiadDatabase, $CableRoutesTable> {
  $$CableRoutesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get routeUuid => $composableBuilder(
      column: $table.routeUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mapUuid => $composableBuilder(
      column: $table.mapUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromPoint => $composableBuilder(
      column: $table.fromPoint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toPoint => $composableBuilder(
      column: $table.toPoint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pathJson => $composableBuilder(
      column: $table.pathJson, builder: (column) => ColumnOrderings(column));
}

class $$CableRoutesTableAnnotationComposer
    extends Composer<_$RiadDatabase, $CableRoutesTable> {
  $$CableRoutesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get routeUuid =>
      $composableBuilder(column: $table.routeUuid, builder: (column) => column);

  GeneratedColumn<String> get mapUuid =>
      $composableBuilder(column: $table.mapUuid, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get fromPoint =>
      $composableBuilder(column: $table.fromPoint, builder: (column) => column);

  GeneratedColumn<String> get toPoint =>
      $composableBuilder(column: $table.toPoint, builder: (column) => column);

  GeneratedColumn<String> get pathJson =>
      $composableBuilder(column: $table.pathJson, builder: (column) => column);
}

class $$CableRoutesTableTableManager extends RootTableManager<
    _$RiadDatabase,
    $CableRoutesTable,
    CableRoute,
    $$CableRoutesTableFilterComposer,
    $$CableRoutesTableOrderingComposer,
    $$CableRoutesTableAnnotationComposer,
    $$CableRoutesTableCreateCompanionBuilder,
    $$CableRoutesTableUpdateCompanionBuilder,
    (CableRoute, BaseReferences<_$RiadDatabase, $CableRoutesTable, CableRoute>),
    CableRoute,
    PrefetchHooks Function()> {
  $$CableRoutesTableTableManager(_$RiadDatabase db, $CableRoutesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CableRoutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CableRoutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CableRoutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> routeUuid = const Value.absent(),
            Value<String> mapUuid = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> fromPoint = const Value.absent(),
            Value<String?> toPoint = const Value.absent(),
            Value<String?> pathJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CableRoutesCompanion(
            routeUuid: routeUuid,
            mapUuid: mapUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            fromPoint: fromPoint,
            toPoint: toPoint,
            pathJson: pathJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String routeUuid,
            required String mapUuid,
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> fromPoint = const Value.absent(),
            Value<String?> toPoint = const Value.absent(),
            Value<String?> pathJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CableRoutesCompanion.insert(
            routeUuid: routeUuid,
            mapUuid: mapUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            fromPoint: fromPoint,
            toPoint: toPoint,
            pathJson: pathJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CableRoutesTableProcessedTableManager = ProcessedTableManager<
    _$RiadDatabase,
    $CableRoutesTable,
    CableRoute,
    $$CableRoutesTableFilterComposer,
    $$CableRoutesTableOrderingComposer,
    $$CableRoutesTableAnnotationComposer,
    $$CableRoutesTableCreateCompanionBuilder,
    $$CableRoutesTableUpdateCompanionBuilder,
    (CableRoute, BaseReferences<_$RiadDatabase, $CableRoutesTable, CableRoute>),
    CableRoute,
    PrefetchHooks Function()>;
typedef $$MediaAssetsTableCreateCompanionBuilder = MediaAssetsCompanion
    Function({
  required String clientUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> driveFileId,
  Value<bool> aiAllowed,
  Value<String?> transcriptionStatus,
  Value<String?> mediaType,
  Value<String?> tag,
  Value<String?> parentDoctype,
  Value<String?> parentName,
  Value<String?> localPath,
  Value<String?> transcription,
  Value<int> rowid,
});
typedef $$MediaAssetsTableUpdateCompanionBuilder = MediaAssetsCompanion
    Function({
  Value<String> clientUuid,
  Value<int> riadVersion,
  Value<bool> riadDeleted,
  Value<DateTime?> riadDeletedAt,
  Value<String?> driveFileId,
  Value<bool> aiAllowed,
  Value<String?> transcriptionStatus,
  Value<String?> mediaType,
  Value<String?> tag,
  Value<String?> parentDoctype,
  Value<String?> parentName,
  Value<String?> localPath,
  Value<String?> transcription,
  Value<int> rowid,
});

class $$MediaAssetsTableFilterComposer
    extends Composer<_$RiadDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get driveFileId => $composableBuilder(
      column: $table.driveFileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get aiAllowed => $composableBuilder(
      column: $table.aiAllowed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcriptionStatus => $composableBuilder(
      column: $table.transcriptionStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentDoctype => $composableBuilder(
      column: $table.parentDoctype, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcription => $composableBuilder(
      column: $table.transcription, builder: (column) => ColumnFilters(column));
}

class $$MediaAssetsTableOrderingComposer
    extends Composer<_$RiadDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get driveFileId => $composableBuilder(
      column: $table.driveFileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get aiAllowed => $composableBuilder(
      column: $table.aiAllowed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcriptionStatus => $composableBuilder(
      column: $table.transcriptionStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentDoctype => $composableBuilder(
      column: $table.parentDoctype,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcription => $composableBuilder(
      column: $table.transcription,
      builder: (column) => ColumnOrderings(column));
}

class $$MediaAssetsTableAnnotationComposer
    extends Composer<_$RiadDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientUuid => $composableBuilder(
      column: $table.clientUuid, builder: (column) => column);

  GeneratedColumn<int> get riadVersion => $composableBuilder(
      column: $table.riadVersion, builder: (column) => column);

  GeneratedColumn<bool> get riadDeleted => $composableBuilder(
      column: $table.riadDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get riadDeletedAt => $composableBuilder(
      column: $table.riadDeletedAt, builder: (column) => column);

  GeneratedColumn<String> get driveFileId => $composableBuilder(
      column: $table.driveFileId, builder: (column) => column);

  GeneratedColumn<bool> get aiAllowed =>
      $composableBuilder(column: $table.aiAllowed, builder: (column) => column);

  GeneratedColumn<String> get transcriptionStatus => $composableBuilder(
      column: $table.transcriptionStatus, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get parentDoctype => $composableBuilder(
      column: $table.parentDoctype, builder: (column) => column);

  GeneratedColumn<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get transcription => $composableBuilder(
      column: $table.transcription, builder: (column) => column);
}

class $$MediaAssetsTableTableManager extends RootTableManager<
    _$RiadDatabase,
    $MediaAssetsTable,
    MediaAsset,
    $$MediaAssetsTableFilterComposer,
    $$MediaAssetsTableOrderingComposer,
    $$MediaAssetsTableAnnotationComposer,
    $$MediaAssetsTableCreateCompanionBuilder,
    $$MediaAssetsTableUpdateCompanionBuilder,
    (MediaAsset, BaseReferences<_$RiadDatabase, $MediaAssetsTable, MediaAsset>),
    MediaAsset,
    PrefetchHooks Function()> {
  $$MediaAssetsTableTableManager(_$RiadDatabase db, $MediaAssetsTable table)
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
            Value<String> clientUuid = const Value.absent(),
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> driveFileId = const Value.absent(),
            Value<bool> aiAllowed = const Value.absent(),
            Value<String?> transcriptionStatus = const Value.absent(),
            Value<String?> mediaType = const Value.absent(),
            Value<String?> tag = const Value.absent(),
            Value<String?> parentDoctype = const Value.absent(),
            Value<String?> parentName = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String?> transcription = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaAssetsCompanion(
            clientUuid: clientUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            driveFileId: driveFileId,
            aiAllowed: aiAllowed,
            transcriptionStatus: transcriptionStatus,
            mediaType: mediaType,
            tag: tag,
            parentDoctype: parentDoctype,
            parentName: parentName,
            localPath: localPath,
            transcription: transcription,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String clientUuid,
            Value<int> riadVersion = const Value.absent(),
            Value<bool> riadDeleted = const Value.absent(),
            Value<DateTime?> riadDeletedAt = const Value.absent(),
            Value<String?> driveFileId = const Value.absent(),
            Value<bool> aiAllowed = const Value.absent(),
            Value<String?> transcriptionStatus = const Value.absent(),
            Value<String?> mediaType = const Value.absent(),
            Value<String?> tag = const Value.absent(),
            Value<String?> parentDoctype = const Value.absent(),
            Value<String?> parentName = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String?> transcription = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaAssetsCompanion.insert(
            clientUuid: clientUuid,
            riadVersion: riadVersion,
            riadDeleted: riadDeleted,
            riadDeletedAt: riadDeletedAt,
            driveFileId: driveFileId,
            aiAllowed: aiAllowed,
            transcriptionStatus: transcriptionStatus,
            mediaType: mediaType,
            tag: tag,
            parentDoctype: parentDoctype,
            parentName: parentName,
            localPath: localPath,
            transcription: transcription,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaAssetsTableProcessedTableManager = ProcessedTableManager<
    _$RiadDatabase,
    $MediaAssetsTable,
    MediaAsset,
    $$MediaAssetsTableFilterComposer,
    $$MediaAssetsTableOrderingComposer,
    $$MediaAssetsTableAnnotationComposer,
    $$MediaAssetsTableCreateCompanionBuilder,
    $$MediaAssetsTableUpdateCompanionBuilder,
    (MediaAsset, BaseReferences<_$RiadDatabase, $MediaAssetsTable, MediaAsset>),
    MediaAsset,
    PrefetchHooks Function()>;
typedef $$PendingMediaUploadsTableCreateCompanionBuilder
    = PendingMediaUploadsCompanion Function({
  Value<int> id,
  required String clientUuid,
  required String localPath,
  required String mediaType,
  Value<String?> tag,
  Value<String?> parentDoctype,
  Value<String?> parentName,
  Value<String> status,
  required int createdAt,
});
typedef $$PendingMediaUploadsTableUpdateCompanionBuilder
    = PendingMediaUploadsCompanion Function({
  Value<int> id,
  Value<String> clientUuid,
  Value<String> localPath,
  Value<String> mediaType,
  Value<String?> tag,
  Value<String?> parentDoctype,
  Value<String?> parentName,
  Value<String> status,
  Value<int> createdAt,
});

class $$PendingMediaUploadsTableFilterComposer
    extends Composer<_$RiadDatabase, $PendingMediaUploadsTable> {
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

  ColumnFilters<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentDoctype => $composableBuilder(
      column: $table.parentDoctype, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PendingMediaUploadsTableOrderingComposer
    extends Composer<_$RiadDatabase, $PendingMediaUploadsTable> {
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

  ColumnOrderings<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentDoctype => $composableBuilder(
      column: $table.parentDoctype,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PendingMediaUploadsTableAnnotationComposer
    extends Composer<_$RiadDatabase, $PendingMediaUploadsTable> {
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

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get parentDoctype => $composableBuilder(
      column: $table.parentDoctype, builder: (column) => column);

  GeneratedColumn<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingMediaUploadsTableTableManager extends RootTableManager<
    _$RiadDatabase,
    $PendingMediaUploadsTable,
    PendingMediaUpload,
    $$PendingMediaUploadsTableFilterComposer,
    $$PendingMediaUploadsTableOrderingComposer,
    $$PendingMediaUploadsTableAnnotationComposer,
    $$PendingMediaUploadsTableCreateCompanionBuilder,
    $$PendingMediaUploadsTableUpdateCompanionBuilder,
    (
      PendingMediaUpload,
      BaseReferences<_$RiadDatabase, $PendingMediaUploadsTable,
          PendingMediaUpload>
    ),
    PendingMediaUpload,
    PrefetchHooks Function()> {
  $$PendingMediaUploadsTableTableManager(
      _$RiadDatabase db, $PendingMediaUploadsTable table)
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
            Value<String?> tag = const Value.absent(),
            Value<String?> parentDoctype = const Value.absent(),
            Value<String?> parentName = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              PendingMediaUploadsCompanion(
            id: id,
            clientUuid: clientUuid,
            localPath: localPath,
            mediaType: mediaType,
            tag: tag,
            parentDoctype: parentDoctype,
            parentName: parentName,
            status: status,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String clientUuid,
            required String localPath,
            required String mediaType,
            Value<String?> tag = const Value.absent(),
            Value<String?> parentDoctype = const Value.absent(),
            Value<String?> parentName = const Value.absent(),
            Value<String> status = const Value.absent(),
            required int createdAt,
          }) =>
              PendingMediaUploadsCompanion.insert(
            id: id,
            clientUuid: clientUuid,
            localPath: localPath,
            mediaType: mediaType,
            tag: tag,
            parentDoctype: parentDoctype,
            parentName: parentName,
            status: status,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingMediaUploadsTableProcessedTableManager = ProcessedTableManager<
    _$RiadDatabase,
    $PendingMediaUploadsTable,
    PendingMediaUpload,
    $$PendingMediaUploadsTableFilterComposer,
    $$PendingMediaUploadsTableOrderingComposer,
    $$PendingMediaUploadsTableAnnotationComposer,
    $$PendingMediaUploadsTableCreateCompanionBuilder,
    $$PendingMediaUploadsTableUpdateCompanionBuilder,
    (
      PendingMediaUpload,
      BaseReferences<_$RiadDatabase, $PendingMediaUploadsTable,
          PendingMediaUpload>
    ),
    PendingMediaUpload,
    PrefetchHooks Function()>;
typedef $$SyncConflictsTableCreateCompanionBuilder = SyncConflictsCompanion
    Function({
  required String conflictId,
  required String doctype,
  required String docname,
  required String fieldName,
  Value<String?> serverValue,
  Value<String?> clientValue,
  Value<bool> resolved,
  Value<int> rowid,
});
typedef $$SyncConflictsTableUpdateCompanionBuilder = SyncConflictsCompanion
    Function({
  Value<String> conflictId,
  Value<String> doctype,
  Value<String> docname,
  Value<String> fieldName,
  Value<String?> serverValue,
  Value<String?> clientValue,
  Value<bool> resolved,
  Value<int> rowid,
});

class $$SyncConflictsTableFilterComposer
    extends Composer<_$RiadDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conflictId => $composableBuilder(
      column: $table.conflictId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get doctype => $composableBuilder(
      column: $table.doctype, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get docname => $composableBuilder(
      column: $table.docname, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fieldName => $composableBuilder(
      column: $table.fieldName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverValue => $composableBuilder(
      column: $table.serverValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientValue => $composableBuilder(
      column: $table.clientValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get resolved => $composableBuilder(
      column: $table.resolved, builder: (column) => ColumnFilters(column));
}

class $$SyncConflictsTableOrderingComposer
    extends Composer<_$RiadDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conflictId => $composableBuilder(
      column: $table.conflictId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get doctype => $composableBuilder(
      column: $table.doctype, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get docname => $composableBuilder(
      column: $table.docname, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fieldName => $composableBuilder(
      column: $table.fieldName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverValue => $composableBuilder(
      column: $table.serverValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientValue => $composableBuilder(
      column: $table.clientValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get resolved => $composableBuilder(
      column: $table.resolved, builder: (column) => ColumnOrderings(column));
}

class $$SyncConflictsTableAnnotationComposer
    extends Composer<_$RiadDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conflictId => $composableBuilder(
      column: $table.conflictId, builder: (column) => column);

  GeneratedColumn<String> get doctype =>
      $composableBuilder(column: $table.doctype, builder: (column) => column);

  GeneratedColumn<String> get docname =>
      $composableBuilder(column: $table.docname, builder: (column) => column);

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<String> get serverValue => $composableBuilder(
      column: $table.serverValue, builder: (column) => column);

  GeneratedColumn<String> get clientValue => $composableBuilder(
      column: $table.clientValue, builder: (column) => column);

  GeneratedColumn<bool> get resolved =>
      $composableBuilder(column: $table.resolved, builder: (column) => column);
}

class $$SyncConflictsTableTableManager extends RootTableManager<
    _$RiadDatabase,
    $SyncConflictsTable,
    SyncConflict,
    $$SyncConflictsTableFilterComposer,
    $$SyncConflictsTableOrderingComposer,
    $$SyncConflictsTableAnnotationComposer,
    $$SyncConflictsTableCreateCompanionBuilder,
    $$SyncConflictsTableUpdateCompanionBuilder,
    (
      SyncConflict,
      BaseReferences<_$RiadDatabase, $SyncConflictsTable, SyncConflict>
    ),
    SyncConflict,
    PrefetchHooks Function()> {
  $$SyncConflictsTableTableManager(_$RiadDatabase db, $SyncConflictsTable table)
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
            Value<String> conflictId = const Value.absent(),
            Value<String> doctype = const Value.absent(),
            Value<String> docname = const Value.absent(),
            Value<String> fieldName = const Value.absent(),
            Value<String?> serverValue = const Value.absent(),
            Value<String?> clientValue = const Value.absent(),
            Value<bool> resolved = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncConflictsCompanion(
            conflictId: conflictId,
            doctype: doctype,
            docname: docname,
            fieldName: fieldName,
            serverValue: serverValue,
            clientValue: clientValue,
            resolved: resolved,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String conflictId,
            required String doctype,
            required String docname,
            required String fieldName,
            Value<String?> serverValue = const Value.absent(),
            Value<String?> clientValue = const Value.absent(),
            Value<bool> resolved = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncConflictsCompanion.insert(
            conflictId: conflictId,
            doctype: doctype,
            docname: docname,
            fieldName: fieldName,
            serverValue: serverValue,
            clientValue: clientValue,
            resolved: resolved,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncConflictsTableProcessedTableManager = ProcessedTableManager<
    _$RiadDatabase,
    $SyncConflictsTable,
    SyncConflict,
    $$SyncConflictsTableFilterComposer,
    $$SyncConflictsTableOrderingComposer,
    $$SyncConflictsTableAnnotationComposer,
    $$SyncConflictsTableCreateCompanionBuilder,
    $$SyncConflictsTableUpdateCompanionBuilder,
    (
      SyncConflict,
      BaseReferences<_$RiadDatabase, $SyncConflictsTable, SyncConflict>
    ),
    SyncConflict,
    PrefetchHooks Function()>;

class $RiadDatabaseManager {
  final _$RiadDatabase _db;
  $RiadDatabaseManager(this._db);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
  $$PendingOpsTableTableManager get pendingOps =>
      $$PendingOpsTableTableManager(_db, _db.pendingOps);
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db, _db.visits);
  $$VisitMaterialsTableTableManager get visitMaterials =>
      $$VisitMaterialsTableTableManager(_db, _db.visitMaterials);
  $$VisitPhotosTableTableManager get visitPhotos =>
      $$VisitPhotosTableTableManager(_db, _db.visitPhotos);
  $$ChecklistInstancesTableTableManager get checklistInstances =>
      $$ChecklistInstancesTableTableManager(_db, _db.checklistInstances);
  $$ChecklistInstanceItemsTableTableManager get checklistInstanceItems =>
      $$ChecklistInstanceItemsTableTableManager(
          _db, _db.checklistInstanceItems);
  $$InstallationMapsTableTableManager get installationMaps =>
      $$InstallationMapsTableTableManager(_db, _db.installationMaps);
  $$MountPointsTableTableManager get mountPoints =>
      $$MountPointsTableTableManager(_db, _db.mountPoints);
  $$CableRoutesTableTableManager get cableRoutes =>
      $$CableRoutesTableTableManager(_db, _db.cableRoutes);
  $$MediaAssetsTableTableManager get mediaAssets =>
      $$MediaAssetsTableTableManager(_db, _db.mediaAssets);
  $$PendingMediaUploadsTableTableManager get pendingMediaUploads =>
      $$PendingMediaUploadsTableTableManager(_db, _db.pendingMediaUploads);
  $$SyncConflictsTableTableManager get syncConflicts =>
      $$SyncConflictsTableTableManager(_db, _db.syncConflicts);
}
