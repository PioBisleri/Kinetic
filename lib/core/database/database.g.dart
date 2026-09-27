// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitSystemMeta = const VerificationMeta(
    'unitSystem',
  );
  @override
  late final GeneratedColumn<String> unitSystem = GeneratedColumn<String>(
    'unit_system',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('kg'),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dark'),
  );
  static const VerificationMeta _bodyweightKgMeta = const VerificationMeta(
    'bodyweightKg',
  );
  @override
  late final GeneratedColumn<double> bodyweightKg = GeneratedColumn<double>(
    'bodyweight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
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
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<String> birthDate = GeneratedColumn<String>(
    'birth_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyFatPctMeta = const VerificationMeta(
    'bodyFatPct',
  );
  @override
  late final GeneratedColumn<double> bodyFatPct = GeneratedColumn<double>(
    'body_fat_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trainingGoalMeta = const VerificationMeta(
    'trainingGoal',
  );
  @override
  late final GeneratedColumn<String> trainingGoal = GeneratedColumn<String>(
    'training_goal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    username,
    unitSystem,
    theme,
    bodyweightKg,
    heightCm,
    birthDate,
    sex,
    bodyFatPct,
    trainingGoal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('unit_system')) {
      context.handle(
        _unitSystemMeta,
        unitSystem.isAcceptableOrUnknown(data['unit_system']!, _unitSystemMeta),
      );
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    }
    if (data.containsKey('bodyweight_kg')) {
      context.handle(
        _bodyweightKgMeta,
        bodyweightKg.isAcceptableOrUnknown(
          data['bodyweight_kg']!,
          _bodyweightKgMeta,
        ),
      );
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    }
    if (data.containsKey('body_fat_pct')) {
      context.handle(
        _bodyFatPctMeta,
        bodyFatPct.isAcceptableOrUnknown(
          data['body_fat_pct']!,
          _bodyFatPctMeta,
        ),
      );
    }
    if (data.containsKey('training_goal')) {
      context.handle(
        _trainingGoalMeta,
        trainingGoal.isAcceptableOrUnknown(
          data['training_goal']!,
          _trainingGoalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      ),
      unitSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_system'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      bodyweightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bodyweight_kg'],
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birth_date'],
      ),
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      ),
      bodyFatPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}body_fat_pct'],
      ),
      trainingGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}training_goal'],
      ),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String? username;
  final String unitSystem;
  final String theme;
  final double? bodyweightKg;
  final double? heightCm;
  final String? birthDate;
  final String? sex;
  final double? bodyFatPct;
  final String? trainingGoal;
  const Profile({
    required this.updatedAt,
    this.syncedAt,
    this.deletedAt,
    required this.id,
    this.username,
    required this.unitSystem,
    required this.theme,
    this.bodyweightKg,
    this.heightCm,
    this.birthDate,
    this.sex,
    this.bodyFatPct,
    this.trainingGoal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    map['unit_system'] = Variable<String>(unitSystem);
    map['theme'] = Variable<String>(theme);
    if (!nullToAbsent || bodyweightKg != null) {
      map['bodyweight_kg'] = Variable<double>(bodyweightKg);
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<String>(birthDate);
    }
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>(sex);
    }
    if (!nullToAbsent || bodyFatPct != null) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct);
    }
    if (!nullToAbsent || trainingGoal != null) {
      map['training_goal'] = Variable<String>(trainingGoal);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      unitSystem: Value(unitSystem),
      theme: Value(theme),
      bodyweightKg: bodyweightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyweightKg),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      bodyFatPct: bodyFatPct == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPct),
      trainingGoal: trainingGoal == null && nullToAbsent
          ? const Value.absent()
          : Value(trainingGoal),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String?>(json['username']),
      unitSystem: serializer.fromJson<String>(json['unitSystem']),
      theme: serializer.fromJson<String>(json['theme']),
      bodyweightKg: serializer.fromJson<double?>(json['bodyweightKg']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      birthDate: serializer.fromJson<String?>(json['birthDate']),
      sex: serializer.fromJson<String?>(json['sex']),
      bodyFatPct: serializer.fromJson<double?>(json['bodyFatPct']),
      trainingGoal: serializer.fromJson<String?>(json['trainingGoal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String?>(username),
      'unitSystem': serializer.toJson<String>(unitSystem),
      'theme': serializer.toJson<String>(theme),
      'bodyweightKg': serializer.toJson<double?>(bodyweightKg),
      'heightCm': serializer.toJson<double?>(heightCm),
      'birthDate': serializer.toJson<String?>(birthDate),
      'sex': serializer.toJson<String?>(sex),
      'bodyFatPct': serializer.toJson<double?>(bodyFatPct),
      'trainingGoal': serializer.toJson<String?>(trainingGoal),
    };
  }

  Profile copyWith({
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    Value<String?> username = const Value.absent(),
    String? unitSystem,
    String? theme,
    Value<double?> bodyweightKg = const Value.absent(),
    Value<double?> heightCm = const Value.absent(),
    Value<String?> birthDate = const Value.absent(),
    Value<String?> sex = const Value.absent(),
    Value<double?> bodyFatPct = const Value.absent(),
    Value<String?> trainingGoal = const Value.absent(),
  }) => Profile(
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    username: username.present ? username.value : this.username,
    unitSystem: unitSystem ?? this.unitSystem,
    theme: theme ?? this.theme,
    bodyweightKg: bodyweightKg.present ? bodyweightKg.value : this.bodyweightKg,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    birthDate: birthDate.present ? birthDate.value : this.birthDate,
    sex: sex.present ? sex.value : this.sex,
    bodyFatPct: bodyFatPct.present ? bodyFatPct.value : this.bodyFatPct,
    trainingGoal: trainingGoal.present ? trainingGoal.value : this.trainingGoal,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      unitSystem: data.unitSystem.present
          ? data.unitSystem.value
          : this.unitSystem,
      theme: data.theme.present ? data.theme.value : this.theme,
      bodyweightKg: data.bodyweightKg.present
          ? data.bodyweightKg.value
          : this.bodyweightKg,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      sex: data.sex.present ? data.sex.value : this.sex,
      bodyFatPct: data.bodyFatPct.present
          ? data.bodyFatPct.value
          : this.bodyFatPct,
      trainingGoal: data.trainingGoal.present
          ? data.trainingGoal.value
          : this.trainingGoal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('unitSystem: $unitSystem, ')
          ..write('theme: $theme, ')
          ..write('bodyweightKg: $bodyweightKg, ')
          ..write('heightCm: $heightCm, ')
          ..write('birthDate: $birthDate, ')
          ..write('sex: $sex, ')
          ..write('bodyFatPct: $bodyFatPct, ')
          ..write('trainingGoal: $trainingGoal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    username,
    unitSystem,
    theme,
    bodyweightKg,
    heightCm,
    birthDate,
    sex,
    bodyFatPct,
    trainingGoal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.username == this.username &&
          other.unitSystem == this.unitSystem &&
          other.theme == this.theme &&
          other.bodyweightKg == this.bodyweightKg &&
          other.heightCm == this.heightCm &&
          other.birthDate == this.birthDate &&
          other.sex == this.sex &&
          other.bodyFatPct == this.bodyFatPct &&
          other.trainingGoal == this.trainingGoal);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String?> username;
  final Value<String> unitSystem;
  final Value<String> theme;
  final Value<double?> bodyweightKg;
  final Value<double?> heightCm;
  final Value<String?> birthDate;
  final Value<String?> sex;
  final Value<double?> bodyFatPct;
  final Value<String?> trainingGoal;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.unitSystem = const Value.absent(),
    this.theme = const Value.absent(),
    this.bodyweightKg = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.sex = const Value.absent(),
    this.bodyFatPct = const Value.absent(),
    this.trainingGoal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    this.username = const Value.absent(),
    this.unitSystem = const Value.absent(),
    this.theme = const Value.absent(),
    this.bodyweightKg = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.sex = const Value.absent(),
    this.bodyFatPct = const Value.absent(),
    this.trainingGoal = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       id = Value(id);
  static Insertable<Profile> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? username,
    Expression<String>? unitSystem,
    Expression<String>? theme,
    Expression<double>? bodyweightKg,
    Expression<double>? heightCm,
    Expression<String>? birthDate,
    Expression<String>? sex,
    Expression<double>? bodyFatPct,
    Expression<String>? trainingGoal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (unitSystem != null) 'unit_system': unitSystem,
      if (theme != null) 'theme': theme,
      if (bodyweightKg != null) 'bodyweight_kg': bodyweightKg,
      if (heightCm != null) 'height_cm': heightCm,
      if (birthDate != null) 'birth_date': birthDate,
      if (sex != null) 'sex': sex,
      if (bodyFatPct != null) 'body_fat_pct': bodyFatPct,
      if (trainingGoal != null) 'training_goal': trainingGoal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String?>? username,
    Value<String>? unitSystem,
    Value<String>? theme,
    Value<double?>? bodyweightKg,
    Value<double?>? heightCm,
    Value<String?>? birthDate,
    Value<String?>? sex,
    Value<double?>? bodyFatPct,
    Value<String?>? trainingGoal,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      username: username ?? this.username,
      unitSystem: unitSystem ?? this.unitSystem,
      theme: theme ?? this.theme,
      bodyweightKg: bodyweightKg ?? this.bodyweightKg,
      heightCm: heightCm ?? this.heightCm,
      birthDate: birthDate ?? this.birthDate,
      sex: sex ?? this.sex,
      bodyFatPct: bodyFatPct ?? this.bodyFatPct,
      trainingGoal: trainingGoal ?? this.trainingGoal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (unitSystem.present) {
      map['unit_system'] = Variable<String>(unitSystem.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (bodyweightKg.present) {
      map['bodyweight_kg'] = Variable<double>(bodyweightKg.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<String>(birthDate.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (bodyFatPct.present) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct.value);
    }
    if (trainingGoal.present) {
      map['training_goal'] = Variable<String>(trainingGoal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('unitSystem: $unitSystem, ')
          ..write('theme: $theme, ')
          ..write('bodyweightKg: $bodyweightKg, ')
          ..write('heightCm: $heightCm, ')
          ..write('birthDate: $birthDate, ')
          ..write('sex: $sex, ')
          ..write('bodyFatPct: $bodyFatPct, ')
          ..write('trainingGoal: $trainingGoal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MuscleGroupsTable extends MuscleGroups
    with TableInfo<$MuscleGroupsTable, MuscleGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MuscleGroupsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
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
  static const VerificationMeta _heatmapNodesMeta = const VerificationMeta(
    'heatmapNodes',
  );
  @override
  late final GeneratedColumn<String> heatmapNodes = GeneratedColumn<String>(
    'heatmap_nodes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    parentId,
    name,
    heatmapNodes,
    orderIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'muscle_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<MuscleGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
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
    if (data.containsKey('heatmap_nodes')) {
      context.handle(
        _heatmapNodesMeta,
        heatmapNodes.isAcceptableOrUnknown(
          data['heatmap_nodes']!,
          _heatmapNodesMeta,
        ),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MuscleGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MuscleGroup(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      heatmapNodes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heatmap_nodes'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $MuscleGroupsTable createAlias(String alias) {
    return $MuscleGroupsTable(attachedDatabase, alias);
  }
}

class MuscleGroup extends DataClass implements Insertable<MuscleGroup> {
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String? parentId;
  final String name;
  final String heatmapNodes;
  final int orderIndex;
  const MuscleGroup({
    required this.updatedAt,
    this.syncedAt,
    this.deletedAt,
    required this.id,
    this.parentId,
    required this.name,
    required this.heatmapNodes,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    map['heatmap_nodes'] = Variable<String>(heatmapNodes);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  MuscleGroupsCompanion toCompanion(bool nullToAbsent) {
    return MuscleGroupsCompanion(
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      heatmapNodes: Value(heatmapNodes),
      orderIndex: Value(orderIndex),
    );
  }

  factory MuscleGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MuscleGroup(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      heatmapNodes: serializer.fromJson<String>(json['heatmapNodes']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'heatmapNodes': serializer.toJson<String>(heatmapNodes),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  MuscleGroup copyWith({
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? name,
    String? heatmapNodes,
    int? orderIndex,
  }) => MuscleGroup(
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    name: name ?? this.name,
    heatmapNodes: heatmapNodes ?? this.heatmapNodes,
    orderIndex: orderIndex ?? this.orderIndex,
  );
  MuscleGroup copyWithCompanion(MuscleGroupsCompanion data) {
    return MuscleGroup(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      heatmapNodes: data.heatmapNodes.present
          ? data.heatmapNodes.value
          : this.heatmapNodes,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MuscleGroup(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('heatmapNodes: $heatmapNodes, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    parentId,
    name,
    heatmapNodes,
    orderIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MuscleGroup &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.heatmapNodes == this.heatmapNodes &&
          other.orderIndex == this.orderIndex);
}

class MuscleGroupsCompanion extends UpdateCompanion<MuscleGroup> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<String> heatmapNodes;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const MuscleGroupsCompanion({
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.heatmapNodes = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MuscleGroupsCompanion.insert({
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    this.parentId = const Value.absent(),
    required String name,
    this.heatmapNodes = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       id = Value(id),
       name = Value(name);
  static Insertable<MuscleGroup> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<String>? heatmapNodes,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (heatmapNodes != null) 'heatmap_nodes': heatmapNodes,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MuscleGroupsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? name,
    Value<String>? heatmapNodes,
    Value<int>? orderIndex,
    Value<int>? rowid,
  }) {
    return MuscleGroupsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      heatmapNodes: heatmapNodes ?? this.heatmapNodes,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (heatmapNodes.present) {
      map['heatmap_nodes'] = Variable<String>(heatmapNodes.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MuscleGroupsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('heatmapNodes: $heatmapNodes, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
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
  static const VerificationMeta _mechanicsMeta = const VerificationMeta(
    'mechanics',
  );
  @override
  late final GeneratedColumn<String> mechanics = GeneratedColumn<String>(
    'mechanics',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _forceTypeMeta = const VerificationMeta(
    'forceType',
  );
  @override
  late final GeneratedColumn<String> forceType = GeneratedColumn<String>(
    'force_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    defaultValue: const Constant('barbell'),
  );
  static const VerificationMeta _primaryMuscleIdMeta = const VerificationMeta(
    'primaryMuscleId',
  );
  @override
  late final GeneratedColumn<String> primaryMuscleId = GeneratedColumn<String>(
    'primary_muscle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _defaultMetricMeta = const VerificationMeta(
    'defaultMetric',
  );
  @override
  late final GeneratedColumn<String> defaultMetric = GeneratedColumn<String>(
    'default_metric',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('weight_reps'),
  );
  static const VerificationMeta _animationKindMeta = const VerificationMeta(
    'animationKind',
  );
  @override
  late final GeneratedColumn<String> animationKind = GeneratedColumn<String>(
    'animation_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _animationRefMeta = const VerificationMeta(
    'animationRef',
  );
  @override
  late final GeneratedColumn<String> animationRef = GeneratedColumn<String>(
    'animation_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailRefMeta = const VerificationMeta(
    'thumbnailRef',
  );
  @override
  late final GeneratedColumn<String> thumbnailRef = GeneratedColumn<String>(
    'thumbnail_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
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
  static const VerificationMeta _progressionIncrementKgMeta =
      const VerificationMeta('progressionIncrementKg');
  @override
  late final GeneratedColumn<double> progressionIncrementKg =
      GeneratedColumn<double>(
        'progression_increment_kg',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    name,
    mechanics,
    forceType,
    category,
    primaryMuscleId,
    equipment,
    defaultMetric,
    animationKind,
    animationRef,
    thumbnailRef,
    isCustom,
    ownerId,
    restSeconds,
    progressionIncrementKg,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
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
    if (data.containsKey('mechanics')) {
      context.handle(
        _mechanicsMeta,
        mechanics.isAcceptableOrUnknown(data['mechanics']!, _mechanicsMeta),
      );
    } else if (isInserting) {
      context.missing(_mechanicsMeta);
    }
    if (data.containsKey('force_type')) {
      context.handle(
        _forceTypeMeta,
        forceType.isAcceptableOrUnknown(data['force_type']!, _forceTypeMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('primary_muscle_id')) {
      context.handle(
        _primaryMuscleIdMeta,
        primaryMuscleId.isAcceptableOrUnknown(
          data['primary_muscle_id']!,
          _primaryMuscleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_primaryMuscleIdMeta);
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    }
    if (data.containsKey('default_metric')) {
      context.handle(
        _defaultMetricMeta,
        defaultMetric.isAcceptableOrUnknown(
          data['default_metric']!,
          _defaultMetricMeta,
        ),
      );
    }
    if (data.containsKey('animation_kind')) {
      context.handle(
        _animationKindMeta,
        animationKind.isAcceptableOrUnknown(
          data['animation_kind']!,
          _animationKindMeta,
        ),
      );
    }
    if (data.containsKey('animation_ref')) {
      context.handle(
        _animationRefMeta,
        animationRef.isAcceptableOrUnknown(
          data['animation_ref']!,
          _animationRefMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_ref')) {
      context.handle(
        _thumbnailRefMeta,
        thumbnailRef.isAcceptableOrUnknown(
          data['thumbnail_ref']!,
          _thumbnailRefMeta,
        ),
      );
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
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
    if (data.containsKey('progression_increment_kg')) {
      context.handle(
        _progressionIncrementKgMeta,
        progressionIncrementKg.isAcceptableOrUnknown(
          data['progression_increment_kg']!,
          _progressionIncrementKgMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      mechanics: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mechanics'],
      )!,
      forceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}force_type'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      primaryMuscleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_muscle_id'],
      )!,
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      )!,
      defaultMetric: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_metric'],
      )!,
      animationKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}animation_kind'],
      )!,
      animationRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}animation_ref'],
      ),
      thumbnailRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_ref'],
      ),
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      restSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_seconds'],
      ),
      progressionIncrementKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progression_increment_kg'],
      ),
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String name;
  final String mechanics;
  final String? forceType;
  final String category;
  final String primaryMuscleId;
  final String equipment;
  final String defaultMetric;
  final String animationKind;
  final String? animationRef;
  final String? thumbnailRef;
  final bool isCustom;
  final String? ownerId;

  /// Rest between sets of this exercise in seconds; null = inherit the
  /// Settings default for the set type.
  final int? restSeconds;

  /// Progression step for this exercise in kg; null = inherit the unit
  /// default (2.5 kg / 5 lb). Canonical kg, like every other weight.
  final double? progressionIncrementKg;
  const Exercise({
    required this.updatedAt,
    this.syncedAt,
    this.deletedAt,
    required this.id,
    required this.name,
    required this.mechanics,
    this.forceType,
    required this.category,
    required this.primaryMuscleId,
    required this.equipment,
    required this.defaultMetric,
    required this.animationKind,
    this.animationRef,
    this.thumbnailRef,
    required this.isCustom,
    this.ownerId,
    this.restSeconds,
    this.progressionIncrementKg,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['mechanics'] = Variable<String>(mechanics);
    if (!nullToAbsent || forceType != null) {
      map['force_type'] = Variable<String>(forceType);
    }
    map['category'] = Variable<String>(category);
    map['primary_muscle_id'] = Variable<String>(primaryMuscleId);
    map['equipment'] = Variable<String>(equipment);
    map['default_metric'] = Variable<String>(defaultMetric);
    map['animation_kind'] = Variable<String>(animationKind);
    if (!nullToAbsent || animationRef != null) {
      map['animation_ref'] = Variable<String>(animationRef);
    }
    if (!nullToAbsent || thumbnailRef != null) {
      map['thumbnail_ref'] = Variable<String>(thumbnailRef);
    }
    map['is_custom'] = Variable<bool>(isCustom);
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    if (!nullToAbsent || restSeconds != null) {
      map['rest_seconds'] = Variable<int>(restSeconds);
    }
    if (!nullToAbsent || progressionIncrementKg != null) {
      map['progression_increment_kg'] = Variable<double>(
        progressionIncrementKg,
      );
    }
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      name: Value(name),
      mechanics: Value(mechanics),
      forceType: forceType == null && nullToAbsent
          ? const Value.absent()
          : Value(forceType),
      category: Value(category),
      primaryMuscleId: Value(primaryMuscleId),
      equipment: Value(equipment),
      defaultMetric: Value(defaultMetric),
      animationKind: Value(animationKind),
      animationRef: animationRef == null && nullToAbsent
          ? const Value.absent()
          : Value(animationRef),
      thumbnailRef: thumbnailRef == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailRef),
      isCustom: Value(isCustom),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      restSeconds: restSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(restSeconds),
      progressionIncrementKg: progressionIncrementKg == null && nullToAbsent
          ? const Value.absent()
          : Value(progressionIncrementKg),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      mechanics: serializer.fromJson<String>(json['mechanics']),
      forceType: serializer.fromJson<String?>(json['forceType']),
      category: serializer.fromJson<String>(json['category']),
      primaryMuscleId: serializer.fromJson<String>(json['primaryMuscleId']),
      equipment: serializer.fromJson<String>(json['equipment']),
      defaultMetric: serializer.fromJson<String>(json['defaultMetric']),
      animationKind: serializer.fromJson<String>(json['animationKind']),
      animationRef: serializer.fromJson<String?>(json['animationRef']),
      thumbnailRef: serializer.fromJson<String?>(json['thumbnailRef']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      restSeconds: serializer.fromJson<int?>(json['restSeconds']),
      progressionIncrementKg: serializer.fromJson<double?>(
        json['progressionIncrementKg'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'mechanics': serializer.toJson<String>(mechanics),
      'forceType': serializer.toJson<String?>(forceType),
      'category': serializer.toJson<String>(category),
      'primaryMuscleId': serializer.toJson<String>(primaryMuscleId),
      'equipment': serializer.toJson<String>(equipment),
      'defaultMetric': serializer.toJson<String>(defaultMetric),
      'animationKind': serializer.toJson<String>(animationKind),
      'animationRef': serializer.toJson<String?>(animationRef),
      'thumbnailRef': serializer.toJson<String?>(thumbnailRef),
      'isCustom': serializer.toJson<bool>(isCustom),
      'ownerId': serializer.toJson<String?>(ownerId),
      'restSeconds': serializer.toJson<int?>(restSeconds),
      'progressionIncrementKg': serializer.toJson<double?>(
        progressionIncrementKg,
      ),
    };
  }

  Exercise copyWith({
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? name,
    String? mechanics,
    Value<String?> forceType = const Value.absent(),
    String? category,
    String? primaryMuscleId,
    String? equipment,
    String? defaultMetric,
    String? animationKind,
    Value<String?> animationRef = const Value.absent(),
    Value<String?> thumbnailRef = const Value.absent(),
    bool? isCustom,
    Value<String?> ownerId = const Value.absent(),
    Value<int?> restSeconds = const Value.absent(),
    Value<double?> progressionIncrementKg = const Value.absent(),
  }) => Exercise(
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    name: name ?? this.name,
    mechanics: mechanics ?? this.mechanics,
    forceType: forceType.present ? forceType.value : this.forceType,
    category: category ?? this.category,
    primaryMuscleId: primaryMuscleId ?? this.primaryMuscleId,
    equipment: equipment ?? this.equipment,
    defaultMetric: defaultMetric ?? this.defaultMetric,
    animationKind: animationKind ?? this.animationKind,
    animationRef: animationRef.present ? animationRef.value : this.animationRef,
    thumbnailRef: thumbnailRef.present ? thumbnailRef.value : this.thumbnailRef,
    isCustom: isCustom ?? this.isCustom,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    restSeconds: restSeconds.present ? restSeconds.value : this.restSeconds,
    progressionIncrementKg: progressionIncrementKg.present
        ? progressionIncrementKg.value
        : this.progressionIncrementKg,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      mechanics: data.mechanics.present ? data.mechanics.value : this.mechanics,
      forceType: data.forceType.present ? data.forceType.value : this.forceType,
      category: data.category.present ? data.category.value : this.category,
      primaryMuscleId: data.primaryMuscleId.present
          ? data.primaryMuscleId.value
          : this.primaryMuscleId,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      defaultMetric: data.defaultMetric.present
          ? data.defaultMetric.value
          : this.defaultMetric,
      animationKind: data.animationKind.present
          ? data.animationKind.value
          : this.animationKind,
      animationRef: data.animationRef.present
          ? data.animationRef.value
          : this.animationRef,
      thumbnailRef: data.thumbnailRef.present
          ? data.thumbnailRef.value
          : this.thumbnailRef,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      restSeconds: data.restSeconds.present
          ? data.restSeconds.value
          : this.restSeconds,
      progressionIncrementKg: data.progressionIncrementKg.present
          ? data.progressionIncrementKg.value
          : this.progressionIncrementKg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mechanics: $mechanics, ')
          ..write('forceType: $forceType, ')
          ..write('category: $category, ')
          ..write('primaryMuscleId: $primaryMuscleId, ')
          ..write('equipment: $equipment, ')
          ..write('defaultMetric: $defaultMetric, ')
          ..write('animationKind: $animationKind, ')
          ..write('animationRef: $animationRef, ')
          ..write('thumbnailRef: $thumbnailRef, ')
          ..write('isCustom: $isCustom, ')
          ..write('ownerId: $ownerId, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('progressionIncrementKg: $progressionIncrementKg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    name,
    mechanics,
    forceType,
    category,
    primaryMuscleId,
    equipment,
    defaultMetric,
    animationKind,
    animationRef,
    thumbnailRef,
    isCustom,
    ownerId,
    restSeconds,
    progressionIncrementKg,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.name == this.name &&
          other.mechanics == this.mechanics &&
          other.forceType == this.forceType &&
          other.category == this.category &&
          other.primaryMuscleId == this.primaryMuscleId &&
          other.equipment == this.equipment &&
          other.defaultMetric == this.defaultMetric &&
          other.animationKind == this.animationKind &&
          other.animationRef == this.animationRef &&
          other.thumbnailRef == this.thumbnailRef &&
          other.isCustom == this.isCustom &&
          other.ownerId == this.ownerId &&
          other.restSeconds == this.restSeconds &&
          other.progressionIncrementKg == this.progressionIncrementKg);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> name;
  final Value<String> mechanics;
  final Value<String?> forceType;
  final Value<String> category;
  final Value<String> primaryMuscleId;
  final Value<String> equipment;
  final Value<String> defaultMetric;
  final Value<String> animationKind;
  final Value<String?> animationRef;
  final Value<String?> thumbnailRef;
  final Value<bool> isCustom;
  final Value<String?> ownerId;
  final Value<int?> restSeconds;
  final Value<double?> progressionIncrementKg;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.mechanics = const Value.absent(),
    this.forceType = const Value.absent(),
    this.category = const Value.absent(),
    this.primaryMuscleId = const Value.absent(),
    this.equipment = const Value.absent(),
    this.defaultMetric = const Value.absent(),
    this.animationKind = const Value.absent(),
    this.animationRef = const Value.absent(),
    this.thumbnailRef = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.progressionIncrementKg = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String name,
    required String mechanics,
    this.forceType = const Value.absent(),
    this.category = const Value.absent(),
    required String primaryMuscleId,
    this.equipment = const Value.absent(),
    this.defaultMetric = const Value.absent(),
    this.animationKind = const Value.absent(),
    this.animationRef = const Value.absent(),
    this.thumbnailRef = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.progressionIncrementKg = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       id = Value(id),
       name = Value(name),
       mechanics = Value(mechanics),
       primaryMuscleId = Value(primaryMuscleId);
  static Insertable<Exercise> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? mechanics,
    Expression<String>? forceType,
    Expression<String>? category,
    Expression<String>? primaryMuscleId,
    Expression<String>? equipment,
    Expression<String>? defaultMetric,
    Expression<String>? animationKind,
    Expression<String>? animationRef,
    Expression<String>? thumbnailRef,
    Expression<bool>? isCustom,
    Expression<String>? ownerId,
    Expression<int>? restSeconds,
    Expression<double>? progressionIncrementKg,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (mechanics != null) 'mechanics': mechanics,
      if (forceType != null) 'force_type': forceType,
      if (category != null) 'category': category,
      if (primaryMuscleId != null) 'primary_muscle_id': primaryMuscleId,
      if (equipment != null) 'equipment': equipment,
      if (defaultMetric != null) 'default_metric': defaultMetric,
      if (animationKind != null) 'animation_kind': animationKind,
      if (animationRef != null) 'animation_ref': animationRef,
      if (thumbnailRef != null) 'thumbnail_ref': thumbnailRef,
      if (isCustom != null) 'is_custom': isCustom,
      if (ownerId != null) 'owner_id': ownerId,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (progressionIncrementKg != null)
        'progression_increment_kg': progressionIncrementKg,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? name,
    Value<String>? mechanics,
    Value<String?>? forceType,
    Value<String>? category,
    Value<String>? primaryMuscleId,
    Value<String>? equipment,
    Value<String>? defaultMetric,
    Value<String>? animationKind,
    Value<String?>? animationRef,
    Value<String?>? thumbnailRef,
    Value<bool>? isCustom,
    Value<String?>? ownerId,
    Value<int?>? restSeconds,
    Value<double?>? progressionIncrementKg,
    Value<int>? rowid,
  }) {
    return ExercisesCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      name: name ?? this.name,
      mechanics: mechanics ?? this.mechanics,
      forceType: forceType ?? this.forceType,
      category: category ?? this.category,
      primaryMuscleId: primaryMuscleId ?? this.primaryMuscleId,
      equipment: equipment ?? this.equipment,
      defaultMetric: defaultMetric ?? this.defaultMetric,
      animationKind: animationKind ?? this.animationKind,
      animationRef: animationRef ?? this.animationRef,
      thumbnailRef: thumbnailRef ?? this.thumbnailRef,
      isCustom: isCustom ?? this.isCustom,
      ownerId: ownerId ?? this.ownerId,
      restSeconds: restSeconds ?? this.restSeconds,
      progressionIncrementKg:
          progressionIncrementKg ?? this.progressionIncrementKg,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mechanics.present) {
      map['mechanics'] = Variable<String>(mechanics.value);
    }
    if (forceType.present) {
      map['force_type'] = Variable<String>(forceType.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (primaryMuscleId.present) {
      map['primary_muscle_id'] = Variable<String>(primaryMuscleId.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (defaultMetric.present) {
      map['default_metric'] = Variable<String>(defaultMetric.value);
    }
    if (animationKind.present) {
      map['animation_kind'] = Variable<String>(animationKind.value);
    }
    if (animationRef.present) {
      map['animation_ref'] = Variable<String>(animationRef.value);
    }
    if (thumbnailRef.present) {
      map['thumbnail_ref'] = Variable<String>(thumbnailRef.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (progressionIncrementKg.present) {
      map['progression_increment_kg'] = Variable<double>(
        progressionIncrementKg.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mechanics: $mechanics, ')
          ..write('forceType: $forceType, ')
          ..write('category: $category, ')
          ..write('primaryMuscleId: $primaryMuscleId, ')
          ..write('equipment: $equipment, ')
          ..write('defaultMetric: $defaultMetric, ')
          ..write('animationKind: $animationKind, ')
          ..write('animationRef: $animationRef, ')
          ..write('thumbnailRef: $thumbnailRef, ')
          ..write('isCustom: $isCustom, ')
          ..write('ownerId: $ownerId, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('progressionIncrementKg: $progressionIncrementKg, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseMuscleMapTable extends ExerciseMuscleMap
    with TableInfo<$ExerciseMuscleMapTable, ExerciseMuscleMapData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseMuscleMapTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _muscleIdMeta = const VerificationMeta(
    'muscleId',
  );
  @override
  late final GeneratedColumn<String> muscleId = GeneratedColumn<String>(
    'muscle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contributionMeta = const VerificationMeta(
    'contribution',
  );
  @override
  late final GeneratedColumn<double> contribution = GeneratedColumn<double>(
    'contribution',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('secondary'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    exerciseId,
    muscleId,
    contribution,
    role,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_muscle_map';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseMuscleMapData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('muscle_id')) {
      context.handle(
        _muscleIdMeta,
        muscleId.isAcceptableOrUnknown(data['muscle_id']!, _muscleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_muscleIdMeta);
    }
    if (data.containsKey('contribution')) {
      context.handle(
        _contributionMeta,
        contribution.isAcceptableOrUnknown(
          data['contribution']!,
          _contributionMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exerciseId, muscleId};
  @override
  ExerciseMuscleMapData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseMuscleMapData(
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      muscleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}muscle_id'],
      )!,
      contribution: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}contribution'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
    );
  }

  @override
  $ExerciseMuscleMapTable createAlias(String alias) {
    return $ExerciseMuscleMapTable(attachedDatabase, alias);
  }
}

class ExerciseMuscleMapData extends DataClass
    implements Insertable<ExerciseMuscleMapData> {
  final String exerciseId;
  final String muscleId;

  /// 0..1 — share of stimulus credited to this muscle (bench: chest 1.0,
  /// triceps 0.5). Drives volume attribution and the Muscle Grade engine.
  final double contribution;
  final String role;
  const ExerciseMuscleMapData({
    required this.exerciseId,
    required this.muscleId,
    required this.contribution,
    required this.role,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_id'] = Variable<String>(exerciseId);
    map['muscle_id'] = Variable<String>(muscleId);
    map['contribution'] = Variable<double>(contribution);
    map['role'] = Variable<String>(role);
    return map;
  }

  ExerciseMuscleMapCompanion toCompanion(bool nullToAbsent) {
    return ExerciseMuscleMapCompanion(
      exerciseId: Value(exerciseId),
      muscleId: Value(muscleId),
      contribution: Value(contribution),
      role: Value(role),
    );
  }

  factory ExerciseMuscleMapData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseMuscleMapData(
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      muscleId: serializer.fromJson<String>(json['muscleId']),
      contribution: serializer.fromJson<double>(json['contribution']),
      role: serializer.fromJson<String>(json['role']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseId': serializer.toJson<String>(exerciseId),
      'muscleId': serializer.toJson<String>(muscleId),
      'contribution': serializer.toJson<double>(contribution),
      'role': serializer.toJson<String>(role),
    };
  }

  ExerciseMuscleMapData copyWith({
    String? exerciseId,
    String? muscleId,
    double? contribution,
    String? role,
  }) => ExerciseMuscleMapData(
    exerciseId: exerciseId ?? this.exerciseId,
    muscleId: muscleId ?? this.muscleId,
    contribution: contribution ?? this.contribution,
    role: role ?? this.role,
  );
  ExerciseMuscleMapData copyWithCompanion(ExerciseMuscleMapCompanion data) {
    return ExerciseMuscleMapData(
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      muscleId: data.muscleId.present ? data.muscleId.value : this.muscleId,
      contribution: data.contribution.present
          ? data.contribution.value
          : this.contribution,
      role: data.role.present ? data.role.value : this.role,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseMuscleMapData(')
          ..write('exerciseId: $exerciseId, ')
          ..write('muscleId: $muscleId, ')
          ..write('contribution: $contribution, ')
          ..write('role: $role')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exerciseId, muscleId, contribution, role);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseMuscleMapData &&
          other.exerciseId == this.exerciseId &&
          other.muscleId == this.muscleId &&
          other.contribution == this.contribution &&
          other.role == this.role);
}

class ExerciseMuscleMapCompanion
    extends UpdateCompanion<ExerciseMuscleMapData> {
  final Value<String> exerciseId;
  final Value<String> muscleId;
  final Value<double> contribution;
  final Value<String> role;
  final Value<int> rowid;
  const ExerciseMuscleMapCompanion({
    this.exerciseId = const Value.absent(),
    this.muscleId = const Value.absent(),
    this.contribution = const Value.absent(),
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseMuscleMapCompanion.insert({
    required String exerciseId,
    required String muscleId,
    this.contribution = const Value.absent(),
    this.role = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       muscleId = Value(muscleId);
  static Insertable<ExerciseMuscleMapData> custom({
    Expression<String>? exerciseId,
    Expression<String>? muscleId,
    Expression<double>? contribution,
    Expression<String>? role,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (muscleId != null) 'muscle_id': muscleId,
      if (contribution != null) 'contribution': contribution,
      if (role != null) 'role': role,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseMuscleMapCompanion copyWith({
    Value<String>? exerciseId,
    Value<String>? muscleId,
    Value<double>? contribution,
    Value<String>? role,
    Value<int>? rowid,
  }) {
    return ExerciseMuscleMapCompanion(
      exerciseId: exerciseId ?? this.exerciseId,
      muscleId: muscleId ?? this.muscleId,
      contribution: contribution ?? this.contribution,
      role: role ?? this.role,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (muscleId.present) {
      map['muscle_id'] = Variable<String>(muscleId.value);
    }
    if (contribution.present) {
      map['contribution'] = Variable<double>(contribution.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseMuscleMapCompanion(')
          ..write('exerciseId: $exerciseId, ')
          ..write('muscleId: $muscleId, ')
          ..write('contribution: $contribution, ')
          ..write('role: $role, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutinesTable extends Routines with TableInfo<$RoutinesTable, Routine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutinesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
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
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    userId,
    name,
    description,
    orderIndex,
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
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
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
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
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $RoutinesTable createAlias(String alias) {
    return $RoutinesTable(attachedDatabase, alias);
  }
}

class Routine extends DataClass implements Insertable<Routine> {
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String userId;
  final String name;
  final String? description;
  final int orderIndex;
  const Routine({
    required this.updatedAt,
    this.syncedAt,
    this.deletedAt,
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  RoutinesCompanion toCompanion(bool nullToAbsent) {
    return RoutinesCompanion(
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      orderIndex: Value(orderIndex),
    );
  }

  factory Routine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Routine(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  Routine copyWith({
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? userId,
    String? name,
    Value<String?> description = const Value.absent(),
    int? orderIndex,
  }) => Routine(
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    orderIndex: orderIndex ?? this.orderIndex,
  );
  Routine copyWithCompanion(RoutinesCompanion data) {
    return Routine(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Routine(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    userId,
    name,
    description,
    orderIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Routine &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.description == this.description &&
          other.orderIndex == this.orderIndex);
}

class RoutinesCompanion extends UpdateCompanion<Routine> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const RoutinesCompanion({
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutinesCompanion.insert({
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String userId,
    required String name,
    this.description = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       id = Value(id),
       userId = Value(userId),
       name = Value(name);
  static Insertable<Routine> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutinesCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? orderIndex,
    Value<int>? rowid,
  }) {
    return RoutinesCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutinesCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('orderIndex: $orderIndex, ')
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
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
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supersetGroupMeta = const VerificationMeta(
    'supersetGroup',
  );
  @override
  late final GeneratedColumn<int> supersetGroup = GeneratedColumn<int>(
    'superset_group',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetSetsMeta = const VerificationMeta(
    'targetSets',
  );
  @override
  late final GeneratedColumn<int> targetSets = GeneratedColumn<int>(
    'target_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _targetRepsMeta = const VerificationMeta(
    'targetReps',
  );
  @override
  late final GeneratedColumn<int> targetReps = GeneratedColumn<int>(
    'target_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(8),
  );
  static const VerificationMeta _targetRpeMeta = const VerificationMeta(
    'targetRpe',
  );
  @override
  late final GeneratedColumn<double> targetRpe = GeneratedColumn<double>(
    'target_rpe',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetWeightMeta = const VerificationMeta(
    'targetWeight',
  );
  @override
  late final GeneratedColumn<double> targetWeight = GeneratedColumn<double>(
    'target_weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restSecondsMeta = const VerificationMeta(
    'restSeconds',
  );
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
    'rest_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(90),
  );
  static const VerificationMeta _warmupSetsMeta = const VerificationMeta(
    'warmupSets',
  );
  @override
  late final GeneratedColumn<int> warmupSets = GeneratedColumn<int>(
    'warmup_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dropSetsMeta = const VerificationMeta(
    'dropSets',
  );
  @override
  late final GeneratedColumn<int> dropSets = GeneratedColumn<int>(
    'drop_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _failureSetsMeta = const VerificationMeta(
    'failureSets',
  );
  @override
  late final GeneratedColumn<int> failureSets = GeneratedColumn<int>(
    'failure_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    routineId,
    exerciseId,
    orderIndex,
    supersetGroup,
    targetSets,
    targetReps,
    targetRpe,
    targetWeight,
    restSeconds,
    warmupSets,
    dropSets,
    failureSets,
    isWarmup,
    notes,
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
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
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('superset_group')) {
      context.handle(
        _supersetGroupMeta,
        supersetGroup.isAcceptableOrUnknown(
          data['superset_group']!,
          _supersetGroupMeta,
        ),
      );
    }
    if (data.containsKey('target_sets')) {
      context.handle(
        _targetSetsMeta,
        targetSets.isAcceptableOrUnknown(data['target_sets']!, _targetSetsMeta),
      );
    }
    if (data.containsKey('target_reps')) {
      context.handle(
        _targetRepsMeta,
        targetReps.isAcceptableOrUnknown(data['target_reps']!, _targetRepsMeta),
      );
    }
    if (data.containsKey('target_rpe')) {
      context.handle(
        _targetRpeMeta,
        targetRpe.isAcceptableOrUnknown(data['target_rpe']!, _targetRpeMeta),
      );
    }
    if (data.containsKey('target_weight')) {
      context.handle(
        _targetWeightMeta,
        targetWeight.isAcceptableOrUnknown(
          data['target_weight']!,
          _targetWeightMeta,
        ),
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
    if (data.containsKey('warmup_sets')) {
      context.handle(
        _warmupSetsMeta,
        warmupSets.isAcceptableOrUnknown(data['warmup_sets']!, _warmupSetsMeta),
      );
    }
    if (data.containsKey('drop_sets')) {
      context.handle(
        _dropSetsMeta,
        dropSets.isAcceptableOrUnknown(data['drop_sets']!, _dropSetsMeta),
      );
    }
    if (data.containsKey('failure_sets')) {
      context.handle(
        _failureSetsMeta,
        failureSets.isAcceptableOrUnknown(
          data['failure_sets']!,
          _failureSetsMeta,
        ),
      );
    }
    if (data.containsKey('is_warmup')) {
      context.handle(
        _isWarmupMeta,
        isWarmup.isAcceptableOrUnknown(data['is_warmup']!, _isWarmupMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      supersetGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}superset_group'],
      ),
      targetSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_sets'],
      )!,
      targetReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_reps'],
      )!,
      targetRpe: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_rpe'],
      ),
      targetWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_weight'],
      ),
      restSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_seconds'],
      )!,
      warmupSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warmup_sets'],
      )!,
      dropSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}drop_sets'],
      )!,
      failureSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failure_sets'],
      )!,
      isWarmup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_warmup'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $RoutineExercisesTable createAlias(String alias) {
    return $RoutineExercisesTable(attachedDatabase, alias);
  }
}

class RoutineExercise extends DataClass implements Insertable<RoutineExercise> {
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String routineId;
  final String exerciseId;
  final int orderIndex;
  final int? supersetGroup;
  final int targetSets;
  final int targetReps;
  final double? targetRpe;
  final double? targetWeight;

  /// Rest after each set of this entry in seconds.
  /// [inheritRestSeconds] = -1 → fall through to the exercise override,
  /// then to the per-type Settings default. (Kept NOT NULL so the column
  /// can be added by `ALTER TABLE` without a table rebuild.)
  final int restSeconds;

  /// Per-type planned set counts (Hevy-style). `targetSets` stays the
  /// TOTAL planned sets; working = targetSets − warmup − drop − failure.
  final int warmupSets;
  final int dropSets;
  final int failureSets;

  /// Legacy v1/v2 flag: the whole entry was warm-up. Kept for wire
  /// compatibility; derived from [warmupSets] on write since v3.
  final bool isWarmup;
  final String? notes;
  const RoutineExercise({
    required this.updatedAt,
    this.syncedAt,
    this.deletedAt,
    required this.id,
    required this.routineId,
    required this.exerciseId,
    required this.orderIndex,
    this.supersetGroup,
    required this.targetSets,
    required this.targetReps,
    this.targetRpe,
    this.targetWeight,
    required this.restSeconds,
    required this.warmupSets,
    required this.dropSets,
    required this.failureSets,
    required this.isWarmup,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['routine_id'] = Variable<String>(routineId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || supersetGroup != null) {
      map['superset_group'] = Variable<int>(supersetGroup);
    }
    map['target_sets'] = Variable<int>(targetSets);
    map['target_reps'] = Variable<int>(targetReps);
    if (!nullToAbsent || targetRpe != null) {
      map['target_rpe'] = Variable<double>(targetRpe);
    }
    if (!nullToAbsent || targetWeight != null) {
      map['target_weight'] = Variable<double>(targetWeight);
    }
    map['rest_seconds'] = Variable<int>(restSeconds);
    map['warmup_sets'] = Variable<int>(warmupSets);
    map['drop_sets'] = Variable<int>(dropSets);
    map['failure_sets'] = Variable<int>(failureSets);
    map['is_warmup'] = Variable<bool>(isWarmup);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  RoutineExercisesCompanion toCompanion(bool nullToAbsent) {
    return RoutineExercisesCompanion(
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      routineId: Value(routineId),
      exerciseId: Value(exerciseId),
      orderIndex: Value(orderIndex),
      supersetGroup: supersetGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetGroup),
      targetSets: Value(targetSets),
      targetReps: Value(targetReps),
      targetRpe: targetRpe == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRpe),
      targetWeight: targetWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeight),
      restSeconds: Value(restSeconds),
      warmupSets: Value(warmupSets),
      dropSets: Value(dropSets),
      failureSets: Value(failureSets),
      isWarmup: Value(isWarmup),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory RoutineExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineExercise(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      routineId: serializer.fromJson<String>(json['routineId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      supersetGroup: serializer.fromJson<int?>(json['supersetGroup']),
      targetSets: serializer.fromJson<int>(json['targetSets']),
      targetReps: serializer.fromJson<int>(json['targetReps']),
      targetRpe: serializer.fromJson<double?>(json['targetRpe']),
      targetWeight: serializer.fromJson<double?>(json['targetWeight']),
      restSeconds: serializer.fromJson<int>(json['restSeconds']),
      warmupSets: serializer.fromJson<int>(json['warmupSets']),
      dropSets: serializer.fromJson<int>(json['dropSets']),
      failureSets: serializer.fromJson<int>(json['failureSets']),
      isWarmup: serializer.fromJson<bool>(json['isWarmup']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'routineId': serializer.toJson<String>(routineId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'supersetGroup': serializer.toJson<int?>(supersetGroup),
      'targetSets': serializer.toJson<int>(targetSets),
      'targetReps': serializer.toJson<int>(targetReps),
      'targetRpe': serializer.toJson<double?>(targetRpe),
      'targetWeight': serializer.toJson<double?>(targetWeight),
      'restSeconds': serializer.toJson<int>(restSeconds),
      'warmupSets': serializer.toJson<int>(warmupSets),
      'dropSets': serializer.toJson<int>(dropSets),
      'failureSets': serializer.toJson<int>(failureSets),
      'isWarmup': serializer.toJson<bool>(isWarmup),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  RoutineExercise copyWith({
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? routineId,
    String? exerciseId,
    int? orderIndex,
    Value<int?> supersetGroup = const Value.absent(),
    int? targetSets,
    int? targetReps,
    Value<double?> targetRpe = const Value.absent(),
    Value<double?> targetWeight = const Value.absent(),
    int? restSeconds,
    int? warmupSets,
    int? dropSets,
    int? failureSets,
    bool? isWarmup,
    Value<String?> notes = const Value.absent(),
  }) => RoutineExercise(
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    routineId: routineId ?? this.routineId,
    exerciseId: exerciseId ?? this.exerciseId,
    orderIndex: orderIndex ?? this.orderIndex,
    supersetGroup: supersetGroup.present
        ? supersetGroup.value
        : this.supersetGroup,
    targetSets: targetSets ?? this.targetSets,
    targetReps: targetReps ?? this.targetReps,
    targetRpe: targetRpe.present ? targetRpe.value : this.targetRpe,
    targetWeight: targetWeight.present ? targetWeight.value : this.targetWeight,
    restSeconds: restSeconds ?? this.restSeconds,
    warmupSets: warmupSets ?? this.warmupSets,
    dropSets: dropSets ?? this.dropSets,
    failureSets: failureSets ?? this.failureSets,
    isWarmup: isWarmup ?? this.isWarmup,
    notes: notes.present ? notes.value : this.notes,
  );
  RoutineExercise copyWithCompanion(RoutineExercisesCompanion data) {
    return RoutineExercise(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      supersetGroup: data.supersetGroup.present
          ? data.supersetGroup.value
          : this.supersetGroup,
      targetSets: data.targetSets.present
          ? data.targetSets.value
          : this.targetSets,
      targetReps: data.targetReps.present
          ? data.targetReps.value
          : this.targetReps,
      targetRpe: data.targetRpe.present ? data.targetRpe.value : this.targetRpe,
      targetWeight: data.targetWeight.present
          ? data.targetWeight.value
          : this.targetWeight,
      restSeconds: data.restSeconds.present
          ? data.restSeconds.value
          : this.restSeconds,
      warmupSets: data.warmupSets.present
          ? data.warmupSets.value
          : this.warmupSets,
      dropSets: data.dropSets.present ? data.dropSets.value : this.dropSets,
      failureSets: data.failureSets.present
          ? data.failureSets.value
          : this.failureSets,
      isWarmup: data.isWarmup.present ? data.isWarmup.value : this.isWarmup,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineExercise(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('supersetGroup: $supersetGroup, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetRpe: $targetRpe, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('warmupSets: $warmupSets, ')
          ..write('dropSets: $dropSets, ')
          ..write('failureSets: $failureSets, ')
          ..write('isWarmup: $isWarmup, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    routineId,
    exerciseId,
    orderIndex,
    supersetGroup,
    targetSets,
    targetReps,
    targetRpe,
    targetWeight,
    restSeconds,
    warmupSets,
    dropSets,
    failureSets,
    isWarmup,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineExercise &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.routineId == this.routineId &&
          other.exerciseId == this.exerciseId &&
          other.orderIndex == this.orderIndex &&
          other.supersetGroup == this.supersetGroup &&
          other.targetSets == this.targetSets &&
          other.targetReps == this.targetReps &&
          other.targetRpe == this.targetRpe &&
          other.targetWeight == this.targetWeight &&
          other.restSeconds == this.restSeconds &&
          other.warmupSets == this.warmupSets &&
          other.dropSets == this.dropSets &&
          other.failureSets == this.failureSets &&
          other.isWarmup == this.isWarmup &&
          other.notes == this.notes);
}

class RoutineExercisesCompanion extends UpdateCompanion<RoutineExercise> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> routineId;
  final Value<String> exerciseId;
  final Value<int> orderIndex;
  final Value<int?> supersetGroup;
  final Value<int> targetSets;
  final Value<int> targetReps;
  final Value<double?> targetRpe;
  final Value<double?> targetWeight;
  final Value<int> restSeconds;
  final Value<int> warmupSets;
  final Value<int> dropSets;
  final Value<int> failureSets;
  final Value<bool> isWarmup;
  final Value<String?> notes;
  final Value<int> rowid;
  const RoutineExercisesCompanion({
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.routineId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.supersetGroup = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.targetRpe = const Value.absent(),
    this.targetWeight = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.warmupSets = const Value.absent(),
    this.dropSets = const Value.absent(),
    this.failureSets = const Value.absent(),
    this.isWarmup = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutineExercisesCompanion.insert({
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String routineId,
    required String exerciseId,
    required int orderIndex,
    this.supersetGroup = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.targetRpe = const Value.absent(),
    this.targetWeight = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.warmupSets = const Value.absent(),
    this.dropSets = const Value.absent(),
    this.failureSets = const Value.absent(),
    this.isWarmup = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       id = Value(id),
       routineId = Value(routineId),
       exerciseId = Value(exerciseId),
       orderIndex = Value(orderIndex);
  static Insertable<RoutineExercise> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? routineId,
    Expression<String>? exerciseId,
    Expression<int>? orderIndex,
    Expression<int>? supersetGroup,
    Expression<int>? targetSets,
    Expression<int>? targetReps,
    Expression<double>? targetRpe,
    Expression<double>? targetWeight,
    Expression<int>? restSeconds,
    Expression<int>? warmupSets,
    Expression<int>? dropSets,
    Expression<int>? failureSets,
    Expression<bool>? isWarmup,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (routineId != null) 'routine_id': routineId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (supersetGroup != null) 'superset_group': supersetGroup,
      if (targetSets != null) 'target_sets': targetSets,
      if (targetReps != null) 'target_reps': targetReps,
      if (targetRpe != null) 'target_rpe': targetRpe,
      if (targetWeight != null) 'target_weight': targetWeight,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (warmupSets != null) 'warmup_sets': warmupSets,
      if (dropSets != null) 'drop_sets': dropSets,
      if (failureSets != null) 'failure_sets': failureSets,
      if (isWarmup != null) 'is_warmup': isWarmup,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutineExercisesCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? routineId,
    Value<String>? exerciseId,
    Value<int>? orderIndex,
    Value<int?>? supersetGroup,
    Value<int>? targetSets,
    Value<int>? targetReps,
    Value<double?>? targetRpe,
    Value<double?>? targetWeight,
    Value<int>? restSeconds,
    Value<int>? warmupSets,
    Value<int>? dropSets,
    Value<int>? failureSets,
    Value<bool>? isWarmup,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return RoutineExercisesCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      supersetGroup: supersetGroup ?? this.supersetGroup,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetRpe: targetRpe ?? this.targetRpe,
      targetWeight: targetWeight ?? this.targetWeight,
      restSeconds: restSeconds ?? this.restSeconds,
      warmupSets: warmupSets ?? this.warmupSets,
      dropSets: dropSets ?? this.dropSets,
      failureSets: failureSets ?? this.failureSets,
      isWarmup: isWarmup ?? this.isWarmup,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (supersetGroup.present) {
      map['superset_group'] = Variable<int>(supersetGroup.value);
    }
    if (targetSets.present) {
      map['target_sets'] = Variable<int>(targetSets.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<int>(targetReps.value);
    }
    if (targetRpe.present) {
      map['target_rpe'] = Variable<double>(targetRpe.value);
    }
    if (targetWeight.present) {
      map['target_weight'] = Variable<double>(targetWeight.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (warmupSets.present) {
      map['warmup_sets'] = Variable<int>(warmupSets.value);
    }
    if (dropSets.present) {
      map['drop_sets'] = Variable<int>(dropSets.value);
    }
    if (failureSets.present) {
      map['failure_sets'] = Variable<int>(failureSets.value);
    }
    if (isWarmup.present) {
      map['is_warmup'] = Variable<bool>(isWarmup.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineExercisesCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('supersetGroup: $supersetGroup, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetRpe: $targetRpe, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('warmupSets: $warmupSets, ')
          ..write('dropSets: $dropSets, ')
          ..write('failureSets: $failureSets, ')
          ..write('isWarmup: $isWarmup, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeeklyPlansTable extends WeeklyPlans
    with TableInfo<$WeeklyPlansTable, WeeklyPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyPlansTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    syncedAt,
    deletedAt,
    weekday,
    routineId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeeklyPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    }
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {weekday};
  @override
  WeeklyPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyPlan(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_id'],
      ),
    );
  }

  @override
  $WeeklyPlansTable createAlias(String alias) {
    return $WeeklyPlansTable(attachedDatabase, alias);
  }
}

class WeeklyPlan extends DataClass implements Insertable<WeeklyPlan> {
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final int weekday;
  final String? routineId;
  const WeeklyPlan({
    required this.updatedAt,
    this.syncedAt,
    this.deletedAt,
    required this.weekday,
    this.routineId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['weekday'] = Variable<int>(weekday);
    if (!nullToAbsent || routineId != null) {
      map['routine_id'] = Variable<String>(routineId);
    }
    return map;
  }

  WeeklyPlansCompanion toCompanion(bool nullToAbsent) {
    return WeeklyPlansCompanion(
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      weekday: Value(weekday),
      routineId: routineId == null && nullToAbsent
          ? const Value.absent()
          : Value(routineId),
    );
  }

  factory WeeklyPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyPlan(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      weekday: serializer.fromJson<int>(json['weekday']),
      routineId: serializer.fromJson<String?>(json['routineId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'weekday': serializer.toJson<int>(weekday),
      'routineId': serializer.toJson<String?>(routineId),
    };
  }

  WeeklyPlan copyWith({
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    int? weekday,
    Value<String?> routineId = const Value.absent(),
  }) => WeeklyPlan(
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    weekday: weekday ?? this.weekday,
    routineId: routineId.present ? routineId.value : this.routineId,
  );
  WeeklyPlan copyWithCompanion(WeeklyPlansCompanion data) {
    return WeeklyPlan(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyPlan(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('weekday: $weekday, ')
          ..write('routineId: $routineId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(updatedAt, syncedAt, deletedAt, weekday, routineId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyPlan &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.weekday == this.weekday &&
          other.routineId == this.routineId);
}

class WeeklyPlansCompanion extends UpdateCompanion<WeeklyPlan> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> weekday;
  final Value<String?> routineId;
  const WeeklyPlansCompanion({
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.weekday = const Value.absent(),
    this.routineId = const Value.absent(),
  });
  WeeklyPlansCompanion.insert({
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.weekday = const Value.absent(),
    this.routineId = const Value.absent(),
  }) : updatedAt = Value(updatedAt);
  static Insertable<WeeklyPlan> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? weekday,
    Expression<String>? routineId,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (weekday != null) 'weekday': weekday,
      if (routineId != null) 'routine_id': routineId,
    });
  }

  WeeklyPlansCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? weekday,
    Value<String?>? routineId,
  }) {
    return WeeklyPlansCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      weekday: weekday ?? this.weekday,
      routineId: routineId ?? this.routineId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyPlansCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('weekday: $weekday, ')
          ..write('routineId: $routineId')
          ..write(')'))
        .toString();
  }
}

class $WorkoutsTable extends Workouts with TableInfo<$WorkoutsTable, Workout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalVolumeMeta = const VerificationMeta(
    'totalVolume',
  );
  @override
  late final GeneratedColumn<double> totalVolume = GeneratedColumn<double>(
    'total_volume',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    userId,
    routineId,
    status,
    startedAt,
    endedAt,
    durationSec,
    totalVolume,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Workout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('total_volume')) {
      context.handle(
        _totalVolumeMeta,
        totalVolume.isAcceptableOrUnknown(
          data['total_volume']!,
          _totalVolumeMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workout(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      ),
      totalVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_volume'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }
}

class Workout extends DataClass implements Insertable<Workout> {
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String userId;
  final String? routineId;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSec;
  final double totalVolume;
  final String? notes;
  const Workout({
    required this.updatedAt,
    this.syncedAt,
    this.deletedAt,
    required this.id,
    required this.userId,
    this.routineId,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.durationSec,
    required this.totalVolume,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || routineId != null) {
      map['routine_id'] = Variable<String>(routineId);
    }
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    map['total_volume'] = Variable<double>(totalVolume);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      userId: Value(userId),
      routineId: routineId == null && nullToAbsent
          ? const Value.absent()
          : Value(routineId),
      status: Value(status),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      totalVolume: Value(totalVolume),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory Workout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workout(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      routineId: serializer.fromJson<String?>(json['routineId']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
      totalVolume: serializer.fromJson<double>(json['totalVolume']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'routineId': serializer.toJson<String?>(routineId),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'durationSec': serializer.toJson<int?>(durationSec),
      'totalVolume': serializer.toJson<double>(totalVolume),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Workout copyWith({
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? userId,
    Value<String?> routineId = const Value.absent(),
    String? status,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<int?> durationSec = const Value.absent(),
    double? totalVolume,
    Value<String?> notes = const Value.absent(),
  }) => Workout(
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    userId: userId ?? this.userId,
    routineId: routineId.present ? routineId.value : this.routineId,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
    totalVolume: totalVolume ?? this.totalVolume,
    notes: notes.present ? notes.value : this.notes,
  );
  Workout copyWithCompanion(WorkoutsCompanion data) {
    return Workout(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      totalVolume: data.totalVolume.present
          ? data.totalVolume.value
          : this.totalVolume,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workout(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('routineId: $routineId, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSec: $durationSec, ')
          ..write('totalVolume: $totalVolume, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    userId,
    routineId,
    status,
    startedAt,
    endedAt,
    durationSec,
    totalVolume,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workout &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.routineId == this.routineId &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSec == this.durationSec &&
          other.totalVolume == this.totalVolume &&
          other.notes == this.notes);
}

class WorkoutsCompanion extends UpdateCompanion<Workout> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> routineId;
  final Value<String> status;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int?> durationSec;
  final Value<double> totalVolume;
  final Value<String?> notes;
  final Value<int> rowid;
  const WorkoutsCompanion({
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.totalVolume = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String userId,
    this.routineId = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.totalVolume = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       id = Value(id),
       userId = Value(userId),
       startedAt = Value(startedAt);
  static Insertable<Workout> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? routineId,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? durationSec,
    Expression<double>? totalVolume,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (routineId != null) 'routine_id': routineId,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationSec != null) 'duration_sec': durationSec,
      if (totalVolume != null) 'total_volume': totalVolume,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? routineId,
    Value<String>? status,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int?>? durationSec,
    Value<double>? totalVolume,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return WorkoutsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      routineId: routineId ?? this.routineId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSec: durationSec ?? this.durationSec,
      totalVolume: totalVolume ?? this.totalVolume,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (totalVolume.present) {
      map['total_volume'] = Variable<double>(totalVolume.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('routineId: $routineId, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSec: $durationSec, ')
          ..write('totalVolume: $totalVolume, ')
          ..write('notes: $notes, ')
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setTypeMeta = const VerificationMeta(
    'setType',
  );
  @override
  late final GeneratedColumn<String> setType = GeneratedColumn<String>(
    'set_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('working'),
  );
  static const VerificationMeta _supersetGroupMeta = const VerificationMeta(
    'supersetGroup',
  );
  @override
  late final GeneratedColumn<int> supersetGroup = GeneratedColumn<int>(
    'superset_group',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<double> rpe = GeneratedColumn<double>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heartRateMeta = const VerificationMeta(
    'heartRate',
  );
  @override
  late final GeneratedColumn<int> heartRate = GeneratedColumn<int>(
    'heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    workoutId,
    exerciseId,
    orderIndex,
    setType,
    supersetGroup,
    weightKg,
    reps,
    rpe,
    distanceM,
    durationSec,
    heartRate,
    isCompleted,
    loggedAt,
    notes,
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('set_type')) {
      context.handle(
        _setTypeMeta,
        setType.isAcceptableOrUnknown(data['set_type']!, _setTypeMeta),
      );
    }
    if (data.containsKey('superset_group')) {
      context.handle(
        _supersetGroupMeta,
        supersetGroup.isAcceptableOrUnknown(
          data['superset_group']!,
          _supersetGroupMeta,
        ),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('rpe')) {
      context.handle(
        _rpeMeta,
        rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta),
      );
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('heart_rate')) {
      context.handle(
        _heartRateMeta,
        heartRate.isAcceptableOrUnknown(data['heart_rate']!, _heartRateMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      setType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_type'],
      )!,
      supersetGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}superset_group'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      rpe: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rpe'],
      ),
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      ),
      heartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heart_rate'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $WorkoutSetsTable createAlias(String alias) {
    return $WorkoutSetsTable(attachedDatabase, alias);
  }
}

class WorkoutSet extends DataClass implements Insertable<WorkoutSet> {
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final DateTime? deletedAt;
  final String id;
  final String workoutId;
  final String exerciseId;
  final int orderIndex;
  final String setType;
  final int? supersetGroup;
  final double? weightKg;
  final int? reps;
  final double? rpe;
  final double? distanceM;
  final int? durationSec;
  final int? heartRate;
  final bool isCompleted;
  final DateTime? loggedAt;
  final String? notes;
  const WorkoutSet({
    required this.updatedAt,
    this.syncedAt,
    this.deletedAt,
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.orderIndex,
    required this.setType,
    this.supersetGroup,
    this.weightKg,
    this.reps,
    this.rpe,
    this.distanceM,
    this.durationSec,
    this.heartRate,
    required this.isCompleted,
    this.loggedAt,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['workout_id'] = Variable<String>(workoutId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['order_index'] = Variable<int>(orderIndex);
    map['set_type'] = Variable<String>(setType);
    if (!nullToAbsent || supersetGroup != null) {
      map['superset_group'] = Variable<int>(supersetGroup);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<double>(rpe);
    }
    if (!nullToAbsent || distanceM != null) {
      map['distance_m'] = Variable<double>(distanceM);
    }
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    if (!nullToAbsent || heartRate != null) {
      map['heart_rate'] = Variable<int>(heartRate);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || loggedAt != null) {
      map['logged_at'] = Variable<DateTime>(loggedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  WorkoutSetsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSetsCompanion(
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      workoutId: Value(workoutId),
      exerciseId: Value(exerciseId),
      orderIndex: Value(orderIndex),
      setType: Value(setType),
      supersetGroup: supersetGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetGroup),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      distanceM: distanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceM),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      heartRate: heartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRate),
      isCompleted: Value(isCompleted),
      loggedAt: loggedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(loggedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory WorkoutSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSet(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      setType: serializer.fromJson<String>(json['setType']),
      supersetGroup: serializer.fromJson<int?>(json['supersetGroup']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      reps: serializer.fromJson<int?>(json['reps']),
      rpe: serializer.fromJson<double?>(json['rpe']),
      distanceM: serializer.fromJson<double?>(json['distanceM']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
      heartRate: serializer.fromJson<int?>(json['heartRate']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      loggedAt: serializer.fromJson<DateTime?>(json['loggedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'workoutId': serializer.toJson<String>(workoutId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'setType': serializer.toJson<String>(setType),
      'supersetGroup': serializer.toJson<int?>(supersetGroup),
      'weightKg': serializer.toJson<double?>(weightKg),
      'reps': serializer.toJson<int?>(reps),
      'rpe': serializer.toJson<double?>(rpe),
      'distanceM': serializer.toJson<double?>(distanceM),
      'durationSec': serializer.toJson<int?>(durationSec),
      'heartRate': serializer.toJson<int?>(heartRate),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'loggedAt': serializer.toJson<DateTime?>(loggedAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  WorkoutSet copyWith({
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? workoutId,
    String? exerciseId,
    int? orderIndex,
    String? setType,
    Value<int?> supersetGroup = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<int?> reps = const Value.absent(),
    Value<double?> rpe = const Value.absent(),
    Value<double?> distanceM = const Value.absent(),
    Value<int?> durationSec = const Value.absent(),
    Value<int?> heartRate = const Value.absent(),
    bool? isCompleted,
    Value<DateTime?> loggedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => WorkoutSet(
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    workoutId: workoutId ?? this.workoutId,
    exerciseId: exerciseId ?? this.exerciseId,
    orderIndex: orderIndex ?? this.orderIndex,
    setType: setType ?? this.setType,
    supersetGroup: supersetGroup.present
        ? supersetGroup.value
        : this.supersetGroup,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    reps: reps.present ? reps.value : this.reps,
    rpe: rpe.present ? rpe.value : this.rpe,
    distanceM: distanceM.present ? distanceM.value : this.distanceM,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
    heartRate: heartRate.present ? heartRate.value : this.heartRate,
    isCompleted: isCompleted ?? this.isCompleted,
    loggedAt: loggedAt.present ? loggedAt.value : this.loggedAt,
    notes: notes.present ? notes.value : this.notes,
  );
  WorkoutSet copyWithCompanion(WorkoutSetsCompanion data) {
    return WorkoutSet(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      setType: data.setType.present ? data.setType.value : this.setType,
      supersetGroup: data.supersetGroup.present
          ? data.supersetGroup.value
          : this.supersetGroup,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      reps: data.reps.present ? data.reps.value : this.reps,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      heartRate: data.heartRate.present ? data.heartRate.value : this.heartRate,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSet(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('setType: $setType, ')
          ..write('supersetGroup: $supersetGroup, ')
          ..write('weightKg: $weightKg, ')
          ..write('reps: $reps, ')
          ..write('rpe: $rpe, ')
          ..write('distanceM: $distanceM, ')
          ..write('durationSec: $durationSec, ')
          ..write('heartRate: $heartRate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    syncedAt,
    deletedAt,
    id,
    workoutId,
    exerciseId,
    orderIndex,
    setType,
    supersetGroup,
    weightKg,
    reps,
    rpe,
    distanceM,
    durationSec,
    heartRate,
    isCompleted,
    loggedAt,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSet &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.exerciseId == this.exerciseId &&
          other.orderIndex == this.orderIndex &&
          other.setType == this.setType &&
          other.supersetGroup == this.supersetGroup &&
          other.weightKg == this.weightKg &&
          other.reps == this.reps &&
          other.rpe == this.rpe &&
          other.distanceM == this.distanceM &&
          other.durationSec == this.durationSec &&
          other.heartRate == this.heartRate &&
          other.isCompleted == this.isCompleted &&
          other.loggedAt == this.loggedAt &&
          other.notes == this.notes);
}

class WorkoutSetsCompanion extends UpdateCompanion<WorkoutSet> {
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> workoutId;
  final Value<String> exerciseId;
  final Value<int> orderIndex;
  final Value<String> setType;
  final Value<int?> supersetGroup;
  final Value<double?> weightKg;
  final Value<int?> reps;
  final Value<double?> rpe;
  final Value<double?> distanceM;
  final Value<int?> durationSec;
  final Value<int?> heartRate;
  final Value<bool> isCompleted;
  final Value<DateTime?> loggedAt;
  final Value<String?> notes;
  final Value<int> rowid;
  const WorkoutSetsCompanion({
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.setType = const Value.absent(),
    this.supersetGroup = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.reps = const Value.absent(),
    this.rpe = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutSetsCompanion.insert({
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String workoutId,
    required String exerciseId,
    required int orderIndex,
    this.setType = const Value.absent(),
    this.supersetGroup = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.reps = const Value.absent(),
    this.rpe = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       id = Value(id),
       workoutId = Value(workoutId),
       exerciseId = Value(exerciseId),
       orderIndex = Value(orderIndex);
  static Insertable<WorkoutSet> custom({
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? workoutId,
    Expression<String>? exerciseId,
    Expression<int>? orderIndex,
    Expression<String>? setType,
    Expression<int>? supersetGroup,
    Expression<double>? weightKg,
    Expression<int>? reps,
    Expression<double>? rpe,
    Expression<double>? distanceM,
    Expression<int>? durationSec,
    Expression<int>? heartRate,
    Expression<bool>? isCompleted,
    Expression<DateTime>? loggedAt,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (setType != null) 'set_type': setType,
      if (supersetGroup != null) 'superset_group': supersetGroup,
      if (weightKg != null) 'weight_kg': weightKg,
      if (reps != null) 'reps': reps,
      if (rpe != null) 'rpe': rpe,
      if (distanceM != null) 'distance_m': distanceM,
      if (durationSec != null) 'duration_sec': durationSec,
      if (heartRate != null) 'heart_rate': heartRate,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutSetsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? workoutId,
    Value<String>? exerciseId,
    Value<int>? orderIndex,
    Value<String>? setType,
    Value<int?>? supersetGroup,
    Value<double?>? weightKg,
    Value<int?>? reps,
    Value<double?>? rpe,
    Value<double?>? distanceM,
    Value<int?>? durationSec,
    Value<int?>? heartRate,
    Value<bool>? isCompleted,
    Value<DateTime?>? loggedAt,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return WorkoutSetsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      setType: setType ?? this.setType,
      supersetGroup: supersetGroup ?? this.supersetGroup,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      distanceM: distanceM ?? this.distanceM,
      durationSec: durationSec ?? this.durationSec,
      heartRate: heartRate ?? this.heartRate,
      isCompleted: isCompleted ?? this.isCompleted,
      loggedAt: loggedAt ?? this.loggedAt,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (setType.present) {
      map['set_type'] = Variable<String>(setType.value);
    }
    if (supersetGroup.present) {
      map['superset_group'] = Variable<int>(supersetGroup.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<double>(rpe.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (heartRate.present) {
      map['heart_rate'] = Variable<int>(heartRate.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('setType: $setType, ')
          ..write('supersetGroup: $supersetGroup, ')
          ..write('weightKg: $weightKg, ')
          ..write('reps: $reps, ')
          ..write('rpe: $rpe, ')
          ..write('distanceM: $distanceM, ')
          ..write('durationSec: $durationSec, ')
          ..write('heartRate: $heartRate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MuscleVolumeDailyTable extends MuscleVolumeDaily
    with TableInfo<$MuscleVolumeDailyTable, MuscleVolumeDailyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MuscleVolumeDailyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _muscleIdMeta = const VerificationMeta(
    'muscleId',
  );
  @override
  late final GeneratedColumn<String> muscleId = GeneratedColumn<String>(
    'muscle_id',
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
  static const VerificationMeta _totalSetsMeta = const VerificationMeta(
    'totalSets',
  );
  @override
  late final GeneratedColumn<int> totalSets = GeneratedColumn<int>(
    'total_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<double> volume = GeneratedColumn<double>(
    'volume',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bestE1RmMeta = const VerificationMeta(
    'bestE1Rm',
  );
  @override
  late final GeneratedColumn<double> bestE1Rm = GeneratedColumn<double>(
    'best_e1_rm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    muscleId,
    date,
    totalSets,
    volume,
    bestE1Rm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'muscle_volume_daily';
  @override
  VerificationContext validateIntegrity(
    Insertable<MuscleVolumeDailyData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('muscle_id')) {
      context.handle(
        _muscleIdMeta,
        muscleId.isAcceptableOrUnknown(data['muscle_id']!, _muscleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_muscleIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('total_sets')) {
      context.handle(
        _totalSetsMeta,
        totalSets.isAcceptableOrUnknown(data['total_sets']!, _totalSetsMeta),
      );
    }
    if (data.containsKey('volume')) {
      context.handle(
        _volumeMeta,
        volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta),
      );
    }
    if (data.containsKey('best_e1_rm')) {
      context.handle(
        _bestE1RmMeta,
        bestE1Rm.isAcceptableOrUnknown(data['best_e1_rm']!, _bestE1RmMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, muscleId, date};
  @override
  MuscleVolumeDailyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MuscleVolumeDailyData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      muscleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}muscle_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      totalSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_sets'],
      )!,
      volume: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}volume'],
      )!,
      bestE1Rm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}best_e1_rm'],
      )!,
    );
  }

  @override
  $MuscleVolumeDailyTable createAlias(String alias) {
    return $MuscleVolumeDailyTable(attachedDatabase, alias);
  }
}

class MuscleVolumeDailyData extends DataClass
    implements Insertable<MuscleVolumeDailyData> {
  final String userId;
  final String muscleId;
  final DateTime date;
  final int totalSets;
  final double volume;
  final double bestE1Rm;
  const MuscleVolumeDailyData({
    required this.userId,
    required this.muscleId,
    required this.date,
    required this.totalSets,
    required this.volume,
    required this.bestE1Rm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['muscle_id'] = Variable<String>(muscleId);
    map['date'] = Variable<DateTime>(date);
    map['total_sets'] = Variable<int>(totalSets);
    map['volume'] = Variable<double>(volume);
    map['best_e1_rm'] = Variable<double>(bestE1Rm);
    return map;
  }

  MuscleVolumeDailyCompanion toCompanion(bool nullToAbsent) {
    return MuscleVolumeDailyCompanion(
      userId: Value(userId),
      muscleId: Value(muscleId),
      date: Value(date),
      totalSets: Value(totalSets),
      volume: Value(volume),
      bestE1Rm: Value(bestE1Rm),
    );
  }

  factory MuscleVolumeDailyData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MuscleVolumeDailyData(
      userId: serializer.fromJson<String>(json['userId']),
      muscleId: serializer.fromJson<String>(json['muscleId']),
      date: serializer.fromJson<DateTime>(json['date']),
      totalSets: serializer.fromJson<int>(json['totalSets']),
      volume: serializer.fromJson<double>(json['volume']),
      bestE1Rm: serializer.fromJson<double>(json['bestE1Rm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'muscleId': serializer.toJson<String>(muscleId),
      'date': serializer.toJson<DateTime>(date),
      'totalSets': serializer.toJson<int>(totalSets),
      'volume': serializer.toJson<double>(volume),
      'bestE1Rm': serializer.toJson<double>(bestE1Rm),
    };
  }

  MuscleVolumeDailyData copyWith({
    String? userId,
    String? muscleId,
    DateTime? date,
    int? totalSets,
    double? volume,
    double? bestE1Rm,
  }) => MuscleVolumeDailyData(
    userId: userId ?? this.userId,
    muscleId: muscleId ?? this.muscleId,
    date: date ?? this.date,
    totalSets: totalSets ?? this.totalSets,
    volume: volume ?? this.volume,
    bestE1Rm: bestE1Rm ?? this.bestE1Rm,
  );
  MuscleVolumeDailyData copyWithCompanion(MuscleVolumeDailyCompanion data) {
    return MuscleVolumeDailyData(
      userId: data.userId.present ? data.userId.value : this.userId,
      muscleId: data.muscleId.present ? data.muscleId.value : this.muscleId,
      date: data.date.present ? data.date.value : this.date,
      totalSets: data.totalSets.present ? data.totalSets.value : this.totalSets,
      volume: data.volume.present ? data.volume.value : this.volume,
      bestE1Rm: data.bestE1Rm.present ? data.bestE1Rm.value : this.bestE1Rm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MuscleVolumeDailyData(')
          ..write('userId: $userId, ')
          ..write('muscleId: $muscleId, ')
          ..write('date: $date, ')
          ..write('totalSets: $totalSets, ')
          ..write('volume: $volume, ')
          ..write('bestE1Rm: $bestE1Rm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, muscleId, date, totalSets, volume, bestE1Rm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MuscleVolumeDailyData &&
          other.userId == this.userId &&
          other.muscleId == this.muscleId &&
          other.date == this.date &&
          other.totalSets == this.totalSets &&
          other.volume == this.volume &&
          other.bestE1Rm == this.bestE1Rm);
}

class MuscleVolumeDailyCompanion
    extends UpdateCompanion<MuscleVolumeDailyData> {
  final Value<String> userId;
  final Value<String> muscleId;
  final Value<DateTime> date;
  final Value<int> totalSets;
  final Value<double> volume;
  final Value<double> bestE1Rm;
  final Value<int> rowid;
  const MuscleVolumeDailyCompanion({
    this.userId = const Value.absent(),
    this.muscleId = const Value.absent(),
    this.date = const Value.absent(),
    this.totalSets = const Value.absent(),
    this.volume = const Value.absent(),
    this.bestE1Rm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MuscleVolumeDailyCompanion.insert({
    required String userId,
    required String muscleId,
    required DateTime date,
    this.totalSets = const Value.absent(),
    this.volume = const Value.absent(),
    this.bestE1Rm = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       muscleId = Value(muscleId),
       date = Value(date);
  static Insertable<MuscleVolumeDailyData> custom({
    Expression<String>? userId,
    Expression<String>? muscleId,
    Expression<DateTime>? date,
    Expression<int>? totalSets,
    Expression<double>? volume,
    Expression<double>? bestE1Rm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (muscleId != null) 'muscle_id': muscleId,
      if (date != null) 'date': date,
      if (totalSets != null) 'total_sets': totalSets,
      if (volume != null) 'volume': volume,
      if (bestE1Rm != null) 'best_e1_rm': bestE1Rm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MuscleVolumeDailyCompanion copyWith({
    Value<String>? userId,
    Value<String>? muscleId,
    Value<DateTime>? date,
    Value<int>? totalSets,
    Value<double>? volume,
    Value<double>? bestE1Rm,
    Value<int>? rowid,
  }) {
    return MuscleVolumeDailyCompanion(
      userId: userId ?? this.userId,
      muscleId: muscleId ?? this.muscleId,
      date: date ?? this.date,
      totalSets: totalSets ?? this.totalSets,
      volume: volume ?? this.volume,
      bestE1Rm: bestE1Rm ?? this.bestE1Rm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (muscleId.present) {
      map['muscle_id'] = Variable<String>(muscleId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (totalSets.present) {
      map['total_sets'] = Variable<int>(totalSets.value);
    }
    if (volume.present) {
      map['volume'] = Variable<double>(volume.value);
    }
    if (bestE1Rm.present) {
      map['best_e1_rm'] = Variable<double>(bestE1Rm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MuscleVolumeDailyCompanion(')
          ..write('userId: $userId, ')
          ..write('muscleId: $muscleId, ')
          ..write('date: $date, ')
          ..write('totalSets: $totalSets, ')
          ..write('volume: $volume, ')
          ..write('bestE1Rm: $bestE1Rm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseHistoryTable extends ExerciseHistory
    with TableInfo<$ExerciseHistoryTable, ExerciseHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
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
  static const VerificationMeta _bestE1RmMeta = const VerificationMeta(
    'bestE1Rm',
  );
  @override
  late final GeneratedColumn<double> bestE1Rm = GeneratedColumn<double>(
    'best_e1_rm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _topWeightMeta = const VerificationMeta(
    'topWeight',
  );
  @override
  late final GeneratedColumn<double> topWeight = GeneratedColumn<double>(
    'top_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _topRepsMeta = const VerificationMeta(
    'topReps',
  );
  @override
  late final GeneratedColumn<int> topReps = GeneratedColumn<int>(
    'top_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalVolumeMeta = const VerificationMeta(
    'totalVolume',
  );
  @override
  late final GeneratedColumn<double> totalVolume = GeneratedColumn<double>(
    'total_volume',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    exerciseId,
    date,
    bestE1Rm,
    topWeight,
    topReps,
    totalVolume,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('best_e1_rm')) {
      context.handle(
        _bestE1RmMeta,
        bestE1Rm.isAcceptableOrUnknown(data['best_e1_rm']!, _bestE1RmMeta),
      );
    }
    if (data.containsKey('top_weight')) {
      context.handle(
        _topWeightMeta,
        topWeight.isAcceptableOrUnknown(data['top_weight']!, _topWeightMeta),
      );
    }
    if (data.containsKey('top_reps')) {
      context.handle(
        _topRepsMeta,
        topReps.isAcceptableOrUnknown(data['top_reps']!, _topRepsMeta),
      );
    }
    if (data.containsKey('total_volume')) {
      context.handle(
        _totalVolumeMeta,
        totalVolume.isAcceptableOrUnknown(
          data['total_volume']!,
          _totalVolumeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, exerciseId, date};
  @override
  ExerciseHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseHistoryData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      bestE1Rm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}best_e1_rm'],
      )!,
      topWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}top_weight'],
      )!,
      topReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}top_reps'],
      )!,
      totalVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_volume'],
      )!,
    );
  }

  @override
  $ExerciseHistoryTable createAlias(String alias) {
    return $ExerciseHistoryTable(attachedDatabase, alias);
  }
}

class ExerciseHistoryData extends DataClass
    implements Insertable<ExerciseHistoryData> {
  final String userId;
  final String exerciseId;
  final DateTime date;
  final double bestE1Rm;
  final double topWeight;
  final int topReps;
  final double totalVolume;
  const ExerciseHistoryData({
    required this.userId,
    required this.exerciseId,
    required this.date,
    required this.bestE1Rm,
    required this.topWeight,
    required this.topReps,
    required this.totalVolume,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['date'] = Variable<DateTime>(date);
    map['best_e1_rm'] = Variable<double>(bestE1Rm);
    map['top_weight'] = Variable<double>(topWeight);
    map['top_reps'] = Variable<int>(topReps);
    map['total_volume'] = Variable<double>(totalVolume);
    return map;
  }

  ExerciseHistoryCompanion toCompanion(bool nullToAbsent) {
    return ExerciseHistoryCompanion(
      userId: Value(userId),
      exerciseId: Value(exerciseId),
      date: Value(date),
      bestE1Rm: Value(bestE1Rm),
      topWeight: Value(topWeight),
      topReps: Value(topReps),
      totalVolume: Value(totalVolume),
    );
  }

  factory ExerciseHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseHistoryData(
      userId: serializer.fromJson<String>(json['userId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      date: serializer.fromJson<DateTime>(json['date']),
      bestE1Rm: serializer.fromJson<double>(json['bestE1Rm']),
      topWeight: serializer.fromJson<double>(json['topWeight']),
      topReps: serializer.fromJson<int>(json['topReps']),
      totalVolume: serializer.fromJson<double>(json['totalVolume']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'date': serializer.toJson<DateTime>(date),
      'bestE1Rm': serializer.toJson<double>(bestE1Rm),
      'topWeight': serializer.toJson<double>(topWeight),
      'topReps': serializer.toJson<int>(topReps),
      'totalVolume': serializer.toJson<double>(totalVolume),
    };
  }

  ExerciseHistoryData copyWith({
    String? userId,
    String? exerciseId,
    DateTime? date,
    double? bestE1Rm,
    double? topWeight,
    int? topReps,
    double? totalVolume,
  }) => ExerciseHistoryData(
    userId: userId ?? this.userId,
    exerciseId: exerciseId ?? this.exerciseId,
    date: date ?? this.date,
    bestE1Rm: bestE1Rm ?? this.bestE1Rm,
    topWeight: topWeight ?? this.topWeight,
    topReps: topReps ?? this.topReps,
    totalVolume: totalVolume ?? this.totalVolume,
  );
  ExerciseHistoryData copyWithCompanion(ExerciseHistoryCompanion data) {
    return ExerciseHistoryData(
      userId: data.userId.present ? data.userId.value : this.userId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      date: data.date.present ? data.date.value : this.date,
      bestE1Rm: data.bestE1Rm.present ? data.bestE1Rm.value : this.bestE1Rm,
      topWeight: data.topWeight.present ? data.topWeight.value : this.topWeight,
      topReps: data.topReps.present ? data.topReps.value : this.topReps,
      totalVolume: data.totalVolume.present
          ? data.totalVolume.value
          : this.totalVolume,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseHistoryData(')
          ..write('userId: $userId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('date: $date, ')
          ..write('bestE1Rm: $bestE1Rm, ')
          ..write('topWeight: $topWeight, ')
          ..write('topReps: $topReps, ')
          ..write('totalVolume: $totalVolume')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    exerciseId,
    date,
    bestE1Rm,
    topWeight,
    topReps,
    totalVolume,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseHistoryData &&
          other.userId == this.userId &&
          other.exerciseId == this.exerciseId &&
          other.date == this.date &&
          other.bestE1Rm == this.bestE1Rm &&
          other.topWeight == this.topWeight &&
          other.topReps == this.topReps &&
          other.totalVolume == this.totalVolume);
}

class ExerciseHistoryCompanion extends UpdateCompanion<ExerciseHistoryData> {
  final Value<String> userId;
  final Value<String> exerciseId;
  final Value<DateTime> date;
  final Value<double> bestE1Rm;
  final Value<double> topWeight;
  final Value<int> topReps;
  final Value<double> totalVolume;
  final Value<int> rowid;
  const ExerciseHistoryCompanion({
    this.userId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.date = const Value.absent(),
    this.bestE1Rm = const Value.absent(),
    this.topWeight = const Value.absent(),
    this.topReps = const Value.absent(),
    this.totalVolume = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseHistoryCompanion.insert({
    required String userId,
    required String exerciseId,
    required DateTime date,
    this.bestE1Rm = const Value.absent(),
    this.topWeight = const Value.absent(),
    this.topReps = const Value.absent(),
    this.totalVolume = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       exerciseId = Value(exerciseId),
       date = Value(date);
  static Insertable<ExerciseHistoryData> custom({
    Expression<String>? userId,
    Expression<String>? exerciseId,
    Expression<DateTime>? date,
    Expression<double>? bestE1Rm,
    Expression<double>? topWeight,
    Expression<int>? topReps,
    Expression<double>? totalVolume,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (date != null) 'date': date,
      if (bestE1Rm != null) 'best_e1_rm': bestE1Rm,
      if (topWeight != null) 'top_weight': topWeight,
      if (topReps != null) 'top_reps': topReps,
      if (totalVolume != null) 'total_volume': totalVolume,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseHistoryCompanion copyWith({
    Value<String>? userId,
    Value<String>? exerciseId,
    Value<DateTime>? date,
    Value<double>? bestE1Rm,
    Value<double>? topWeight,
    Value<int>? topReps,
    Value<double>? totalVolume,
    Value<int>? rowid,
  }) {
    return ExerciseHistoryCompanion(
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      date: date ?? this.date,
      bestE1Rm: bestE1Rm ?? this.bestE1Rm,
      topWeight: topWeight ?? this.topWeight,
      topReps: topReps ?? this.topReps,
      totalVolume: totalVolume ?? this.totalVolume,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (bestE1Rm.present) {
      map['best_e1_rm'] = Variable<double>(bestE1Rm.value);
    }
    if (topWeight.present) {
      map['top_weight'] = Variable<double>(topWeight.value);
    }
    if (topReps.present) {
      map['top_reps'] = Variable<int>(topReps.value);
    }
    if (totalVolume.present) {
      map['total_volume'] = Variable<double>(totalVolume.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseHistoryCompanion(')
          ..write('userId: $userId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('date: $date, ')
          ..write('bestE1Rm: $bestE1Rm, ')
          ..write('topWeight: $topWeight, ')
          ..write('topReps: $topReps, ')
          ..write('totalVolume: $totalVolume, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MuscleGradeHistoryTable extends MuscleGradeHistory
    with TableInfo<$MuscleGradeHistoryTable, MuscleGradeHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MuscleGradeHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _muscleIdMeta = const VerificationMeta(
    'muscleId',
  );
  @override
  late final GeneratedColumn<String> muscleId = GeneratedColumn<String>(
    'muscle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _computedAtMeta = const VerificationMeta(
    'computedAt',
  );
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
    'computed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volumeComponentMeta = const VerificationMeta(
    'volumeComponent',
  );
  @override
  late final GeneratedColumn<double> volumeComponent = GeneratedColumn<double>(
    'volume_component',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strengthComponentMeta = const VerificationMeta(
    'strengthComponent',
  );
  @override
  late final GeneratedColumn<double> strengthComponent =
      GeneratedColumn<double>(
        'strength_component',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _consistencyComponentMeta =
      const VerificationMeta('consistencyComponent');
  @override
  late final GeneratedColumn<double> consistencyComponent =
      GeneratedColumn<double>(
        'consistency_component',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    muscleId,
    computedAt,
    grade,
    score,
    volumeComponent,
    strengthComponent,
    consistencyComponent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'muscle_grade_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<MuscleGradeHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('muscle_id')) {
      context.handle(
        _muscleIdMeta,
        muscleId.isAcceptableOrUnknown(data['muscle_id']!, _muscleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_muscleIdMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
        _computedAtMeta,
        computedAt.isAcceptableOrUnknown(data['computed_at']!, _computedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('volume_component')) {
      context.handle(
        _volumeComponentMeta,
        volumeComponent.isAcceptableOrUnknown(
          data['volume_component']!,
          _volumeComponentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_volumeComponentMeta);
    }
    if (data.containsKey('strength_component')) {
      context.handle(
        _strengthComponentMeta,
        strengthComponent.isAcceptableOrUnknown(
          data['strength_component']!,
          _strengthComponentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strengthComponentMeta);
    }
    if (data.containsKey('consistency_component')) {
      context.handle(
        _consistencyComponentMeta,
        consistencyComponent.isAcceptableOrUnknown(
          data['consistency_component']!,
          _consistencyComponentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consistencyComponentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, muscleId, computedAt};
  @override
  MuscleGradeHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MuscleGradeHistoryData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      muscleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}muscle_id'],
      )!,
      computedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}computed_at'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      volumeComponent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}volume_component'],
      )!,
      strengthComponent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}strength_component'],
      )!,
      consistencyComponent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}consistency_component'],
      )!,
    );
  }

  @override
  $MuscleGradeHistoryTable createAlias(String alias) {
    return $MuscleGradeHistoryTable(attachedDatabase, alias);
  }
}

class MuscleGradeHistoryData extends DataClass
    implements Insertable<MuscleGradeHistoryData> {
  final String userId;
  final String muscleId;
  final DateTime computedAt;
  final String grade;
  final double score;
  final double volumeComponent;
  final double strengthComponent;
  final double consistencyComponent;
  const MuscleGradeHistoryData({
    required this.userId,
    required this.muscleId,
    required this.computedAt,
    required this.grade,
    required this.score,
    required this.volumeComponent,
    required this.strengthComponent,
    required this.consistencyComponent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['muscle_id'] = Variable<String>(muscleId);
    map['computed_at'] = Variable<DateTime>(computedAt);
    map['grade'] = Variable<String>(grade);
    map['score'] = Variable<double>(score);
    map['volume_component'] = Variable<double>(volumeComponent);
    map['strength_component'] = Variable<double>(strengthComponent);
    map['consistency_component'] = Variable<double>(consistencyComponent);
    return map;
  }

  MuscleGradeHistoryCompanion toCompanion(bool nullToAbsent) {
    return MuscleGradeHistoryCompanion(
      userId: Value(userId),
      muscleId: Value(muscleId),
      computedAt: Value(computedAt),
      grade: Value(grade),
      score: Value(score),
      volumeComponent: Value(volumeComponent),
      strengthComponent: Value(strengthComponent),
      consistencyComponent: Value(consistencyComponent),
    );
  }

  factory MuscleGradeHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MuscleGradeHistoryData(
      userId: serializer.fromJson<String>(json['userId']),
      muscleId: serializer.fromJson<String>(json['muscleId']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
      grade: serializer.fromJson<String>(json['grade']),
      score: serializer.fromJson<double>(json['score']),
      volumeComponent: serializer.fromJson<double>(json['volumeComponent']),
      strengthComponent: serializer.fromJson<double>(json['strengthComponent']),
      consistencyComponent: serializer.fromJson<double>(
        json['consistencyComponent'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'muscleId': serializer.toJson<String>(muscleId),
      'computedAt': serializer.toJson<DateTime>(computedAt),
      'grade': serializer.toJson<String>(grade),
      'score': serializer.toJson<double>(score),
      'volumeComponent': serializer.toJson<double>(volumeComponent),
      'strengthComponent': serializer.toJson<double>(strengthComponent),
      'consistencyComponent': serializer.toJson<double>(consistencyComponent),
    };
  }

  MuscleGradeHistoryData copyWith({
    String? userId,
    String? muscleId,
    DateTime? computedAt,
    String? grade,
    double? score,
    double? volumeComponent,
    double? strengthComponent,
    double? consistencyComponent,
  }) => MuscleGradeHistoryData(
    userId: userId ?? this.userId,
    muscleId: muscleId ?? this.muscleId,
    computedAt: computedAt ?? this.computedAt,
    grade: grade ?? this.grade,
    score: score ?? this.score,
    volumeComponent: volumeComponent ?? this.volumeComponent,
    strengthComponent: strengthComponent ?? this.strengthComponent,
    consistencyComponent: consistencyComponent ?? this.consistencyComponent,
  );
  MuscleGradeHistoryData copyWithCompanion(MuscleGradeHistoryCompanion data) {
    return MuscleGradeHistoryData(
      userId: data.userId.present ? data.userId.value : this.userId,
      muscleId: data.muscleId.present ? data.muscleId.value : this.muscleId,
      computedAt: data.computedAt.present
          ? data.computedAt.value
          : this.computedAt,
      grade: data.grade.present ? data.grade.value : this.grade,
      score: data.score.present ? data.score.value : this.score,
      volumeComponent: data.volumeComponent.present
          ? data.volumeComponent.value
          : this.volumeComponent,
      strengthComponent: data.strengthComponent.present
          ? data.strengthComponent.value
          : this.strengthComponent,
      consistencyComponent: data.consistencyComponent.present
          ? data.consistencyComponent.value
          : this.consistencyComponent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MuscleGradeHistoryData(')
          ..write('userId: $userId, ')
          ..write('muscleId: $muscleId, ')
          ..write('computedAt: $computedAt, ')
          ..write('grade: $grade, ')
          ..write('score: $score, ')
          ..write('volumeComponent: $volumeComponent, ')
          ..write('strengthComponent: $strengthComponent, ')
          ..write('consistencyComponent: $consistencyComponent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    muscleId,
    computedAt,
    grade,
    score,
    volumeComponent,
    strengthComponent,
    consistencyComponent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MuscleGradeHistoryData &&
          other.userId == this.userId &&
          other.muscleId == this.muscleId &&
          other.computedAt == this.computedAt &&
          other.grade == this.grade &&
          other.score == this.score &&
          other.volumeComponent == this.volumeComponent &&
          other.strengthComponent == this.strengthComponent &&
          other.consistencyComponent == this.consistencyComponent);
}

class MuscleGradeHistoryCompanion
    extends UpdateCompanion<MuscleGradeHistoryData> {
  final Value<String> userId;
  final Value<String> muscleId;
  final Value<DateTime> computedAt;
  final Value<String> grade;
  final Value<double> score;
  final Value<double> volumeComponent;
  final Value<double> strengthComponent;
  final Value<double> consistencyComponent;
  final Value<int> rowid;
  const MuscleGradeHistoryCompanion({
    this.userId = const Value.absent(),
    this.muscleId = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.grade = const Value.absent(),
    this.score = const Value.absent(),
    this.volumeComponent = const Value.absent(),
    this.strengthComponent = const Value.absent(),
    this.consistencyComponent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MuscleGradeHistoryCompanion.insert({
    required String userId,
    required String muscleId,
    required DateTime computedAt,
    required String grade,
    required double score,
    required double volumeComponent,
    required double strengthComponent,
    required double consistencyComponent,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       muscleId = Value(muscleId),
       computedAt = Value(computedAt),
       grade = Value(grade),
       score = Value(score),
       volumeComponent = Value(volumeComponent),
       strengthComponent = Value(strengthComponent),
       consistencyComponent = Value(consistencyComponent);
  static Insertable<MuscleGradeHistoryData> custom({
    Expression<String>? userId,
    Expression<String>? muscleId,
    Expression<DateTime>? computedAt,
    Expression<String>? grade,
    Expression<double>? score,
    Expression<double>? volumeComponent,
    Expression<double>? strengthComponent,
    Expression<double>? consistencyComponent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (muscleId != null) 'muscle_id': muscleId,
      if (computedAt != null) 'computed_at': computedAt,
      if (grade != null) 'grade': grade,
      if (score != null) 'score': score,
      if (volumeComponent != null) 'volume_component': volumeComponent,
      if (strengthComponent != null) 'strength_component': strengthComponent,
      if (consistencyComponent != null)
        'consistency_component': consistencyComponent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MuscleGradeHistoryCompanion copyWith({
    Value<String>? userId,
    Value<String>? muscleId,
    Value<DateTime>? computedAt,
    Value<String>? grade,
    Value<double>? score,
    Value<double>? volumeComponent,
    Value<double>? strengthComponent,
    Value<double>? consistencyComponent,
    Value<int>? rowid,
  }) {
    return MuscleGradeHistoryCompanion(
      userId: userId ?? this.userId,
      muscleId: muscleId ?? this.muscleId,
      computedAt: computedAt ?? this.computedAt,
      grade: grade ?? this.grade,
      score: score ?? this.score,
      volumeComponent: volumeComponent ?? this.volumeComponent,
      strengthComponent: strengthComponent ?? this.strengthComponent,
      consistencyComponent: consistencyComponent ?? this.consistencyComponent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (muscleId.present) {
      map['muscle_id'] = Variable<String>(muscleId.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (volumeComponent.present) {
      map['volume_component'] = Variable<double>(volumeComponent.value);
    }
    if (strengthComponent.present) {
      map['strength_component'] = Variable<double>(strengthComponent.value);
    }
    if (consistencyComponent.present) {
      map['consistency_component'] = Variable<double>(
        consistencyComponent.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MuscleGradeHistoryCompanion(')
          ..write('userId: $userId, ')
          ..write('muscleId: $muscleId, ')
          ..write('computedAt: $computedAt, ')
          ..write('grade: $grade, ')
          ..write('score: $score, ')
          ..write('volumeComponent: $volumeComponent, ')
          ..write('strengthComponent: $strengthComponent, ')
          ..write('consistencyComponent: $consistencyComponent, ')
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
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
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
  static const VerificationMeta _retriesMeta = const VerificationMeta(
    'retries',
  );
  @override
  late final GeneratedColumn<int> retries = GeneratedColumn<int>(
    'retries',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetTable,
    rowId,
    op,
    payload,
    createdAt,
    retries,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retries')) {
      context.handle(
        _retriesMeta,
        retries.isAcceptableOrUnknown(data['retries']!, _retriesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retries'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;

  /// Target drift table name. (Named [targetTable], not `tableName` —
  /// that collides with Drift's built-in `Table.tableName` getter.)
  final String targetTable;
  final String rowId;
  final String op;
  final String payload;
  final DateTime createdAt;
  final int retries;
  const SyncQueueData({
    required this.id,
    required this.targetTable,
    required this.rowId,
    required this.op,
    required this.payload,
    required this.createdAt,
    required this.retries,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_table'] = Variable<String>(targetTable);
    map['row_id'] = Variable<String>(rowId);
    map['op'] = Variable<String>(op);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retries'] = Variable<int>(retries);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      rowId: Value(rowId),
      op: Value(op),
      payload: Value(payload),
      createdAt: Value(createdAt),
      retries: Value(retries),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      rowId: serializer.fromJson<String>(json['rowId']),
      op: serializer.fromJson<String>(json['op']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retries: serializer.fromJson<int>(json['retries']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'rowId': serializer.toJson<String>(rowId),
      'op': serializer.toJson<String>(op),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retries': serializer.toJson<int>(retries),
    };
  }

  SyncQueueData copyWith({
    int? id,
    String? targetTable,
    String? rowId,
    String? op,
    String? payload,
    DateTime? createdAt,
    int? retries,
  }) => SyncQueueData(
    id: id ?? this.id,
    targetTable: targetTable ?? this.targetTable,
    rowId: rowId ?? this.rowId,
    op: op ?? this.op,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    retries: retries ?? this.retries,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retries: data.retries.present ? data.retries.value : this.retries,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('rowId: $rowId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retries: $retries')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, targetTable, rowId, op, payload, createdAt, retries);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.rowId == this.rowId &&
          other.op == this.op &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.retries == this.retries);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> targetTable;
  final Value<String> rowId;
  final Value<String> op;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> retries;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.rowId = const Value.absent(),
    this.op = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retries = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String targetTable,
    required String rowId,
    required String op,
    required String payload,
    required DateTime createdAt,
    this.retries = const Value.absent(),
  }) : targetTable = Value(targetTable),
       rowId = Value(rowId),
       op = Value(op),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? targetTable,
    Expression<String>? rowId,
    Expression<String>? op,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? retries,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (rowId != null) 'row_id': rowId,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retries != null) 'retries': retries,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? targetTable,
    Value<String>? rowId,
    Value<String>? op,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? retries,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      rowId: rowId ?? this.rowId,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retries: retries ?? this.retries,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retries.present) {
      map['retries'] = Variable<int>(retries.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('rowId: $rowId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retries: $retries')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $MuscleGroupsTable muscleGroups = $MuscleGroupsTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $ExerciseMuscleMapTable exerciseMuscleMap =
      $ExerciseMuscleMapTable(this);
  late final $RoutinesTable routines = $RoutinesTable(this);
  late final $RoutineExercisesTable routineExercises = $RoutineExercisesTable(
    this,
  );
  late final $WeeklyPlansTable weeklyPlans = $WeeklyPlansTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $WorkoutSetsTable workoutSets = $WorkoutSetsTable(this);
  late final $MuscleVolumeDailyTable muscleVolumeDaily =
      $MuscleVolumeDailyTable(this);
  late final $ExerciseHistoryTable exerciseHistory = $ExerciseHistoryTable(
    this,
  );
  late final $MuscleGradeHistoryTable muscleGradeHistory =
      $MuscleGradeHistoryTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    muscleGroups,
    exercises,
    exerciseMuscleMap,
    routines,
    routineExercises,
    weeklyPlans,
    workouts,
    workoutSets,
    muscleVolumeDaily,
    exerciseHistory,
    muscleGradeHistory,
    syncQueue,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  required String id,
  Value<String?> username,
  Value<String> unitSystem,
  Value<String> theme,
  Value<double?> bodyweightKg,
  Value<double?> heightCm,
  Value<String?> birthDate,
  Value<String?> sex,
  Value<double?> bodyFatPct,
  Value<String?> trainingGoal,
  Value<int> rowid,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String?> username,
  Value<String> unitSystem,
  Value<String> theme,
  Value<double?> bodyweightKg,
  Value<double?> heightCm,
  Value<String?> birthDate,
  Value<String?> sex,
  Value<double?> bodyFatPct,
  Value<String?> trainingGoal,
  Value<int> rowid,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitSystem => $composableBuilder(
    column: $table.unitSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bodyweightKg => $composableBuilder(
    column: $table.bodyweightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trainingGoal => $composableBuilder(
    column: $table.trainingGoal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitSystem => $composableBuilder(
    column: $table.unitSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bodyweightKg => $composableBuilder(
    column: $table.bodyweightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trainingGoal => $composableBuilder(
    column: $table.trainingGoal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get unitSystem => $composableBuilder(
    column: $table.unitSystem,
    builder: (column) => column,
  );

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<double> get bodyweightKg => $composableBuilder(
    column: $table.bodyweightKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<String> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trainingGoal => $composableBuilder(
    column: $table.trainingGoal,
    builder: (column) => column,
  );
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String> unitSystem = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<double?> bodyweightKg = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<String?> birthDate = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<double?> bodyFatPct = const Value.absent(),
                Value<String?> trainingGoal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                username: username,
                unitSystem: unitSystem,
                theme: theme,
                bodyweightKg: bodyweightKg,
                heightCm: heightCm,
                birthDate: birthDate,
                sex: sex,
                bodyFatPct: bodyFatPct,
                trainingGoal: trainingGoal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                Value<String?> username = const Value.absent(),
                Value<String> unitSystem = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<double?> bodyweightKg = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<String?> birthDate = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<double?> bodyFatPct = const Value.absent(),
                Value<String?> trainingGoal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                username: username,
                unitSystem: unitSystem,
                theme: theme,
                bodyweightKg: bodyweightKg,
                heightCm: heightCm,
                birthDate: birthDate,
                sex: sex,
                bodyFatPct: bodyFatPct,
                trainingGoal: trainingGoal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, Profile>(table),
                  BaseReferences<_$AppDatabase, $ProfilesTable, Profile>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$MuscleGroupsTableCreateCompanionBuilder =
    MuscleGroupsCompanion Function({
      required DateTime updatedAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> deletedAt,
      required String id,
      Value<String?> parentId,
      required String name,
      Value<String> heatmapNodes,
      Value<int> orderIndex,
      Value<int> rowid,
    });
typedef $$MuscleGroupsTableUpdateCompanionBuilder =
    MuscleGroupsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> deletedAt,
      Value<String> id,
      Value<String?> parentId,
      Value<String> name,
      Value<String> heatmapNodes,
      Value<int> orderIndex,
      Value<int> rowid,
    });

class $$MuscleGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $MuscleGroupsTable> {
  $$MuscleGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heatmapNodes => $composableBuilder(
    column: $table.heatmapNodes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MuscleGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $MuscleGroupsTable> {
  $$MuscleGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heatmapNodes => $composableBuilder(
    column: $table.heatmapNodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MuscleGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MuscleGroupsTable> {
  $$MuscleGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get heatmapNodes => $composableBuilder(
    column: $table.heatmapNodes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );
}

class $$MuscleGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MuscleGroupsTable,
          MuscleGroup,
          $$MuscleGroupsTableFilterComposer,
          $$MuscleGroupsTableOrderingComposer,
          $$MuscleGroupsTableAnnotationComposer,
          $$MuscleGroupsTableCreateCompanionBuilder,
          $$MuscleGroupsTableUpdateCompanionBuilder,
          (
            MuscleGroup,
            BaseReferences<_$AppDatabase, $MuscleGroupsTable, MuscleGroup>,
          ),
          MuscleGroup,
          PrefetchHooks Function()
        > {
  $$MuscleGroupsTableTableManager(_$AppDatabase db, $MuscleGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MuscleGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MuscleGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MuscleGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> heatmapNodes = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MuscleGroupsCompanion(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                parentId: parentId,
                name: name,
                heatmapNodes: heatmapNodes,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                Value<String?> parentId = const Value.absent(),
                required String name,
                Value<String> heatmapNodes = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MuscleGroupsCompanion.insert(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                parentId: parentId,
                name: name,
                heatmapNodes: heatmapNodes,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MuscleGroupsTable, MuscleGroup>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MuscleGroupsTable,
                    MuscleGroup
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MuscleGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MuscleGroupsTable,
      MuscleGroup,
      $$MuscleGroupsTableFilterComposer,
      $$MuscleGroupsTableOrderingComposer,
      $$MuscleGroupsTableAnnotationComposer,
      $$MuscleGroupsTableCreateCompanionBuilder,
      $$MuscleGroupsTableUpdateCompanionBuilder,
      (
        MuscleGroup,
        BaseReferences<_$AppDatabase, $MuscleGroupsTable, MuscleGroup>,
      ),
      MuscleGroup,
      PrefetchHooks Function()
    >;
typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String name,
  required String mechanics,
  Value<String?> forceType,
  Value<String> category,
  required String primaryMuscleId,
  Value<String> equipment,
  Value<String> defaultMetric,
  Value<String> animationKind,
  Value<String?> animationRef,
  Value<String?> thumbnailRef,
  Value<bool> isCustom,
  Value<String?> ownerId,
  Value<int?> restSeconds,
  Value<double?> progressionIncrementKg,
  Value<int> rowid,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> name,
  Value<String> mechanics,
  Value<String?> forceType,
  Value<String> category,
  Value<String> primaryMuscleId,
  Value<String> equipment,
  Value<String> defaultMetric,
  Value<String> animationKind,
  Value<String?> animationRef,
  Value<String?> thumbnailRef,
  Value<bool> isCustom,
  Value<String?> ownerId,
  Value<int?> restSeconds,
  Value<double?> progressionIncrementKg,
  Value<int> rowid,
});

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mechanics => $composableBuilder(
    column: $table.mechanics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get forceType => $composableBuilder(
    column: $table.forceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryMuscleId => $composableBuilder(
    column: $table.primaryMuscleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultMetric => $composableBuilder(
    column: $table.defaultMetric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get animationKind => $composableBuilder(
    column: $table.animationKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get animationRef => $composableBuilder(
    column: $table.animationRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailRef => $composableBuilder(
    column: $table.thumbnailRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progressionIncrementKg => $composableBuilder(
    column: $table.progressionIncrementKg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mechanics => $composableBuilder(
    column: $table.mechanics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forceType => $composableBuilder(
    column: $table.forceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryMuscleId => $composableBuilder(
    column: $table.primaryMuscleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultMetric => $composableBuilder(
    column: $table.defaultMetric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get animationKind => $composableBuilder(
    column: $table.animationKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get animationRef => $composableBuilder(
    column: $table.animationRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailRef => $composableBuilder(
    column: $table.thumbnailRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progressionIncrementKg => $composableBuilder(
    column: $table.progressionIncrementKg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get mechanics =>
      $composableBuilder(column: $table.mechanics, builder: (column) => column);

  GeneratedColumn<String> get forceType =>
      $composableBuilder(column: $table.forceType, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get primaryMuscleId => $composableBuilder(
    column: $table.primaryMuscleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get defaultMetric => $composableBuilder(
    column: $table.defaultMetric,
    builder: (column) => column,
  );

  GeneratedColumn<String> get animationKind => $composableBuilder(
    column: $table.animationKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get animationRef => $composableBuilder(
    column: $table.animationRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailRef => $composableBuilder(
    column: $table.thumbnailRef,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progressionIncrementKg => $composableBuilder(
    column: $table.progressionIncrementKg,
    builder: (column) => column,
  );
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
          Exercise,
          PrefetchHooks Function()
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> mechanics = const Value.absent(),
                Value<String?> forceType = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> primaryMuscleId = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<String> defaultMetric = const Value.absent(),
                Value<String> animationKind = const Value.absent(),
                Value<String?> animationRef = const Value.absent(),
                Value<String?> thumbnailRef = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<int?> restSeconds = const Value.absent(),
                Value<double?> progressionIncrementKg = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                name: name,
                mechanics: mechanics,
                forceType: forceType,
                category: category,
                primaryMuscleId: primaryMuscleId,
                equipment: equipment,
                defaultMetric: defaultMetric,
                animationKind: animationKind,
                animationRef: animationRef,
                thumbnailRef: thumbnailRef,
                isCustom: isCustom,
                ownerId: ownerId,
                restSeconds: restSeconds,
                progressionIncrementKg: progressionIncrementKg,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String name,
                required String mechanics,
                Value<String?> forceType = const Value.absent(),
                Value<String> category = const Value.absent(),
                required String primaryMuscleId,
                Value<String> equipment = const Value.absent(),
                Value<String> defaultMetric = const Value.absent(),
                Value<String> animationKind = const Value.absent(),
                Value<String?> animationRef = const Value.absent(),
                Value<String?> thumbnailRef = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<int?> restSeconds = const Value.absent(),
                Value<double?> progressionIncrementKg = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion.insert(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                name: name,
                mechanics: mechanics,
                forceType: forceType,
                category: category,
                primaryMuscleId: primaryMuscleId,
                equipment: equipment,
                defaultMetric: defaultMetric,
                animationKind: animationKind,
                animationRef: animationRef,
                thumbnailRef: thumbnailRef,
                isCustom: isCustom,
                ownerId: ownerId,
                restSeconds: restSeconds,
                progressionIncrementKg: progressionIncrementKg,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExercisesTable, Exercise>(table),
                  BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, BaseReferences<_$AppDatabase, $ExercisesTable, Exercise>),
      Exercise,
      PrefetchHooks Function()
    >;
typedef $$ExerciseMuscleMapTableCreateCompanionBuilder =
    ExerciseMuscleMapCompanion Function({
      required String exerciseId,
      required String muscleId,
      Value<double> contribution,
      Value<String> role,
      Value<int> rowid,
    });
typedef $$ExerciseMuscleMapTableUpdateCompanionBuilder =
    ExerciseMuscleMapCompanion Function({
      Value<String> exerciseId,
      Value<String> muscleId,
      Value<double> contribution,
      Value<String> role,
      Value<int> rowid,
    });

class $$ExerciseMuscleMapTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseMuscleMapTable> {
  $$ExerciseMuscleMapTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get muscleId => $composableBuilder(
    column: $table.muscleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get contribution => $composableBuilder(
    column: $table.contribution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseMuscleMapTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseMuscleMapTable> {
  $$ExerciseMuscleMapTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muscleId => $composableBuilder(
    column: $table.muscleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get contribution => $composableBuilder(
    column: $table.contribution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseMuscleMapTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseMuscleMapTable> {
  $$ExerciseMuscleMapTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get muscleId =>
      $composableBuilder(column: $table.muscleId, builder: (column) => column);

  GeneratedColumn<double> get contribution => $composableBuilder(
    column: $table.contribution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);
}

class $$ExerciseMuscleMapTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseMuscleMapTable,
          ExerciseMuscleMapData,
          $$ExerciseMuscleMapTableFilterComposer,
          $$ExerciseMuscleMapTableOrderingComposer,
          $$ExerciseMuscleMapTableAnnotationComposer,
          $$ExerciseMuscleMapTableCreateCompanionBuilder,
          $$ExerciseMuscleMapTableUpdateCompanionBuilder,
          (
            ExerciseMuscleMapData,
            BaseReferences<
              _$AppDatabase,
              $ExerciseMuscleMapTable,
              ExerciseMuscleMapData
            >,
          ),
          ExerciseMuscleMapData,
          PrefetchHooks Function()
        > {
  $$ExerciseMuscleMapTableTableManager(
    _$AppDatabase db,
    $ExerciseMuscleMapTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseMuscleMapTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseMuscleMapTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseMuscleMapTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> exerciseId = const Value.absent(),
                Value<String> muscleId = const Value.absent(),
                Value<double> contribution = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseMuscleMapCompanion(
                exerciseId: exerciseId,
                muscleId: muscleId,
                contribution: contribution,
                role: role,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String exerciseId,
                required String muscleId,
                Value<double> contribution = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseMuscleMapCompanion.insert(
                exerciseId: exerciseId,
                muscleId: muscleId,
                contribution: contribution,
                role: role,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExerciseMuscleMapTable, ExerciseMuscleMapData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ExerciseMuscleMapTable,
                    ExerciseMuscleMapData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseMuscleMapTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseMuscleMapTable,
      ExerciseMuscleMapData,
      $$ExerciseMuscleMapTableFilterComposer,
      $$ExerciseMuscleMapTableOrderingComposer,
      $$ExerciseMuscleMapTableAnnotationComposer,
      $$ExerciseMuscleMapTableCreateCompanionBuilder,
      $$ExerciseMuscleMapTableUpdateCompanionBuilder,
      (
        ExerciseMuscleMapData,
        BaseReferences<
          _$AppDatabase,
          $ExerciseMuscleMapTable,
          ExerciseMuscleMapData
        >,
      ),
      ExerciseMuscleMapData,
      PrefetchHooks Function()
    >;
typedef $$RoutinesTableCreateCompanionBuilder = RoutinesCompanion Function({
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String userId,
  required String name,
  Value<String?> description,
  Value<int> orderIndex,
  Value<int> rowid,
});
typedef $$RoutinesTableUpdateCompanionBuilder = RoutinesCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> userId,
  Value<String> name,
  Value<String?> description,
  Value<int> orderIndex,
  Value<int> rowid,
});

class $$RoutinesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
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

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );
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
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
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

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
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
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );
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
          (Routine, BaseReferences<_$AppDatabase, $RoutinesTable, Routine>),
          Routine,
          PrefetchHooks Function()
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
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutinesCompanion(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                userId: userId,
                name: name,
                description: description,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String userId,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutinesCompanion.insert(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                userId: userId,
                name: name,
                description: description,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RoutinesTable, Routine>(table),
                  BaseReferences<_$AppDatabase, $RoutinesTable, Routine>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
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
      (Routine, BaseReferences<_$AppDatabase, $RoutinesTable, Routine>),
      Routine,
      PrefetchHooks Function()
    >;
typedef $$RoutineExercisesTableCreateCompanionBuilder =
    RoutineExercisesCompanion Function({
      required DateTime updatedAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> deletedAt,
      required String id,
      required String routineId,
      required String exerciseId,
      required int orderIndex,
      Value<int?> supersetGroup,
      Value<int> targetSets,
      Value<int> targetReps,
      Value<double?> targetRpe,
      Value<double?> targetWeight,
      Value<int> restSeconds,
      Value<int> warmupSets,
      Value<int> dropSets,
      Value<int> failureSets,
      Value<bool> isWarmup,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$RoutineExercisesTableUpdateCompanionBuilder =
    RoutineExercisesCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> deletedAt,
      Value<String> id,
      Value<String> routineId,
      Value<String> exerciseId,
      Value<int> orderIndex,
      Value<int?> supersetGroup,
      Value<int> targetSets,
      Value<int> targetReps,
      Value<double?> targetRpe,
      Value<double?> targetWeight,
      Value<int> restSeconds,
      Value<int> warmupSets,
      Value<int> dropSets,
      Value<int> failureSets,
      Value<bool> isWarmup,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$RoutineExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutineExercisesTable> {
  $$RoutineExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetRpe => $composableBuilder(
    column: $table.targetRpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warmupSets => $composableBuilder(
    column: $table.warmupSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dropSets => $composableBuilder(
    column: $table.dropSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failureSets => $composableBuilder(
    column: $table.failureSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
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
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetRpe => $composableBuilder(
    column: $table.targetRpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warmupSets => $composableBuilder(
    column: $table.warmupSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dropSets => $composableBuilder(
    column: $table.dropSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failureSets => $composableBuilder(
    column: $table.failureSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
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
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetRpe =>
      $composableBuilder(column: $table.targetRpe, builder: (column) => column);

  GeneratedColumn<double> get targetWeight => $composableBuilder(
    column: $table.targetWeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get warmupSets => $composableBuilder(
    column: $table.warmupSets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dropSets =>
      $composableBuilder(column: $table.dropSets, builder: (column) => column);

  GeneratedColumn<int> get failureSets => $composableBuilder(
    column: $table.failureSets,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isWarmup =>
      $composableBuilder(column: $table.isWarmup, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
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
          (
            RoutineExercise,
            BaseReferences<
              _$AppDatabase,
              $RoutineExercisesTable,
              RoutineExercise
            >,
          ),
          RoutineExercise,
          PrefetchHooks Function()
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
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> routineId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int?> supersetGroup = const Value.absent(),
                Value<int> targetSets = const Value.absent(),
                Value<int> targetReps = const Value.absent(),
                Value<double?> targetRpe = const Value.absent(),
                Value<double?> targetWeight = const Value.absent(),
                Value<int> restSeconds = const Value.absent(),
                Value<int> warmupSets = const Value.absent(),
                Value<int> dropSets = const Value.absent(),
                Value<int> failureSets = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutineExercisesCompanion(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                routineId: routineId,
                exerciseId: exerciseId,
                orderIndex: orderIndex,
                supersetGroup: supersetGroup,
                targetSets: targetSets,
                targetReps: targetReps,
                targetRpe: targetRpe,
                targetWeight: targetWeight,
                restSeconds: restSeconds,
                warmupSets: warmupSets,
                dropSets: dropSets,
                failureSets: failureSets,
                isWarmup: isWarmup,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String routineId,
                required String exerciseId,
                required int orderIndex,
                Value<int?> supersetGroup = const Value.absent(),
                Value<int> targetSets = const Value.absent(),
                Value<int> targetReps = const Value.absent(),
                Value<double?> targetRpe = const Value.absent(),
                Value<double?> targetWeight = const Value.absent(),
                Value<int> restSeconds = const Value.absent(),
                Value<int> warmupSets = const Value.absent(),
                Value<int> dropSets = const Value.absent(),
                Value<int> failureSets = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutineExercisesCompanion.insert(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                routineId: routineId,
                exerciseId: exerciseId,
                orderIndex: orderIndex,
                supersetGroup: supersetGroup,
                targetSets: targetSets,
                targetReps: targetReps,
                targetRpe: targetRpe,
                targetWeight: targetWeight,
                restSeconds: restSeconds,
                warmupSets: warmupSets,
                dropSets: dropSets,
                failureSets: failureSets,
                isWarmup: isWarmup,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RoutineExercisesTable, RoutineExercise>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RoutineExercisesTable,
                    RoutineExercise
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
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
      (
        RoutineExercise,
        BaseReferences<_$AppDatabase, $RoutineExercisesTable, RoutineExercise>,
      ),
      RoutineExercise,
      PrefetchHooks Function()
    >;
typedef $$WeeklyPlansTableCreateCompanionBuilder =
    WeeklyPlansCompanion Function({
      required DateTime updatedAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> deletedAt,
      Value<int> weekday,
      Value<String?> routineId,
    });
typedef $$WeeklyPlansTableUpdateCompanionBuilder =
    WeeklyPlansCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> deletedAt,
      Value<int> weekday,
      Value<String?> routineId,
    });

class $$WeeklyPlansTableFilterComposer
    extends Composer<_$AppDatabase, $WeeklyPlansTable> {
  $$WeeklyPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeeklyPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $WeeklyPlansTable> {
  $$WeeklyPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeeklyPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeeklyPlansTable> {
  $$WeeklyPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);
}

class $$WeeklyPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeeklyPlansTable,
          WeeklyPlan,
          $$WeeklyPlansTableFilterComposer,
          $$WeeklyPlansTableOrderingComposer,
          $$WeeklyPlansTableAnnotationComposer,
          $$WeeklyPlansTableCreateCompanionBuilder,
          $$WeeklyPlansTableUpdateCompanionBuilder,
          (
            WeeklyPlan,
            BaseReferences<_$AppDatabase, $WeeklyPlansTable, WeeklyPlan>,
          ),
          WeeklyPlan,
          PrefetchHooks Function()
        > {
  $$WeeklyPlansTableTableManager(_$AppDatabase db, $WeeklyPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklyPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeklyPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<String?> routineId = const Value.absent(),
              }) => WeeklyPlansCompanion(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                weekday: weekday,
                routineId: routineId,
              ),
          createCompanionCallback:
              ({
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<String?> routineId = const Value.absent(),
              }) => WeeklyPlansCompanion.insert(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                weekday: weekday,
                routineId: routineId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeeklyPlansTable, WeeklyPlan>(table),
                  BaseReferences<_$AppDatabase, $WeeklyPlansTable, WeeklyPlan>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeeklyPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeeklyPlansTable,
      WeeklyPlan,
      $$WeeklyPlansTableFilterComposer,
      $$WeeklyPlansTableOrderingComposer,
      $$WeeklyPlansTableAnnotationComposer,
      $$WeeklyPlansTableCreateCompanionBuilder,
      $$WeeklyPlansTableUpdateCompanionBuilder,
      (
        WeeklyPlan,
        BaseReferences<_$AppDatabase, $WeeklyPlansTable, WeeklyPlan>,
      ),
      WeeklyPlan,
      PrefetchHooks Function()
    >;
typedef $$WorkoutsTableCreateCompanionBuilder = WorkoutsCompanion Function({
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  required String id,
  required String userId,
  Value<String?> routineId,
  Value<String> status,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<int?> durationSec,
  Value<double> totalVolume,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$WorkoutsTableUpdateCompanionBuilder = WorkoutsCompanion Function({
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<DateTime?> deletedAt,
  Value<String> id,
  Value<String> userId,
  Value<String?> routineId,
  Value<String> status,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<int?> durationSec,
  Value<double> totalVolume,
  Value<String?> notes,
  Value<int> rowid,
});

class $$WorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalVolume => $composableBuilder(
    column: $table.totalVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalVolume => $composableBuilder(
    column: $table.totalVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalVolume => $composableBuilder(
    column: $table.totalVolume,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$WorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutsTable,
          Workout,
          $$WorkoutsTableFilterComposer,
          $$WorkoutsTableOrderingComposer,
          $$WorkoutsTableAnnotationComposer,
          $$WorkoutsTableCreateCompanionBuilder,
          $$WorkoutsTableUpdateCompanionBuilder,
          (Workout, BaseReferences<_$AppDatabase, $WorkoutsTable, Workout>),
          Workout,
          PrefetchHooks Function()
        > {
  $$WorkoutsTableTableManager(_$AppDatabase db, $WorkoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> routineId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<double> totalVolume = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutsCompanion(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                userId: userId,
                routineId: routineId,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSec: durationSec,
                totalVolume: totalVolume,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String userId,
                Value<String?> routineId = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<double> totalVolume = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutsCompanion.insert(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                userId: userId,
                routineId: routineId,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSec: durationSec,
                totalVolume: totalVolume,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutsTable, Workout>(table),
                  BaseReferences<_$AppDatabase, $WorkoutsTable, Workout>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutsTable,
      Workout,
      $$WorkoutsTableFilterComposer,
      $$WorkoutsTableOrderingComposer,
      $$WorkoutsTableAnnotationComposer,
      $$WorkoutsTableCreateCompanionBuilder,
      $$WorkoutsTableUpdateCompanionBuilder,
      (Workout, BaseReferences<_$AppDatabase, $WorkoutsTable, Workout>),
      Workout,
      PrefetchHooks Function()
    >;
typedef $$WorkoutSetsTableCreateCompanionBuilder =
    WorkoutSetsCompanion Function({
      required DateTime updatedAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> deletedAt,
      required String id,
      required String workoutId,
      required String exerciseId,
      required int orderIndex,
      Value<String> setType,
      Value<int?> supersetGroup,
      Value<double?> weightKg,
      Value<int?> reps,
      Value<double?> rpe,
      Value<double?> distanceM,
      Value<int?> durationSec,
      Value<int?> heartRate,
      Value<bool> isCompleted,
      Value<DateTime?> loggedAt,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$WorkoutSetsTableUpdateCompanionBuilder =
    WorkoutSetsCompanion Function({
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> deletedAt,
      Value<String> id,
      Value<String> workoutId,
      Value<String> exerciseId,
      Value<int> orderIndex,
      Value<String> setType,
      Value<int?> supersetGroup,
      Value<double?> weightKg,
      Value<int?> reps,
      Value<double?> rpe,
      Value<double?> distanceM,
      Value<int?> durationSec,
      Value<int?> heartRate,
      Value<bool> isCompleted,
      Value<DateTime?> loggedAt,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$WorkoutSetsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workoutId => $composableBuilder(
    column: $table.workoutId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setType => $composableBuilder(
    column: $table.setType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heartRate => $composableBuilder(
    column: $table.heartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
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
  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutId => $composableBuilder(
    column: $table.workoutId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setType => $composableBuilder(
    column: $table.setType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heartRate => $composableBuilder(
    column: $table.heartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
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
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workoutId =>
      $composableBuilder(column: $table.workoutId, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get setType =>
      $composableBuilder(column: $table.setType, builder: (column) => column);

  GeneratedColumn<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heartRate =>
      $composableBuilder(column: $table.heartRate, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
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
          (
            WorkoutSet,
            BaseReferences<_$AppDatabase, $WorkoutSetsTable, WorkoutSet>,
          ),
          WorkoutSet,
          PrefetchHooks Function()
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
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> workoutId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String> setType = const Value.absent(),
                Value<int?> supersetGroup = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<int?> heartRate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> loggedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSetsCompanion(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                workoutId: workoutId,
                exerciseId: exerciseId,
                orderIndex: orderIndex,
                setType: setType,
                supersetGroup: supersetGroup,
                weightKg: weightKg,
                reps: reps,
                rpe: rpe,
                distanceM: distanceM,
                durationSec: durationSec,
                heartRate: heartRate,
                isCompleted: isCompleted,
                loggedAt: loggedAt,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String workoutId,
                required String exerciseId,
                required int orderIndex,
                Value<String> setType = const Value.absent(),
                Value<int?> supersetGroup = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<int?> heartRate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> loggedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSetsCompanion.insert(
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                deletedAt: deletedAt,
                id: id,
                workoutId: workoutId,
                exerciseId: exerciseId,
                orderIndex: orderIndex,
                setType: setType,
                supersetGroup: supersetGroup,
                weightKg: weightKg,
                reps: reps,
                rpe: rpe,
                distanceM: distanceM,
                durationSec: durationSec,
                heartRate: heartRate,
                isCompleted: isCompleted,
                loggedAt: loggedAt,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutSetsTable, WorkoutSet>(table),
                  BaseReferences<_$AppDatabase, $WorkoutSetsTable, WorkoutSet>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
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
      (
        WorkoutSet,
        BaseReferences<_$AppDatabase, $WorkoutSetsTable, WorkoutSet>,
      ),
      WorkoutSet,
      PrefetchHooks Function()
    >;
typedef $$MuscleVolumeDailyTableCreateCompanionBuilder =
    MuscleVolumeDailyCompanion Function({
      required String userId,
      required String muscleId,
      required DateTime date,
      Value<int> totalSets,
      Value<double> volume,
      Value<double> bestE1Rm,
      Value<int> rowid,
    });
typedef $$MuscleVolumeDailyTableUpdateCompanionBuilder =
    MuscleVolumeDailyCompanion Function({
      Value<String> userId,
      Value<String> muscleId,
      Value<DateTime> date,
      Value<int> totalSets,
      Value<double> volume,
      Value<double> bestE1Rm,
      Value<int> rowid,
    });

class $$MuscleVolumeDailyTableFilterComposer
    extends Composer<_$AppDatabase, $MuscleVolumeDailyTable> {
  $$MuscleVolumeDailyTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get muscleId => $composableBuilder(
    column: $table.muscleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSets => $composableBuilder(
    column: $table.totalSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bestE1Rm => $composableBuilder(
    column: $table.bestE1Rm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MuscleVolumeDailyTableOrderingComposer
    extends Composer<_$AppDatabase, $MuscleVolumeDailyTable> {
  $$MuscleVolumeDailyTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muscleId => $composableBuilder(
    column: $table.muscleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSets => $composableBuilder(
    column: $table.totalSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bestE1Rm => $composableBuilder(
    column: $table.bestE1Rm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MuscleVolumeDailyTableAnnotationComposer
    extends Composer<_$AppDatabase, $MuscleVolumeDailyTable> {
  $$MuscleVolumeDailyTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get muscleId =>
      $composableBuilder(column: $table.muscleId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get totalSets =>
      $composableBuilder(column: $table.totalSets, builder: (column) => column);

  GeneratedColumn<double> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  GeneratedColumn<double> get bestE1Rm =>
      $composableBuilder(column: $table.bestE1Rm, builder: (column) => column);
}

class $$MuscleVolumeDailyTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MuscleVolumeDailyTable,
          MuscleVolumeDailyData,
          $$MuscleVolumeDailyTableFilterComposer,
          $$MuscleVolumeDailyTableOrderingComposer,
          $$MuscleVolumeDailyTableAnnotationComposer,
          $$MuscleVolumeDailyTableCreateCompanionBuilder,
          $$MuscleVolumeDailyTableUpdateCompanionBuilder,
          (
            MuscleVolumeDailyData,
            BaseReferences<
              _$AppDatabase,
              $MuscleVolumeDailyTable,
              MuscleVolumeDailyData
            >,
          ),
          MuscleVolumeDailyData,
          PrefetchHooks Function()
        > {
  $$MuscleVolumeDailyTableTableManager(
    _$AppDatabase db,
    $MuscleVolumeDailyTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MuscleVolumeDailyTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MuscleVolumeDailyTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MuscleVolumeDailyTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> muscleId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> totalSets = const Value.absent(),
                Value<double> volume = const Value.absent(),
                Value<double> bestE1Rm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MuscleVolumeDailyCompanion(
                userId: userId,
                muscleId: muscleId,
                date: date,
                totalSets: totalSets,
                volume: volume,
                bestE1Rm: bestE1Rm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String muscleId,
                required DateTime date,
                Value<int> totalSets = const Value.absent(),
                Value<double> volume = const Value.absent(),
                Value<double> bestE1Rm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MuscleVolumeDailyCompanion.insert(
                userId: userId,
                muscleId: muscleId,
                date: date,
                totalSets: totalSets,
                volume: volume,
                bestE1Rm: bestE1Rm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MuscleVolumeDailyTable, MuscleVolumeDailyData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $MuscleVolumeDailyTable,
                    MuscleVolumeDailyData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MuscleVolumeDailyTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MuscleVolumeDailyTable,
      MuscleVolumeDailyData,
      $$MuscleVolumeDailyTableFilterComposer,
      $$MuscleVolumeDailyTableOrderingComposer,
      $$MuscleVolumeDailyTableAnnotationComposer,
      $$MuscleVolumeDailyTableCreateCompanionBuilder,
      $$MuscleVolumeDailyTableUpdateCompanionBuilder,
      (
        MuscleVolumeDailyData,
        BaseReferences<
          _$AppDatabase,
          $MuscleVolumeDailyTable,
          MuscleVolumeDailyData
        >,
      ),
      MuscleVolumeDailyData,
      PrefetchHooks Function()
    >;
typedef $$ExerciseHistoryTableCreateCompanionBuilder =
    ExerciseHistoryCompanion Function({
      required String userId,
      required String exerciseId,
      required DateTime date,
      Value<double> bestE1Rm,
      Value<double> topWeight,
      Value<int> topReps,
      Value<double> totalVolume,
      Value<int> rowid,
    });
typedef $$ExerciseHistoryTableUpdateCompanionBuilder =
    ExerciseHistoryCompanion Function({
      Value<String> userId,
      Value<String> exerciseId,
      Value<DateTime> date,
      Value<double> bestE1Rm,
      Value<double> topWeight,
      Value<int> topReps,
      Value<double> totalVolume,
      Value<int> rowid,
    });

class $$ExerciseHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseHistoryTable> {
  $$ExerciseHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bestE1Rm => $composableBuilder(
    column: $table.bestE1Rm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get topWeight => $composableBuilder(
    column: $table.topWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get topReps => $composableBuilder(
    column: $table.topReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalVolume => $composableBuilder(
    column: $table.totalVolume,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseHistoryTable> {
  $$ExerciseHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bestE1Rm => $composableBuilder(
    column: $table.bestE1Rm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get topWeight => $composableBuilder(
    column: $table.topWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get topReps => $composableBuilder(
    column: $table.topReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalVolume => $composableBuilder(
    column: $table.totalVolume,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseHistoryTable> {
  $$ExerciseHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get bestE1Rm =>
      $composableBuilder(column: $table.bestE1Rm, builder: (column) => column);

  GeneratedColumn<double> get topWeight =>
      $composableBuilder(column: $table.topWeight, builder: (column) => column);

  GeneratedColumn<int> get topReps =>
      $composableBuilder(column: $table.topReps, builder: (column) => column);

  GeneratedColumn<double> get totalVolume => $composableBuilder(
    column: $table.totalVolume,
    builder: (column) => column,
  );
}

class $$ExerciseHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseHistoryTable,
          ExerciseHistoryData,
          $$ExerciseHistoryTableFilterComposer,
          $$ExerciseHistoryTableOrderingComposer,
          $$ExerciseHistoryTableAnnotationComposer,
          $$ExerciseHistoryTableCreateCompanionBuilder,
          $$ExerciseHistoryTableUpdateCompanionBuilder,
          (
            ExerciseHistoryData,
            BaseReferences<
              _$AppDatabase,
              $ExerciseHistoryTable,
              ExerciseHistoryData
            >,
          ),
          ExerciseHistoryData,
          PrefetchHooks Function()
        > {
  $$ExerciseHistoryTableTableManager(
    _$AppDatabase db,
    $ExerciseHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> bestE1Rm = const Value.absent(),
                Value<double> topWeight = const Value.absent(),
                Value<int> topReps = const Value.absent(),
                Value<double> totalVolume = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseHistoryCompanion(
                userId: userId,
                exerciseId: exerciseId,
                date: date,
                bestE1Rm: bestE1Rm,
                topWeight: topWeight,
                topReps: topReps,
                totalVolume: totalVolume,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String exerciseId,
                required DateTime date,
                Value<double> bestE1Rm = const Value.absent(),
                Value<double> topWeight = const Value.absent(),
                Value<int> topReps = const Value.absent(),
                Value<double> totalVolume = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseHistoryCompanion.insert(
                userId: userId,
                exerciseId: exerciseId,
                date: date,
                bestE1Rm: bestE1Rm,
                topWeight: topWeight,
                topReps: topReps,
                totalVolume: totalVolume,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExerciseHistoryTable, ExerciseHistoryData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ExerciseHistoryTable,
                    ExerciseHistoryData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseHistoryTable,
      ExerciseHistoryData,
      $$ExerciseHistoryTableFilterComposer,
      $$ExerciseHistoryTableOrderingComposer,
      $$ExerciseHistoryTableAnnotationComposer,
      $$ExerciseHistoryTableCreateCompanionBuilder,
      $$ExerciseHistoryTableUpdateCompanionBuilder,
      (
        ExerciseHistoryData,
        BaseReferences<
          _$AppDatabase,
          $ExerciseHistoryTable,
          ExerciseHistoryData
        >,
      ),
      ExerciseHistoryData,
      PrefetchHooks Function()
    >;
typedef $$MuscleGradeHistoryTableCreateCompanionBuilder =
    MuscleGradeHistoryCompanion Function({
      required String userId,
      required String muscleId,
      required DateTime computedAt,
      required String grade,
      required double score,
      required double volumeComponent,
      required double strengthComponent,
      required double consistencyComponent,
      Value<int> rowid,
    });
typedef $$MuscleGradeHistoryTableUpdateCompanionBuilder =
    MuscleGradeHistoryCompanion Function({
      Value<String> userId,
      Value<String> muscleId,
      Value<DateTime> computedAt,
      Value<String> grade,
      Value<double> score,
      Value<double> volumeComponent,
      Value<double> strengthComponent,
      Value<double> consistencyComponent,
      Value<int> rowid,
    });

class $$MuscleGradeHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $MuscleGradeHistoryTable> {
  $$MuscleGradeHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get muscleId => $composableBuilder(
    column: $table.muscleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get volumeComponent => $composableBuilder(
    column: $table.volumeComponent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get strengthComponent => $composableBuilder(
    column: $table.strengthComponent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get consistencyComponent => $composableBuilder(
    column: $table.consistencyComponent,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MuscleGradeHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $MuscleGradeHistoryTable> {
  $$MuscleGradeHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muscleId => $composableBuilder(
    column: $table.muscleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get volumeComponent => $composableBuilder(
    column: $table.volumeComponent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get strengthComponent => $composableBuilder(
    column: $table.strengthComponent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get consistencyComponent => $composableBuilder(
    column: $table.consistencyComponent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MuscleGradeHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $MuscleGradeHistoryTable> {
  $$MuscleGradeHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get muscleId =>
      $composableBuilder(column: $table.muscleId, builder: (column) => column);

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<double> get volumeComponent => $composableBuilder(
    column: $table.volumeComponent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get strengthComponent => $composableBuilder(
    column: $table.strengthComponent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get consistencyComponent => $composableBuilder(
    column: $table.consistencyComponent,
    builder: (column) => column,
  );
}

class $$MuscleGradeHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MuscleGradeHistoryTable,
          MuscleGradeHistoryData,
          $$MuscleGradeHistoryTableFilterComposer,
          $$MuscleGradeHistoryTableOrderingComposer,
          $$MuscleGradeHistoryTableAnnotationComposer,
          $$MuscleGradeHistoryTableCreateCompanionBuilder,
          $$MuscleGradeHistoryTableUpdateCompanionBuilder,
          (
            MuscleGradeHistoryData,
            BaseReferences<
              _$AppDatabase,
              $MuscleGradeHistoryTable,
              MuscleGradeHistoryData
            >,
          ),
          MuscleGradeHistoryData,
          PrefetchHooks Function()
        > {
  $$MuscleGradeHistoryTableTableManager(
    _$AppDatabase db,
    $MuscleGradeHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MuscleGradeHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MuscleGradeHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MuscleGradeHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> muscleId = const Value.absent(),
                Value<DateTime> computedAt = const Value.absent(),
                Value<String> grade = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<double> volumeComponent = const Value.absent(),
                Value<double> strengthComponent = const Value.absent(),
                Value<double> consistencyComponent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MuscleGradeHistoryCompanion(
                userId: userId,
                muscleId: muscleId,
                computedAt: computedAt,
                grade: grade,
                score: score,
                volumeComponent: volumeComponent,
                strengthComponent: strengthComponent,
                consistencyComponent: consistencyComponent,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String muscleId,
                required DateTime computedAt,
                required String grade,
                required double score,
                required double volumeComponent,
                required double strengthComponent,
                required double consistencyComponent,
                Value<int> rowid = const Value.absent(),
              }) => MuscleGradeHistoryCompanion.insert(
                userId: userId,
                muscleId: muscleId,
                computedAt: computedAt,
                grade: grade,
                score: score,
                volumeComponent: volumeComponent,
                strengthComponent: strengthComponent,
                consistencyComponent: consistencyComponent,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MuscleGradeHistoryTable, MuscleGradeHistoryData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $MuscleGradeHistoryTable,
                    MuscleGradeHistoryData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MuscleGradeHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MuscleGradeHistoryTable,
      MuscleGradeHistoryData,
      $$MuscleGradeHistoryTableFilterComposer,
      $$MuscleGradeHistoryTableOrderingComposer,
      $$MuscleGradeHistoryTableAnnotationComposer,
      $$MuscleGradeHistoryTableCreateCompanionBuilder,
      $$MuscleGradeHistoryTableUpdateCompanionBuilder,
      (
        MuscleGradeHistoryData,
        BaseReferences<
          _$AppDatabase,
          $MuscleGradeHistoryTable,
          MuscleGradeHistoryData
        >,
      ),
      MuscleGradeHistoryData,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String targetTable,
  required String rowId,
  required String op,
  required String payload,
  required DateTime createdAt,
  Value<int> retries,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> targetTable,
  Value<String> rowId,
  Value<String> op,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<int> retries,
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
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retries => $composableBuilder(
    column: $table.retries,
    builder: (column) => ColumnFilters(column),
  );
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
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retries => $composableBuilder(
    column: $table.retries,
    builder: (column) => ColumnOrderings(column),
  );
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

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retries =>
      $composableBuilder(column: $table.retries, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
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
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retries = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                targetTable: targetTable,
                rowId: rowId,
                op: op,
                payload: payload,
                createdAt: createdAt,
                retries: retries,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String targetTable,
                required String rowId,
                required String op,
                required String payload,
                required DateTime createdAt,
                Value<int> retries = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                targetTable: targetTable,
                rowId: rowId,
                op: op,
                payload: payload,
                createdAt: createdAt,
                retries: retries,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueTable, SyncQueueData>(table),
                  BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
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
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$MuscleGroupsTableTableManager get muscleGroups =>
      $$MuscleGroupsTableTableManager(_db, _db.muscleGroups);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$ExerciseMuscleMapTableTableManager get exerciseMuscleMap =>
      $$ExerciseMuscleMapTableTableManager(_db, _db.exerciseMuscleMap);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db, _db.routines);
  $$RoutineExercisesTableTableManager get routineExercises =>
      $$RoutineExercisesTableTableManager(_db, _db.routineExercises);
  $$WeeklyPlansTableTableManager get weeklyPlans =>
      $$WeeklyPlansTableTableManager(_db, _db.weeklyPlans);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db, _db.workouts);
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db, _db.workoutSets);
  $$MuscleVolumeDailyTableTableManager get muscleVolumeDaily =>
      $$MuscleVolumeDailyTableTableManager(_db, _db.muscleVolumeDaily);
  $$ExerciseHistoryTableTableManager get exerciseHistory =>
      $$ExerciseHistoryTableTableManager(_db, _db.exerciseHistory);
  $$MuscleGradeHistoryTableTableManager get muscleGradeHistory =>
      $$MuscleGradeHistoryTableTableManager(_db, _db.muscleGradeHistory);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
