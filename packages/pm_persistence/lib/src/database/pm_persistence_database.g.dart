// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pm_persistence_database.dart';

// ignore_for_file: type=lint
class $QuestionProgressRecordsTable extends QuestionProgressRecords
    with TableInfo<$QuestionProgressRecordsTable, QuestionProgressRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionProgressRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionCodeMeta = const VerificationMeta(
    'questionCode',
  );
  @override
  late final GeneratedColumn<String> questionCode = GeneratedColumn<String>(
    'question_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
    'section',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSelectedOptionMeta =
      const VerificationMeta('lastSelectedOption');
  @override
  late final GeneratedColumn<String> lastSelectedOption =
      GeneratedColumn<String>(
        'last_selected_option',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 1,
          maxTextLength: 1,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _correctOptionMeta = const VerificationMeta(
    'correctOption',
  );
  @override
  late final GeneratedColumn<String> correctOption = GeneratedColumn<String>(
    'correct_option',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 1,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAnswerWasCorrectMeta =
      const VerificationMeta('lastAnswerWasCorrect');
  @override
  late final GeneratedColumn<bool> lastAnswerWasCorrect = GeneratedColumn<bool>(
    'last_answer_was_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("last_answer_was_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctAttemptsMeta = const VerificationMeta(
    'correctAttempts',
  );
  @override
  late final GeneratedColumn<int> correctAttempts = GeneratedColumn<int>(
    'correct_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _incorrectAttemptsMeta = const VerificationMeta(
    'incorrectAttempts',
  );
  @override
  late final GeneratedColumn<int> incorrectAttempts = GeneratedColumn<int>(
    'incorrect_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstAnsweredAtMeta = const VerificationMeta(
    'firstAnsweredAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstAnsweredAt =
      GeneratedColumn<DateTime>(
        'first_answered_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastAnsweredAtMeta = const VerificationMeta(
    'lastAnsweredAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAnsweredAt =
      GeneratedColumn<DateTime>(
        'last_answered_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    questionCode,
    section,
    lastSelectedOption,
    correctOption,
    lastAnswerWasCorrect,
    attempts,
    correctAttempts,
    incorrectAttempts,
    firstAnsweredAt,
    lastAnsweredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_progress_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionProgressRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question_code')) {
      context.handle(
        _questionCodeMeta,
        questionCode.isAcceptableOrUnknown(
          data['question_code']!,
          _questionCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionCodeMeta);
    }
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionMeta);
    }
    if (data.containsKey('last_selected_option')) {
      context.handle(
        _lastSelectedOptionMeta,
        lastSelectedOption.isAcceptableOrUnknown(
          data['last_selected_option']!,
          _lastSelectedOptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSelectedOptionMeta);
    }
    if (data.containsKey('correct_option')) {
      context.handle(
        _correctOptionMeta,
        correctOption.isAcceptableOrUnknown(
          data['correct_option']!,
          _correctOptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctOptionMeta);
    }
    if (data.containsKey('last_answer_was_correct')) {
      context.handle(
        _lastAnswerWasCorrectMeta,
        lastAnswerWasCorrect.isAcceptableOrUnknown(
          data['last_answer_was_correct']!,
          _lastAnswerWasCorrectMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAnswerWasCorrectMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptsMeta);
    }
    if (data.containsKey('correct_attempts')) {
      context.handle(
        _correctAttemptsMeta,
        correctAttempts.isAcceptableOrUnknown(
          data['correct_attempts']!,
          _correctAttemptsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctAttemptsMeta);
    }
    if (data.containsKey('incorrect_attempts')) {
      context.handle(
        _incorrectAttemptsMeta,
        incorrectAttempts.isAcceptableOrUnknown(
          data['incorrect_attempts']!,
          _incorrectAttemptsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_incorrectAttemptsMeta);
    }
    if (data.containsKey('first_answered_at')) {
      context.handle(
        _firstAnsweredAtMeta,
        firstAnsweredAt.isAcceptableOrUnknown(
          data['first_answered_at']!,
          _firstAnsweredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstAnsweredAtMeta);
    }
    if (data.containsKey('last_answered_at')) {
      context.handle(
        _lastAnsweredAtMeta,
        lastAnsweredAt.isAcceptableOrUnknown(
          data['last_answered_at']!,
          _lastAnsweredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAnsweredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questionCode};
  @override
  QuestionProgressRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionProgressRecord(
      questionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_code'],
      )!,
      section: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section'],
      )!,
      lastSelectedOption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_selected_option'],
      )!,
      correctOption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correct_option'],
      )!,
      lastAnswerWasCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}last_answer_was_correct'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      correctAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_attempts'],
      )!,
      incorrectAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}incorrect_attempts'],
      )!,
      firstAnsweredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_answered_at'],
      )!,
      lastAnsweredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_answered_at'],
      )!,
    );
  }

  @override
  $QuestionProgressRecordsTable createAlias(String alias) {
    return $QuestionProgressRecordsTable(attachedDatabase, alias);
  }
}

