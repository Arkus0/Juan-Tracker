// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RoutinesTable extends Routines with TableInfo<$RoutinesTable, Routine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schedulingModeMeta = const VerificationMeta(
    'schedulingMode',
  );
  @override
  late final GeneratedColumn<String> schedulingMode = GeneratedColumn<String>(
    'scheduling_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sequential'),
  );
  static const VerificationMeta _schedulingConfigMeta = const VerificationMeta(
    'schedulingConfig',
  );
  @override
  late final GeneratedColumn<String> schedulingConfig = GeneratedColumn<String>(
    'scheduling_config',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdAt,
    schedulingMode,
    schedulingConfig,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routines';
  @override
  VerificationContext validateIntegrity(
    Insertable<Routine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('scheduling_mode')) {
      context.handle(
        _schedulingModeMeta,
        schedulingMode.isAcceptableOrUnknown(
          data['scheduling_mode']!,
          _schedulingModeMeta,
        ),
      );
    }
    if (data.containsKey('scheduling_config')) {
      context.handle(
        _schedulingConfigMeta,
        schedulingConfig.isAcceptableOrUnknown(
          data['scheduling_config']!,
          _schedulingConfigMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Routine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Routine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      schedulingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduling_mode'],
      )!,
      schedulingConfig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduling_config'],
      ),
    );
  }

  @override
  $RoutinesTable createAlias(String alias) {
    return $RoutinesTable(attachedDatabase, alias);
  }
}

class Routine extends DataClass implements Insertable<Routine> {
  final String id;
  final String name;
  final DateTime createdAt;
  final String schedulingMode;
  final String? schedulingConfig;
  const Routine({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.schedulingMode,
    this.schedulingConfig,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['scheduling_mode'] = Variable<String>(schedulingMode);
    if (!nullToAbsent || schedulingConfig != null) {
      map['scheduling_config'] = Variable<String>(schedulingConfig);
    }
    return map;
  }

  RoutinesCompanion toCompanion(bool nullToAbsent) {
    return RoutinesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      schedulingMode: Value(schedulingMode),
      schedulingConfig: schedulingConfig == null && nullToAbsent
          ? const Value.absent()
          : Value(schedulingConfig),
    );
  }

  factory Routine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Routine(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      schedulingMode: serializer.fromJson<String>(json['schedulingMode']),
      schedulingConfig: serializer.fromJson<String?>(json['schedulingConfig']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'schedulingMode': serializer.toJson<String>(schedulingMode),
      'schedulingConfig': serializer.toJson<String?>(schedulingConfig),
    };
  }

  Routine copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    String? schedulingMode,
    Value<String?> schedulingConfig = const Value.absent(),
  }) => Routine(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    schedulingMode: schedulingMode ?? this.schedulingMode,
    schedulingConfig: schedulingConfig.present
        ? schedulingConfig.value
        : this.schedulingConfig,
  );
  Routine copyWithCompanion(RoutinesCompanion data) {
    return Routine(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      schedulingMode: data.schedulingMode.present
          ? data.schedulingMode.value
          : this.schedulingMode,
      schedulingConfig: data.schedulingConfig.present
          ? data.schedulingConfig.value
          : this.schedulingConfig,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Routine(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('schedulingMode: $schedulingMode, ')
          ..write('schedulingConfig: $schedulingConfig')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, createdAt, schedulingMode, schedulingConfig);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Routine &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.schedulingMode == this.schedulingMode &&
          other.schedulingConfig == this.schedulingConfig);
}

class RoutinesCompanion extends UpdateCompanion<Routine> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<String> schedulingMode;
  final Value<String?> schedulingConfig;
  final Value<int> rowid;
  const RoutinesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.schedulingMode = const Value.absent(),
    this.schedulingConfig = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutinesCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    this.schedulingMode = const Value.absent(),
    this.schedulingConfig = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Routine> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<String>? schedulingMode,
    Expression<String>? schedulingConfig,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (schedulingMode != null) 'scheduling_mode': schedulingMode,
      if (schedulingConfig != null) 'scheduling_config': schedulingConfig,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutinesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<String>? schedulingMode,
    Value<String?>? schedulingConfig,
    Value<int>? rowid,
  }) {
    return RoutinesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      schedulingMode: schedulingMode ?? this.schedulingMode,
      schedulingConfig: schedulingConfig ?? this.schedulingConfig,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (schedulingMode.present) {
      map['scheduling_mode'] = Variable<String>(schedulingMode.value);
    }
    if (schedulingConfig.present) {
      map['scheduling_config'] = Variable<String>(schedulingConfig.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutinesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('schedulingMode: $schedulingMode, ')
          ..write('schedulingConfig: $schedulingConfig, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutineDaysTable extends RoutineDays
    with TableInfo<$RoutineDaysTable, RoutineDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
    'routine_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES routines (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressionTypeMeta = const VerificationMeta(
    'progressionType',
  );
  @override
  late final GeneratedColumn<String> progressionType = GeneratedColumn<String>(
    'progression_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _dayIndexMeta = const VerificationMeta(
    'dayIndex',
  );
  @override
  late final GeneratedColumn<int> dayIndex = GeneratedColumn<int>(
    'day_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdaysMeta = const VerificationMeta(
    'weekdays',
  );
  @override
  late final GeneratedColumn<String> weekdays = GeneratedColumn<String>(
    'weekdays',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minRestHoursMeta = const VerificationMeta(
    'minRestHours',
  );
  @override
  late final GeneratedColumn<int> minRestHours = GeneratedColumn<int>(
    'min_rest_hours',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    routineId,
    name,
    progressionType,
    dayIndex,
    weekdays,
    minRestHours,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoutineDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('progression_type')) {
      context.handle(
        _progressionTypeMeta,
        progressionType.isAcceptableOrUnknown(
          data['progression_type']!,
          _progressionTypeMeta,
        ),
      );
    }
    if (data.containsKey('day_index')) {
      context.handle(
        _dayIndexMeta,
        dayIndex.isAcceptableOrUnknown(data['day_index']!, _dayIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIndexMeta);
    }
    if (data.containsKey('weekdays')) {
      context.handle(
        _weekdaysMeta,
        weekdays.isAcceptableOrUnknown(data['weekdays']!, _weekdaysMeta),
      );
    }
    if (data.containsKey('min_rest_hours')) {
      context.handle(
        _minRestHoursMeta,
        minRestHours.isAcceptableOrUnknown(
          data['min_rest_hours']!,
          _minRestHoursMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineDay(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      progressionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}progression_type'],
      )!,
      dayIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_index'],
      )!,
      weekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekdays'],
      ),
      minRestHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_rest_hours'],
      ),
    );
  }

  @override
  $RoutineDaysTable createAlias(String alias) {
    return $RoutineDaysTable(attachedDatabase, alias);
  }
}

class RoutineDay extends DataClass implements Insertable<RoutineDay> {
  final String id;
  final String routineId;
  final String name;
  final String progressionType;
  final int dayIndex;
  final String? weekdays;
  final int? minRestHours;
  const RoutineDay({
    required this.id,
    required this.routineId,
    required this.name,
    required this.progressionType,
    required this.dayIndex,
    this.weekdays,
    this.minRestHours,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['routine_id'] = Variable<String>(routineId);
    map['name'] = Variable<String>(name);
    map['progression_type'] = Variable<String>(progressionType);
    map['day_index'] = Variable<int>(dayIndex);
    if (!nullToAbsent || weekdays != null) {
      map['weekdays'] = Variable<String>(weekdays);
    }
    if (!nullToAbsent || minRestHours != null) {
      map['min_rest_hours'] = Variable<int>(minRestHours);
    }
    return map;
  }

  RoutineDaysCompanion toCompanion(bool nullToAbsent) {
    return RoutineDaysCompanion(
      id: Value(id),
      routineId: Value(routineId),
      name: Value(name),
      progressionType: Value(progressionType),
      dayIndex: Value(dayIndex),
      weekdays: weekdays == null && nullToAbsent
          ? const Value.absent()
          : Value(weekdays),
      minRestHours: minRestHours == null && nullToAbsent
          ? const Value.absent()
          : Value(minRestHours),
    );
  }

  factory RoutineDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineDay(
      id: serializer.fromJson<String>(json['id']),
      routineId: serializer.fromJson<String>(json['routineId']),
      name: serializer.fromJson<String>(json['name']),
      progressionType: serializer.fromJson<String>(json['progressionType']),
      dayIndex: serializer.fromJson<int>(json['dayIndex']),
      weekdays: serializer.fromJson<String?>(json['weekdays']),
      minRestHours: serializer.fromJson<int?>(json['minRestHours']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'routineId': serializer.toJson<String>(routineId),
      'name': serializer.toJson<String>(name),
      'progressionType': serializer.toJson<String>(progressionType),
      'dayIndex': serializer.toJson<int>(dayIndex),
      'weekdays': serializer.toJson<String?>(weekdays),
      'minRestHours': serializer.toJson<int?>(minRestHours),
    };
  }

  RoutineDay copyWith({
    String? id,
    String? routineId,
    String? name,
    String? progressionType,
    int? dayIndex,
    Value<String?> weekdays = const Value.absent(),
    Value<int?> minRestHours = const Value.absent(),
  }) => RoutineDay(
    id: id ?? this.id,
    routineId: routineId ?? this.routineId,
    name: name ?? this.name,
    progressionType: progressionType ?? this.progressionType,
    dayIndex: dayIndex ?? this.dayIndex,
    weekdays: weekdays.present ? weekdays.value : this.weekdays,
    minRestHours: minRestHours.present ? minRestHours.value : this.minRestHours,
  );
  RoutineDay copyWithCompanion(RoutineDaysCompanion data) {
    return RoutineDay(
      id: data.id.present ? data.id.value : this.id,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      name: data.name.present ? data.name.value : this.name,
      progressionType: data.progressionType.present
          ? data.progressionType.value
          : this.progressionType,
      dayIndex: data.dayIndex.present ? data.dayIndex.value : this.dayIndex,
      weekdays: data.weekdays.present ? data.weekdays.value : this.weekdays,
      minRestHours: data.minRestHours.present
          ? data.minRestHours.value
          : this.minRestHours,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineDay(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('name: $name, ')
          ..write('progressionType: $progressionType, ')
          ..write('dayIndex: $dayIndex, ')
          ..write('weekdays: $weekdays, ')
          ..write('minRestHours: $minRestHours')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    routineId,
    name,
    progressionType,
    dayIndex,
    weekdays,
    minRestHours,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineDay &&
          other.id == this.id &&
          other.routineId == this.routineId &&
          other.name == this.name &&
          other.progressionType == this.progressionType &&
          other.dayIndex == this.dayIndex &&
          other.weekdays == this.weekdays &&
          other.minRestHours == this.minRestHours);
}

class RoutineDaysCompanion extends UpdateCompanion<RoutineDay> {
  final Value<String> id;
  final Value<String> routineId;
  final Value<String> name;
  final Value<String> progressionType;
  final Value<int> dayIndex;
  final Value<String?> weekdays;
  final Value<int?> minRestHours;
  final Value<int> rowid;
  const RoutineDaysCompanion({
    this.id = const Value.absent(),
    this.routineId = const Value.absent(),
    this.name = const Value.absent(),
    this.progressionType = const Value.absent(),
    this.dayIndex = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.minRestHours = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutineDaysCompanion.insert({
    required String id,
    required String routineId,
    required String name,
    this.progressionType = const Value.absent(),
    required int dayIndex,
    this.weekdays = const Value.absent(),
    this.minRestHours = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       routineId = Value(routineId),
       name = Value(name),
       dayIndex = Value(dayIndex);
  static Insertable<RoutineDay> custom({
    Expression<String>? id,
    Expression<String>? routineId,
    Expression<String>? name,
    Expression<String>? progressionType,
    Expression<int>? dayIndex,
    Expression<String>? weekdays,
    Expression<int>? minRestHours,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routineId != null) 'routine_id': routineId,
      if (name != null) 'name': name,
      if (progressionType != null) 'progression_type': progressionType,
      if (dayIndex != null) 'day_index': dayIndex,
      if (weekdays != null) 'weekdays': weekdays,
      if (minRestHours != null) 'min_rest_hours': minRestHours,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutineDaysCompanion copyWith({
    Value<String>? id,
    Value<String>? routineId,
    Value<String>? name,
    Value<String>? progressionType,
    Value<int>? dayIndex,
    Value<String?>? weekdays,
    Value<int?>? minRestHours,
    Value<int>? rowid,
  }) {
    return RoutineDaysCompanion(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      name: name ?? this.name,
      progressionType: progressionType ?? this.progressionType,
      dayIndex: dayIndex ?? this.dayIndex,
      weekdays: weekdays ?? this.weekdays,
      minRestHours: minRestHours ?? this.minRestHours,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (progressionType.present) {
      map['progression_type'] = Variable<String>(progressionType.value);
    }
    if (dayIndex.present) {
      map['day_index'] = Variable<int>(dayIndex.value);
    }
    if (weekdays.present) {
      map['weekdays'] = Variable<String>(weekdays.value);
    }
    if (minRestHours.present) {
      map['min_rest_hours'] = Variable<int>(minRestHours.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineDaysCompanion(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('name: $name, ')
          ..write('progressionType: $progressionType, ')
          ..write('dayIndex: $dayIndex, ')
          ..write('weekdays: $weekdays, ')
          ..write('minRestHours: $minRestHours, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutineExercisesTable extends RoutineExercises
    with TableInfo<$RoutineExercisesTable, RoutineExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<String> dayId = GeneratedColumn<String>(
    'day_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES routine_days (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _libraryIdMeta = const VerificationMeta(
    'libraryId',
  );
  @override
  late final GeneratedColumn<String> libraryId = GeneratedColumn<String>(
    'library_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  musclesPrimary =
      GeneratedColumn<String>(
        'muscles_primary',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>(
        $RoutineExercisesTable.$convertermusclesPrimary,
      );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  musclesSecondary =
      GeneratedColumn<String>(
        'muscles_secondary',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>(
        $RoutineExercisesTable.$convertermusclesSecondary,
      );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localImagePathMeta = const VerificationMeta(
    'localImagePath',
  );
  @override
  late final GeneratedColumn<String> localImagePath = GeneratedColumn<String>(
    'local_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesMeta = const VerificationMeta('series');
  @override
  late final GeneratedColumn<int> series = GeneratedColumn<int>(
    'series',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsRangeMeta = const VerificationMeta(
    'repsRange',
  );
  @override
  late final GeneratedColumn<String> repsRange = GeneratedColumn<String>(
    'reps_range',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _suggestedRestSecondsMeta =
      const VerificationMeta('suggestedRestSeconds');
  @override
  late final GeneratedColumn<int> suggestedRestSeconds = GeneratedColumn<int>(
    'suggested_rest_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supersetIdMeta = const VerificationMeta(
    'supersetId',
  );
  @override
  late final GeneratedColumn<String> supersetId = GeneratedColumn<String>(
    'superset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exerciseIndexMeta = const VerificationMeta(
    'exerciseIndex',
  );
  @override
  late final GeneratedColumn<int> exerciseIndex = GeneratedColumn<int>(
    'exercise_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressionTypeMeta = const VerificationMeta(
    'progressionType',
  );
  @override
  late final GeneratedColumn<String> progressionType = GeneratedColumn<String>(
    'progression_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _weightIncrementMeta = const VerificationMeta(
    'weightIncrement',
  );
  @override
  late final GeneratedColumn<double> weightIncrement = GeneratedColumn<double>(
    'weight_increment',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _targetRpeMeta = const VerificationMeta(
    'targetRpe',
  );
  @override
  late final GeneratedColumn<int> targetRpe = GeneratedColumn<int>(
    'target_rpe',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayId,
    libraryId,
    name,
    description,
    musclesPrimary,
    musclesSecondary,
    equipment,
    localImagePath,
    series,
    repsRange,
    suggestedRestSeconds,
    notes,
    supersetId,
    exerciseIndex,
    progressionType,
    weightIncrement,
    targetRpe,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoutineExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIdMeta);
    }
    if (data.containsKey('library_id')) {
      context.handle(
        _libraryIdMeta,
        libraryId.isAcceptableOrUnknown(data['library_id']!, _libraryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_libraryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    } else if (isInserting) {
      context.missing(_equipmentMeta);
    }
    if (data.containsKey('local_image_path')) {
      context.handle(
        _localImagePathMeta,
        localImagePath.isAcceptableOrUnknown(
          data['local_image_path']!,
          _localImagePathMeta,
        ),
      );
    }
    if (data.containsKey('series')) {
      context.handle(
        _seriesMeta,
        series.isAcceptableOrUnknown(data['series']!, _seriesMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesMeta);
    }
    if (data.containsKey('reps_range')) {
      context.handle(
        _repsRangeMeta,
        repsRange.isAcceptableOrUnknown(data['reps_range']!, _repsRangeMeta),
      );
    } else if (isInserting) {
      context.missing(_repsRangeMeta);
    }
    if (data.containsKey('suggested_rest_seconds')) {
      context.handle(
        _suggestedRestSecondsMeta,
        suggestedRestSeconds.isAcceptableOrUnknown(
          data['suggested_rest_seconds']!,
          _suggestedRestSecondsMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('superset_id')) {
      context.handle(
        _supersetIdMeta,
        supersetId.isAcceptableOrUnknown(data['superset_id']!, _supersetIdMeta),
      );
    }
    if (data.containsKey('exercise_index')) {
      context.handle(
        _exerciseIndexMeta,
        exerciseIndex.isAcceptableOrUnknown(
          data['exercise_index']!,
          _exerciseIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseIndexMeta);
    }
    if (data.containsKey('progression_type')) {
      context.handle(
        _progressionTypeMeta,
        progressionType.isAcceptableOrUnknown(
          data['progression_type']!,
          _progressionTypeMeta,
        ),
      );
    }
    if (data.containsKey('weight_increment')) {
      context.handle(
        _weightIncrementMeta,
        weightIncrement.isAcceptableOrUnknown(
          data['weight_increment']!,
          _weightIncrementMeta,
        ),
      );
    }
    if (data.containsKey('target_rpe')) {
      context.handle(
        _targetRpeMeta,
        targetRpe.isAcceptableOrUnknown(data['target_rpe']!, _targetRpeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_id'],
      )!,
      libraryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      musclesPrimary: $RoutineExercisesTable.$convertermusclesPrimary.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}muscles_primary'],
        )!,
      ),
      musclesSecondary: $RoutineExercisesTable.$convertermusclesSecondary
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}muscles_secondary'],
            )!,
          ),
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      )!,
      localImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_image_path'],
      ),
      series: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series'],
      )!,
      repsRange: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reps_range'],
      )!,
      suggestedRestSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}suggested_rest_seconds'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      supersetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}superset_id'],
      ),
      exerciseIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_index'],
      )!,
      progressionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}progression_type'],
      )!,
      weightIncrement: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_increment'],
      )!,
      targetRpe: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_rpe'],
      ),
    );
  }

  @override
  $RoutineExercisesTable createAlias(String alias) {
    return $RoutineExercisesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertermusclesPrimary =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertermusclesSecondary =
      const StringListConverter();
}

class RoutineExercise extends DataClass implements Insertable<RoutineExercise> {
  final String id;
  final String dayId;
  final String libraryId;
  final String name;
  final String? description;
  final List<String> musclesPrimary;
  final List<String> musclesSecondary;
  final String equipment;
  final String? localImagePath;
  final int series;
  final String repsRange;
  final int? suggestedRestSeconds;
  final String? notes;
  final String? supersetId;
  final int exerciseIndex;
  final String progressionType;
  final double weightIncrement;
  final int? targetRpe;
  const RoutineExercise({
    required this.id,
    required this.dayId,
    required this.libraryId,
    required this.name,
    this.description,
    required this.musclesPrimary,
    required this.musclesSecondary,
    required this.equipment,
    this.localImagePath,
    required this.series,
    required this.repsRange,
    this.suggestedRestSeconds,
    this.notes,
    this.supersetId,
    required this.exerciseIndex,
    required this.progressionType,
    required this.weightIncrement,
    this.targetRpe,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day_id'] = Variable<String>(dayId);
    map['library_id'] = Variable<String>(libraryId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    {
      map['muscles_primary'] = Variable<String>(
        $RoutineExercisesTable.$convertermusclesPrimary.toSql(musclesPrimary),
      );
    }
    {
      map['muscles_secondary'] = Variable<String>(
        $RoutineExercisesTable.$convertermusclesSecondary.toSql(
          musclesSecondary,
        ),
      );
    }
    map['equipment'] = Variable<String>(equipment);
    if (!nullToAbsent || localImagePath != null) {
      map['local_image_path'] = Variable<String>(localImagePath);
    }
    map['series'] = Variable<int>(series);
    map['reps_range'] = Variable<String>(repsRange);
    if (!nullToAbsent || suggestedRestSeconds != null) {
      map['suggested_rest_seconds'] = Variable<int>(suggestedRestSeconds);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || supersetId != null) {
      map['superset_id'] = Variable<String>(supersetId);
    }
    map['exercise_index'] = Variable<int>(exerciseIndex);
    map['progression_type'] = Variable<String>(progressionType);
    map['weight_increment'] = Variable<double>(weightIncrement);
    if (!nullToAbsent || targetRpe != null) {
      map['target_rpe'] = Variable<int>(targetRpe);
    }
    return map;
  }

  RoutineExercisesCompanion toCompanion(bool nullToAbsent) {
    return RoutineExercisesCompanion(
      id: Value(id),
      dayId: Value(dayId),
      libraryId: Value(libraryId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      musclesPrimary: Value(musclesPrimary),
      musclesSecondary: Value(musclesSecondary),
      equipment: Value(equipment),
      localImagePath: localImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localImagePath),
      series: Value(series),
      repsRange: Value(repsRange),
      suggestedRestSeconds: suggestedRestSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(suggestedRestSeconds),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      supersetId: supersetId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetId),
      exerciseIndex: Value(exerciseIndex),
      progressionType: Value(progressionType),
      weightIncrement: Value(weightIncrement),
      targetRpe: targetRpe == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRpe),
    );
  }

  factory RoutineExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineExercise(
      id: serializer.fromJson<String>(json['id']),
      dayId: serializer.fromJson<String>(json['dayId']),
      libraryId: serializer.fromJson<String>(json['libraryId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      musclesPrimary: serializer.fromJson<List<String>>(json['musclesPrimary']),
      musclesSecondary: serializer.fromJson<List<String>>(
        json['musclesSecondary'],
      ),
      equipment: serializer.fromJson<String>(json['equipment']),
      localImagePath: serializer.fromJson<String?>(json['localImagePath']),
      series: serializer.fromJson<int>(json['series']),
      repsRange: serializer.fromJson<String>(json['repsRange']),
      suggestedRestSeconds: serializer.fromJson<int?>(
        json['suggestedRestSeconds'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      supersetId: serializer.fromJson<String?>(json['supersetId']),
      exerciseIndex: serializer.fromJson<int>(json['exerciseIndex']),
      progressionType: serializer.fromJson<String>(json['progressionType']),
      weightIncrement: serializer.fromJson<double>(json['weightIncrement']),
      targetRpe: serializer.fromJson<int?>(json['targetRpe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dayId': serializer.toJson<String>(dayId),
      'libraryId': serializer.toJson<String>(libraryId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'musclesPrimary': serializer.toJson<List<String>>(musclesPrimary),
      'musclesSecondary': serializer.toJson<List<String>>(musclesSecondary),
      'equipment': serializer.toJson<String>(equipment),
      'localImagePath': serializer.toJson<String?>(localImagePath),
      'series': serializer.toJson<int>(series),
      'repsRange': serializer.toJson<String>(repsRange),
      'suggestedRestSeconds': serializer.toJson<int?>(suggestedRestSeconds),
      'notes': serializer.toJson<String?>(notes),
      'supersetId': serializer.toJson<String?>(supersetId),
      'exerciseIndex': serializer.toJson<int>(exerciseIndex),
      'progressionType': serializer.toJson<String>(progressionType),
      'weightIncrement': serializer.toJson<double>(weightIncrement),
      'targetRpe': serializer.toJson<int?>(targetRpe),
    };
  }

  RoutineExercise copyWith({
    String? id,
    String? dayId,
    String? libraryId,
    String? name,
    Value<String?> description = const Value.absent(),
    List<String>? musclesPrimary,
    List<String>? musclesSecondary,
    String? equipment,
    Value<String?> localImagePath = const Value.absent(),
    int? series,
    String? repsRange,
    Value<int?> suggestedRestSeconds = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> supersetId = const Value.absent(),
    int? exerciseIndex,
    String? progressionType,
    double? weightIncrement,
    Value<int?> targetRpe = const Value.absent(),
  }) => RoutineExercise(
    id: id ?? this.id,
    dayId: dayId ?? this.dayId,
    libraryId: libraryId ?? this.libraryId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    musclesPrimary: musclesPrimary ?? this.musclesPrimary,
    musclesSecondary: musclesSecondary ?? this.musclesSecondary,
    equipment: equipment ?? this.equipment,
    localImagePath: localImagePath.present
        ? localImagePath.value
        : this.localImagePath,
    series: series ?? this.series,
    repsRange: repsRange ?? this.repsRange,
    suggestedRestSeconds: suggestedRestSeconds.present
        ? suggestedRestSeconds.value
        : this.suggestedRestSeconds,
    notes: notes.present ? notes.value : this.notes,
    supersetId: supersetId.present ? supersetId.value : this.supersetId,
    exerciseIndex: exerciseIndex ?? this.exerciseIndex,
    progressionType: progressionType ?? this.progressionType,
    weightIncrement: weightIncrement ?? this.weightIncrement,
    targetRpe: targetRpe.present ? targetRpe.value : this.targetRpe,
  );
  RoutineExercise copyWithCompanion(RoutineExercisesCompanion data) {
    return RoutineExercise(
      id: data.id.present ? data.id.value : this.id,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      libraryId: data.libraryId.present ? data.libraryId.value : this.libraryId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      musclesPrimary: data.musclesPrimary.present
          ? data.musclesPrimary.value
          : this.musclesPrimary,
      musclesSecondary: data.musclesSecondary.present
          ? data.musclesSecondary.value
          : this.musclesSecondary,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      localImagePath: data.localImagePath.present
          ? data.localImagePath.value
          : this.localImagePath,
      series: data.series.present ? data.series.value : this.series,
      repsRange: data.repsRange.present ? data.repsRange.value : this.repsRange,
      suggestedRestSeconds: data.suggestedRestSeconds.present
          ? data.suggestedRestSeconds.value
          : this.suggestedRestSeconds,
      notes: data.notes.present ? data.notes.value : this.notes,
      supersetId: data.supersetId.present
          ? data.supersetId.value
          : this.supersetId,
      exerciseIndex: data.exerciseIndex.present
          ? data.exerciseIndex.value
          : this.exerciseIndex,
      progressionType: data.progressionType.present
          ? data.progressionType.value
          : this.progressionType,
      weightIncrement: data.weightIncrement.present
          ? data.weightIncrement.value
          : this.weightIncrement,
      targetRpe: data.targetRpe.present ? data.targetRpe.value : this.targetRpe,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineExercise(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('libraryId: $libraryId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('musclesPrimary: $musclesPrimary, ')
          ..write('musclesSecondary: $musclesSecondary, ')
          ..write('equipment: $equipment, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('series: $series, ')
          ..write('repsRange: $repsRange, ')
          ..write('suggestedRestSeconds: $suggestedRestSeconds, ')
          ..write('notes: $notes, ')
          ..write('supersetId: $supersetId, ')
          ..write('exerciseIndex: $exerciseIndex, ')
          ..write('progressionType: $progressionType, ')
          ..write('weightIncrement: $weightIncrement, ')
          ..write('targetRpe: $targetRpe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dayId,
    libraryId,
    name,
    description,
    musclesPrimary,
    musclesSecondary,
    equipment,
    localImagePath,
    series,
    repsRange,
    suggestedRestSeconds,
    notes,
    supersetId,
    exerciseIndex,
    progressionType,
    weightIncrement,
    targetRpe,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineExercise &&
          other.id == this.id &&
          other.dayId == this.dayId &&
          other.libraryId == this.libraryId &&
          other.name == this.name &&
          other.description == this.description &&
          other.musclesPrimary == this.musclesPrimary &&
          other.musclesSecondary == this.musclesSecondary &&
          other.equipment == this.equipment &&
          other.localImagePath == this.localImagePath &&
          other.series == this.series &&
          other.repsRange == this.repsRange &&
          other.suggestedRestSeconds == this.suggestedRestSeconds &&
          other.notes == this.notes &&
          other.supersetId == this.supersetId &&
          other.exerciseIndex == this.exerciseIndex &&
          other.progressionType == this.progressionType &&
          other.weightIncrement == this.weightIncrement &&
          other.targetRpe == this.targetRpe);
}

class RoutineExercisesCompanion extends UpdateCompanion<RoutineExercise> {
  final Value<String> id;
  final Value<String> dayId;
  final Value<String> libraryId;
  final Value<String> name;
  final Value<String?> description;
  final Value<List<String>> musclesPrimary;
  final Value<List<String>> musclesSecondary;
  final Value<String> equipment;
  final Value<String?> localImagePath;
  final Value<int> series;
  final Value<String> repsRange;
  final Value<int?> suggestedRestSeconds;
  final Value<String?> notes;
  final Value<String?> supersetId;
  final Value<int> exerciseIndex;
  final Value<String> progressionType;
  final Value<double> weightIncrement;
  final Value<int?> targetRpe;
  final Value<int> rowid;
  const RoutineExercisesCompanion({
    this.id = const Value.absent(),
    this.dayId = const Value.absent(),
    this.libraryId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.musclesPrimary = const Value.absent(),
    this.musclesSecondary = const Value.absent(),
    this.equipment = const Value.absent(),
    this.localImagePath = const Value.absent(),
    this.series = const Value.absent(),
    this.repsRange = const Value.absent(),
    this.suggestedRestSeconds = const Value.absent(),
    this.notes = const Value.absent(),
    this.supersetId = const Value.absent(),
    this.exerciseIndex = const Value.absent(),
    this.progressionType = const Value.absent(),
    this.weightIncrement = const Value.absent(),
    this.targetRpe = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutineExercisesCompanion.insert({
    required String id,
    required String dayId,
    required String libraryId,
    required String name,
    this.description = const Value.absent(),
    required List<String> musclesPrimary,
    required List<String> musclesSecondary,
    required String equipment,
    this.localImagePath = const Value.absent(),
    required int series,
    required String repsRange,
    this.suggestedRestSeconds = const Value.absent(),
    this.notes = const Value.absent(),
    this.supersetId = const Value.absent(),
    required int exerciseIndex,
    this.progressionType = const Value.absent(),
    this.weightIncrement = const Value.absent(),
    this.targetRpe = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dayId = Value(dayId),
       libraryId = Value(libraryId),
       name = Value(name),
       musclesPrimary = Value(musclesPrimary),
       musclesSecondary = Value(musclesSecondary),
       equipment = Value(equipment),
       series = Value(series),
       repsRange = Value(repsRange),
       exerciseIndex = Value(exerciseIndex);
  static Insertable<RoutineExercise> custom({
    Expression<String>? id,
    Expression<String>? dayId,
    Expression<String>? libraryId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? musclesPrimary,
    Expression<String>? musclesSecondary,
    Expression<String>? equipment,
    Expression<String>? localImagePath,
    Expression<int>? series,
    Expression<String>? repsRange,
    Expression<int>? suggestedRestSeconds,
    Expression<String>? notes,
    Expression<String>? supersetId,
    Expression<int>? exerciseIndex,
    Expression<String>? progressionType,
    Expression<double>? weightIncrement,
    Expression<int>? targetRpe,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayId != null) 'day_id': dayId,
      if (libraryId != null) 'library_id': libraryId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (musclesPrimary != null) 'muscles_primary': musclesPrimary,
      if (musclesSecondary != null) 'muscles_secondary': musclesSecondary,
      if (equipment != null) 'equipment': equipment,
      if (localImagePath != null) 'local_image_path': localImagePath,
      if (series != null) 'series': series,
      if (repsRange != null) 'reps_range': repsRange,
      if (suggestedRestSeconds != null)
        'suggested_rest_seconds': suggestedRestSeconds,
      if (notes != null) 'notes': notes,
      if (supersetId != null) 'superset_id': supersetId,
      if (exerciseIndex != null) 'exercise_index': exerciseIndex,
      if (progressionType != null) 'progression_type': progressionType,
      if (weightIncrement != null) 'weight_increment': weightIncrement,
      if (targetRpe != null) 'target_rpe': targetRpe,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutineExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? dayId,
    Value<String>? libraryId,
    Value<String>? name,
    Value<String?>? description,
    Value<List<String>>? musclesPrimary,
    Value<List<String>>? musclesSecondary,
    Value<String>? equipment,
    Value<String?>? localImagePath,
    Value<int>? series,
    Value<String>? repsRange,
    Value<int?>? suggestedRestSeconds,
    Value<String?>? notes,
    Value<String?>? supersetId,
    Value<int>? exerciseIndex,
    Value<String>? progressionType,
    Value<double>? weightIncrement,
    Value<int?>? targetRpe,
    Value<int>? rowid,
  }) {
    return RoutineExercisesCompanion(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      libraryId: libraryId ?? this.libraryId,
      name: name ?? this.name,
      description: description ?? this.description,
      musclesPrimary: musclesPrimary ?? this.musclesPrimary,
      musclesSecondary: musclesSecondary ?? this.musclesSecondary,
      equipment: equipment ?? this.equipment,
      localImagePath: localImagePath ?? this.localImagePath,
      series: series ?? this.series,
      repsRange: repsRange ?? this.repsRange,
      suggestedRestSeconds: suggestedRestSeconds ?? this.suggestedRestSeconds,
      notes: notes ?? this.notes,
      supersetId: supersetId ?? this.supersetId,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      progressionType: progressionType ?? this.progressionType,
      weightIncrement: weightIncrement ?? this.weightIncrement,
      targetRpe: targetRpe ?? this.targetRpe,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<String>(dayId.value);
    }
    if (libraryId.present) {
      map['library_id'] = Variable<String>(libraryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (musclesPrimary.present) {
      map['muscles_primary'] = Variable<String>(
        $RoutineExercisesTable.$convertermusclesPrimary.toSql(
          musclesPrimary.value,
        ),
      );
    }
    if (musclesSecondary.present) {
      map['muscles_secondary'] = Variable<String>(
        $RoutineExercisesTable.$convertermusclesSecondary.toSql(
          musclesSecondary.value,
        ),
      );
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (localImagePath.present) {
      map['local_image_path'] = Variable<String>(localImagePath.value);
    }
    if (series.present) {
      map['series'] = Variable<int>(series.value);
    }
    if (repsRange.present) {
      map['reps_range'] = Variable<String>(repsRange.value);
    }
    if (suggestedRestSeconds.present) {
      map['suggested_rest_seconds'] = Variable<int>(suggestedRestSeconds.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (supersetId.present) {
      map['superset_id'] = Variable<String>(supersetId.value);
    }
    if (exerciseIndex.present) {
      map['exercise_index'] = Variable<int>(exerciseIndex.value);
    }
    if (progressionType.present) {
      map['progression_type'] = Variable<String>(progressionType.value);
    }
    if (weightIncrement.present) {
      map['weight_increment'] = Variable<double>(weightIncrement.value);
    }
    if (targetRpe.present) {
      map['target_rpe'] = Variable<int>(targetRpe.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineExercisesCompanion(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('libraryId: $libraryId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('musclesPrimary: $musclesPrimary, ')
          ..write('musclesSecondary: $musclesSecondary, ')
          ..write('equipment: $equipment, ')
          ..write('localImagePath: $localImagePath, ')
          ..write('series: $series, ')
          ..write('repsRange: $repsRange, ')
          ..write('suggestedRestSeconds: $suggestedRestSeconds, ')
          ..write('notes: $notes, ')
          ..write('supersetId: $supersetId, ')
          ..write('exerciseIndex: $exerciseIndex, ')
          ..write('progressionType: $progressionType, ')
          ..write('weightIncrement: $weightIncrement, ')
          ..write('targetRpe: $targetRpe, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
    'routine_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayNameMeta = const VerificationMeta(
    'dayName',
  );
  @override
  late final GeneratedColumn<String> dayName = GeneratedColumn<String>(
    'day_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayIndexMeta = const VerificationMeta(
    'dayIndex',
  );
  @override
  late final GeneratedColumn<int> dayIndex = GeneratedColumn<int>(
    'day_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBadDayMeta = const VerificationMeta(
    'isBadDay',
  );
  @override
  late final GeneratedColumn<bool> isBadDay = GeneratedColumn<bool>(
    'is_bad_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bad_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    routineId,
    dayName,
    dayIndex,
    startTime,
    durationSeconds,
    isBadDay,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    }
    if (data.containsKey('day_name')) {
      context.handle(
        _dayNameMeta,
        dayName.isAcceptableOrUnknown(data['day_name']!, _dayNameMeta),
      );
    }
    if (data.containsKey('day_index')) {
      context.handle(
        _dayIndexMeta,
        dayIndex.isAcceptableOrUnknown(data['day_index']!, _dayIndexMeta),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_bad_day')) {
      context.handle(
        _isBadDayMeta,
        isBadDay.isAcceptableOrUnknown(data['is_bad_day']!, _isBadDayMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_id'],
      ),
      dayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_name'],
      ),
      dayIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_index'],
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      isBadDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bad_day'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final String? routineId;
  final String? dayName;
  final int? dayIndex;
  final DateTime startTime;
  final int? durationSeconds;
  final bool isBadDay;
  final DateTime? completedAt;
  const Session({
    required this.id,
    this.routineId,
    this.dayName,
    this.dayIndex,
    required this.startTime,
    this.durationSeconds,
    required this.isBadDay,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || routineId != null) {
      map['routine_id'] = Variable<String>(routineId);
    }
    if (!nullToAbsent || dayName != null) {
      map['day_name'] = Variable<String>(dayName);
    }
    if (!nullToAbsent || dayIndex != null) {
      map['day_index'] = Variable<int>(dayIndex);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['is_bad_day'] = Variable<bool>(isBadDay);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      routineId: routineId == null && nullToAbsent
          ? const Value.absent()
          : Value(routineId),
      dayName: dayName == null && nullToAbsent
          ? const Value.absent()
          : Value(dayName),
      dayIndex: dayIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(dayIndex),
      startTime: Value(startTime),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      isBadDay: Value(isBadDay),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      routineId: serializer.fromJson<String?>(json['routineId']),
      dayName: serializer.fromJson<String?>(json['dayName']),
      dayIndex: serializer.fromJson<int?>(json['dayIndex']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      isBadDay: serializer.fromJson<bool>(json['isBadDay']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'routineId': serializer.toJson<String?>(routineId),
      'dayName': serializer.toJson<String?>(dayName),
      'dayIndex': serializer.toJson<int?>(dayIndex),
      'startTime': serializer.toJson<DateTime>(startTime),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'isBadDay': serializer.toJson<bool>(isBadDay),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  Session copyWith({
    String? id,
    Value<String?> routineId = const Value.absent(),
    Value<String?> dayName = const Value.absent(),
    Value<int?> dayIndex = const Value.absent(),
    DateTime? startTime,
    Value<int?> durationSeconds = const Value.absent(),
    bool? isBadDay,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => Session(
    id: id ?? this.id,
    routineId: routineId.present ? routineId.value : this.routineId,
    dayName: dayName.present ? dayName.value : this.dayName,
    dayIndex: dayIndex.present ? dayIndex.value : this.dayIndex,
    startTime: startTime ?? this.startTime,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    isBadDay: isBadDay ?? this.isBadDay,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      dayName: data.dayName.present ? data.dayName.value : this.dayName,
      dayIndex: data.dayIndex.present ? data.dayIndex.value : this.dayIndex,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      isBadDay: data.isBadDay.present ? data.isBadDay.value : this.isBadDay,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('dayName: $dayName, ')
          ..write('dayIndex: $dayIndex, ')
          ..write('startTime: $startTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('isBadDay: $isBadDay, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    routineId,
    dayName,
    dayIndex,
    startTime,
    durationSeconds,
    isBadDay,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.routineId == this.routineId &&
          other.dayName == this.dayName &&
          other.dayIndex == this.dayIndex &&
          other.startTime == this.startTime &&
          other.durationSeconds == this.durationSeconds &&
          other.isBadDay == this.isBadDay &&
          other.completedAt == this.completedAt);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String?> routineId;
  final Value<String?> dayName;
  final Value<int?> dayIndex;
  final Value<DateTime> startTime;
  final Value<int?> durationSeconds;
  final Value<bool> isBadDay;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.routineId = const Value.absent(),
    this.dayName = const Value.absent(),
    this.dayIndex = const Value.absent(),
    this.startTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.isBadDay = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    this.routineId = const Value.absent(),
    this.dayName = const Value.absent(),
    this.dayIndex = const Value.absent(),
    required DateTime startTime,
    this.durationSeconds = const Value.absent(),
    this.isBadDay = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startTime = Value(startTime);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? routineId,
    Expression<String>? dayName,
    Expression<int>? dayIndex,
    Expression<DateTime>? startTime,
    Expression<int>? durationSeconds,
    Expression<bool>? isBadDay,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routineId != null) 'routine_id': routineId,
      if (dayName != null) 'day_name': dayName,
      if (dayIndex != null) 'day_index': dayIndex,
      if (startTime != null) 'start_time': startTime,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (isBadDay != null) 'is_bad_day': isBadDay,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? routineId,
    Value<String?>? dayName,
    Value<int?>? dayIndex,
    Value<DateTime>? startTime,
    Value<int?>? durationSeconds,
    Value<bool>? isBadDay,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      dayName: dayName ?? this.dayName,
      dayIndex: dayIndex ?? this.dayIndex,
      startTime: startTime ?? this.startTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isBadDay: isBadDay ?? this.isBadDay,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (dayName.present) {
      map['day_name'] = Variable<String>(dayName.value);
    }
    if (dayIndex.present) {
      map['day_index'] = Variable<int>(dayIndex.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (isBadDay.present) {
      map['is_bad_day'] = Variable<bool>(isBadDay.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('dayName: $dayName, ')
          ..write('dayIndex: $dayIndex, ')
          ..write('startTime: $startTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('isBadDay: $isBadDay, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionExercisesTable extends SessionExercises
    with TableInfo<$SessionExercisesTable, SessionExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _libraryIdMeta = const VerificationMeta(
    'libraryId',
  );
  @override
  late final GeneratedColumn<String> libraryId = GeneratedColumn<String>(
    'library_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  musclesPrimary =
      GeneratedColumn<String>(
        'muscles_primary',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>(
        $SessionExercisesTable.$convertermusclesPrimary,
      );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  musclesSecondary =
      GeneratedColumn<String>(
        'muscles_secondary',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>(
        $SessionExercisesTable.$convertermusclesSecondary,
      );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exerciseIndexMeta = const VerificationMeta(
    'exerciseIndex',
  );
  @override
  late final GeneratedColumn<int> exerciseIndex = GeneratedColumn<int>(
    'exercise_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isTargetMeta = const VerificationMeta(
    'isTarget',
  );
  @override
  late final GeneratedColumn<bool> isTarget = GeneratedColumn<bool>(
    'is_target',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_target" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    libraryId,
    name,
    musclesPrimary,
    musclesSecondary,
    equipment,
    notes,
    exerciseIndex,
    isTarget,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('library_id')) {
      context.handle(
        _libraryIdMeta,
        libraryId.isAcceptableOrUnknown(data['library_id']!, _libraryIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('exercise_index')) {
      context.handle(
        _exerciseIndexMeta,
        exerciseIndex.isAcceptableOrUnknown(
          data['exercise_index']!,
          _exerciseIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseIndexMeta);
    }
    if (data.containsKey('is_target')) {
      context.handle(
        _isTargetMeta,
        isTarget.isAcceptableOrUnknown(data['is_target']!, _isTargetMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      libraryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      musclesPrimary: $SessionExercisesTable.$convertermusclesPrimary.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}muscles_primary'],
        )!,
      ),
      musclesSecondary: $SessionExercisesTable.$convertermusclesSecondary
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}muscles_secondary'],
            )!,
          ),
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      exerciseIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_index'],
      )!,
      isTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_target'],
      )!,
    );
  }

  @override
  $SessionExercisesTable createAlias(String alias) {
    return $SessionExercisesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertermusclesPrimary =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertermusclesSecondary =
      const StringListConverter();
}

class SessionExercise extends DataClass implements Insertable<SessionExercise> {
  final String id;
  final String sessionId;
  final String? libraryId;
  final String name;
  final List<String> musclesPrimary;
  final List<String> musclesSecondary;
  final String? equipment;
  final String? notes;
  final int exerciseIndex;
  final bool isTarget;
  const SessionExercise({
    required this.id,
    required this.sessionId,
    this.libraryId,
    required this.name,
    required this.musclesPrimary,
    required this.musclesSecondary,
    this.equipment,
    this.notes,
    required this.exerciseIndex,
    required this.isTarget,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    if (!nullToAbsent || libraryId != null) {
      map['library_id'] = Variable<String>(libraryId);
    }
    map['name'] = Variable<String>(name);
    {
      map['muscles_primary'] = Variable<String>(
        $SessionExercisesTable.$convertermusclesPrimary.toSql(musclesPrimary),
      );
    }
    {
      map['muscles_secondary'] = Variable<String>(
        $SessionExercisesTable.$convertermusclesSecondary.toSql(
          musclesSecondary,
        ),
      );
    }
    if (!nullToAbsent || equipment != null) {
      map['equipment'] = Variable<String>(equipment);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['exercise_index'] = Variable<int>(exerciseIndex);
    map['is_target'] = Variable<bool>(isTarget);
    return map;
  }

  SessionExercisesCompanion toCompanion(bool nullToAbsent) {
    return SessionExercisesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      libraryId: libraryId == null && nullToAbsent
          ? const Value.absent()
          : Value(libraryId),
      name: Value(name),
      musclesPrimary: Value(musclesPrimary),
      musclesSecondary: Value(musclesSecondary),
      equipment: equipment == null && nullToAbsent
          ? const Value.absent()
          : Value(equipment),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      exerciseIndex: Value(exerciseIndex),
      isTarget: Value(isTarget),
    );
  }

  factory SessionExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionExercise(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      libraryId: serializer.fromJson<String?>(json['libraryId']),
      name: serializer.fromJson<String>(json['name']),
      musclesPrimary: serializer.fromJson<List<String>>(json['musclesPrimary']),
      musclesSecondary: serializer.fromJson<List<String>>(
        json['musclesSecondary'],
      ),
      equipment: serializer.fromJson<String?>(json['equipment']),
      notes: serializer.fromJson<String?>(json['notes']),
      exerciseIndex: serializer.fromJson<int>(json['exerciseIndex']),
      isTarget: serializer.fromJson<bool>(json['isTarget']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'libraryId': serializer.toJson<String?>(libraryId),
      'name': serializer.toJson<String>(name),
      'musclesPrimary': serializer.toJson<List<String>>(musclesPrimary),
      'musclesSecondary': serializer.toJson<List<String>>(musclesSecondary),
      'equipment': serializer.toJson<String?>(equipment),
      'notes': serializer.toJson<String?>(notes),
      'exerciseIndex': serializer.toJson<int>(exerciseIndex),
      'isTarget': serializer.toJson<bool>(isTarget),
    };
  }

  SessionExercise copyWith({
    String? id,
    String? sessionId,
    Value<String?> libraryId = const Value.absent(),
    String? name,
    List<String>? musclesPrimary,
    List<String>? musclesSecondary,
    Value<String?> equipment = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? exerciseIndex,
    bool? isTarget,
  }) => SessionExercise(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    libraryId: libraryId.present ? libraryId.value : this.libraryId,
    name: name ?? this.name,
    musclesPrimary: musclesPrimary ?? this.musclesPrimary,
    musclesSecondary: musclesSecondary ?? this.musclesSecondary,
    equipment: equipment.present ? equipment.value : this.equipment,
    notes: notes.present ? notes.value : this.notes,
    exerciseIndex: exerciseIndex ?? this.exerciseIndex,
    isTarget: isTarget ?? this.isTarget,
  );
  SessionExercise copyWithCompanion(SessionExercisesCompanion data) {
    return SessionExercise(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      libraryId: data.libraryId.present ? data.libraryId.value : this.libraryId,
      name: data.name.present ? data.name.value : this.name,
      musclesPrimary: data.musclesPrimary.present
          ? data.musclesPrimary.value
          : this.musclesPrimary,
      musclesSecondary: data.musclesSecondary.present
          ? data.musclesSecondary.value
          : this.musclesSecondary,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      notes: data.notes.present ? data.notes.value : this.notes,
      exerciseIndex: data.exerciseIndex.present
          ? data.exerciseIndex.value
          : this.exerciseIndex,
      isTarget: data.isTarget.present ? data.isTarget.value : this.isTarget,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercise(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('libraryId: $libraryId, ')
          ..write('name: $name, ')
          ..write('musclesPrimary: $musclesPrimary, ')
          ..write('musclesSecondary: $musclesSecondary, ')
          ..write('equipment: $equipment, ')
          ..write('notes: $notes, ')
          ..write('exerciseIndex: $exerciseIndex, ')
          ..write('isTarget: $isTarget')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    libraryId,
    name,
    musclesPrimary,
    musclesSecondary,
    equipment,
    notes,
    exerciseIndex,
    isTarget,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionExercise &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.libraryId == this.libraryId &&
          other.name == this.name &&
          other.musclesPrimary == this.musclesPrimary &&
          other.musclesSecondary == this.musclesSecondary &&
          other.equipment == this.equipment &&
          other.notes == this.notes &&
          other.exerciseIndex == this.exerciseIndex &&
          other.isTarget == this.isTarget);
}

class SessionExercisesCompanion extends UpdateCompanion<SessionExercise> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String?> libraryId;
  final Value<String> name;
  final Value<List<String>> musclesPrimary;
  final Value<List<String>> musclesSecondary;
  final Value<String?> equipment;
  final Value<String?> notes;
  final Value<int> exerciseIndex;
  final Value<bool> isTarget;
  final Value<int> rowid;
  const SessionExercisesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.libraryId = const Value.absent(),
    this.name = const Value.absent(),
    this.musclesPrimary = const Value.absent(),
    this.musclesSecondary = const Value.absent(),
    this.equipment = const Value.absent(),
    this.notes = const Value.absent(),
    this.exerciseIndex = const Value.absent(),
    this.isTarget = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionExercisesCompanion.insert({
    required String id,
    required String sessionId,
    this.libraryId = const Value.absent(),
    required String name,
    required List<String> musclesPrimary,
    required List<String> musclesSecondary,
    this.equipment = const Value.absent(),
    this.notes = const Value.absent(),
    required int exerciseIndex,
    this.isTarget = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       name = Value(name),
       musclesPrimary = Value(musclesPrimary),
       musclesSecondary = Value(musclesSecondary),
       exerciseIndex = Value(exerciseIndex);
  static Insertable<SessionExercise> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? libraryId,
    Expression<String>? name,
    Expression<String>? musclesPrimary,
    Expression<String>? musclesSecondary,
    Expression<String>? equipment,
    Expression<String>? notes,
    Expression<int>? exerciseIndex,
    Expression<bool>? isTarget,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (libraryId != null) 'library_id': libraryId,
      if (name != null) 'name': name,
      if (musclesPrimary != null) 'muscles_primary': musclesPrimary,
      if (musclesSecondary != null) 'muscles_secondary': musclesSecondary,
      if (equipment != null) 'equipment': equipment,
      if (notes != null) 'notes': notes,
      if (exerciseIndex != null) 'exercise_index': exerciseIndex,
      if (isTarget != null) 'is_target': isTarget,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String?>? libraryId,
    Value<String>? name,
    Value<List<String>>? musclesPrimary,
    Value<List<String>>? musclesSecondary,
    Value<String?>? equipment,
    Value<String?>? notes,
    Value<int>? exerciseIndex,
    Value<bool>? isTarget,
    Value<int>? rowid,
  }) {
    return SessionExercisesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      libraryId: libraryId ?? this.libraryId,
      name: name ?? this.name,
      musclesPrimary: musclesPrimary ?? this.musclesPrimary,
      musclesSecondary: musclesSecondary ?? this.musclesSecondary,
      equipment: equipment ?? this.equipment,
      notes: notes ?? this.notes,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      isTarget: isTarget ?? this.isTarget,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (libraryId.present) {
      map['library_id'] = Variable<String>(libraryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (musclesPrimary.present) {
      map['muscles_primary'] = Variable<String>(
        $SessionExercisesTable.$convertermusclesPrimary.toSql(
          musclesPrimary.value,
        ),
      );
    }
    if (musclesSecondary.present) {
      map['muscles_secondary'] = Variable<String>(
        $SessionExercisesTable.$convertermusclesSecondary.toSql(
          musclesSecondary.value,
        ),
      );
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (exerciseIndex.present) {
      map['exercise_index'] = Variable<int>(exerciseIndex.value);
    }
    if (isTarget.present) {
      map['is_target'] = Variable<bool>(isTarget.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercisesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('libraryId: $libraryId, ')
          ..write('name: $name, ')
          ..write('musclesPrimary: $musclesPrimary, ')
          ..write('musclesSecondary: $musclesSecondary, ')
          ..write('equipment: $equipment, ')
          ..write('notes: $notes, ')
          ..write('exerciseIndex: $exerciseIndex, ')
          ..write('isTarget: $isTarget, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSetsTable extends WorkoutSets
    with TableInfo<$WorkoutSetsTable, WorkoutSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionExerciseIdMeta = const VerificationMeta(
    'sessionExerciseId',
  );
  @override
  late final GeneratedColumn<String> sessionExerciseId =
      GeneratedColumn<String>(
        'session_exercise_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES session_exercises (id) ON DELETE CASCADE',
        ),
      );
  static const VerificationMeta _setIndexMeta = const VerificationMeta(
    'setIndex',
  );
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<int> rpe = GeneratedColumn<int>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restSecondsMeta = const VerificationMeta(
    'restSeconds',
  );
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
    'rest_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFailureMeta = const VerificationMeta(
    'isFailure',
  );
  @override
  late final GeneratedColumn<bool> isFailure = GeneratedColumn<bool>(
    'is_failure',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_failure" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDropsetMeta = const VerificationMeta(
    'isDropset',
  );
  @override
  late final GeneratedColumn<bool> isDropset = GeneratedColumn<bool>(
    'is_dropset',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dropset" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isRestPauseMeta = const VerificationMeta(
    'isRestPause',
  );
  @override
  late final GeneratedColumn<bool> isRestPause = GeneratedColumn<bool>(
    'is_rest_pause',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_rest_pause" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isWarmupMeta = const VerificationMeta(
    'isWarmup',
  );
  @override
  late final GeneratedColumn<bool> isWarmup = GeneratedColumn<bool>(
    'is_warmup',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_warmup" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionExerciseId,
    setIndex,
    weight,
    reps,
    completed,
    rpe,
    notes,
    restSeconds,
    isFailure,
    isDropset,
    isRestPause,
    isWarmup,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_exercise_id')) {
      context.handle(
        _sessionExerciseIdMeta,
        sessionExerciseId.isAcceptableOrUnknown(
          data['session_exercise_id']!,
          _sessionExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionExerciseIdMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('rpe')) {
      context.handle(
        _rpeMeta,
        rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(
        _restSecondsMeta,
        restSeconds.isAcceptableOrUnknown(
          data['rest_seconds']!,
          _restSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_failure')) {
      context.handle(
        _isFailureMeta,
        isFailure.isAcceptableOrUnknown(data['is_failure']!, _isFailureMeta),
      );
    }
    if (data.containsKey('is_dropset')) {
      context.handle(
        _isDropsetMeta,
        isDropset.isAcceptableOrUnknown(data['is_dropset']!, _isDropsetMeta),
      );
    }
    if (data.containsKey('is_rest_pause')) {
      context.handle(
        _isRestPauseMeta,
        isRestPause.isAcceptableOrUnknown(
          data['is_rest_pause']!,
          _isRestPauseMeta,
        ),
      );
    }
    if (data.containsKey('is_warmup')) {
      context.handle(
        _isWarmupMeta,
        isWarmup.isAcceptableOrUnknown(data['is_warmup']!, _isWarmupMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_exercise_id'],
      )!,
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_index'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      rpe: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rpe'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      restSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_seconds'],
      ),
      isFailure: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_failure'],
      )!,
      isDropset: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dropset'],
      )!,
      isRestPause: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_rest_pause'],
      )!,
      isWarmup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_warmup'],
      )!,
    );
  }

  @override
  $WorkoutSetsTable createAlias(String alias) {
    return $WorkoutSetsTable(attachedDatabase, alias);
  }
}

class WorkoutSet extends DataClass implements Insertable<WorkoutSet> {
  final String id;
  final String sessionExerciseId;
  final int setIndex;
  final double weight;
  final int reps;
  final bool completed;
  final int? rpe;
  final String? notes;
  final int? restSeconds;
  final bool isFailure;
  final bool isDropset;
  final bool isRestPause;
  final bool isWarmup;
  const WorkoutSet({
    required this.id,
    required this.sessionExerciseId,
    required this.setIndex,
    required this.weight,
    required this.reps,
    required this.completed,
    this.rpe,
    this.notes,
    this.restSeconds,
    required this.isFailure,
    required this.isDropset,
    required this.isRestPause,
    required this.isWarmup,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_exercise_id'] = Variable<String>(sessionExerciseId);
    map['set_index'] = Variable<int>(setIndex);
    map['weight'] = Variable<double>(weight);
    map['reps'] = Variable<int>(reps);
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<int>(rpe);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || restSeconds != null) {
      map['rest_seconds'] = Variable<int>(restSeconds);
    }
    map['is_failure'] = Variable<bool>(isFailure);
    map['is_dropset'] = Variable<bool>(isDropset);
    map['is_rest_pause'] = Variable<bool>(isRestPause);
    map['is_warmup'] = Variable<bool>(isWarmup);
    return map;
  }

  WorkoutSetsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSetsCompanion(
      id: Value(id),
      sessionExerciseId: Value(sessionExerciseId),
      setIndex: Value(setIndex),
      weight: Value(weight),
      reps: Value(reps),
      completed: Value(completed),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      restSeconds: restSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(restSeconds),
      isFailure: Value(isFailure),
      isDropset: Value(isDropset),
      isRestPause: Value(isRestPause),
      isWarmup: Value(isWarmup),
    );
  }

  factory WorkoutSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSet(
      id: serializer.fromJson<String>(json['id']),
      sessionExerciseId: serializer.fromJson<String>(json['sessionExerciseId']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      weight: serializer.fromJson<double>(json['weight']),
      reps: serializer.fromJson<int>(json['reps']),
      completed: serializer.fromJson<bool>(json['completed']),
      rpe: serializer.fromJson<int?>(json['rpe']),
      notes: serializer.fromJson<String?>(json['notes']),
      restSeconds: serializer.fromJson<int?>(json['restSeconds']),
      isFailure: serializer.fromJson<bool>(json['isFailure']),
      isDropset: serializer.fromJson<bool>(json['isDropset']),
      isRestPause: serializer.fromJson<bool>(json['isRestPause']),
      isWarmup: serializer.fromJson<bool>(json['isWarmup']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionExerciseId': serializer.toJson<String>(sessionExerciseId),
      'setIndex': serializer.toJson<int>(setIndex),
      'weight': serializer.toJson<double>(weight),
      'reps': serializer.toJson<int>(reps),
      'completed': serializer.toJson<bool>(completed),
      'rpe': serializer.toJson<int?>(rpe),
      'notes': serializer.toJson<String?>(notes),
      'restSeconds': serializer.toJson<int?>(restSeconds),
      'isFailure': serializer.toJson<bool>(isFailure),
      'isDropset': serializer.toJson<bool>(isDropset),
      'isRestPause': serializer.toJson<bool>(isRestPause),
      'isWarmup': serializer.toJson<bool>(isWarmup),
    };
  }

  WorkoutSet copyWith({
    String? id,
    String? sessionExerciseId,
    int? setIndex,
    double? weight,
    int? reps,
    bool? completed,
    Value<int?> rpe = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> restSeconds = const Value.absent(),
    bool? isFailure,
    bool? isDropset,
    bool? isRestPause,
    bool? isWarmup,
  }) => WorkoutSet(
    id: id ?? this.id,
    sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
    setIndex: setIndex ?? this.setIndex,
    weight: weight ?? this.weight,
    reps: reps ?? this.reps,
    completed: completed ?? this.completed,
    rpe: rpe.present ? rpe.value : this.rpe,
    notes: notes.present ? notes.value : this.notes,
    restSeconds: restSeconds.present ? restSeconds.value : this.restSeconds,
    isFailure: isFailure ?? this.isFailure,
    isDropset: isDropset ?? this.isDropset,
    isRestPause: isRestPause ?? this.isRestPause,
    isWarmup: isWarmup ?? this.isWarmup,
  );
  WorkoutSet copyWithCompanion(WorkoutSetsCompanion data) {
    return WorkoutSet(
      id: data.id.present ? data.id.value : this.id,
      sessionExerciseId: data.sessionExerciseId.present
          ? data.sessionExerciseId.value
          : this.sessionExerciseId,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      weight: data.weight.present ? data.weight.value : this.weight,
      reps: data.reps.present ? data.reps.value : this.reps,
      completed: data.completed.present ? data.completed.value : this.completed,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      notes: data.notes.present ? data.notes.value : this.notes,
      restSeconds: data.restSeconds.present
          ? data.restSeconds.value
          : this.restSeconds,
      isFailure: data.isFailure.present ? data.isFailure.value : this.isFailure,
      isDropset: data.isDropset.present ? data.isDropset.value : this.isDropset,
      isRestPause: data.isRestPause.present
          ? data.isRestPause.value
          : this.isRestPause,
      isWarmup: data.isWarmup.present ? data.isWarmup.value : this.isWarmup,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSet(')
          ..write('id: $id, ')
          ..write('sessionExerciseId: $sessionExerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('completed: $completed, ')
          ..write('rpe: $rpe, ')
          ..write('notes: $notes, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('isFailure: $isFailure, ')
          ..write('isDropset: $isDropset, ')
          ..write('isRestPause: $isRestPause, ')
          ..write('isWarmup: $isWarmup')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionExerciseId,
    setIndex,
    weight,
    reps,
    completed,
    rpe,
    notes,
    restSeconds,
    isFailure,
    isDropset,
    isRestPause,
    isWarmup,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSet &&
          other.id == this.id &&
          other.sessionExerciseId == this.sessionExerciseId &&
          other.setIndex == this.setIndex &&
          other.weight == this.weight &&
          other.reps == this.reps &&
          other.completed == this.completed &&
          other.rpe == this.rpe &&
          other.notes == this.notes &&
          other.restSeconds == this.restSeconds &&
          other.isFailure == this.isFailure &&
          other.isDropset == this.isDropset &&
          other.isRestPause == this.isRestPause &&
          other.isWarmup == this.isWarmup);
}

class WorkoutSetsCompanion extends UpdateCompanion<WorkoutSet> {
  final Value<String> id;
  final Value<String> sessionExerciseId;
  final Value<int> setIndex;
  final Value<double> weight;
  final Value<int> reps;
  final Value<bool> completed;
  final Value<int?> rpe;
  final Value<String?> notes;
  final Value<int?> restSeconds;
  final Value<bool> isFailure;
  final Value<bool> isDropset;
  final Value<bool> isRestPause;
  final Value<bool> isWarmup;
  final Value<int> rowid;
  const WorkoutSetsCompanion({
    this.id = const Value.absent(),
    this.sessionExerciseId = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.completed = const Value.absent(),
    this.rpe = const Value.absent(),
    this.notes = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.isFailure = const Value.absent(),
    this.isDropset = const Value.absent(),
    this.isRestPause = const Value.absent(),
    this.isWarmup = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutSetsCompanion.insert({
    required String id,
    required String sessionExerciseId,
    required int setIndex,
    required double weight,
    required int reps,
    this.completed = const Value.absent(),
    this.rpe = const Value.absent(),
    this.notes = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.isFailure = const Value.absent(),
    this.isDropset = const Value.absent(),
    this.isRestPause = const Value.absent(),
    this.isWarmup = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionExerciseId = Value(sessionExerciseId),
       setIndex = Value(setIndex),
       weight = Value(weight),
       reps = Value(reps);
  static Insertable<WorkoutSet> custom({
    Expression<String>? id,
    Expression<String>? sessionExerciseId,
    Expression<int>? setIndex,
    Expression<double>? weight,
    Expression<int>? reps,
    Expression<bool>? completed,
    Expression<int>? rpe,
    Expression<String>? notes,
    Expression<int>? restSeconds,
    Expression<bool>? isFailure,
    Expression<bool>? isDropset,
    Expression<bool>? isRestPause,
    Expression<bool>? isWarmup,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionExerciseId != null) 'session_exercise_id': sessionExerciseId,
      if (setIndex != null) 'set_index': setIndex,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (completed != null) 'completed': completed,
      if (rpe != null) 'rpe': rpe,
      if (notes != null) 'notes': notes,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (isFailure != null) 'is_failure': isFailure,
      if (isDropset != null) 'is_dropset': isDropset,
      if (isRestPause != null) 'is_rest_pause': isRestPause,
      if (isWarmup != null) 'is_warmup': isWarmup,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutSetsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionExerciseId,
    Value<int>? setIndex,
    Value<double>? weight,
    Value<int>? reps,
    Value<bool>? completed,
    Value<int?>? rpe,
    Value<String?>? notes,
    Value<int?>? restSeconds,
    Value<bool>? isFailure,
    Value<bool>? isDropset,
    Value<bool>? isRestPause,
    Value<bool>? isWarmup,
    Value<int>? rowid,
  }) {
    return WorkoutSetsCompanion(
      id: id ?? this.id,
      sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
      setIndex: setIndex ?? this.setIndex,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      completed: completed ?? this.completed,
      rpe: rpe ?? this.rpe,
      notes: notes ?? this.notes,
      restSeconds: restSeconds ?? this.restSeconds,
      isFailure: isFailure ?? this.isFailure,
      isDropset: isDropset ?? this.isDropset,
      isRestPause: isRestPause ?? this.isRestPause,
      isWarmup: isWarmup ?? this.isWarmup,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionExerciseId.present) {
      map['session_exercise_id'] = Variable<String>(sessionExerciseId.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<int>(rpe.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (isFailure.present) {
      map['is_failure'] = Variable<bool>(isFailure.value);
    }
    if (isDropset.present) {
      map['is_dropset'] = Variable<bool>(isDropset.value);
    }
    if (isRestPause.present) {
      map['is_rest_pause'] = Variable<bool>(isRestPause.value);
    }
    if (isWarmup.present) {
      map['is_warmup'] = Variable<bool>(isWarmup.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetsCompanion(')
          ..write('id: $id, ')
          ..write('sessionExerciseId: $sessionExerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('completed: $completed, ')
          ..write('rpe: $rpe, ')
          ..write('notes: $notes, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('isFailure: $isFailure, ')
          ..write('isDropset: $isDropset, ')
          ..write('isRestPause: $isRestPause, ')
          ..write('isWarmup: $isWarmup, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseNotesTable extends ExerciseNotes
    with TableInfo<$ExerciseNotesTable, ExerciseNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseNameMeta = const VerificationMeta(
    'exerciseName',
  );
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
    'exercise_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [exerciseName, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_name')) {
      context.handle(
        _exerciseNameMeta,
        exerciseName.isAcceptableOrUnknown(
          data['exercise_name']!,
          _exerciseNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseNameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exerciseName};
  @override
  ExerciseNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseNote(
      exerciseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $ExerciseNotesTable createAlias(String alias) {
    return $ExerciseNotesTable(attachedDatabase, alias);
  }
}

class ExerciseNote extends DataClass implements Insertable<ExerciseNote> {
  final String exerciseName;
  final String note;
  const ExerciseNote({required this.exerciseName, required this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_name'] = Variable<String>(exerciseName);
    map['note'] = Variable<String>(note);
    return map;
  }

  ExerciseNotesCompanion toCompanion(bool nullToAbsent) {
    return ExerciseNotesCompanion(
      exerciseName: Value(exerciseName),
      note: Value(note),
    );
  }

  factory ExerciseNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseNote(
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseName': serializer.toJson<String>(exerciseName),
      'note': serializer.toJson<String>(note),
    };
  }

  ExerciseNote copyWith({String? exerciseName, String? note}) => ExerciseNote(
    exerciseName: exerciseName ?? this.exerciseName,
    note: note ?? this.note,
  );
  ExerciseNote copyWithCompanion(ExerciseNotesCompanion data) {
    return ExerciseNote(
      exerciseName: data.exerciseName.present
          ? data.exerciseName.value
          : this.exerciseName,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseNote(')
          ..write('exerciseName: $exerciseName, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exerciseName, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseNote &&
          other.exerciseName == this.exerciseName &&
          other.note == this.note);
}

class ExerciseNotesCompanion extends UpdateCompanion<ExerciseNote> {
  final Value<String> exerciseName;
  final Value<String> note;
  final Value<int> rowid;
  const ExerciseNotesCompanion({
    this.exerciseName = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseNotesCompanion.insert({
    required String exerciseName,
    required String note,
    this.rowid = const Value.absent(),
  }) : exerciseName = Value(exerciseName),
       note = Value(note);
  static Insertable<ExerciseNote> custom({
    Expression<String>? exerciseName,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseNotesCompanion copyWith({
    Value<String>? exerciseName,
    Value<String>? note,
    Value<int>? rowid,
  }) {
    return ExerciseNotesCompanion(
      exerciseName: exerciseName ?? this.exerciseName,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseNotesCompanion(')
          ..write('exerciseName: $exerciseName, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
    'age',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentWeightKgMeta = const VerificationMeta(
    'currentWeightKg',
  );
  @override
  late final GeneratedColumn<double> currentWeightKg = GeneratedColumn<double>(
    'current_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activityLevelMeta = const VerificationMeta(
    'activityLevel',
  );
  @override
  late final GeneratedColumn<String> activityLevel = GeneratedColumn<String>(
    'activity_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('moderatelyActive'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    age,
    gender,
    heightCm,
    currentWeightKg,
    activityLevel,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
      );
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('current_weight_kg')) {
      context.handle(
        _currentWeightKgMeta,
        currentWeightKg.isAcceptableOrUnknown(
          data['current_weight_kg']!,
          _currentWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('activity_level')) {
      context.handle(
        _activityLevelMeta,
        activityLevel.isAcceptableOrUnknown(
          data['activity_level']!,
          _activityLevelMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      age: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age'],
      ),
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      currentWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_weight_kg'],
      ),
      activityLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_level'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfile extends DataClass implements Insertable<UserProfile> {
  final String id;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? currentWeightKg;
  final String activityLevel;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserProfile({
    required this.id,
    this.age,
    this.gender,
    this.heightCm,
    this.currentWeightKg,
    required this.activityLevel,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || age != null) {
      map['age'] = Variable<int>(age);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || currentWeightKg != null) {
      map['current_weight_kg'] = Variable<double>(currentWeightKg);
    }
    map['activity_level'] = Variable<String>(activityLevel);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      age: age == null && nullToAbsent ? const Value.absent() : Value(age),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      currentWeightKg: currentWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(currentWeightKg),
      activityLevel: Value(activityLevel),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfile(
      id: serializer.fromJson<String>(json['id']),
      age: serializer.fromJson<int?>(json['age']),
      gender: serializer.fromJson<String?>(json['gender']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      currentWeightKg: serializer.fromJson<double?>(json['currentWeightKg']),
      activityLevel: serializer.fromJson<String>(json['activityLevel']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'age': serializer.toJson<int?>(age),
      'gender': serializer.toJson<String?>(gender),
      'heightCm': serializer.toJson<double?>(heightCm),
      'currentWeightKg': serializer.toJson<double?>(currentWeightKg),
      'activityLevel': serializer.toJson<String>(activityLevel),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserProfile copyWith({
    String? id,
    Value<int?> age = const Value.absent(),
    Value<String?> gender = const Value.absent(),
    Value<double?> heightCm = const Value.absent(),
    Value<double?> currentWeightKg = const Value.absent(),
    String? activityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id ?? this.id,
    age: age.present ? age.value : this.age,
    gender: gender.present ? gender.value : this.gender,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    currentWeightKg: currentWeightKg.present
        ? currentWeightKg.value
        : this.currentWeightKg,
    activityLevel: activityLevel ?? this.activityLevel,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserProfile copyWithCompanion(UserProfilesCompanion data) {
    return UserProfile(
      id: data.id.present ? data.id.value : this.id,
      age: data.age.present ? data.age.value : this.age,
      gender: data.gender.present ? data.gender.value : this.gender,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      currentWeightKg: data.currentWeightKg.present
          ? data.currentWeightKg.value
          : this.currentWeightKg,
      activityLevel: data.activityLevel.present
          ? data.activityLevel.value
          : this.activityLevel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfile(')
          ..write('id: $id, ')
          ..write('age: $age, ')
          ..write('gender: $gender, ')
          ..write('heightCm: $heightCm, ')
          ..write('currentWeightKg: $currentWeightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    age,
    gender,
    heightCm,
    currentWeightKg,
    activityLevel,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfile &&
          other.id == this.id &&
          other.age == this.age &&
          other.gender == this.gender &&
          other.heightCm == this.heightCm &&
          other.currentWeightKg == this.currentWeightKg &&
          other.activityLevel == this.activityLevel &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfile> {
  final Value<String> id;
  final Value<int?> age;
  final Value<String?> gender;
  final Value<double?> heightCm;
  final Value<double?> currentWeightKg;
  final Value<String> activityLevel;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.age = const Value.absent(),
    this.gender = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.currentWeightKg = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    required String id,
    this.age = const Value.absent(),
    this.gender = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.currentWeightKg = const Value.absent(),
    this.activityLevel = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserProfile> custom({
    Expression<String>? id,
    Expression<int>? age,
    Expression<String>? gender,
    Expression<double>? heightCm,
    Expression<double>? currentWeightKg,
    Expression<String>? activityLevel,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (heightCm != null) 'height_cm': heightCm,
      if (currentWeightKg != null) 'current_weight_kg': currentWeightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfilesCompanion copyWith({
    Value<String>? id,
    Value<int?>? age,
    Value<String?>? gender,
    Value<double?>? heightCm,
    Value<double?>? currentWeightKg,
    Value<String>? activityLevel,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
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
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (currentWeightKg.present) {
      map['current_weight_kg'] = Variable<double>(currentWeightKg.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>(activityLevel.value);
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
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('age: $age, ')
          ..write('gender: $gender, ')
          ..write('heightCm: $heightCm, ')
          ..write('currentWeightKg: $currentWeightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoodsTable extends Foods with TableInfo<$FoodsTable, Food> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kcalPer100gMeta = const VerificationMeta(
    'kcalPer100g',
  );
  @override
  late final GeneratedColumn<int> kcalPer100g = GeneratedColumn<int>(
    'kcal_per100g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinPer100gMeta = const VerificationMeta(
    'proteinPer100g',
  );
  @override
  late final GeneratedColumn<double> proteinPer100g = GeneratedColumn<double>(
    'protein_per100g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsPer100gMeta = const VerificationMeta(
    'carbsPer100g',
  );
  @override
  late final GeneratedColumn<double> carbsPer100g = GeneratedColumn<double>(
    'carbs_per100g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatPer100gMeta = const VerificationMeta(
    'fatPer100g',
  );
  @override
  late final GeneratedColumn<double> fatPer100g = GeneratedColumn<double>(
    'fat_per100g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portionNameMeta = const VerificationMeta(
    'portionName',
  );
  @override
  late final GeneratedColumn<String> portionName = GeneratedColumn<String>(
    'portion_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portionGramsMeta = const VerificationMeta(
    'portionGrams',
  );
  @override
  late final GeneratedColumn<double> portionGrams = GeneratedColumn<double>(
    'portion_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userCreatedMeta = const VerificationMeta(
    'userCreated',
  );
  @override
  late final GeneratedColumn<bool> userCreated = GeneratedColumn<bool>(
    'user_created',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_created" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _verifiedSourceMeta = const VerificationMeta(
    'verifiedSource',
  );
  @override
  late final GeneratedColumn<String> verifiedSource = GeneratedColumn<String>(
    'verified_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>?, String>
  sourceMetadata = GeneratedColumn<String>(
    'source_metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<Map<String, dynamic>?>($FoodsTable.$convertersourceMetadatan);
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _useCountMeta = const VerificationMeta(
    'useCount',
  );
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
    'use_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nutriScoreMeta = const VerificationMeta(
    'nutriScore',
  );
  @override
  late final GeneratedColumn<String> nutriScore = GeneratedColumn<String>(
    'nutri_score',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _novaGroupMeta = const VerificationMeta(
    'novaGroup',
  );
  @override
  late final GeneratedColumn<int> novaGroup = GeneratedColumn<int>(
    'nova_group',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    brand,
    barcode,
    kcalPer100g,
    proteinPer100g,
    carbsPer100g,
    fatPer100g,
    portionName,
    portionGrams,
    userCreated,
    verifiedSource,
    sourceMetadata,
    normalizedName,
    useCount,
    lastUsedAt,
    nutriScore,
    novaGroup,
    isFavorite,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<Food> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('kcal_per100g')) {
      context.handle(
        _kcalPer100gMeta,
        kcalPer100g.isAcceptableOrUnknown(
          data['kcal_per100g']!,
          _kcalPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kcalPer100gMeta);
    }
    if (data.containsKey('protein_per100g')) {
      context.handle(
        _proteinPer100gMeta,
        proteinPer100g.isAcceptableOrUnknown(
          data['protein_per100g']!,
          _proteinPer100gMeta,
        ),
      );
    }
    if (data.containsKey('carbs_per100g')) {
      context.handle(
        _carbsPer100gMeta,
        carbsPer100g.isAcceptableOrUnknown(
          data['carbs_per100g']!,
          _carbsPer100gMeta,
        ),
      );
    }
    if (data.containsKey('fat_per100g')) {
      context.handle(
        _fatPer100gMeta,
        fatPer100g.isAcceptableOrUnknown(data['fat_per100g']!, _fatPer100gMeta),
      );
    }
    if (data.containsKey('portion_name')) {
      context.handle(
        _portionNameMeta,
        portionName.isAcceptableOrUnknown(
          data['portion_name']!,
          _portionNameMeta,
        ),
      );
    }
    if (data.containsKey('portion_grams')) {
      context.handle(
        _portionGramsMeta,
        portionGrams.isAcceptableOrUnknown(
          data['portion_grams']!,
          _portionGramsMeta,
        ),
      );
    }
    if (data.containsKey('user_created')) {
      context.handle(
        _userCreatedMeta,
        userCreated.isAcceptableOrUnknown(
          data['user_created']!,
          _userCreatedMeta,
        ),
      );
    }
    if (data.containsKey('verified_source')) {
      context.handle(
        _verifiedSourceMeta,
        verifiedSource.isAcceptableOrUnknown(
          data['verified_source']!,
          _verifiedSourceMeta,
        ),
      );
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    }
    if (data.containsKey('use_count')) {
      context.handle(
        _useCountMeta,
        useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    if (data.containsKey('nutri_score')) {
      context.handle(
        _nutriScoreMeta,
        nutriScore.isAcceptableOrUnknown(data['nutri_score']!, _nutriScoreMeta),
      );
    }
    if (data.containsKey('nova_group')) {
      context.handle(
        _novaGroupMeta,
        novaGroup.isAcceptableOrUnknown(data['nova_group']!, _novaGroupMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Food map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Food(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      kcalPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kcal_per100g'],
      )!,
      proteinPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_per100g'],
      ),
      carbsPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_per100g'],
      ),
      fatPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_per100g'],
      ),
      portionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portion_name'],
      ),
      portionGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}portion_grams'],
      ),
      userCreated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_created'],
      )!,
      verifiedSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verified_source'],
      ),
      sourceMetadata: $FoodsTable.$convertersourceMetadatan.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source_metadata'],
        ),
      ),
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      ),
      useCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}use_count'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      ),
      nutriScore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nutri_score'],
      ),
      novaGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}nova_group'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FoodsTable createAlias(String alias) {
    return $FoodsTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, dynamic>, String> $convertersourceMetadata =
      const JsonMapConverter();
  static TypeConverter<Map<String, dynamic>?, String?>
  $convertersourceMetadatan = NullAwareTypeConverter.wrap(
    $convertersourceMetadata,
  );
}

class Food extends DataClass implements Insertable<Food> {
  final String id;
  final String name;
  final String? brand;
  final String? barcode;
  final int kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final String? portionName;
  final double? portionGrams;
  final bool userCreated;
  final String? verifiedSource;
  final Map<String, dynamic>? sourceMetadata;
  final String? normalizedName;
  final int useCount;
  final DateTime? lastUsedAt;
  final String? nutriScore;
  final int? novaGroup;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Food({
    required this.id,
    required this.name,
    this.brand,
    this.barcode,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.portionName,
    this.portionGrams,
    required this.userCreated,
    this.verifiedSource,
    this.sourceMetadata,
    this.normalizedName,
    required this.useCount,
    this.lastUsedAt,
    this.nutriScore,
    this.novaGroup,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['kcal_per100g'] = Variable<int>(kcalPer100g);
    if (!nullToAbsent || proteinPer100g != null) {
      map['protein_per100g'] = Variable<double>(proteinPer100g);
    }
    if (!nullToAbsent || carbsPer100g != null) {
      map['carbs_per100g'] = Variable<double>(carbsPer100g);
    }
    if (!nullToAbsent || fatPer100g != null) {
      map['fat_per100g'] = Variable<double>(fatPer100g);
    }
    if (!nullToAbsent || portionName != null) {
      map['portion_name'] = Variable<String>(portionName);
    }
    if (!nullToAbsent || portionGrams != null) {
      map['portion_grams'] = Variable<double>(portionGrams);
    }
    map['user_created'] = Variable<bool>(userCreated);
    if (!nullToAbsent || verifiedSource != null) {
      map['verified_source'] = Variable<String>(verifiedSource);
    }
    if (!nullToAbsent || sourceMetadata != null) {
      map['source_metadata'] = Variable<String>(
        $FoodsTable.$convertersourceMetadatan.toSql(sourceMetadata),
      );
    }
    if (!nullToAbsent || normalizedName != null) {
      map['normalized_name'] = Variable<String>(normalizedName);
    }
    map['use_count'] = Variable<int>(useCount);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    if (!nullToAbsent || nutriScore != null) {
      map['nutri_score'] = Variable<String>(nutriScore);
    }
    if (!nullToAbsent || novaGroup != null) {
      map['nova_group'] = Variable<int>(novaGroup);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FoodsCompanion toCompanion(bool nullToAbsent) {
    return FoodsCompanion(
      id: Value(id),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      kcalPer100g: Value(kcalPer100g),
      proteinPer100g: proteinPer100g == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinPer100g),
      carbsPer100g: carbsPer100g == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsPer100g),
      fatPer100g: fatPer100g == null && nullToAbsent
          ? const Value.absent()
          : Value(fatPer100g),
      portionName: portionName == null && nullToAbsent
          ? const Value.absent()
          : Value(portionName),
      portionGrams: portionGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(portionGrams),
      userCreated: Value(userCreated),
      verifiedSource: verifiedSource == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedSource),
      sourceMetadata: sourceMetadata == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceMetadata),
      normalizedName: normalizedName == null && nullToAbsent
          ? const Value.absent()
          : Value(normalizedName),
      useCount: Value(useCount),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      nutriScore: nutriScore == null && nullToAbsent
          ? const Value.absent()
          : Value(nutriScore),
      novaGroup: novaGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(novaGroup),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Food.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Food(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      kcalPer100g: serializer.fromJson<int>(json['kcalPer100g']),
      proteinPer100g: serializer.fromJson<double?>(json['proteinPer100g']),
      carbsPer100g: serializer.fromJson<double?>(json['carbsPer100g']),
      fatPer100g: serializer.fromJson<double?>(json['fatPer100g']),
      portionName: serializer.fromJson<String?>(json['portionName']),
      portionGrams: serializer.fromJson<double?>(json['portionGrams']),
      userCreated: serializer.fromJson<bool>(json['userCreated']),
      verifiedSource: serializer.fromJson<String?>(json['verifiedSource']),
      sourceMetadata: serializer.fromJson<Map<String, dynamic>?>(
        json['sourceMetadata'],
      ),
      normalizedName: serializer.fromJson<String?>(json['normalizedName']),
      useCount: serializer.fromJson<int>(json['useCount']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
      nutriScore: serializer.fromJson<String?>(json['nutriScore']),
      novaGroup: serializer.fromJson<int?>(json['novaGroup']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'barcode': serializer.toJson<String?>(barcode),
      'kcalPer100g': serializer.toJson<int>(kcalPer100g),
      'proteinPer100g': serializer.toJson<double?>(proteinPer100g),
      'carbsPer100g': serializer.toJson<double?>(carbsPer100g),
      'fatPer100g': serializer.toJson<double?>(fatPer100g),
      'portionName': serializer.toJson<String?>(portionName),
      'portionGrams': serializer.toJson<double?>(portionGrams),
      'userCreated': serializer.toJson<bool>(userCreated),
      'verifiedSource': serializer.toJson<String?>(verifiedSource),
      'sourceMetadata': serializer.toJson<Map<String, dynamic>?>(
        sourceMetadata,
      ),
      'normalizedName': serializer.toJson<String?>(normalizedName),
      'useCount': serializer.toJson<int>(useCount),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
      'nutriScore': serializer.toJson<String?>(nutriScore),
      'novaGroup': serializer.toJson<int?>(novaGroup),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Food copyWith({
    String? id,
    String? name,
    Value<String?> brand = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    int? kcalPer100g,
    Value<double?> proteinPer100g = const Value.absent(),
    Value<double?> carbsPer100g = const Value.absent(),
    Value<double?> fatPer100g = const Value.absent(),
    Value<String?> portionName = const Value.absent(),
    Value<double?> portionGrams = const Value.absent(),
    bool? userCreated,
    Value<String?> verifiedSource = const Value.absent(),
    Value<Map<String, dynamic>?> sourceMetadata = const Value.absent(),
    Value<String?> normalizedName = const Value.absent(),
    int? useCount,
    Value<DateTime?> lastUsedAt = const Value.absent(),
    Value<String?> nutriScore = const Value.absent(),
    Value<int?> novaGroup = const Value.absent(),
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Food(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    barcode: barcode.present ? barcode.value : this.barcode,
    kcalPer100g: kcalPer100g ?? this.kcalPer100g,
    proteinPer100g: proteinPer100g.present
        ? proteinPer100g.value
        : this.proteinPer100g,
    carbsPer100g: carbsPer100g.present ? carbsPer100g.value : this.carbsPer100g,
    fatPer100g: fatPer100g.present ? fatPer100g.value : this.fatPer100g,
    portionName: portionName.present ? portionName.value : this.portionName,
    portionGrams: portionGrams.present ? portionGrams.value : this.portionGrams,
    userCreated: userCreated ?? this.userCreated,
    verifiedSource: verifiedSource.present
        ? verifiedSource.value
        : this.verifiedSource,
    sourceMetadata: sourceMetadata.present
        ? sourceMetadata.value
        : this.sourceMetadata,
    normalizedName: normalizedName.present
        ? normalizedName.value
        : this.normalizedName,
    useCount: useCount ?? this.useCount,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
    nutriScore: nutriScore.present ? nutriScore.value : this.nutriScore,
    novaGroup: novaGroup.present ? novaGroup.value : this.novaGroup,
    isFavorite: isFavorite ?? this.isFavorite,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Food copyWithCompanion(FoodsCompanion data) {
    return Food(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      kcalPer100g: data.kcalPer100g.present
          ? data.kcalPer100g.value
          : this.kcalPer100g,
      proteinPer100g: data.proteinPer100g.present
          ? data.proteinPer100g.value
          : this.proteinPer100g,
      carbsPer100g: data.carbsPer100g.present
          ? data.carbsPer100g.value
          : this.carbsPer100g,
      fatPer100g: data.fatPer100g.present
          ? data.fatPer100g.value
          : this.fatPer100g,
      portionName: data.portionName.present
          ? data.portionName.value
          : this.portionName,
      portionGrams: data.portionGrams.present
          ? data.portionGrams.value
          : this.portionGrams,
      userCreated: data.userCreated.present
          ? data.userCreated.value
          : this.userCreated,
      verifiedSource: data.verifiedSource.present
          ? data.verifiedSource.value
          : this.verifiedSource,
      sourceMetadata: data.sourceMetadata.present
          ? data.sourceMetadata.value
          : this.sourceMetadata,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      nutriScore: data.nutriScore.present
          ? data.nutriScore.value
          : this.nutriScore,
      novaGroup: data.novaGroup.present ? data.novaGroup.value : this.novaGroup,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Food(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('barcode: $barcode, ')
          ..write('kcalPer100g: $kcalPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('carbsPer100g: $carbsPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('portionName: $portionName, ')
          ..write('portionGrams: $portionGrams, ')
          ..write('userCreated: $userCreated, ')
          ..write('verifiedSource: $verifiedSource, ')
          ..write('sourceMetadata: $sourceMetadata, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('nutriScore: $nutriScore, ')
          ..write('novaGroup: $novaGroup, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    brand,
    barcode,
    kcalPer100g,
    proteinPer100g,
    carbsPer100g,
    fatPer100g,
    portionName,
    portionGrams,
    userCreated,
    verifiedSource,
    sourceMetadata,
    normalizedName,
    useCount,
    lastUsedAt,
    nutriScore,
    novaGroup,
    isFavorite,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Food &&
          other.id == this.id &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.barcode == this.barcode &&
          other.kcalPer100g == this.kcalPer100g &&
          other.proteinPer100g == this.proteinPer100g &&
          other.carbsPer100g == this.carbsPer100g &&
          other.fatPer100g == this.fatPer100g &&
          other.portionName == this.portionName &&
          other.portionGrams == this.portionGrams &&
          other.userCreated == this.userCreated &&
          other.verifiedSource == this.verifiedSource &&
          other.sourceMetadata == this.sourceMetadata &&
          other.normalizedName == this.normalizedName &&
          other.useCount == this.useCount &&
          other.lastUsedAt == this.lastUsedAt &&
          other.nutriScore == this.nutriScore &&
          other.novaGroup == this.novaGroup &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FoodsCompanion extends UpdateCompanion<Food> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> brand;
  final Value<String?> barcode;
  final Value<int> kcalPer100g;
  final Value<double?> proteinPer100g;
  final Value<double?> carbsPer100g;
  final Value<double?> fatPer100g;
  final Value<String?> portionName;
  final Value<double?> portionGrams;
  final Value<bool> userCreated;
  final Value<String?> verifiedSource;
  final Value<Map<String, dynamic>?> sourceMetadata;
  final Value<String?> normalizedName;
  final Value<int> useCount;
  final Value<DateTime?> lastUsedAt;
  final Value<String?> nutriScore;
  final Value<int?> novaGroup;
  final Value<bool> isFavorite;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.barcode = const Value.absent(),
    this.kcalPer100g = const Value.absent(),
    this.proteinPer100g = const Value.absent(),
    this.carbsPer100g = const Value.absent(),
    this.fatPer100g = const Value.absent(),
    this.portionName = const Value.absent(),
    this.portionGrams = const Value.absent(),
    this.userCreated = const Value.absent(),
    this.verifiedSource = const Value.absent(),
    this.sourceMetadata = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.nutriScore = const Value.absent(),
    this.novaGroup = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodsCompanion.insert({
    required String id,
    required String name,
    this.brand = const Value.absent(),
    this.barcode = const Value.absent(),
    required int kcalPer100g,
    this.proteinPer100g = const Value.absent(),
    this.carbsPer100g = const Value.absent(),
    this.fatPer100g = const Value.absent(),
    this.portionName = const Value.absent(),
    this.portionGrams = const Value.absent(),
    this.userCreated = const Value.absent(),
    this.verifiedSource = const Value.absent(),
    this.sourceMetadata = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.nutriScore = const Value.absent(),
    this.novaGroup = const Value.absent(),
    this.isFavorite = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kcalPer100g = Value(kcalPer100g),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Food> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<String>? barcode,
    Expression<int>? kcalPer100g,
    Expression<double>? proteinPer100g,
    Expression<double>? carbsPer100g,
    Expression<double>? fatPer100g,
    Expression<String>? portionName,
    Expression<double>? portionGrams,
    Expression<bool>? userCreated,
    Expression<String>? verifiedSource,
    Expression<String>? sourceMetadata,
    Expression<String>? normalizedName,
    Expression<int>? useCount,
    Expression<DateTime>? lastUsedAt,
    Expression<String>? nutriScore,
    Expression<int>? novaGroup,
    Expression<bool>? isFavorite,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (barcode != null) 'barcode': barcode,
      if (kcalPer100g != null) 'kcal_per100g': kcalPer100g,
      if (proteinPer100g != null) 'protein_per100g': proteinPer100g,
      if (carbsPer100g != null) 'carbs_per100g': carbsPer100g,
      if (fatPer100g != null) 'fat_per100g': fatPer100g,
      if (portionName != null) 'portion_name': portionName,
      if (portionGrams != null) 'portion_grams': portionGrams,
      if (userCreated != null) 'user_created': userCreated,
      if (verifiedSource != null) 'verified_source': verifiedSource,
      if (sourceMetadata != null) 'source_metadata': sourceMetadata,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (useCount != null) 'use_count': useCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (nutriScore != null) 'nutri_score': nutriScore,
      if (novaGroup != null) 'nova_group': novaGroup,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? brand,
    Value<String?>? barcode,
    Value<int>? kcalPer100g,
    Value<double?>? proteinPer100g,
    Value<double?>? carbsPer100g,
    Value<double?>? fatPer100g,
    Value<String?>? portionName,
    Value<double?>? portionGrams,
    Value<bool>? userCreated,
    Value<String?>? verifiedSource,
    Value<Map<String, dynamic>?>? sourceMetadata,
    Value<String?>? normalizedName,
    Value<int>? useCount,
    Value<DateTime?>? lastUsedAt,
    Value<String?>? nutriScore,
    Value<int?>? novaGroup,
    Value<bool>? isFavorite,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      kcalPer100g: kcalPer100g ?? this.kcalPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      portionName: portionName ?? this.portionName,
      portionGrams: portionGrams ?? this.portionGrams,
      userCreated: userCreated ?? this.userCreated,
      verifiedSource: verifiedSource ?? this.verifiedSource,
      sourceMetadata: sourceMetadata ?? this.sourceMetadata,
      normalizedName: normalizedName ?? this.normalizedName,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      nutriScore: nutriScore ?? this.nutriScore,
      novaGroup: novaGroup ?? this.novaGroup,
      isFavorite: isFavorite ?? this.isFavorite,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (kcalPer100g.present) {
      map['kcal_per100g'] = Variable<int>(kcalPer100g.value);
    }
    if (proteinPer100g.present) {
      map['protein_per100g'] = Variable<double>(proteinPer100g.value);
    }
    if (carbsPer100g.present) {
      map['carbs_per100g'] = Variable<double>(carbsPer100g.value);
    }
    if (fatPer100g.present) {
      map['fat_per100g'] = Variable<double>(fatPer100g.value);
    }
    if (portionName.present) {
      map['portion_name'] = Variable<String>(portionName.value);
    }
    if (portionGrams.present) {
      map['portion_grams'] = Variable<double>(portionGrams.value);
    }
    if (userCreated.present) {
      map['user_created'] = Variable<bool>(userCreated.value);
    }
    if (verifiedSource.present) {
      map['verified_source'] = Variable<String>(verifiedSource.value);
    }
    if (sourceMetadata.present) {
      map['source_metadata'] = Variable<String>(
        $FoodsTable.$convertersourceMetadatan.toSql(sourceMetadata.value),
      );
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (nutriScore.present) {
      map['nutri_score'] = Variable<String>(nutriScore.value);
    }
    if (novaGroup.present) {
      map['nova_group'] = Variable<int>(novaGroup.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
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
    return (StringBuffer('FoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('barcode: $barcode, ')
          ..write('kcalPer100g: $kcalPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('carbsPer100g: $carbsPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('portionName: $portionName, ')
          ..write('portionGrams: $portionGrams, ')
          ..write('userCreated: $userCreated, ')
          ..write('verifiedSource: $verifiedSource, ')
          ..write('sourceMetadata: $sourceMetadata, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('nutriScore: $nutriScore, ')
          ..write('novaGroup: $novaGroup, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiaryEntriesTable extends DiaryEntries
    with TableInfo<$DiaryEntriesTable, DiaryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiaryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MealType, String> mealType =
      GeneratedColumn<String>(
        'meal_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MealType>($DiaryEntriesTable.$convertermealType);
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES foods (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _foodNameMeta = const VerificationMeta(
    'foodName',
  );
  @override
  late final GeneratedColumn<String> foodName = GeneratedColumn<String>(
    'food_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodBrandMeta = const VerificationMeta(
    'foodBrand',
  );
  @override
  late final GeneratedColumn<String> foodBrand = GeneratedColumn<String>(
    'food_brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ServingUnit, String> unit =
      GeneratedColumn<String>(
        'unit',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ServingUnit>($DiaryEntriesTable.$converterunit);
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<int> kcal = GeneratedColumn<int>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
    'protein',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<double> carbs = GeneratedColumn<double>(
    'carbs',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<double> fat = GeneratedColumn<double>(
    'fat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isQuickAddMeta = const VerificationMeta(
    'isQuickAdd',
  );
  @override
  late final GeneratedColumn<bool> isQuickAdd = GeneratedColumn<bool>(
    'is_quick_add',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_quick_add" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    mealType,
    foodId,
    foodName,
    foodBrand,
    amount,
    unit,
    kcal,
    protein,
    carbs,
    fat,
    isQuickAdd,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diary_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiaryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    }
    if (data.containsKey('food_name')) {
      context.handle(
        _foodNameMeta,
        foodName.isAcceptableOrUnknown(data['food_name']!, _foodNameMeta),
      );
    } else if (isInserting) {
      context.missing(_foodNameMeta);
    }
    if (data.containsKey('food_brand')) {
      context.handle(
        _foodBrandMeta,
        foodBrand.isAcceptableOrUnknown(data['food_brand']!, _foodBrandMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    }
    if (data.containsKey('carbs')) {
      context.handle(
        _carbsMeta,
        carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta),
      );
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    }
    if (data.containsKey('is_quick_add')) {
      context.handle(
        _isQuickAddMeta,
        isQuickAdd.isAcceptableOrUnknown(
          data['is_quick_add']!,
          _isQuickAddMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiaryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiaryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      mealType: $DiaryEntriesTable.$convertermealType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meal_type'],
        )!,
      ),
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      ),
      foodName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_name'],
      )!,
      foodBrand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_brand'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      unit: $DiaryEntriesTable.$converterunit.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unit'],
        )!,
      ),
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kcal'],
      )!,
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein'],
      ),
      carbs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs'],
      ),
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat'],
      ),
      isQuickAdd: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_quick_add'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DiaryEntriesTable createAlias(String alias) {
    return $DiaryEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<MealType, String> $convertermealType =
      const MealTypeConverter();
  static TypeConverter<ServingUnit, String> $converterunit =
      const ServingUnitConverter();
}

class DiaryEntry extends DataClass implements Insertable<DiaryEntry> {
  final String id;
  final DateTime date;
  final MealType mealType;
  final String? foodId;
  final String foodName;
  final String? foodBrand;
  final double amount;
  final ServingUnit unit;
  final int kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final bool isQuickAdd;
  final String? notes;
  final DateTime createdAt;
  const DiaryEntry({
    required this.id,
    required this.date,
    required this.mealType,
    this.foodId,
    required this.foodName,
    this.foodBrand,
    required this.amount,
    required this.unit,
    required this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    required this.isQuickAdd,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    {
      map['meal_type'] = Variable<String>(
        $DiaryEntriesTable.$convertermealType.toSql(mealType),
      );
    }
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<String>(foodId);
    }
    map['food_name'] = Variable<String>(foodName);
    if (!nullToAbsent || foodBrand != null) {
      map['food_brand'] = Variable<String>(foodBrand);
    }
    map['amount'] = Variable<double>(amount);
    {
      map['unit'] = Variable<String>(
        $DiaryEntriesTable.$converterunit.toSql(unit),
      );
    }
    map['kcal'] = Variable<int>(kcal);
    if (!nullToAbsent || protein != null) {
      map['protein'] = Variable<double>(protein);
    }
    if (!nullToAbsent || carbs != null) {
      map['carbs'] = Variable<double>(carbs);
    }
    if (!nullToAbsent || fat != null) {
      map['fat'] = Variable<double>(fat);
    }
    map['is_quick_add'] = Variable<bool>(isQuickAdd);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DiaryEntriesCompanion toCompanion(bool nullToAbsent) {
    return DiaryEntriesCompanion(
      id: Value(id),
      date: Value(date),
      mealType: Value(mealType),
      foodId: foodId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodId),
      foodName: Value(foodName),
      foodBrand: foodBrand == null && nullToAbsent
          ? const Value.absent()
          : Value(foodBrand),
      amount: Value(amount),
      unit: Value(unit),
      kcal: Value(kcal),
      protein: protein == null && nullToAbsent
          ? const Value.absent()
          : Value(protein),
      carbs: carbs == null && nullToAbsent
          ? const Value.absent()
          : Value(carbs),
      fat: fat == null && nullToAbsent ? const Value.absent() : Value(fat),
      isQuickAdd: Value(isQuickAdd),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory DiaryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiaryEntry(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      mealType: serializer.fromJson<MealType>(json['mealType']),
      foodId: serializer.fromJson<String?>(json['foodId']),
      foodName: serializer.fromJson<String>(json['foodName']),
      foodBrand: serializer.fromJson<String?>(json['foodBrand']),
      amount: serializer.fromJson<double>(json['amount']),
      unit: serializer.fromJson<ServingUnit>(json['unit']),
      kcal: serializer.fromJson<int>(json['kcal']),
      protein: serializer.fromJson<double?>(json['protein']),
      carbs: serializer.fromJson<double?>(json['carbs']),
      fat: serializer.fromJson<double?>(json['fat']),
      isQuickAdd: serializer.fromJson<bool>(json['isQuickAdd']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'mealType': serializer.toJson<MealType>(mealType),
      'foodId': serializer.toJson<String?>(foodId),
      'foodName': serializer.toJson<String>(foodName),
      'foodBrand': serializer.toJson<String?>(foodBrand),
      'amount': serializer.toJson<double>(amount),
      'unit': serializer.toJson<ServingUnit>(unit),
      'kcal': serializer.toJson<int>(kcal),
      'protein': serializer.toJson<double?>(protein),
      'carbs': serializer.toJson<double?>(carbs),
      'fat': serializer.toJson<double?>(fat),
      'isQuickAdd': serializer.toJson<bool>(isQuickAdd),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    MealType? mealType,
    Value<String?> foodId = const Value.absent(),
    String? foodName,
    Value<String?> foodBrand = const Value.absent(),
    double? amount,
    ServingUnit? unit,
    int? kcal,
    Value<double?> protein = const Value.absent(),
    Value<double?> carbs = const Value.absent(),
    Value<double?> fat = const Value.absent(),
    bool? isQuickAdd,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => DiaryEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    mealType: mealType ?? this.mealType,
    foodId: foodId.present ? foodId.value : this.foodId,
    foodName: foodName ?? this.foodName,
    foodBrand: foodBrand.present ? foodBrand.value : this.foodBrand,
    amount: amount ?? this.amount,
    unit: unit ?? this.unit,
    kcal: kcal ?? this.kcal,
    protein: protein.present ? protein.value : this.protein,
    carbs: carbs.present ? carbs.value : this.carbs,
    fat: fat.present ? fat.value : this.fat,
    isQuickAdd: isQuickAdd ?? this.isQuickAdd,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  DiaryEntry copyWithCompanion(DiaryEntriesCompanion data) {
    return DiaryEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      foodName: data.foodName.present ? data.foodName.value : this.foodName,
      foodBrand: data.foodBrand.present ? data.foodBrand.value : this.foodBrand,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      protein: data.protein.present ? data.protein.value : this.protein,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      fat: data.fat.present ? data.fat.value : this.fat,
      isQuickAdd: data.isQuickAdd.present
          ? data.isQuickAdd.value
          : this.isQuickAdd,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mealType: $mealType, ')
          ..write('foodId: $foodId, ')
          ..write('foodName: $foodName, ')
          ..write('foodBrand: $foodBrand, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat, ')
          ..write('isQuickAdd: $isQuickAdd, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    mealType,
    foodId,
    foodName,
    foodBrand,
    amount,
    unit,
    kcal,
    protein,
    carbs,
    fat,
    isQuickAdd,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiaryEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.mealType == this.mealType &&
          other.foodId == this.foodId &&
          other.foodName == this.foodName &&
          other.foodBrand == this.foodBrand &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.kcal == this.kcal &&
          other.protein == this.protein &&
          other.carbs == this.carbs &&
          other.fat == this.fat &&
          other.isQuickAdd == this.isQuickAdd &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class DiaryEntriesCompanion extends UpdateCompanion<DiaryEntry> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<MealType> mealType;
  final Value<String?> foodId;
  final Value<String> foodName;
  final Value<String?> foodBrand;
  final Value<double> amount;
  final Value<ServingUnit> unit;
  final Value<int> kcal;
  final Value<double?> protein;
  final Value<double?> carbs;
  final Value<double?> fat;
  final Value<bool> isQuickAdd;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DiaryEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.mealType = const Value.absent(),
    this.foodId = const Value.absent(),
    this.foodName = const Value.absent(),
    this.foodBrand = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.kcal = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
    this.isQuickAdd = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiaryEntriesCompanion.insert({
    required String id,
    required DateTime date,
    required MealType mealType,
    this.foodId = const Value.absent(),
    required String foodName,
    this.foodBrand = const Value.absent(),
    required double amount,
    required ServingUnit unit,
    required int kcal,
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
    this.isQuickAdd = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       mealType = Value(mealType),
       foodName = Value(foodName),
       amount = Value(amount),
       unit = Value(unit),
       kcal = Value(kcal),
       createdAt = Value(createdAt);
  static Insertable<DiaryEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<String>? mealType,
    Expression<String>? foodId,
    Expression<String>? foodName,
    Expression<String>? foodBrand,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<int>? kcal,
    Expression<double>? protein,
    Expression<double>? carbs,
    Expression<double>? fat,
    Expression<bool>? isQuickAdd,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (mealType != null) 'meal_type': mealType,
      if (foodId != null) 'food_id': foodId,
      if (foodName != null) 'food_name': foodName,
      if (foodBrand != null) 'food_brand': foodBrand,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (kcal != null) 'kcal': kcal,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fat != null) 'fat': fat,
      if (isQuickAdd != null) 'is_quick_add': isQuickAdd,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiaryEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<MealType>? mealType,
    Value<String?>? foodId,
    Value<String>? foodName,
    Value<String?>? foodBrand,
    Value<double>? amount,
    Value<ServingUnit>? unit,
    Value<int>? kcal,
    Value<double?>? protein,
    Value<double?>? carbs,
    Value<double?>? fat,
    Value<bool>? isQuickAdd,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DiaryEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      foodBrand: foodBrand ?? this.foodBrand,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      isQuickAdd: isQuickAdd ?? this.isQuickAdd,
      notes: notes ?? this.notes,
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
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(
        $DiaryEntriesTable.$convertermealType.toSql(mealType.value),
      );
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (foodName.present) {
      map['food_name'] = Variable<String>(foodName.value);
    }
    if (foodBrand.present) {
      map['food_brand'] = Variable<String>(foodBrand.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(
        $DiaryEntriesTable.$converterunit.toSql(unit.value),
      );
    }
    if (kcal.present) {
      map['kcal'] = Variable<int>(kcal.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<double>(carbs.value);
    }
    if (fat.present) {
      map['fat'] = Variable<double>(fat.value);
    }
    if (isQuickAdd.present) {
      map['is_quick_add'] = Variable<bool>(isQuickAdd.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
    return (StringBuffer('DiaryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mealType: $mealType, ')
          ..write('foodId: $foodId, ')
          ..write('foodName: $foodName, ')
          ..write('foodBrand: $foodBrand, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat, ')
          ..write('isQuickAdd: $isQuickAdd, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeighInsTable extends WeighIns with TableInfo<$WeighInsTable, WeighIn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeighInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measuredAtMeta = const VerificationMeta(
    'measuredAt',
  );
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
    'measured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    measuredAt,
    weightKg,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weigh_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeighIn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('measured_at')) {
      context.handle(
        _measuredAtMeta,
        measuredAt.isAcceptableOrUnknown(data['measured_at']!, _measuredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeighIn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeighIn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      measuredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}measured_at'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WeighInsTable createAlias(String alias) {
    return $WeighInsTable(attachedDatabase, alias);
  }
}

class WeighIn extends DataClass implements Insertable<WeighIn> {
  final String id;
  final DateTime measuredAt;
  final double weightKg;
  final String? note;
  final DateTime createdAt;
  const WeighIn({
    required this.id,
    required this.measuredAt,
    required this.weightKg,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['measured_at'] = Variable<DateTime>(measuredAt);
    map['weight_kg'] = Variable<double>(weightKg);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WeighInsCompanion toCompanion(bool nullToAbsent) {
    return WeighInsCompanion(
      id: Value(id),
      measuredAt: Value(measuredAt),
      weightKg: Value(weightKg),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory WeighIn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeighIn(
      id: serializer.fromJson<String>(json['id']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
      'weightKg': serializer.toJson<double>(weightKg),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WeighIn copyWith({
    String? id,
    DateTime? measuredAt,
    double? weightKg,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => WeighIn(
    id: id ?? this.id,
    measuredAt: measuredAt ?? this.measuredAt,
    weightKg: weightKg ?? this.weightKg,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  WeighIn copyWithCompanion(WeighInsCompanion data) {
    return WeighIn(
      id: data.id.present ? data.id.value : this.id,
      measuredAt: data.measuredAt.present
          ? data.measuredAt.value
          : this.measuredAt,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeighIn(')
          ..write('id: $id, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, measuredAt, weightKg, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeighIn &&
          other.id == this.id &&
          other.measuredAt == this.measuredAt &&
          other.weightKg == this.weightKg &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class WeighInsCompanion extends UpdateCompanion<WeighIn> {
  final Value<String> id;
  final Value<DateTime> measuredAt;
  final Value<double> weightKg;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const WeighInsCompanion({
    this.id = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeighInsCompanion.insert({
    required String id,
    required DateTime measuredAt,
    required double weightKg,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       measuredAt = Value(measuredAt),
       weightKg = Value(weightKg),
       createdAt = Value(createdAt);
  static Insertable<WeighIn> custom({
    Expression<String>? id,
    Expression<DateTime>? measuredAt,
    Expression<double>? weightKg,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (weightKg != null) 'weight_kg': weightKg,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeighInsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? measuredAt,
    Value<double>? weightKg,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return WeighInsCompanion(
      id: id ?? this.id,
      measuredAt: measuredAt ?? this.measuredAt,
      weightKg: weightKg ?? this.weightKg,
      note: note ?? this.note,
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
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
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
    return (StringBuffer('WeighInsCompanion(')
          ..write('id: $id, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('weightKg: $weightKg, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TargetsTable extends Targets with TableInfo<$TargetsTable, Target> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<DateTime> validFrom = GeneratedColumn<DateTime>(
    'valid_from',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalTargetMeta = const VerificationMeta(
    'kcalTarget',
  );
  @override
  late final GeneratedColumn<int> kcalTarget = GeneratedColumn<int>(
    'kcal_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinTargetMeta = const VerificationMeta(
    'proteinTarget',
  );
  @override
  late final GeneratedColumn<double> proteinTarget = GeneratedColumn<double>(
    'protein_target',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsTargetMeta = const VerificationMeta(
    'carbsTarget',
  );
  @override
  late final GeneratedColumn<double> carbsTarget = GeneratedColumn<double>(
    'carbs_target',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatTargetMeta = const VerificationMeta(
    'fatTarget',
  );
  @override
  late final GeneratedColumn<double> fatTarget = GeneratedColumn<double>(
    'fat_target',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    validFrom,
    kcalTarget,
    proteinTarget,
    carbsTarget,
    fatTarget,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'targets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Target> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    } else if (isInserting) {
      context.missing(_validFromMeta);
    }
    if (data.containsKey('kcal_target')) {
      context.handle(
        _kcalTargetMeta,
        kcalTarget.isAcceptableOrUnknown(data['kcal_target']!, _kcalTargetMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalTargetMeta);
    }
    if (data.containsKey('protein_target')) {
      context.handle(
        _proteinTargetMeta,
        proteinTarget.isAcceptableOrUnknown(
          data['protein_target']!,
          _proteinTargetMeta,
        ),
      );
    }
    if (data.containsKey('carbs_target')) {
      context.handle(
        _carbsTargetMeta,
        carbsTarget.isAcceptableOrUnknown(
          data['carbs_target']!,
          _carbsTargetMeta,
        ),
      );
    }
    if (data.containsKey('fat_target')) {
      context.handle(
        _fatTargetMeta,
        fatTarget.isAcceptableOrUnknown(data['fat_target']!, _fatTargetMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Target map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Target(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_from'],
      )!,
      kcalTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kcal_target'],
      )!,
      proteinTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_target'],
      ),
      carbsTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_target'],
      ),
      fatTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_target'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TargetsTable createAlias(String alias) {
    return $TargetsTable(attachedDatabase, alias);
  }
}

class Target extends DataClass implements Insertable<Target> {
  final String id;
  final DateTime validFrom;
  final int kcalTarget;
  final double? proteinTarget;
  final double? carbsTarget;
  final double? fatTarget;
  final String? notes;
  final DateTime createdAt;
  const Target({
    required this.id,
    required this.validFrom,
    required this.kcalTarget,
    this.proteinTarget,
    this.carbsTarget,
    this.fatTarget,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['valid_from'] = Variable<DateTime>(validFrom);
    map['kcal_target'] = Variable<int>(kcalTarget);
    if (!nullToAbsent || proteinTarget != null) {
      map['protein_target'] = Variable<double>(proteinTarget);
    }
    if (!nullToAbsent || carbsTarget != null) {
      map['carbs_target'] = Variable<double>(carbsTarget);
    }
    if (!nullToAbsent || fatTarget != null) {
      map['fat_target'] = Variable<double>(fatTarget);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TargetsCompanion toCompanion(bool nullToAbsent) {
    return TargetsCompanion(
      id: Value(id),
      validFrom: Value(validFrom),
      kcalTarget: Value(kcalTarget),
      proteinTarget: proteinTarget == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinTarget),
      carbsTarget: carbsTarget == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsTarget),
      fatTarget: fatTarget == null && nullToAbsent
          ? const Value.absent()
          : Value(fatTarget),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory Target.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Target(
      id: serializer.fromJson<String>(json['id']),
      validFrom: serializer.fromJson<DateTime>(json['validFrom']),
      kcalTarget: serializer.fromJson<int>(json['kcalTarget']),
      proteinTarget: serializer.fromJson<double?>(json['proteinTarget']),
      carbsTarget: serializer.fromJson<double?>(json['carbsTarget']),
      fatTarget: serializer.fromJson<double?>(json['fatTarget']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'validFrom': serializer.toJson<DateTime>(validFrom),
      'kcalTarget': serializer.toJson<int>(kcalTarget),
      'proteinTarget': serializer.toJson<double?>(proteinTarget),
      'carbsTarget': serializer.toJson<double?>(carbsTarget),
      'fatTarget': serializer.toJson<double?>(fatTarget),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Target copyWith({
    String? id,
    DateTime? validFrom,
    int? kcalTarget,
    Value<double?> proteinTarget = const Value.absent(),
    Value<double?> carbsTarget = const Value.absent(),
    Value<double?> fatTarget = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => Target(
    id: id ?? this.id,
    validFrom: validFrom ?? this.validFrom,
    kcalTarget: kcalTarget ?? this.kcalTarget,
    proteinTarget: proteinTarget.present
        ? proteinTarget.value
        : this.proteinTarget,
    carbsTarget: carbsTarget.present ? carbsTarget.value : this.carbsTarget,
    fatTarget: fatTarget.present ? fatTarget.value : this.fatTarget,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  Target copyWithCompanion(TargetsCompanion data) {
    return Target(
      id: data.id.present ? data.id.value : this.id,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      kcalTarget: data.kcalTarget.present
          ? data.kcalTarget.value
          : this.kcalTarget,
      proteinTarget: data.proteinTarget.present
          ? data.proteinTarget.value
          : this.proteinTarget,
      carbsTarget: data.carbsTarget.present
          ? data.carbsTarget.value
          : this.carbsTarget,
      fatTarget: data.fatTarget.present ? data.fatTarget.value : this.fatTarget,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Target(')
          ..write('id: $id, ')
          ..write('validFrom: $validFrom, ')
          ..write('kcalTarget: $kcalTarget, ')
          ..write('proteinTarget: $proteinTarget, ')
          ..write('carbsTarget: $carbsTarget, ')
          ..write('fatTarget: $fatTarget, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    validFrom,
    kcalTarget,
    proteinTarget,
    carbsTarget,
    fatTarget,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Target &&
          other.id == this.id &&
          other.validFrom == this.validFrom &&
          other.kcalTarget == this.kcalTarget &&
          other.proteinTarget == this.proteinTarget &&
          other.carbsTarget == this.carbsTarget &&
          other.fatTarget == this.fatTarget &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class TargetsCompanion extends UpdateCompanion<Target> {
  final Value<String> id;
  final Value<DateTime> validFrom;
  final Value<int> kcalTarget;
  final Value<double?> proteinTarget;
  final Value<double?> carbsTarget;
  final Value<double?> fatTarget;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TargetsCompanion({
    this.id = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.kcalTarget = const Value.absent(),
    this.proteinTarget = const Value.absent(),
    this.carbsTarget = const Value.absent(),
    this.fatTarget = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TargetsCompanion.insert({
    required String id,
    required DateTime validFrom,
    required int kcalTarget,
    this.proteinTarget = const Value.absent(),
    this.carbsTarget = const Value.absent(),
    this.fatTarget = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       validFrom = Value(validFrom),
       kcalTarget = Value(kcalTarget),
       createdAt = Value(createdAt);
  static Insertable<Target> custom({
    Expression<String>? id,
    Expression<DateTime>? validFrom,
    Expression<int>? kcalTarget,
    Expression<double>? proteinTarget,
    Expression<double>? carbsTarget,
    Expression<double>? fatTarget,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (validFrom != null) 'valid_from': validFrom,
      if (kcalTarget != null) 'kcal_target': kcalTarget,
      if (proteinTarget != null) 'protein_target': proteinTarget,
      if (carbsTarget != null) 'carbs_target': carbsTarget,
      if (fatTarget != null) 'fat_target': fatTarget,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TargetsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? validFrom,
    Value<int>? kcalTarget,
    Value<double?>? proteinTarget,
    Value<double?>? carbsTarget,
    Value<double?>? fatTarget,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TargetsCompanion(
      id: id ?? this.id,
      validFrom: validFrom ?? this.validFrom,
      kcalTarget: kcalTarget ?? this.kcalTarget,
      proteinTarget: proteinTarget ?? this.proteinTarget,
      carbsTarget: carbsTarget ?? this.carbsTarget,
      fatTarget: fatTarget ?? this.fatTarget,
      notes: notes ?? this.notes,
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
    if (validFrom.present) {
      map['valid_from'] = Variable<DateTime>(validFrom.value);
    }
    if (kcalTarget.present) {
      map['kcal_target'] = Variable<int>(kcalTarget.value);
    }
    if (proteinTarget.present) {
      map['protein_target'] = Variable<double>(proteinTarget.value);
    }
    if (carbsTarget.present) {
      map['carbs_target'] = Variable<double>(carbsTarget.value);
    }
    if (fatTarget.present) {
      map['fat_target'] = Variable<double>(fatTarget.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
    return (StringBuffer('TargetsCompanion(')
          ..write('id: $id, ')
          ..write('validFrom: $validFrom, ')
          ..write('kcalTarget: $kcalTarget, ')
          ..write('proteinTarget: $proteinTarget, ')
          ..write('carbsTarget: $carbsTarget, ')
          ..write('fatTarget: $fatTarget, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, Recipe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalKcalMeta = const VerificationMeta(
    'totalKcal',
  );
  @override
  late final GeneratedColumn<int> totalKcal = GeneratedColumn<int>(
    'total_kcal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalProteinMeta = const VerificationMeta(
    'totalProtein',
  );
  @override
  late final GeneratedColumn<double> totalProtein = GeneratedColumn<double>(
    'total_protein',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalCarbsMeta = const VerificationMeta(
    'totalCarbs',
  );
  @override
  late final GeneratedColumn<double> totalCarbs = GeneratedColumn<double>(
    'total_carbs',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalFatMeta = const VerificationMeta(
    'totalFat',
  );
  @override
  late final GeneratedColumn<double> totalFat = GeneratedColumn<double>(
    'total_fat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalGramsMeta = const VerificationMeta(
    'totalGrams',
  );
  @override
  late final GeneratedColumn<double> totalGrams = GeneratedColumn<double>(
    'total_grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _servingsMeta = const VerificationMeta(
    'servings',
  );
  @override
  late final GeneratedColumn<int> servings = GeneratedColumn<int>(
    'servings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _servingNameMeta = const VerificationMeta(
    'servingName',
  );
  @override
  late final GeneratedColumn<String> servingName = GeneratedColumn<String>(
    'serving_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userCreatedMeta = const VerificationMeta(
    'userCreated',
  );
  @override
  late final GeneratedColumn<bool> userCreated = GeneratedColumn<bool>(
    'user_created',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_created" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    totalKcal,
    totalProtein,
    totalCarbs,
    totalFat,
    totalGrams,
    servings,
    servingName,
    userCreated,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recipe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('total_kcal')) {
      context.handle(
        _totalKcalMeta,
        totalKcal.isAcceptableOrUnknown(data['total_kcal']!, _totalKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalKcalMeta);
    }
    if (data.containsKey('total_protein')) {
      context.handle(
        _totalProteinMeta,
        totalProtein.isAcceptableOrUnknown(
          data['total_protein']!,
          _totalProteinMeta,
        ),
      );
    }
    if (data.containsKey('total_carbs')) {
      context.handle(
        _totalCarbsMeta,
        totalCarbs.isAcceptableOrUnknown(data['total_carbs']!, _totalCarbsMeta),
      );
    }
    if (data.containsKey('total_fat')) {
      context.handle(
        _totalFatMeta,
        totalFat.isAcceptableOrUnknown(data['total_fat']!, _totalFatMeta),
      );
    }
    if (data.containsKey('total_grams')) {
      context.handle(
        _totalGramsMeta,
        totalGrams.isAcceptableOrUnknown(data['total_grams']!, _totalGramsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalGramsMeta);
    }
    if (data.containsKey('servings')) {
      context.handle(
        _servingsMeta,
        servings.isAcceptableOrUnknown(data['servings']!, _servingsMeta),
      );
    }
    if (data.containsKey('serving_name')) {
      context.handle(
        _servingNameMeta,
        servingName.isAcceptableOrUnknown(
          data['serving_name']!,
          _servingNameMeta,
        ),
      );
    }
    if (data.containsKey('user_created')) {
      context.handle(
        _userCreatedMeta,
        userCreated.isAcceptableOrUnknown(
          data['user_created']!,
          _userCreatedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recipe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recipe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      totalKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_kcal'],
      )!,
      totalProtein: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_protein'],
      ),
      totalCarbs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_carbs'],
      ),
      totalFat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_fat'],
      ),
      totalGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_grams'],
      )!,
      servings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}servings'],
      )!,
      servingName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serving_name'],
      ),
      userCreated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_created'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }
}

class Recipe extends DataClass implements Insertable<Recipe> {
  final String id;
  final String name;
  final String? description;
  final int totalKcal;
  final double? totalProtein;
  final double? totalCarbs;
  final double? totalFat;
  final double totalGrams;
  final int servings;
  final String? servingName;
  final bool userCreated;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Recipe({
    required this.id,
    required this.name,
    this.description,
    required this.totalKcal,
    this.totalProtein,
    this.totalCarbs,
    this.totalFat,
    required this.totalGrams,
    required this.servings,
    this.servingName,
    required this.userCreated,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['total_kcal'] = Variable<int>(totalKcal);
    if (!nullToAbsent || totalProtein != null) {
      map['total_protein'] = Variable<double>(totalProtein);
    }
    if (!nullToAbsent || totalCarbs != null) {
      map['total_carbs'] = Variable<double>(totalCarbs);
    }
    if (!nullToAbsent || totalFat != null) {
      map['total_fat'] = Variable<double>(totalFat);
    }
    map['total_grams'] = Variable<double>(totalGrams);
    map['servings'] = Variable<int>(servings);
    if (!nullToAbsent || servingName != null) {
      map['serving_name'] = Variable<String>(servingName);
    }
    map['user_created'] = Variable<bool>(userCreated);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      totalKcal: Value(totalKcal),
      totalProtein: totalProtein == null && nullToAbsent
          ? const Value.absent()
          : Value(totalProtein),
      totalCarbs: totalCarbs == null && nullToAbsent
          ? const Value.absent()
          : Value(totalCarbs),
      totalFat: totalFat == null && nullToAbsent
          ? const Value.absent()
          : Value(totalFat),
      totalGrams: Value(totalGrams),
      servings: Value(servings),
      servingName: servingName == null && nullToAbsent
          ? const Value.absent()
          : Value(servingName),
      userCreated: Value(userCreated),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Recipe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recipe(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      totalKcal: serializer.fromJson<int>(json['totalKcal']),
      totalProtein: serializer.fromJson<double?>(json['totalProtein']),
      totalCarbs: serializer.fromJson<double?>(json['totalCarbs']),
      totalFat: serializer.fromJson<double?>(json['totalFat']),
      totalGrams: serializer.fromJson<double>(json['totalGrams']),
      servings: serializer.fromJson<int>(json['servings']),
      servingName: serializer.fromJson<String?>(json['servingName']),
      userCreated: serializer.fromJson<bool>(json['userCreated']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'totalKcal': serializer.toJson<int>(totalKcal),
      'totalProtein': serializer.toJson<double?>(totalProtein),
      'totalCarbs': serializer.toJson<double?>(totalCarbs),
      'totalFat': serializer.toJson<double?>(totalFat),
      'totalGrams': serializer.toJson<double>(totalGrams),
      'servings': serializer.toJson<int>(servings),
      'servingName': serializer.toJson<String?>(servingName),
      'userCreated': serializer.toJson<bool>(userCreated),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Recipe copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    int? totalKcal,
    Value<double?> totalProtein = const Value.absent(),
    Value<double?> totalCarbs = const Value.absent(),
    Value<double?> totalFat = const Value.absent(),
    double? totalGrams,
    int? servings,
    Value<String?> servingName = const Value.absent(),
    bool? userCreated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Recipe(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    totalKcal: totalKcal ?? this.totalKcal,
    totalProtein: totalProtein.present ? totalProtein.value : this.totalProtein,
    totalCarbs: totalCarbs.present ? totalCarbs.value : this.totalCarbs,
    totalFat: totalFat.present ? totalFat.value : this.totalFat,
    totalGrams: totalGrams ?? this.totalGrams,
    servings: servings ?? this.servings,
    servingName: servingName.present ? servingName.value : this.servingName,
    userCreated: userCreated ?? this.userCreated,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Recipe copyWithCompanion(RecipesCompanion data) {
    return Recipe(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      totalKcal: data.totalKcal.present ? data.totalKcal.value : this.totalKcal,
      totalProtein: data.totalProtein.present
          ? data.totalProtein.value
          : this.totalProtein,
      totalCarbs: data.totalCarbs.present
          ? data.totalCarbs.value
          : this.totalCarbs,
      totalFat: data.totalFat.present ? data.totalFat.value : this.totalFat,
      totalGrams: data.totalGrams.present
          ? data.totalGrams.value
          : this.totalGrams,
      servings: data.servings.present ? data.servings.value : this.servings,
      servingName: data.servingName.present
          ? data.servingName.value
          : this.servingName,
      userCreated: data.userCreated.present
          ? data.userCreated.value
          : this.userCreated,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recipe(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('totalKcal: $totalKcal, ')
          ..write('totalProtein: $totalProtein, ')
          ..write('totalCarbs: $totalCarbs, ')
          ..write('totalFat: $totalFat, ')
          ..write('totalGrams: $totalGrams, ')
          ..write('servings: $servings, ')
          ..write('servingName: $servingName, ')
          ..write('userCreated: $userCreated, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    totalKcal,
    totalProtein,
    totalCarbs,
    totalFat,
    totalGrams,
    servings,
    servingName,
    userCreated,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recipe &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.totalKcal == this.totalKcal &&
          other.totalProtein == this.totalProtein &&
          other.totalCarbs == this.totalCarbs &&
          other.totalFat == this.totalFat &&
          other.totalGrams == this.totalGrams &&
          other.servings == this.servings &&
          other.servingName == this.servingName &&
          other.userCreated == this.userCreated &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecipesCompanion extends UpdateCompanion<Recipe> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> totalKcal;
  final Value<double?> totalProtein;
  final Value<double?> totalCarbs;
  final Value<double?> totalFat;
  final Value<double> totalGrams;
  final Value<int> servings;
  final Value<String?> servingName;
  final Value<bool> userCreated;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.totalKcal = const Value.absent(),
    this.totalProtein = const Value.absent(),
    this.totalCarbs = const Value.absent(),
    this.totalFat = const Value.absent(),
    this.totalGrams = const Value.absent(),
    this.servings = const Value.absent(),
    this.servingName = const Value.absent(),
    this.userCreated = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required int totalKcal,
    this.totalProtein = const Value.absent(),
    this.totalCarbs = const Value.absent(),
    this.totalFat = const Value.absent(),
    required double totalGrams,
    this.servings = const Value.absent(),
    this.servingName = const Value.absent(),
    this.userCreated = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       totalKcal = Value(totalKcal),
       totalGrams = Value(totalGrams),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Recipe> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? totalKcal,
    Expression<double>? totalProtein,
    Expression<double>? totalCarbs,
    Expression<double>? totalFat,
    Expression<double>? totalGrams,
    Expression<int>? servings,
    Expression<String>? servingName,
    Expression<bool>? userCreated,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (totalKcal != null) 'total_kcal': totalKcal,
      if (totalProtein != null) 'total_protein': totalProtein,
      if (totalCarbs != null) 'total_carbs': totalCarbs,
      if (totalFat != null) 'total_fat': totalFat,
      if (totalGrams != null) 'total_grams': totalGrams,
      if (servings != null) 'servings': servings,
      if (servingName != null) 'serving_name': servingName,
      if (userCreated != null) 'user_created': userCreated,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? totalKcal,
    Value<double?>? totalProtein,
    Value<double?>? totalCarbs,
    Value<double?>? totalFat,
    Value<double>? totalGrams,
    Value<int>? servings,
    Value<String?>? servingName,
    Value<bool>? userCreated,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RecipesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalKcal: totalKcal ?? this.totalKcal,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      totalGrams: totalGrams ?? this.totalGrams,
      servings: servings ?? this.servings,
      servingName: servingName ?? this.servingName,
      userCreated: userCreated ?? this.userCreated,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (totalKcal.present) {
      map['total_kcal'] = Variable<int>(totalKcal.value);
    }
    if (totalProtein.present) {
      map['total_protein'] = Variable<double>(totalProtein.value);
    }
    if (totalCarbs.present) {
      map['total_carbs'] = Variable<double>(totalCarbs.value);
    }
    if (totalFat.present) {
      map['total_fat'] = Variable<double>(totalFat.value);
    }
    if (totalGrams.present) {
      map['total_grams'] = Variable<double>(totalGrams.value);
    }
    if (servings.present) {
      map['servings'] = Variable<int>(servings.value);
    }
    if (servingName.present) {
      map['serving_name'] = Variable<String>(servingName.value);
    }
    if (userCreated.present) {
      map['user_created'] = Variable<bool>(userCreated.value);
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
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('totalKcal: $totalKcal, ')
          ..write('totalProtein: $totalProtein, ')
          ..write('totalCarbs: $totalCarbs, ')
          ..write('totalFat: $totalFat, ')
          ..write('totalGrams: $totalGrams, ')
          ..write('servings: $servings, ')
          ..write('servingName: $servingName, ')
          ..write('userCreated: $userCreated, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeItemsTable extends RecipeItems
    with TableInfo<$RecipeItemsTable, RecipeItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES foods (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ServingUnit, String> unit =
      GeneratedColumn<String>(
        'unit',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ServingUnit>($RecipeItemsTable.$converterunit);
  static const VerificationMeta _foodNameSnapshotMeta = const VerificationMeta(
    'foodNameSnapshot',
  );
  @override
  late final GeneratedColumn<String> foodNameSnapshot = GeneratedColumn<String>(
    'food_name_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalPer100gSnapshotMeta =
      const VerificationMeta('kcalPer100gSnapshot');
  @override
  late final GeneratedColumn<int> kcalPer100gSnapshot = GeneratedColumn<int>(
    'kcal_per100g_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinPer100gSnapshotMeta =
      const VerificationMeta('proteinPer100gSnapshot');
  @override
  late final GeneratedColumn<double> proteinPer100gSnapshot =
      GeneratedColumn<double>(
        'protein_per100g_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _carbsPer100gSnapshotMeta =
      const VerificationMeta('carbsPer100gSnapshot');
  @override
  late final GeneratedColumn<double> carbsPer100gSnapshot =
      GeneratedColumn<double>(
        'carbs_per100g_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fatPer100gSnapshotMeta =
      const VerificationMeta('fatPer100gSnapshot');
  @override
  late final GeneratedColumn<double> fatPer100gSnapshot =
      GeneratedColumn<double>(
        'fat_per100g_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recipeId,
    foodId,
    amount,
    unit,
    foodNameSnapshot,
    kcalPer100gSnapshot,
    proteinPer100gSnapshot,
    carbsPer100gSnapshot,
    fatPer100gSnapshot,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('food_name_snapshot')) {
      context.handle(
        _foodNameSnapshotMeta,
        foodNameSnapshot.isAcceptableOrUnknown(
          data['food_name_snapshot']!,
          _foodNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_foodNameSnapshotMeta);
    }
    if (data.containsKey('kcal_per100g_snapshot')) {
      context.handle(
        _kcalPer100gSnapshotMeta,
        kcalPer100gSnapshot.isAcceptableOrUnknown(
          data['kcal_per100g_snapshot']!,
          _kcalPer100gSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kcalPer100gSnapshotMeta);
    }
    if (data.containsKey('protein_per100g_snapshot')) {
      context.handle(
        _proteinPer100gSnapshotMeta,
        proteinPer100gSnapshot.isAcceptableOrUnknown(
          data['protein_per100g_snapshot']!,
          _proteinPer100gSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('carbs_per100g_snapshot')) {
      context.handle(
        _carbsPer100gSnapshotMeta,
        carbsPer100gSnapshot.isAcceptableOrUnknown(
          data['carbs_per100g_snapshot']!,
          _carbsPer100gSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('fat_per100g_snapshot')) {
      context.handle(
        _fatPer100gSnapshotMeta,
        fatPer100gSnapshot.isAcceptableOrUnknown(
          data['fat_per100g_snapshot']!,
          _fatPer100gSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      unit: $RecipeItemsTable.$converterunit.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unit'],
        )!,
      ),
      foodNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_name_snapshot'],
      )!,
      kcalPer100gSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kcal_per100g_snapshot'],
      )!,
      proteinPer100gSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_per100g_snapshot'],
      ),
      carbsPer100gSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_per100g_snapshot'],
      ),
      fatPer100gSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_per100g_snapshot'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $RecipeItemsTable createAlias(String alias) {
    return $RecipeItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<ServingUnit, String> $converterunit =
      const ServingUnitConverter();
}

class RecipeItem extends DataClass implements Insertable<RecipeItem> {
  final String id;
  final String recipeId;
  final String foodId;
  final double amount;
  final ServingUnit unit;
  final String foodNameSnapshot;
  final int kcalPer100gSnapshot;
  final double? proteinPer100gSnapshot;
  final double? carbsPer100gSnapshot;
  final double? fatPer100gSnapshot;
  final int sortOrder;
  const RecipeItem({
    required this.id,
    required this.recipeId,
    required this.foodId,
    required this.amount,
    required this.unit,
    required this.foodNameSnapshot,
    required this.kcalPer100gSnapshot,
    this.proteinPer100gSnapshot,
    this.carbsPer100gSnapshot,
    this.fatPer100gSnapshot,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    map['food_id'] = Variable<String>(foodId);
    map['amount'] = Variable<double>(amount);
    {
      map['unit'] = Variable<String>(
        $RecipeItemsTable.$converterunit.toSql(unit),
      );
    }
    map['food_name_snapshot'] = Variable<String>(foodNameSnapshot);
    map['kcal_per100g_snapshot'] = Variable<int>(kcalPer100gSnapshot);
    if (!nullToAbsent || proteinPer100gSnapshot != null) {
      map['protein_per100g_snapshot'] = Variable<double>(
        proteinPer100gSnapshot,
      );
    }
    if (!nullToAbsent || carbsPer100gSnapshot != null) {
      map['carbs_per100g_snapshot'] = Variable<double>(carbsPer100gSnapshot);
    }
    if (!nullToAbsent || fatPer100gSnapshot != null) {
      map['fat_per100g_snapshot'] = Variable<double>(fatPer100gSnapshot);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  RecipeItemsCompanion toCompanion(bool nullToAbsent) {
    return RecipeItemsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      foodId: Value(foodId),
      amount: Value(amount),
      unit: Value(unit),
      foodNameSnapshot: Value(foodNameSnapshot),
      kcalPer100gSnapshot: Value(kcalPer100gSnapshot),
      proteinPer100gSnapshot: proteinPer100gSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinPer100gSnapshot),
      carbsPer100gSnapshot: carbsPer100gSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsPer100gSnapshot),
      fatPer100gSnapshot: fatPer100gSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(fatPer100gSnapshot),
      sortOrder: Value(sortOrder),
    );
  }

  factory RecipeItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeItem(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      foodId: serializer.fromJson<String>(json['foodId']),
      amount: serializer.fromJson<double>(json['amount']),
      unit: serializer.fromJson<ServingUnit>(json['unit']),
      foodNameSnapshot: serializer.fromJson<String>(json['foodNameSnapshot']),
      kcalPer100gSnapshot: serializer.fromJson<int>(
        json['kcalPer100gSnapshot'],
      ),
      proteinPer100gSnapshot: serializer.fromJson<double?>(
        json['proteinPer100gSnapshot'],
      ),
      carbsPer100gSnapshot: serializer.fromJson<double?>(
        json['carbsPer100gSnapshot'],
      ),
      fatPer100gSnapshot: serializer.fromJson<double?>(
        json['fatPer100gSnapshot'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'foodId': serializer.toJson<String>(foodId),
      'amount': serializer.toJson<double>(amount),
      'unit': serializer.toJson<ServingUnit>(unit),
      'foodNameSnapshot': serializer.toJson<String>(foodNameSnapshot),
      'kcalPer100gSnapshot': serializer.toJson<int>(kcalPer100gSnapshot),
      'proteinPer100gSnapshot': serializer.toJson<double?>(
        proteinPer100gSnapshot,
      ),
      'carbsPer100gSnapshot': serializer.toJson<double?>(carbsPer100gSnapshot),
      'fatPer100gSnapshot': serializer.toJson<double?>(fatPer100gSnapshot),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  RecipeItem copyWith({
    String? id,
    String? recipeId,
    String? foodId,
    double? amount,
    ServingUnit? unit,
    String? foodNameSnapshot,
    int? kcalPer100gSnapshot,
    Value<double?> proteinPer100gSnapshot = const Value.absent(),
    Value<double?> carbsPer100gSnapshot = const Value.absent(),
    Value<double?> fatPer100gSnapshot = const Value.absent(),
    int? sortOrder,
  }) => RecipeItem(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    foodId: foodId ?? this.foodId,
    amount: amount ?? this.amount,
    unit: unit ?? this.unit,
    foodNameSnapshot: foodNameSnapshot ?? this.foodNameSnapshot,
    kcalPer100gSnapshot: kcalPer100gSnapshot ?? this.kcalPer100gSnapshot,
    proteinPer100gSnapshot: proteinPer100gSnapshot.present
        ? proteinPer100gSnapshot.value
        : this.proteinPer100gSnapshot,
    carbsPer100gSnapshot: carbsPer100gSnapshot.present
        ? carbsPer100gSnapshot.value
        : this.carbsPer100gSnapshot,
    fatPer100gSnapshot: fatPer100gSnapshot.present
        ? fatPer100gSnapshot.value
        : this.fatPer100gSnapshot,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  RecipeItem copyWithCompanion(RecipeItemsCompanion data) {
    return RecipeItem(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      foodNameSnapshot: data.foodNameSnapshot.present
          ? data.foodNameSnapshot.value
          : this.foodNameSnapshot,
      kcalPer100gSnapshot: data.kcalPer100gSnapshot.present
          ? data.kcalPer100gSnapshot.value
          : this.kcalPer100gSnapshot,
      proteinPer100gSnapshot: data.proteinPer100gSnapshot.present
          ? data.proteinPer100gSnapshot.value
          : this.proteinPer100gSnapshot,
      carbsPer100gSnapshot: data.carbsPer100gSnapshot.present
          ? data.carbsPer100gSnapshot.value
          : this.carbsPer100gSnapshot,
      fatPer100gSnapshot: data.fatPer100gSnapshot.present
          ? data.fatPer100gSnapshot.value
          : this.fatPer100gSnapshot,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeItem(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('foodId: $foodId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('foodNameSnapshot: $foodNameSnapshot, ')
          ..write('kcalPer100gSnapshot: $kcalPer100gSnapshot, ')
          ..write('proteinPer100gSnapshot: $proteinPer100gSnapshot, ')
          ..write('carbsPer100gSnapshot: $carbsPer100gSnapshot, ')
          ..write('fatPer100gSnapshot: $fatPer100gSnapshot, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recipeId,
    foodId,
    amount,
    unit,
    foodNameSnapshot,
    kcalPer100gSnapshot,
    proteinPer100gSnapshot,
    carbsPer100gSnapshot,
    fatPer100gSnapshot,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeItem &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.foodId == this.foodId &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.foodNameSnapshot == this.foodNameSnapshot &&
          other.kcalPer100gSnapshot == this.kcalPer100gSnapshot &&
          other.proteinPer100gSnapshot == this.proteinPer100gSnapshot &&
          other.carbsPer100gSnapshot == this.carbsPer100gSnapshot &&
          other.fatPer100gSnapshot == this.fatPer100gSnapshot &&
          other.sortOrder == this.sortOrder);
}

class RecipeItemsCompanion extends UpdateCompanion<RecipeItem> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<String> foodId;
  final Value<double> amount;
  final Value<ServingUnit> unit;
  final Value<String> foodNameSnapshot;
  final Value<int> kcalPer100gSnapshot;
  final Value<double?> proteinPer100gSnapshot;
  final Value<double?> carbsPer100gSnapshot;
  final Value<double?> fatPer100gSnapshot;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const RecipeItemsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.foodId = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.foodNameSnapshot = const Value.absent(),
    this.kcalPer100gSnapshot = const Value.absent(),
    this.proteinPer100gSnapshot = const Value.absent(),
    this.carbsPer100gSnapshot = const Value.absent(),
    this.fatPer100gSnapshot = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeItemsCompanion.insert({
    required String id,
    required String recipeId,
    required String foodId,
    required double amount,
    required ServingUnit unit,
    required String foodNameSnapshot,
    required int kcalPer100gSnapshot,
    this.proteinPer100gSnapshot = const Value.absent(),
    this.carbsPer100gSnapshot = const Value.absent(),
    this.fatPer100gSnapshot = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recipeId = Value(recipeId),
       foodId = Value(foodId),
       amount = Value(amount),
       unit = Value(unit),
       foodNameSnapshot = Value(foodNameSnapshot),
       kcalPer100gSnapshot = Value(kcalPer100gSnapshot);
  static Insertable<RecipeItem> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<String>? foodId,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<String>? foodNameSnapshot,
    Expression<int>? kcalPer100gSnapshot,
    Expression<double>? proteinPer100gSnapshot,
    Expression<double>? carbsPer100gSnapshot,
    Expression<double>? fatPer100gSnapshot,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (foodId != null) 'food_id': foodId,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (foodNameSnapshot != null) 'food_name_snapshot': foodNameSnapshot,
      if (kcalPer100gSnapshot != null)
        'kcal_per100g_snapshot': kcalPer100gSnapshot,
      if (proteinPer100gSnapshot != null)
        'protein_per100g_snapshot': proteinPer100gSnapshot,
      if (carbsPer100gSnapshot != null)
        'carbs_per100g_snapshot': carbsPer100gSnapshot,
      if (fatPer100gSnapshot != null)
        'fat_per100g_snapshot': fatPer100gSnapshot,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? recipeId,
    Value<String>? foodId,
    Value<double>? amount,
    Value<ServingUnit>? unit,
    Value<String>? foodNameSnapshot,
    Value<int>? kcalPer100gSnapshot,
    Value<double?>? proteinPer100gSnapshot,
    Value<double?>? carbsPer100gSnapshot,
    Value<double?>? fatPer100gSnapshot,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return RecipeItemsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      foodId: foodId ?? this.foodId,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      foodNameSnapshot: foodNameSnapshot ?? this.foodNameSnapshot,
      kcalPer100gSnapshot: kcalPer100gSnapshot ?? this.kcalPer100gSnapshot,
      proteinPer100gSnapshot:
          proteinPer100gSnapshot ?? this.proteinPer100gSnapshot,
      carbsPer100gSnapshot: carbsPer100gSnapshot ?? this.carbsPer100gSnapshot,
      fatPer100gSnapshot: fatPer100gSnapshot ?? this.fatPer100gSnapshot,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(
        $RecipeItemsTable.$converterunit.toSql(unit.value),
      );
    }
    if (foodNameSnapshot.present) {
      map['food_name_snapshot'] = Variable<String>(foodNameSnapshot.value);
    }
    if (kcalPer100gSnapshot.present) {
      map['kcal_per100g_snapshot'] = Variable<int>(kcalPer100gSnapshot.value);
    }
    if (proteinPer100gSnapshot.present) {
      map['protein_per100g_snapshot'] = Variable<double>(
        proteinPer100gSnapshot.value,
      );
    }
    if (carbsPer100gSnapshot.present) {
      map['carbs_per100g_snapshot'] = Variable<double>(
        carbsPer100gSnapshot.value,
      );
    }
    if (fatPer100gSnapshot.present) {
      map['fat_per100g_snapshot'] = Variable<double>(fatPer100gSnapshot.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeItemsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('foodId: $foodId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('foodNameSnapshot: $foodNameSnapshot, ')
          ..write('kcalPer100gSnapshot: $kcalPer100gSnapshot, ')
          ..write('proteinPer100gSnapshot: $proteinPer100gSnapshot, ')
          ..write('carbsPer100gSnapshot: $carbsPer100gSnapshot, ')
          ..write('fatPer100gSnapshot: $fatPer100gSnapshot, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoodsFtsTable extends FoodsFts with TableInfo<$FoodsFtsTable, FoodsFt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodsFtsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [name, brand];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foods_fts';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodsFt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  FoodsFt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodsFt(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
    );
  }

  @override
  $FoodsFtsTable createAlias(String alias) {
    return $FoodsFtsTable(attachedDatabase, alias);
  }
}

class FoodsFt extends DataClass implements Insertable<FoodsFt> {
  final String name;
  final String? brand;
  const FoodsFt({required this.name, this.brand});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    return map;
  }

  FoodsFtsCompanion toCompanion(bool nullToAbsent) {
    return FoodsFtsCompanion(
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
    );
  }

  factory FoodsFt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodsFt(
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
    };
  }

  FoodsFt copyWith({
    String? name,
    Value<String?> brand = const Value.absent(),
  }) => FoodsFt(
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
  );
  FoodsFt copyWithCompanion(FoodsFtsCompanion data) {
    return FoodsFt(
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodsFt(')
          ..write('name: $name, ')
          ..write('brand: $brand')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, brand);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodsFt &&
          other.name == this.name &&
          other.brand == this.brand);
}

class FoodsFtsCompanion extends UpdateCompanion<FoodsFt> {
  final Value<String> name;
  final Value<String?> brand;
  final Value<int> rowid;
  const FoodsFtsCompanion({
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodsFtsCompanion.insert({
    required String name,
    this.brand = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<FoodsFt> custom({
    Expression<String>? name,
    Expression<String>? brand,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodsFtsCompanion copyWith({
    Value<String>? name,
    Value<String?>? brand,
    Value<int>? rowid,
  }) {
    return FoodsFtsCompanion(
      name: name ?? this.name,
      brand: brand ?? this.brand,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodsFtsCompanion(')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoryTable extends SearchHistory
    with TableInfo<$SearchHistoryTable, SearchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedQueryMeta = const VerificationMeta(
    'normalizedQuery',
  );
  @override
  late final GeneratedColumn<String> normalizedQuery = GeneratedColumn<String>(
    'normalized_query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedFoodIdMeta = const VerificationMeta(
    'selectedFoodId',
  );
  @override
  late final GeneratedColumn<String> selectedFoodId = GeneratedColumn<String>(
    'selected_food_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchedAtMeta = const VerificationMeta(
    'searchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> searchedAt = GeneratedColumn<DateTime>(
    'searched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _hasResultsMeta = const VerificationMeta(
    'hasResults',
  );
  @override
  late final GeneratedColumn<bool> hasResults = GeneratedColumn<bool>(
    'has_results',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_results" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    query,
    normalizedQuery,
    selectedFoodId,
    searchedAt,
    hasResults,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('normalized_query')) {
      context.handle(
        _normalizedQueryMeta,
        normalizedQuery.isAcceptableOrUnknown(
          data['normalized_query']!,
          _normalizedQueryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedQueryMeta);
    }
    if (data.containsKey('selected_food_id')) {
      context.handle(
        _selectedFoodIdMeta,
        selectedFoodId.isAcceptableOrUnknown(
          data['selected_food_id']!,
          _selectedFoodIdMeta,
        ),
      );
    }
    if (data.containsKey('searched_at')) {
      context.handle(
        _searchedAtMeta,
        searchedAt.isAcceptableOrUnknown(data['searched_at']!, _searchedAtMeta),
      );
    }
    if (data.containsKey('has_results')) {
      context.handle(
        _hasResultsMeta,
        hasResults.isAcceptableOrUnknown(data['has_results']!, _hasResultsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SearchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      normalizedQuery: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_query'],
      )!,
      selectedFoodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_food_id'],
      ),
      searchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}searched_at'],
      )!,
      hasResults: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_results'],
      )!,
    );
  }

  @override
  $SearchHistoryTable createAlias(String alias) {
    return $SearchHistoryTable(attachedDatabase, alias);
  }
}

class SearchHistoryData extends DataClass
    implements Insertable<SearchHistoryData> {
  final int id;
  final String query;
  final String normalizedQuery;
  final String? selectedFoodId;
  final DateTime searchedAt;
  final bool hasResults;
  const SearchHistoryData({
    required this.id,
    required this.query,
    required this.normalizedQuery,
    this.selectedFoodId,
    required this.searchedAt,
    required this.hasResults,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['query'] = Variable<String>(query);
    map['normalized_query'] = Variable<String>(normalizedQuery);
    if (!nullToAbsent || selectedFoodId != null) {
      map['selected_food_id'] = Variable<String>(selectedFoodId);
    }
    map['searched_at'] = Variable<DateTime>(searchedAt);
    map['has_results'] = Variable<bool>(hasResults);
    return map;
  }

  SearchHistoryCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryCompanion(
      id: Value(id),
      query: Value(query),
      normalizedQuery: Value(normalizedQuery),
      selectedFoodId: selectedFoodId == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedFoodId),
      searchedAt: Value(searchedAt),
      hasResults: Value(hasResults),
    );
  }

  factory SearchHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryData(
      id: serializer.fromJson<int>(json['id']),
      query: serializer.fromJson<String>(json['query']),
      normalizedQuery: serializer.fromJson<String>(json['normalizedQuery']),
      selectedFoodId: serializer.fromJson<String?>(json['selectedFoodId']),
      searchedAt: serializer.fromJson<DateTime>(json['searchedAt']),
      hasResults: serializer.fromJson<bool>(json['hasResults']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'query': serializer.toJson<String>(query),
      'normalizedQuery': serializer.toJson<String>(normalizedQuery),
      'selectedFoodId': serializer.toJson<String?>(selectedFoodId),
      'searchedAt': serializer.toJson<DateTime>(searchedAt),
      'hasResults': serializer.toJson<bool>(hasResults),
    };
  }

  SearchHistoryData copyWith({
    int? id,
    String? query,
    String? normalizedQuery,
    Value<String?> selectedFoodId = const Value.absent(),
    DateTime? searchedAt,
    bool? hasResults,
  }) => SearchHistoryData(
    id: id ?? this.id,
    query: query ?? this.query,
    normalizedQuery: normalizedQuery ?? this.normalizedQuery,
    selectedFoodId: selectedFoodId.present
        ? selectedFoodId.value
        : this.selectedFoodId,
    searchedAt: searchedAt ?? this.searchedAt,
    hasResults: hasResults ?? this.hasResults,
  );
  SearchHistoryData copyWithCompanion(SearchHistoryCompanion data) {
    return SearchHistoryData(
      id: data.id.present ? data.id.value : this.id,
      query: data.query.present ? data.query.value : this.query,
      normalizedQuery: data.normalizedQuery.present
          ? data.normalizedQuery.value
          : this.normalizedQuery,
      selectedFoodId: data.selectedFoodId.present
          ? data.selectedFoodId.value
          : this.selectedFoodId,
      searchedAt: data.searchedAt.present
          ? data.searchedAt.value
          : this.searchedAt,
      hasResults: data.hasResults.present
          ? data.hasResults.value
          : this.hasResults,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryData(')
          ..write('id: $id, ')
          ..write('query: $query, ')
          ..write('normalizedQuery: $normalizedQuery, ')
          ..write('selectedFoodId: $selectedFoodId, ')
          ..write('searchedAt: $searchedAt, ')
          ..write('hasResults: $hasResults')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    query,
    normalizedQuery,
    selectedFoodId,
    searchedAt,
    hasResults,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryData &&
          other.id == this.id &&
          other.query == this.query &&
          other.normalizedQuery == this.normalizedQuery &&
          other.selectedFoodId == this.selectedFoodId &&
          other.searchedAt == this.searchedAt &&
          other.hasResults == this.hasResults);
}

class SearchHistoryCompanion extends UpdateCompanion<SearchHistoryData> {
  final Value<int> id;
  final Value<String> query;
  final Value<String> normalizedQuery;
  final Value<String?> selectedFoodId;
  final Value<DateTime> searchedAt;
  final Value<bool> hasResults;
  const SearchHistoryCompanion({
    this.id = const Value.absent(),
    this.query = const Value.absent(),
    this.normalizedQuery = const Value.absent(),
    this.selectedFoodId = const Value.absent(),
    this.searchedAt = const Value.absent(),
    this.hasResults = const Value.absent(),
  });
  SearchHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String query,
    required String normalizedQuery,
    this.selectedFoodId = const Value.absent(),
    this.searchedAt = const Value.absent(),
    this.hasResults = const Value.absent(),
  }) : query = Value(query),
       normalizedQuery = Value(normalizedQuery);
  static Insertable<SearchHistoryData> custom({
    Expression<int>? id,
    Expression<String>? query,
    Expression<String>? normalizedQuery,
    Expression<String>? selectedFoodId,
    Expression<DateTime>? searchedAt,
    Expression<bool>? hasResults,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (query != null) 'query': query,
      if (normalizedQuery != null) 'normalized_query': normalizedQuery,
      if (selectedFoodId != null) 'selected_food_id': selectedFoodId,
      if (searchedAt != null) 'searched_at': searchedAt,
      if (hasResults != null) 'has_results': hasResults,
    });
  }

  SearchHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? query,
    Value<String>? normalizedQuery,
    Value<String?>? selectedFoodId,
    Value<DateTime>? searchedAt,
    Value<bool>? hasResults,
  }) {
    return SearchHistoryCompanion(
      id: id ?? this.id,
      query: query ?? this.query,
      normalizedQuery: normalizedQuery ?? this.normalizedQuery,
      selectedFoodId: selectedFoodId ?? this.selectedFoodId,
      searchedAt: searchedAt ?? this.searchedAt,
      hasResults: hasResults ?? this.hasResults,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (normalizedQuery.present) {
      map['normalized_query'] = Variable<String>(normalizedQuery.value);
    }
    if (selectedFoodId.present) {
      map['selected_food_id'] = Variable<String>(selectedFoodId.value);
    }
    if (searchedAt.present) {
      map['searched_at'] = Variable<DateTime>(searchedAt.value);
    }
    if (hasResults.present) {
      map['has_results'] = Variable<bool>(hasResults.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryCompanion(')
          ..write('id: $id, ')
          ..write('query: $query, ')
          ..write('normalizedQuery: $normalizedQuery, ')
          ..write('selectedFoodId: $selectedFoodId, ')
          ..write('searchedAt: $searchedAt, ')
          ..write('hasResults: $hasResults')
          ..write(')'))
        .toString();
  }
}

class $ConsumptionPatternsTable extends ConsumptionPatterns
    with TableInfo<$ConsumptionPatternsTable, ConsumptionPattern> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsumptionPatternsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES foods (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _hourOfDayMeta = const VerificationMeta(
    'hourOfDay',
  );
  @override
  late final GeneratedColumn<int> hourOfDay = GeneratedColumn<int>(
    'hour_of_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MealType?, String> mealType =
      GeneratedColumn<String>(
        'meal_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<MealType?>($ConsumptionPatternsTable.$convertermealTypen);
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<int> frequency = GeneratedColumn<int>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastConsumedAtMeta = const VerificationMeta(
    'lastConsumedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastConsumedAt =
      GeneratedColumn<DateTime>(
        'last_consumed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    foodId,
    hourOfDay,
    dayOfWeek,
    mealType,
    frequency,
    lastConsumedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consumption_patterns';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConsumptionPattern> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('hour_of_day')) {
      context.handle(
        _hourOfDayMeta,
        hourOfDay.isAcceptableOrUnknown(data['hour_of_day']!, _hourOfDayMeta),
      );
    } else if (isInserting) {
      context.missing(_hourOfDayMeta);
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('last_consumed_at')) {
      context.handle(
        _lastConsumedAtMeta,
        lastConsumedAt.isAcceptableOrUnknown(
          data['last_consumed_at']!,
          _lastConsumedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastConsumedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConsumptionPattern map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConsumptionPattern(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      )!,
      hourOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour_of_day'],
      )!,
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      )!,
      mealType: $ConsumptionPatternsTable.$convertermealTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meal_type'],
        ),
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}frequency'],
      )!,
      lastConsumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_consumed_at'],
      )!,
    );
  }

  @override
  $ConsumptionPatternsTable createAlias(String alias) {
    return $ConsumptionPatternsTable(attachedDatabase, alias);
  }

  static TypeConverter<MealType, String> $convertermealType =
      const MealTypeConverter();
  static TypeConverter<MealType?, String?> $convertermealTypen =
      NullAwareTypeConverter.wrap($convertermealType);
}

class ConsumptionPattern extends DataClass
    implements Insertable<ConsumptionPattern> {
  final int id;
  final String foodId;
  final int hourOfDay;
  final int dayOfWeek;
  final MealType? mealType;
  final int frequency;
  final DateTime lastConsumedAt;
  const ConsumptionPattern({
    required this.id,
    required this.foodId,
    required this.hourOfDay,
    required this.dayOfWeek,
    this.mealType,
    required this.frequency,
    required this.lastConsumedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['food_id'] = Variable<String>(foodId);
    map['hour_of_day'] = Variable<int>(hourOfDay);
    map['day_of_week'] = Variable<int>(dayOfWeek);
    if (!nullToAbsent || mealType != null) {
      map['meal_type'] = Variable<String>(
        $ConsumptionPatternsTable.$convertermealTypen.toSql(mealType),
      );
    }
    map['frequency'] = Variable<int>(frequency);
    map['last_consumed_at'] = Variable<DateTime>(lastConsumedAt);
    return map;
  }

  ConsumptionPatternsCompanion toCompanion(bool nullToAbsent) {
    return ConsumptionPatternsCompanion(
      id: Value(id),
      foodId: Value(foodId),
      hourOfDay: Value(hourOfDay),
      dayOfWeek: Value(dayOfWeek),
      mealType: mealType == null && nullToAbsent
          ? const Value.absent()
          : Value(mealType),
      frequency: Value(frequency),
      lastConsumedAt: Value(lastConsumedAt),
    );
  }

  factory ConsumptionPattern.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConsumptionPattern(
      id: serializer.fromJson<int>(json['id']),
      foodId: serializer.fromJson<String>(json['foodId']),
      hourOfDay: serializer.fromJson<int>(json['hourOfDay']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      mealType: serializer.fromJson<MealType?>(json['mealType']),
      frequency: serializer.fromJson<int>(json['frequency']),
      lastConsumedAt: serializer.fromJson<DateTime>(json['lastConsumedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'foodId': serializer.toJson<String>(foodId),
      'hourOfDay': serializer.toJson<int>(hourOfDay),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'mealType': serializer.toJson<MealType?>(mealType),
      'frequency': serializer.toJson<int>(frequency),
      'lastConsumedAt': serializer.toJson<DateTime>(lastConsumedAt),
    };
  }

  ConsumptionPattern copyWith({
    int? id,
    String? foodId,
    int? hourOfDay,
    int? dayOfWeek,
    Value<MealType?> mealType = const Value.absent(),
    int? frequency,
    DateTime? lastConsumedAt,
  }) => ConsumptionPattern(
    id: id ?? this.id,
    foodId: foodId ?? this.foodId,
    hourOfDay: hourOfDay ?? this.hourOfDay,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    mealType: mealType.present ? mealType.value : this.mealType,
    frequency: frequency ?? this.frequency,
    lastConsumedAt: lastConsumedAt ?? this.lastConsumedAt,
  );
  ConsumptionPattern copyWithCompanion(ConsumptionPatternsCompanion data) {
    return ConsumptionPattern(
      id: data.id.present ? data.id.value : this.id,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      hourOfDay: data.hourOfDay.present ? data.hourOfDay.value : this.hourOfDay,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      lastConsumedAt: data.lastConsumedAt.present
          ? data.lastConsumedAt.value
          : this.lastConsumedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConsumptionPattern(')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('hourOfDay: $hourOfDay, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('mealType: $mealType, ')
          ..write('frequency: $frequency, ')
          ..write('lastConsumedAt: $lastConsumedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    foodId,
    hourOfDay,
    dayOfWeek,
    mealType,
    frequency,
    lastConsumedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConsumptionPattern &&
          other.id == this.id &&
          other.foodId == this.foodId &&
          other.hourOfDay == this.hourOfDay &&
          other.dayOfWeek == this.dayOfWeek &&
          other.mealType == this.mealType &&
          other.frequency == this.frequency &&
          other.lastConsumedAt == this.lastConsumedAt);
}

class ConsumptionPatternsCompanion extends UpdateCompanion<ConsumptionPattern> {
  final Value<int> id;
  final Value<String> foodId;
  final Value<int> hourOfDay;
  final Value<int> dayOfWeek;
  final Value<MealType?> mealType;
  final Value<int> frequency;
  final Value<DateTime> lastConsumedAt;
  const ConsumptionPatternsCompanion({
    this.id = const Value.absent(),
    this.foodId = const Value.absent(),
    this.hourOfDay = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.mealType = const Value.absent(),
    this.frequency = const Value.absent(),
    this.lastConsumedAt = const Value.absent(),
  });
  ConsumptionPatternsCompanion.insert({
    this.id = const Value.absent(),
    required String foodId,
    required int hourOfDay,
    required int dayOfWeek,
    this.mealType = const Value.absent(),
    this.frequency = const Value.absent(),
    required DateTime lastConsumedAt,
  }) : foodId = Value(foodId),
       hourOfDay = Value(hourOfDay),
       dayOfWeek = Value(dayOfWeek),
       lastConsumedAt = Value(lastConsumedAt);
  static Insertable<ConsumptionPattern> custom({
    Expression<int>? id,
    Expression<String>? foodId,
    Expression<int>? hourOfDay,
    Expression<int>? dayOfWeek,
    Expression<String>? mealType,
    Expression<int>? frequency,
    Expression<DateTime>? lastConsumedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (foodId != null) 'food_id': foodId,
      if (hourOfDay != null) 'hour_of_day': hourOfDay,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (mealType != null) 'meal_type': mealType,
      if (frequency != null) 'frequency': frequency,
      if (lastConsumedAt != null) 'last_consumed_at': lastConsumedAt,
    });
  }

  ConsumptionPatternsCompanion copyWith({
    Value<int>? id,
    Value<String>? foodId,
    Value<int>? hourOfDay,
    Value<int>? dayOfWeek,
    Value<MealType?>? mealType,
    Value<int>? frequency,
    Value<DateTime>? lastConsumedAt,
  }) {
    return ConsumptionPatternsCompanion(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      hourOfDay: hourOfDay ?? this.hourOfDay,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      mealType: mealType ?? this.mealType,
      frequency: frequency ?? this.frequency,
      lastConsumedAt: lastConsumedAt ?? this.lastConsumedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (hourOfDay.present) {
      map['hour_of_day'] = Variable<int>(hourOfDay.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(
        $ConsumptionPatternsTable.$convertermealTypen.toSql(mealType.value),
      );
    }
    if (frequency.present) {
      map['frequency'] = Variable<int>(frequency.value);
    }
    if (lastConsumedAt.present) {
      map['last_consumed_at'] = Variable<DateTime>(lastConsumedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsumptionPatternsCompanion(')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('hourOfDay: $hourOfDay, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('mealType: $mealType, ')
          ..write('frequency: $frequency, ')
          ..write('lastConsumedAt: $lastConsumedAt')
          ..write(')'))
        .toString();
  }
}

class $MealTemplatesTable extends MealTemplates
    with TableInfo<$MealTemplatesTable, MealTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MealType, String> mealType =
      GeneratedColumn<String>(
        'meal_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MealType>($MealTemplatesTable.$convertermealType);
  static const VerificationMeta _useCountMeta = const VerificationMeta(
    'useCount',
  );
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
    'use_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    mealType,
    useCount,
    lastUsedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('use_count')) {
      context.handle(
        _useCountMeta,
        useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      mealType: $MealTemplatesTable.$convertermealType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meal_type'],
        )!,
      ),
      useCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}use_count'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MealTemplatesTable createAlias(String alias) {
    return $MealTemplatesTable(attachedDatabase, alias);
  }

  static TypeConverter<MealType, String> $convertermealType =
      const MealTypeConverter();
}

class MealTemplate extends DataClass implements Insertable<MealTemplate> {
  final String id;
  final String name;
  final MealType mealType;
  final int useCount;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MealTemplate({
    required this.id,
    required this.name,
    required this.mealType,
    required this.useCount,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['meal_type'] = Variable<String>(
        $MealTemplatesTable.$convertermealType.toSql(mealType),
      );
    }
    map['use_count'] = Variable<int>(useCount);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MealTemplatesCompanion toCompanion(bool nullToAbsent) {
    return MealTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      mealType: Value(mealType),
      useCount: Value(useCount),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MealTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealTemplate(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      mealType: serializer.fromJson<MealType>(json['mealType']),
      useCount: serializer.fromJson<int>(json['useCount']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'mealType': serializer.toJson<MealType>(mealType),
      'useCount': serializer.toJson<int>(useCount),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MealTemplate copyWith({
    String? id,
    String? name,
    MealType? mealType,
    int? useCount,
    Value<DateTime?> lastUsedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MealTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    mealType: mealType ?? this.mealType,
    useCount: useCount ?? this.useCount,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MealTemplate copyWithCompanion(MealTemplatesCompanion data) {
    return MealTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mealType: $mealType, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    mealType,
    useCount,
    lastUsedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.mealType == this.mealType &&
          other.useCount == this.useCount &&
          other.lastUsedAt == this.lastUsedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MealTemplatesCompanion extends UpdateCompanion<MealTemplate> {
  final Value<String> id;
  final Value<String> name;
  final Value<MealType> mealType;
  final Value<int> useCount;
  final Value<DateTime?> lastUsedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MealTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.mealType = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealTemplatesCompanion.insert({
    required String id,
    required String name,
    required MealType mealType,
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       mealType = Value(mealType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MealTemplate> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? mealType,
    Expression<int>? useCount,
    Expression<DateTime>? lastUsedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (mealType != null) 'meal_type': mealType,
      if (useCount != null) 'use_count': useCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<MealType>? mealType,
    Value<int>? useCount,
    Value<DateTime?>? lastUsedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MealTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(
        $MealTemplatesTable.$convertermealType.toSql(mealType.value),
      );
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
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
    return (StringBuffer('MealTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mealType: $mealType, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealTemplateItemsTable extends MealTemplateItems
    with TableInfo<$MealTemplateItemsTable, MealTemplateItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealTemplateItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES meal_templates (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES foods (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ServingUnit, String> unit =
      GeneratedColumn<String>(
        'unit',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ServingUnit>($MealTemplateItemsTable.$converterunit);
  static const VerificationMeta _foodNameSnapshotMeta = const VerificationMeta(
    'foodNameSnapshot',
  );
  @override
  late final GeneratedColumn<String> foodNameSnapshot = GeneratedColumn<String>(
    'food_name_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kcalPer100gSnapshotMeta =
      const VerificationMeta('kcalPer100gSnapshot');
  @override
  late final GeneratedColumn<int> kcalPer100gSnapshot = GeneratedColumn<int>(
    'kcal_per100g_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinPer100gSnapshotMeta =
      const VerificationMeta('proteinPer100gSnapshot');
  @override
  late final GeneratedColumn<double> proteinPer100gSnapshot =
      GeneratedColumn<double>(
        'protein_per100g_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _carbsPer100gSnapshotMeta =
      const VerificationMeta('carbsPer100gSnapshot');
  @override
  late final GeneratedColumn<double> carbsPer100gSnapshot =
      GeneratedColumn<double>(
        'carbs_per100g_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fatPer100gSnapshotMeta =
      const VerificationMeta('fatPer100gSnapshot');
  @override
  late final GeneratedColumn<double> fatPer100gSnapshot =
      GeneratedColumn<double>(
        'fat_per100g_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    foodId,
    amount,
    unit,
    foodNameSnapshot,
    kcalPer100gSnapshot,
    proteinPer100gSnapshot,
    carbsPer100gSnapshot,
    fatPer100gSnapshot,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_template_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealTemplateItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    } else if (isInserting) {
      context.missing(_foodIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('food_name_snapshot')) {
      context.handle(
        _foodNameSnapshotMeta,
        foodNameSnapshot.isAcceptableOrUnknown(
          data['food_name_snapshot']!,
          _foodNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_foodNameSnapshotMeta);
    }
    if (data.containsKey('kcal_per100g_snapshot')) {
      context.handle(
        _kcalPer100gSnapshotMeta,
        kcalPer100gSnapshot.isAcceptableOrUnknown(
          data['kcal_per100g_snapshot']!,
          _kcalPer100gSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kcalPer100gSnapshotMeta);
    }
    if (data.containsKey('protein_per100g_snapshot')) {
      context.handle(
        _proteinPer100gSnapshotMeta,
        proteinPer100gSnapshot.isAcceptableOrUnknown(
          data['protein_per100g_snapshot']!,
          _proteinPer100gSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('carbs_per100g_snapshot')) {
      context.handle(
        _carbsPer100gSnapshotMeta,
        carbsPer100gSnapshot.isAcceptableOrUnknown(
          data['carbs_per100g_snapshot']!,
          _carbsPer100gSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('fat_per100g_snapshot')) {
      context.handle(
        _fatPer100gSnapshotMeta,
        fatPer100gSnapshot.isAcceptableOrUnknown(
          data['fat_per100g_snapshot']!,
          _fatPer100gSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealTemplateItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealTemplateItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      unit: $MealTemplateItemsTable.$converterunit.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unit'],
        )!,
      ),
      foodNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_name_snapshot'],
      )!,
      kcalPer100gSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kcal_per100g_snapshot'],
      )!,
      proteinPer100gSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_per100g_snapshot'],
      ),
      carbsPer100gSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_per100g_snapshot'],
      ),
      fatPer100gSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_per100g_snapshot'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $MealTemplateItemsTable createAlias(String alias) {
    return $MealTemplateItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<ServingUnit, String> $converterunit =
      const ServingUnitConverter();
}

class MealTemplateItem extends DataClass
    implements Insertable<MealTemplateItem> {
  final String id;
  final String templateId;
  final String foodId;
  final double amount;
  final ServingUnit unit;
  final String foodNameSnapshot;
  final int kcalPer100gSnapshot;
  final double? proteinPer100gSnapshot;
  final double? carbsPer100gSnapshot;
  final double? fatPer100gSnapshot;
  final int sortOrder;
  const MealTemplateItem({
    required this.id,
    required this.templateId,
    required this.foodId,
    required this.amount,
    required this.unit,
    required this.foodNameSnapshot,
    required this.kcalPer100gSnapshot,
    this.proteinPer100gSnapshot,
    this.carbsPer100gSnapshot,
    this.fatPer100gSnapshot,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['food_id'] = Variable<String>(foodId);
    map['amount'] = Variable<double>(amount);
    {
      map['unit'] = Variable<String>(
        $MealTemplateItemsTable.$converterunit.toSql(unit),
      );
    }
    map['food_name_snapshot'] = Variable<String>(foodNameSnapshot);
    map['kcal_per100g_snapshot'] = Variable<int>(kcalPer100gSnapshot);
    if (!nullToAbsent || proteinPer100gSnapshot != null) {
      map['protein_per100g_snapshot'] = Variable<double>(
        proteinPer100gSnapshot,
      );
    }
    if (!nullToAbsent || carbsPer100gSnapshot != null) {
      map['carbs_per100g_snapshot'] = Variable<double>(carbsPer100gSnapshot);
    }
    if (!nullToAbsent || fatPer100gSnapshot != null) {
      map['fat_per100g_snapshot'] = Variable<double>(fatPer100gSnapshot);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  MealTemplateItemsCompanion toCompanion(bool nullToAbsent) {
    return MealTemplateItemsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      foodId: Value(foodId),
      amount: Value(amount),
      unit: Value(unit),
      foodNameSnapshot: Value(foodNameSnapshot),
      kcalPer100gSnapshot: Value(kcalPer100gSnapshot),
      proteinPer100gSnapshot: proteinPer100gSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinPer100gSnapshot),
      carbsPer100gSnapshot: carbsPer100gSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsPer100gSnapshot),
      fatPer100gSnapshot: fatPer100gSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(fatPer100gSnapshot),
      sortOrder: Value(sortOrder),
    );
  }

  factory MealTemplateItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealTemplateItem(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['templateId']),
      foodId: serializer.fromJson<String>(json['foodId']),
      amount: serializer.fromJson<double>(json['amount']),
      unit: serializer.fromJson<ServingUnit>(json['unit']),
      foodNameSnapshot: serializer.fromJson<String>(json['foodNameSnapshot']),
      kcalPer100gSnapshot: serializer.fromJson<int>(
        json['kcalPer100gSnapshot'],
      ),
      proteinPer100gSnapshot: serializer.fromJson<double?>(
        json['proteinPer100gSnapshot'],
      ),
      carbsPer100gSnapshot: serializer.fromJson<double?>(
        json['carbsPer100gSnapshot'],
      ),
      fatPer100gSnapshot: serializer.fromJson<double?>(
        json['fatPer100gSnapshot'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String>(templateId),
      'foodId': serializer.toJson<String>(foodId),
      'amount': serializer.toJson<double>(amount),
      'unit': serializer.toJson<ServingUnit>(unit),
      'foodNameSnapshot': serializer.toJson<String>(foodNameSnapshot),
      'kcalPer100gSnapshot': serializer.toJson<int>(kcalPer100gSnapshot),
      'proteinPer100gSnapshot': serializer.toJson<double?>(
        proteinPer100gSnapshot,
      ),
      'carbsPer100gSnapshot': serializer.toJson<double?>(carbsPer100gSnapshot),
      'fatPer100gSnapshot': serializer.toJson<double?>(fatPer100gSnapshot),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  MealTemplateItem copyWith({
    String? id,
    String? templateId,
    String? foodId,
    double? amount,
    ServingUnit? unit,
    String? foodNameSnapshot,
    int? kcalPer100gSnapshot,
    Value<double?> proteinPer100gSnapshot = const Value.absent(),
    Value<double?> carbsPer100gSnapshot = const Value.absent(),
    Value<double?> fatPer100gSnapshot = const Value.absent(),
    int? sortOrder,
  }) => MealTemplateItem(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    foodId: foodId ?? this.foodId,
    amount: amount ?? this.amount,
    unit: unit ?? this.unit,
    foodNameSnapshot: foodNameSnapshot ?? this.foodNameSnapshot,
    kcalPer100gSnapshot: kcalPer100gSnapshot ?? this.kcalPer100gSnapshot,
    proteinPer100gSnapshot: proteinPer100gSnapshot.present
        ? proteinPer100gSnapshot.value
        : this.proteinPer100gSnapshot,
    carbsPer100gSnapshot: carbsPer100gSnapshot.present
        ? carbsPer100gSnapshot.value
        : this.carbsPer100gSnapshot,
    fatPer100gSnapshot: fatPer100gSnapshot.present
        ? fatPer100gSnapshot.value
        : this.fatPer100gSnapshot,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  MealTemplateItem copyWithCompanion(MealTemplateItemsCompanion data) {
    return MealTemplateItem(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      foodNameSnapshot: data.foodNameSnapshot.present
          ? data.foodNameSnapshot.value
          : this.foodNameSnapshot,
      kcalPer100gSnapshot: data.kcalPer100gSnapshot.present
          ? data.kcalPer100gSnapshot.value
          : this.kcalPer100gSnapshot,
      proteinPer100gSnapshot: data.proteinPer100gSnapshot.present
          ? data.proteinPer100gSnapshot.value
          : this.proteinPer100gSnapshot,
      carbsPer100gSnapshot: data.carbsPer100gSnapshot.present
          ? data.carbsPer100gSnapshot.value
          : this.carbsPer100gSnapshot,
      fatPer100gSnapshot: data.fatPer100gSnapshot.present
          ? data.fatPer100gSnapshot.value
          : this.fatPer100gSnapshot,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealTemplateItem(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('foodId: $foodId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('foodNameSnapshot: $foodNameSnapshot, ')
          ..write('kcalPer100gSnapshot: $kcalPer100gSnapshot, ')
          ..write('proteinPer100gSnapshot: $proteinPer100gSnapshot, ')
          ..write('carbsPer100gSnapshot: $carbsPer100gSnapshot, ')
          ..write('fatPer100gSnapshot: $fatPer100gSnapshot, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    foodId,
    amount,
    unit,
    foodNameSnapshot,
    kcalPer100gSnapshot,
    proteinPer100gSnapshot,
    carbsPer100gSnapshot,
    fatPer100gSnapshot,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealTemplateItem &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.foodId == this.foodId &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.foodNameSnapshot == this.foodNameSnapshot &&
          other.kcalPer100gSnapshot == this.kcalPer100gSnapshot &&
          other.proteinPer100gSnapshot == this.proteinPer100gSnapshot &&
          other.carbsPer100gSnapshot == this.carbsPer100gSnapshot &&
          other.fatPer100gSnapshot == this.fatPer100gSnapshot &&
          other.sortOrder == this.sortOrder);
}

class MealTemplateItemsCompanion extends UpdateCompanion<MealTemplateItem> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<String> foodId;
  final Value<double> amount;
  final Value<ServingUnit> unit;
  final Value<String> foodNameSnapshot;
  final Value<int> kcalPer100gSnapshot;
  final Value<double?> proteinPer100gSnapshot;
  final Value<double?> carbsPer100gSnapshot;
  final Value<double?> fatPer100gSnapshot;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const MealTemplateItemsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.foodId = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.foodNameSnapshot = const Value.absent(),
    this.kcalPer100gSnapshot = const Value.absent(),
    this.proteinPer100gSnapshot = const Value.absent(),
    this.carbsPer100gSnapshot = const Value.absent(),
    this.fatPer100gSnapshot = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealTemplateItemsCompanion.insert({
    required String id,
    required String templateId,
    required String foodId,
    required double amount,
    required ServingUnit unit,
    required String foodNameSnapshot,
    required int kcalPer100gSnapshot,
    this.proteinPer100gSnapshot = const Value.absent(),
    this.carbsPer100gSnapshot = const Value.absent(),
    this.fatPer100gSnapshot = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateId = Value(templateId),
       foodId = Value(foodId),
       amount = Value(amount),
       unit = Value(unit),
       foodNameSnapshot = Value(foodNameSnapshot),
       kcalPer100gSnapshot = Value(kcalPer100gSnapshot);
  static Insertable<MealTemplateItem> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? foodId,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<String>? foodNameSnapshot,
    Expression<int>? kcalPer100gSnapshot,
    Expression<double>? proteinPer100gSnapshot,
    Expression<double>? carbsPer100gSnapshot,
    Expression<double>? fatPer100gSnapshot,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (foodId != null) 'food_id': foodId,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (foodNameSnapshot != null) 'food_name_snapshot': foodNameSnapshot,
      if (kcalPer100gSnapshot != null)
        'kcal_per100g_snapshot': kcalPer100gSnapshot,
      if (proteinPer100gSnapshot != null)
        'protein_per100g_snapshot': proteinPer100gSnapshot,
      if (carbsPer100gSnapshot != null)
        'carbs_per100g_snapshot': carbsPer100gSnapshot,
      if (fatPer100gSnapshot != null)
        'fat_per100g_snapshot': fatPer100gSnapshot,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealTemplateItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? templateId,
    Value<String>? foodId,
    Value<double>? amount,
    Value<ServingUnit>? unit,
    Value<String>? foodNameSnapshot,
    Value<int>? kcalPer100gSnapshot,
    Value<double?>? proteinPer100gSnapshot,
    Value<double?>? carbsPer100gSnapshot,
    Value<double?>? fatPer100gSnapshot,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return MealTemplateItemsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      foodId: foodId ?? this.foodId,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      foodNameSnapshot: foodNameSnapshot ?? this.foodNameSnapshot,
      kcalPer100gSnapshot: kcalPer100gSnapshot ?? this.kcalPer100gSnapshot,
      proteinPer100gSnapshot:
          proteinPer100gSnapshot ?? this.proteinPer100gSnapshot,
      carbsPer100gSnapshot: carbsPer100gSnapshot ?? this.carbsPer100gSnapshot,
      fatPer100gSnapshot: fatPer100gSnapshot ?? this.fatPer100gSnapshot,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(
        $MealTemplateItemsTable.$converterunit.toSql(unit.value),
      );
    }
    if (foodNameSnapshot.present) {
      map['food_name_snapshot'] = Variable<String>(foodNameSnapshot.value);
    }
    if (kcalPer100gSnapshot.present) {
      map['kcal_per100g_snapshot'] = Variable<int>(kcalPer100gSnapshot.value);
    }
    if (proteinPer100gSnapshot.present) {
      map['protein_per100g_snapshot'] = Variable<double>(
        proteinPer100gSnapshot.value,
      );
    }
    if (carbsPer100gSnapshot.present) {
      map['carbs_per100g_snapshot'] = Variable<double>(
        carbsPer100gSnapshot.value,
      );
    }
    if (fatPer100gSnapshot.present) {
      map['fat_per100g_snapshot'] = Variable<double>(fatPer100gSnapshot.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealTemplateItemsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('foodId: $foodId, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('foodNameSnapshot: $foodNameSnapshot, ')
          ..write('kcalPer100gSnapshot: $kcalPer100gSnapshot, ')
          ..write('proteinPer100gSnapshot: $proteinPer100gSnapshot, ')
          ..write('carbsPer100gSnapshot: $carbsPer100gSnapshot, ')
          ..write('fatPer100gSnapshot: $fatPer100gSnapshot, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BodyMeasurementsTable extends BodyMeasurements
    with TableInfo<$BodyMeasurementsTable, BodyMeasurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waistCmMeta = const VerificationMeta(
    'waistCm',
  );
  @override
  late final GeneratedColumn<double> waistCm = GeneratedColumn<double>(
    'waist_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chestCmMeta = const VerificationMeta(
    'chestCm',
  );
  @override
  late final GeneratedColumn<double> chestCm = GeneratedColumn<double>(
    'chest_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hipsCmMeta = const VerificationMeta('hipsCm');
  @override
  late final GeneratedColumn<double> hipsCm = GeneratedColumn<double>(
    'hips_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leftArmCmMeta = const VerificationMeta(
    'leftArmCm',
  );
  @override
  late final GeneratedColumn<double> leftArmCm = GeneratedColumn<double>(
    'left_arm_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rightArmCmMeta = const VerificationMeta(
    'rightArmCm',
  );
  @override
  late final GeneratedColumn<double> rightArmCm = GeneratedColumn<double>(
    'right_arm_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leftThighCmMeta = const VerificationMeta(
    'leftThighCm',
  );
  @override
  late final GeneratedColumn<double> leftThighCm = GeneratedColumn<double>(
    'left_thigh_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rightThighCmMeta = const VerificationMeta(
    'rightThighCm',
  );
  @override
  late final GeneratedColumn<double> rightThighCm = GeneratedColumn<double>(
    'right_thigh_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leftCalfCmMeta = const VerificationMeta(
    'leftCalfCm',
  );
  @override
  late final GeneratedColumn<double> leftCalfCm = GeneratedColumn<double>(
    'left_calf_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rightCalfCmMeta = const VerificationMeta(
    'rightCalfCm',
  );
  @override
  late final GeneratedColumn<double> rightCalfCm = GeneratedColumn<double>(
    'right_calf_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _neckCmMeta = const VerificationMeta('neckCm');
  @override
  late final GeneratedColumn<double> neckCm = GeneratedColumn<double>(
    'neck_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyFatPercentageMeta = const VerificationMeta(
    'bodyFatPercentage',
  );
  @override
  late final GeneratedColumn<double> bodyFatPercentage =
      GeneratedColumn<double>(
        'body_fat_percentage',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    weightKg,
    waistCm,
    chestCm,
    hipsCm,
    leftArmCm,
    rightArmCm,
    leftThighCm,
    rightThighCm,
    leftCalfCm,
    rightCalfCm,
    neckCm,
    bodyFatPercentage,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<BodyMeasurement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('waist_cm')) {
      context.handle(
        _waistCmMeta,
        waistCm.isAcceptableOrUnknown(data['waist_cm']!, _waistCmMeta),
      );
    }
    if (data.containsKey('chest_cm')) {
      context.handle(
        _chestCmMeta,
        chestCm.isAcceptableOrUnknown(data['chest_cm']!, _chestCmMeta),
      );
    }
    if (data.containsKey('hips_cm')) {
      context.handle(
        _hipsCmMeta,
        hipsCm.isAcceptableOrUnknown(data['hips_cm']!, _hipsCmMeta),
      );
    }
    if (data.containsKey('left_arm_cm')) {
      context.handle(
        _leftArmCmMeta,
        leftArmCm.isAcceptableOrUnknown(data['left_arm_cm']!, _leftArmCmMeta),
      );
    }
    if (data.containsKey('right_arm_cm')) {
      context.handle(
        _rightArmCmMeta,
        rightArmCm.isAcceptableOrUnknown(
          data['right_arm_cm']!,
          _rightArmCmMeta,
        ),
      );
    }
    if (data.containsKey('left_thigh_cm')) {
      context.handle(
        _leftThighCmMeta,
        leftThighCm.isAcceptableOrUnknown(
          data['left_thigh_cm']!,
          _leftThighCmMeta,
        ),
      );
    }
    if (data.containsKey('right_thigh_cm')) {
      context.handle(
        _rightThighCmMeta,
        rightThighCm.isAcceptableOrUnknown(
          data['right_thigh_cm']!,
          _rightThighCmMeta,
        ),
      );
    }
    if (data.containsKey('left_calf_cm')) {
      context.handle(
        _leftCalfCmMeta,
        leftCalfCm.isAcceptableOrUnknown(
          data['left_calf_cm']!,
          _leftCalfCmMeta,
        ),
      );
    }
    if (data.containsKey('right_calf_cm')) {
      context.handle(
        _rightCalfCmMeta,
        rightCalfCm.isAcceptableOrUnknown(
          data['right_calf_cm']!,
          _rightCalfCmMeta,
        ),
      );
    }
    if (data.containsKey('neck_cm')) {
      context.handle(
        _neckCmMeta,
        neckCm.isAcceptableOrUnknown(data['neck_cm']!, _neckCmMeta),
      );
    }
    if (data.containsKey('body_fat_percentage')) {
      context.handle(
        _bodyFatPercentageMeta,
        bodyFatPercentage.isAcceptableOrUnknown(
          data['body_fat_percentage']!,
          _bodyFatPercentageMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyMeasurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyMeasurement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      waistCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}waist_cm'],
      ),
      chestCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}chest_cm'],
      ),
      hipsCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hips_cm'],
      ),
      leftArmCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}left_arm_cm'],
      ),
      rightArmCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}right_arm_cm'],
      ),
      leftThighCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}left_thigh_cm'],
      ),
      rightThighCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}right_thigh_cm'],
      ),
      leftCalfCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}left_calf_cm'],
      ),
      rightCalfCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}right_calf_cm'],
      ),
      neckCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}neck_cm'],
      ),
      bodyFatPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}body_fat_percentage'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BodyMeasurementsTable createAlias(String alias) {
    return $BodyMeasurementsTable(attachedDatabase, alias);
  }
}

class BodyMeasurement extends DataClass implements Insertable<BodyMeasurement> {
  final String id;
  final DateTime date;
  final double? weightKg;
  final double? waistCm;
  final double? chestCm;
  final double? hipsCm;
  final double? leftArmCm;
  final double? rightArmCm;
  final double? leftThighCm;
  final double? rightThighCm;
  final double? leftCalfCm;
  final double? rightCalfCm;
  final double? neckCm;
  final double? bodyFatPercentage;
  final String? notes;
  final DateTime createdAt;
  const BodyMeasurement({
    required this.id,
    required this.date,
    this.weightKg,
    this.waistCm,
    this.chestCm,
    this.hipsCm,
    this.leftArmCm,
    this.rightArmCm,
    this.leftThighCm,
    this.rightThighCm,
    this.leftCalfCm,
    this.rightCalfCm,
    this.neckCm,
    this.bodyFatPercentage,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || waistCm != null) {
      map['waist_cm'] = Variable<double>(waistCm);
    }
    if (!nullToAbsent || chestCm != null) {
      map['chest_cm'] = Variable<double>(chestCm);
    }
    if (!nullToAbsent || hipsCm != null) {
      map['hips_cm'] = Variable<double>(hipsCm);
    }
    if (!nullToAbsent || leftArmCm != null) {
      map['left_arm_cm'] = Variable<double>(leftArmCm);
    }
    if (!nullToAbsent || rightArmCm != null) {
      map['right_arm_cm'] = Variable<double>(rightArmCm);
    }
    if (!nullToAbsent || leftThighCm != null) {
      map['left_thigh_cm'] = Variable<double>(leftThighCm);
    }
    if (!nullToAbsent || rightThighCm != null) {
      map['right_thigh_cm'] = Variable<double>(rightThighCm);
    }
    if (!nullToAbsent || leftCalfCm != null) {
      map['left_calf_cm'] = Variable<double>(leftCalfCm);
    }
    if (!nullToAbsent || rightCalfCm != null) {
      map['right_calf_cm'] = Variable<double>(rightCalfCm);
    }
    if (!nullToAbsent || neckCm != null) {
      map['neck_cm'] = Variable<double>(neckCm);
    }
    if (!nullToAbsent || bodyFatPercentage != null) {
      map['body_fat_percentage'] = Variable<double>(bodyFatPercentage);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BodyMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return BodyMeasurementsCompanion(
      id: Value(id),
      date: Value(date),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      waistCm: waistCm == null && nullToAbsent
          ? const Value.absent()
          : Value(waistCm),
      chestCm: chestCm == null && nullToAbsent
          ? const Value.absent()
          : Value(chestCm),
      hipsCm: hipsCm == null && nullToAbsent
          ? const Value.absent()
          : Value(hipsCm),
      leftArmCm: leftArmCm == null && nullToAbsent
          ? const Value.absent()
          : Value(leftArmCm),
      rightArmCm: rightArmCm == null && nullToAbsent
          ? const Value.absent()
          : Value(rightArmCm),
      leftThighCm: leftThighCm == null && nullToAbsent
          ? const Value.absent()
          : Value(leftThighCm),
      rightThighCm: rightThighCm == null && nullToAbsent
          ? const Value.absent()
          : Value(rightThighCm),
      leftCalfCm: leftCalfCm == null && nullToAbsent
          ? const Value.absent()
          : Value(leftCalfCm),
      rightCalfCm: rightCalfCm == null && nullToAbsent
          ? const Value.absent()
          : Value(rightCalfCm),
      neckCm: neckCm == null && nullToAbsent
          ? const Value.absent()
          : Value(neckCm),
      bodyFatPercentage: bodyFatPercentage == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPercentage),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory BodyMeasurement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyMeasurement(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      waistCm: serializer.fromJson<double?>(json['waistCm']),
      chestCm: serializer.fromJson<double?>(json['chestCm']),
      hipsCm: serializer.fromJson<double?>(json['hipsCm']),
      leftArmCm: serializer.fromJson<double?>(json['leftArmCm']),
      rightArmCm: serializer.fromJson<double?>(json['rightArmCm']),
      leftThighCm: serializer.fromJson<double?>(json['leftThighCm']),
      rightThighCm: serializer.fromJson<double?>(json['rightThighCm']),
      leftCalfCm: serializer.fromJson<double?>(json['leftCalfCm']),
      rightCalfCm: serializer.fromJson<double?>(json['rightCalfCm']),
      neckCm: serializer.fromJson<double?>(json['neckCm']),
      bodyFatPercentage: serializer.fromJson<double?>(
        json['bodyFatPercentage'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'weightKg': serializer.toJson<double?>(weightKg),
      'waistCm': serializer.toJson<double?>(waistCm),
      'chestCm': serializer.toJson<double?>(chestCm),
      'hipsCm': serializer.toJson<double?>(hipsCm),
      'leftArmCm': serializer.toJson<double?>(leftArmCm),
      'rightArmCm': serializer.toJson<double?>(rightArmCm),
      'leftThighCm': serializer.toJson<double?>(leftThighCm),
      'rightThighCm': serializer.toJson<double?>(rightThighCm),
      'leftCalfCm': serializer.toJson<double?>(leftCalfCm),
      'rightCalfCm': serializer.toJson<double?>(rightCalfCm),
      'neckCm': serializer.toJson<double?>(neckCm),
      'bodyFatPercentage': serializer.toJson<double?>(bodyFatPercentage),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BodyMeasurement copyWith({
    String? id,
    DateTime? date,
    Value<double?> weightKg = const Value.absent(),
    Value<double?> waistCm = const Value.absent(),
    Value<double?> chestCm = const Value.absent(),
    Value<double?> hipsCm = const Value.absent(),
    Value<double?> leftArmCm = const Value.absent(),
    Value<double?> rightArmCm = const Value.absent(),
    Value<double?> leftThighCm = const Value.absent(),
    Value<double?> rightThighCm = const Value.absent(),
    Value<double?> leftCalfCm = const Value.absent(),
    Value<double?> rightCalfCm = const Value.absent(),
    Value<double?> neckCm = const Value.absent(),
    Value<double?> bodyFatPercentage = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => BodyMeasurement(
    id: id ?? this.id,
    date: date ?? this.date,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    waistCm: waistCm.present ? waistCm.value : this.waistCm,
    chestCm: chestCm.present ? chestCm.value : this.chestCm,
    hipsCm: hipsCm.present ? hipsCm.value : this.hipsCm,
    leftArmCm: leftArmCm.present ? leftArmCm.value : this.leftArmCm,
    rightArmCm: rightArmCm.present ? rightArmCm.value : this.rightArmCm,
    leftThighCm: leftThighCm.present ? leftThighCm.value : this.leftThighCm,
    rightThighCm: rightThighCm.present ? rightThighCm.value : this.rightThighCm,
    leftCalfCm: leftCalfCm.present ? leftCalfCm.value : this.leftCalfCm,
    rightCalfCm: rightCalfCm.present ? rightCalfCm.value : this.rightCalfCm,
    neckCm: neckCm.present ? neckCm.value : this.neckCm,
    bodyFatPercentage: bodyFatPercentage.present
        ? bodyFatPercentage.value
        : this.bodyFatPercentage,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  BodyMeasurement copyWithCompanion(BodyMeasurementsCompanion data) {
    return BodyMeasurement(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      waistCm: data.waistCm.present ? data.waistCm.value : this.waistCm,
      chestCm: data.chestCm.present ? data.chestCm.value : this.chestCm,
      hipsCm: data.hipsCm.present ? data.hipsCm.value : this.hipsCm,
      leftArmCm: data.leftArmCm.present ? data.leftArmCm.value : this.leftArmCm,
      rightArmCm: data.rightArmCm.present
          ? data.rightArmCm.value
          : this.rightArmCm,
      leftThighCm: data.leftThighCm.present
          ? data.leftThighCm.value
          : this.leftThighCm,
      rightThighCm: data.rightThighCm.present
          ? data.rightThighCm.value
          : this.rightThighCm,
      leftCalfCm: data.leftCalfCm.present
          ? data.leftCalfCm.value
          : this.leftCalfCm,
      rightCalfCm: data.rightCalfCm.present
          ? data.rightCalfCm.value
          : this.rightCalfCm,
      neckCm: data.neckCm.present ? data.neckCm.value : this.neckCm,
      bodyFatPercentage: data.bodyFatPercentage.present
          ? data.bodyFatPercentage.value
          : this.bodyFatPercentage,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurement(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('weightKg: $weightKg, ')
          ..write('waistCm: $waistCm, ')
          ..write('chestCm: $chestCm, ')
          ..write('hipsCm: $hipsCm, ')
          ..write('leftArmCm: $leftArmCm, ')
          ..write('rightArmCm: $rightArmCm, ')
          ..write('leftThighCm: $leftThighCm, ')
          ..write('rightThighCm: $rightThighCm, ')
          ..write('leftCalfCm: $leftCalfCm, ')
          ..write('rightCalfCm: $rightCalfCm, ')
          ..write('neckCm: $neckCm, ')
          ..write('bodyFatPercentage: $bodyFatPercentage, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    weightKg,
    waistCm,
    chestCm,
    hipsCm,
    leftArmCm,
    rightArmCm,
    leftThighCm,
    rightThighCm,
    leftCalfCm,
    rightCalfCm,
    neckCm,
    bodyFatPercentage,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyMeasurement &&
          other.id == this.id &&
          other.date == this.date &&
          other.weightKg == this.weightKg &&
          other.waistCm == this.waistCm &&
          other.chestCm == this.chestCm &&
          other.hipsCm == this.hipsCm &&
          other.leftArmCm == this.leftArmCm &&
          other.rightArmCm == this.rightArmCm &&
          other.leftThighCm == this.leftThighCm &&
          other.rightThighCm == this.rightThighCm &&
          other.leftCalfCm == this.leftCalfCm &&
          other.rightCalfCm == this.rightCalfCm &&
          other.neckCm == this.neckCm &&
          other.bodyFatPercentage == this.bodyFatPercentage &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class BodyMeasurementsCompanion extends UpdateCompanion<BodyMeasurement> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<double?> weightKg;
  final Value<double?> waistCm;
  final Value<double?> chestCm;
  final Value<double?> hipsCm;
  final Value<double?> leftArmCm;
  final Value<double?> rightArmCm;
  final Value<double?> leftThighCm;
  final Value<double?> rightThighCm;
  final Value<double?> leftCalfCm;
  final Value<double?> rightCalfCm;
  final Value<double?> neckCm;
  final Value<double?> bodyFatPercentage;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BodyMeasurementsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.waistCm = const Value.absent(),
    this.chestCm = const Value.absent(),
    this.hipsCm = const Value.absent(),
    this.leftArmCm = const Value.absent(),
    this.rightArmCm = const Value.absent(),
    this.leftThighCm = const Value.absent(),
    this.rightThighCm = const Value.absent(),
    this.leftCalfCm = const Value.absent(),
    this.rightCalfCm = const Value.absent(),
    this.neckCm = const Value.absent(),
    this.bodyFatPercentage = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BodyMeasurementsCompanion.insert({
    required String id,
    required DateTime date,
    this.weightKg = const Value.absent(),
    this.waistCm = const Value.absent(),
    this.chestCm = const Value.absent(),
    this.hipsCm = const Value.absent(),
    this.leftArmCm = const Value.absent(),
    this.rightArmCm = const Value.absent(),
    this.leftThighCm = const Value.absent(),
    this.rightThighCm = const Value.absent(),
    this.leftCalfCm = const Value.absent(),
    this.rightCalfCm = const Value.absent(),
    this.neckCm = const Value.absent(),
    this.bodyFatPercentage = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<BodyMeasurement> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<double>? weightKg,
    Expression<double>? waistCm,
    Expression<double>? chestCm,
    Expression<double>? hipsCm,
    Expression<double>? leftArmCm,
    Expression<double>? rightArmCm,
    Expression<double>? leftThighCm,
    Expression<double>? rightThighCm,
    Expression<double>? leftCalfCm,
    Expression<double>? rightCalfCm,
    Expression<double>? neckCm,
    Expression<double>? bodyFatPercentage,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (weightKg != null) 'weight_kg': weightKg,
      if (waistCm != null) 'waist_cm': waistCm,
      if (chestCm != null) 'chest_cm': chestCm,
      if (hipsCm != null) 'hips_cm': hipsCm,
      if (leftArmCm != null) 'left_arm_cm': leftArmCm,
      if (rightArmCm != null) 'right_arm_cm': rightArmCm,
      if (leftThighCm != null) 'left_thigh_cm': leftThighCm,
      if (rightThighCm != null) 'right_thigh_cm': rightThighCm,
      if (leftCalfCm != null) 'left_calf_cm': leftCalfCm,
      if (rightCalfCm != null) 'right_calf_cm': rightCalfCm,
      if (neckCm != null) 'neck_cm': neckCm,
      if (bodyFatPercentage != null) 'body_fat_percentage': bodyFatPercentage,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BodyMeasurementsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<double?>? weightKg,
    Value<double?>? waistCm,
    Value<double?>? chestCm,
    Value<double?>? hipsCm,
    Value<double?>? leftArmCm,
    Value<double?>? rightArmCm,
    Value<double?>? leftThighCm,
    Value<double?>? rightThighCm,
    Value<double?>? leftCalfCm,
    Value<double?>? rightCalfCm,
    Value<double?>? neckCm,
    Value<double?>? bodyFatPercentage,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BodyMeasurementsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      waistCm: waistCm ?? this.waistCm,
      chestCm: chestCm ?? this.chestCm,
      hipsCm: hipsCm ?? this.hipsCm,
      leftArmCm: leftArmCm ?? this.leftArmCm,
      rightArmCm: rightArmCm ?? this.rightArmCm,
      leftThighCm: leftThighCm ?? this.leftThighCm,
      rightThighCm: rightThighCm ?? this.rightThighCm,
      leftCalfCm: leftCalfCm ?? this.leftCalfCm,
      rightCalfCm: rightCalfCm ?? this.rightCalfCm,
      neckCm: neckCm ?? this.neckCm,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      notes: notes ?? this.notes,
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
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (waistCm.present) {
      map['waist_cm'] = Variable<double>(waistCm.value);
    }
    if (chestCm.present) {
      map['chest_cm'] = Variable<double>(chestCm.value);
    }
    if (hipsCm.present) {
      map['hips_cm'] = Variable<double>(hipsCm.value);
    }
    if (leftArmCm.present) {
      map['left_arm_cm'] = Variable<double>(leftArmCm.value);
    }
    if (rightArmCm.present) {
      map['right_arm_cm'] = Variable<double>(rightArmCm.value);
    }
    if (leftThighCm.present) {
      map['left_thigh_cm'] = Variable<double>(leftThighCm.value);
    }
    if (rightThighCm.present) {
      map['right_thigh_cm'] = Variable<double>(rightThighCm.value);
    }
    if (leftCalfCm.present) {
      map['left_calf_cm'] = Variable<double>(leftCalfCm.value);
    }
    if (rightCalfCm.present) {
      map['right_calf_cm'] = Variable<double>(rightCalfCm.value);
    }
    if (neckCm.present) {
      map['neck_cm'] = Variable<double>(neckCm.value);
    }
    if (bodyFatPercentage.present) {
      map['body_fat_percentage'] = Variable<double>(bodyFatPercentage.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
    return (StringBuffer('BodyMeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('weightKg: $weightKg, ')
          ..write('waistCm: $waistCm, ')
          ..write('chestCm: $chestCm, ')
          ..write('hipsCm: $hipsCm, ')
          ..write('leftArmCm: $leftArmCm, ')
          ..write('rightArmCm: $rightArmCm, ')
          ..write('leftThighCm: $leftThighCm, ')
          ..write('rightThighCm: $rightThighCm, ')
          ..write('leftCalfCm: $leftCalfCm, ')
          ..write('rightCalfCm: $rightCalfCm, ')
          ..write('neckCm: $neckCm, ')
          ..write('bodyFatPercentage: $bodyFatPercentage, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgressPhotosTable extends ProgressPhotos
    with TableInfo<$ProgressPhotosTable, ProgressPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('front'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _measurementIdMeta = const VerificationMeta(
    'measurementId',
  );
  @override
  late final GeneratedColumn<String> measurementId = GeneratedColumn<String>(
    'measurement_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES body_measurements (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    imagePath,
    category,
    notes,
    measurementId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgressPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('measurement_id')) {
      context.handle(
        _measurementIdMeta,
        measurementId.isAcceptableOrUnknown(
          data['measurement_id']!,
          _measurementIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgressPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressPhoto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      measurementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProgressPhotosTable createAlias(String alias) {
    return $ProgressPhotosTable(attachedDatabase, alias);
  }
}

class ProgressPhoto extends DataClass implements Insertable<ProgressPhoto> {
  final String id;
  final DateTime date;
  final String imagePath;
  final String category;
  final String? notes;
  final String? measurementId;
  final DateTime createdAt;
  const ProgressPhoto({
    required this.id,
    required this.date,
    required this.imagePath,
    required this.category,
    this.notes,
    this.measurementId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    map['image_path'] = Variable<String>(imagePath);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || measurementId != null) {
      map['measurement_id'] = Variable<String>(measurementId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProgressPhotosCompanion toCompanion(bool nullToAbsent) {
    return ProgressPhotosCompanion(
      id: Value(id),
      date: Value(date),
      imagePath: Value(imagePath),
      category: Value(category),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      measurementId: measurementId == null && nullToAbsent
          ? const Value.absent()
          : Value(measurementId),
      createdAt: Value(createdAt),
    );
  }

  factory ProgressPhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressPhoto(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      category: serializer.fromJson<String>(json['category']),
      notes: serializer.fromJson<String?>(json['notes']),
      measurementId: serializer.fromJson<String?>(json['measurementId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'imagePath': serializer.toJson<String>(imagePath),
      'category': serializer.toJson<String>(category),
      'notes': serializer.toJson<String?>(notes),
      'measurementId': serializer.toJson<String?>(measurementId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProgressPhoto copyWith({
    String? id,
    DateTime? date,
    String? imagePath,
    String? category,
    Value<String?> notes = const Value.absent(),
    Value<String?> measurementId = const Value.absent(),
    DateTime? createdAt,
  }) => ProgressPhoto(
    id: id ?? this.id,
    date: date ?? this.date,
    imagePath: imagePath ?? this.imagePath,
    category: category ?? this.category,
    notes: notes.present ? notes.value : this.notes,
    measurementId: measurementId.present
        ? measurementId.value
        : this.measurementId,
    createdAt: createdAt ?? this.createdAt,
  );
  ProgressPhoto copyWithCompanion(ProgressPhotosCompanion data) {
    return ProgressPhoto(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      category: data.category.present ? data.category.value : this.category,
      notes: data.notes.present ? data.notes.value : this.notes,
      measurementId: data.measurementId.present
          ? data.measurementId.value
          : this.measurementId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressPhoto(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('imagePath: $imagePath, ')
          ..write('category: $category, ')
          ..write('notes: $notes, ')
          ..write('measurementId: $measurementId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    imagePath,
    category,
    notes,
    measurementId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressPhoto &&
          other.id == this.id &&
          other.date == this.date &&
          other.imagePath == this.imagePath &&
          other.category == this.category &&
          other.notes == this.notes &&
          other.measurementId == this.measurementId &&
          other.createdAt == this.createdAt);
}

class ProgressPhotosCompanion extends UpdateCompanion<ProgressPhoto> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<String> imagePath;
  final Value<String> category;
  final Value<String?> notes;
  final Value<String?> measurementId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProgressPhotosCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.category = const Value.absent(),
    this.notes = const Value.absent(),
    this.measurementId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressPhotosCompanion.insert({
    required String id,
    required DateTime date,
    required String imagePath,
    this.category = const Value.absent(),
    this.notes = const Value.absent(),
    this.measurementId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       imagePath = Value(imagePath),
       createdAt = Value(createdAt);
  static Insertable<ProgressPhoto> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<String>? imagePath,
    Expression<String>? category,
    Expression<String>? notes,
    Expression<String>? measurementId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (imagePath != null) 'image_path': imagePath,
      if (category != null) 'category': category,
      if (notes != null) 'notes': notes,
      if (measurementId != null) 'measurement_id': measurementId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressPhotosCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<String>? imagePath,
    Value<String>? category,
    Value<String?>? notes,
    Value<String?>? measurementId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProgressPhotosCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      measurementId: measurementId ?? this.measurementId,
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
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (measurementId.present) {
      map['measurement_id'] = Variable<String>(measurementId.value);
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
    return (StringBuffer('ProgressPhotosCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('imagePath: $imagePath, ')
          ..write('category: $category, ')
          ..write('notes: $notes, ')
          ..write('measurementId: $measurementId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RoutinesTable routines = $RoutinesTable(this);
  late final $RoutineDaysTable routineDays = $RoutineDaysTable(this);
  late final $RoutineExercisesTable routineExercises = $RoutineExercisesTable(
    this,
  );
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SessionExercisesTable sessionExercises = $SessionExercisesTable(
    this,
  );
  late final $WorkoutSetsTable workoutSets = $WorkoutSetsTable(this);
  late final $ExerciseNotesTable exerciseNotes = $ExerciseNotesTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $FoodsTable foods = $FoodsTable(this);
  late final $DiaryEntriesTable diaryEntries = $DiaryEntriesTable(this);
  late final $WeighInsTable weighIns = $WeighInsTable(this);
  late final $TargetsTable targets = $TargetsTable(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $RecipeItemsTable recipeItems = $RecipeItemsTable(this);
  late final $FoodsFtsTable foodsFts = $FoodsFtsTable(this);
  late final $SearchHistoryTable searchHistory = $SearchHistoryTable(this);
  late final $ConsumptionPatternsTable consumptionPatterns =
      $ConsumptionPatternsTable(this);
  late final $MealTemplatesTable mealTemplates = $MealTemplatesTable(this);
  late final $MealTemplateItemsTable mealTemplateItems =
      $MealTemplateItemsTable(this);
  late final $BodyMeasurementsTable bodyMeasurements = $BodyMeasurementsTable(
    this,
  );
  late final $ProgressPhotosTable progressPhotos = $ProgressPhotosTable(this);
  late final Index sessionExercisesNameIdx = Index(
    'session_exercises_name_idx',
    'CREATE INDEX session_exercises_name_idx ON session_exercises (name)',
  );
  late final Index foodsNameIdx = Index(
    'foods_name_idx',
    'CREATE INDEX foods_name_idx ON foods (name)',
  );
  late final Index foodsBarcodeIdx = Index(
    'foods_barcode_idx',
    'CREATE INDEX foods_barcode_idx ON foods (barcode)',
  );
  late final Index diaryDateIdx = Index(
    'diary_date_idx',
    'CREATE INDEX diary_date_idx ON diary_entries (date)',
  );
  late final Index diaryDateMealIdx = Index(
    'diary_date_meal_idx',
    'CREATE INDEX diary_date_meal_idx ON diary_entries (date, meal_type)',
  );
  late final Index weighinDateIdx = Index(
    'weighin_date_idx',
    'CREATE INDEX weighin_date_idx ON weigh_ins (measured_at)',
  );
  late final Index targetsValidfromIdx = Index(
    'targets_validfrom_idx',
    'CREATE INDEX targets_validfrom_idx ON targets (valid_from)',
  );
  late final Index foodsFtsIdx = Index(
    'foods_fts_idx',
    'CREATE INDEX foods_fts_idx ON foods_fts (name, brand)',
  );
  late final Index searchHistoryQueryIdx = Index(
    'search_history_query_idx',
    'CREATE INDEX search_history_query_idx ON search_history (normalized_query)',
  );
  late final Index searchHistoryDateIdx = Index(
    'search_history_date_idx',
    'CREATE INDEX search_history_date_idx ON search_history (searched_at)',
  );
  late final Index consumptionPatternsUniqueIdx = Index(
    'consumption_patterns_unique_idx',
    'CREATE INDEX consumption_patterns_unique_idx ON consumption_patterns (food_id, hour_of_day, day_of_week)',
  );
  late final Index mealTemplatesNameIdx = Index(
    'meal_templates_name_idx',
    'CREATE INDEX meal_templates_name_idx ON meal_templates (name)',
  );
  late final Index bodyMeasurementsDateIdx = Index(
    'body_measurements_date_idx',
    'CREATE INDEX body_measurements_date_idx ON body_measurements (date)',
  );
  late final Index progressPhotosDateIdx = Index(
    'progress_photos_date_idx',
    'CREATE INDEX progress_photos_date_idx ON progress_photos (date)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    routines,
    routineDays,
    routineExercises,
    sessions,
    sessionExercises,
    workoutSets,
    exerciseNotes,
    userProfiles,
    foods,
    diaryEntries,
    weighIns,
    targets,
    recipes,
    recipeItems,
    foodsFts,
    searchHistory,
    consumptionPatterns,
    mealTemplates,
    mealTemplateItems,
    bodyMeasurements,
    progressPhotos,
    sessionExercisesNameIdx,
    foodsNameIdx,
    foodsBarcodeIdx,
    diaryDateIdx,
    diaryDateMealIdx,
    weighinDateIdx,
    targetsValidfromIdx,
    foodsFtsIdx,
    searchHistoryQueryIdx,
    searchHistoryDateIdx,
    consumptionPatternsUniqueIdx,
    mealTemplatesNameIdx,
    bodyMeasurementsDateIdx,
    progressPhotosDateIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'routines',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('routine_days', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'routine_days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('routine_exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'session_exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_sets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'foods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('diary_entries', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'foods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'foods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('consumption_patterns', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'meal_templates',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('meal_template_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'foods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('meal_template_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'body_measurements',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('progress_photos', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$RoutinesTableCreateCompanionBuilder =
    RoutinesCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      Value<String> schedulingMode,
      Value<String?> schedulingConfig,
      Value<int> rowid,
    });
typedef $$RoutinesTableUpdateCompanionBuilder =
    RoutinesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<String> schedulingMode,
      Value<String?> schedulingConfig,
      Value<int> rowid,
    });

final class $$RoutinesTableReferences
    extends BaseReferences<_$AppDatabase, $RoutinesTable, Routine> {
  $$RoutinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoutineDaysTable, List<RoutineDay>>
  _routineDaysRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.routineDays,
    aliasName: $_aliasNameGenerator(db.routines.id, db.routineDays.routineId),
  );

  $$RoutineDaysTableProcessedTableManager get routineDaysRefs {
    final manager = $$RoutineDaysTableTableManager(
      $_db,
      $_db.routineDays,
    ).filter((f) => f.routineId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_routineDaysRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoutinesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schedulingMode => $composableBuilder(
    column: $table.schedulingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schedulingConfig => $composableBuilder(
    column: $table.schedulingConfig,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> routineDaysRefs(
    Expression<bool> Function($$RoutineDaysTableFilterComposer f) f,
  ) {
    final $$RoutineDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineDays,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineDaysTableFilterComposer(
            $db: $db,
            $table: $db.routineDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutinesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schedulingMode => $composableBuilder(
    column: $table.schedulingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schedulingConfig => $composableBuilder(
    column: $table.schedulingConfig,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoutinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get schedulingMode => $composableBuilder(
    column: $table.schedulingMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get schedulingConfig => $composableBuilder(
    column: $table.schedulingConfig,
    builder: (column) => column,
  );

  Expression<T> routineDaysRefs<T extends Object>(
    Expression<T> Function($$RoutineDaysTableAnnotationComposer a) f,
  ) {
    final $$RoutineDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineDays,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.routineDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutinesTable,
          Routine,
          $$RoutinesTableFilterComposer,
          $$RoutinesTableOrderingComposer,
          $$RoutinesTableAnnotationComposer,
          $$RoutinesTableCreateCompanionBuilder,
          $$RoutinesTableUpdateCompanionBuilder,
          (Routine, $$RoutinesTableReferences),
          Routine,
          PrefetchHooks Function({bool routineDaysRefs})
        > {
  $$RoutinesTableTableManager(_$AppDatabase db, $RoutinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> schedulingMode = const Value.absent(),
                Value<String?> schedulingConfig = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutinesCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                schedulingMode: schedulingMode,
                schedulingConfig: schedulingConfig,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                Value<String> schedulingMode = const Value.absent(),
                Value<String?> schedulingConfig = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutinesCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                schedulingMode: schedulingMode,
                schedulingConfig: schedulingConfig,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RoutinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({routineDaysRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (routineDaysRefs) db.routineDays],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routineDaysRefs)
                    await $_getPrefetchedData<
                      Routine,
                      $RoutinesTable,
                      RoutineDay
                    >(
                      currentTable: table,
                      referencedTable: $$RoutinesTableReferences
                          ._routineDaysRefsTable(db),
                      managerFromTypedResult: (p0) => $$RoutinesTableReferences(
                        db,
                        table,
                        p0,
                      ).routineDaysRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.routineId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RoutinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutinesTable,
      Routine,
      $$RoutinesTableFilterComposer,
      $$RoutinesTableOrderingComposer,
      $$RoutinesTableAnnotationComposer,
      $$RoutinesTableCreateCompanionBuilder,
      $$RoutinesTableUpdateCompanionBuilder,
      (Routine, $$RoutinesTableReferences),
      Routine,
      PrefetchHooks Function({bool routineDaysRefs})
    >;
typedef $$RoutineDaysTableCreateCompanionBuilder =
    RoutineDaysCompanion Function({
      required String id,
      required String routineId,
      required String name,
      Value<String> progressionType,
      required int dayIndex,
      Value<String?> weekdays,
      Value<int?> minRestHours,
      Value<int> rowid,
    });
typedef $$RoutineDaysTableUpdateCompanionBuilder =
    RoutineDaysCompanion Function({
      Value<String> id,
      Value<String> routineId,
      Value<String> name,
      Value<String> progressionType,
      Value<int> dayIndex,
      Value<String?> weekdays,
      Value<int?> minRestHours,
      Value<int> rowid,
    });

final class $$RoutineDaysTableReferences
    extends BaseReferences<_$AppDatabase, $RoutineDaysTable, RoutineDay> {
  $$RoutineDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoutinesTable _routineIdTable(_$AppDatabase db) =>
      db.routines.createAlias(
        $_aliasNameGenerator(db.routineDays.routineId, db.routines.id),
      );

  $$RoutinesTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<String>('routine_id')!;

    final manager = $$RoutinesTableTableManager(
      $_db,
      $_db.routines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RoutineExercisesTable, List<RoutineExercise>>
  _routineExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.routineExercises,
    aliasName: $_aliasNameGenerator(
      db.routineDays.id,
      db.routineExercises.dayId,
    ),
  );

  $$RoutineExercisesTableProcessedTableManager get routineExercisesRefs {
    final manager = $$RoutineExercisesTableTableManager(
      $_db,
      $_db.routineExercises,
    ).filter((f) => f.dayId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _routineExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoutineDaysTableFilterComposer
    extends Composer<_$AppDatabase, $RoutineDaysTable> {
  $$RoutineDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get progressionType => $composableBuilder(
    column: $table.progressionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayIndex => $composableBuilder(
    column: $table.dayIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minRestHours => $composableBuilder(
    column: $table.minRestHours,
    builder: (column) => ColumnFilters(column),
  );

  $$RoutinesTableFilterComposer get routineId {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableFilterComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> routineExercisesRefs(
    Expression<bool> Function($$RoutineExercisesTableFilterComposer f) f,
  ) {
    final $$RoutineExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineExercises,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineExercisesTableFilterComposer(
            $db: $db,
            $table: $db.routineExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutineDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutineDaysTable> {
  $$RoutineDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get progressionType => $composableBuilder(
    column: $table.progressionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayIndex => $composableBuilder(
    column: $table.dayIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekdays => $composableBuilder(
    column: $table.weekdays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minRestHours => $composableBuilder(
    column: $table.minRestHours,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoutinesTableOrderingComposer get routineId {
    final $$RoutinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableOrderingComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutineDaysTable> {
  $$RoutineDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get progressionType => $composableBuilder(
    column: $table.progressionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayIndex =>
      $composableBuilder(column: $table.dayIndex, builder: (column) => column);

  GeneratedColumn<String> get weekdays =>
      $composableBuilder(column: $table.weekdays, builder: (column) => column);

  GeneratedColumn<int> get minRestHours => $composableBuilder(
    column: $table.minRestHours,
    builder: (column) => column,
  );

  $$RoutinesTableAnnotationComposer get routineId {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableAnnotationComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> routineExercisesRefs<T extends Object>(
    Expression<T> Function($$RoutineExercisesTableAnnotationComposer a) f,
  ) {
    final $$RoutineExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineExercises,
      getReferencedColumn: (t) => t.dayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.routineExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutineDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutineDaysTable,
          RoutineDay,
          $$RoutineDaysTableFilterComposer,
          $$RoutineDaysTableOrderingComposer,
          $$RoutineDaysTableAnnotationComposer,
          $$RoutineDaysTableCreateCompanionBuilder,
          $$RoutineDaysTableUpdateCompanionBuilder,
          (RoutineDay, $$RoutineDaysTableReferences),
          RoutineDay,
          PrefetchHooks Function({bool routineId, bool routineExercisesRefs})
        > {
  $$RoutineDaysTableTableManager(_$AppDatabase db, $RoutineDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutineDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutineDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutineDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> routineId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> progressionType = const Value.absent(),
                Value<int> dayIndex = const Value.absent(),
                Value<String?> weekdays = const Value.absent(),
                Value<int?> minRestHours = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutineDaysCompanion(
                id: id,
                routineId: routineId,
                name: name,
                progressionType: progressionType,
                dayIndex: dayIndex,
                weekdays: weekdays,
                minRestHours: minRestHours,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String routineId,
                required String name,
                Value<String> progressionType = const Value.absent(),
                required int dayIndex,
                Value<String?> weekdays = const Value.absent(),
                Value<int?> minRestHours = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutineDaysCompanion.insert(
                id: id,
                routineId: routineId,
                name: name,
                progressionType: progressionType,
                dayIndex: dayIndex,
                weekdays: weekdays,
                minRestHours: minRestHours,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RoutineDaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({routineId = false, routineExercisesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (routineExercisesRefs) db.routineExercises,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (routineId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.routineId,
                                    referencedTable:
                                        $$RoutineDaysTableReferences
                                            ._routineIdTable(db),
                                    referencedColumn:
                                        $$RoutineDaysTableReferences
                                            ._routineIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (routineExercisesRefs)
                        await $_getPrefetchedData<
                          RoutineDay,
                          $RoutineDaysTable,
                          RoutineExercise
                        >(
                          currentTable: table,
                          referencedTable: $$RoutineDaysTableReferences
                              ._routineExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RoutineDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).routineExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RoutineDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutineDaysTable,
      RoutineDay,
      $$RoutineDaysTableFilterComposer,
      $$RoutineDaysTableOrderingComposer,
      $$RoutineDaysTableAnnotationComposer,
      $$RoutineDaysTableCreateCompanionBuilder,
      $$RoutineDaysTableUpdateCompanionBuilder,
      (RoutineDay, $$RoutineDaysTableReferences),
      RoutineDay,
      PrefetchHooks Function({bool routineId, bool routineExercisesRefs})
    >;
typedef $$RoutineExercisesTableCreateCompanionBuilder =
    RoutineExercisesCompanion Function({
      required String id,
      required String dayId,
      required String libraryId,
      required String name,
      Value<String?> description,
      required List<String> musclesPrimary,
      required List<String> musclesSecondary,
      required String equipment,
      Value<String?> localImagePath,
      required int series,
      required String repsRange,
      Value<int?> suggestedRestSeconds,
      Value<String?> notes,
      Value<String?> supersetId,
      required int exerciseIndex,
      Value<String> progressionType,
      Value<double> weightIncrement,
      Value<int?> targetRpe,
      Value<int> rowid,
    });
typedef $$RoutineExercisesTableUpdateCompanionBuilder =
    RoutineExercisesCompanion Function({
      Value<String> id,
      Value<String> dayId,
      Value<String> libraryId,
      Value<String> name,
      Value<String?> description,
      Value<List<String>> musclesPrimary,
      Value<List<String>> musclesSecondary,
      Value<String> equipment,
      Value<String?> localImagePath,
      Value<int> series,
      Value<String> repsRange,
      Value<int?> suggestedRestSeconds,
      Value<String?> notes,
      Value<String?> supersetId,
      Value<int> exerciseIndex,
      Value<String> progressionType,
      Value<double> weightIncrement,
      Value<int?> targetRpe,
      Value<int> rowid,
    });

final class $$RoutineExercisesTableReferences
    extends
        BaseReferences<_$AppDatabase, $RoutineExercisesTable, RoutineExercise> {
  $$RoutineExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RoutineDaysTable _dayIdTable(_$AppDatabase db) =>
      db.routineDays.createAlias(
        $_aliasNameGenerator(db.routineExercises.dayId, db.routineDays.id),
      );

  $$RoutineDaysTableProcessedTableManager get dayId {
    final $_column = $_itemColumn<String>('day_id')!;

    final manager = $$RoutineDaysTableTableManager(
      $_db,
      $_db.routineDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RoutineExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutineExercisesTable> {
  $$RoutineExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get libraryId => $composableBuilder(
    column: $table.libraryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get musclesPrimary => $composableBuilder(
    column: $table.musclesPrimary,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get musclesSecondary => $composableBuilder(
    column: $table.musclesSecondary,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repsRange => $composableBuilder(
    column: $table.repsRange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get suggestedRestSeconds => $composableBuilder(
    column: $table.suggestedRestSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supersetId => $composableBuilder(
    column: $table.supersetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseIndex => $composableBuilder(
    column: $table.exerciseIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get progressionType => $composableBuilder(
    column: $table.progressionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightIncrement => $composableBuilder(
    column: $table.weightIncrement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetRpe => $composableBuilder(
    column: $table.targetRpe,
    builder: (column) => ColumnFilters(column),
  );

  $$RoutineDaysTableFilterComposer get dayId {
    final $$RoutineDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.routineDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineDaysTableFilterComposer(
            $db: $db,
            $table: $db.routineDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutineExercisesTable> {
  $$RoutineExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get libraryId => $composableBuilder(
    column: $table.libraryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musclesPrimary => $composableBuilder(
    column: $table.musclesPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musclesSecondary => $composableBuilder(
    column: $table.musclesSecondary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repsRange => $composableBuilder(
    column: $table.repsRange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get suggestedRestSeconds => $composableBuilder(
    column: $table.suggestedRestSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supersetId => $composableBuilder(
    column: $table.supersetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseIndex => $composableBuilder(
    column: $table.exerciseIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get progressionType => $composableBuilder(
    column: $table.progressionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightIncrement => $composableBuilder(
    column: $table.weightIncrement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetRpe => $composableBuilder(
    column: $table.targetRpe,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoutineDaysTableOrderingComposer get dayId {
    final $$RoutineDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.routineDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineDaysTableOrderingComposer(
            $db: $db,
            $table: $db.routineDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutineExercisesTable> {
  $$RoutineExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get libraryId =>
      $composableBuilder(column: $table.libraryId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get musclesPrimary =>
      $composableBuilder(
        column: $table.musclesPrimary,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<List<String>, String> get musclesSecondary =>
      $composableBuilder(
        column: $table.musclesSecondary,
        builder: (column) => column,
      );

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get localImagePath => $composableBuilder(
    column: $table.localImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get series =>
      $composableBuilder(column: $table.series, builder: (column) => column);

  GeneratedColumn<String> get repsRange =>
      $composableBuilder(column: $table.repsRange, builder: (column) => column);

  GeneratedColumn<int> get suggestedRestSeconds => $composableBuilder(
    column: $table.suggestedRestSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get supersetId => $composableBuilder(
    column: $table.supersetId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exerciseIndex => $composableBuilder(
    column: $table.exerciseIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get progressionType => $composableBuilder(
    column: $table.progressionType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightIncrement => $composableBuilder(
    column: $table.weightIncrement,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetRpe =>
      $composableBuilder(column: $table.targetRpe, builder: (column) => column);

  $$RoutineDaysTableAnnotationComposer get dayId {
    final $$RoutineDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayId,
      referencedTable: $db.routineDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.routineDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutineExercisesTable,
          RoutineExercise,
          $$RoutineExercisesTableFilterComposer,
          $$RoutineExercisesTableOrderingComposer,
          $$RoutineExercisesTableAnnotationComposer,
          $$RoutineExercisesTableCreateCompanionBuilder,
          $$RoutineExercisesTableUpdateCompanionBuilder,
          (RoutineExercise, $$RoutineExercisesTableReferences),
          RoutineExercise,
          PrefetchHooks Function({bool dayId})
        > {
  $$RoutineExercisesTableTableManager(
    _$AppDatabase db,
    $RoutineExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutineExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutineExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutineExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> dayId = const Value.absent(),
                Value<String> libraryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<List<String>> musclesPrimary = const Value.absent(),
                Value<List<String>> musclesSecondary = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<String?> localImagePath = const Value.absent(),
                Value<int> series = const Value.absent(),
                Value<String> repsRange = const Value.absent(),
                Value<int?> suggestedRestSeconds = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> supersetId = const Value.absent(),
                Value<int> exerciseIndex = const Value.absent(),
                Value<String> progressionType = const Value.absent(),
                Value<double> weightIncrement = const Value.absent(),
                Value<int?> targetRpe = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutineExercisesCompanion(
                id: id,
                dayId: dayId,
                libraryId: libraryId,
                name: name,
                description: description,
                musclesPrimary: musclesPrimary,
                musclesSecondary: musclesSecondary,
                equipment: equipment,
                localImagePath: localImagePath,
                series: series,
                repsRange: repsRange,
                suggestedRestSeconds: suggestedRestSeconds,
                notes: notes,
                supersetId: supersetId,
                exerciseIndex: exerciseIndex,
                progressionType: progressionType,
                weightIncrement: weightIncrement,
                targetRpe: targetRpe,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String dayId,
                required String libraryId,
                required String name,
                Value<String?> description = const Value.absent(),
                required List<String> musclesPrimary,
                required List<String> musclesSecondary,
                required String equipment,
                Value<String?> localImagePath = const Value.absent(),
                required int series,
                required String repsRange,
                Value<int?> suggestedRestSeconds = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> supersetId = const Value.absent(),
                required int exerciseIndex,
                Value<String> progressionType = const Value.absent(),
                Value<double> weightIncrement = const Value.absent(),
                Value<int?> targetRpe = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutineExercisesCompanion.insert(
                id: id,
                dayId: dayId,
                libraryId: libraryId,
                name: name,
                description: description,
                musclesPrimary: musclesPrimary,
                musclesSecondary: musclesSecondary,
                equipment: equipment,
                localImagePath: localImagePath,
                series: series,
                repsRange: repsRange,
                suggestedRestSeconds: suggestedRestSeconds,
                notes: notes,
                supersetId: supersetId,
                exerciseIndex: exerciseIndex,
                progressionType: progressionType,
                weightIncrement: weightIncrement,
                targetRpe: targetRpe,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RoutineExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dayId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (dayId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dayId,
                                referencedTable:
                                    $$RoutineExercisesTableReferences
                                        ._dayIdTable(db),
                                referencedColumn:
                                    $$RoutineExercisesTableReferences
                                        ._dayIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RoutineExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutineExercisesTable,
      RoutineExercise,
      $$RoutineExercisesTableFilterComposer,
      $$RoutineExercisesTableOrderingComposer,
      $$RoutineExercisesTableAnnotationComposer,
      $$RoutineExercisesTableCreateCompanionBuilder,
      $$RoutineExercisesTableUpdateCompanionBuilder,
      (RoutineExercise, $$RoutineExercisesTableReferences),
      RoutineExercise,
      PrefetchHooks Function({bool dayId})
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      Value<String?> routineId,
      Value<String?> dayName,
      Value<int?> dayIndex,
      required DateTime startTime,
      Value<int?> durationSeconds,
      Value<bool> isBadDay,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<String?> routineId,
      Value<String?> dayName,
      Value<int?> dayIndex,
      Value<DateTime> startTime,
      Value<int?> durationSeconds,
      Value<bool> isBadDay,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionExercisesTable, List<SessionExercise>>
  _sessionExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionExercises,
    aliasName: $_aliasNameGenerator(
      db.sessions.id,
      db.sessionExercises.sessionId,
    ),
  );

  $$SessionExercisesTableProcessedTableManager get sessionExercisesRefs {
    final manager = $$SessionExercisesTableTableManager(
      $_db,
      $_db.sessionExercises,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayName => $composableBuilder(
    column: $table.dayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayIndex => $composableBuilder(
    column: $table.dayIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBadDay => $composableBuilder(
    column: $table.isBadDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionExercisesRefs(
    Expression<bool> Function($$SessionExercisesTableFilterComposer f) f,
  ) {
    final $$SessionExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableFilterComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayName => $composableBuilder(
    column: $table.dayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayIndex => $composableBuilder(
    column: $table.dayIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBadDay => $composableBuilder(
    column: $table.isBadDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<String> get dayName =>
      $composableBuilder(column: $table.dayName, builder: (column) => column);

  GeneratedColumn<int> get dayIndex =>
      $composableBuilder(column: $table.dayIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBadDay =>
      $composableBuilder(column: $table.isBadDay, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  Expression<T> sessionExercisesRefs<T extends Object>(
    Expression<T> Function($$SessionExercisesTableAnnotationComposer a) f,
  ) {
    final $$SessionExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({bool sessionExercisesRefs})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> routineId = const Value.absent(),
                Value<String?> dayName = const Value.absent(),
                Value<int?> dayIndex = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> isBadDay = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                routineId: routineId,
                dayName: dayName,
                dayIndex: dayIndex,
                startTime: startTime,
                durationSeconds: durationSeconds,
                isBadDay: isBadDay,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> routineId = const Value.absent(),
                Value<String?> dayName = const Value.absent(),
                Value<int?> dayIndex = const Value.absent(),
                required DateTime startTime,
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> isBadDay = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                routineId: routineId,
                dayName: dayName,
                dayIndex: dayIndex,
                startTime: startTime,
                durationSeconds: durationSeconds,
                isBadDay: isBadDay,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sessionExercisesRefs) db.sessionExercises,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionExercisesRefs)
                    await $_getPrefetchedData<
                      Session,
                      $SessionsTable,
                      SessionExercise
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._sessionExercisesRefsTable(db),
                      managerFromTypedResult: (p0) => $$SessionsTableReferences(
                        db,
                        table,
                        p0,
                      ).sessionExercisesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({bool sessionExercisesRefs})
    >;
typedef $$SessionExercisesTableCreateCompanionBuilder =
    SessionExercisesCompanion Function({
      required String id,
      required String sessionId,
      Value<String?> libraryId,
      required String name,
      required List<String> musclesPrimary,
      required List<String> musclesSecondary,
      Value<String?> equipment,
      Value<String?> notes,
      required int exerciseIndex,
      Value<bool> isTarget,
      Value<int> rowid,
    });
typedef $$SessionExercisesTableUpdateCompanionBuilder =
    SessionExercisesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String?> libraryId,
      Value<String> name,
      Value<List<String>> musclesPrimary,
      Value<List<String>> musclesSecondary,
      Value<String?> equipment,
      Value<String?> notes,
      Value<int> exerciseIndex,
      Value<bool> isTarget,
      Value<int> rowid,
    });

final class $$SessionExercisesTableReferences
    extends
        BaseReferences<_$AppDatabase, $SessionExercisesTable, SessionExercise> {
  $$SessionExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.sessionExercises.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>>
  _workoutSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutSets,
    aliasName: $_aliasNameGenerator(
      db.sessionExercises.id,
      db.workoutSets.sessionExerciseId,
    ),
  );

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager($_db, $_db.workoutSets)
        .filter(
          (f) => f.sessionExerciseId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get libraryId => $composableBuilder(
    column: $table.libraryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get musclesPrimary => $composableBuilder(
    column: $table.musclesPrimary,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get musclesSecondary => $composableBuilder(
    column: $table.musclesSecondary,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseIndex => $composableBuilder(
    column: $table.exerciseIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTarget => $composableBuilder(
    column: $table.isTarget,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workoutSetsRefs(
    Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f,
  ) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.sessionExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get libraryId => $composableBuilder(
    column: $table.libraryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musclesPrimary => $composableBuilder(
    column: $table.musclesPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musclesSecondary => $composableBuilder(
    column: $table.musclesSecondary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseIndex => $composableBuilder(
    column: $table.exerciseIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTarget => $composableBuilder(
    column: $table.isTarget,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get libraryId =>
      $composableBuilder(column: $table.libraryId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get musclesPrimary =>
      $composableBuilder(
        column: $table.musclesPrimary,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<List<String>, String> get musclesSecondary =>
      $composableBuilder(
        column: $table.musclesSecondary,
        builder: (column) => column,
      );

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get exerciseIndex => $composableBuilder(
    column: $table.exerciseIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTarget =>
      $composableBuilder(column: $table.isTarget, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> workoutSetsRefs<T extends Object>(
    Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.sessionExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionExercisesTable,
          SessionExercise,
          $$SessionExercisesTableFilterComposer,
          $$SessionExercisesTableOrderingComposer,
          $$SessionExercisesTableAnnotationComposer,
          $$SessionExercisesTableCreateCompanionBuilder,
          $$SessionExercisesTableUpdateCompanionBuilder,
          (SessionExercise, $$SessionExercisesTableReferences),
          SessionExercise,
          PrefetchHooks Function({bool sessionId, bool workoutSetsRefs})
        > {
  $$SessionExercisesTableTableManager(
    _$AppDatabase db,
    $SessionExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String?> libraryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<List<String>> musclesPrimary = const Value.absent(),
                Value<List<String>> musclesSecondary = const Value.absent(),
                Value<String?> equipment = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> exerciseIndex = const Value.absent(),
                Value<bool> isTarget = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionExercisesCompanion(
                id: id,
                sessionId: sessionId,
                libraryId: libraryId,
                name: name,
                musclesPrimary: musclesPrimary,
                musclesSecondary: musclesSecondary,
                equipment: equipment,
                notes: notes,
                exerciseIndex: exerciseIndex,
                isTarget: isTarget,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                Value<String?> libraryId = const Value.absent(),
                required String name,
                required List<String> musclesPrimary,
                required List<String> musclesSecondary,
                Value<String?> equipment = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int exerciseIndex,
                Value<bool> isTarget = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionExercisesCompanion.insert(
                id: id,
                sessionId: sessionId,
                libraryId: libraryId,
                name: name,
                musclesPrimary: musclesPrimary,
                musclesSecondary: musclesSecondary,
                equipment: equipment,
                notes: notes,
                exerciseIndex: exerciseIndex,
                isTarget: isTarget,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sessionId = false, workoutSetsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workoutSetsRefs) db.workoutSets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sessionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sessionId,
                                    referencedTable:
                                        $$SessionExercisesTableReferences
                                            ._sessionIdTable(db),
                                    referencedColumn:
                                        $$SessionExercisesTableReferences
                                            ._sessionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workoutSetsRefs)
                        await $_getPrefetchedData<
                          SessionExercise,
                          $SessionExercisesTable,
                          WorkoutSet
                        >(
                          currentTable: table,
                          referencedTable: $$SessionExercisesTableReferences
                              ._workoutSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionExerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionExercisesTable,
      SessionExercise,
      $$SessionExercisesTableFilterComposer,
      $$SessionExercisesTableOrderingComposer,
      $$SessionExercisesTableAnnotationComposer,
      $$SessionExercisesTableCreateCompanionBuilder,
      $$SessionExercisesTableUpdateCompanionBuilder,
      (SessionExercise, $$SessionExercisesTableReferences),
      SessionExercise,
      PrefetchHooks Function({bool sessionId, bool workoutSetsRefs})
    >;
typedef $$WorkoutSetsTableCreateCompanionBuilder =
    WorkoutSetsCompanion Function({
      required String id,
      required String sessionExerciseId,
      required int setIndex,
      required double weight,
      required int reps,
      Value<bool> completed,
      Value<int?> rpe,
      Value<String?> notes,
      Value<int?> restSeconds,
      Value<bool> isFailure,
      Value<bool> isDropset,
      Value<bool> isRestPause,
      Value<bool> isWarmup,
      Value<int> rowid,
    });
typedef $$WorkoutSetsTableUpdateCompanionBuilder =
    WorkoutSetsCompanion Function({
      Value<String> id,
      Value<String> sessionExerciseId,
      Value<int> setIndex,
      Value<double> weight,
      Value<int> reps,
      Value<bool> completed,
      Value<int?> rpe,
      Value<String?> notes,
      Value<int?> restSeconds,
      Value<bool> isFailure,
      Value<bool> isDropset,
      Value<bool> isRestPause,
      Value<bool> isWarmup,
      Value<int> rowid,
    });

final class $$WorkoutSetsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutSetsTable, WorkoutSet> {
  $$WorkoutSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionExercisesTable _sessionExerciseIdTable(_$AppDatabase db) =>
      db.sessionExercises.createAlias(
        $_aliasNameGenerator(
          db.workoutSets.sessionExerciseId,
          db.sessionExercises.id,
        ),
      );

  $$SessionExercisesTableProcessedTableManager get sessionExerciseId {
    final $_column = $_itemColumn<String>('session_exercise_id')!;

    final manager = $$SessionExercisesTableTableManager(
      $_db,
      $_db.sessionExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkoutSetsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFailure => $composableBuilder(
    column: $table.isFailure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDropset => $composableBuilder(
    column: $table.isDropset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRestPause => $composableBuilder(
    column: $table.isRestPause,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionExercisesTableFilterComposer get sessionExerciseId {
    final $$SessionExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionExerciseId,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableFilterComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFailure => $composableBuilder(
    column: $table.isFailure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDropset => $composableBuilder(
    column: $table.isDropset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRestPause => $composableBuilder(
    column: $table.isRestPause,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionExercisesTableOrderingComposer get sessionExerciseId {
    final $$SessionExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionExerciseId,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFailure =>
      $composableBuilder(column: $table.isFailure, builder: (column) => column);

  GeneratedColumn<bool> get isDropset =>
      $composableBuilder(column: $table.isDropset, builder: (column) => column);

  GeneratedColumn<bool> get isRestPause => $composableBuilder(
    column: $table.isRestPause,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isWarmup =>
      $composableBuilder(column: $table.isWarmup, builder: (column) => column);

  $$SessionExercisesTableAnnotationComposer get sessionExerciseId {
    final $$SessionExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionExerciseId,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSetsTable,
          WorkoutSet,
          $$WorkoutSetsTableFilterComposer,
          $$WorkoutSetsTableOrderingComposer,
          $$WorkoutSetsTableAnnotationComposer,
          $$WorkoutSetsTableCreateCompanionBuilder,
          $$WorkoutSetsTableUpdateCompanionBuilder,
          (WorkoutSet, $$WorkoutSetsTableReferences),
          WorkoutSet,
          PrefetchHooks Function({bool sessionExerciseId})
        > {
  $$WorkoutSetsTableTableManager(_$AppDatabase db, $WorkoutSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionExerciseId = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int?> rpe = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> restSeconds = const Value.absent(),
                Value<bool> isFailure = const Value.absent(),
                Value<bool> isDropset = const Value.absent(),
                Value<bool> isRestPause = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSetsCompanion(
                id: id,
                sessionExerciseId: sessionExerciseId,
                setIndex: setIndex,
                weight: weight,
                reps: reps,
                completed: completed,
                rpe: rpe,
                notes: notes,
                restSeconds: restSeconds,
                isFailure: isFailure,
                isDropset: isDropset,
                isRestPause: isRestPause,
                isWarmup: isWarmup,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionExerciseId,
                required int setIndex,
                required double weight,
                required int reps,
                Value<bool> completed = const Value.absent(),
                Value<int?> rpe = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> restSeconds = const Value.absent(),
                Value<bool> isFailure = const Value.absent(),
                Value<bool> isDropset = const Value.absent(),
                Value<bool> isRestPause = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSetsCompanion.insert(
                id: id,
                sessionExerciseId: sessionExerciseId,
                setIndex: setIndex,
                weight: weight,
                reps: reps,
                completed: completed,
                rpe: rpe,
                notes: notes,
                restSeconds: restSeconds,
                isFailure: isFailure,
                isDropset: isDropset,
                isRestPause: isRestPause,
                isWarmup: isWarmup,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionExerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionExerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionExerciseId,
                                referencedTable: $$WorkoutSetsTableReferences
                                    ._sessionExerciseIdTable(db),
                                referencedColumn: $$WorkoutSetsTableReferences
                                    ._sessionExerciseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSetsTable,
      WorkoutSet,
      $$WorkoutSetsTableFilterComposer,
      $$WorkoutSetsTableOrderingComposer,
      $$WorkoutSetsTableAnnotationComposer,
      $$WorkoutSetsTableCreateCompanionBuilder,
      $$WorkoutSetsTableUpdateCompanionBuilder,
      (WorkoutSet, $$WorkoutSetsTableReferences),
      WorkoutSet,
      PrefetchHooks Function({bool sessionExerciseId})
    >;
typedef $$ExerciseNotesTableCreateCompanionBuilder =
    ExerciseNotesCompanion Function({
      required String exerciseName,
      required String note,
      Value<int> rowid,
    });
typedef $$ExerciseNotesTableUpdateCompanionBuilder =
    ExerciseNotesCompanion Function({
      Value<String> exerciseName,
      Value<String> note,
      Value<int> rowid,
    });

class $$ExerciseNotesTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseNotesTable> {
  $$ExerciseNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseNotesTable> {
  $$ExerciseNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseNotesTable> {
  $$ExerciseNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$ExerciseNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseNotesTable,
          ExerciseNote,
          $$ExerciseNotesTableFilterComposer,
          $$ExerciseNotesTableOrderingComposer,
          $$ExerciseNotesTableAnnotationComposer,
          $$ExerciseNotesTableCreateCompanionBuilder,
          $$ExerciseNotesTableUpdateCompanionBuilder,
          (
            ExerciseNote,
            BaseReferences<_$AppDatabase, $ExerciseNotesTable, ExerciseNote>,
          ),
          ExerciseNote,
          PrefetchHooks Function()
        > {
  $$ExerciseNotesTableTableManager(_$AppDatabase db, $ExerciseNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> exerciseName = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseNotesCompanion(
                exerciseName: exerciseName,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String exerciseName,
                required String note,
                Value<int> rowid = const Value.absent(),
              }) => ExerciseNotesCompanion.insert(
                exerciseName: exerciseName,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseNotesTable,
      ExerciseNote,
      $$ExerciseNotesTableFilterComposer,
      $$ExerciseNotesTableOrderingComposer,
      $$ExerciseNotesTableAnnotationComposer,
      $$ExerciseNotesTableCreateCompanionBuilder,
      $$ExerciseNotesTableUpdateCompanionBuilder,
      (
        ExerciseNote,
        BaseReferences<_$AppDatabase, $ExerciseNotesTable, ExerciseNote>,
      ),
      ExerciseNote,
      PrefetchHooks Function()
    >;
typedef $$UserProfilesTableCreateCompanionBuilder =
    UserProfilesCompanion Function({
      required String id,
      Value<int?> age,
      Value<String?> gender,
      Value<double?> heightCm,
      Value<double?> currentWeightKg,
      Value<String> activityLevel,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$UserProfilesTableUpdateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<String> id,
      Value<int?> age,
      Value<String?> gender,
      Value<double?> heightCm,
      Value<double?> currentWeightKg,
      Value<String> activityLevel,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentWeightKg => $composableBuilder(
    column: $table.currentWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentWeightKg => $composableBuilder(
    column: $table.currentWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get currentWeightKg => $composableBuilder(
    column: $table.currentWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfilesTable,
          UserProfile,
          $$UserProfilesTableFilterComposer,
          $$UserProfilesTableOrderingComposer,
          $$UserProfilesTableAnnotationComposer,
          $$UserProfilesTableCreateCompanionBuilder,
          $$UserProfilesTableUpdateCompanionBuilder,
          (
            UserProfile,
            BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>,
          ),
          UserProfile,
          PrefetchHooks Function()
        > {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int?> age = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> currentWeightKg = const Value.absent(),
                Value<String> activityLevel = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfilesCompanion(
                id: id,
                age: age,
                gender: gender,
                heightCm: heightCm,
                currentWeightKg: currentWeightKg,
                activityLevel: activityLevel,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int?> age = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> currentWeightKg = const Value.absent(),
                Value<String> activityLevel = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserProfilesCompanion.insert(
                id: id,
                age: age,
                gender: gender,
                heightCm: heightCm,
                currentWeightKg: currentWeightKg,
                activityLevel: activityLevel,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfilesTable,
      UserProfile,
      $$UserProfilesTableFilterComposer,
      $$UserProfilesTableOrderingComposer,
      $$UserProfilesTableAnnotationComposer,
      $$UserProfilesTableCreateCompanionBuilder,
      $$UserProfilesTableUpdateCompanionBuilder,
      (
        UserProfile,
        BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>,
      ),
      UserProfile,
      PrefetchHooks Function()
    >;
typedef $$FoodsTableCreateCompanionBuilder =
    FoodsCompanion Function({
      required String id,
      required String name,
      Value<String?> brand,
      Value<String?> barcode,
      required int kcalPer100g,
      Value<double?> proteinPer100g,
      Value<double?> carbsPer100g,
      Value<double?> fatPer100g,
      Value<String?> portionName,
      Value<double?> portionGrams,
      Value<bool> userCreated,
      Value<String?> verifiedSource,
      Value<Map<String, dynamic>?> sourceMetadata,
      Value<String?> normalizedName,
      Value<int> useCount,
      Value<DateTime?> lastUsedAt,
      Value<String?> nutriScore,
      Value<int?> novaGroup,
      Value<bool> isFavorite,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FoodsTableUpdateCompanionBuilder =
    FoodsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> brand,
      Value<String?> barcode,
      Value<int> kcalPer100g,
      Value<double?> proteinPer100g,
      Value<double?> carbsPer100g,
      Value<double?> fatPer100g,
      Value<String?> portionName,
      Value<double?> portionGrams,
      Value<bool> userCreated,
      Value<String?> verifiedSource,
      Value<Map<String, dynamic>?> sourceMetadata,
      Value<String?> normalizedName,
      Value<int> useCount,
      Value<DateTime?> lastUsedAt,
      Value<String?> nutriScore,
      Value<int?> novaGroup,
      Value<bool> isFavorite,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FoodsTableReferences
    extends BaseReferences<_$AppDatabase, $FoodsTable, Food> {
  $$FoodsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DiaryEntriesTable, List<DiaryEntry>>
  _diaryEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.diaryEntries,
    aliasName: $_aliasNameGenerator(db.foods.id, db.diaryEntries.foodId),
  );

  $$DiaryEntriesTableProcessedTableManager get diaryEntriesRefs {
    final manager = $$DiaryEntriesTableTableManager(
      $_db,
      $_db.diaryEntries,
    ).filter((f) => f.foodId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_diaryEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecipeItemsTable, List<RecipeItem>>
  _recipeItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recipeItems,
    aliasName: $_aliasNameGenerator(db.foods.id, db.recipeItems.foodId),
  );

  $$RecipeItemsTableProcessedTableManager get recipeItemsRefs {
    final manager = $$RecipeItemsTableTableManager(
      $_db,
      $_db.recipeItems,
    ).filter((f) => f.foodId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ConsumptionPatternsTable,
    List<ConsumptionPattern>
  >
  _consumptionPatternsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.consumptionPatterns,
        aliasName: $_aliasNameGenerator(
          db.foods.id,
          db.consumptionPatterns.foodId,
        ),
      );

  $$ConsumptionPatternsTableProcessedTableManager get consumptionPatternsRefs {
    final manager = $$ConsumptionPatternsTableTableManager(
      $_db,
      $_db.consumptionPatterns,
    ).filter((f) => f.foodId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _consumptionPatternsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MealTemplateItemsTable, List<MealTemplateItem>>
  _mealTemplateItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.mealTemplateItems,
        aliasName: $_aliasNameGenerator(
          db.foods.id,
          db.mealTemplateItems.foodId,
        ),
      );

  $$MealTemplateItemsTableProcessedTableManager get mealTemplateItemsRefs {
    final manager = $$MealTemplateItemsTableTableManager(
      $_db,
      $_db.mealTemplateItems,
    ).filter((f) => f.foodId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _mealTemplateItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FoodsTableFilterComposer extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kcalPer100g => $composableBuilder(
    column: $table.kcalPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portionName => $composableBuilder(
    column: $table.portionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get portionGrams => $composableBuilder(
    column: $table.portionGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get userCreated => $composableBuilder(
    column: $table.userCreated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verifiedSource => $composableBuilder(
    column: $table.verifiedSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, dynamic>?,
    Map<String, dynamic>,
    String
  >
  get sourceMetadata => $composableBuilder(
    column: $table.sourceMetadata,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nutriScore => $composableBuilder(
    column: $table.nutriScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get novaGroup => $composableBuilder(
    column: $table.novaGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> diaryEntriesRefs(
    Expression<bool> Function($$DiaryEntriesTableFilterComposer f) f,
  ) {
    final $$DiaryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diaryEntries,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiaryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.diaryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recipeItemsRefs(
    Expression<bool> Function($$RecipeItemsTableFilterComposer f) f,
  ) {
    final $$RecipeItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeItems,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeItemsTableFilterComposer(
            $db: $db,
            $table: $db.recipeItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> consumptionPatternsRefs(
    Expression<bool> Function($$ConsumptionPatternsTableFilterComposer f) f,
  ) {
    final $$ConsumptionPatternsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.consumptionPatterns,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConsumptionPatternsTableFilterComposer(
            $db: $db,
            $table: $db.consumptionPatterns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mealTemplateItemsRefs(
    Expression<bool> Function($$MealTemplateItemsTableFilterComposer f) f,
  ) {
    final $$MealTemplateItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealTemplateItems,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealTemplateItemsTableFilterComposer(
            $db: $db,
            $table: $db.mealTemplateItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kcalPer100g => $composableBuilder(
    column: $table.kcalPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portionName => $composableBuilder(
    column: $table.portionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get portionGrams => $composableBuilder(
    column: $table.portionGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userCreated => $composableBuilder(
    column: $table.userCreated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verifiedSource => $composableBuilder(
    column: $table.verifiedSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceMetadata => $composableBuilder(
    column: $table.sourceMetadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nutriScore => $composableBuilder(
    column: $table.nutriScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get novaGroup => $composableBuilder(
    column: $table.novaGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<int> get kcalPer100g => $composableBuilder(
    column: $table.kcalPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<String> get portionName => $composableBuilder(
    column: $table.portionName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get portionGrams => $composableBuilder(
    column: $table.portionGrams,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get userCreated => $composableBuilder(
    column: $table.userCreated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verifiedSource => $composableBuilder(
    column: $table.verifiedSource,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Map<String, dynamic>?, String>
  get sourceMetadata => $composableBuilder(
    column: $table.sourceMetadata,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nutriScore => $composableBuilder(
    column: $table.nutriScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get novaGroup =>
      $composableBuilder(column: $table.novaGroup, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> diaryEntriesRefs<T extends Object>(
    Expression<T> Function($$DiaryEntriesTableAnnotationComposer a) f,
  ) {
    final $$DiaryEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diaryEntries,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiaryEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.diaryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recipeItemsRefs<T extends Object>(
    Expression<T> Function($$RecipeItemsTableAnnotationComposer a) f,
  ) {
    final $$RecipeItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeItems,
      getReferencedColumn: (t) => t.foodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.recipeItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> consumptionPatternsRefs<T extends Object>(
    Expression<T> Function($$ConsumptionPatternsTableAnnotationComposer a) f,
  ) {
    final $$ConsumptionPatternsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.consumptionPatterns,
          getReferencedColumn: (t) => t.foodId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConsumptionPatternsTableAnnotationComposer(
                $db: $db,
                $table: $db.consumptionPatterns,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> mealTemplateItemsRefs<T extends Object>(
    Expression<T> Function($$MealTemplateItemsTableAnnotationComposer a) f,
  ) {
    final $$MealTemplateItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.mealTemplateItems,
          getReferencedColumn: (t) => t.foodId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MealTemplateItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.mealTemplateItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FoodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodsTable,
          Food,
          $$FoodsTableFilterComposer,
          $$FoodsTableOrderingComposer,
          $$FoodsTableAnnotationComposer,
          $$FoodsTableCreateCompanionBuilder,
          $$FoodsTableUpdateCompanionBuilder,
          (Food, $$FoodsTableReferences),
          Food,
          PrefetchHooks Function({
            bool diaryEntriesRefs,
            bool recipeItemsRefs,
            bool consumptionPatternsRefs,
            bool mealTemplateItemsRefs,
          })
        > {
  $$FoodsTableTableManager(_$AppDatabase db, $FoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<int> kcalPer100g = const Value.absent(),
                Value<double?> proteinPer100g = const Value.absent(),
                Value<double?> carbsPer100g = const Value.absent(),
                Value<double?> fatPer100g = const Value.absent(),
                Value<String?> portionName = const Value.absent(),
                Value<double?> portionGrams = const Value.absent(),
                Value<bool> userCreated = const Value.absent(),
                Value<String?> verifiedSource = const Value.absent(),
                Value<Map<String, dynamic>?> sourceMetadata =
                    const Value.absent(),
                Value<String?> normalizedName = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<String?> nutriScore = const Value.absent(),
                Value<int?> novaGroup = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodsCompanion(
                id: id,
                name: name,
                brand: brand,
                barcode: barcode,
                kcalPer100g: kcalPer100g,
                proteinPer100g: proteinPer100g,
                carbsPer100g: carbsPer100g,
                fatPer100g: fatPer100g,
                portionName: portionName,
                portionGrams: portionGrams,
                userCreated: userCreated,
                verifiedSource: verifiedSource,
                sourceMetadata: sourceMetadata,
                normalizedName: normalizedName,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                nutriScore: nutriScore,
                novaGroup: novaGroup,
                isFavorite: isFavorite,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                required int kcalPer100g,
                Value<double?> proteinPer100g = const Value.absent(),
                Value<double?> carbsPer100g = const Value.absent(),
                Value<double?> fatPer100g = const Value.absent(),
                Value<String?> portionName = const Value.absent(),
                Value<double?> portionGrams = const Value.absent(),
                Value<bool> userCreated = const Value.absent(),
                Value<String?> verifiedSource = const Value.absent(),
                Value<Map<String, dynamic>?> sourceMetadata =
                    const Value.absent(),
                Value<String?> normalizedName = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<String?> nutriScore = const Value.absent(),
                Value<int?> novaGroup = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FoodsCompanion.insert(
                id: id,
                name: name,
                brand: brand,
                barcode: barcode,
                kcalPer100g: kcalPer100g,
                proteinPer100g: proteinPer100g,
                carbsPer100g: carbsPer100g,
                fatPer100g: fatPer100g,
                portionName: portionName,
                portionGrams: portionGrams,
                userCreated: userCreated,
                verifiedSource: verifiedSource,
                sourceMetadata: sourceMetadata,
                normalizedName: normalizedName,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                nutriScore: nutriScore,
                novaGroup: novaGroup,
                isFavorite: isFavorite,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$FoodsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                diaryEntriesRefs = false,
                recipeItemsRefs = false,
                consumptionPatternsRefs = false,
                mealTemplateItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (diaryEntriesRefs) db.diaryEntries,
                    if (recipeItemsRefs) db.recipeItems,
                    if (consumptionPatternsRefs) db.consumptionPatterns,
                    if (mealTemplateItemsRefs) db.mealTemplateItems,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (diaryEntriesRefs)
                        await $_getPrefetchedData<
                          Food,
                          $FoodsTable,
                          DiaryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$FoodsTableReferences
                              ._diaryEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FoodsTableReferences(
                                db,
                                table,
                                p0,
                              ).diaryEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.foodId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recipeItemsRefs)
                        await $_getPrefetchedData<
                          Food,
                          $FoodsTable,
                          RecipeItem
                        >(
                          currentTable: table,
                          referencedTable: $$FoodsTableReferences
                              ._recipeItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FoodsTableReferences(
                                db,
                                table,
                                p0,
                              ).recipeItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.foodId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (consumptionPatternsRefs)
                        await $_getPrefetchedData<
                          Food,
                          $FoodsTable,
                          ConsumptionPattern
                        >(
                          currentTable: table,
                          referencedTable: $$FoodsTableReferences
                              ._consumptionPatternsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FoodsTableReferences(
                                db,
                                table,
                                p0,
                              ).consumptionPatternsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.foodId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (mealTemplateItemsRefs)
                        await $_getPrefetchedData<
                          Food,
                          $FoodsTable,
                          MealTemplateItem
                        >(
                          currentTable: table,
                          referencedTable: $$FoodsTableReferences
                              ._mealTemplateItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FoodsTableReferences(
                                db,
                                table,
                                p0,
                              ).mealTemplateItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.foodId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodsTable,
      Food,
      $$FoodsTableFilterComposer,
      $$FoodsTableOrderingComposer,
      $$FoodsTableAnnotationComposer,
      $$FoodsTableCreateCompanionBuilder,
      $$FoodsTableUpdateCompanionBuilder,
      (Food, $$FoodsTableReferences),
      Food,
      PrefetchHooks Function({
        bool diaryEntriesRefs,
        bool recipeItemsRefs,
        bool consumptionPatternsRefs,
        bool mealTemplateItemsRefs,
      })
    >;
typedef $$DiaryEntriesTableCreateCompanionBuilder =
    DiaryEntriesCompanion Function({
      required String id,
      required DateTime date,
      required MealType mealType,
      Value<String?> foodId,
      required String foodName,
      Value<String?> foodBrand,
      required double amount,
      required ServingUnit unit,
      required int kcal,
      Value<double?> protein,
      Value<double?> carbs,
      Value<double?> fat,
      Value<bool> isQuickAdd,
      Value<String?> notes,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DiaryEntriesTableUpdateCompanionBuilder =
    DiaryEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<MealType> mealType,
      Value<String?> foodId,
      Value<String> foodName,
      Value<String?> foodBrand,
      Value<double> amount,
      Value<ServingUnit> unit,
      Value<int> kcal,
      Value<double?> protein,
      Value<double?> carbs,
      Value<double?> fat,
      Value<bool> isQuickAdd,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$DiaryEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $DiaryEntriesTable, DiaryEntry> {
  $$DiaryEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoodsTable _foodIdTable(_$AppDatabase db) => db.foods.createAlias(
    $_aliasNameGenerator(db.diaryEntries.foodId, db.foods.id),
  );

  $$FoodsTableProcessedTableManager? get foodId {
    final $_column = $_itemColumn<String>('food_id');
    if ($_column == null) return null;
    final manager = $$FoodsTableTableManager(
      $_db,
      $_db.foods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_foodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DiaryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MealType, MealType, String> get mealType =>
      $composableBuilder(
        column: $table.mealType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get foodName => $composableBuilder(
    column: $table.foodName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodBrand => $composableBuilder(
    column: $table.foodBrand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ServingUnit, ServingUnit, String> get unit =>
      $composableBuilder(
        column: $table.unit,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isQuickAdd => $composableBuilder(
    column: $table.isQuickAdd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FoodsTableFilterComposer get foodId {
    final $$FoodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableFilterComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiaryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodName => $composableBuilder(
    column: $table.foodName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodBrand => $composableBuilder(
    column: $table.foodBrand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isQuickAdd => $composableBuilder(
    column: $table.isQuickAdd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoodsTableOrderingComposer get foodId {
    final $$FoodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableOrderingComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiaryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MealType, String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<String> get foodName =>
      $composableBuilder(column: $table.foodName, builder: (column) => column);

  GeneratedColumn<String> get foodBrand =>
      $composableBuilder(column: $table.foodBrand, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ServingUnit, String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<double> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);

  GeneratedColumn<bool> get isQuickAdd => $composableBuilder(
    column: $table.isQuickAdd,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FoodsTableAnnotationComposer get foodId {
    final $$FoodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableAnnotationComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiaryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiaryEntriesTable,
          DiaryEntry,
          $$DiaryEntriesTableFilterComposer,
          $$DiaryEntriesTableOrderingComposer,
          $$DiaryEntriesTableAnnotationComposer,
          $$DiaryEntriesTableCreateCompanionBuilder,
          $$DiaryEntriesTableUpdateCompanionBuilder,
          (DiaryEntry, $$DiaryEntriesTableReferences),
          DiaryEntry,
          PrefetchHooks Function({bool foodId})
        > {
  $$DiaryEntriesTableTableManager(_$AppDatabase db, $DiaryEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiaryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiaryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiaryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<MealType> mealType = const Value.absent(),
                Value<String?> foodId = const Value.absent(),
                Value<String> foodName = const Value.absent(),
                Value<String?> foodBrand = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<ServingUnit> unit = const Value.absent(),
                Value<int> kcal = const Value.absent(),
                Value<double?> protein = const Value.absent(),
                Value<double?> carbs = const Value.absent(),
                Value<double?> fat = const Value.absent(),
                Value<bool> isQuickAdd = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiaryEntriesCompanion(
                id: id,
                date: date,
                mealType: mealType,
                foodId: foodId,
                foodName: foodName,
                foodBrand: foodBrand,
                amount: amount,
                unit: unit,
                kcal: kcal,
                protein: protein,
                carbs: carbs,
                fat: fat,
                isQuickAdd: isQuickAdd,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                required MealType mealType,
                Value<String?> foodId = const Value.absent(),
                required String foodName,
                Value<String?> foodBrand = const Value.absent(),
                required double amount,
                required ServingUnit unit,
                required int kcal,
                Value<double?> protein = const Value.absent(),
                Value<double?> carbs = const Value.absent(),
                Value<double?> fat = const Value.absent(),
                Value<bool> isQuickAdd = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DiaryEntriesCompanion.insert(
                id: id,
                date: date,
                mealType: mealType,
                foodId: foodId,
                foodName: foodName,
                foodBrand: foodBrand,
                amount: amount,
                unit: unit,
                kcal: kcal,
                protein: protein,
                carbs: carbs,
                fat: fat,
                isQuickAdd: isQuickAdd,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DiaryEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({foodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (foodId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.foodId,
                                referencedTable: $$DiaryEntriesTableReferences
                                    ._foodIdTable(db),
                                referencedColumn: $$DiaryEntriesTableReferences
                                    ._foodIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DiaryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiaryEntriesTable,
      DiaryEntry,
      $$DiaryEntriesTableFilterComposer,
      $$DiaryEntriesTableOrderingComposer,
      $$DiaryEntriesTableAnnotationComposer,
      $$DiaryEntriesTableCreateCompanionBuilder,
      $$DiaryEntriesTableUpdateCompanionBuilder,
      (DiaryEntry, $$DiaryEntriesTableReferences),
      DiaryEntry,
      PrefetchHooks Function({bool foodId})
    >;
typedef $$WeighInsTableCreateCompanionBuilder =
    WeighInsCompanion Function({
      required String id,
      required DateTime measuredAt,
      required double weightKg,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$WeighInsTableUpdateCompanionBuilder =
    WeighInsCompanion Function({
      Value<String> id,
      Value<DateTime> measuredAt,
      Value<double> weightKg,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$WeighInsTableFilterComposer
    extends Composer<_$AppDatabase, $WeighInsTable> {
  $$WeighInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeighInsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeighInsTable> {
  $$WeighInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeighInsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeighInsTable> {
  $$WeighInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WeighInsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeighInsTable,
          WeighIn,
          $$WeighInsTableFilterComposer,
          $$WeighInsTableOrderingComposer,
          $$WeighInsTableAnnotationComposer,
          $$WeighInsTableCreateCompanionBuilder,
          $$WeighInsTableUpdateCompanionBuilder,
          (WeighIn, BaseReferences<_$AppDatabase, $WeighInsTable, WeighIn>),
          WeighIn,
          PrefetchHooks Function()
        > {
  $$WeighInsTableTableManager(_$AppDatabase db, $WeighInsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeighInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeighInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeighInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> measuredAt = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeighInsCompanion(
                id: id,
                measuredAt: measuredAt,
                weightKg: weightKg,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime measuredAt,
                required double weightKg,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => WeighInsCompanion.insert(
                id: id,
                measuredAt: measuredAt,
                weightKg: weightKg,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeighInsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeighInsTable,
      WeighIn,
      $$WeighInsTableFilterComposer,
      $$WeighInsTableOrderingComposer,
      $$WeighInsTableAnnotationComposer,
      $$WeighInsTableCreateCompanionBuilder,
      $$WeighInsTableUpdateCompanionBuilder,
      (WeighIn, BaseReferences<_$AppDatabase, $WeighInsTable, WeighIn>),
      WeighIn,
      PrefetchHooks Function()
    >;
typedef $$TargetsTableCreateCompanionBuilder =
    TargetsCompanion Function({
      required String id,
      required DateTime validFrom,
      required int kcalTarget,
      Value<double?> proteinTarget,
      Value<double?> carbsTarget,
      Value<double?> fatTarget,
      Value<String?> notes,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TargetsTableUpdateCompanionBuilder =
    TargetsCompanion Function({
      Value<String> id,
      Value<DateTime> validFrom,
      Value<int> kcalTarget,
      Value<double?> proteinTarget,
      Value<double?> carbsTarget,
      Value<double?> fatTarget,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$TargetsTableFilterComposer
    extends Composer<_$AppDatabase, $TargetsTable> {
  $$TargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kcalTarget => $composableBuilder(
    column: $table.kcalTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinTarget => $composableBuilder(
    column: $table.proteinTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsTarget => $composableBuilder(
    column: $table.carbsTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatTarget => $composableBuilder(
    column: $table.fatTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TargetsTableOrderingComposer
    extends Composer<_$AppDatabase, $TargetsTable> {
  $$TargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kcalTarget => $composableBuilder(
    column: $table.kcalTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinTarget => $composableBuilder(
    column: $table.proteinTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsTarget => $composableBuilder(
    column: $table.carbsTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatTarget => $composableBuilder(
    column: $table.fatTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TargetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TargetsTable> {
  $$TargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<int> get kcalTarget => $composableBuilder(
    column: $table.kcalTarget,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinTarget => $composableBuilder(
    column: $table.proteinTarget,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbsTarget => $composableBuilder(
    column: $table.carbsTarget,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatTarget =>
      $composableBuilder(column: $table.fatTarget, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TargetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TargetsTable,
          Target,
          $$TargetsTableFilterComposer,
          $$TargetsTableOrderingComposer,
          $$TargetsTableAnnotationComposer,
          $$TargetsTableCreateCompanionBuilder,
          $$TargetsTableUpdateCompanionBuilder,
          (Target, BaseReferences<_$AppDatabase, $TargetsTable, Target>),
          Target,
          PrefetchHooks Function()
        > {
  $$TargetsTableTableManager(_$AppDatabase db, $TargetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TargetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> validFrom = const Value.absent(),
                Value<int> kcalTarget = const Value.absent(),
                Value<double?> proteinTarget = const Value.absent(),
                Value<double?> carbsTarget = const Value.absent(),
                Value<double?> fatTarget = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TargetsCompanion(
                id: id,
                validFrom: validFrom,
                kcalTarget: kcalTarget,
                proteinTarget: proteinTarget,
                carbsTarget: carbsTarget,
                fatTarget: fatTarget,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime validFrom,
                required int kcalTarget,
                Value<double?> proteinTarget = const Value.absent(),
                Value<double?> carbsTarget = const Value.absent(),
                Value<double?> fatTarget = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TargetsCompanion.insert(
                id: id,
                validFrom: validFrom,
                kcalTarget: kcalTarget,
                proteinTarget: proteinTarget,
                carbsTarget: carbsTarget,
                fatTarget: fatTarget,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TargetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TargetsTable,
      Target,
      $$TargetsTableFilterComposer,
      $$TargetsTableOrderingComposer,
      $$TargetsTableAnnotationComposer,
      $$TargetsTableCreateCompanionBuilder,
      $$TargetsTableUpdateCompanionBuilder,
      (Target, BaseReferences<_$AppDatabase, $TargetsTable, Target>),
      Target,
      PrefetchHooks Function()
    >;
typedef $$RecipesTableCreateCompanionBuilder =
    RecipesCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      required int totalKcal,
      Value<double?> totalProtein,
      Value<double?> totalCarbs,
      Value<double?> totalFat,
      required double totalGrams,
      Value<int> servings,
      Value<String?> servingName,
      Value<bool> userCreated,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$RecipesTableUpdateCompanionBuilder =
    RecipesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<int> totalKcal,
      Value<double?> totalProtein,
      Value<double?> totalCarbs,
      Value<double?> totalFat,
      Value<double> totalGrams,
      Value<int> servings,
      Value<String?> servingName,
      Value<bool> userCreated,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$RecipesTableReferences
    extends BaseReferences<_$AppDatabase, $RecipesTable, Recipe> {
  $$RecipesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RecipeItemsTable, List<RecipeItem>>
  _recipeItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recipeItems,
    aliasName: $_aliasNameGenerator(db.recipes.id, db.recipeItems.recipeId),
  );

  $$RecipeItemsTableProcessedTableManager get recipeItemsRefs {
    final manager = $$RecipeItemsTableTableManager(
      $_db,
      $_db.recipeItems,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalKcal => $composableBuilder(
    column: $table.totalKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalProtein => $composableBuilder(
    column: $table.totalProtein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalCarbs => $composableBuilder(
    column: $table.totalCarbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalFat => $composableBuilder(
    column: $table.totalFat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalGrams => $composableBuilder(
    column: $table.totalGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servingName => $composableBuilder(
    column: $table.servingName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get userCreated => $composableBuilder(
    column: $table.userCreated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> recipeItemsRefs(
    Expression<bool> Function($$RecipeItemsTableFilterComposer f) f,
  ) {
    final $$RecipeItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeItems,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeItemsTableFilterComposer(
            $db: $db,
            $table: $db.recipeItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalKcal => $composableBuilder(
    column: $table.totalKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalProtein => $composableBuilder(
    column: $table.totalProtein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalCarbs => $composableBuilder(
    column: $table.totalCarbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalFat => $composableBuilder(
    column: $table.totalFat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalGrams => $composableBuilder(
    column: $table.totalGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servingName => $composableBuilder(
    column: $table.servingName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userCreated => $composableBuilder(
    column: $table.userCreated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalKcal =>
      $composableBuilder(column: $table.totalKcal, builder: (column) => column);

  GeneratedColumn<double> get totalProtein => $composableBuilder(
    column: $table.totalProtein,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalCarbs => $composableBuilder(
    column: $table.totalCarbs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalFat =>
      $composableBuilder(column: $table.totalFat, builder: (column) => column);

  GeneratedColumn<double> get totalGrams => $composableBuilder(
    column: $table.totalGrams,
    builder: (column) => column,
  );

  GeneratedColumn<int> get servings =>
      $composableBuilder(column: $table.servings, builder: (column) => column);

  GeneratedColumn<String> get servingName => $composableBuilder(
    column: $table.servingName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get userCreated => $composableBuilder(
    column: $table.userCreated,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> recipeItemsRefs<T extends Object>(
    Expression<T> Function($$RecipeItemsTableAnnotationComposer a) f,
  ) {
    final $$RecipeItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeItems,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.recipeItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipesTable,
          Recipe,
          $$RecipesTableFilterComposer,
          $$RecipesTableOrderingComposer,
          $$RecipesTableAnnotationComposer,
          $$RecipesTableCreateCompanionBuilder,
          $$RecipesTableUpdateCompanionBuilder,
          (Recipe, $$RecipesTableReferences),
          Recipe,
          PrefetchHooks Function({bool recipeItemsRefs})
        > {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> totalKcal = const Value.absent(),
                Value<double?> totalProtein = const Value.absent(),
                Value<double?> totalCarbs = const Value.absent(),
                Value<double?> totalFat = const Value.absent(),
                Value<double> totalGrams = const Value.absent(),
                Value<int> servings = const Value.absent(),
                Value<String?> servingName = const Value.absent(),
                Value<bool> userCreated = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion(
                id: id,
                name: name,
                description: description,
                totalKcal: totalKcal,
                totalProtein: totalProtein,
                totalCarbs: totalCarbs,
                totalFat: totalFat,
                totalGrams: totalGrams,
                servings: servings,
                servingName: servingName,
                userCreated: userCreated,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required int totalKcal,
                Value<double?> totalProtein = const Value.absent(),
                Value<double?> totalCarbs = const Value.absent(),
                Value<double?> totalFat = const Value.absent(),
                required double totalGrams,
                Value<int> servings = const Value.absent(),
                Value<String?> servingName = const Value.absent(),
                Value<bool> userCreated = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion.insert(
                id: id,
                name: name,
                description: description,
                totalKcal: totalKcal,
                totalProtein: totalProtein,
                totalCarbs: totalCarbs,
                totalFat: totalFat,
                totalGrams: totalGrams,
                servings: servings,
                servingName: servingName,
                userCreated: userCreated,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (recipeItemsRefs) db.recipeItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recipeItemsRefs)
                    await $_getPrefetchedData<
                      Recipe,
                      $RecipesTable,
                      RecipeItem
                    >(
                      currentTable: table,
                      referencedTable: $$RecipesTableReferences
                          ._recipeItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$RecipesTableReferences(
                        db,
                        table,
                        p0,
                      ).recipeItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.recipeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipesTable,
      Recipe,
      $$RecipesTableFilterComposer,
      $$RecipesTableOrderingComposer,
      $$RecipesTableAnnotationComposer,
      $$RecipesTableCreateCompanionBuilder,
      $$RecipesTableUpdateCompanionBuilder,
      (Recipe, $$RecipesTableReferences),
      Recipe,
      PrefetchHooks Function({bool recipeItemsRefs})
    >;
typedef $$RecipeItemsTableCreateCompanionBuilder =
    RecipeItemsCompanion Function({
      required String id,
      required String recipeId,
      required String foodId,
      required double amount,
      required ServingUnit unit,
      required String foodNameSnapshot,
      required int kcalPer100gSnapshot,
      Value<double?> proteinPer100gSnapshot,
      Value<double?> carbsPer100gSnapshot,
      Value<double?> fatPer100gSnapshot,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$RecipeItemsTableUpdateCompanionBuilder =
    RecipeItemsCompanion Function({
      Value<String> id,
      Value<String> recipeId,
      Value<String> foodId,
      Value<double> amount,
      Value<ServingUnit> unit,
      Value<String> foodNameSnapshot,
      Value<int> kcalPer100gSnapshot,
      Value<double?> proteinPer100gSnapshot,
      Value<double?> carbsPer100gSnapshot,
      Value<double?> fatPer100gSnapshot,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$RecipeItemsTableReferences
    extends BaseReferences<_$AppDatabase, $RecipeItemsTable, RecipeItem> {
  $$RecipeItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias(
        $_aliasNameGenerator(db.recipeItems.recipeId, db.recipes.id),
      );

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FoodsTable _foodIdTable(_$AppDatabase db) => db.foods.createAlias(
    $_aliasNameGenerator(db.recipeItems.foodId, db.foods.id),
  );

  $$FoodsTableProcessedTableManager get foodId {
    final $_column = $_itemColumn<String>('food_id')!;

    final manager = $$FoodsTableTableManager(
      $_db,
      $_db.foods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_foodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecipeItemsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeItemsTable> {
  $$RecipeItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ServingUnit, ServingUnit, String> get unit =>
      $composableBuilder(
        column: $table.unit,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get foodNameSnapshot => $composableBuilder(
    column: $table.foodNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kcalPer100gSnapshot => $composableBuilder(
    column: $table.kcalPer100gSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinPer100gSnapshot => $composableBuilder(
    column: $table.proteinPer100gSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsPer100gSnapshot => $composableBuilder(
    column: $table.carbsPer100gSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatPer100gSnapshot => $composableBuilder(
    column: $table.fatPer100gSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoodsTableFilterComposer get foodId {
    final $$FoodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableFilterComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeItemsTable> {
  $$RecipeItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodNameSnapshot => $composableBuilder(
    column: $table.foodNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kcalPer100gSnapshot => $composableBuilder(
    column: $table.kcalPer100gSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinPer100gSnapshot => $composableBuilder(
    column: $table.proteinPer100gSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsPer100gSnapshot => $composableBuilder(
    column: $table.carbsPer100gSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatPer100gSnapshot => $composableBuilder(
    column: $table.fatPer100gSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoodsTableOrderingComposer get foodId {
    final $$FoodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableOrderingComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeItemsTable> {
  $$RecipeItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ServingUnit, String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get foodNameSnapshot => $composableBuilder(
    column: $table.foodNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get kcalPer100gSnapshot => $composableBuilder(
    column: $table.kcalPer100gSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinPer100gSnapshot => $composableBuilder(
    column: $table.proteinPer100gSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbsPer100gSnapshot => $composableBuilder(
    column: $table.carbsPer100gSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatPer100gSnapshot => $composableBuilder(
    column: $table.fatPer100gSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoodsTableAnnotationComposer get foodId {
    final $$FoodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableAnnotationComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeItemsTable,
          RecipeItem,
          $$RecipeItemsTableFilterComposer,
          $$RecipeItemsTableOrderingComposer,
          $$RecipeItemsTableAnnotationComposer,
          $$RecipeItemsTableCreateCompanionBuilder,
          $$RecipeItemsTableUpdateCompanionBuilder,
          (RecipeItem, $$RecipeItemsTableReferences),
          RecipeItem,
          PrefetchHooks Function({bool recipeId, bool foodId})
        > {
  $$RecipeItemsTableTableManager(_$AppDatabase db, $RecipeItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<String> foodId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<ServingUnit> unit = const Value.absent(),
                Value<String> foodNameSnapshot = const Value.absent(),
                Value<int> kcalPer100gSnapshot = const Value.absent(),
                Value<double?> proteinPer100gSnapshot = const Value.absent(),
                Value<double?> carbsPer100gSnapshot = const Value.absent(),
                Value<double?> fatPer100gSnapshot = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeItemsCompanion(
                id: id,
                recipeId: recipeId,
                foodId: foodId,
                amount: amount,
                unit: unit,
                foodNameSnapshot: foodNameSnapshot,
                kcalPer100gSnapshot: kcalPer100gSnapshot,
                proteinPer100gSnapshot: proteinPer100gSnapshot,
                carbsPer100gSnapshot: carbsPer100gSnapshot,
                fatPer100gSnapshot: fatPer100gSnapshot,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recipeId,
                required String foodId,
                required double amount,
                required ServingUnit unit,
                required String foodNameSnapshot,
                required int kcalPer100gSnapshot,
                Value<double?> proteinPer100gSnapshot = const Value.absent(),
                Value<double?> carbsPer100gSnapshot = const Value.absent(),
                Value<double?> fatPer100gSnapshot = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeItemsCompanion.insert(
                id: id,
                recipeId: recipeId,
                foodId: foodId,
                amount: amount,
                unit: unit,
                foodNameSnapshot: foodNameSnapshot,
                kcalPer100gSnapshot: kcalPer100gSnapshot,
                proteinPer100gSnapshot: proteinPer100gSnapshot,
                carbsPer100gSnapshot: carbsPer100gSnapshot,
                fatPer100gSnapshot: fatPer100gSnapshot,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecipeItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false, foodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable: $$RecipeItemsTableReferences
                                    ._recipeIdTable(db),
                                referencedColumn: $$RecipeItemsTableReferences
                                    ._recipeIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (foodId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.foodId,
                                referencedTable: $$RecipeItemsTableReferences
                                    ._foodIdTable(db),
                                referencedColumn: $$RecipeItemsTableReferences
                                    ._foodIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RecipeItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeItemsTable,
      RecipeItem,
      $$RecipeItemsTableFilterComposer,
      $$RecipeItemsTableOrderingComposer,
      $$RecipeItemsTableAnnotationComposer,
      $$RecipeItemsTableCreateCompanionBuilder,
      $$RecipeItemsTableUpdateCompanionBuilder,
      (RecipeItem, $$RecipeItemsTableReferences),
      RecipeItem,
      PrefetchHooks Function({bool recipeId, bool foodId})
    >;
typedef $$FoodsFtsTableCreateCompanionBuilder =
    FoodsFtsCompanion Function({
      required String name,
      Value<String?> brand,
      Value<int> rowid,
    });
typedef $$FoodsFtsTableUpdateCompanionBuilder =
    FoodsFtsCompanion Function({
      Value<String> name,
      Value<String?> brand,
      Value<int> rowid,
    });

class $$FoodsFtsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodsFtsTable> {
  $$FoodsFtsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodsFtsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodsFtsTable> {
  $$FoodsFtsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodsFtsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodsFtsTable> {
  $$FoodsFtsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);
}

class $$FoodsFtsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodsFtsTable,
          FoodsFt,
          $$FoodsFtsTableFilterComposer,
          $$FoodsFtsTableOrderingComposer,
          $$FoodsFtsTableAnnotationComposer,
          $$FoodsFtsTableCreateCompanionBuilder,
          $$FoodsFtsTableUpdateCompanionBuilder,
          (FoodsFt, BaseReferences<_$AppDatabase, $FoodsFtsTable, FoodsFt>),
          FoodsFt,
          PrefetchHooks Function()
        > {
  $$FoodsFtsTableTableManager(_$AppDatabase db, $FoodsFtsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodsFtsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodsFtsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodsFtsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodsFtsCompanion(name: name, brand: brand, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodsFtsCompanion.insert(
                name: name,
                brand: brand,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodsFtsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodsFtsTable,
      FoodsFt,
      $$FoodsFtsTableFilterComposer,
      $$FoodsFtsTableOrderingComposer,
      $$FoodsFtsTableAnnotationComposer,
      $$FoodsFtsTableCreateCompanionBuilder,
      $$FoodsFtsTableUpdateCompanionBuilder,
      (FoodsFt, BaseReferences<_$AppDatabase, $FoodsFtsTable, FoodsFt>),
      FoodsFt,
      PrefetchHooks Function()
    >;
typedef $$SearchHistoryTableCreateCompanionBuilder =
    SearchHistoryCompanion Function({
      Value<int> id,
      required String query,
      required String normalizedQuery,
      Value<String?> selectedFoodId,
      Value<DateTime> searchedAt,
      Value<bool> hasResults,
    });
typedef $$SearchHistoryTableUpdateCompanionBuilder =
    SearchHistoryCompanion Function({
      Value<int> id,
      Value<String> query,
      Value<String> normalizedQuery,
      Value<String?> selectedFoodId,
      Value<DateTime> searchedAt,
      Value<bool> hasResults,
    });

class $$SearchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedQuery => $composableBuilder(
    column: $table.normalizedQuery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedFoodId => $composableBuilder(
    column: $table.selectedFoodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get searchedAt => $composableBuilder(
    column: $table.searchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasResults => $composableBuilder(
    column: $table.hasResults,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedQuery => $composableBuilder(
    column: $table.normalizedQuery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedFoodId => $composableBuilder(
    column: $table.selectedFoodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get searchedAt => $composableBuilder(
    column: $table.searchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasResults => $composableBuilder(
    column: $table.hasResults,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<String> get normalizedQuery => $composableBuilder(
    column: $table.normalizedQuery,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedFoodId => $composableBuilder(
    column: $table.selectedFoodId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get searchedAt => $composableBuilder(
    column: $table.searchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasResults => $composableBuilder(
    column: $table.hasResults,
    builder: (column) => column,
  );
}

class $$SearchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchHistoryTable,
          SearchHistoryData,
          $$SearchHistoryTableFilterComposer,
          $$SearchHistoryTableOrderingComposer,
          $$SearchHistoryTableAnnotationComposer,
          $$SearchHistoryTableCreateCompanionBuilder,
          $$SearchHistoryTableUpdateCompanionBuilder,
          (
            SearchHistoryData,
            BaseReferences<
              _$AppDatabase,
              $SearchHistoryTable,
              SearchHistoryData
            >,
          ),
          SearchHistoryData,
          PrefetchHooks Function()
        > {
  $$SearchHistoryTableTableManager(_$AppDatabase db, $SearchHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> query = const Value.absent(),
                Value<String> normalizedQuery = const Value.absent(),
                Value<String?> selectedFoodId = const Value.absent(),
                Value<DateTime> searchedAt = const Value.absent(),
                Value<bool> hasResults = const Value.absent(),
              }) => SearchHistoryCompanion(
                id: id,
                query: query,
                normalizedQuery: normalizedQuery,
                selectedFoodId: selectedFoodId,
                searchedAt: searchedAt,
                hasResults: hasResults,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String query,
                required String normalizedQuery,
                Value<String?> selectedFoodId = const Value.absent(),
                Value<DateTime> searchedAt = const Value.absent(),
                Value<bool> hasResults = const Value.absent(),
              }) => SearchHistoryCompanion.insert(
                id: id,
                query: query,
                normalizedQuery: normalizedQuery,
                selectedFoodId: selectedFoodId,
                searchedAt: searchedAt,
                hasResults: hasResults,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchHistoryTable,
      SearchHistoryData,
      $$SearchHistoryTableFilterComposer,
      $$SearchHistoryTableOrderingComposer,
      $$SearchHistoryTableAnnotationComposer,
      $$SearchHistoryTableCreateCompanionBuilder,
      $$SearchHistoryTableUpdateCompanionBuilder,
      (
        SearchHistoryData,
        BaseReferences<_$AppDatabase, $SearchHistoryTable, SearchHistoryData>,
      ),
      SearchHistoryData,
      PrefetchHooks Function()
    >;
typedef $$ConsumptionPatternsTableCreateCompanionBuilder =
    ConsumptionPatternsCompanion Function({
      Value<int> id,
      required String foodId,
      required int hourOfDay,
      required int dayOfWeek,
      Value<MealType?> mealType,
      Value<int> frequency,
      required DateTime lastConsumedAt,
    });
typedef $$ConsumptionPatternsTableUpdateCompanionBuilder =
    ConsumptionPatternsCompanion Function({
      Value<int> id,
      Value<String> foodId,
      Value<int> hourOfDay,
      Value<int> dayOfWeek,
      Value<MealType?> mealType,
      Value<int> frequency,
      Value<DateTime> lastConsumedAt,
    });

final class $$ConsumptionPatternsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ConsumptionPatternsTable,
          ConsumptionPattern
        > {
  $$ConsumptionPatternsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FoodsTable _foodIdTable(_$AppDatabase db) => db.foods.createAlias(
    $_aliasNameGenerator(db.consumptionPatterns.foodId, db.foods.id),
  );

  $$FoodsTableProcessedTableManager get foodId {
    final $_column = $_itemColumn<String>('food_id')!;

    final manager = $$FoodsTableTableManager(
      $_db,
      $_db.foods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_foodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ConsumptionPatternsTableFilterComposer
    extends Composer<_$AppDatabase, $ConsumptionPatternsTable> {
  $$ConsumptionPatternsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hourOfDay => $composableBuilder(
    column: $table.hourOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MealType?, MealType, String> get mealType =>
      $composableBuilder(
        column: $table.mealType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastConsumedAt => $composableBuilder(
    column: $table.lastConsumedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FoodsTableFilterComposer get foodId {
    final $$FoodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableFilterComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConsumptionPatternsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConsumptionPatternsTable> {
  $$ConsumptionPatternsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hourOfDay => $composableBuilder(
    column: $table.hourOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastConsumedAt => $composableBuilder(
    column: $table.lastConsumedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoodsTableOrderingComposer get foodId {
    final $$FoodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableOrderingComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConsumptionPatternsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConsumptionPatternsTable> {
  $$ConsumptionPatternsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get hourOfDay =>
      $composableBuilder(column: $table.hourOfDay, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MealType?, String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<int> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<DateTime> get lastConsumedAt => $composableBuilder(
    column: $table.lastConsumedAt,
    builder: (column) => column,
  );

  $$FoodsTableAnnotationComposer get foodId {
    final $$FoodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableAnnotationComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConsumptionPatternsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConsumptionPatternsTable,
          ConsumptionPattern,
          $$ConsumptionPatternsTableFilterComposer,
          $$ConsumptionPatternsTableOrderingComposer,
          $$ConsumptionPatternsTableAnnotationComposer,
          $$ConsumptionPatternsTableCreateCompanionBuilder,
          $$ConsumptionPatternsTableUpdateCompanionBuilder,
          (ConsumptionPattern, $$ConsumptionPatternsTableReferences),
          ConsumptionPattern,
          PrefetchHooks Function({bool foodId})
        > {
  $$ConsumptionPatternsTableTableManager(
    _$AppDatabase db,
    $ConsumptionPatternsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsumptionPatternsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsumptionPatternsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ConsumptionPatternsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> foodId = const Value.absent(),
                Value<int> hourOfDay = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                Value<MealType?> mealType = const Value.absent(),
                Value<int> frequency = const Value.absent(),
                Value<DateTime> lastConsumedAt = const Value.absent(),
              }) => ConsumptionPatternsCompanion(
                id: id,
                foodId: foodId,
                hourOfDay: hourOfDay,
                dayOfWeek: dayOfWeek,
                mealType: mealType,
                frequency: frequency,
                lastConsumedAt: lastConsumedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String foodId,
                required int hourOfDay,
                required int dayOfWeek,
                Value<MealType?> mealType = const Value.absent(),
                Value<int> frequency = const Value.absent(),
                required DateTime lastConsumedAt,
              }) => ConsumptionPatternsCompanion.insert(
                id: id,
                foodId: foodId,
                hourOfDay: hourOfDay,
                dayOfWeek: dayOfWeek,
                mealType: mealType,
                frequency: frequency,
                lastConsumedAt: lastConsumedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConsumptionPatternsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({foodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (foodId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.foodId,
                                referencedTable:
                                    $$ConsumptionPatternsTableReferences
                                        ._foodIdTable(db),
                                referencedColumn:
                                    $$ConsumptionPatternsTableReferences
                                        ._foodIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ConsumptionPatternsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConsumptionPatternsTable,
      ConsumptionPattern,
      $$ConsumptionPatternsTableFilterComposer,
      $$ConsumptionPatternsTableOrderingComposer,
      $$ConsumptionPatternsTableAnnotationComposer,
      $$ConsumptionPatternsTableCreateCompanionBuilder,
      $$ConsumptionPatternsTableUpdateCompanionBuilder,
      (ConsumptionPattern, $$ConsumptionPatternsTableReferences),
      ConsumptionPattern,
      PrefetchHooks Function({bool foodId})
    >;
typedef $$MealTemplatesTableCreateCompanionBuilder =
    MealTemplatesCompanion Function({
      required String id,
      required String name,
      required MealType mealType,
      Value<int> useCount,
      Value<DateTime?> lastUsedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MealTemplatesTableUpdateCompanionBuilder =
    MealTemplatesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<MealType> mealType,
      Value<int> useCount,
      Value<DateTime?> lastUsedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$MealTemplatesTableReferences
    extends BaseReferences<_$AppDatabase, $MealTemplatesTable, MealTemplate> {
  $$MealTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$MealTemplateItemsTable, List<MealTemplateItem>>
  _mealTemplateItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.mealTemplateItems,
        aliasName: $_aliasNameGenerator(
          db.mealTemplates.id,
          db.mealTemplateItems.templateId,
        ),
      );

  $$MealTemplateItemsTableProcessedTableManager get mealTemplateItemsRefs {
    final manager = $$MealTemplateItemsTableTableManager(
      $_db,
      $_db.mealTemplateItems,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _mealTemplateItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MealTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $MealTemplatesTable> {
  $$MealTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MealType, MealType, String> get mealType =>
      $composableBuilder(
        column: $table.mealType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mealTemplateItemsRefs(
    Expression<bool> Function($$MealTemplateItemsTableFilterComposer f) f,
  ) {
    final $$MealTemplateItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealTemplateItems,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealTemplateItemsTableFilterComposer(
            $db: $db,
            $table: $db.mealTemplateItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MealTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $MealTemplatesTable> {
  $$MealTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealTemplatesTable> {
  $$MealTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MealType, String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> mealTemplateItemsRefs<T extends Object>(
    Expression<T> Function($$MealTemplateItemsTableAnnotationComposer a) f,
  ) {
    final $$MealTemplateItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.mealTemplateItems,
          getReferencedColumn: (t) => t.templateId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MealTemplateItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.mealTemplateItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MealTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealTemplatesTable,
          MealTemplate,
          $$MealTemplatesTableFilterComposer,
          $$MealTemplatesTableOrderingComposer,
          $$MealTemplatesTableAnnotationComposer,
          $$MealTemplatesTableCreateCompanionBuilder,
          $$MealTemplatesTableUpdateCompanionBuilder,
          (MealTemplate, $$MealTemplatesTableReferences),
          MealTemplate,
          PrefetchHooks Function({bool mealTemplateItemsRefs})
        > {
  $$MealTemplatesTableTableManager(_$AppDatabase db, $MealTemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<MealType> mealType = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealTemplatesCompanion(
                id: id,
                name: name,
                mealType: mealType,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required MealType mealType,
                Value<int> useCount = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MealTemplatesCompanion.insert(
                id: id,
                name: name,
                mealType: mealType,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MealTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mealTemplateItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (mealTemplateItemsRefs) db.mealTemplateItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mealTemplateItemsRefs)
                    await $_getPrefetchedData<
                      MealTemplate,
                      $MealTemplatesTable,
                      MealTemplateItem
                    >(
                      currentTable: table,
                      referencedTable: $$MealTemplatesTableReferences
                          ._mealTemplateItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MealTemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).mealTemplateItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.templateId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MealTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealTemplatesTable,
      MealTemplate,
      $$MealTemplatesTableFilterComposer,
      $$MealTemplatesTableOrderingComposer,
      $$MealTemplatesTableAnnotationComposer,
      $$MealTemplatesTableCreateCompanionBuilder,
      $$MealTemplatesTableUpdateCompanionBuilder,
      (MealTemplate, $$MealTemplatesTableReferences),
      MealTemplate,
      PrefetchHooks Function({bool mealTemplateItemsRefs})
    >;
typedef $$MealTemplateItemsTableCreateCompanionBuilder =
    MealTemplateItemsCompanion Function({
      required String id,
      required String templateId,
      required String foodId,
      required double amount,
      required ServingUnit unit,
      required String foodNameSnapshot,
      required int kcalPer100gSnapshot,
      Value<double?> proteinPer100gSnapshot,
      Value<double?> carbsPer100gSnapshot,
      Value<double?> fatPer100gSnapshot,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$MealTemplateItemsTableUpdateCompanionBuilder =
    MealTemplateItemsCompanion Function({
      Value<String> id,
      Value<String> templateId,
      Value<String> foodId,
      Value<double> amount,
      Value<ServingUnit> unit,
      Value<String> foodNameSnapshot,
      Value<int> kcalPer100gSnapshot,
      Value<double?> proteinPer100gSnapshot,
      Value<double?> carbsPer100gSnapshot,
      Value<double?> fatPer100gSnapshot,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$MealTemplateItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MealTemplateItemsTable,
          MealTemplateItem
        > {
  $$MealTemplateItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MealTemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.mealTemplates.createAlias(
        $_aliasNameGenerator(
          db.mealTemplateItems.templateId,
          db.mealTemplates.id,
        ),
      );

  $$MealTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<String>('template_id')!;

    final manager = $$MealTemplatesTableTableManager(
      $_db,
      $_db.mealTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FoodsTable _foodIdTable(_$AppDatabase db) => db.foods.createAlias(
    $_aliasNameGenerator(db.mealTemplateItems.foodId, db.foods.id),
  );

  $$FoodsTableProcessedTableManager get foodId {
    final $_column = $_itemColumn<String>('food_id')!;

    final manager = $$FoodsTableTableManager(
      $_db,
      $_db.foods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_foodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MealTemplateItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MealTemplateItemsTable> {
  $$MealTemplateItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ServingUnit, ServingUnit, String> get unit =>
      $composableBuilder(
        column: $table.unit,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get foodNameSnapshot => $composableBuilder(
    column: $table.foodNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kcalPer100gSnapshot => $composableBuilder(
    column: $table.kcalPer100gSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinPer100gSnapshot => $composableBuilder(
    column: $table.proteinPer100gSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsPer100gSnapshot => $composableBuilder(
    column: $table.carbsPer100gSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatPer100gSnapshot => $composableBuilder(
    column: $table.fatPer100gSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$MealTemplatesTableFilterComposer get templateId {
    final $$MealTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.mealTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.mealTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoodsTableFilterComposer get foodId {
    final $$FoodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableFilterComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealTemplateItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealTemplateItemsTable> {
  $$MealTemplateItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodNameSnapshot => $composableBuilder(
    column: $table.foodNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kcalPer100gSnapshot => $composableBuilder(
    column: $table.kcalPer100gSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinPer100gSnapshot => $composableBuilder(
    column: $table.proteinPer100gSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsPer100gSnapshot => $composableBuilder(
    column: $table.carbsPer100gSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatPer100gSnapshot => $composableBuilder(
    column: $table.fatPer100gSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$MealTemplatesTableOrderingComposer get templateId {
    final $$MealTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.mealTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.mealTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoodsTableOrderingComposer get foodId {
    final $$FoodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableOrderingComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealTemplateItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealTemplateItemsTable> {
  $$MealTemplateItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ServingUnit, String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get foodNameSnapshot => $composableBuilder(
    column: $table.foodNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get kcalPer100gSnapshot => $composableBuilder(
    column: $table.kcalPer100gSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinPer100gSnapshot => $composableBuilder(
    column: $table.proteinPer100gSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbsPer100gSnapshot => $composableBuilder(
    column: $table.carbsPer100gSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatPer100gSnapshot => $composableBuilder(
    column: $table.fatPer100gSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$MealTemplatesTableAnnotationComposer get templateId {
    final $$MealTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.mealTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.mealTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoodsTableAnnotationComposer get foodId {
    final $$FoodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoodsTableAnnotationComposer(
            $db: $db,
            $table: $db.foods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealTemplateItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealTemplateItemsTable,
          MealTemplateItem,
          $$MealTemplateItemsTableFilterComposer,
          $$MealTemplateItemsTableOrderingComposer,
          $$MealTemplateItemsTableAnnotationComposer,
          $$MealTemplateItemsTableCreateCompanionBuilder,
          $$MealTemplateItemsTableUpdateCompanionBuilder,
          (MealTemplateItem, $$MealTemplateItemsTableReferences),
          MealTemplateItem,
          PrefetchHooks Function({bool templateId, bool foodId})
        > {
  $$MealTemplateItemsTableTableManager(
    _$AppDatabase db,
    $MealTemplateItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealTemplateItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealTemplateItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealTemplateItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> foodId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<ServingUnit> unit = const Value.absent(),
                Value<String> foodNameSnapshot = const Value.absent(),
                Value<int> kcalPer100gSnapshot = const Value.absent(),
                Value<double?> proteinPer100gSnapshot = const Value.absent(),
                Value<double?> carbsPer100gSnapshot = const Value.absent(),
                Value<double?> fatPer100gSnapshot = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealTemplateItemsCompanion(
                id: id,
                templateId: templateId,
                foodId: foodId,
                amount: amount,
                unit: unit,
                foodNameSnapshot: foodNameSnapshot,
                kcalPer100gSnapshot: kcalPer100gSnapshot,
                proteinPer100gSnapshot: proteinPer100gSnapshot,
                carbsPer100gSnapshot: carbsPer100gSnapshot,
                fatPer100gSnapshot: fatPer100gSnapshot,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateId,
                required String foodId,
                required double amount,
                required ServingUnit unit,
                required String foodNameSnapshot,
                required int kcalPer100gSnapshot,
                Value<double?> proteinPer100gSnapshot = const Value.absent(),
                Value<double?> carbsPer100gSnapshot = const Value.absent(),
                Value<double?> fatPer100gSnapshot = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealTemplateItemsCompanion.insert(
                id: id,
                templateId: templateId,
                foodId: foodId,
                amount: amount,
                unit: unit,
                foodNameSnapshot: foodNameSnapshot,
                kcalPer100gSnapshot: kcalPer100gSnapshot,
                proteinPer100gSnapshot: proteinPer100gSnapshot,
                carbsPer100gSnapshot: carbsPer100gSnapshot,
                fatPer100gSnapshot: fatPer100gSnapshot,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MealTemplateItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateId = false, foodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (templateId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.templateId,
                                referencedTable:
                                    $$MealTemplateItemsTableReferences
                                        ._templateIdTable(db),
                                referencedColumn:
                                    $$MealTemplateItemsTableReferences
                                        ._templateIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (foodId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.foodId,
                                referencedTable:
                                    $$MealTemplateItemsTableReferences
                                        ._foodIdTable(db),
                                referencedColumn:
                                    $$MealTemplateItemsTableReferences
                                        ._foodIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MealTemplateItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealTemplateItemsTable,
      MealTemplateItem,
      $$MealTemplateItemsTableFilterComposer,
      $$MealTemplateItemsTableOrderingComposer,
      $$MealTemplateItemsTableAnnotationComposer,
      $$MealTemplateItemsTableCreateCompanionBuilder,
      $$MealTemplateItemsTableUpdateCompanionBuilder,
      (MealTemplateItem, $$MealTemplateItemsTableReferences),
      MealTemplateItem,
      PrefetchHooks Function({bool templateId, bool foodId})
    >;
typedef $$BodyMeasurementsTableCreateCompanionBuilder =
    BodyMeasurementsCompanion Function({
      required String id,
      required DateTime date,
      Value<double?> weightKg,
      Value<double?> waistCm,
      Value<double?> chestCm,
      Value<double?> hipsCm,
      Value<double?> leftArmCm,
      Value<double?> rightArmCm,
      Value<double?> leftThighCm,
      Value<double?> rightThighCm,
      Value<double?> leftCalfCm,
      Value<double?> rightCalfCm,
      Value<double?> neckCm,
      Value<double?> bodyFatPercentage,
      Value<String?> notes,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$BodyMeasurementsTableUpdateCompanionBuilder =
    BodyMeasurementsCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<double?> weightKg,
      Value<double?> waistCm,
      Value<double?> chestCm,
      Value<double?> hipsCm,
      Value<double?> leftArmCm,
      Value<double?> rightArmCm,
      Value<double?> leftThighCm,
      Value<double?> rightThighCm,
      Value<double?> leftCalfCm,
      Value<double?> rightCalfCm,
      Value<double?> neckCm,
      Value<double?> bodyFatPercentage,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$BodyMeasurementsTableReferences
    extends
        BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement> {
  $$BodyMeasurementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ProgressPhotosTable, List<ProgressPhoto>>
  _progressPhotosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.progressPhotos,
    aliasName: $_aliasNameGenerator(
      db.bodyMeasurements.id,
      db.progressPhotos.measurementId,
    ),
  );

  $$ProgressPhotosTableProcessedTableManager get progressPhotosRefs {
    final manager = $$ProgressPhotosTableTableManager(
      $_db,
      $_db.progressPhotos,
    ).filter((f) => f.measurementId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_progressPhotosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BodyMeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waistCm => $composableBuilder(
    column: $table.waistCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get chestCm => $composableBuilder(
    column: $table.chestCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hipsCm => $composableBuilder(
    column: $table.hipsCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get leftArmCm => $composableBuilder(
    column: $table.leftArmCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rightArmCm => $composableBuilder(
    column: $table.rightArmCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get leftThighCm => $composableBuilder(
    column: $table.leftThighCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rightThighCm => $composableBuilder(
    column: $table.rightThighCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get leftCalfCm => $composableBuilder(
    column: $table.leftCalfCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rightCalfCm => $composableBuilder(
    column: $table.rightCalfCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get neckCm => $composableBuilder(
    column: $table.neckCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bodyFatPercentage => $composableBuilder(
    column: $table.bodyFatPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> progressPhotosRefs(
    Expression<bool> Function($$ProgressPhotosTableFilterComposer f) f,
  ) {
    final $$ProgressPhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.progressPhotos,
      getReferencedColumn: (t) => t.measurementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgressPhotosTableFilterComposer(
            $db: $db,
            $table: $db.progressPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BodyMeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waistCm => $composableBuilder(
    column: $table.waistCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get chestCm => $composableBuilder(
    column: $table.chestCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hipsCm => $composableBuilder(
    column: $table.hipsCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get leftArmCm => $composableBuilder(
    column: $table.leftArmCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rightArmCm => $composableBuilder(
    column: $table.rightArmCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get leftThighCm => $composableBuilder(
    column: $table.leftThighCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rightThighCm => $composableBuilder(
    column: $table.rightThighCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get leftCalfCm => $composableBuilder(
    column: $table.leftCalfCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rightCalfCm => $composableBuilder(
    column: $table.rightCalfCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get neckCm => $composableBuilder(
    column: $table.neckCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bodyFatPercentage => $composableBuilder(
    column: $table.bodyFatPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BodyMeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get waistCm =>
      $composableBuilder(column: $table.waistCm, builder: (column) => column);

  GeneratedColumn<double> get chestCm =>
      $composableBuilder(column: $table.chestCm, builder: (column) => column);

  GeneratedColumn<double> get hipsCm =>
      $composableBuilder(column: $table.hipsCm, builder: (column) => column);

  GeneratedColumn<double> get leftArmCm =>
      $composableBuilder(column: $table.leftArmCm, builder: (column) => column);

  GeneratedColumn<double> get rightArmCm => $composableBuilder(
    column: $table.rightArmCm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get leftThighCm => $composableBuilder(
    column: $table.leftThighCm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rightThighCm => $composableBuilder(
    column: $table.rightThighCm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get leftCalfCm => $composableBuilder(
    column: $table.leftCalfCm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rightCalfCm => $composableBuilder(
    column: $table.rightCalfCm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get neckCm =>
      $composableBuilder(column: $table.neckCm, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPercentage => $composableBuilder(
    column: $table.bodyFatPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> progressPhotosRefs<T extends Object>(
    Expression<T> Function($$ProgressPhotosTableAnnotationComposer a) f,
  ) {
    final $$ProgressPhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.progressPhotos,
      getReferencedColumn: (t) => t.measurementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgressPhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.progressPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BodyMeasurementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BodyMeasurementsTable,
          BodyMeasurement,
          $$BodyMeasurementsTableFilterComposer,
          $$BodyMeasurementsTableOrderingComposer,
          $$BodyMeasurementsTableAnnotationComposer,
          $$BodyMeasurementsTableCreateCompanionBuilder,
          $$BodyMeasurementsTableUpdateCompanionBuilder,
          (BodyMeasurement, $$BodyMeasurementsTableReferences),
          BodyMeasurement,
          PrefetchHooks Function({bool progressPhotosRefs})
        > {
  $$BodyMeasurementsTableTableManager(
    _$AppDatabase db,
    $BodyMeasurementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyMeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> waistCm = const Value.absent(),
                Value<double?> chestCm = const Value.absent(),
                Value<double?> hipsCm = const Value.absent(),
                Value<double?> leftArmCm = const Value.absent(),
                Value<double?> rightArmCm = const Value.absent(),
                Value<double?> leftThighCm = const Value.absent(),
                Value<double?> rightThighCm = const Value.absent(),
                Value<double?> leftCalfCm = const Value.absent(),
                Value<double?> rightCalfCm = const Value.absent(),
                Value<double?> neckCm = const Value.absent(),
                Value<double?> bodyFatPercentage = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BodyMeasurementsCompanion(
                id: id,
                date: date,
                weightKg: weightKg,
                waistCm: waistCm,
                chestCm: chestCm,
                hipsCm: hipsCm,
                leftArmCm: leftArmCm,
                rightArmCm: rightArmCm,
                leftThighCm: leftThighCm,
                rightThighCm: rightThighCm,
                leftCalfCm: leftCalfCm,
                rightCalfCm: rightCalfCm,
                neckCm: neckCm,
                bodyFatPercentage: bodyFatPercentage,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                Value<double?> weightKg = const Value.absent(),
                Value<double?> waistCm = const Value.absent(),
                Value<double?> chestCm = const Value.absent(),
                Value<double?> hipsCm = const Value.absent(),
                Value<double?> leftArmCm = const Value.absent(),
                Value<double?> rightArmCm = const Value.absent(),
                Value<double?> leftThighCm = const Value.absent(),
                Value<double?> rightThighCm = const Value.absent(),
                Value<double?> leftCalfCm = const Value.absent(),
                Value<double?> rightCalfCm = const Value.absent(),
                Value<double?> neckCm = const Value.absent(),
                Value<double?> bodyFatPercentage = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BodyMeasurementsCompanion.insert(
                id: id,
                date: date,
                weightKg: weightKg,
                waistCm: waistCm,
                chestCm: chestCm,
                hipsCm: hipsCm,
                leftArmCm: leftArmCm,
                rightArmCm: rightArmCm,
                leftThighCm: leftThighCm,
                rightThighCm: rightThighCm,
                leftCalfCm: leftCalfCm,
                rightCalfCm: rightCalfCm,
                neckCm: neckCm,
                bodyFatPercentage: bodyFatPercentage,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BodyMeasurementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({progressPhotosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (progressPhotosRefs) db.progressPhotos,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (progressPhotosRefs)
                    await $_getPrefetchedData<
                      BodyMeasurement,
                      $BodyMeasurementsTable,
                      ProgressPhoto
                    >(
                      currentTable: table,
                      referencedTable: $$BodyMeasurementsTableReferences
                          ._progressPhotosRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BodyMeasurementsTableReferences(
                            db,
                            table,
                            p0,
                          ).progressPhotosRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.measurementId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BodyMeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BodyMeasurementsTable,
      BodyMeasurement,
      $$BodyMeasurementsTableFilterComposer,
      $$BodyMeasurementsTableOrderingComposer,
      $$BodyMeasurementsTableAnnotationComposer,
      $$BodyMeasurementsTableCreateCompanionBuilder,
      $$BodyMeasurementsTableUpdateCompanionBuilder,
      (BodyMeasurement, $$BodyMeasurementsTableReferences),
      BodyMeasurement,
      PrefetchHooks Function({bool progressPhotosRefs})
    >;
typedef $$ProgressPhotosTableCreateCompanionBuilder =
    ProgressPhotosCompanion Function({
      required String id,
      required DateTime date,
      required String imagePath,
      Value<String> category,
      Value<String?> notes,
      Value<String?> measurementId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ProgressPhotosTableUpdateCompanionBuilder =
    ProgressPhotosCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<String> imagePath,
      Value<String> category,
      Value<String?> notes,
      Value<String?> measurementId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ProgressPhotosTableReferences
    extends BaseReferences<_$AppDatabase, $ProgressPhotosTable, ProgressPhoto> {
  $$ProgressPhotosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BodyMeasurementsTable _measurementIdTable(_$AppDatabase db) =>
      db.bodyMeasurements.createAlias(
        $_aliasNameGenerator(
          db.progressPhotos.measurementId,
          db.bodyMeasurements.id,
        ),
      );

  $$BodyMeasurementsTableProcessedTableManager? get measurementId {
    final $_column = $_itemColumn<String>('measurement_id');
    if ($_column == null) return null;
    final manager = $$BodyMeasurementsTableTableManager(
      $_db,
      $_db.bodyMeasurements,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_measurementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProgressPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressPhotosTable> {
  $$ProgressPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BodyMeasurementsTableFilterComposer get measurementId {
    final $$BodyMeasurementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.measurementId,
      referencedTable: $db.bodyMeasurements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BodyMeasurementsTableFilterComposer(
            $db: $db,
            $table: $db.bodyMeasurements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgressPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressPhotosTable> {
  $$ProgressPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BodyMeasurementsTableOrderingComposer get measurementId {
    final $$BodyMeasurementsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.measurementId,
      referencedTable: $db.bodyMeasurements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BodyMeasurementsTableOrderingComposer(
            $db: $db,
            $table: $db.bodyMeasurements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgressPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressPhotosTable> {
  $$ProgressPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BodyMeasurementsTableAnnotationComposer get measurementId {
    final $$BodyMeasurementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.measurementId,
      referencedTable: $db.bodyMeasurements,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BodyMeasurementsTableAnnotationComposer(
            $db: $db,
            $table: $db.bodyMeasurements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgressPhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgressPhotosTable,
          ProgressPhoto,
          $$ProgressPhotosTableFilterComposer,
          $$ProgressPhotosTableOrderingComposer,
          $$ProgressPhotosTableAnnotationComposer,
          $$ProgressPhotosTableCreateCompanionBuilder,
          $$ProgressPhotosTableUpdateCompanionBuilder,
          (ProgressPhoto, $$ProgressPhotosTableReferences),
          ProgressPhoto,
          PrefetchHooks Function({bool measurementId})
        > {
  $$ProgressPhotosTableTableManager(
    _$AppDatabase db,
    $ProgressPhotosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> measurementId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgressPhotosCompanion(
                id: id,
                date: date,
                imagePath: imagePath,
                category: category,
                notes: notes,
                measurementId: measurementId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                required String imagePath,
                Value<String> category = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> measurementId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ProgressPhotosCompanion.insert(
                id: id,
                date: date,
                imagePath: imagePath,
                category: category,
                notes: notes,
                measurementId: measurementId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProgressPhotosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({measurementId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (measurementId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.measurementId,
                                referencedTable: $$ProgressPhotosTableReferences
                                    ._measurementIdTable(db),
                                referencedColumn:
                                    $$ProgressPhotosTableReferences
                                        ._measurementIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProgressPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgressPhotosTable,
      ProgressPhoto,
      $$ProgressPhotosTableFilterComposer,
      $$ProgressPhotosTableOrderingComposer,
      $$ProgressPhotosTableAnnotationComposer,
      $$ProgressPhotosTableCreateCompanionBuilder,
      $$ProgressPhotosTableUpdateCompanionBuilder,
      (ProgressPhoto, $$ProgressPhotosTableReferences),
      ProgressPhoto,
      PrefetchHooks Function({bool measurementId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db, _db.routines);
  $$RoutineDaysTableTableManager get routineDays =>
      $$RoutineDaysTableTableManager(_db, _db.routineDays);
  $$RoutineExercisesTableTableManager get routineExercises =>
      $$RoutineExercisesTableTableManager(_db, _db.routineExercises);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SessionExercisesTableTableManager get sessionExercises =>
      $$SessionExercisesTableTableManager(_db, _db.sessionExercises);
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db, _db.workoutSets);
  $$ExerciseNotesTableTableManager get exerciseNotes =>
      $$ExerciseNotesTableTableManager(_db, _db.exerciseNotes);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$FoodsTableTableManager get foods =>
      $$FoodsTableTableManager(_db, _db.foods);
  $$DiaryEntriesTableTableManager get diaryEntries =>
      $$DiaryEntriesTableTableManager(_db, _db.diaryEntries);
  $$WeighInsTableTableManager get weighIns =>
      $$WeighInsTableTableManager(_db, _db.weighIns);
  $$TargetsTableTableManager get targets =>
      $$TargetsTableTableManager(_db, _db.targets);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$RecipeItemsTableTableManager get recipeItems =>
      $$RecipeItemsTableTableManager(_db, _db.recipeItems);
  $$FoodsFtsTableTableManager get foodsFts =>
      $$FoodsFtsTableTableManager(_db, _db.foodsFts);
  $$SearchHistoryTableTableManager get searchHistory =>
      $$SearchHistoryTableTableManager(_db, _db.searchHistory);
  $$ConsumptionPatternsTableTableManager get consumptionPatterns =>
      $$ConsumptionPatternsTableTableManager(_db, _db.consumptionPatterns);
  $$MealTemplatesTableTableManager get mealTemplates =>
      $$MealTemplatesTableTableManager(_db, _db.mealTemplates);
  $$MealTemplateItemsTableTableManager get mealTemplateItems =>
      $$MealTemplateItemsTableTableManager(_db, _db.mealTemplateItems);
  $$BodyMeasurementsTableTableManager get bodyMeasurements =>
      $$BodyMeasurementsTableTableManager(_db, _db.bodyMeasurements);
  $$ProgressPhotosTableTableManager get progressPhotos =>
      $$ProgressPhotosTableTableManager(_db, _db.progressPhotos);
}
