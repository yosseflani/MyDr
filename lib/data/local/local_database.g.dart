// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class FamilyMembers extends Table
    with TableInfo<FamilyMembers, FamilyMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FamilyMembers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) > 0)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) > 0)',
  );
  static const VerificationMeta _relationMeta = const VerificationMeta(
    'relation',
  );
  late final GeneratedColumn<String> relation = GeneratedColumn<String>(
    'relation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (relation IN (\'self\', \'spouse\', \'child\', \'parent\', \'sibling\', \'grandparent\', \'other\'))',
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  late final GeneratedColumn<String> birthDate = GeneratedColumn<String>(
    'birth_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (birth_date IS NULL OR(length(birth_date) = 10 AND birth_date GLOB \'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\'))',
  );
  static const VerificationMeta _allergiesMeta = const VerificationMeta(
    'allergies',
  );
  late final GeneratedColumn<String> allergies = GeneratedColumn<String>(
    'allergies',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'[]\' CHECK (json_valid(allergies) AND json_type(allergies) = \'array\')',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _chronicConditionsMeta = const VerificationMeta(
    'chronicConditions',
  );
  late final GeneratedColumn<String>
  chronicConditions = GeneratedColumn<String>(
    'chronic_conditions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'[]\' CHECK (json_valid(chronic_conditions) AND json_type(chronic_conditions) = \'array\')',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    relation,
    birthDate,
    allergies,
    chronicConditions,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyMemberRow> instance, {
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
    if (data.containsKey('relation')) {
      context.handle(
        _relationMeta,
        relation.isAcceptableOrUnknown(data['relation']!, _relationMeta),
      );
    } else if (isInserting) {
      context.missing(_relationMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    }
    if (data.containsKey('allergies')) {
      context.handle(
        _allergiesMeta,
        allergies.isAcceptableOrUnknown(data['allergies']!, _allergiesMeta),
      );
    }
    if (data.containsKey('chronic_conditions')) {
      context.handle(
        _chronicConditionsMeta,
        chronicConditions.isAcceptableOrUnknown(
          data['chronic_conditions']!,
          _chronicConditionsMeta,
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
  FamilyMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyMemberRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      relation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation'],
      )!,
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birth_date'],
      ),
      allergies: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allergies'],
      )!,
      chronicConditions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chronic_conditions'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  FamilyMembers createAlias(String alias) {
    return FamilyMembers(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class FamilyMemberRow extends DataClass implements Insertable<FamilyMemberRow> {
  final String id;
  final String name;
  final String relation;
  final String? birthDate;
  final String allergies;
  final String chronicConditions;
  final String? notes;
  const FamilyMemberRow({
    required this.id,
    required this.name,
    required this.relation,
    this.birthDate,
    required this.allergies,
    required this.chronicConditions,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['relation'] = Variable<String>(relation);
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<String>(birthDate);
    }
    map['allergies'] = Variable<String>(allergies);
    map['chronic_conditions'] = Variable<String>(chronicConditions);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  FamilyMembersCompanion toCompanion(bool nullToAbsent) {
    return FamilyMembersCompanion(
      id: Value(id),
      name: Value(name),
      relation: Value(relation),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      allergies: Value(allergies),
      chronicConditions: Value(chronicConditions),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory FamilyMemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyMemberRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      relation: serializer.fromJson<String>(json['relation']),
      birthDate: serializer.fromJson<String?>(json['birth_date']),
      allergies: serializer.fromJson<String>(json['allergies']),
      chronicConditions: serializer.fromJson<String>(
        json['chronic_conditions'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'relation': serializer.toJson<String>(relation),
      'birth_date': serializer.toJson<String?>(birthDate),
      'allergies': serializer.toJson<String>(allergies),
      'chronic_conditions': serializer.toJson<String>(chronicConditions),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  FamilyMemberRow copyWith({
    String? id,
    String? name,
    String? relation,
    Value<String?> birthDate = const Value.absent(),
    String? allergies,
    String? chronicConditions,
    Value<String?> notes = const Value.absent(),
  }) => FamilyMemberRow(
    id: id ?? this.id,
    name: name ?? this.name,
    relation: relation ?? this.relation,
    birthDate: birthDate.present ? birthDate.value : this.birthDate,
    allergies: allergies ?? this.allergies,
    chronicConditions: chronicConditions ?? this.chronicConditions,
    notes: notes.present ? notes.value : this.notes,
  );
  FamilyMemberRow copyWithCompanion(FamilyMembersCompanion data) {
    return FamilyMemberRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      relation: data.relation.present ? data.relation.value : this.relation,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      allergies: data.allergies.present ? data.allergies.value : this.allergies,
      chronicConditions: data.chronicConditions.present
          ? data.chronicConditions.value
          : this.chronicConditions,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyMemberRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('relation: $relation, ')
          ..write('birthDate: $birthDate, ')
          ..write('allergies: $allergies, ')
          ..write('chronicConditions: $chronicConditions, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    relation,
    birthDate,
    allergies,
    chronicConditions,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyMemberRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.relation == this.relation &&
          other.birthDate == this.birthDate &&
          other.allergies == this.allergies &&
          other.chronicConditions == this.chronicConditions &&
          other.notes == this.notes);
}

class FamilyMembersCompanion extends UpdateCompanion<FamilyMemberRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> relation;
  final Value<String?> birthDate;
  final Value<String> allergies;
  final Value<String> chronicConditions;
  final Value<String?> notes;
  final Value<int> rowid;
  const FamilyMembersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.relation = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.allergies = const Value.absent(),
    this.chronicConditions = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamilyMembersCompanion.insert({
    required String id,
    required String name,
    required String relation,
    this.birthDate = const Value.absent(),
    this.allergies = const Value.absent(),
    this.chronicConditions = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       relation = Value(relation);
  static Insertable<FamilyMemberRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? relation,
    Expression<String>? birthDate,
    Expression<String>? allergies,
    Expression<String>? chronicConditions,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (relation != null) 'relation': relation,
      if (birthDate != null) 'birth_date': birthDate,
      if (allergies != null) 'allergies': allergies,
      if (chronicConditions != null) 'chronic_conditions': chronicConditions,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamilyMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? relation,
    Value<String?>? birthDate,
    Value<String>? allergies,
    Value<String>? chronicConditions,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return FamilyMembersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      birthDate: birthDate ?? this.birthDate,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      notes: notes ?? this.notes,
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
    if (relation.present) {
      map['relation'] = Variable<String>(relation.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<String>(birthDate.value);
    }
    if (allergies.present) {
      map['allergies'] = Variable<String>(allergies.value);
    }
    if (chronicConditions.present) {
      map['chronic_conditions'] = Variable<String>(chronicConditions.value);
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
    return (StringBuffer('FamilyMembersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('relation: $relation, ')
          ..write('birthDate: $birthDate, ')
          ..write('allergies: $allergies, ')
          ..write('chronicConditions: $chronicConditions, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Appointments extends Table with TableInfo<Appointments, AppointmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Appointments(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) > 0)',
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES family_members(id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _doctorNameMeta = const VerificationMeta(
    'doctorName',
  );
  late final GeneratedColumn<String> doctorName = GeneratedColumn<String>(
    'doctor_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(doctor_name)) > 0)',
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  late final GeneratedColumn<String> scheduledAt = GeneratedColumn<String>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(scheduled_at) = 26 AND scheduled_at GLOB \'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9][0-9][0-9][0-9]\')',
  );
  static const VerificationMeta _specialtyMeta = const VerificationMeta(
    'specialty',
  );
  late final GeneratedColumn<String> specialty = GeneratedColumn<String>(
    'specialty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    doctorName,
    scheduledAt,
    specialty,
    location,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'appointments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppointmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('doctor_name')) {
      context.handle(
        _doctorNameMeta,
        doctorName.isAcceptableOrUnknown(data['doctor_name']!, _doctorNameMeta),
      );
    } else if (isInserting) {
      context.missing(_doctorNameMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('specialty')) {
      context.handle(
        _specialtyMeta,
        specialty.isAcceptableOrUnknown(data['specialty']!, _specialtyMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {id, memberId},
  ];
  @override
  AppointmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppointmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      doctorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doctor_name'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_at'],
      )!,
      specialty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}specialty'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  Appointments createAlias(String alias) {
    return Appointments(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const ['UNIQUE(id, member_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class AppointmentRow extends DataClass implements Insertable<AppointmentRow> {
  final String id;
  final String memberId;
  final String doctorName;
  final String scheduledAt;
  final String? specialty;
  final String? location;
  final String? notes;
  const AppointmentRow({
    required this.id,
    required this.memberId,
    required this.doctorName,
    required this.scheduledAt,
    this.specialty,
    this.location,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['doctor_name'] = Variable<String>(doctorName);
    map['scheduled_at'] = Variable<String>(scheduledAt);
    if (!nullToAbsent || specialty != null) {
      map['specialty'] = Variable<String>(specialty);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  AppointmentsCompanion toCompanion(bool nullToAbsent) {
    return AppointmentsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      doctorName: Value(doctorName),
      scheduledAt: Value(scheduledAt),
      specialty: specialty == null && nullToAbsent
          ? const Value.absent()
          : Value(specialty),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory AppointmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppointmentRow(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['member_id']),
      doctorName: serializer.fromJson<String>(json['doctor_name']),
      scheduledAt: serializer.fromJson<String>(json['scheduled_at']),
      specialty: serializer.fromJson<String?>(json['specialty']),
      location: serializer.fromJson<String?>(json['location']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'member_id': serializer.toJson<String>(memberId),
      'doctor_name': serializer.toJson<String>(doctorName),
      'scheduled_at': serializer.toJson<String>(scheduledAt),
      'specialty': serializer.toJson<String?>(specialty),
      'location': serializer.toJson<String?>(location),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  AppointmentRow copyWith({
    String? id,
    String? memberId,
    String? doctorName,
    String? scheduledAt,
    Value<String?> specialty = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => AppointmentRow(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    doctorName: doctorName ?? this.doctorName,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    specialty: specialty.present ? specialty.value : this.specialty,
    location: location.present ? location.value : this.location,
    notes: notes.present ? notes.value : this.notes,
  );
  AppointmentRow copyWithCompanion(AppointmentsCompanion data) {
    return AppointmentRow(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      doctorName: data.doctorName.present
          ? data.doctorName.value
          : this.doctorName,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      specialty: data.specialty.present ? data.specialty.value : this.specialty,
      location: data.location.present ? data.location.value : this.location,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppointmentRow(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('doctorName: $doctorName, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('specialty: $specialty, ')
          ..write('location: $location, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    doctorName,
    scheduledAt,
    specialty,
    location,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppointmentRow &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.doctorName == this.doctorName &&
          other.scheduledAt == this.scheduledAt &&
          other.specialty == this.specialty &&
          other.location == this.location &&
          other.notes == this.notes);
}

class AppointmentsCompanion extends UpdateCompanion<AppointmentRow> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> doctorName;
  final Value<String> scheduledAt;
  final Value<String?> specialty;
  final Value<String?> location;
  final Value<String?> notes;
  final Value<int> rowid;
  const AppointmentsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.doctorName = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.specialty = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppointmentsCompanion.insert({
    required String id,
    required String memberId,
    required String doctorName,
    required String scheduledAt,
    this.specialty = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       doctorName = Value(doctorName),
       scheduledAt = Value(scheduledAt);
  static Insertable<AppointmentRow> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? doctorName,
    Expression<String>? scheduledAt,
    Expression<String>? specialty,
    Expression<String>? location,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (doctorName != null) 'doctor_name': doctorName,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (specialty != null) 'specialty': specialty,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppointmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? doctorName,
    Value<String>? scheduledAt,
    Value<String?>? specialty,
    Value<String?>? location,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return AppointmentsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      doctorName: doctorName ?? this.doctorName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      specialty: specialty ?? this.specialty,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (doctorName.present) {
      map['doctor_name'] = Variable<String>(doctorName.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<String>(scheduledAt.value);
    }
    if (specialty.present) {
      map['specialty'] = Variable<String>(specialty.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
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
    return (StringBuffer('AppointmentsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('doctorName: $doctorName, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('specialty: $specialty, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DoctorQuestions extends Table
    with TableInfo<DoctorQuestions, DoctorQuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DoctorQuestions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) > 0)',
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES family_members(id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _appointmentIdMeta = const VerificationMeta(
    'appointmentId',
  );
  late final GeneratedColumn<String> appointmentId = GeneratedColumn<String>(
    'appointment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _questionTextMeta = const VerificationMeta(
    'questionText',
  );
  late final GeneratedColumn<String> questionText = GeneratedColumn<String>(
    'question_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(question_text)) > 0)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _isResolvedMeta = const VerificationMeta(
    'isResolved',
  );
  late final GeneratedColumn<int> isResolved = GeneratedColumn<int>(
    'is_resolved',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (is_resolved IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _doctorAnswerMeta = const VerificationMeta(
    'doctorAnswer',
  );
  late final GeneratedColumn<String> doctorAnswer = GeneratedColumn<String>(
    'doctor_answer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    appointmentId,
    questionText,
    createdAt,
    isResolved,
    doctorAnswer,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'doctor_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DoctorQuestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('appointment_id')) {
      context.handle(
        _appointmentIdMeta,
        appointmentId.isAcceptableOrUnknown(
          data['appointment_id']!,
          _appointmentIdMeta,
        ),
      );
    }
    if (data.containsKey('question_text')) {
      context.handle(
        _questionTextMeta,
        questionText.isAcceptableOrUnknown(
          data['question_text']!,
          _questionTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionTextMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_resolved')) {
      context.handle(
        _isResolvedMeta,
        isResolved.isAcceptableOrUnknown(data['is_resolved']!, _isResolvedMeta),
      );
    }
    if (data.containsKey('doctor_answer')) {
      context.handle(
        _doctorAnswerMeta,
        doctorAnswer.isAcceptableOrUnknown(
          data['doctor_answer']!,
          _doctorAnswerMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DoctorQuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DoctorQuestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      appointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_id'],
      ),
      questionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      isResolved: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_resolved'],
      )!,
      doctorAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doctor_answer'],
      ),
    );
  }

  @override
  DoctorQuestions createAlias(String alias) {
    return DoctorQuestions(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY(appointment_id, member_id)REFERENCES appointments(id, member_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class DoctorQuestionRow extends DataClass
    implements Insertable<DoctorQuestionRow> {
  final String id;
  final String memberId;

  /// Null for a general question.
  final String? appointmentId;
  final String questionText;
  final int createdAt;
  final int isResolved;
  final String? doctorAnswer;
  const DoctorQuestionRow({
    required this.id,
    required this.memberId,
    this.appointmentId,
    required this.questionText,
    required this.createdAt,
    required this.isResolved,
    this.doctorAnswer,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    if (!nullToAbsent || appointmentId != null) {
      map['appointment_id'] = Variable<String>(appointmentId);
    }
    map['question_text'] = Variable<String>(questionText);
    map['created_at'] = Variable<int>(createdAt);
    map['is_resolved'] = Variable<int>(isResolved);
    if (!nullToAbsent || doctorAnswer != null) {
      map['doctor_answer'] = Variable<String>(doctorAnswer);
    }
    return map;
  }

  DoctorQuestionsCompanion toCompanion(bool nullToAbsent) {
    return DoctorQuestionsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      appointmentId: appointmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(appointmentId),
      questionText: Value(questionText),
      createdAt: Value(createdAt),
      isResolved: Value(isResolved),
      doctorAnswer: doctorAnswer == null && nullToAbsent
          ? const Value.absent()
          : Value(doctorAnswer),
    );
  }

  factory DoctorQuestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DoctorQuestionRow(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['member_id']),
      appointmentId: serializer.fromJson<String?>(json['appointment_id']),
      questionText: serializer.fromJson<String>(json['question_text']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      isResolved: serializer.fromJson<int>(json['is_resolved']),
      doctorAnswer: serializer.fromJson<String?>(json['doctor_answer']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'member_id': serializer.toJson<String>(memberId),
      'appointment_id': serializer.toJson<String?>(appointmentId),
      'question_text': serializer.toJson<String>(questionText),
      'created_at': serializer.toJson<int>(createdAt),
      'is_resolved': serializer.toJson<int>(isResolved),
      'doctor_answer': serializer.toJson<String?>(doctorAnswer),
    };
  }

  DoctorQuestionRow copyWith({
    String? id,
    String? memberId,
    Value<String?> appointmentId = const Value.absent(),
    String? questionText,
    int? createdAt,
    int? isResolved,
    Value<String?> doctorAnswer = const Value.absent(),
  }) => DoctorQuestionRow(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    appointmentId: appointmentId.present
        ? appointmentId.value
        : this.appointmentId,
    questionText: questionText ?? this.questionText,
    createdAt: createdAt ?? this.createdAt,
    isResolved: isResolved ?? this.isResolved,
    doctorAnswer: doctorAnswer.present ? doctorAnswer.value : this.doctorAnswer,
  );
  DoctorQuestionRow copyWithCompanion(DoctorQuestionsCompanion data) {
    return DoctorQuestionRow(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      appointmentId: data.appointmentId.present
          ? data.appointmentId.value
          : this.appointmentId,
      questionText: data.questionText.present
          ? data.questionText.value
          : this.questionText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isResolved: data.isResolved.present
          ? data.isResolved.value
          : this.isResolved,
      doctorAnswer: data.doctorAnswer.present
          ? data.doctorAnswer.value
          : this.doctorAnswer,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DoctorQuestionRow(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('questionText: $questionText, ')
          ..write('createdAt: $createdAt, ')
          ..write('isResolved: $isResolved, ')
          ..write('doctorAnswer: $doctorAnswer')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    appointmentId,
    questionText,
    createdAt,
    isResolved,
    doctorAnswer,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DoctorQuestionRow &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.appointmentId == this.appointmentId &&
          other.questionText == this.questionText &&
          other.createdAt == this.createdAt &&
          other.isResolved == this.isResolved &&
          other.doctorAnswer == this.doctorAnswer);
}

class DoctorQuestionsCompanion extends UpdateCompanion<DoctorQuestionRow> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String?> appointmentId;
  final Value<String> questionText;
  final Value<int> createdAt;
  final Value<int> isResolved;
  final Value<String?> doctorAnswer;
  final Value<int> rowid;
  const DoctorQuestionsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.appointmentId = const Value.absent(),
    this.questionText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isResolved = const Value.absent(),
    this.doctorAnswer = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DoctorQuestionsCompanion.insert({
    required String id,
    required String memberId,
    this.appointmentId = const Value.absent(),
    required String questionText,
    required int createdAt,
    this.isResolved = const Value.absent(),
    this.doctorAnswer = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       questionText = Value(questionText),
       createdAt = Value(createdAt);
  static Insertable<DoctorQuestionRow> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? appointmentId,
    Expression<String>? questionText,
    Expression<int>? createdAt,
    Expression<int>? isResolved,
    Expression<String>? doctorAnswer,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (questionText != null) 'question_text': questionText,
      if (createdAt != null) 'created_at': createdAt,
      if (isResolved != null) 'is_resolved': isResolved,
      if (doctorAnswer != null) 'doctor_answer': doctorAnswer,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DoctorQuestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String?>? appointmentId,
    Value<String>? questionText,
    Value<int>? createdAt,
    Value<int>? isResolved,
    Value<String?>? doctorAnswer,
    Value<int>? rowid,
  }) {
    return DoctorQuestionsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      appointmentId: appointmentId ?? this.appointmentId,
      questionText: questionText ?? this.questionText,
      createdAt: createdAt ?? this.createdAt,
      isResolved: isResolved ?? this.isResolved,
      doctorAnswer: doctorAnswer ?? this.doctorAnswer,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (appointmentId.present) {
      map['appointment_id'] = Variable<String>(appointmentId.value);
    }
    if (questionText.present) {
      map['question_text'] = Variable<String>(questionText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (isResolved.present) {
      map['is_resolved'] = Variable<int>(isResolved.value);
    }
    if (doctorAnswer.present) {
      map['doctor_answer'] = Variable<String>(doctorAnswer.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DoctorQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('questionText: $questionText, ')
          ..write('createdAt: $createdAt, ')
          ..write('isResolved: $isResolved, ')
          ..write('doctorAnswer: $doctorAnswer, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SymptomEntries extends Table
    with TableInfo<SymptomEntries, SymptomEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SymptomEntries(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) > 0)',
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES family_members(id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) > 0)',
  );
  static const VerificationMeta _nameKeyMeta = const VerificationMeta(
    'nameKey',
  );
  late final GeneratedColumn<String> nameKey = GeneratedColumn<String>(
    'name_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(name_key) > 0)',
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(started_at) = 26 AND started_at GLOB \'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9][0-9][0-9][0-9]\')',
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  late final GeneratedColumn<int> severity = GeneratedColumn<int>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (severity BETWEEN 1 AND 5)',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'ongoing\' CHECK (status IN (\'ongoing\', \'resolved\'))',
    defaultValue: const CustomExpression('\'ongoing\''),
  );
  static const VerificationMeta _durationMicrosMeta = const VerificationMeta(
    'durationMicros',
  );
  late final GeneratedColumn<int> durationMicros = GeneratedColumn<int>(
    'duration_micros',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (duration_micros IS NULL OR duration_micros >= 0)',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    name,
    nameKey,
    startedAt,
    severity,
    status,
    durationMicros,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'symptom_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SymptomEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_key')) {
      context.handle(
        _nameKeyMeta,
        nameKey.isAcceptableOrUnknown(data['name_key']!, _nameKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKeyMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('duration_micros')) {
      context.handle(
        _durationMicrosMeta,
        durationMicros.isAcceptableOrUnknown(
          data['duration_micros']!,
          _durationMicrosMeta,
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
  SymptomEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SymptomEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_key'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started_at'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}severity'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      durationMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_micros'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  SymptomEntries createAlias(String alias) {
    return SymptomEntries(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class SymptomEntryRow extends DataClass implements Insertable<SymptomEntryRow> {
  final String id;
  final String memberId;
  final String name;

  /// The name as compared for grouping (trimmed, single spaces, lower case).
  final String nameKey;
  final String startedAt;
  final int severity;
  final String status;
  final int? durationMicros;
  final String? notes;
  const SymptomEntryRow({
    required this.id,
    required this.memberId,
    required this.name,
    required this.nameKey,
    required this.startedAt,
    required this.severity,
    required this.status,
    this.durationMicros,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['name'] = Variable<String>(name);
    map['name_key'] = Variable<String>(nameKey);
    map['started_at'] = Variable<String>(startedAt);
    map['severity'] = Variable<int>(severity);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || durationMicros != null) {
      map['duration_micros'] = Variable<int>(durationMicros);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  SymptomEntriesCompanion toCompanion(bool nullToAbsent) {
    return SymptomEntriesCompanion(
      id: Value(id),
      memberId: Value(memberId),
      name: Value(name),
      nameKey: Value(nameKey),
      startedAt: Value(startedAt),
      severity: Value(severity),
      status: Value(status),
      durationMicros: durationMicros == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMicros),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory SymptomEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SymptomEntryRow(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['member_id']),
      name: serializer.fromJson<String>(json['name']),
      nameKey: serializer.fromJson<String>(json['name_key']),
      startedAt: serializer.fromJson<String>(json['started_at']),
      severity: serializer.fromJson<int>(json['severity']),
      status: serializer.fromJson<String>(json['status']),
      durationMicros: serializer.fromJson<int?>(json['duration_micros']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'member_id': serializer.toJson<String>(memberId),
      'name': serializer.toJson<String>(name),
      'name_key': serializer.toJson<String>(nameKey),
      'started_at': serializer.toJson<String>(startedAt),
      'severity': serializer.toJson<int>(severity),
      'status': serializer.toJson<String>(status),
      'duration_micros': serializer.toJson<int?>(durationMicros),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  SymptomEntryRow copyWith({
    String? id,
    String? memberId,
    String? name,
    String? nameKey,
    String? startedAt,
    int? severity,
    String? status,
    Value<int?> durationMicros = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => SymptomEntryRow(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    name: name ?? this.name,
    nameKey: nameKey ?? this.nameKey,
    startedAt: startedAt ?? this.startedAt,
    severity: severity ?? this.severity,
    status: status ?? this.status,
    durationMicros: durationMicros.present
        ? durationMicros.value
        : this.durationMicros,
    notes: notes.present ? notes.value : this.notes,
  );
  SymptomEntryRow copyWithCompanion(SymptomEntriesCompanion data) {
    return SymptomEntryRow(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      name: data.name.present ? data.name.value : this.name,
      nameKey: data.nameKey.present ? data.nameKey.value : this.nameKey,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      severity: data.severity.present ? data.severity.value : this.severity,
      status: data.status.present ? data.status.value : this.status,
      durationMicros: data.durationMicros.present
          ? data.durationMicros.value
          : this.durationMicros,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SymptomEntryRow(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('nameKey: $nameKey, ')
          ..write('startedAt: $startedAt, ')
          ..write('severity: $severity, ')
          ..write('status: $status, ')
          ..write('durationMicros: $durationMicros, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    name,
    nameKey,
    startedAt,
    severity,
    status,
    durationMicros,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymptomEntryRow &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.name == this.name &&
          other.nameKey == this.nameKey &&
          other.startedAt == this.startedAt &&
          other.severity == this.severity &&
          other.status == this.status &&
          other.durationMicros == this.durationMicros &&
          other.notes == this.notes);
}

class SymptomEntriesCompanion extends UpdateCompanion<SymptomEntryRow> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> name;
  final Value<String> nameKey;
  final Value<String> startedAt;
  final Value<int> severity;
  final Value<String> status;
  final Value<int?> durationMicros;
  final Value<String?> notes;
  final Value<int> rowid;
  const SymptomEntriesCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.name = const Value.absent(),
    this.nameKey = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.severity = const Value.absent(),
    this.status = const Value.absent(),
    this.durationMicros = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SymptomEntriesCompanion.insert({
    required String id,
    required String memberId,
    required String name,
    required String nameKey,
    required String startedAt,
    required int severity,
    this.status = const Value.absent(),
    this.durationMicros = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       name = Value(name),
       nameKey = Value(nameKey),
       startedAt = Value(startedAt),
       severity = Value(severity);
  static Insertable<SymptomEntryRow> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? name,
    Expression<String>? nameKey,
    Expression<String>? startedAt,
    Expression<int>? severity,
    Expression<String>? status,
    Expression<int>? durationMicros,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (name != null) 'name': name,
      if (nameKey != null) 'name_key': nameKey,
      if (startedAt != null) 'started_at': startedAt,
      if (severity != null) 'severity': severity,
      if (status != null) 'status': status,
      if (durationMicros != null) 'duration_micros': durationMicros,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SymptomEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? name,
    Value<String>? nameKey,
    Value<String>? startedAt,
    Value<int>? severity,
    Value<String>? status,
    Value<int?>? durationMicros,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return SymptomEntriesCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      nameKey: nameKey ?? this.nameKey,
      startedAt: startedAt ?? this.startedAt,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      durationMicros: durationMicros ?? this.durationMicros,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameKey.present) {
      map['name_key'] = Variable<String>(nameKey.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (severity.present) {
      map['severity'] = Variable<int>(severity.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (durationMicros.present) {
      map['duration_micros'] = Variable<int>(durationMicros.value);
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
    return (StringBuffer('SymptomEntriesCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('nameKey: $nameKey, ')
          ..write('startedAt: $startedAt, ')
          ..write('severity: $severity, ')
          ..write('status: $status, ')
          ..write('durationMicros: $durationMicros, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class VisitMedia extends Table with TableInfo<VisitMedia, VisitMediaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  VisitMedia(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) > 0)',
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES family_members(id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _appointmentIdMeta = const VerificationMeta(
    'appointmentId',
  );
  late final GeneratedColumn<String> appointmentId = GeneratedColumn<String>(
    'appointment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'photo\', \'video\'))',
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL UNIQUE CHECK (length(file_name) > 0 AND file_name NOT GLOB \'*[/\\]*\' AND file_name NOT GLOB \'.*\')',
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (byte_size > 0)',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    appointmentId,
    kind,
    fileName,
    byteSize,
    description,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visit_media';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitMediaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('appointment_id')) {
      context.handle(
        _appointmentIdMeta,
        appointmentId.isAcceptableOrUnknown(
          data['appointment_id']!,
          _appointmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appointmentIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
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
  VisitMediaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitMediaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      appointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  VisitMedia createAlias(String alias) {
    return VisitMedia(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY(appointment_id, member_id)REFERENCES appointments(id, member_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class VisitMediaRow extends DataClass implements Insertable<VisitMediaRow> {
  final String id;
  final String memberId;
  final String appointmentId;
  final String kind;

  /// A bare file name inside the private media directory, never a path.
  final String fileName;
  final int byteSize;
  final String? description;
  final int createdAt;
  const VisitMediaRow({
    required this.id,
    required this.memberId,
    required this.appointmentId,
    required this.kind,
    required this.fileName,
    required this.byteSize,
    this.description,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['appointment_id'] = Variable<String>(appointmentId);
    map['kind'] = Variable<String>(kind);
    map['file_name'] = Variable<String>(fileName);
    map['byte_size'] = Variable<int>(byteSize);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  VisitMediaCompanion toCompanion(bool nullToAbsent) {
    return VisitMediaCompanion(
      id: Value(id),
      memberId: Value(memberId),
      appointmentId: Value(appointmentId),
      kind: Value(kind),
      fileName: Value(fileName),
      byteSize: Value(byteSize),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory VisitMediaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitMediaRow(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['member_id']),
      appointmentId: serializer.fromJson<String>(json['appointment_id']),
      kind: serializer.fromJson<String>(json['kind']),
      fileName: serializer.fromJson<String>(json['file_name']),
      byteSize: serializer.fromJson<int>(json['byte_size']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<int>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'member_id': serializer.toJson<String>(memberId),
      'appointment_id': serializer.toJson<String>(appointmentId),
      'kind': serializer.toJson<String>(kind),
      'file_name': serializer.toJson<String>(fileName),
      'byte_size': serializer.toJson<int>(byteSize),
      'description': serializer.toJson<String?>(description),
      'created_at': serializer.toJson<int>(createdAt),
    };
  }

  VisitMediaRow copyWith({
    String? id,
    String? memberId,
    String? appointmentId,
    String? kind,
    String? fileName,
    int? byteSize,
    Value<String?> description = const Value.absent(),
    int? createdAt,
  }) => VisitMediaRow(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    appointmentId: appointmentId ?? this.appointmentId,
    kind: kind ?? this.kind,
    fileName: fileName ?? this.fileName,
    byteSize: byteSize ?? this.byteSize,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
  );
  VisitMediaRow copyWithCompanion(VisitMediaCompanion data) {
    return VisitMediaRow(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      appointmentId: data.appointmentId.present
          ? data.appointmentId.value
          : this.appointmentId,
      kind: data.kind.present ? data.kind.value : this.kind,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitMediaRow(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('kind: $kind, ')
          ..write('fileName: $fileName, ')
          ..write('byteSize: $byteSize, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    appointmentId,
    kind,
    fileName,
    byteSize,
    description,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitMediaRow &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.appointmentId == this.appointmentId &&
          other.kind == this.kind &&
          other.fileName == this.fileName &&
          other.byteSize == this.byteSize &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class VisitMediaCompanion extends UpdateCompanion<VisitMediaRow> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> appointmentId;
  final Value<String> kind;
  final Value<String> fileName;
  final Value<int> byteSize;
  final Value<String?> description;
  final Value<int> createdAt;
  final Value<int> rowid;
  const VisitMediaCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.appointmentId = const Value.absent(),
    this.kind = const Value.absent(),
    this.fileName = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitMediaCompanion.insert({
    required String id,
    required String memberId,
    required String appointmentId,
    required String kind,
    required String fileName,
    required int byteSize,
    this.description = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       appointmentId = Value(appointmentId),
       kind = Value(kind),
       fileName = Value(fileName),
       byteSize = Value(byteSize),
       createdAt = Value(createdAt);
  static Insertable<VisitMediaRow> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? appointmentId,
    Expression<String>? kind,
    Expression<String>? fileName,
    Expression<int>? byteSize,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (kind != null) 'kind': kind,
      if (fileName != null) 'file_name': fileName,
      if (byteSize != null) 'byte_size': byteSize,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitMediaCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? appointmentId,
    Value<String>? kind,
    Value<String>? fileName,
    Value<int>? byteSize,
    Value<String?>? description,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return VisitMediaCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      appointmentId: appointmentId ?? this.appointmentId,
      kind: kind ?? this.kind,
      fileName: fileName ?? this.fileName,
      byteSize: byteSize ?? this.byteSize,
      description: description ?? this.description,
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
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (appointmentId.present) {
      map['appointment_id'] = Variable<String>(appointmentId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitMediaCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('kind: $kind, ')
          ..write('fileName: $fileName, ')
          ..write('byteSize: $byteSize, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Medications extends Table with TableInfo<Medications, MedicationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Medications(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) > 0)',
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES family_members(id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) > 0)',
  );
  static const VerificationMeta _doseMeta = const VerificationMeta('dose');
  late final GeneratedColumn<String> dose = GeneratedColumn<String>(
    'dose',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(dose)) > 0)',
  );
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _reminderTimesMeta = const VerificationMeta(
    'reminderTimes',
  );
  late final GeneratedColumn<String> reminderTimes = GeneratedColumn<String>(
    'reminder_times',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (json_valid(reminder_times) AND json_type(reminder_times) = \'array\' AND json_array_length(reminder_times) > 0)',
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(start_date) = 10 AND start_date GLOB \'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\')',
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (end_date IS NULL OR(length(end_date) = 10 AND end_date GLOB \'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\' AND end_date >= start_date))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    name,
    dose,
    instructions,
    reminderTimes,
    startDate,
    endDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dose')) {
      context.handle(
        _doseMeta,
        dose.isAcceptableOrUnknown(data['dose']!, _doseMeta),
      );
    } else if (isInserting) {
      context.missing(_doseMeta);
    }
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('reminder_times')) {
      context.handle(
        _reminderTimesMeta,
        reminderTimes.isAcceptableOrUnknown(
          data['reminder_times']!,
          _reminderTimesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderTimesMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {id, memberId},
  ];
  @override
  MedicationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      dose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose'],
      )!,
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      ),
      reminderTimes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_times'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
    );
  }

  @override
  Medications createAlias(String alias) {
    return Medications(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const ['UNIQUE(id, member_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class MedicationRow extends DataClass implements Insertable<MedicationRow> {
  final String id;
  final String memberId;
  final String name;
  final String dose;
  final String? instructions;

  /// Daily reminder times: a JSON array of 'HH:MM' strings, at least one.
  final String reminderTimes;
  final String startDate;

  /// Inclusive; null when the treatment has no planned end.
  final String? endDate;
  const MedicationRow({
    required this.id,
    required this.memberId,
    required this.name,
    required this.dose,
    this.instructions,
    required this.reminderTimes,
    required this.startDate,
    this.endDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['name'] = Variable<String>(name);
    map['dose'] = Variable<String>(dose);
    if (!nullToAbsent || instructions != null) {
      map['instructions'] = Variable<String>(instructions);
    }
    map['reminder_times'] = Variable<String>(reminderTimes);
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      name: Value(name),
      dose: Value(dose),
      instructions: instructions == null && nullToAbsent
          ? const Value.absent()
          : Value(instructions),
      reminderTimes: Value(reminderTimes),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
    );
  }

  factory MedicationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationRow(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['member_id']),
      name: serializer.fromJson<String>(json['name']),
      dose: serializer.fromJson<String>(json['dose']),
      instructions: serializer.fromJson<String?>(json['instructions']),
      reminderTimes: serializer.fromJson<String>(json['reminder_times']),
      startDate: serializer.fromJson<String>(json['start_date']),
      endDate: serializer.fromJson<String?>(json['end_date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'member_id': serializer.toJson<String>(memberId),
      'name': serializer.toJson<String>(name),
      'dose': serializer.toJson<String>(dose),
      'instructions': serializer.toJson<String?>(instructions),
      'reminder_times': serializer.toJson<String>(reminderTimes),
      'start_date': serializer.toJson<String>(startDate),
      'end_date': serializer.toJson<String?>(endDate),
    };
  }

  MedicationRow copyWith({
    String? id,
    String? memberId,
    String? name,
    String? dose,
    Value<String?> instructions = const Value.absent(),
    String? reminderTimes,
    String? startDate,
    Value<String?> endDate = const Value.absent(),
  }) => MedicationRow(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    name: name ?? this.name,
    dose: dose ?? this.dose,
    instructions: instructions.present ? instructions.value : this.instructions,
    reminderTimes: reminderTimes ?? this.reminderTimes,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
  );
  MedicationRow copyWithCompanion(MedicationsCompanion data) {
    return MedicationRow(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      name: data.name.present ? data.name.value : this.name,
      dose: data.dose.present ? data.dose.value : this.dose,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      reminderTimes: data.reminderTimes.present
          ? data.reminderTimes.value
          : this.reminderTimes,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationRow(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('dose: $dose, ')
          ..write('instructions: $instructions, ')
          ..write('reminderTimes: $reminderTimes, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    name,
    dose,
    instructions,
    reminderTimes,
    startDate,
    endDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationRow &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.name == this.name &&
          other.dose == this.dose &&
          other.instructions == this.instructions &&
          other.reminderTimes == this.reminderTimes &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate);
}

class MedicationsCompanion extends UpdateCompanion<MedicationRow> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> name;
  final Value<String> dose;
  final Value<String?> instructions;
  final Value<String> reminderTimes;
  final Value<String> startDate;
  final Value<String?> endDate;
  final Value<int> rowid;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.name = const Value.absent(),
    this.dose = const Value.absent(),
    this.instructions = const Value.absent(),
    this.reminderTimes = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationsCompanion.insert({
    required String id,
    required String memberId,
    required String name,
    required String dose,
    this.instructions = const Value.absent(),
    required String reminderTimes,
    required String startDate,
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       name = Value(name),
       dose = Value(dose),
       reminderTimes = Value(reminderTimes),
       startDate = Value(startDate);
  static Insertable<MedicationRow> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? name,
    Expression<String>? dose,
    Expression<String>? instructions,
    Expression<String>? reminderTimes,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (name != null) 'name': name,
      if (dose != null) 'dose': dose,
      if (instructions != null) 'instructions': instructions,
      if (reminderTimes != null) 'reminder_times': reminderTimes,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? name,
    Value<String>? dose,
    Value<String?>? instructions,
    Value<String>? reminderTimes,
    Value<String>? startDate,
    Value<String?>? endDate,
    Value<int>? rowid,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      instructions: instructions ?? this.instructions,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dose.present) {
      map['dose'] = Variable<String>(dose.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (reminderTimes.present) {
      map['reminder_times'] = Variable<String>(reminderTimes.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('dose: $dose, ')
          ..write('instructions: $instructions, ')
          ..write('reminderTimes: $reminderTimes, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DoseRecords extends Table with TableInfo<DoseRecords, DoseRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DoseRecords(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) > 0)',
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES family_members(id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  late final GeneratedColumn<String> scheduledAt = GeneratedColumn<String>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(scheduled_at) = 26 AND scheduled_at GLOB \'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:00.000000\')',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (status IN (\'taken\', \'skipped\'))',
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  late final GeneratedColumn<int> recordedAt = GeneratedColumn<int>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    medicationId,
    scheduledAt,
    status,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dose_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<DoseRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {medicationId, scheduledAt},
  ];
  @override
  DoseRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DoseRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  DoseRecords createAlias(String alias) {
    return DoseRecords(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'UNIQUE(medication_id, scheduled_at)',
    'FOREIGN KEY(medication_id, member_id)REFERENCES medications(id, member_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class DoseRecordRow extends DataClass implements Insertable<DoseRecordRow> {
  final String id;
  final String memberId;
  final String medicationId;

  /// The scheduled dose's local date and time, to the minute.
  final String scheduledAt;
  final String status;
  final int recordedAt;
  const DoseRecordRow({
    required this.id,
    required this.memberId,
    required this.medicationId,
    required this.scheduledAt,
    required this.status,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['medication_id'] = Variable<String>(medicationId);
    map['scheduled_at'] = Variable<String>(scheduledAt);
    map['status'] = Variable<String>(status);
    map['recorded_at'] = Variable<int>(recordedAt);
    return map;
  }

  DoseRecordsCompanion toCompanion(bool nullToAbsent) {
    return DoseRecordsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      medicationId: Value(medicationId),
      scheduledAt: Value(scheduledAt),
      status: Value(status),
      recordedAt: Value(recordedAt),
    );
  }

  factory DoseRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DoseRecordRow(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['member_id']),
      medicationId: serializer.fromJson<String>(json['medication_id']),
      scheduledAt: serializer.fromJson<String>(json['scheduled_at']),
      status: serializer.fromJson<String>(json['status']),
      recordedAt: serializer.fromJson<int>(json['recorded_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'member_id': serializer.toJson<String>(memberId),
      'medication_id': serializer.toJson<String>(medicationId),
      'scheduled_at': serializer.toJson<String>(scheduledAt),
      'status': serializer.toJson<String>(status),
      'recorded_at': serializer.toJson<int>(recordedAt),
    };
  }

  DoseRecordRow copyWith({
    String? id,
    String? memberId,
    String? medicationId,
    String? scheduledAt,
    String? status,
    int? recordedAt,
  }) => DoseRecordRow(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    medicationId: medicationId ?? this.medicationId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    status: status ?? this.status,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  DoseRecordRow copyWithCompanion(DoseRecordsCompanion data) {
    return DoseRecordRow(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      status: data.status.present ? data.status.value : this.status,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DoseRecordRow(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('status: $status, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, memberId, medicationId, scheduledAt, status, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DoseRecordRow &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.medicationId == this.medicationId &&
          other.scheduledAt == this.scheduledAt &&
          other.status == this.status &&
          other.recordedAt == this.recordedAt);
}

class DoseRecordsCompanion extends UpdateCompanion<DoseRecordRow> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> medicationId;
  final Value<String> scheduledAt;
  final Value<String> status;
  final Value<int> recordedAt;
  final Value<int> rowid;
  const DoseRecordsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.status = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DoseRecordsCompanion.insert({
    required String id,
    required String memberId,
    required String medicationId,
    required String scheduledAt,
    required String status,
    required int recordedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       medicationId = Value(medicationId),
       scheduledAt = Value(scheduledAt),
       status = Value(status),
       recordedAt = Value(recordedAt);
  static Insertable<DoseRecordRow> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? medicationId,
    Expression<String>? scheduledAt,
    Expression<String>? status,
    Expression<int>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (medicationId != null) 'medication_id': medicationId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (status != null) 'status': status,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DoseRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? medicationId,
    Value<String>? scheduledAt,
    Value<String>? status,
    Value<int>? recordedAt,
    Value<int>? rowid,
  }) {
    return DoseRecordsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      medicationId: medicationId ?? this.medicationId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<String>(scheduledAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<int>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DoseRecordsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('status: $status, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncSettings extends Table with TableInfo<SyncSettings, SyncSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncSettings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (id = 1)',
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(device_id) > 0)',
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (household_id IS NULL OR length(household_id) > 0)',
  );
  static const VerificationMeta _accountUidMeta = const VerificationMeta(
    'accountUid',
  );
  late final GeneratedColumn<String> accountUid = GeneratedColumn<String>(
    'account_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (account_uid IS NULL OR length(account_uid) > 0)',
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (role IS NULL OR role IN (\'admin\', \'member\'))',
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'off\' CHECK (state IN (\'off\', \'joining\', \'active\', \'removed\'))',
    defaultValue: const CustomExpression('\'off\''),
  );
  static const VerificationMeta _inviteIdMeta = const VerificationMeta(
    'inviteId',
  );
  late final GeneratedColumn<String> inviteId = GeneratedColumn<String>(
    'invite_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  late final GeneratedColumn<int> lastSyncAt = GeneratedColumn<int>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _nextSeqMeta = const VerificationMeta(
    'nextSeq',
  );
  late final GeneratedColumn<int> nextSeq = GeneratedColumn<int>(
    'next_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (next_seq >= 1)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _applyingMeta = const VerificationMeta(
    'applying',
  );
  late final GeneratedColumn<int> applying = GeneratedColumn<int>(
    'applying',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (applying IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceId,
    householdId,
    accountUid,
    role,
    state,
    inviteId,
    lastSyncAt,
    nextSeq,
    applying,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    }
    if (data.containsKey('account_uid')) {
      context.handle(
        _accountUidMeta,
        accountUid.isAcceptableOrUnknown(data['account_uid']!, _accountUidMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('invite_id')) {
      context.handle(
        _inviteIdMeta,
        inviteId.isAcceptableOrUnknown(data['invite_id']!, _inviteIdMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('next_seq')) {
      context.handle(
        _nextSeqMeta,
        nextSeq.isAcceptableOrUnknown(data['next_seq']!, _nextSeqMeta),
      );
    }
    if (data.containsKey('applying')) {
      context.handle(
        _applyingMeta,
        applying.isAcceptableOrUnknown(data['applying']!, _applyingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      ),
      accountUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_uid'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      inviteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invite_id'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sync_at'],
      ),
      nextSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_seq'],
      )!,
      applying: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applying'],
      )!,
    );
  }

  @override
  SyncSettings createAlias(String alias) {
    return SyncSettings(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class SyncSettingsRow extends DataClass implements Insertable<SyncSettingsRow> {
  final int id;

  /// Random, created on first use; names this device's change log.
  final String deviceId;
  final String? householdId;
  final String? accountUid;
  final String? role;
  final String state;

  /// The invitation this device accepted, while it waits to be added.
  final String? inviteId;
  final int? lastSyncAt;

  /// Sequence number of the next change batch this device uploads.
  final int nextSeq;

  /// 1 only inside the transaction that applies changes from other devices,
  /// so those changes are not tracked as local ones.
  final int applying;
  const SyncSettingsRow({
    required this.id,
    required this.deviceId,
    this.householdId,
    this.accountUid,
    this.role,
    required this.state,
    this.inviteId,
    this.lastSyncAt,
    required this.nextSeq,
    required this.applying,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    if (!nullToAbsent || accountUid != null) {
      map['account_uid'] = Variable<String>(accountUid);
    }
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || inviteId != null) {
      map['invite_id'] = Variable<String>(inviteId);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<int>(lastSyncAt);
    }
    map['next_seq'] = Variable<int>(nextSeq);
    map['applying'] = Variable<int>(applying);
    return map;
  }

  SyncSettingsCompanion toCompanion(bool nullToAbsent) {
    return SyncSettingsCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      accountUid: accountUid == null && nullToAbsent
          ? const Value.absent()
          : Value(accountUid),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      state: Value(state),
      inviteId: inviteId == null && nullToAbsent
          ? const Value.absent()
          : Value(inviteId),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      nextSeq: Value(nextSeq),
      applying: Value(applying),
    );
  }

  factory SyncSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['device_id']),
      householdId: serializer.fromJson<String?>(json['household_id']),
      accountUid: serializer.fromJson<String?>(json['account_uid']),
      role: serializer.fromJson<String?>(json['role']),
      state: serializer.fromJson<String>(json['state']),
      inviteId: serializer.fromJson<String?>(json['invite_id']),
      lastSyncAt: serializer.fromJson<int?>(json['last_sync_at']),
      nextSeq: serializer.fromJson<int>(json['next_seq']),
      applying: serializer.fromJson<int>(json['applying']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'device_id': serializer.toJson<String>(deviceId),
      'household_id': serializer.toJson<String?>(householdId),
      'account_uid': serializer.toJson<String?>(accountUid),
      'role': serializer.toJson<String?>(role),
      'state': serializer.toJson<String>(state),
      'invite_id': serializer.toJson<String?>(inviteId),
      'last_sync_at': serializer.toJson<int?>(lastSyncAt),
      'next_seq': serializer.toJson<int>(nextSeq),
      'applying': serializer.toJson<int>(applying),
    };
  }

  SyncSettingsRow copyWith({
    int? id,
    String? deviceId,
    Value<String?> householdId = const Value.absent(),
    Value<String?> accountUid = const Value.absent(),
    Value<String?> role = const Value.absent(),
    String? state,
    Value<String?> inviteId = const Value.absent(),
    Value<int?> lastSyncAt = const Value.absent(),
    int? nextSeq,
    int? applying,
  }) => SyncSettingsRow(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    householdId: householdId.present ? householdId.value : this.householdId,
    accountUid: accountUid.present ? accountUid.value : this.accountUid,
    role: role.present ? role.value : this.role,
    state: state ?? this.state,
    inviteId: inviteId.present ? inviteId.value : this.inviteId,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    nextSeq: nextSeq ?? this.nextSeq,
    applying: applying ?? this.applying,
  );
  SyncSettingsRow copyWithCompanion(SyncSettingsCompanion data) {
    return SyncSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      accountUid: data.accountUid.present
          ? data.accountUid.value
          : this.accountUid,
      role: data.role.present ? data.role.value : this.role,
      state: data.state.present ? data.state.value : this.state,
      inviteId: data.inviteId.present ? data.inviteId.value : this.inviteId,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      nextSeq: data.nextSeq.present ? data.nextSeq.value : this.nextSeq,
      applying: data.applying.present ? data.applying.value : this.applying,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncSettingsRow(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('householdId: $householdId, ')
          ..write('accountUid: $accountUid, ')
          ..write('role: $role, ')
          ..write('state: $state, ')
          ..write('inviteId: $inviteId, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('nextSeq: $nextSeq, ')
          ..write('applying: $applying')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deviceId,
    householdId,
    accountUid,
    role,
    state,
    inviteId,
    lastSyncAt,
    nextSeq,
    applying,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncSettingsRow &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.householdId == this.householdId &&
          other.accountUid == this.accountUid &&
          other.role == this.role &&
          other.state == this.state &&
          other.inviteId == this.inviteId &&
          other.lastSyncAt == this.lastSyncAt &&
          other.nextSeq == this.nextSeq &&
          other.applying == this.applying);
}

class SyncSettingsCompanion extends UpdateCompanion<SyncSettingsRow> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String?> householdId;
  final Value<String?> accountUid;
  final Value<String?> role;
  final Value<String> state;
  final Value<String?> inviteId;
  final Value<int?> lastSyncAt;
  final Value<int> nextSeq;
  final Value<int> applying;
  const SyncSettingsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.accountUid = const Value.absent(),
    this.role = const Value.absent(),
    this.state = const Value.absent(),
    this.inviteId = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.nextSeq = const Value.absent(),
    this.applying = const Value.absent(),
  });
  SyncSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    this.householdId = const Value.absent(),
    this.accountUid = const Value.absent(),
    this.role = const Value.absent(),
    this.state = const Value.absent(),
    this.inviteId = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.nextSeq = const Value.absent(),
    this.applying = const Value.absent(),
  }) : deviceId = Value(deviceId);
  static Insertable<SyncSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? householdId,
    Expression<String>? accountUid,
    Expression<String>? role,
    Expression<String>? state,
    Expression<String>? inviteId,
    Expression<int>? lastSyncAt,
    Expression<int>? nextSeq,
    Expression<int>? applying,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (householdId != null) 'household_id': householdId,
      if (accountUid != null) 'account_uid': accountUid,
      if (role != null) 'role': role,
      if (state != null) 'state': state,
      if (inviteId != null) 'invite_id': inviteId,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (nextSeq != null) 'next_seq': nextSeq,
      if (applying != null) 'applying': applying,
    });
  }

  SyncSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? deviceId,
    Value<String?>? householdId,
    Value<String?>? accountUid,
    Value<String?>? role,
    Value<String>? state,
    Value<String?>? inviteId,
    Value<int?>? lastSyncAt,
    Value<int>? nextSeq,
    Value<int>? applying,
  }) {
    return SyncSettingsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      householdId: householdId ?? this.householdId,
      accountUid: accountUid ?? this.accountUid,
      role: role ?? this.role,
      state: state ?? this.state,
      inviteId: inviteId ?? this.inviteId,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      nextSeq: nextSeq ?? this.nextSeq,
      applying: applying ?? this.applying,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (accountUid.present) {
      map['account_uid'] = Variable<String>(accountUid.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (inviteId.present) {
      map['invite_id'] = Variable<String>(inviteId.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<int>(lastSyncAt.value);
    }
    if (nextSeq.present) {
      map['next_seq'] = Variable<int>(nextSeq.value);
    }
    if (applying.present) {
      map['applying'] = Variable<int>(applying.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncSettingsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('householdId: $householdId, ')
          ..write('accountUid: $accountUid, ')
          ..write('role: $role, ')
          ..write('state: $state, ')
          ..write('inviteId: $inviteId, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('nextSeq: $nextSeq, ')
          ..write('applying: $applying')
          ..write(')'))
        .toString();
  }
}

class SyncSharedMembers extends Table
    with TableInfo<SyncSharedMembers, SyncSharedMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncSharedMembers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY REFERENCES family_members(id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _sharedAtMeta = const VerificationMeta(
    'sharedAt',
  );
  late final GeneratedColumn<int> sharedAt = GeneratedColumn<int>(
    'shared_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [memberId, sharedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_shared_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncSharedMemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('shared_at')) {
      context.handle(
        _sharedAtMeta,
        sharedAt.isAcceptableOrUnknown(data['shared_at']!, _sharedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sharedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memberId};
  @override
  SyncSharedMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncSharedMemberRow(
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      sharedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shared_at'],
      )!,
    );
  }

  @override
  SyncSharedMembers createAlias(String alias) {
    return SyncSharedMembers(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class SyncSharedMemberRow extends DataClass
    implements Insertable<SyncSharedMemberRow> {
  final String memberId;
  final int sharedAt;
  const SyncSharedMemberRow({required this.memberId, required this.sharedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['member_id'] = Variable<String>(memberId);
    map['shared_at'] = Variable<int>(sharedAt);
    return map;
  }

  SyncSharedMembersCompanion toCompanion(bool nullToAbsent) {
    return SyncSharedMembersCompanion(
      memberId: Value(memberId),
      sharedAt: Value(sharedAt),
    );
  }

  factory SyncSharedMemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncSharedMemberRow(
      memberId: serializer.fromJson<String>(json['member_id']),
      sharedAt: serializer.fromJson<int>(json['shared_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'member_id': serializer.toJson<String>(memberId),
      'shared_at': serializer.toJson<int>(sharedAt),
    };
  }

  SyncSharedMemberRow copyWith({String? memberId, int? sharedAt}) =>
      SyncSharedMemberRow(
        memberId: memberId ?? this.memberId,
        sharedAt: sharedAt ?? this.sharedAt,
      );
  SyncSharedMemberRow copyWithCompanion(SyncSharedMembersCompanion data) {
    return SyncSharedMemberRow(
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      sharedAt: data.sharedAt.present ? data.sharedAt.value : this.sharedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncSharedMemberRow(')
          ..write('memberId: $memberId, ')
          ..write('sharedAt: $sharedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(memberId, sharedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncSharedMemberRow &&
          other.memberId == this.memberId &&
          other.sharedAt == this.sharedAt);
}

class SyncSharedMembersCompanion extends UpdateCompanion<SyncSharedMemberRow> {
  final Value<String> memberId;
  final Value<int> sharedAt;
  final Value<int> rowid;
  const SyncSharedMembersCompanion({
    this.memberId = const Value.absent(),
    this.sharedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncSharedMembersCompanion.insert({
    required String memberId,
    required int sharedAt,
    this.rowid = const Value.absent(),
  }) : memberId = Value(memberId),
       sharedAt = Value(sharedAt);
  static Insertable<SyncSharedMemberRow> custom({
    Expression<String>? memberId,
    Expression<int>? sharedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memberId != null) 'member_id': memberId,
      if (sharedAt != null) 'shared_at': sharedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncSharedMembersCompanion copyWith({
    Value<String>? memberId,
    Value<int>? sharedAt,
    Value<int>? rowid,
  }) {
    return SyncSharedMembersCompanion(
      memberId: memberId ?? this.memberId,
      sharedAt: sharedAt ?? this.sharedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (sharedAt.present) {
      map['shared_at'] = Variable<int>(sharedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncSharedMembersCompanion(')
          ..write('memberId: $memberId, ')
          ..write('sharedAt: $sharedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncRecords extends Table with TableInfo<SyncRecords, SyncRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncRecords(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (kind IN (\'member\', \'appointment\', \'question\', \'symptom\', \'media\', \'medication\', \'dose\', \'share\'))',
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(sync_id) > 0)',
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(local_id) > 0)',
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(member_id) > 0)',
  );
  static const VerificationMeta _versionVectorMeta = const VerificationMeta(
    'versionVector',
  );
  late final GeneratedColumn<String> versionVector = GeneratedColumn<String>(
    'version_vector',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (json_valid(version_vector) AND json_type(version_vector) = \'object\')',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(updated_by) > 0)',
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  late final GeneratedColumn<int> deleted = GeneratedColumn<int>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (deleted IN (0, 1))',
  );
  static const VerificationMeta _baseMeta = const VerificationMeta('base');
  late final GeneratedColumn<String> base = GeneratedColumn<String>(
    'base',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (base IS NULL OR(json_valid(base) AND json_type(base) = \'object\'))',
  );
  static const VerificationMeta _parkedMeta = const VerificationMeta('parked');
  late final GeneratedColumn<int> parked = GeneratedColumn<int>(
    'parked',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (parked IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    kind,
    syncId,
    localId,
    memberId,
    versionVector,
    updatedAt,
    updatedBy,
    deleted,
    base,
    parked,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    } else if (isInserting) {
      context.missing(_syncIdMeta);
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('version_vector')) {
      context.handle(
        _versionVectorMeta,
        versionVector.isAcceptableOrUnknown(
          data['version_vector']!,
          _versionVectorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionVectorMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedMeta);
    }
    if (data.containsKey('base')) {
      context.handle(
        _baseMeta,
        base.isAcceptableOrUnknown(data['base']!, _baseMeta),
      );
    }
    if (data.containsKey('parked')) {
      context.handle(
        _parkedMeta,
        parked.isAcceptableOrUnknown(data['parked']!, _parkedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, syncId};
  @override
  SyncRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncRecordRow(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      versionVector: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_vector'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted'],
      )!,
      base: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base'],
      ),
      parked: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parked'],
      )!,
    );
  }

  @override
  SyncRecords createAlias(String alias) {
    return SyncRecords(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(kind, sync_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class SyncRecordRow extends DataClass implements Insertable<SyncRecordRow> {
  final String kind;
  final String syncId;
  final String localId;
  final String memberId;
  final String versionVector;
  final int updatedAt;
  final String updatedBy;
  final int deleted;
  final String? base;

  /// 1 while a change from another device waits for its parent record
  /// (e.g. a question whose appointment has not arrived yet).
  final int parked;
  const SyncRecordRow({
    required this.kind,
    required this.syncId,
    required this.localId,
    required this.memberId,
    required this.versionVector,
    required this.updatedAt,
    required this.updatedBy,
    required this.deleted,
    this.base,
    required this.parked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['sync_id'] = Variable<String>(syncId);
    map['local_id'] = Variable<String>(localId);
    map['member_id'] = Variable<String>(memberId);
    map['version_vector'] = Variable<String>(versionVector);
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    map['deleted'] = Variable<int>(deleted);
    if (!nullToAbsent || base != null) {
      map['base'] = Variable<String>(base);
    }
    map['parked'] = Variable<int>(parked);
    return map;
  }

  SyncRecordsCompanion toCompanion(bool nullToAbsent) {
    return SyncRecordsCompanion(
      kind: Value(kind),
      syncId: Value(syncId),
      localId: Value(localId),
      memberId: Value(memberId),
      versionVector: Value(versionVector),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deleted: Value(deleted),
      base: base == null && nullToAbsent ? const Value.absent() : Value(base),
      parked: Value(parked),
    );
  }

  factory SyncRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncRecordRow(
      kind: serializer.fromJson<String>(json['kind']),
      syncId: serializer.fromJson<String>(json['sync_id']),
      localId: serializer.fromJson<String>(json['local_id']),
      memberId: serializer.fromJson<String>(json['member_id']),
      versionVector: serializer.fromJson<String>(json['version_vector']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      updatedBy: serializer.fromJson<String>(json['updated_by']),
      deleted: serializer.fromJson<int>(json['deleted']),
      base: serializer.fromJson<String?>(json['base']),
      parked: serializer.fromJson<int>(json['parked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'sync_id': serializer.toJson<String>(syncId),
      'local_id': serializer.toJson<String>(localId),
      'member_id': serializer.toJson<String>(memberId),
      'version_vector': serializer.toJson<String>(versionVector),
      'updated_at': serializer.toJson<int>(updatedAt),
      'updated_by': serializer.toJson<String>(updatedBy),
      'deleted': serializer.toJson<int>(deleted),
      'base': serializer.toJson<String?>(base),
      'parked': serializer.toJson<int>(parked),
    };
  }

  SyncRecordRow copyWith({
    String? kind,
    String? syncId,
    String? localId,
    String? memberId,
    String? versionVector,
    int? updatedAt,
    String? updatedBy,
    int? deleted,
    Value<String?> base = const Value.absent(),
    int? parked,
  }) => SyncRecordRow(
    kind: kind ?? this.kind,
    syncId: syncId ?? this.syncId,
    localId: localId ?? this.localId,
    memberId: memberId ?? this.memberId,
    versionVector: versionVector ?? this.versionVector,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deleted: deleted ?? this.deleted,
    base: base.present ? base.value : this.base,
    parked: parked ?? this.parked,
  );
  SyncRecordRow copyWithCompanion(SyncRecordsCompanion data) {
    return SyncRecordRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      localId: data.localId.present ? data.localId.value : this.localId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      versionVector: data.versionVector.present
          ? data.versionVector.value
          : this.versionVector,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      base: data.base.present ? data.base.value : this.base,
      parked: data.parked.present ? data.parked.value : this.parked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRecordRow(')
          ..write('kind: $kind, ')
          ..write('syncId: $syncId, ')
          ..write('localId: $localId, ')
          ..write('memberId: $memberId, ')
          ..write('versionVector: $versionVector, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deleted: $deleted, ')
          ..write('base: $base, ')
          ..write('parked: $parked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    kind,
    syncId,
    localId,
    memberId,
    versionVector,
    updatedAt,
    updatedBy,
    deleted,
    base,
    parked,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncRecordRow &&
          other.kind == this.kind &&
          other.syncId == this.syncId &&
          other.localId == this.localId &&
          other.memberId == this.memberId &&
          other.versionVector == this.versionVector &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deleted == this.deleted &&
          other.base == this.base &&
          other.parked == this.parked);
}

class SyncRecordsCompanion extends UpdateCompanion<SyncRecordRow> {
  final Value<String> kind;
  final Value<String> syncId;
  final Value<String> localId;
  final Value<String> memberId;
  final Value<String> versionVector;
  final Value<int> updatedAt;
  final Value<String> updatedBy;
  final Value<int> deleted;
  final Value<String?> base;
  final Value<int> parked;
  final Value<int> rowid;
  const SyncRecordsCompanion({
    this.kind = const Value.absent(),
    this.syncId = const Value.absent(),
    this.localId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.versionVector = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deleted = const Value.absent(),
    this.base = const Value.absent(),
    this.parked = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncRecordsCompanion.insert({
    required String kind,
    required String syncId,
    required String localId,
    required String memberId,
    required String versionVector,
    required int updatedAt,
    required String updatedBy,
    required int deleted,
    this.base = const Value.absent(),
    this.parked = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       syncId = Value(syncId),
       localId = Value(localId),
       memberId = Value(memberId),
       versionVector = Value(versionVector),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy),
       deleted = Value(deleted);
  static Insertable<SyncRecordRow> custom({
    Expression<String>? kind,
    Expression<String>? syncId,
    Expression<String>? localId,
    Expression<String>? memberId,
    Expression<String>? versionVector,
    Expression<int>? updatedAt,
    Expression<String>? updatedBy,
    Expression<int>? deleted,
    Expression<String>? base,
    Expression<int>? parked,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (syncId != null) 'sync_id': syncId,
      if (localId != null) 'local_id': localId,
      if (memberId != null) 'member_id': memberId,
      if (versionVector != null) 'version_vector': versionVector,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deleted != null) 'deleted': deleted,
      if (base != null) 'base': base,
      if (parked != null) 'parked': parked,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncRecordsCompanion copyWith({
    Value<String>? kind,
    Value<String>? syncId,
    Value<String>? localId,
    Value<String>? memberId,
    Value<String>? versionVector,
    Value<int>? updatedAt,
    Value<String>? updatedBy,
    Value<int>? deleted,
    Value<String?>? base,
    Value<int>? parked,
    Value<int>? rowid,
  }) {
    return SyncRecordsCompanion(
      kind: kind ?? this.kind,
      syncId: syncId ?? this.syncId,
      localId: localId ?? this.localId,
      memberId: memberId ?? this.memberId,
      versionVector: versionVector ?? this.versionVector,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deleted: deleted ?? this.deleted,
      base: base ?? this.base,
      parked: parked ?? this.parked,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (versionVector.present) {
      map['version_vector'] = Variable<String>(versionVector.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<int>(deleted.value);
    }
    if (base.present) {
      map['base'] = Variable<String>(base.value);
    }
    if (parked.present) {
      map['parked'] = Variable<int>(parked.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncRecordsCompanion(')
          ..write('kind: $kind, ')
          ..write('syncId: $syncId, ')
          ..write('localId: $localId, ')
          ..write('memberId: $memberId, ')
          ..write('versionVector: $versionVector, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deleted: $deleted, ')
          ..write('base: $base, ')
          ..write('parked: $parked, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncPending extends Table with TableInfo<SyncPending, SyncPendingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncPending(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (kind IN (\'member\', \'appointment\', \'question\', \'symptom\', \'media\', \'medication\', \'dose\', \'share\'))',
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(sync_id) > 0)',
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(local_id) > 0)',
  );
  static const VerificationMeta _changeCountMeta = const VerificationMeta(
    'changeCount',
  );
  late final GeneratedColumn<int> changeCount = GeneratedColumn<int>(
    'change_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (change_count >= 0)',
    defaultValue: const CustomExpression('1'),
  );
  @override
  List<GeneratedColumn> get $columns => [kind, syncId, localId, changeCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_pending';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncPendingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    } else if (isInserting) {
      context.missing(_syncIdMeta);
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('change_count')) {
      context.handle(
        _changeCountMeta,
        changeCount.isAcceptableOrUnknown(
          data['change_count']!,
          _changeCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, syncId};
  @override
  SyncPendingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncPendingRow(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      changeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_count'],
      )!,
    );
  }

  @override
  SyncPending createAlias(String alias) {
    return SyncPending(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(kind, sync_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class SyncPendingRow extends DataClass implements Insertable<SyncPendingRow> {
  final String kind;
  final String syncId;
  final String localId;
  final int changeCount;
  const SyncPendingRow({
    required this.kind,
    required this.syncId,
    required this.localId,
    required this.changeCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['sync_id'] = Variable<String>(syncId);
    map['local_id'] = Variable<String>(localId);
    map['change_count'] = Variable<int>(changeCount);
    return map;
  }

  SyncPendingCompanion toCompanion(bool nullToAbsent) {
    return SyncPendingCompanion(
      kind: Value(kind),
      syncId: Value(syncId),
      localId: Value(localId),
      changeCount: Value(changeCount),
    );
  }

  factory SyncPendingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncPendingRow(
      kind: serializer.fromJson<String>(json['kind']),
      syncId: serializer.fromJson<String>(json['sync_id']),
      localId: serializer.fromJson<String>(json['local_id']),
      changeCount: serializer.fromJson<int>(json['change_count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'sync_id': serializer.toJson<String>(syncId),
      'local_id': serializer.toJson<String>(localId),
      'change_count': serializer.toJson<int>(changeCount),
    };
  }

  SyncPendingRow copyWith({
    String? kind,
    String? syncId,
    String? localId,
    int? changeCount,
  }) => SyncPendingRow(
    kind: kind ?? this.kind,
    syncId: syncId ?? this.syncId,
    localId: localId ?? this.localId,
    changeCount: changeCount ?? this.changeCount,
  );
  SyncPendingRow copyWithCompanion(SyncPendingCompanion data) {
    return SyncPendingRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      localId: data.localId.present ? data.localId.value : this.localId,
      changeCount: data.changeCount.present
          ? data.changeCount.value
          : this.changeCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncPendingRow(')
          ..write('kind: $kind, ')
          ..write('syncId: $syncId, ')
          ..write('localId: $localId, ')
          ..write('changeCount: $changeCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, syncId, localId, changeCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncPendingRow &&
          other.kind == this.kind &&
          other.syncId == this.syncId &&
          other.localId == this.localId &&
          other.changeCount == this.changeCount);
}

class SyncPendingCompanion extends UpdateCompanion<SyncPendingRow> {
  final Value<String> kind;
  final Value<String> syncId;
  final Value<String> localId;
  final Value<int> changeCount;
  final Value<int> rowid;
  const SyncPendingCompanion({
    this.kind = const Value.absent(),
    this.syncId = const Value.absent(),
    this.localId = const Value.absent(),
    this.changeCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncPendingCompanion.insert({
    required String kind,
    required String syncId,
    required String localId,
    this.changeCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       syncId = Value(syncId),
       localId = Value(localId);
  static Insertable<SyncPendingRow> custom({
    Expression<String>? kind,
    Expression<String>? syncId,
    Expression<String>? localId,
    Expression<int>? changeCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (syncId != null) 'sync_id': syncId,
      if (localId != null) 'local_id': localId,
      if (changeCount != null) 'change_count': changeCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncPendingCompanion copyWith({
    Value<String>? kind,
    Value<String>? syncId,
    Value<String>? localId,
    Value<int>? changeCount,
    Value<int>? rowid,
  }) {
    return SyncPendingCompanion(
      kind: kind ?? this.kind,
      syncId: syncId ?? this.syncId,
      localId: localId ?? this.localId,
      changeCount: changeCount ?? this.changeCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (changeCount.present) {
      map['change_count'] = Variable<int>(changeCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncPendingCompanion(')
          ..write('kind: $kind, ')
          ..write('syncId: $syncId, ')
          ..write('localId: $localId, ')
          ..write('changeCount: $changeCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncConflicts extends Table
    with TableInfo<SyncConflicts, SyncConflictRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncConflicts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (kind IN (\'member\', \'appointment\', \'question\', \'symptom\', \'media\', \'medication\', \'dose\'))',
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(sync_id) > 0)',
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(local_id) > 0)',
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(member_id) > 0)',
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (reason IN (\'edited\', \'deleted\', \'deletedHere\'))',
  );
  static const VerificationMeta _localMeta = const VerificationMeta('local');
  late final GeneratedColumn<String> local = GeneratedColumn<String>(
    'local',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (local IS NULL OR(json_valid(local) AND json_type(local) = \'object\'))',
  );
  static const VerificationMeta _remoteMeta = const VerificationMeta('remote');
  late final GeneratedColumn<String> remote = GeneratedColumn<String>(
    'remote',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (remote IS NULL OR(json_valid(remote) AND json_type(remote) = \'object\'))',
  );
  static const VerificationMeta _remoteVectorMeta = const VerificationMeta(
    'remoteVector',
  );
  late final GeneratedColumn<String> remoteVector = GeneratedColumn<String>(
    'remote_vector',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (json_valid(remote_vector) AND json_type(remote_vector) = \'object\')',
  );
  static const VerificationMeta _remoteUpdatedAtMeta = const VerificationMeta(
    'remoteUpdatedAt',
  );
  late final GeneratedColumn<int> remoteUpdatedAt = GeneratedColumn<int>(
    'remote_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _remoteUpdatedByMeta = const VerificationMeta(
    'remoteUpdatedBy',
  );
  late final GeneratedColumn<String> remoteUpdatedBy = GeneratedColumn<String>(
    'remote_updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(remote_updated_by) > 0)',
  );
  static const VerificationMeta _fieldsMeta = const VerificationMeta('fields');
  late final GeneratedColumn<String> fields = GeneratedColumn<String>(
    'fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'[]\' CHECK (json_valid(fields) AND json_type(fields) = \'array\')',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _detectedAtMeta = const VerificationMeta(
    'detectedAt',
  );
  late final GeneratedColumn<int> detectedAt = GeneratedColumn<int>(
    'detected_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    kind,
    syncId,
    localId,
    memberId,
    reason,
    local,
    remote,
    remoteVector,
    remoteUpdatedAt,
    remoteUpdatedBy,
    fields,
    detectedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncConflictRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    } else if (isInserting) {
      context.missing(_syncIdMeta);
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('local')) {
      context.handle(
        _localMeta,
        local.isAcceptableOrUnknown(data['local']!, _localMeta),
      );
    }
    if (data.containsKey('remote')) {
      context.handle(
        _remoteMeta,
        remote.isAcceptableOrUnknown(data['remote']!, _remoteMeta),
      );
    }
    if (data.containsKey('remote_vector')) {
      context.handle(
        _remoteVectorMeta,
        remoteVector.isAcceptableOrUnknown(
          data['remote_vector']!,
          _remoteVectorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteVectorMeta);
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
        _remoteUpdatedAtMeta,
        remoteUpdatedAt.isAcceptableOrUnknown(
          data['remote_updated_at']!,
          _remoteUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteUpdatedAtMeta);
    }
    if (data.containsKey('remote_updated_by')) {
      context.handle(
        _remoteUpdatedByMeta,
        remoteUpdatedBy.isAcceptableOrUnknown(
          data['remote_updated_by']!,
          _remoteUpdatedByMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteUpdatedByMeta);
    }
    if (data.containsKey('fields')) {
      context.handle(
        _fieldsMeta,
        fields.isAcceptableOrUnknown(data['fields']!, _fieldsMeta),
      );
    }
    if (data.containsKey('detected_at')) {
      context.handle(
        _detectedAtMeta,
        detectedAt.isAcceptableOrUnknown(data['detected_at']!, _detectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_detectedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, syncId};
  @override
  SyncConflictRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConflictRow(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      local: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local'],
      ),
      remote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote'],
      ),
      remoteVector: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_vector'],
      )!,
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_updated_at'],
      )!,
      remoteUpdatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_updated_by'],
      )!,
      fields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fields'],
      )!,
      detectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}detected_at'],
      )!,
    );
  }

  @override
  SyncConflicts createAlias(String alias) {
    return SyncConflicts(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const ['PRIMARY KEY(kind, sync_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class SyncConflictRow extends DataClass implements Insertable<SyncConflictRow> {
  final String kind;
  final String syncId;
  final String localId;
  final String memberId;
  final String reason;
  final String? local;
  final String? remote;
  final String remoteVector;
  final int remoteUpdatedAt;
  final String remoteUpdatedBy;
  final String fields;
  final int detectedAt;
  const SyncConflictRow({
    required this.kind,
    required this.syncId,
    required this.localId,
    required this.memberId,
    required this.reason,
    this.local,
    this.remote,
    required this.remoteVector,
    required this.remoteUpdatedAt,
    required this.remoteUpdatedBy,
    required this.fields,
    required this.detectedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['sync_id'] = Variable<String>(syncId);
    map['local_id'] = Variable<String>(localId);
    map['member_id'] = Variable<String>(memberId);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || local != null) {
      map['local'] = Variable<String>(local);
    }
    if (!nullToAbsent || remote != null) {
      map['remote'] = Variable<String>(remote);
    }
    map['remote_vector'] = Variable<String>(remoteVector);
    map['remote_updated_at'] = Variable<int>(remoteUpdatedAt);
    map['remote_updated_by'] = Variable<String>(remoteUpdatedBy);
    map['fields'] = Variable<String>(fields);
    map['detected_at'] = Variable<int>(detectedAt);
    return map;
  }

  SyncConflictsCompanion toCompanion(bool nullToAbsent) {
    return SyncConflictsCompanion(
      kind: Value(kind),
      syncId: Value(syncId),
      localId: Value(localId),
      memberId: Value(memberId),
      reason: Value(reason),
      local: local == null && nullToAbsent
          ? const Value.absent()
          : Value(local),
      remote: remote == null && nullToAbsent
          ? const Value.absent()
          : Value(remote),
      remoteVector: Value(remoteVector),
      remoteUpdatedAt: Value(remoteUpdatedAt),
      remoteUpdatedBy: Value(remoteUpdatedBy),
      fields: Value(fields),
      detectedAt: Value(detectedAt),
    );
  }

  factory SyncConflictRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConflictRow(
      kind: serializer.fromJson<String>(json['kind']),
      syncId: serializer.fromJson<String>(json['sync_id']),
      localId: serializer.fromJson<String>(json['local_id']),
      memberId: serializer.fromJson<String>(json['member_id']),
      reason: serializer.fromJson<String>(json['reason']),
      local: serializer.fromJson<String?>(json['local']),
      remote: serializer.fromJson<String?>(json['remote']),
      remoteVector: serializer.fromJson<String>(json['remote_vector']),
      remoteUpdatedAt: serializer.fromJson<int>(json['remote_updated_at']),
      remoteUpdatedBy: serializer.fromJson<String>(json['remote_updated_by']),
      fields: serializer.fromJson<String>(json['fields']),
      detectedAt: serializer.fromJson<int>(json['detected_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'sync_id': serializer.toJson<String>(syncId),
      'local_id': serializer.toJson<String>(localId),
      'member_id': serializer.toJson<String>(memberId),
      'reason': serializer.toJson<String>(reason),
      'local': serializer.toJson<String?>(local),
      'remote': serializer.toJson<String?>(remote),
      'remote_vector': serializer.toJson<String>(remoteVector),
      'remote_updated_at': serializer.toJson<int>(remoteUpdatedAt),
      'remote_updated_by': serializer.toJson<String>(remoteUpdatedBy),
      'fields': serializer.toJson<String>(fields),
      'detected_at': serializer.toJson<int>(detectedAt),
    };
  }

  SyncConflictRow copyWith({
    String? kind,
    String? syncId,
    String? localId,
    String? memberId,
    String? reason,
    Value<String?> local = const Value.absent(),
    Value<String?> remote = const Value.absent(),
    String? remoteVector,
    int? remoteUpdatedAt,
    String? remoteUpdatedBy,
    String? fields,
    int? detectedAt,
  }) => SyncConflictRow(
    kind: kind ?? this.kind,
    syncId: syncId ?? this.syncId,
    localId: localId ?? this.localId,
    memberId: memberId ?? this.memberId,
    reason: reason ?? this.reason,
    local: local.present ? local.value : this.local,
    remote: remote.present ? remote.value : this.remote,
    remoteVector: remoteVector ?? this.remoteVector,
    remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
    remoteUpdatedBy: remoteUpdatedBy ?? this.remoteUpdatedBy,
    fields: fields ?? this.fields,
    detectedAt: detectedAt ?? this.detectedAt,
  );
  SyncConflictRow copyWithCompanion(SyncConflictsCompanion data) {
    return SyncConflictRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      localId: data.localId.present ? data.localId.value : this.localId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      reason: data.reason.present ? data.reason.value : this.reason,
      local: data.local.present ? data.local.value : this.local,
      remote: data.remote.present ? data.remote.value : this.remote,
      remoteVector: data.remoteVector.present
          ? data.remoteVector.value
          : this.remoteVector,
      remoteUpdatedAt: data.remoteUpdatedAt.present
          ? data.remoteUpdatedAt.value
          : this.remoteUpdatedAt,
      remoteUpdatedBy: data.remoteUpdatedBy.present
          ? data.remoteUpdatedBy.value
          : this.remoteUpdatedBy,
      fields: data.fields.present ? data.fields.value : this.fields,
      detectedAt: data.detectedAt.present
          ? data.detectedAt.value
          : this.detectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictRow(')
          ..write('kind: $kind, ')
          ..write('syncId: $syncId, ')
          ..write('localId: $localId, ')
          ..write('memberId: $memberId, ')
          ..write('reason: $reason, ')
          ..write('local: $local, ')
          ..write('remote: $remote, ')
          ..write('remoteVector: $remoteVector, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('remoteUpdatedBy: $remoteUpdatedBy, ')
          ..write('fields: $fields, ')
          ..write('detectedAt: $detectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    kind,
    syncId,
    localId,
    memberId,
    reason,
    local,
    remote,
    remoteVector,
    remoteUpdatedAt,
    remoteUpdatedBy,
    fields,
    detectedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflictRow &&
          other.kind == this.kind &&
          other.syncId == this.syncId &&
          other.localId == this.localId &&
          other.memberId == this.memberId &&
          other.reason == this.reason &&
          other.local == this.local &&
          other.remote == this.remote &&
          other.remoteVector == this.remoteVector &&
          other.remoteUpdatedAt == this.remoteUpdatedAt &&
          other.remoteUpdatedBy == this.remoteUpdatedBy &&
          other.fields == this.fields &&
          other.detectedAt == this.detectedAt);
}

class SyncConflictsCompanion extends UpdateCompanion<SyncConflictRow> {
  final Value<String> kind;
  final Value<String> syncId;
  final Value<String> localId;
  final Value<String> memberId;
  final Value<String> reason;
  final Value<String?> local;
  final Value<String?> remote;
  final Value<String> remoteVector;
  final Value<int> remoteUpdatedAt;
  final Value<String> remoteUpdatedBy;
  final Value<String> fields;
  final Value<int> detectedAt;
  final Value<int> rowid;
  const SyncConflictsCompanion({
    this.kind = const Value.absent(),
    this.syncId = const Value.absent(),
    this.localId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.reason = const Value.absent(),
    this.local = const Value.absent(),
    this.remote = const Value.absent(),
    this.remoteVector = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.remoteUpdatedBy = const Value.absent(),
    this.fields = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncConflictsCompanion.insert({
    required String kind,
    required String syncId,
    required String localId,
    required String memberId,
    required String reason,
    this.local = const Value.absent(),
    this.remote = const Value.absent(),
    required String remoteVector,
    required int remoteUpdatedAt,
    required String remoteUpdatedBy,
    this.fields = const Value.absent(),
    required int detectedAt,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       syncId = Value(syncId),
       localId = Value(localId),
       memberId = Value(memberId),
       reason = Value(reason),
       remoteVector = Value(remoteVector),
       remoteUpdatedAt = Value(remoteUpdatedAt),
       remoteUpdatedBy = Value(remoteUpdatedBy),
       detectedAt = Value(detectedAt);
  static Insertable<SyncConflictRow> custom({
    Expression<String>? kind,
    Expression<String>? syncId,
    Expression<String>? localId,
    Expression<String>? memberId,
    Expression<String>? reason,
    Expression<String>? local,
    Expression<String>? remote,
    Expression<String>? remoteVector,
    Expression<int>? remoteUpdatedAt,
    Expression<String>? remoteUpdatedBy,
    Expression<String>? fields,
    Expression<int>? detectedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (syncId != null) 'sync_id': syncId,
      if (localId != null) 'local_id': localId,
      if (memberId != null) 'member_id': memberId,
      if (reason != null) 'reason': reason,
      if (local != null) 'local': local,
      if (remote != null) 'remote': remote,
      if (remoteVector != null) 'remote_vector': remoteVector,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (remoteUpdatedBy != null) 'remote_updated_by': remoteUpdatedBy,
      if (fields != null) 'fields': fields,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncConflictsCompanion copyWith({
    Value<String>? kind,
    Value<String>? syncId,
    Value<String>? localId,
    Value<String>? memberId,
    Value<String>? reason,
    Value<String?>? local,
    Value<String?>? remote,
    Value<String>? remoteVector,
    Value<int>? remoteUpdatedAt,
    Value<String>? remoteUpdatedBy,
    Value<String>? fields,
    Value<int>? detectedAt,
    Value<int>? rowid,
  }) {
    return SyncConflictsCompanion(
      kind: kind ?? this.kind,
      syncId: syncId ?? this.syncId,
      localId: localId ?? this.localId,
      memberId: memberId ?? this.memberId,
      reason: reason ?? this.reason,
      local: local ?? this.local,
      remote: remote ?? this.remote,
      remoteVector: remoteVector ?? this.remoteVector,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      remoteUpdatedBy: remoteUpdatedBy ?? this.remoteUpdatedBy,
      fields: fields ?? this.fields,
      detectedAt: detectedAt ?? this.detectedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (local.present) {
      map['local'] = Variable<String>(local.value);
    }
    if (remote.present) {
      map['remote'] = Variable<String>(remote.value);
    }
    if (remoteVector.present) {
      map['remote_vector'] = Variable<String>(remoteVector.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<int>(remoteUpdatedAt.value);
    }
    if (remoteUpdatedBy.present) {
      map['remote_updated_by'] = Variable<String>(remoteUpdatedBy.value);
    }
    if (fields.present) {
      map['fields'] = Variable<String>(fields.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<int>(detectedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictsCompanion(')
          ..write('kind: $kind, ')
          ..write('syncId: $syncId, ')
          ..write('localId: $localId, ')
          ..write('memberId: $memberId, ')
          ..write('reason: $reason, ')
          ..write('local: $local, ')
          ..write('remote: $remote, ')
          ..write('remoteVector: $remoteVector, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('remoteUpdatedBy: $remoteUpdatedBy, ')
          ..write('fields: $fields, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncCursors extends Table with TableInfo<SyncCursors, SyncCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncCursors(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(device_id) > 0)',
  );
  static const VerificationMeta _lastSeqMeta = const VerificationMeta(
    'lastSeq',
  );
  late final GeneratedColumn<int> lastSeq = GeneratedColumn<int>(
    'last_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (last_seq >= 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, lastSeq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('last_seq')) {
      context.handle(
        _lastSeqMeta,
        lastSeq.isAcceptableOrUnknown(data['last_seq']!, _lastSeqMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeqMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  SyncCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorRow(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      lastSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seq'],
      )!,
    );
  }

  @override
  SyncCursors createAlias(String alias) {
    return SyncCursors(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class SyncCursorRow extends DataClass implements Insertable<SyncCursorRow> {
  final String deviceId;
  final int lastSeq;
  const SyncCursorRow({required this.deviceId, required this.lastSeq});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['last_seq'] = Variable<int>(lastSeq);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      deviceId: Value(deviceId),
      lastSeq: Value(lastSeq),
    );
  }

  factory SyncCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorRow(
      deviceId: serializer.fromJson<String>(json['device_id']),
      lastSeq: serializer.fromJson<int>(json['last_seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'device_id': serializer.toJson<String>(deviceId),
      'last_seq': serializer.toJson<int>(lastSeq),
    };
  }

  SyncCursorRow copyWith({String? deviceId, int? lastSeq}) => SyncCursorRow(
    deviceId: deviceId ?? this.deviceId,
    lastSeq: lastSeq ?? this.lastSeq,
  );
  SyncCursorRow copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursorRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      lastSeq: data.lastSeq.present ? data.lastSeq.value : this.lastSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorRow(')
          ..write('deviceId: $deviceId, ')
          ..write('lastSeq: $lastSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, lastSeq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursorRow &&
          other.deviceId == this.deviceId &&
          other.lastSeq == this.lastSeq);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursorRow> {
  final Value<String> deviceId;
  final Value<int> lastSeq;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.deviceId = const Value.absent(),
    this.lastSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String deviceId,
    required int lastSeq,
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       lastSeq = Value(lastSeq);
  static Insertable<SyncCursorRow> custom({
    Expression<String>? deviceId,
    Expression<int>? lastSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (lastSeq != null) 'last_seq': lastSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? lastSeq,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      deviceId: deviceId ?? this.deviceId,
      lastSeq: lastSeq ?? this.lastSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (lastSeq.present) {
      map['last_seq'] = Variable<int>(lastSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('lastSeq: $lastSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncKnownMembers extends Table
    with TableInfo<SyncKnownMembers, SyncKnownMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncKnownMembers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(uid) > 0)',
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
    'public_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(public_key) > 0)',
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (role IN (\'admin\', \'member\'))',
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [uid, publicKey, role, label];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_known_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncKnownMemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  SyncKnownMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncKnownMemberRow(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
    );
  }

  @override
  SyncKnownMembers createAlias(String alias) {
    return SyncKnownMembers(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class SyncKnownMemberRow extends DataClass
    implements Insertable<SyncKnownMemberRow> {
  final String uid;
  final String publicKey;
  final String role;
  final String? label;
  const SyncKnownMemberRow({
    required this.uid,
    required this.publicKey,
    required this.role,
    this.label,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['public_key'] = Variable<String>(publicKey);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    return map;
  }

  SyncKnownMembersCompanion toCompanion(bool nullToAbsent) {
    return SyncKnownMembersCompanion(
      uid: Value(uid),
      publicKey: Value(publicKey),
      role: Value(role),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
    );
  }

  factory SyncKnownMemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncKnownMemberRow(
      uid: serializer.fromJson<String>(json['uid']),
      publicKey: serializer.fromJson<String>(json['public_key']),
      role: serializer.fromJson<String>(json['role']),
      label: serializer.fromJson<String?>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'public_key': serializer.toJson<String>(publicKey),
      'role': serializer.toJson<String>(role),
      'label': serializer.toJson<String?>(label),
    };
  }

  SyncKnownMemberRow copyWith({
    String? uid,
    String? publicKey,
    String? role,
    Value<String?> label = const Value.absent(),
  }) => SyncKnownMemberRow(
    uid: uid ?? this.uid,
    publicKey: publicKey ?? this.publicKey,
    role: role ?? this.role,
    label: label.present ? label.value : this.label,
  );
  SyncKnownMemberRow copyWithCompanion(SyncKnownMembersCompanion data) {
    return SyncKnownMemberRow(
      uid: data.uid.present ? data.uid.value : this.uid,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      role: data.role.present ? data.role.value : this.role,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncKnownMemberRow(')
          ..write('uid: $uid, ')
          ..write('publicKey: $publicKey, ')
          ..write('role: $role, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, publicKey, role, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncKnownMemberRow &&
          other.uid == this.uid &&
          other.publicKey == this.publicKey &&
          other.role == this.role &&
          other.label == this.label);
}

class SyncKnownMembersCompanion extends UpdateCompanion<SyncKnownMemberRow> {
  final Value<String> uid;
  final Value<String> publicKey;
  final Value<String> role;
  final Value<String?> label;
  final Value<int> rowid;
  const SyncKnownMembersCompanion({
    this.uid = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.role = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncKnownMembersCompanion.insert({
    required String uid,
    required String publicKey,
    required String role,
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       publicKey = Value(publicKey),
       role = Value(role);
  static Insertable<SyncKnownMemberRow> custom({
    Expression<String>? uid,
    Expression<String>? publicKey,
    Expression<String>? role,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (publicKey != null) 'public_key': publicKey,
      if (role != null) 'role': role,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncKnownMembersCompanion copyWith({
    Value<String>? uid,
    Value<String>? publicKey,
    Value<String>? role,
    Value<String?>? label,
    Value<int>? rowid,
  }) {
    return SyncKnownMembersCompanion(
      uid: uid ?? this.uid,
      publicKey: publicKey ?? this.publicKey,
      role: role ?? this.role,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncKnownMembersCompanion(')
          ..write('uid: $uid, ')
          ..write('publicKey: $publicKey, ')
          ..write('role: $role, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final FamilyMembers familyMembers = FamilyMembers(this);
  late final Index familyMembersSingleSelf = Index(
    'family_members_single_self',
    'CREATE UNIQUE INDEX family_members_single_self ON family_members (relation) WHERE relation = \'self\'',
  );
  late final Appointments appointments = Appointments(this);
  late final Index appointmentsByMember = Index(
    'appointments_by_member',
    'CREATE INDEX appointments_by_member ON appointments (member_id, scheduled_at)',
  );
  late final DoctorQuestions doctorQuestions = DoctorQuestions(this);
  late final Index doctorQuestionsByMember = Index(
    'doctor_questions_by_member',
    'CREATE INDEX doctor_questions_by_member ON doctor_questions (member_id, created_at)',
  );
  late final Index doctorQuestionsByAppointment = Index(
    'doctor_questions_by_appointment',
    'CREATE INDEX doctor_questions_by_appointment ON doctor_questions (appointment_id)',
  );
  late final SymptomEntries symptomEntries = SymptomEntries(this);
  late final Index symptomEntriesByGroup = Index(
    'symptom_entries_by_group',
    'CREATE INDEX symptom_entries_by_group ON symptom_entries (member_id, name_key, started_at)',
  );
  late final VisitMedia visitMedia = VisitMedia(this);
  late final Index visitMediaByAppointment = Index(
    'visit_media_by_appointment',
    'CREATE INDEX visit_media_by_appointment ON visit_media (appointment_id, created_at)',
  );
  late final Index visitMediaByMember = Index(
    'visit_media_by_member',
    'CREATE INDEX visit_media_by_member ON visit_media (member_id)',
  );
  late final Medications medications = Medications(this);
  late final Index medicationsByMember = Index(
    'medications_by_member',
    'CREATE INDEX medications_by_member ON medications (member_id)',
  );
  late final DoseRecords doseRecords = DoseRecords(this);
  late final Index doseRecordsByMember = Index(
    'dose_records_by_member',
    'CREATE INDEX dose_records_by_member ON dose_records (member_id, scheduled_at)',
  );
  late final SyncSettings syncSettings = SyncSettings(this);
  late final SyncSharedMembers syncSharedMembers = SyncSharedMembers(this);
  late final SyncRecords syncRecords = SyncRecords(this);
  late final Index syncRecordsByLocal = Index(
    'sync_records_by_local',
    'CREATE INDEX sync_records_by_local ON sync_records (kind, local_id)',
  );
  late final Index syncRecordsByMember = Index(
    'sync_records_by_member',
    'CREATE INDEX sync_records_by_member ON sync_records (member_id)',
  );
  late final SyncPending syncPending = SyncPending(this);
  late final SyncConflicts syncConflicts = SyncConflicts(this);
  late final SyncCursors syncCursors = SyncCursors(this);
  late final SyncKnownMembers syncKnownMembers = SyncKnownMembers(this);
  late final Trigger syncShareOnlyChildren = Trigger(
    'CREATE TRIGGER sync_share_only_children BEFORE INSERT ON sync_shared_members WHEN (SELECT relation FROM family_members WHERE id = NEW.member_id) IS NOT \'child\' BEGIN SELECT RAISE (ABORT, \'only a child profile can be shared\');END',
    'sync_share_only_children',
  );
  late final Trigger syncSharedStaysChild = Trigger(
    'CREATE TRIGGER sync_shared_stays_child BEFORE UPDATE OF relation ON family_members WHEN NEW.relation <> \'child\' AND EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.id) BEGIN SELECT RAISE (ABORT, \'a shared profile stays a child\');END',
    'sync_shared_stays_child',
  );
  late final Trigger syncTrackFamilyMembersInsert = Trigger(
    'CREATE TRIGGER sync_track_family_members_insert AFTER INSERT ON family_members WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'member\' AND sync_id = NEW.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'member\', NEW.id, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'member\' AND sync_id = NEW.id;END',
    'sync_track_family_members_insert',
  );
  late final Trigger syncTrackFamilyMembersUpdate = Trigger(
    'CREATE TRIGGER sync_track_family_members_update AFTER UPDATE ON family_members WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.id) OR EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'member\' AND sync_id = NEW.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'member\', NEW.id, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'member\' AND sync_id = NEW.id;END',
    'sync_track_family_members_update',
  );
  late final Trigger syncTrackFamilyMembersDelete = Trigger(
    'CREATE TRIGGER sync_track_family_members_delete AFTER DELETE ON family_members WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'member\' AND sync_id = OLD.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'member\', OLD.id, OLD.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = OLD.id WHERE kind = \'member\' AND sync_id = OLD.id;END',
    'sync_track_family_members_delete',
  );
  late final Trigger syncTrackAppointmentsInsert = Trigger(
    'CREATE TRIGGER sync_track_appointments_insert AFTER INSERT ON appointments WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'appointment\' AND sync_id = NEW.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'appointment\', NEW.id, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'appointment\' AND sync_id = NEW.id;END',
    'sync_track_appointments_insert',
  );
  late final Trigger syncTrackAppointmentsUpdate = Trigger(
    'CREATE TRIGGER sync_track_appointments_update AFTER UPDATE ON appointments WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.member_id) OR EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'appointment\' AND sync_id = NEW.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'appointment\', NEW.id, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'appointment\' AND sync_id = NEW.id;END',
    'sync_track_appointments_update',
  );
  late final Trigger syncTrackAppointmentsDelete = Trigger(
    'CREATE TRIGGER sync_track_appointments_delete AFTER DELETE ON appointments WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'appointment\' AND sync_id = OLD.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'appointment\', OLD.id, OLD.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = OLD.id WHERE kind = \'appointment\' AND sync_id = OLD.id;END',
    'sync_track_appointments_delete',
  );
  late final Trigger syncTrackDoctorQuestionsInsert = Trigger(
    'CREATE TRIGGER sync_track_doctor_questions_insert AFTER INSERT ON doctor_questions WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'question\' AND sync_id = NEW.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'question\', NEW.id, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'question\' AND sync_id = NEW.id;END',
    'sync_track_doctor_questions_insert',
  );
  late final Trigger syncTrackDoctorQuestionsUpdate = Trigger(
    'CREATE TRIGGER sync_track_doctor_questions_update AFTER UPDATE ON doctor_questions WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.member_id) OR EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'question\' AND sync_id = NEW.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'question\', NEW.id, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'question\' AND sync_id = NEW.id;END',
    'sync_track_doctor_questions_update',
  );
  late final Trigger syncTrackDoctorQuestionsDelete = Trigger(
    'CREATE TRIGGER sync_track_doctor_questions_delete AFTER DELETE ON doctor_questions WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'question\' AND sync_id = OLD.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'question\', OLD.id, OLD.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = OLD.id WHERE kind = \'question\' AND sync_id = OLD.id;END',
    'sync_track_doctor_questions_delete',
  );
  late final Trigger syncTrackSymptomEntriesInsert = Trigger(
    'CREATE TRIGGER sync_track_symptom_entries_insert AFTER INSERT ON symptom_entries WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'symptom\' AND sync_id = NEW.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'symptom\', NEW.id, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'symptom\' AND sync_id = NEW.id;END',
    'sync_track_symptom_entries_insert',
  );
  late final Trigger syncTrackSymptomEntriesUpdate = Trigger(
    'CREATE TRIGGER sync_track_symptom_entries_update AFTER UPDATE ON symptom_entries WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.member_id) OR EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'symptom\' AND sync_id = NEW.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'symptom\', NEW.id, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'symptom\' AND sync_id = NEW.id;END',
    'sync_track_symptom_entries_update',
  );
  late final Trigger syncTrackSymptomEntriesDelete = Trigger(
    'CREATE TRIGGER sync_track_symptom_entries_delete AFTER DELETE ON symptom_entries WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'symptom\' AND sync_id = OLD.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'symptom\', OLD.id, OLD.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = OLD.id WHERE kind = \'symptom\' AND sync_id = OLD.id;END',
    'sync_track_symptom_entries_delete',
  );
  late final Trigger syncTrackVisitMediaInsert = Trigger(
    'CREATE TRIGGER sync_track_visit_media_insert AFTER INSERT ON visit_media WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'media\' AND sync_id = NEW.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'media\', NEW.id, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'media\' AND sync_id = NEW.id;END',
    'sync_track_visit_media_insert',
  );
  late final Trigger syncTrackVisitMediaUpdate = Trigger(
    'CREATE TRIGGER sync_track_visit_media_update AFTER UPDATE ON visit_media WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.member_id) OR EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'media\' AND sync_id = NEW.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'media\', NEW.id, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'media\' AND sync_id = NEW.id;END',
    'sync_track_visit_media_update',
  );
  late final Trigger syncTrackVisitMediaDelete = Trigger(
    'CREATE TRIGGER sync_track_visit_media_delete AFTER DELETE ON visit_media WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'media\' AND sync_id = OLD.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'media\', OLD.id, OLD.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = OLD.id WHERE kind = \'media\' AND sync_id = OLD.id;END',
    'sync_track_visit_media_delete',
  );
  late final Trigger syncTrackMedicationsInsert = Trigger(
    'CREATE TRIGGER sync_track_medications_insert AFTER INSERT ON medications WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'medication\' AND sync_id = NEW.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'medication\', NEW.id, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'medication\' AND sync_id = NEW.id;END',
    'sync_track_medications_insert',
  );
  late final Trigger syncTrackMedicationsUpdate = Trigger(
    'CREATE TRIGGER sync_track_medications_update AFTER UPDATE ON medications WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.member_id) OR EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'medication\' AND sync_id = NEW.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'medication\', NEW.id, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'medication\' AND sync_id = NEW.id;END',
    'sync_track_medications_update',
  );
  late final Trigger syncTrackMedicationsDelete = Trigger(
    'CREATE TRIGGER sync_track_medications_delete AFTER DELETE ON medications WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'medication\' AND sync_id = OLD.id))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'medication\', OLD.id, OLD.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = OLD.id WHERE kind = \'medication\' AND sync_id = OLD.id;END',
    'sync_track_medications_delete',
  );
  late final Trigger syncTrackDoseRecordsInsert = Trigger(
    'CREATE TRIGGER sync_track_dose_records_insert AFTER INSERT ON dose_records WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'dose\' AND sync_id = NEW.medication_id || \'@\' || NEW.scheduled_at))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'dose\', NEW.medication_id || \'@\' || NEW.scheduled_at, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'dose\' AND sync_id = NEW.medication_id || \'@\' || NEW.scheduled_at;END',
    'sync_track_dose_records_insert',
  );
  late final Trigger syncTrackDoseRecordsUpdate = Trigger(
    'CREATE TRIGGER sync_track_dose_records_update AFTER UPDATE ON dose_records WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = NEW.member_id) OR EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'dose\' AND sync_id = NEW.medication_id || \'@\' || NEW.scheduled_at))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'dose\', NEW.medication_id || \'@\' || NEW.scheduled_at, NEW.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = NEW.id WHERE kind = \'dose\' AND sync_id = NEW.medication_id || \'@\' || NEW.scheduled_at;END',
    'sync_track_dose_records_update',
  );
  late final Trigger syncTrackDoseRecordsDelete = Trigger(
    'CREATE TRIGGER sync_track_dose_records_delete AFTER DELETE ON dose_records WHEN EXISTS (SELECT 1 FROM sync_settings WHERE household_id IS NOT NULL AND applying = 0) AND(EXISTS (SELECT 1 FROM sync_shared_members WHERE member_id = OLD.member_id) OR EXISTS (SELECT 1 FROM sync_records WHERE kind = \'dose\' AND sync_id = OLD.medication_id || \'@\' || OLD.scheduled_at))BEGIN INSERT OR IGNORE INTO sync_pending (kind, sync_id, local_id, change_count) VALUES (\'dose\', OLD.medication_id || \'@\' || OLD.scheduled_at, OLD.id, 0);UPDATE sync_pending SET change_count = change_count + 1, local_id = OLD.id WHERE kind = \'dose\' AND sync_id = OLD.medication_id || \'@\' || OLD.scheduled_at;END',
    'sync_track_dose_records_delete',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    familyMembers,
    familyMembersSingleSelf,
    appointments,
    appointmentsByMember,
    doctorQuestions,
    doctorQuestionsByMember,
    doctorQuestionsByAppointment,
    symptomEntries,
    symptomEntriesByGroup,
    visitMedia,
    visitMediaByAppointment,
    visitMediaByMember,
    medications,
    medicationsByMember,
    doseRecords,
    doseRecordsByMember,
    syncSettings,
    syncSharedMembers,
    syncRecords,
    syncRecordsByLocal,
    syncRecordsByMember,
    syncPending,
    syncConflicts,
    syncCursors,
    syncKnownMembers,
    syncShareOnlyChildren,
    syncSharedStaysChild,
    syncTrackFamilyMembersInsert,
    syncTrackFamilyMembersUpdate,
    syncTrackFamilyMembersDelete,
    syncTrackAppointmentsInsert,
    syncTrackAppointmentsUpdate,
    syncTrackAppointmentsDelete,
    syncTrackDoctorQuestionsInsert,
    syncTrackDoctorQuestionsUpdate,
    syncTrackDoctorQuestionsDelete,
    syncTrackSymptomEntriesInsert,
    syncTrackSymptomEntriesUpdate,
    syncTrackSymptomEntriesDelete,
    syncTrackVisitMediaInsert,
    syncTrackVisitMediaUpdate,
    syncTrackVisitMediaDelete,
    syncTrackMedicationsInsert,
    syncTrackMedicationsUpdate,
    syncTrackMedicationsDelete,
    syncTrackDoseRecordsInsert,
    syncTrackDoseRecordsUpdate,
    syncTrackDoseRecordsDelete,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sync_shared_members',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'family_members',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'family_members',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'family_members',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'family_members',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'appointments',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'appointments',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'appointments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'doctor_questions',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'doctor_questions',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'doctor_questions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'symptom_entries',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'symptom_entries',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'symptom_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visit_media',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visit_media',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visit_media',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'medications',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'medications',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'medications',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dose_records',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dose_records',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dose_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('sync_pending', kind: UpdateKind.insert),
        TableUpdate('sync_pending', kind: UpdateKind.update),
      ],
    ),
  ]);
}

typedef $FamilyMembersCreateCompanionBuilder =
    FamilyMembersCompanion Function({
      required String id,
      required String name,
      required String relation,
      Value<String?> birthDate,
      Value<String> allergies,
      Value<String> chronicConditions,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $FamilyMembersUpdateCompanionBuilder =
    FamilyMembersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> relation,
      Value<String?> birthDate,
      Value<String> allergies,
      Value<String> chronicConditions,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $FamilyMembersReferences
    extends BaseReferences<_$LocalDatabase, FamilyMembers, FamilyMemberRow> {
  $FamilyMembersReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Appointments, List<AppointmentRow>>
  _appointmentsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.appointments,
    aliasName: 'family_members__id__appointments__member_id',
  );

  $AppointmentsProcessedTableManager get appointmentsRefs {
    final manager = $AppointmentsTableManager(
      $_db,
      $_db.appointments,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_appointmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<DoctorQuestions, List<DoctorQuestionRow>>
  _doctorQuestionsRefsTable(_$LocalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.doctorQuestions,
        aliasName: 'family_members__id__doctor_questions__member_id',
      );

  $DoctorQuestionsProcessedTableManager get doctorQuestionsRefs {
    final manager = $DoctorQuestionsTableManager(
      $_db,
      $_db.doctorQuestions,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _doctorQuestionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<SymptomEntries, List<SymptomEntryRow>>
  _symptomEntriesRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.symptomEntries,
    aliasName: 'family_members__id__symptom_entries__member_id',
  );

  $SymptomEntriesProcessedTableManager get symptomEntriesRefs {
    final manager = $SymptomEntriesTableManager(
      $_db,
      $_db.symptomEntries,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_symptomEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<VisitMedia, List<VisitMediaRow>>
  _visitMediaRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.visitMedia,
    aliasName: 'family_members__id__visit_media__member_id',
  );

  $VisitMediaProcessedTableManager get visitMediaRefs {
    final manager = $VisitMediaTableManager(
      $_db,
      $_db.visitMedia,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_visitMediaRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Medications, List<MedicationRow>>
  _medicationsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.medications,
    aliasName: 'family_members__id__medications__member_id',
  );

  $MedicationsProcessedTableManager get medicationsRefs {
    final manager = $MedicationsTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_medicationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<DoseRecords, List<DoseRecordRow>>
  _doseRecordsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.doseRecords,
    aliasName: 'family_members__id__dose_records__member_id',
  );

  $DoseRecordsProcessedTableManager get doseRecordsRefs {
    final manager = $DoseRecordsTableManager(
      $_db,
      $_db.doseRecords,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_doseRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<SyncSharedMembers, List<SyncSharedMemberRow>>
  _syncSharedMembersRefsTable(_$LocalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.syncSharedMembers,
        aliasName: 'family_members__id__sync_shared_members__member_id',
      );

  $SyncSharedMembersProcessedTableManager get syncSharedMembersRefs {
    final manager = $SyncSharedMembersTableManager(
      $_db,
      $_db.syncSharedMembers,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _syncSharedMembersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $FamilyMembersFilterComposer
    extends Composer<_$LocalDatabase, FamilyMembers> {
  $FamilyMembersFilterComposer({
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

  ColumnFilters<String> get relation => $composableBuilder(
    column: $table.relation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chronicConditions => $composableBuilder(
    column: $table.chronicConditions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> appointmentsRefs(
    Expression<bool> Function($AppointmentsFilterComposer f) f,
  ) {
    final $AppointmentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appointments,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AppointmentsFilterComposer(
            $db: $db,
            $table: $db.appointments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> doctorQuestionsRefs(
    Expression<bool> Function($DoctorQuestionsFilterComposer f) f,
  ) {
    final $DoctorQuestionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doctorQuestions,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DoctorQuestionsFilterComposer(
            $db: $db,
            $table: $db.doctorQuestions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> symptomEntriesRefs(
    Expression<bool> Function($SymptomEntriesFilterComposer f) f,
  ) {
    final $SymptomEntriesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.symptomEntries,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SymptomEntriesFilterComposer(
            $db: $db,
            $table: $db.symptomEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> visitMediaRefs(
    Expression<bool> Function($VisitMediaFilterComposer f) f,
  ) {
    final $VisitMediaFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitMedia,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $VisitMediaFilterComposer(
            $db: $db,
            $table: $db.visitMedia,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> medicationsRefs(
    Expression<bool> Function($MedicationsFilterComposer f) f,
  ) {
    final $MedicationsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationsFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> doseRecordsRefs(
    Expression<bool> Function($DoseRecordsFilterComposer f) f,
  ) {
    final $DoseRecordsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doseRecords,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DoseRecordsFilterComposer(
            $db: $db,
            $table: $db.doseRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncSharedMembersRefs(
    Expression<bool> Function($SyncSharedMembersFilterComposer f) f,
  ) {
    final $SyncSharedMembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncSharedMembers,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SyncSharedMembersFilterComposer(
            $db: $db,
            $table: $db.syncSharedMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $FamilyMembersOrderingComposer
    extends Composer<_$LocalDatabase, FamilyMembers> {
  $FamilyMembersOrderingComposer({
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

  ColumnOrderings<String> get relation => $composableBuilder(
    column: $table.relation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chronicConditions => $composableBuilder(
    column: $table.chronicConditions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $FamilyMembersAnnotationComposer
    extends Composer<_$LocalDatabase, FamilyMembers> {
  $FamilyMembersAnnotationComposer({
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

  GeneratedColumn<String> get relation =>
      $composableBuilder(column: $table.relation, builder: (column) => column);

  GeneratedColumn<String> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get allergies =>
      $composableBuilder(column: $table.allergies, builder: (column) => column);

  GeneratedColumn<String> get chronicConditions => $composableBuilder(
    column: $table.chronicConditions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> appointmentsRefs<T extends Object>(
    Expression<T> Function($AppointmentsAnnotationComposer a) f,
  ) {
    final $AppointmentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appointments,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AppointmentsAnnotationComposer(
            $db: $db,
            $table: $db.appointments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> doctorQuestionsRefs<T extends Object>(
    Expression<T> Function($DoctorQuestionsAnnotationComposer a) f,
  ) {
    final $DoctorQuestionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doctorQuestions,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DoctorQuestionsAnnotationComposer(
            $db: $db,
            $table: $db.doctorQuestions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> symptomEntriesRefs<T extends Object>(
    Expression<T> Function($SymptomEntriesAnnotationComposer a) f,
  ) {
    final $SymptomEntriesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.symptomEntries,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SymptomEntriesAnnotationComposer(
            $db: $db,
            $table: $db.symptomEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> visitMediaRefs<T extends Object>(
    Expression<T> Function($VisitMediaAnnotationComposer a) f,
  ) {
    final $VisitMediaAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitMedia,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $VisitMediaAnnotationComposer(
            $db: $db,
            $table: $db.visitMedia,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> medicationsRefs<T extends Object>(
    Expression<T> Function($MedicationsAnnotationComposer a) f,
  ) {
    final $MedicationsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationsAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> doseRecordsRefs<T extends Object>(
    Expression<T> Function($DoseRecordsAnnotationComposer a) f,
  ) {
    final $DoseRecordsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.doseRecords,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DoseRecordsAnnotationComposer(
            $db: $db,
            $table: $db.doseRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syncSharedMembersRefs<T extends Object>(
    Expression<T> Function($SyncSharedMembersAnnotationComposer a) f,
  ) {
    final $SyncSharedMembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncSharedMembers,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SyncSharedMembersAnnotationComposer(
            $db: $db,
            $table: $db.syncSharedMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $FamilyMembersTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          FamilyMembers,
          FamilyMemberRow,
          $FamilyMembersFilterComposer,
          $FamilyMembersOrderingComposer,
          $FamilyMembersAnnotationComposer,
          $FamilyMembersCreateCompanionBuilder,
          $FamilyMembersUpdateCompanionBuilder,
          (FamilyMemberRow, $FamilyMembersReferences),
          FamilyMemberRow,
          PrefetchHooks Function({
            bool appointmentsRefs,
            bool doctorQuestionsRefs,
            bool symptomEntriesRefs,
            bool visitMediaRefs,
            bool medicationsRefs,
            bool doseRecordsRefs,
            bool syncSharedMembersRefs,
          })
        > {
  $FamilyMembersTableManager(_$LocalDatabase db, FamilyMembers table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $FamilyMembersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $FamilyMembersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $FamilyMembersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> relation = const Value.absent(),
                Value<String?> birthDate = const Value.absent(),
                Value<String> allergies = const Value.absent(),
                Value<String> chronicConditions = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyMembersCompanion(
                id: id,
                name: name,
                relation: relation,
                birthDate: birthDate,
                allergies: allergies,
                chronicConditions: chronicConditions,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String relation,
                Value<String?> birthDate = const Value.absent(),
                Value<String> allergies = const Value.absent(),
                Value<String> chronicConditions = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyMembersCompanion.insert(
                id: id,
                name: name,
                relation: relation,
                birthDate: birthDate,
                allergies: allergies,
                chronicConditions: chronicConditions,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $FamilyMembersReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                appointmentsRefs = false,
                doctorQuestionsRefs = false,
                symptomEntriesRefs = false,
                visitMediaRefs = false,
                medicationsRefs = false,
                doseRecordsRefs = false,
                syncSharedMembersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (appointmentsRefs) db.appointments,
                    if (doctorQuestionsRefs) db.doctorQuestions,
                    if (symptomEntriesRefs) db.symptomEntries,
                    if (visitMediaRefs) db.visitMedia,
                    if (medicationsRefs) db.medications,
                    if (doseRecordsRefs) db.doseRecords,
                    if (syncSharedMembersRefs) db.syncSharedMembers,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (appointmentsRefs)
                        await $_getPrefetchedData<
                          FamilyMemberRow,
                          FamilyMembers,
                          AppointmentRow
                        >(
                          currentTable: table,
                          referencedTable: $FamilyMembersReferences
                              ._appointmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $FamilyMembersReferences(
                                db,
                                table,
                                p0,
                              ).appointmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (doctorQuestionsRefs)
                        await $_getPrefetchedData<
                          FamilyMemberRow,
                          FamilyMembers,
                          DoctorQuestionRow
                        >(
                          currentTable: table,
                          referencedTable: $FamilyMembersReferences
                              ._doctorQuestionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $FamilyMembersReferences(
                                db,
                                table,
                                p0,
                              ).doctorQuestionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (symptomEntriesRefs)
                        await $_getPrefetchedData<
                          FamilyMemberRow,
                          FamilyMembers,
                          SymptomEntryRow
                        >(
                          currentTable: table,
                          referencedTable: $FamilyMembersReferences
                              ._symptomEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $FamilyMembersReferences(
                                db,
                                table,
                                p0,
                              ).symptomEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (visitMediaRefs)
                        await $_getPrefetchedData<
                          FamilyMemberRow,
                          FamilyMembers,
                          VisitMediaRow
                        >(
                          currentTable: table,
                          referencedTable: $FamilyMembersReferences
                              ._visitMediaRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $FamilyMembersReferences(
                                db,
                                table,
                                p0,
                              ).visitMediaRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (medicationsRefs)
                        await $_getPrefetchedData<
                          FamilyMemberRow,
                          FamilyMembers,
                          MedicationRow
                        >(
                          currentTable: table,
                          referencedTable: $FamilyMembersReferences
                              ._medicationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $FamilyMembersReferences(
                                db,
                                table,
                                p0,
                              ).medicationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (doseRecordsRefs)
                        await $_getPrefetchedData<
                          FamilyMemberRow,
                          FamilyMembers,
                          DoseRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $FamilyMembersReferences
                              ._doseRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $FamilyMembersReferences(
                                db,
                                table,
                                p0,
                              ).doseRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syncSharedMembersRefs)
                        await $_getPrefetchedData<
                          FamilyMemberRow,
                          FamilyMembers,
                          SyncSharedMemberRow
                        >(
                          currentTable: table,
                          referencedTable: $FamilyMembersReferences
                              ._syncSharedMembersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $FamilyMembersReferences(
                                db,
                                table,
                                p0,
                              ).syncSharedMembersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
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

typedef $FamilyMembersProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      FamilyMembers,
      FamilyMemberRow,
      $FamilyMembersFilterComposer,
      $FamilyMembersOrderingComposer,
      $FamilyMembersAnnotationComposer,
      $FamilyMembersCreateCompanionBuilder,
      $FamilyMembersUpdateCompanionBuilder,
      (FamilyMemberRow, $FamilyMembersReferences),
      FamilyMemberRow,
      PrefetchHooks Function({
        bool appointmentsRefs,
        bool doctorQuestionsRefs,
        bool symptomEntriesRefs,
        bool visitMediaRefs,
        bool medicationsRefs,
        bool doseRecordsRefs,
        bool syncSharedMembersRefs,
      })
    >;
typedef $AppointmentsCreateCompanionBuilder =
    AppointmentsCompanion Function({
      required String id,
      required String memberId,
      required String doctorName,
      required String scheduledAt,
      Value<String?> specialty,
      Value<String?> location,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $AppointmentsUpdateCompanionBuilder =
    AppointmentsCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> doctorName,
      Value<String> scheduledAt,
      Value<String?> specialty,
      Value<String?> location,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $AppointmentsReferences
    extends BaseReferences<_$LocalDatabase, Appointments, AppointmentRow> {
  $AppointmentsReferences(super.$_db, super.$_table, super.$_typedResult);

  static FamilyMembers _memberIdTable(_$LocalDatabase db) => db.familyMembers
      .createAlias('appointments__member_id__family_members__id');

  $FamilyMembersProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $FamilyMembersTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $AppointmentsFilterComposer
    extends Composer<_$LocalDatabase, Appointments> {
  $AppointmentsFilterComposer({
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

  ColumnFilters<String> get doctorName => $composableBuilder(
    column: $table.doctorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specialty => $composableBuilder(
    column: $table.specialty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $FamilyMembersFilterComposer get memberId {
    final $FamilyMembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AppointmentsOrderingComposer
    extends Composer<_$LocalDatabase, Appointments> {
  $AppointmentsOrderingComposer({
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

  ColumnOrderings<String> get doctorName => $composableBuilder(
    column: $table.doctorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specialty => $composableBuilder(
    column: $table.specialty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $FamilyMembersOrderingComposer get memberId {
    final $FamilyMembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AppointmentsAnnotationComposer
    extends Composer<_$LocalDatabase, Appointments> {
  $AppointmentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get doctorName => $composableBuilder(
    column: $table.doctorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get specialty =>
      $composableBuilder(column: $table.specialty, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $FamilyMembersAnnotationComposer get memberId {
    final $FamilyMembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AppointmentsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          Appointments,
          AppointmentRow,
          $AppointmentsFilterComposer,
          $AppointmentsOrderingComposer,
          $AppointmentsAnnotationComposer,
          $AppointmentsCreateCompanionBuilder,
          $AppointmentsUpdateCompanionBuilder,
          (AppointmentRow, $AppointmentsReferences),
          AppointmentRow,
          PrefetchHooks Function({bool memberId})
        > {
  $AppointmentsTableManager(_$LocalDatabase db, Appointments table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AppointmentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AppointmentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AppointmentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> doctorName = const Value.absent(),
                Value<String> scheduledAt = const Value.absent(),
                Value<String?> specialty = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppointmentsCompanion(
                id: id,
                memberId: memberId,
                doctorName: doctorName,
                scheduledAt: scheduledAt,
                specialty: specialty,
                location: location,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String doctorName,
                required String scheduledAt,
                Value<String?> specialty = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppointmentsCompanion.insert(
                id: id,
                memberId: memberId,
                doctorName: doctorName,
                scheduledAt: scheduledAt,
                specialty: specialty,
                location: location,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $AppointmentsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
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
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable: $AppointmentsReferences
                                    ._memberIdTable(db),
                                referencedColumn: $AppointmentsReferences
                                    ._memberIdTable(db)
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

typedef $AppointmentsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      Appointments,
      AppointmentRow,
      $AppointmentsFilterComposer,
      $AppointmentsOrderingComposer,
      $AppointmentsAnnotationComposer,
      $AppointmentsCreateCompanionBuilder,
      $AppointmentsUpdateCompanionBuilder,
      (AppointmentRow, $AppointmentsReferences),
      AppointmentRow,
      PrefetchHooks Function({bool memberId})
    >;
typedef $DoctorQuestionsCreateCompanionBuilder =
    DoctorQuestionsCompanion Function({
      required String id,
      required String memberId,
      Value<String?> appointmentId,
      required String questionText,
      required int createdAt,
      Value<int> isResolved,
      Value<String?> doctorAnswer,
      Value<int> rowid,
    });
typedef $DoctorQuestionsUpdateCompanionBuilder =
    DoctorQuestionsCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String?> appointmentId,
      Value<String> questionText,
      Value<int> createdAt,
      Value<int> isResolved,
      Value<String?> doctorAnswer,
      Value<int> rowid,
    });

final class $DoctorQuestionsReferences
    extends
        BaseReferences<_$LocalDatabase, DoctorQuestions, DoctorQuestionRow> {
  $DoctorQuestionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static FamilyMembers _memberIdTable(_$LocalDatabase db) => db.familyMembers
      .createAlias('doctor_questions__member_id__family_members__id');

  $FamilyMembersProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $FamilyMembersTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $DoctorQuestionsFilterComposer
    extends Composer<_$LocalDatabase, DoctorQuestions> {
  $DoctorQuestionsFilterComposer({
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

  ColumnFilters<String> get appointmentId => $composableBuilder(
    column: $table.appointmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isResolved => $composableBuilder(
    column: $table.isResolved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doctorAnswer => $composableBuilder(
    column: $table.doctorAnswer,
    builder: (column) => ColumnFilters(column),
  );

  $FamilyMembersFilterComposer get memberId {
    final $FamilyMembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DoctorQuestionsOrderingComposer
    extends Composer<_$LocalDatabase, DoctorQuestions> {
  $DoctorQuestionsOrderingComposer({
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

  ColumnOrderings<String> get appointmentId => $composableBuilder(
    column: $table.appointmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isResolved => $composableBuilder(
    column: $table.isResolved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doctorAnswer => $composableBuilder(
    column: $table.doctorAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  $FamilyMembersOrderingComposer get memberId {
    final $FamilyMembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DoctorQuestionsAnnotationComposer
    extends Composer<_$LocalDatabase, DoctorQuestions> {
  $DoctorQuestionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get appointmentId => $composableBuilder(
    column: $table.appointmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get isResolved => $composableBuilder(
    column: $table.isResolved,
    builder: (column) => column,
  );

  GeneratedColumn<String> get doctorAnswer => $composableBuilder(
    column: $table.doctorAnswer,
    builder: (column) => column,
  );

  $FamilyMembersAnnotationComposer get memberId {
    final $FamilyMembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DoctorQuestionsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          DoctorQuestions,
          DoctorQuestionRow,
          $DoctorQuestionsFilterComposer,
          $DoctorQuestionsOrderingComposer,
          $DoctorQuestionsAnnotationComposer,
          $DoctorQuestionsCreateCompanionBuilder,
          $DoctorQuestionsUpdateCompanionBuilder,
          (DoctorQuestionRow, $DoctorQuestionsReferences),
          DoctorQuestionRow,
          PrefetchHooks Function({bool memberId})
        > {
  $DoctorQuestionsTableManager(_$LocalDatabase db, DoctorQuestions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DoctorQuestionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DoctorQuestionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DoctorQuestionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String?> appointmentId = const Value.absent(),
                Value<String> questionText = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> isResolved = const Value.absent(),
                Value<String?> doctorAnswer = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DoctorQuestionsCompanion(
                id: id,
                memberId: memberId,
                appointmentId: appointmentId,
                questionText: questionText,
                createdAt: createdAt,
                isResolved: isResolved,
                doctorAnswer: doctorAnswer,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                Value<String?> appointmentId = const Value.absent(),
                required String questionText,
                required int createdAt,
                Value<int> isResolved = const Value.absent(),
                Value<String?> doctorAnswer = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DoctorQuestionsCompanion.insert(
                id: id,
                memberId: memberId,
                appointmentId: appointmentId,
                questionText: questionText,
                createdAt: createdAt,
                isResolved: isResolved,
                doctorAnswer: doctorAnswer,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $DoctorQuestionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
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
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable: $DoctorQuestionsReferences
                                    ._memberIdTable(db),
                                referencedColumn: $DoctorQuestionsReferences
                                    ._memberIdTable(db)
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

typedef $DoctorQuestionsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      DoctorQuestions,
      DoctorQuestionRow,
      $DoctorQuestionsFilterComposer,
      $DoctorQuestionsOrderingComposer,
      $DoctorQuestionsAnnotationComposer,
      $DoctorQuestionsCreateCompanionBuilder,
      $DoctorQuestionsUpdateCompanionBuilder,
      (DoctorQuestionRow, $DoctorQuestionsReferences),
      DoctorQuestionRow,
      PrefetchHooks Function({bool memberId})
    >;
typedef $SymptomEntriesCreateCompanionBuilder =
    SymptomEntriesCompanion Function({
      required String id,
      required String memberId,
      required String name,
      required String nameKey,
      required String startedAt,
      required int severity,
      Value<String> status,
      Value<int?> durationMicros,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $SymptomEntriesUpdateCompanionBuilder =
    SymptomEntriesCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> name,
      Value<String> nameKey,
      Value<String> startedAt,
      Value<int> severity,
      Value<String> status,
      Value<int?> durationMicros,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $SymptomEntriesReferences
    extends BaseReferences<_$LocalDatabase, SymptomEntries, SymptomEntryRow> {
  $SymptomEntriesReferences(super.$_db, super.$_table, super.$_typedResult);

  static FamilyMembers _memberIdTable(_$LocalDatabase db) => db.familyMembers
      .createAlias('symptom_entries__member_id__family_members__id');

  $FamilyMembersProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $FamilyMembersTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $SymptomEntriesFilterComposer
    extends Composer<_$LocalDatabase, SymptomEntries> {
  $SymptomEntriesFilterComposer({
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

  ColumnFilters<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMicros => $composableBuilder(
    column: $table.durationMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $FamilyMembersFilterComposer get memberId {
    final $FamilyMembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SymptomEntriesOrderingComposer
    extends Composer<_$LocalDatabase, SymptomEntries> {
  $SymptomEntriesOrderingComposer({
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

  ColumnOrderings<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMicros => $composableBuilder(
    column: $table.durationMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $FamilyMembersOrderingComposer get memberId {
    final $FamilyMembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SymptomEntriesAnnotationComposer
    extends Composer<_$LocalDatabase, SymptomEntries> {
  $SymptomEntriesAnnotationComposer({
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

  GeneratedColumn<String> get nameKey =>
      $composableBuilder(column: $table.nameKey, builder: (column) => column);

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get durationMicros => $composableBuilder(
    column: $table.durationMicros,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $FamilyMembersAnnotationComposer get memberId {
    final $FamilyMembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SymptomEntriesTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          SymptomEntries,
          SymptomEntryRow,
          $SymptomEntriesFilterComposer,
          $SymptomEntriesOrderingComposer,
          $SymptomEntriesAnnotationComposer,
          $SymptomEntriesCreateCompanionBuilder,
          $SymptomEntriesUpdateCompanionBuilder,
          (SymptomEntryRow, $SymptomEntriesReferences),
          SymptomEntryRow,
          PrefetchHooks Function({bool memberId})
        > {
  $SymptomEntriesTableManager(_$LocalDatabase db, SymptomEntries table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SymptomEntriesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SymptomEntriesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SymptomEntriesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameKey = const Value.absent(),
                Value<String> startedAt = const Value.absent(),
                Value<int> severity = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> durationMicros = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SymptomEntriesCompanion(
                id: id,
                memberId: memberId,
                name: name,
                nameKey: nameKey,
                startedAt: startedAt,
                severity: severity,
                status: status,
                durationMicros: durationMicros,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String name,
                required String nameKey,
                required String startedAt,
                required int severity,
                Value<String> status = const Value.absent(),
                Value<int?> durationMicros = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SymptomEntriesCompanion.insert(
                id: id,
                memberId: memberId,
                name: name,
                nameKey: nameKey,
                startedAt: startedAt,
                severity: severity,
                status: status,
                durationMicros: durationMicros,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $SymptomEntriesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
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
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable: $SymptomEntriesReferences
                                    ._memberIdTable(db),
                                referencedColumn: $SymptomEntriesReferences
                                    ._memberIdTable(db)
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

typedef $SymptomEntriesProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      SymptomEntries,
      SymptomEntryRow,
      $SymptomEntriesFilterComposer,
      $SymptomEntriesOrderingComposer,
      $SymptomEntriesAnnotationComposer,
      $SymptomEntriesCreateCompanionBuilder,
      $SymptomEntriesUpdateCompanionBuilder,
      (SymptomEntryRow, $SymptomEntriesReferences),
      SymptomEntryRow,
      PrefetchHooks Function({bool memberId})
    >;
typedef $VisitMediaCreateCompanionBuilder =
    VisitMediaCompanion Function({
      required String id,
      required String memberId,
      required String appointmentId,
      required String kind,
      required String fileName,
      required int byteSize,
      Value<String?> description,
      required int createdAt,
      Value<int> rowid,
    });
typedef $VisitMediaUpdateCompanionBuilder =
    VisitMediaCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> appointmentId,
      Value<String> kind,
      Value<String> fileName,
      Value<int> byteSize,
      Value<String?> description,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $VisitMediaReferences
    extends BaseReferences<_$LocalDatabase, VisitMedia, VisitMediaRow> {
  $VisitMediaReferences(super.$_db, super.$_table, super.$_typedResult);

  static FamilyMembers _memberIdTable(_$LocalDatabase db) => db.familyMembers
      .createAlias('visit_media__member_id__family_members__id');

  $FamilyMembersProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $FamilyMembersTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $VisitMediaFilterComposer extends Composer<_$LocalDatabase, VisitMedia> {
  $VisitMediaFilterComposer({
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

  ColumnFilters<String> get appointmentId => $composableBuilder(
    column: $table.appointmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $FamilyMembersFilterComposer get memberId {
    final $FamilyMembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $VisitMediaOrderingComposer
    extends Composer<_$LocalDatabase, VisitMedia> {
  $VisitMediaOrderingComposer({
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

  ColumnOrderings<String> get appointmentId => $composableBuilder(
    column: $table.appointmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $FamilyMembersOrderingComposer get memberId {
    final $FamilyMembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $VisitMediaAnnotationComposer
    extends Composer<_$LocalDatabase, VisitMedia> {
  $VisitMediaAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get appointmentId => $composableBuilder(
    column: $table.appointmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $FamilyMembersAnnotationComposer get memberId {
    final $FamilyMembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $VisitMediaTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          VisitMedia,
          VisitMediaRow,
          $VisitMediaFilterComposer,
          $VisitMediaOrderingComposer,
          $VisitMediaAnnotationComposer,
          $VisitMediaCreateCompanionBuilder,
          $VisitMediaUpdateCompanionBuilder,
          (VisitMediaRow, $VisitMediaReferences),
          VisitMediaRow,
          PrefetchHooks Function({bool memberId})
        > {
  $VisitMediaTableManager(_$LocalDatabase db, VisitMedia table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $VisitMediaFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $VisitMediaOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $VisitMediaAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> appointmentId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitMediaCompanion(
                id: id,
                memberId: memberId,
                appointmentId: appointmentId,
                kind: kind,
                fileName: fileName,
                byteSize: byteSize,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String appointmentId,
                required String kind,
                required String fileName,
                required int byteSize,
                Value<String?> description = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => VisitMediaCompanion.insert(
                id: id,
                memberId: memberId,
                appointmentId: appointmentId,
                kind: kind,
                fileName: fileName,
                byteSize: byteSize,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $VisitMediaReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
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
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable: $VisitMediaReferences
                                    ._memberIdTable(db),
                                referencedColumn: $VisitMediaReferences
                                    ._memberIdTable(db)
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

typedef $VisitMediaProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      VisitMedia,
      VisitMediaRow,
      $VisitMediaFilterComposer,
      $VisitMediaOrderingComposer,
      $VisitMediaAnnotationComposer,
      $VisitMediaCreateCompanionBuilder,
      $VisitMediaUpdateCompanionBuilder,
      (VisitMediaRow, $VisitMediaReferences),
      VisitMediaRow,
      PrefetchHooks Function({bool memberId})
    >;
typedef $MedicationsCreateCompanionBuilder =
    MedicationsCompanion Function({
      required String id,
      required String memberId,
      required String name,
      required String dose,
      Value<String?> instructions,
      required String reminderTimes,
      required String startDate,
      Value<String?> endDate,
      Value<int> rowid,
    });
typedef $MedicationsUpdateCompanionBuilder =
    MedicationsCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> name,
      Value<String> dose,
      Value<String?> instructions,
      Value<String> reminderTimes,
      Value<String> startDate,
      Value<String?> endDate,
      Value<int> rowid,
    });

final class $MedicationsReferences
    extends BaseReferences<_$LocalDatabase, Medications, MedicationRow> {
  $MedicationsReferences(super.$_db, super.$_table, super.$_typedResult);

  static FamilyMembers _memberIdTable(_$LocalDatabase db) => db.familyMembers
      .createAlias('medications__member_id__family_members__id');

  $FamilyMembersProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $FamilyMembersTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $MedicationsFilterComposer
    extends Composer<_$LocalDatabase, Medications> {
  $MedicationsFilterComposer({
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

  ColumnFilters<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTimes => $composableBuilder(
    column: $table.reminderTimes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  $FamilyMembersFilterComposer get memberId {
    final $FamilyMembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MedicationsOrderingComposer
    extends Composer<_$LocalDatabase, Medications> {
  $MedicationsOrderingComposer({
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

  ColumnOrderings<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTimes => $composableBuilder(
    column: $table.reminderTimes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  $FamilyMembersOrderingComposer get memberId {
    final $FamilyMembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MedicationsAnnotationComposer
    extends Composer<_$LocalDatabase, Medications> {
  $MedicationsAnnotationComposer({
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

  GeneratedColumn<String> get dose =>
      $composableBuilder(column: $table.dose, builder: (column) => column);

  GeneratedColumn<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderTimes => $composableBuilder(
    column: $table.reminderTimes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  $FamilyMembersAnnotationComposer get memberId {
    final $FamilyMembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MedicationsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          Medications,
          MedicationRow,
          $MedicationsFilterComposer,
          $MedicationsOrderingComposer,
          $MedicationsAnnotationComposer,
          $MedicationsCreateCompanionBuilder,
          $MedicationsUpdateCompanionBuilder,
          (MedicationRow, $MedicationsReferences),
          MedicationRow,
          PrefetchHooks Function({bool memberId})
        > {
  $MedicationsTableManager(_$LocalDatabase db, Medications table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MedicationsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MedicationsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MedicationsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> dose = const Value.absent(),
                Value<String?> instructions = const Value.absent(),
                Value<String> reminderTimes = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion(
                id: id,
                memberId: memberId,
                name: name,
                dose: dose,
                instructions: instructions,
                reminderTimes: reminderTimes,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String name,
                required String dose,
                Value<String?> instructions = const Value.absent(),
                required String reminderTimes,
                required String startDate,
                Value<String?> endDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion.insert(
                id: id,
                memberId: memberId,
                name: name,
                dose: dose,
                instructions: instructions,
                reminderTimes: reminderTimes,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $MedicationsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
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
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable: $MedicationsReferences
                                    ._memberIdTable(db),
                                referencedColumn: $MedicationsReferences
                                    ._memberIdTable(db)
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

typedef $MedicationsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      Medications,
      MedicationRow,
      $MedicationsFilterComposer,
      $MedicationsOrderingComposer,
      $MedicationsAnnotationComposer,
      $MedicationsCreateCompanionBuilder,
      $MedicationsUpdateCompanionBuilder,
      (MedicationRow, $MedicationsReferences),
      MedicationRow,
      PrefetchHooks Function({bool memberId})
    >;
typedef $DoseRecordsCreateCompanionBuilder =
    DoseRecordsCompanion Function({
      required String id,
      required String memberId,
      required String medicationId,
      required String scheduledAt,
      required String status,
      required int recordedAt,
      Value<int> rowid,
    });
typedef $DoseRecordsUpdateCompanionBuilder =
    DoseRecordsCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> medicationId,
      Value<String> scheduledAt,
      Value<String> status,
      Value<int> recordedAt,
      Value<int> rowid,
    });

final class $DoseRecordsReferences
    extends BaseReferences<_$LocalDatabase, DoseRecords, DoseRecordRow> {
  $DoseRecordsReferences(super.$_db, super.$_table, super.$_typedResult);

  static FamilyMembers _memberIdTable(_$LocalDatabase db) => db.familyMembers
      .createAlias('dose_records__member_id__family_members__id');

  $FamilyMembersProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $FamilyMembersTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $DoseRecordsFilterComposer
    extends Composer<_$LocalDatabase, DoseRecords> {
  $DoseRecordsFilterComposer({
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

  ColumnFilters<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  $FamilyMembersFilterComposer get memberId {
    final $FamilyMembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DoseRecordsOrderingComposer
    extends Composer<_$LocalDatabase, DoseRecords> {
  $DoseRecordsOrderingComposer({
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

  ColumnOrderings<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $FamilyMembersOrderingComposer get memberId {
    final $FamilyMembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DoseRecordsAnnotationComposer
    extends Composer<_$LocalDatabase, DoseRecords> {
  $DoseRecordsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  $FamilyMembersAnnotationComposer get memberId {
    final $FamilyMembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DoseRecordsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          DoseRecords,
          DoseRecordRow,
          $DoseRecordsFilterComposer,
          $DoseRecordsOrderingComposer,
          $DoseRecordsAnnotationComposer,
          $DoseRecordsCreateCompanionBuilder,
          $DoseRecordsUpdateCompanionBuilder,
          (DoseRecordRow, $DoseRecordsReferences),
          DoseRecordRow,
          PrefetchHooks Function({bool memberId})
        > {
  $DoseRecordsTableManager(_$LocalDatabase db, DoseRecords table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DoseRecordsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DoseRecordsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DoseRecordsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<String> scheduledAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DoseRecordsCompanion(
                id: id,
                memberId: memberId,
                medicationId: medicationId,
                scheduledAt: scheduledAt,
                status: status,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String medicationId,
                required String scheduledAt,
                required String status,
                required int recordedAt,
                Value<int> rowid = const Value.absent(),
              }) => DoseRecordsCompanion.insert(
                id: id,
                memberId: memberId,
                medicationId: medicationId,
                scheduledAt: scheduledAt,
                status: status,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $DoseRecordsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
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
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable: $DoseRecordsReferences
                                    ._memberIdTable(db),
                                referencedColumn: $DoseRecordsReferences
                                    ._memberIdTable(db)
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

typedef $DoseRecordsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      DoseRecords,
      DoseRecordRow,
      $DoseRecordsFilterComposer,
      $DoseRecordsOrderingComposer,
      $DoseRecordsAnnotationComposer,
      $DoseRecordsCreateCompanionBuilder,
      $DoseRecordsUpdateCompanionBuilder,
      (DoseRecordRow, $DoseRecordsReferences),
      DoseRecordRow,
      PrefetchHooks Function({bool memberId})
    >;
typedef $SyncSettingsCreateCompanionBuilder =
    SyncSettingsCompanion Function({
      Value<int> id,
      required String deviceId,
      Value<String?> householdId,
      Value<String?> accountUid,
      Value<String?> role,
      Value<String> state,
      Value<String?> inviteId,
      Value<int?> lastSyncAt,
      Value<int> nextSeq,
      Value<int> applying,
    });
typedef $SyncSettingsUpdateCompanionBuilder =
    SyncSettingsCompanion Function({
      Value<int> id,
      Value<String> deviceId,
      Value<String?> householdId,
      Value<String?> accountUid,
      Value<String?> role,
      Value<String> state,
      Value<String?> inviteId,
      Value<int?> lastSyncAt,
      Value<int> nextSeq,
      Value<int> applying,
    });

class $SyncSettingsFilterComposer
    extends Composer<_$LocalDatabase, SyncSettings> {
  $SyncSettingsFilterComposer({
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

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountUid => $composableBuilder(
    column: $table.accountUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inviteId => $composableBuilder(
    column: $table.inviteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextSeq => $composableBuilder(
    column: $table.nextSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get applying => $composableBuilder(
    column: $table.applying,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncSettingsOrderingComposer
    extends Composer<_$LocalDatabase, SyncSettings> {
  $SyncSettingsOrderingComposer({
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

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountUid => $composableBuilder(
    column: $table.accountUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inviteId => $composableBuilder(
    column: $table.inviteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextSeq => $composableBuilder(
    column: $table.nextSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get applying => $composableBuilder(
    column: $table.applying,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncSettingsAnnotationComposer
    extends Composer<_$LocalDatabase, SyncSettings> {
  $SyncSettingsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountUid => $composableBuilder(
    column: $table.accountUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get inviteId =>
      $composableBuilder(column: $table.inviteId, builder: (column) => column);

  GeneratedColumn<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextSeq =>
      $composableBuilder(column: $table.nextSeq, builder: (column) => column);

  GeneratedColumn<int> get applying =>
      $composableBuilder(column: $table.applying, builder: (column) => column);
}

class $SyncSettingsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          SyncSettings,
          SyncSettingsRow,
          $SyncSettingsFilterComposer,
          $SyncSettingsOrderingComposer,
          $SyncSettingsAnnotationComposer,
          $SyncSettingsCreateCompanionBuilder,
          $SyncSettingsUpdateCompanionBuilder,
          (
            SyncSettingsRow,
            BaseReferences<_$LocalDatabase, SyncSettings, SyncSettingsRow>,
          ),
          SyncSettingsRow,
          PrefetchHooks Function()
        > {
  $SyncSettingsTableManager(_$LocalDatabase db, SyncSettings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncSettingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncSettingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncSettingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String?> householdId = const Value.absent(),
                Value<String?> accountUid = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> inviteId = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<int> nextSeq = const Value.absent(),
                Value<int> applying = const Value.absent(),
              }) => SyncSettingsCompanion(
                id: id,
                deviceId: deviceId,
                householdId: householdId,
                accountUid: accountUid,
                role: role,
                state: state,
                inviteId: inviteId,
                lastSyncAt: lastSyncAt,
                nextSeq: nextSeq,
                applying: applying,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deviceId,
                Value<String?> householdId = const Value.absent(),
                Value<String?> accountUid = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> inviteId = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<int> nextSeq = const Value.absent(),
                Value<int> applying = const Value.absent(),
              }) => SyncSettingsCompanion.insert(
                id: id,
                deviceId: deviceId,
                householdId: householdId,
                accountUid: accountUid,
                role: role,
                state: state,
                inviteId: inviteId,
                lastSyncAt: lastSyncAt,
                nextSeq: nextSeq,
                applying: applying,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncSettingsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      SyncSettings,
      SyncSettingsRow,
      $SyncSettingsFilterComposer,
      $SyncSettingsOrderingComposer,
      $SyncSettingsAnnotationComposer,
      $SyncSettingsCreateCompanionBuilder,
      $SyncSettingsUpdateCompanionBuilder,
      (
        SyncSettingsRow,
        BaseReferences<_$LocalDatabase, SyncSettings, SyncSettingsRow>,
      ),
      SyncSettingsRow,
      PrefetchHooks Function()
    >;
typedef $SyncSharedMembersCreateCompanionBuilder =
    SyncSharedMembersCompanion Function({
      required String memberId,
      required int sharedAt,
      Value<int> rowid,
    });
typedef $SyncSharedMembersUpdateCompanionBuilder =
    SyncSharedMembersCompanion Function({
      Value<String> memberId,
      Value<int> sharedAt,
      Value<int> rowid,
    });

final class $SyncSharedMembersReferences
    extends
        BaseReferences<
          _$LocalDatabase,
          SyncSharedMembers,
          SyncSharedMemberRow
        > {
  $SyncSharedMembersReferences(super.$_db, super.$_table, super.$_typedResult);

  static FamilyMembers _memberIdTable(_$LocalDatabase db) => db.familyMembers
      .createAlias('sync_shared_members__member_id__family_members__id');

  $FamilyMembersProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $FamilyMembersTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $SyncSharedMembersFilterComposer
    extends Composer<_$LocalDatabase, SyncSharedMembers> {
  $SyncSharedMembersFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sharedAt => $composableBuilder(
    column: $table.sharedAt,
    builder: (column) => ColumnFilters(column),
  );

  $FamilyMembersFilterComposer get memberId {
    final $FamilyMembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SyncSharedMembersOrderingComposer
    extends Composer<_$LocalDatabase, SyncSharedMembers> {
  $SyncSharedMembersOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sharedAt => $composableBuilder(
    column: $table.sharedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $FamilyMembersOrderingComposer get memberId {
    final $FamilyMembersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SyncSharedMembersAnnotationComposer
    extends Composer<_$LocalDatabase, SyncSharedMembers> {
  $SyncSharedMembersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sharedAt =>
      $composableBuilder(column: $table.sharedAt, builder: (column) => column);

  $FamilyMembersAnnotationComposer get memberId {
    final $FamilyMembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FamilyMembersAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SyncSharedMembersTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          SyncSharedMembers,
          SyncSharedMemberRow,
          $SyncSharedMembersFilterComposer,
          $SyncSharedMembersOrderingComposer,
          $SyncSharedMembersAnnotationComposer,
          $SyncSharedMembersCreateCompanionBuilder,
          $SyncSharedMembersUpdateCompanionBuilder,
          (SyncSharedMemberRow, $SyncSharedMembersReferences),
          SyncSharedMemberRow,
          PrefetchHooks Function({bool memberId})
        > {
  $SyncSharedMembersTableManager(_$LocalDatabase db, SyncSharedMembers table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncSharedMembersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncSharedMembersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncSharedMembersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> memberId = const Value.absent(),
                Value<int> sharedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncSharedMembersCompanion(
                memberId: memberId,
                sharedAt: sharedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String memberId,
                required int sharedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncSharedMembersCompanion.insert(
                memberId: memberId,
                sharedAt: sharedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $SyncSharedMembersReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
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
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable: $SyncSharedMembersReferences
                                    ._memberIdTable(db),
                                referencedColumn: $SyncSharedMembersReferences
                                    ._memberIdTable(db)
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

typedef $SyncSharedMembersProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      SyncSharedMembers,
      SyncSharedMemberRow,
      $SyncSharedMembersFilterComposer,
      $SyncSharedMembersOrderingComposer,
      $SyncSharedMembersAnnotationComposer,
      $SyncSharedMembersCreateCompanionBuilder,
      $SyncSharedMembersUpdateCompanionBuilder,
      (SyncSharedMemberRow, $SyncSharedMembersReferences),
      SyncSharedMemberRow,
      PrefetchHooks Function({bool memberId})
    >;
typedef $SyncRecordsCreateCompanionBuilder =
    SyncRecordsCompanion Function({
      required String kind,
      required String syncId,
      required String localId,
      required String memberId,
      required String versionVector,
      required int updatedAt,
      required String updatedBy,
      required int deleted,
      Value<String?> base,
      Value<int> parked,
      Value<int> rowid,
    });
typedef $SyncRecordsUpdateCompanionBuilder =
    SyncRecordsCompanion Function({
      Value<String> kind,
      Value<String> syncId,
      Value<String> localId,
      Value<String> memberId,
      Value<String> versionVector,
      Value<int> updatedAt,
      Value<String> updatedBy,
      Value<int> deleted,
      Value<String?> base,
      Value<int> parked,
      Value<int> rowid,
    });

class $SyncRecordsFilterComposer
    extends Composer<_$LocalDatabase, SyncRecords> {
  $SyncRecordsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versionVector => $composableBuilder(
    column: $table.versionVector,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get base => $composableBuilder(
    column: $table.base,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parked => $composableBuilder(
    column: $table.parked,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncRecordsOrderingComposer
    extends Composer<_$LocalDatabase, SyncRecords> {
  $SyncRecordsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versionVector => $composableBuilder(
    column: $table.versionVector,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get base => $composableBuilder(
    column: $table.base,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parked => $composableBuilder(
    column: $table.parked,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncRecordsAnnotationComposer
    extends Composer<_$LocalDatabase, SyncRecords> {
  $SyncRecordsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get versionVector => $composableBuilder(
    column: $table.versionVector,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<int> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get base =>
      $composableBuilder(column: $table.base, builder: (column) => column);

  GeneratedColumn<int> get parked =>
      $composableBuilder(column: $table.parked, builder: (column) => column);
}

class $SyncRecordsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          SyncRecords,
          SyncRecordRow,
          $SyncRecordsFilterComposer,
          $SyncRecordsOrderingComposer,
          $SyncRecordsAnnotationComposer,
          $SyncRecordsCreateCompanionBuilder,
          $SyncRecordsUpdateCompanionBuilder,
          (
            SyncRecordRow,
            BaseReferences<_$LocalDatabase, SyncRecords, SyncRecordRow>,
          ),
          SyncRecordRow,
          PrefetchHooks Function()
        > {
  $SyncRecordsTableManager(_$LocalDatabase db, SyncRecords table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncRecordsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncRecordsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncRecordsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> versionVector = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<int> deleted = const Value.absent(),
                Value<String?> base = const Value.absent(),
                Value<int> parked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRecordsCompanion(
                kind: kind,
                syncId: syncId,
                localId: localId,
                memberId: memberId,
                versionVector: versionVector,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deleted: deleted,
                base: base,
                parked: parked,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String syncId,
                required String localId,
                required String memberId,
                required String versionVector,
                required int updatedAt,
                required String updatedBy,
                required int deleted,
                Value<String?> base = const Value.absent(),
                Value<int> parked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRecordsCompanion.insert(
                kind: kind,
                syncId: syncId,
                localId: localId,
                memberId: memberId,
                versionVector: versionVector,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deleted: deleted,
                base: base,
                parked: parked,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncRecordsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      SyncRecords,
      SyncRecordRow,
      $SyncRecordsFilterComposer,
      $SyncRecordsOrderingComposer,
      $SyncRecordsAnnotationComposer,
      $SyncRecordsCreateCompanionBuilder,
      $SyncRecordsUpdateCompanionBuilder,
      (
        SyncRecordRow,
        BaseReferences<_$LocalDatabase, SyncRecords, SyncRecordRow>,
      ),
      SyncRecordRow,
      PrefetchHooks Function()
    >;
typedef $SyncPendingCreateCompanionBuilder =
    SyncPendingCompanion Function({
      required String kind,
      required String syncId,
      required String localId,
      Value<int> changeCount,
      Value<int> rowid,
    });
typedef $SyncPendingUpdateCompanionBuilder =
    SyncPendingCompanion Function({
      Value<String> kind,
      Value<String> syncId,
      Value<String> localId,
      Value<int> changeCount,
      Value<int> rowid,
    });

class $SyncPendingFilterComposer
    extends Composer<_$LocalDatabase, SyncPending> {
  $SyncPendingFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeCount => $composableBuilder(
    column: $table.changeCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncPendingOrderingComposer
    extends Composer<_$LocalDatabase, SyncPending> {
  $SyncPendingOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeCount => $composableBuilder(
    column: $table.changeCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncPendingAnnotationComposer
    extends Composer<_$LocalDatabase, SyncPending> {
  $SyncPendingAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get changeCount => $composableBuilder(
    column: $table.changeCount,
    builder: (column) => column,
  );
}

class $SyncPendingTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          SyncPending,
          SyncPendingRow,
          $SyncPendingFilterComposer,
          $SyncPendingOrderingComposer,
          $SyncPendingAnnotationComposer,
          $SyncPendingCreateCompanionBuilder,
          $SyncPendingUpdateCompanionBuilder,
          (
            SyncPendingRow,
            BaseReferences<_$LocalDatabase, SyncPending, SyncPendingRow>,
          ),
          SyncPendingRow,
          PrefetchHooks Function()
        > {
  $SyncPendingTableManager(_$LocalDatabase db, SyncPending table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncPendingFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncPendingOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncPendingAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<int> changeCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncPendingCompanion(
                kind: kind,
                syncId: syncId,
                localId: localId,
                changeCount: changeCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String syncId,
                required String localId,
                Value<int> changeCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncPendingCompanion.insert(
                kind: kind,
                syncId: syncId,
                localId: localId,
                changeCount: changeCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncPendingProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      SyncPending,
      SyncPendingRow,
      $SyncPendingFilterComposer,
      $SyncPendingOrderingComposer,
      $SyncPendingAnnotationComposer,
      $SyncPendingCreateCompanionBuilder,
      $SyncPendingUpdateCompanionBuilder,
      (
        SyncPendingRow,
        BaseReferences<_$LocalDatabase, SyncPending, SyncPendingRow>,
      ),
      SyncPendingRow,
      PrefetchHooks Function()
    >;
typedef $SyncConflictsCreateCompanionBuilder =
    SyncConflictsCompanion Function({
      required String kind,
      required String syncId,
      required String localId,
      required String memberId,
      required String reason,
      Value<String?> local,
      Value<String?> remote,
      required String remoteVector,
      required int remoteUpdatedAt,
      required String remoteUpdatedBy,
      Value<String> fields,
      required int detectedAt,
      Value<int> rowid,
    });
typedef $SyncConflictsUpdateCompanionBuilder =
    SyncConflictsCompanion Function({
      Value<String> kind,
      Value<String> syncId,
      Value<String> localId,
      Value<String> memberId,
      Value<String> reason,
      Value<String?> local,
      Value<String?> remote,
      Value<String> remoteVector,
      Value<int> remoteUpdatedAt,
      Value<String> remoteUpdatedBy,
      Value<String> fields,
      Value<int> detectedAt,
      Value<int> rowid,
    });

class $SyncConflictsFilterComposer
    extends Composer<_$LocalDatabase, SyncConflicts> {
  $SyncConflictsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get local => $composableBuilder(
    column: $table.local,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remote => $composableBuilder(
    column: $table.remote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteVector => $composableBuilder(
    column: $table.remoteVector,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUpdatedBy => $composableBuilder(
    column: $table.remoteUpdatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fields => $composableBuilder(
    column: $table.fields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncConflictsOrderingComposer
    extends Composer<_$LocalDatabase, SyncConflicts> {
  $SyncConflictsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get local => $composableBuilder(
    column: $table.local,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remote => $composableBuilder(
    column: $table.remote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteVector => $composableBuilder(
    column: $table.remoteVector,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUpdatedBy => $composableBuilder(
    column: $table.remoteUpdatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fields => $composableBuilder(
    column: $table.fields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncConflictsAnnotationComposer
    extends Composer<_$LocalDatabase, SyncConflicts> {
  $SyncConflictsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get local =>
      $composableBuilder(column: $table.local, builder: (column) => column);

  GeneratedColumn<String> get remote =>
      $composableBuilder(column: $table.remote, builder: (column) => column);

  GeneratedColumn<String> get remoteVector => $composableBuilder(
    column: $table.remoteVector,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteUpdatedBy => $composableBuilder(
    column: $table.remoteUpdatedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fields =>
      $composableBuilder(column: $table.fields, builder: (column) => column);

  GeneratedColumn<int> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => column,
  );
}

class $SyncConflictsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          SyncConflicts,
          SyncConflictRow,
          $SyncConflictsFilterComposer,
          $SyncConflictsOrderingComposer,
          $SyncConflictsAnnotationComposer,
          $SyncConflictsCreateCompanionBuilder,
          $SyncConflictsUpdateCompanionBuilder,
          (
            SyncConflictRow,
            BaseReferences<_$LocalDatabase, SyncConflicts, SyncConflictRow>,
          ),
          SyncConflictRow,
          PrefetchHooks Function()
        > {
  $SyncConflictsTableManager(_$LocalDatabase db, SyncConflicts table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncConflictsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncConflictsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncConflictsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> syncId = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> local = const Value.absent(),
                Value<String?> remote = const Value.absent(),
                Value<String> remoteVector = const Value.absent(),
                Value<int> remoteUpdatedAt = const Value.absent(),
                Value<String> remoteUpdatedBy = const Value.absent(),
                Value<String> fields = const Value.absent(),
                Value<int> detectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncConflictsCompanion(
                kind: kind,
                syncId: syncId,
                localId: localId,
                memberId: memberId,
                reason: reason,
                local: local,
                remote: remote,
                remoteVector: remoteVector,
                remoteUpdatedAt: remoteUpdatedAt,
                remoteUpdatedBy: remoteUpdatedBy,
                fields: fields,
                detectedAt: detectedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String syncId,
                required String localId,
                required String memberId,
                required String reason,
                Value<String?> local = const Value.absent(),
                Value<String?> remote = const Value.absent(),
                required String remoteVector,
                required int remoteUpdatedAt,
                required String remoteUpdatedBy,
                Value<String> fields = const Value.absent(),
                required int detectedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncConflictsCompanion.insert(
                kind: kind,
                syncId: syncId,
                localId: localId,
                memberId: memberId,
                reason: reason,
                local: local,
                remote: remote,
                remoteVector: remoteVector,
                remoteUpdatedAt: remoteUpdatedAt,
                remoteUpdatedBy: remoteUpdatedBy,
                fields: fields,
                detectedAt: detectedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncConflictsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      SyncConflicts,
      SyncConflictRow,
      $SyncConflictsFilterComposer,
      $SyncConflictsOrderingComposer,
      $SyncConflictsAnnotationComposer,
      $SyncConflictsCreateCompanionBuilder,
      $SyncConflictsUpdateCompanionBuilder,
      (
        SyncConflictRow,
        BaseReferences<_$LocalDatabase, SyncConflicts, SyncConflictRow>,
      ),
      SyncConflictRow,
      PrefetchHooks Function()
    >;
typedef $SyncCursorsCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String deviceId,
      required int lastSeq,
      Value<int> rowid,
    });
typedef $SyncCursorsUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> deviceId,
      Value<int> lastSeq,
      Value<int> rowid,
    });

class $SyncCursorsFilterComposer
    extends Composer<_$LocalDatabase, SyncCursors> {
  $SyncCursorsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeq => $composableBuilder(
    column: $table.lastSeq,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncCursorsOrderingComposer
    extends Composer<_$LocalDatabase, SyncCursors> {
  $SyncCursorsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeq => $composableBuilder(
    column: $table.lastSeq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncCursorsAnnotationComposer
    extends Composer<_$LocalDatabase, SyncCursors> {
  $SyncCursorsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get lastSeq =>
      $composableBuilder(column: $table.lastSeq, builder: (column) => column);
}

class $SyncCursorsTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          SyncCursors,
          SyncCursorRow,
          $SyncCursorsFilterComposer,
          $SyncCursorsOrderingComposer,
          $SyncCursorsAnnotationComposer,
          $SyncCursorsCreateCompanionBuilder,
          $SyncCursorsUpdateCompanionBuilder,
          (
            SyncCursorRow,
            BaseReferences<_$LocalDatabase, SyncCursors, SyncCursorRow>,
          ),
          SyncCursorRow,
          PrefetchHooks Function()
        > {
  $SyncCursorsTableManager(_$LocalDatabase db, SyncCursors table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncCursorsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncCursorsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncCursorsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> lastSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion(
                deviceId: deviceId,
                lastSeq: lastSeq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int lastSeq,
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                deviceId: deviceId,
                lastSeq: lastSeq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncCursorsProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      SyncCursors,
      SyncCursorRow,
      $SyncCursorsFilterComposer,
      $SyncCursorsOrderingComposer,
      $SyncCursorsAnnotationComposer,
      $SyncCursorsCreateCompanionBuilder,
      $SyncCursorsUpdateCompanionBuilder,
      (
        SyncCursorRow,
        BaseReferences<_$LocalDatabase, SyncCursors, SyncCursorRow>,
      ),
      SyncCursorRow,
      PrefetchHooks Function()
    >;
typedef $SyncKnownMembersCreateCompanionBuilder =
    SyncKnownMembersCompanion Function({
      required String uid,
      required String publicKey,
      required String role,
      Value<String?> label,
      Value<int> rowid,
    });
typedef $SyncKnownMembersUpdateCompanionBuilder =
    SyncKnownMembersCompanion Function({
      Value<String> uid,
      Value<String> publicKey,
      Value<String> role,
      Value<String?> label,
      Value<int> rowid,
    });

class $SyncKnownMembersFilterComposer
    extends Composer<_$LocalDatabase, SyncKnownMembers> {
  $SyncKnownMembersFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncKnownMembersOrderingComposer
    extends Composer<_$LocalDatabase, SyncKnownMembers> {
  $SyncKnownMembersOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncKnownMembersAnnotationComposer
    extends Composer<_$LocalDatabase, SyncKnownMembers> {
  $SyncKnownMembersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);
}

class $SyncKnownMembersTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          SyncKnownMembers,
          SyncKnownMemberRow,
          $SyncKnownMembersFilterComposer,
          $SyncKnownMembersOrderingComposer,
          $SyncKnownMembersAnnotationComposer,
          $SyncKnownMembersCreateCompanionBuilder,
          $SyncKnownMembersUpdateCompanionBuilder,
          (
            SyncKnownMemberRow,
            BaseReferences<
              _$LocalDatabase,
              SyncKnownMembers,
              SyncKnownMemberRow
            >,
          ),
          SyncKnownMemberRow,
          PrefetchHooks Function()
        > {
  $SyncKnownMembersTableManager(_$LocalDatabase db, SyncKnownMembers table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncKnownMembersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncKnownMembersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncKnownMembersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> publicKey = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncKnownMembersCompanion(
                uid: uid,
                publicKey: publicKey,
                role: role,
                label: label,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String publicKey,
                required String role,
                Value<String?> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncKnownMembersCompanion.insert(
                uid: uid,
                publicKey: publicKey,
                role: role,
                label: label,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncKnownMembersProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      SyncKnownMembers,
      SyncKnownMemberRow,
      $SyncKnownMembersFilterComposer,
      $SyncKnownMembersOrderingComposer,
      $SyncKnownMembersAnnotationComposer,
      $SyncKnownMembersCreateCompanionBuilder,
      $SyncKnownMembersUpdateCompanionBuilder,
      (
        SyncKnownMemberRow,
        BaseReferences<_$LocalDatabase, SyncKnownMembers, SyncKnownMemberRow>,
      ),
      SyncKnownMemberRow,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $FamilyMembersTableManager get familyMembers =>
      $FamilyMembersTableManager(_db, _db.familyMembers);
  $AppointmentsTableManager get appointments =>
      $AppointmentsTableManager(_db, _db.appointments);
  $DoctorQuestionsTableManager get doctorQuestions =>
      $DoctorQuestionsTableManager(_db, _db.doctorQuestions);
  $SymptomEntriesTableManager get symptomEntries =>
      $SymptomEntriesTableManager(_db, _db.symptomEntries);
  $VisitMediaTableManager get visitMedia =>
      $VisitMediaTableManager(_db, _db.visitMedia);
  $MedicationsTableManager get medications =>
      $MedicationsTableManager(_db, _db.medications);
  $DoseRecordsTableManager get doseRecords =>
      $DoseRecordsTableManager(_db, _db.doseRecords);
  $SyncSettingsTableManager get syncSettings =>
      $SyncSettingsTableManager(_db, _db.syncSettings);
  $SyncSharedMembersTableManager get syncSharedMembers =>
      $SyncSharedMembersTableManager(_db, _db.syncSharedMembers);
  $SyncRecordsTableManager get syncRecords =>
      $SyncRecordsTableManager(_db, _db.syncRecords);
  $SyncPendingTableManager get syncPending =>
      $SyncPendingTableManager(_db, _db.syncPending);
  $SyncConflictsTableManager get syncConflicts =>
      $SyncConflictsTableManager(_db, _db.syncConflicts);
  $SyncCursorsTableManager get syncCursors =>
      $SyncCursorsTableManager(_db, _db.syncCursors);
  $SyncKnownMembersTableManager get syncKnownMembers =>
      $SyncKnownMembersTableManager(_db, _db.syncKnownMembers);
}