class QuestionProgressRecord extends DataClass
    implements Insertable<QuestionProgressRecord> {
  final String questionCode;
  final String section;
  final String lastSelectedOption;
  final String correctOption;
  final bool lastAnswerWasCorrect;
  final int attempts;
  final int correctAttempts;
  final int incorrectAttempts;
  final DateTime firstAnsweredAt;
  final DateTime lastAnsweredAt;
  const QuestionProgressRecord({
    required this.questionCode,
    required this.section,
    required this.lastSelectedOption,
    required this.correctOption,
    required this.lastAnswerWasCorrect,
    required this.attempts,
    required this.correctAttempts,
    required this.incorrectAttempts,
    required this.firstAnsweredAt,
    required this.lastAnsweredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_code'] = Variable<String>(questionCode);
    map['section'] = Variable<String>(section);
    map['last_selected_option'] = Variable<String>(lastSelectedOption);
    map['correct_option'] = Variable<String>(correctOption);
    map['last_answer_was_correct'] = Variable<bool>(lastAnswerWasCorrect);
    map['attempts'] = Variable<int>(attempts);
    map['correct_attempts'] = Variable<int>(correctAttempts);
    map['incorrect_attempts'] = Variable<int>(incorrectAttempts);
    map['first_answered_at'] = Variable<DateTime>(firstAnsweredAt);
    map['last_answered_at'] = Variable<DateTime>(lastAnsweredAt);
    return map;
  }

  QuestionProgressRecordsCompanion toCompanion(bool nullToAbsent) {
    return QuestionProgressRecordsCompanion(
      questionCode: Value(questionCode),
      section: Value(section),
      lastSelectedOption: Value(lastSelectedOption),
      correctOption: Value(correctOption),
      lastAnswerWasCorrect: Value(lastAnswerWasCorrect),
      attempts: Value(attempts),
      correctAttempts: Value(correctAttempts),
      incorrectAttempts: Value(incorrectAttempts),
      firstAnsweredAt: Value(firstAnsweredAt),
      lastAnsweredAt: Value(lastAnsweredAt),
    );
  }

  factory QuestionProgressRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionProgressRecord(
      questionCode: serializer.fromJson<String>(json['questionCode']),
      section: serializer.fromJson<String>(json['section']),
      lastSelectedOption: serializer.fromJson<String>(
        json['lastSelectedOption'],
      ),
      correctOption: serializer.fromJson<String>(json['correctOption']),
      lastAnswerWasCorrect: serializer.fromJson<bool>(
        json['lastAnswerWasCorrect'],
      ),
      attempts: serializer.fromJson<int>(json['attempts']),
      correctAttempts: serializer.fromJson<int>(json['correctAttempts']),
      incorrectAttempts: serializer.fromJson<int>(json['incorrectAttempts']),
      firstAnsweredAt: serializer.fromJson<DateTime>(json['firstAnsweredAt']),
      lastAnsweredAt: serializer.fromJson<DateTime>(json['lastAnsweredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionCode': serializer.toJson<String>(questionCode),
      'section': serializer.toJson<String>(section),
      'lastSelectedOption': serializer.toJson<String>(lastSelectedOption),
      'correctOption': serializer.toJson<String>(correctOption),
      'lastAnswerWasCorrect': serializer.toJson<bool>(lastAnswerWasCorrect),
      'attempts': serializer.toJson<int>(attempts),
      'correctAttempts': serializer.toJson<int>(correctAttempts),
      'incorrectAttempts': serializer.toJson<int>(incorrectAttempts),
      'firstAnsweredAt': serializer.toJson<DateTime>(firstAnsweredAt),
      'lastAnsweredAt': serializer.toJson<DateTime>(lastAnsweredAt),
    };
  }

  QuestionProgressRecord copyWith({
    String? questionCode,
    String? section,
    String? lastSelectedOption,
    String? correctOption,
    bool? lastAnswerWasCorrect,
    int? attempts,
    int? correctAttempts,
    int? incorrectAttempts,
    DateTime? firstAnsweredAt,
    DateTime? lastAnsweredAt,
  }) => QuestionProgressRecord(
    questionCode: questionCode ?? this.questionCode,
    section: section ?? this.section,
    lastSelectedOption: lastSelectedOption ?? this.lastSelectedOption,
    correctOption: correctOption ?? this.correctOption,
    lastAnswerWasCorrect: lastAnswerWasCorrect ?? this.lastAnswerWasCorrect,
    attempts: attempts ?? this.attempts,
    correctAttempts: correctAttempts ?? this.correctAttempts,
    incorrectAttempts: incorrectAttempts ?? this.incorrectAttempts,
    firstAnsweredAt: firstAnsweredAt ?? this.firstAnsweredAt,
    lastAnsweredAt: lastAnsweredAt ?? this.lastAnsweredAt,
  );
  QuestionProgressRecord copyWithCompanion(
    QuestionProgressRecordsCompanion data,
  ) {
    return QuestionProgressRecord(
      questionCode: data.questionCode.present
          ? data.questionCode.value
          : this.questionCode,
      section: data.section.present ? data.section.value : this.section,
      lastSelectedOption: data.lastSelectedOption.present
          ? data.lastSelectedOption.value
          : this.lastSelectedOption,
      correctOption: data.correctOption.present
          ? data.correctOption.value
          : this.correctOption,
      lastAnswerWasCorrect: data.lastAnswerWasCorrect.present
          ? data.lastAnswerWasCorrect.value
          : this.lastAnswerWasCorrect,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      correctAttempts: data.correctAttempts.present
          ? data.correctAttempts.value
          : this.correctAttempts,
      incorrectAttempts: data.incorrectAttempts.present
          ? data.incorrectAttempts.value
          : this.incorrectAttempts,
      firstAnsweredAt: data.firstAnsweredAt.present
          ? data.firstAnsweredAt.value
          : this.firstAnsweredAt,
      lastAnsweredAt: data.lastAnsweredAt.present
          ? data.lastAnsweredAt.value
          : this.lastAnsweredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionProgressRecord(')
          ..write('questionCode: $questionCode, ')
          ..write('section: $section, ')
          ..write('lastSelectedOption: $lastSelectedOption, ')
          ..write('correctOption: $correctOption, ')
          ..write('lastAnswerWasCorrect: $lastAnswerWasCorrect, ')
          ..write('attempts: $attempts, ')
          ..write('correctAttempts: $correctAttempts, ')
          ..write('incorrectAttempts: $incorrectAttempts, ')
          ..write('firstAnsweredAt: $firstAnsweredAt, ')
          ..write('lastAnsweredAt: $lastAnsweredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    questionCode,
    section,
    lastSelectedOption,
    correctOption,
    lastAnswerWasCorrect,
    attempts,
    correctAttempts,
    incorrectAttempts,
    firstAnsweredAt,
    lastAnsweredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionProgressRecord &&
          other.questionCode == this.questionCode &&
          other.section == this.section &&
          other.lastSelectedOption == this.lastSelectedOption &&
          other.correctOption == this.correctOption &&
          other.lastAnswerWasCorrect == this.lastAnswerWasCorrect &&
          other.attempts == this.attempts &&
          other.correctAttempts == this.correctAttempts &&
          other.incorrectAttempts == this.incorrectAttempts &&
          other.firstAnsweredAt == this.firstAnsweredAt &&
          other.lastAnsweredAt == this.lastAnsweredAt);
}

class QuestionProgressRecordsCompanion
    extends UpdateCompanion<QuestionProgressRecord> {
  final Value<String> questionCode;
  final Value<String> section;
  final Value<String> lastSelectedOption;
  final Value<String> correctOption;
  final Value<bool> lastAnswerWasCorrect;
  final Value<int> attempts;
  final Value<int> correctAttempts;
  final Value<int> incorrectAttempts;
  final Value<DateTime> firstAnsweredAt;
  final Value<DateTime> lastAnsweredAt;
  final Value<int> rowid;
  const QuestionProgressRecordsCompanion({
    this.questionCode = const Value.absent(),
    this.section = const Value.absent(),
    this.lastSelectedOption = const Value.absent(),
    this.correctOption = const Value.absent(),
    this.lastAnswerWasCorrect = const Value.absent(),
    this.attempts = const Value.absent(),
    this.correctAttempts = const Value.absent(),
    this.incorrectAttempts = const Value.absent(),
    this.firstAnsweredAt = const Value.absent(),
    this.lastAnsweredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionProgressRecordsCompanion.insert({
    required String questionCode,
    required String section,
    required String lastSelectedOption,
    required String correctOption,
    required bool lastAnswerWasCorrect,
    required int attempts,
    required int correctAttempts,
    required int incorrectAttempts,
    required DateTime firstAnsweredAt,
    required DateTime lastAnsweredAt,
    this.rowid = const Value.absent(),
  }) : questionCode = Value(questionCode),
       section = Value(section),
       lastSelectedOption = Value(lastSelectedOption),
       correctOption = Value(correctOption),
       lastAnswerWasCorrect = Value(lastAnswerWasCorrect),
       attempts = Value(attempts),
       correctAttempts = Value(correctAttempts),
       incorrectAttempts = Value(incorrectAttempts),
       firstAnsweredAt = Value(firstAnsweredAt),
       lastAnsweredAt = Value(lastAnsweredAt);
  static Insertable<QuestionProgressRecord> custom({
    Expression<String>? questionCode,
    Expression<String>? section,
    Expression<String>? lastSelectedOption,
    Expression<String>? correctOption,
    Expression<bool>? lastAnswerWasCorrect,
    Expression<int>? attempts,
    Expression<int>? correctAttempts,
    Expression<int>? incorrectAttempts,
    Expression<DateTime>? firstAnsweredAt,
    Expression<DateTime>? lastAnsweredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionCode != null) 'question_code': questionCode,
      if (section != null) 'section': section,
      if (lastSelectedOption != null)
        'last_selected_option': lastSelectedOption,
      if (correctOption != null) 'correct_option': correctOption,
      if (lastAnswerWasCorrect != null)
        'last_answer_was_correct': lastAnswerWasCorrect,
      if (attempts != null) 'attempts': attempts,
      if (correctAttempts != null) 'correct_attempts': correctAttempts,
      if (incorrectAttempts != null) 'incorrect_attempts': incorrectAttempts,
      if (firstAnsweredAt != null) 'first_answered_at': firstAnsweredAt,
      if (lastAnsweredAt != null) 'last_answered_at': lastAnsweredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionProgressRecordsCompanion copyWith({
    Value<String>? questionCode,
    Value<String>? section,
    Value<String>? lastSelectedOption,
    Value<String>? correctOption,
    Value<bool>? lastAnswerWasCorrect,
    Value<int>? attempts,
    Value<int>? correctAttempts,
    Value<int>? incorrectAttempts,
    Value<DateTime>? firstAnsweredAt,
    Value<DateTime>? lastAnsweredAt,
    Value<int>? rowid,
  }) {
    return QuestionProgressRecordsCompanion(
      questionCode: questionCode ?? this.questionCode,
      section: section ?? this.section,
      lastSelectedOption: lastSelectedOption ?? this.lastSelectedOption,
      correctOption: correctOption ?? this.correctOption,
      lastAnswerWasCorrect: lastAnswerWasCorrect ?? this.lastAnswerWasCorrect,
      attempts: attempts ?? this.attempts,
      correctAttempts: correctAttempts ?? this.correctAttempts,
      incorrectAttempts: incorrectAttempts ?? this.incorrectAttempts,
      firstAnsweredAt: firstAnsweredAt ?? this.firstAnsweredAt,
      lastAnsweredAt: lastAnsweredAt ?? this.lastAnsweredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionCode.present) {
      map['question_code'] = Variable<String>(questionCode.value);
    }
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (lastSelectedOption.present) {
      map['last_selected_option'] = Variable<String>(lastSelectedOption.value);
    }
    if (correctOption.present) {
      map['correct_option'] = Variable<String>(correctOption.value);
    }
    if (lastAnswerWasCorrect.present) {
      map['last_answer_was_correct'] = Variable<bool>(
        lastAnswerWasCorrect.value,
      );
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (correctAttempts.present) {
      map['correct_attempts'] = Variable<int>(correctAttempts.value);
    }
    if (incorrectAttempts.present) {
      map['incorrect_attempts'] = Variable<int>(incorrectAttempts.value);
    }
    if (firstAnsweredAt.present) {
      map['first_answered_at'] = Variable<DateTime>(firstAnsweredAt.value);
    }
    if (lastAnsweredAt.present) {
      map['last_answered_at'] = Variable<DateTime>(lastAnsweredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionProgressRecordsCompanion(')
          ..write('questionCode: $questionCode, ')
          ..write('section: $section, ')
          ..write('lastSelectedOption: $lastSelectedOption, ')
          ..write('correctOption: $correctOption, ')
          ..write('lastAnswerWasCorrect: $lastAnswerWasCorrect, ')
          ..write('attempts: $attempts, ')
          ..write('correctAttempts: $correctAttempts, ')
          ..write('incorrectAttempts: $incorrectAttempts, ')
          ..write('firstAnsweredAt: $firstAnsweredAt, ')
          ..write('lastAnsweredAt: $lastAnsweredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestionAttemptRecordsTable extends QuestionAttemptRecords
    with TableInfo<$QuestionAttemptRecordsTable, QuestionAttemptRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionAttemptRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _questionCodeMeta = const VerificationMeta(
    'questionCode',
  );
  @override
  late final GeneratedColumn<String> questionCode = GeneratedColumn<String>(
    'question_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
    'section',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedOptionMeta = const VerificationMeta(
    'selectedOption',
  );
  @override
  late final GeneratedColumn<String> selectedOption = GeneratedColumn<String>(
    'selected_option',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 1,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctOptionMeta = const VerificationMeta(
    'correctOption',
  );
  @override
  late final GeneratedColumn<String> correctOption = GeneratedColumn<String>(
    'correct_option',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 1,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCorrectMeta = const VerificationMeta(
    'isCorrect',
  );
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
    'is_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>(
    'answered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    questionCode,
    section,
    selectedOption,
    correctOption,
    isCorrect,
    answeredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_attempt_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionAttemptRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_code')) {
      context.handle(
        _questionCodeMeta,
        questionCode.isAcceptableOrUnknown(
          data['question_code']!,
          _questionCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionCodeMeta);
    }
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionMeta);
    }
    if (data.containsKey('selected_option')) {
      context.handle(
        _selectedOptionMeta,
        selectedOption.isAcceptableOrUnknown(
          data['selected_option']!,
          _selectedOptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_selectedOptionMeta);
    }
    if (data.containsKey('correct_option')) {
      context.handle(
        _correctOptionMeta,
        correctOption.isAcceptableOrUnknown(
          data['correct_option']!,
          _correctOptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctOptionMeta);
    }
    if (data.containsKey('is_correct')) {
      context.handle(
        _isCorrectMeta,
        isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta),
      );
    } else if (isInserting) {
      context.missing(_isCorrectMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_answeredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionAttemptRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionAttemptRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_code'],
      )!,
      section: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section'],
      )!,
      selectedOption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_option'],
      )!,
      correctOption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correct_option'],
      )!,
      isCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_correct'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}answered_at'],
      )!,
    );
  }

  @override
  $QuestionAttemptRecordsTable createAlias(String alias) {
    return $QuestionAttemptRecordsTable(attachedDatabase, alias);
  }
}

class QuestionAttemptRecord extends DataClass
    implements Insertable<QuestionAttemptRecord> {
  final int id;
  final String questionCode;
  final String section;
  final String selectedOption;
  final String correctOption;
  final bool isCorrect;
  final DateTime answeredAt;
  const QuestionAttemptRecord({
    required this.id,
    required this.questionCode,
    required this.section,
    required this.selectedOption,
    required this.correctOption,
    required this.isCorrect,
    required this.answeredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_code'] = Variable<String>(questionCode);
    map['section'] = Variable<String>(section);
    map['selected_option'] = Variable<String>(selectedOption);
    map['correct_option'] = Variable<String>(correctOption);
    map['is_correct'] = Variable<bool>(isCorrect);
    map['answered_at'] = Variable<DateTime>(answeredAt);
    return map;
  }

  QuestionAttemptRecordsCompanion toCompanion(bool nullToAbsent) {
    return QuestionAttemptRecordsCompanion(
      id: Value(id),
      questionCode: Value(questionCode),
      section: Value(section),
      selectedOption: Value(selectedOption),
      correctOption: Value(correctOption),
      isCorrect: Value(isCorrect),
      answeredAt: Value(answeredAt),
    );
  }

  factory QuestionAttemptRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionAttemptRecord(
      id: serializer.fromJson<int>(json['id']),
      questionCode: serializer.fromJson<String>(json['questionCode']),
      section: serializer.fromJson<String>(json['section']),
      selectedOption: serializer.fromJson<String>(json['selectedOption']),
      correctOption: serializer.fromJson<String>(json['correctOption']),
      isCorrect: serializer.fromJson<bool>(json['isCorrect']),
      answeredAt: serializer.fromJson<DateTime>(json['answeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionCode': serializer.toJson<String>(questionCode),
      'section': serializer.toJson<String>(section),
      'selectedOption': serializer.toJson<String>(selectedOption),
      'correctOption': serializer.toJson<String>(correctOption),
      'isCorrect': serializer.toJson<bool>(isCorrect),
      'answeredAt': serializer.toJson<DateTime>(answeredAt),
    };
  }

  QuestionAttemptRecord copyWith({
    int? id,
    String? questionCode,
    String? section,
    String? selectedOption,
    String? correctOption,
    bool? isCorrect,
    DateTime? answeredAt,
  }) => QuestionAttemptRecord(
    id: id ?? this.id,
    questionCode: questionCode ?? this.questionCode,
    section: section ?? this.section,
    selectedOption: selectedOption ?? this.selectedOption,
    correctOption: correctOption ?? this.correctOption,
    isCorrect: isCorrect ?? this.isCorrect,
    answeredAt: answeredAt ?? this.answeredAt,
  );
  QuestionAttemptRecord copyWithCompanion(
    QuestionAttemptRecordsCompanion data,
  ) {
    return QuestionAttemptRecord(
      id: data.id.present ? data.id.value : this.id,
      questionCode: data.questionCode.present
          ? data.questionCode.value
          : this.questionCode,
      section: data.section.present ? data.section.value : this.section,
      selectedOption: data.selectedOption.present
          ? data.selectedOption.value
          : this.selectedOption,
      correctOption: data.correctOption.present
          ? data.correctOption.value
          : this.correctOption,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionAttemptRecord(')
          ..write('id: $id, ')
          ..write('questionCode: $questionCode, ')
          ..write('section: $section, ')
          ..write('selectedOption: $selectedOption, ')
          ..write('correctOption: $correctOption, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    questionCode,
    section,
    selectedOption,
    correctOption,
    isCorrect,
    answeredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionAttemptRecord &&
          other.id == this.id &&
          other.questionCode == this.questionCode &&
          other.section == this.section &&
          other.selectedOption == this.selectedOption &&
          other.correctOption == this.correctOption &&
          other.isCorrect == this.isCorrect &&
          other.answeredAt == this.answeredAt);
}

class QuestionAttemptRecordsCompanion
    extends UpdateCompanion<QuestionAttemptRecord> {
  final Value<int> id;
  final Value<String> questionCode;
  final Value<String> section;
  final Value<String> selectedOption;
  final Value<String> correctOption;
  final Value<bool> isCorrect;
  final Value<DateTime> answeredAt;
  const QuestionAttemptRecordsCompanion({
    this.id = const Value.absent(),
    this.questionCode = const Value.absent(),
    this.section = const Value.absent(),
    this.selectedOption = const Value.absent(),
    this.correctOption = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.answeredAt = const Value.absent(),
  });
  QuestionAttemptRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String questionCode,
    required String section,
    required String selectedOption,
    required String correctOption,
    required bool isCorrect,
    required DateTime answeredAt,
  }) : questionCode = Value(questionCode),
       section = Value(section),
       selectedOption = Value(selectedOption),
       correctOption = Value(correctOption),
       isCorrect = Value(isCorrect),
       answeredAt = Value(answeredAt);
  static Insertable<QuestionAttemptRecord> custom({
    Expression<int>? id,
    Expression<String>? questionCode,
    Expression<String>? section,
    Expression<String>? selectedOption,
    Expression<String>? correctOption,
    Expression<bool>? isCorrect,
    Expression<DateTime>? answeredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionCode != null) 'question_code': questionCode,
      if (section != null) 'section': section,
      if (selectedOption != null) 'selected_option': selectedOption,
      if (correctOption != null) 'correct_option': correctOption,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (answeredAt != null) 'answered_at': answeredAt,
    });
  }

  QuestionAttemptRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? questionCode,
    Value<String>? section,
    Value<String>? selectedOption,
    Value<String>? correctOption,
    Value<bool>? isCorrect,
    Value<DateTime>? answeredAt,
  }) {
    return QuestionAttemptRecordsCompanion(
      id: id ?? this.id,
      questionCode: questionCode ?? this.questionCode,
      section: section ?? this.section,
      selectedOption: selectedOption ?? this.selectedOption,
      correctOption: correctOption ?? this.correctOption,
      isCorrect: isCorrect ?? this.isCorrect,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionCode.present) {
      map['question_code'] = Variable<String>(questionCode.value);
    }
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (selectedOption.present) {
      map['selected_option'] = Variable<String>(selectedOption.value);
    }
    if (correctOption.present) {
      map['correct_option'] = Variable<String>(correctOption.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<DateTime>(answeredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionAttemptRecordsCompanion(')
          ..write('id: $id, ')
          ..write('questionCode: $questionCode, ')
          ..write('section: $section, ')
          ..write('selectedOption: $selectedOption, ')
          ..write('correctOption: $correctOption, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$PmPersistenceDatabase extends GeneratedDatabase {
  _$PmPersistenceDatabase(QueryExecutor e) : super(e);
  $PmPersistenceDatabaseManager get managers =>
      $PmPersistenceDatabaseManager(this);
  late final $QuestionProgressRecordsTable questionProgressRecords =
      $QuestionProgressRecordsTable(this);
  late final $QuestionAttemptRecordsTable questionAttemptRecords =
      $QuestionAttemptRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    questionProgressRecords,
    questionAttemptRecords,
  ];
}

typedef $$QuestionProgressRecordsTableCreateCompanionBuilder =
    QuestionProgressRecordsCompanion Function({
      required String questionCode,
      required String section,
      required String lastSelectedOption,
      required String correctOption,
      required bool lastAnswerWasCorrect,
      required int attempts,
      required int correctAttempts,
      required int incorrectAttempts,
      required DateTime firstAnsweredAt,
      required DateTime lastAnsweredAt,
      Value<int> rowid,
    });
typedef $$QuestionProgressRecordsTableUpdateCompanionBuilder =
    QuestionProgressRecordsCompanion Function({
      Value<String> questionCode,
      Value<String> section,
      Value<String> lastSelectedOption,
      Value<String> correctOption,
      Value<bool> lastAnswerWasCorrect,
      Value<int> attempts,
      Value<int> correctAttempts,
      Value<int> incorrectAttempts,
      Value<DateTime> firstAnsweredAt,
      Value<DateTime> lastAnsweredAt,
      Value<int> rowid,
    });

class $$QuestionProgressRecordsTableFilterComposer
    extends Composer<_$PmPersistenceDatabase, $QuestionProgressRecordsTable> {
  $$QuestionProgressRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get questionCode => $composableBuilder(
    column: $table.questionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSelectedOption => $composableBuilder(
    column: $table.lastSelectedOption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctOption => $composableBuilder(
    column: $table.correctOption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lastAnswerWasCorrect => $composableBuilder(
    column: $table.lastAnswerWasCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctAttempts => $composableBuilder(
    column: $table.correctAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get incorrectAttempts => $composableBuilder(
    column: $table.incorrectAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstAnsweredAt => $composableBuilder(
    column: $table.firstAnsweredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAnsweredAt => $composableBuilder(
    column: $table.lastAnsweredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuestionProgressRecordsTableOrderingComposer
    extends Composer<_$PmPersistenceDatabase, $QuestionProgressRecordsTable> {
  $$QuestionProgressRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get questionCode => $composableBuilder(
    column: $table.questionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSelectedOption => $composableBuilder(
    column: $table.lastSelectedOption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctOption => $composableBuilder(
    column: $table.correctOption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lastAnswerWasCorrect => $composableBuilder(
    column: $table.lastAnswerWasCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctAttempts => $composableBuilder(
    column: $table.correctAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get incorrectAttempts => $composableBuilder(
    column: $table.incorrectAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstAnsweredAt => $composableBuilder(
    column: $table.firstAnsweredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAnsweredAt => $composableBuilder(
    column: $table.lastAnsweredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestionProgressRecordsTableAnnotationComposer
    extends Composer<_$PmPersistenceDatabase, $QuestionProgressRecordsTable> {
  $$QuestionProgressRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get questionCode => $composableBuilder(
    column: $table.questionCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<String> get lastSelectedOption => $composableBuilder(
    column: $table.lastSelectedOption,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correctOption => $composableBuilder(
    column: $table.correctOption,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lastAnswerWasCorrect => $composableBuilder(
    column: $table.lastAnswerWasCorrect,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get correctAttempts => $composableBuilder(
    column: $table.correctAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get incorrectAttempts => $composableBuilder(
    column: $table.incorrectAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstAnsweredAt => $composableBuilder(
    column: $table.firstAnsweredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAnsweredAt => $composableBuilder(
    column: $table.lastAnsweredAt,
    builder: (column) => column,
  );
}

class $$QuestionProgressRecordsTableTableManager
    extends
        RootTableManager<
          _$PmPersistenceDatabase,
          $QuestionProgressRecordsTable,
          QuestionProgressRecord,
          $$QuestionProgressRecordsTableFilterComposer,
          $$QuestionProgressRecordsTableOrderingComposer,
          $$QuestionProgressRecordsTableAnnotationComposer,
          $$QuestionProgressRecordsTableCreateCompanionBuilder,
          $$QuestionProgressRecordsTableUpdateCompanionBuilder,
          (
            QuestionProgressRecord,
            BaseReferences<
              _$PmPersistenceDatabase,
              $QuestionProgressRecordsTable,
              QuestionProgressRecord
            >,
          ),
          QuestionProgressRecord,
          PrefetchHooks Function()
        > {
  $$QuestionProgressRecordsTableTableManager(
    _$PmPersistenceDatabase db,
    $QuestionProgressRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionProgressRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$QuestionProgressRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$QuestionProgressRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> questionCode = const Value.absent(),
                Value<String> section = const Value.absent(),
                Value<String> lastSelectedOption = const Value.absent(),
                Value<String> correctOption = const Value.absent(),
                Value<bool> lastAnswerWasCorrect = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> correctAttempts = const Value.absent(),
                Value<int> incorrectAttempts = const Value.absent(),
                Value<DateTime> firstAnsweredAt = const Value.absent(),
                Value<DateTime> lastAnsweredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionProgressRecordsCompanion(
                questionCode: questionCode,
                section: section,
                lastSelectedOption: lastSelectedOption,
                correctOption: correctOption,
                lastAnswerWasCorrect: lastAnswerWasCorrect,
                attempts: attempts,
                correctAttempts: correctAttempts,
                incorrectAttempts: incorrectAttempts,
                firstAnsweredAt: firstAnsweredAt,
                lastAnsweredAt: lastAnsweredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String questionCode,
                required String section,
                required String lastSelectedOption,
                required String correctOption,
                required bool lastAnswerWasCorrect,
                required int attempts,
                required int correctAttempts,
                required int incorrectAttempts,
                required DateTime firstAnsweredAt,
                required DateTime lastAnsweredAt,
                Value<int> rowid = const Value.absent(),
              }) => QuestionProgressRecordsCompanion.insert(
                questionCode: questionCode,
                section: section,
                lastSelectedOption: lastSelectedOption,
                correctOption: correctOption,
                lastAnswerWasCorrect: lastAnswerWasCorrect,
                attempts: attempts,
                correctAttempts: correctAttempts,
                incorrectAttempts: incorrectAttempts,
                firstAnsweredAt: firstAnsweredAt,
                lastAnsweredAt: lastAnsweredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuestionProgressRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$PmPersistenceDatabase,
      $QuestionProgressRecordsTable,
      QuestionProgressRecord,
      $$QuestionProgressRecordsTableFilterComposer,
      $$QuestionProgressRecordsTableOrderingComposer,
      $$QuestionProgressRecordsTableAnnotationComposer,
      $$QuestionProgressRecordsTableCreateCompanionBuilder,
      $$QuestionProgressRecordsTableUpdateCompanionBuilder,
      (
        QuestionProgressRecord,
        BaseReferences<
          _$PmPersistenceDatabase,
          $QuestionProgressRecordsTable,
          QuestionProgressRecord
        >,
      ),
      QuestionProgressRecord,
      PrefetchHooks Function()
    >;
typedef $$QuestionAttemptRecordsTableCreateCompanionBuilder =
    QuestionAttemptRecordsCompanion Function({
      Value<int> id,
      required String questionCode,
      required String section,
      required String selectedOption,
      required String correctOption,
      required bool isCorrect,
      required DateTime answeredAt,
    });
typedef $$QuestionAttemptRecordsTableUpdateCompanionBuilder =
    QuestionAttemptRecordsCompanion Function({
      Value<int> id,
      Value<String> questionCode,
      Value<String> section,
      Value<String> selectedOption,
      Value<String> correctOption,
      Value<bool> isCorrect,
      Value<DateTime> answeredAt,
    });

class $$QuestionAttemptRecordsTableFilterComposer
    extends Composer<_$PmPersistenceDatabase, $QuestionAttemptRecordsTable> {
  $$QuestionAttemptRecordsTableFilterComposer({
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

  ColumnFilters<String> get questionCode => $composableBuilder(
    column: $table.questionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedOption => $composableBuilder(
    column: $table.selectedOption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctOption => $composableBuilder(
    column: $table.correctOption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuestionAttemptRecordsTableOrderingComposer
    extends Composer<_$PmPersistenceDatabase, $QuestionAttemptRecordsTable> {
  $$QuestionAttemptRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get questionCode => $composableBuilder(
    column: $table.questionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedOption => $composableBuilder(
    column: $table.selectedOption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctOption => $composableBuilder(
    column: $table.correctOption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestionAttemptRecordsTableAnnotationComposer
    extends Composer<_$PmPersistenceDatabase, $QuestionAttemptRecordsTable> {
  $$QuestionAttemptRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionCode => $composableBuilder(
    column: $table.questionCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<String> get selectedOption => $composableBuilder(
    column: $table.selectedOption,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correctOption => $composableBuilder(
    column: $table.correctOption,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );
}

class $$QuestionAttemptRecordsTableTableManager
    extends
        RootTableManager<
          _$PmPersistenceDatabase,
          $QuestionAttemptRecordsTable,
          QuestionAttemptRecord,
          $$QuestionAttemptRecordsTableFilterComposer,
          $$QuestionAttemptRecordsTableOrderingComposer,
          $$QuestionAttemptRecordsTableAnnotationComposer,
          $$QuestionAttemptRecordsTableCreateCompanionBuilder,
          $$QuestionAttemptRecordsTableUpdateCompanionBuilder,
          (
            QuestionAttemptRecord,
            BaseReferences<
              _$PmPersistenceDatabase,
              $QuestionAttemptRecordsTable,
              QuestionAttemptRecord
            >,
          ),
          QuestionAttemptRecord,
          PrefetchHooks Function()
        > {
  $$QuestionAttemptRecordsTableTableManager(
    _$PmPersistenceDatabase db,
    $QuestionAttemptRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionAttemptRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$QuestionAttemptRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$QuestionAttemptRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> questionCode = const Value.absent(),
                Value<String> section = const Value.absent(),
                Value<String> selectedOption = const Value.absent(),
                Value<String> correctOption = const Value.absent(),
                Value<bool> isCorrect = const Value.absent(),
                Value<DateTime> answeredAt = const Value.absent(),
              }) => QuestionAttemptRecordsCompanion(
                id: id,
                questionCode: questionCode,
                section: section,
                selectedOption: selectedOption,
                correctOption: correctOption,
                isCorrect: isCorrect,
                answeredAt: answeredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String questionCode,
                required String section,
                required String selectedOption,
                required String correctOption,
                required bool isCorrect,
                required DateTime answeredAt,
              }) => QuestionAttemptRecordsCompanion.insert(
                id: id,
                questionCode: questionCode,
                section: section,
                selectedOption: selectedOption,
                correctOption: correctOption,
                isCorrect: isCorrect,
                answeredAt: answeredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuestionAttemptRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$PmPersistenceDatabase,
      $QuestionAttemptRecordsTable,
      QuestionAttemptRecord,
      $$QuestionAttemptRecordsTableFilterComposer,
      $$QuestionAttemptRecordsTableOrderingComposer,
      $$QuestionAttemptRecordsTableAnnotationComposer,
      $$QuestionAttemptRecordsTableCreateCompanionBuilder,
      $$QuestionAttemptRecordsTableUpdateCompanionBuilder,
      (
        QuestionAttemptRecord,
        BaseReferences<
          _$PmPersistenceDatabase,
          $QuestionAttemptRecordsTable,
          QuestionAttemptRecord
        >,
      ),
      QuestionAttemptRecord,
      PrefetchHooks Function()
    >;

class $PmPersistenceDatabaseManager {
  final _$PmPersistenceDatabase _db;
  $PmPersistenceDatabaseManager(this._db);
  $$QuestionProgressRecordsTableTableManager get questionProgressRecords =>
      $$QuestionProgressRecordsTableTableManager(
        _db,
        _db.questionProgressRecords,
      );
  $$QuestionAttemptRecordsTableTableManager get questionAttemptRecords =>
      $$QuestionAttemptRecordsTableTableManager(
        _db,
        _db.questionAttemptRecords,
      );
}
