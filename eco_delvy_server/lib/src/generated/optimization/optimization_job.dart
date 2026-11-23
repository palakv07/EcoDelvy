/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:serverpod/serverpod.dart' as _is;

abstract class OptimizationJob
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  OptimizationJob._({
    this.id,
    required this.userIdentifier,
    required this.status,
    required this.solver,
    required this.payloadJson,
    required this.timeLimit,
    this.vehiclePenaltyWeight,
    required this.distanceWeight,
    required this.mipGap,
    this.resultJson,
    this.errorMessage,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.attemptCount,
    this.leaseExpiresAt,
    this.leaseToken,
    this.lastLogSequence,
  });

  factory OptimizationJob({
    int? id,
    required String userIdentifier,
    required String status,
    required String solver,
    required String payloadJson,
    required int timeLimit,
    double? vehiclePenaltyWeight,
    required double distanceWeight,
    required double mipGap,
    String? resultJson,
    String? errorMessage,
    required DateTime createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? attemptCount,
    DateTime? leaseExpiresAt,
    String? leaseToken,
    int? lastLogSequence,
  }) = _OptimizationJobImpl;

  factory OptimizationJob.fromJson(Map<String, dynamic> jsonSerialization) {
    return OptimizationJob(
      id: jsonSerialization['id'] as int?,
      userIdentifier: jsonSerialization['userIdentifier'] as String,
      status: jsonSerialization['status'] as String,
      solver: jsonSerialization['solver'] as String,
      payloadJson: jsonSerialization['payloadJson'] as String,
      timeLimit: jsonSerialization['timeLimit'] as int,
      vehiclePenaltyWeight: (jsonSerialization['vehiclePenaltyWeight'] as num?)
          ?.toDouble(),
      distanceWeight: (jsonSerialization['distanceWeight'] as num).toDouble(),
      mipGap: (jsonSerialization['mipGap'] as num).toDouble(),
      resultJson: jsonSerialization['resultJson'] as String?,
      errorMessage: jsonSerialization['errorMessage'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      attemptCount: jsonSerialization['attemptCount'] as int?,
      leaseExpiresAt: jsonSerialization['leaseExpiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['leaseExpiresAt'],
            ),
      leaseToken: jsonSerialization['leaseToken'] as String?,
      lastLogSequence: jsonSerialization['lastLogSequence'] as int?,
    );
  }

  static final t = OptimizationJobTable();

  static const db = OptimizationJobRepository._();

  @override
  int? id;

  String userIdentifier;

  String status;

  String solver;

  String payloadJson;

  int timeLimit;

  double? vehiclePenaltyWeight;

  double distanceWeight;

  double mipGap;

  String? resultJson;

  String? errorMessage;

  DateTime createdAt;

  DateTime? startedAt;

  DateTime? completedAt;

  int? attemptCount;

  DateTime? leaseExpiresAt;

  String? leaseToken;

  int? lastLogSequence;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [OptimizationJob]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  OptimizationJob copyWith({
    int? id,
    String? userIdentifier,
    String? status,
    String? solver,
    String? payloadJson,
    int? timeLimit,
    double? vehiclePenaltyWeight,
    double? distanceWeight,
    double? mipGap,
    String? resultJson,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? startedAt = const _is.$UndefinedDateTime(),
    DateTime? completedAt = const _is.$UndefinedDateTime(),
    int? attemptCount,
    DateTime? leaseExpiresAt = const _is.$UndefinedDateTime(),
    String? leaseToken,
    int? lastLogSequence,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OptimizationJob',
      if (id != null) 'id': id,
      'userIdentifier': userIdentifier,
      'status': status,
      'solver': solver,
      'payloadJson': payloadJson,
      'timeLimit': timeLimit,
      if (vehiclePenaltyWeight != null)
        'vehiclePenaltyWeight': vehiclePenaltyWeight,
      'distanceWeight': distanceWeight,
      'mipGap': mipGap,
      if (resultJson != null) 'resultJson': resultJson,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'createdAt': createdAt.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (attemptCount != null) 'attemptCount': attemptCount,
      if (leaseExpiresAt != null) 'leaseExpiresAt': leaseExpiresAt?.toJson(),
      if (leaseToken != null) 'leaseToken': leaseToken,
      if (lastLogSequence != null) 'lastLogSequence': lastLogSequence,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OptimizationJob',
      if (id != null) 'id': id,
      'userIdentifier': userIdentifier,
      'status': status,
      'solver': solver,
      'payloadJson': payloadJson,
      'timeLimit': timeLimit,
      if (vehiclePenaltyWeight != null)
        'vehiclePenaltyWeight': vehiclePenaltyWeight,
      'distanceWeight': distanceWeight,
      'mipGap': mipGap,
      if (resultJson != null) 'resultJson': resultJson,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'createdAt': createdAt.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  static OptimizationJobInclude include() {
    return OptimizationJobInclude._();
  }

  static OptimizationJobIncludeList includeList({
    _is.WhereExpressionBuilder<OptimizationJobTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OptimizationJobTable>? orderBy,
    _is.OrderByListBuilder<OptimizationJobTable>? orderByList,
    OptimizationJobInclude? include,
  }) {
    return OptimizationJobIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OptimizationJob.t),
      orderByList: orderByList?.call(OptimizationJob.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OptimizationJobImpl extends OptimizationJob {
  _OptimizationJobImpl({
    int? id,
    required String userIdentifier,
    required String status,
    required String solver,
    required String payloadJson,
    required int timeLimit,
    double? vehiclePenaltyWeight,
    required double distanceWeight,
    required double mipGap,
    String? resultJson,
    String? errorMessage,
    required DateTime createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? attemptCount,
    DateTime? leaseExpiresAt,
    String? leaseToken,
    int? lastLogSequence,
  }) : super._(
         id: id,
         userIdentifier: userIdentifier,
         status: status,
         solver: solver,
         payloadJson: payloadJson,
         timeLimit: timeLimit,
         vehiclePenaltyWeight: vehiclePenaltyWeight,
         distanceWeight: distanceWeight,
         mipGap: mipGap,
         resultJson: resultJson,
         errorMessage: errorMessage,
         createdAt: createdAt,
         startedAt: startedAt,
         completedAt: completedAt,
         attemptCount: attemptCount,
         leaseExpiresAt: leaseExpiresAt,
         leaseToken: leaseToken,
         lastLogSequence: lastLogSequence,
       );

  /// Returns a shallow copy of this [OptimizationJob]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  OptimizationJob copyWith({
    Object? id = _Undefined,
    String? userIdentifier,
    String? status,
    String? solver,
    String? payloadJson,
    int? timeLimit,
    Object? vehiclePenaltyWeight = _Undefined,
    double? distanceWeight,
    double? mipGap,
    Object? resultJson = _Undefined,
    Object? errorMessage = _Undefined,
    DateTime? createdAt,
    DateTime? startedAt = const _is.$UndefinedDateTime(),
    DateTime? completedAt = const _is.$UndefinedDateTime(),
    Object? attemptCount = _Undefined,
    DateTime? leaseExpiresAt = const _is.$UndefinedDateTime(),
    Object? leaseToken = _Undefined,
    Object? lastLogSequence = _Undefined,
  }) {
    return OptimizationJob(
      id: id is int? ? id : this.id,
      userIdentifier: userIdentifier ?? this.userIdentifier,
      status: status ?? this.status,
      solver: solver ?? this.solver,
      payloadJson: payloadJson ?? this.payloadJson,
      timeLimit: timeLimit ?? this.timeLimit,
      vehiclePenaltyWeight: vehiclePenaltyWeight is double?
          ? vehiclePenaltyWeight
          : this.vehiclePenaltyWeight,
      distanceWeight: distanceWeight ?? this.distanceWeight,
      mipGap: mipGap ?? this.mipGap,
      resultJson: resultJson is String? ? resultJson : this.resultJson,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt is _is.UndefinedSentinel
          ? this.startedAt
          : startedAt,
      completedAt: completedAt is _is.UndefinedSentinel
          ? this.completedAt
          : completedAt,
      attemptCount: attemptCount is int? ? attemptCount : this.attemptCount,
      leaseExpiresAt: leaseExpiresAt is _is.UndefinedSentinel
          ? this.leaseExpiresAt
          : leaseExpiresAt,
      leaseToken: leaseToken is String? ? leaseToken : this.leaseToken,
      lastLogSequence: lastLogSequence is int?
          ? lastLogSequence
          : this.lastLogSequence,
    );
  }
}

class OptimizationJobUpdateTable extends _is.UpdateTable<OptimizationJobTable> {
  OptimizationJobUpdateTable(super.table);

  _is.ColumnValue<String, String> userIdentifier(String value) =>
      _is.ColumnValue(
        table.userIdentifier,
        value,
      );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> solver(String value) => _is.ColumnValue(
    table.solver,
    value,
  );

  _is.ColumnValue<String, String> payloadJson(String value) => _is.ColumnValue(
    table.payloadJson,
    value,
  );

  _is.ColumnValue<int, int> timeLimit(int value) => _is.ColumnValue(
    table.timeLimit,
    value,
  );

  _is.ColumnValue<double, double> vehiclePenaltyWeight(double? value) =>
      _is.ColumnValue(
        table.vehiclePenaltyWeight,
        value,
      );

  _is.ColumnValue<double, double> distanceWeight(double value) =>
      _is.ColumnValue(
        table.distanceWeight,
        value,
      );

  _is.ColumnValue<double, double> mipGap(double value) => _is.ColumnValue(
    table.mipGap,
    value,
  );

  _is.ColumnValue<String, String> resultJson(String? value) => _is.ColumnValue(
    table.resultJson,
    value,
  );

  _is.ColumnValue<String, String> errorMessage(String? value) =>
      _is.ColumnValue(
        table.errorMessage,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> startedAt(DateTime? value) =>
      _is.ColumnValue(
        table.startedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> completedAt(DateTime? value) =>
      _is.ColumnValue(
        table.completedAt,
        value,
      );

  _is.ColumnValue<int, int> attemptCount(int? value) => _is.ColumnValue(
    table.attemptCount,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> leaseExpiresAt(DateTime? value) =>
      _is.ColumnValue(
        table.leaseExpiresAt,
        value,
      );

  _is.ColumnValue<String, String> leaseToken(String? value) => _is.ColumnValue(
    table.leaseToken,
    value,
  );

  _is.ColumnValue<int, int> lastLogSequence(int? value) => _is.ColumnValue(
    table.lastLogSequence,
    value,
  );
}

class OptimizationJobTable extends _is.Table<int?> {
  OptimizationJobTable({super.tableRelation})
    : super(tableName: 'optimization_job') {
    updateTable = OptimizationJobUpdateTable(this);
    userIdentifier = _is.ColumnString(
      'userIdentifier',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    solver = _is.ColumnString(
      'solver',
      this,
    );
    payloadJson = _is.ColumnString(
      'payloadJson',
      this,
    );
    timeLimit = _is.ColumnInt(
      'timeLimit',
      this,
    );
    vehiclePenaltyWeight = _is.ColumnDouble(
      'vehiclePenaltyWeight',
      this,
    );
    distanceWeight = _is.ColumnDouble(
      'distanceWeight',
      this,
    );
    mipGap = _is.ColumnDouble(
      'mipGap',
      this,
    );
    resultJson = _is.ColumnString(
      'resultJson',
      this,
    );
    errorMessage = _is.ColumnString(
      'errorMessage',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    startedAt = _is.ColumnDateTime(
      'startedAt',
      this,
    );
    completedAt = _is.ColumnDateTime(
      'completedAt',
      this,
    );
    attemptCount = _is.ColumnInt(
      'attemptCount',
      this,
    );
    leaseExpiresAt = _is.ColumnDateTime(
      'leaseExpiresAt',
      this,
    );
    leaseToken = _is.ColumnString(
      'leaseToken',
      this,
    );
    lastLogSequence = _is.ColumnInt(
      'lastLogSequence',
      this,
    );
  }

  late final OptimizationJobUpdateTable updateTable;

  late final _is.ColumnString userIdentifier;

  late final _is.ColumnString status;

  late final _is.ColumnString solver;

  late final _is.ColumnString payloadJson;

  late final _is.ColumnInt timeLimit;

  late final _is.ColumnDouble vehiclePenaltyWeight;

  late final _is.ColumnDouble distanceWeight;

  late final _is.ColumnDouble mipGap;

  late final _is.ColumnString resultJson;

  late final _is.ColumnString errorMessage;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime startedAt;

  late final _is.ColumnDateTime completedAt;

  late final _is.ColumnInt attemptCount;

  late final _is.ColumnDateTime leaseExpiresAt;

  late final _is.ColumnString leaseToken;

  late final _is.ColumnInt lastLogSequence;

  @override
  List<_is.Column> get columns => [
    id,
    userIdentifier,
    status,
    solver,
    payloadJson,
    timeLimit,
    vehiclePenaltyWeight,
    distanceWeight,
    mipGap,
    resultJson,
    errorMessage,
    createdAt,
    startedAt,
    completedAt,
    attemptCount,
    leaseExpiresAt,
    leaseToken,
    lastLogSequence,
  ];
}

class OptimizationJobInclude extends _is.IncludeObject {
  OptimizationJobInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => OptimizationJob.t;
}

class OptimizationJobIncludeList extends _is.IncludeList {
  OptimizationJobIncludeList._({
    _is.WhereExpressionBuilder<OptimizationJobTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(OptimizationJob.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => OptimizationJob.t;
}

class OptimizationJobRepository {
  const OptimizationJobRepository._();

  /// Returns a list of [OptimizationJob]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<OptimizationJob>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OptimizationJobTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OptimizationJobTable>? orderBy,
    _is.OrderByListBuilder<OptimizationJobTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<OptimizationJob>(
      where: where?.call(OptimizationJob.t),
      orderBy: orderBy?.call(OptimizationJob.t),
      orderByList: orderByList?.call(OptimizationJob.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [OptimizationJob]s matching the given query parameters every time the
  /// source tables are modified.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// Use [throttle] to specify the minimum interval between queries. It can
  /// also be set to `null`, in which case the stream will only be throttled
  /// when its subscription is paused.
  ///
  /// Source tables are collected from the queried table, [where], [orderBy],
  /// [orderByList], and the [include] graph. [alsoTriggerOnTables] is added
  /// to that set. Pass [Table] instances such as `OptimizationJob.t`.
  ///
  /// Raw [Expression] SQL is not inspected. Tables referenced only in raw
  /// SQL must be passed via [alsoTriggerOnTables].
  ///
  /// The stream always reads committed state and never joins an ambient
  /// [Transaction]. Emissions for a write fire after that write commits.
  ///
  /// Currently only supported on SQLite. Calling this method on PostgreSQL
  /// throws an [UnsupportedError].
  ///
  /// ```dart
  /// var subscription = Persons.db.watch(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// ).listen((persons) {
  ///   // Handle the latest matching rows.
  /// });
  /// ```
  _ida.Stream<List<OptimizationJob>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OptimizationJobTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OptimizationJobTable>? orderBy,
    _is.OrderByListBuilder<OptimizationJobTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<OptimizationJob>(
      where: where?.call(OptimizationJob.t),
      orderBy: orderBy?.call(OptimizationJob.t),
      orderByList: orderByList?.call(OptimizationJob.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [OptimizationJob] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<OptimizationJob?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OptimizationJobTable>? where,
    int? offset,
    _is.OrderByBuilder<OptimizationJobTable>? orderBy,
    _is.OrderByListBuilder<OptimizationJobTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<OptimizationJob>(
      where: where?.call(OptimizationJob.t),
      orderBy: orderBy?.call(OptimizationJob.t),
      orderByList: orderByList?.call(OptimizationJob.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [OptimizationJob] by its [id] or null if no such row exists.
  Future<OptimizationJob?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<OptimizationJob>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [OptimizationJob]s in the list and returns the inserted rows.
  ///
  /// The returned [OptimizationJob]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OptimizationJob>> insert(
    _is.DatabaseSession session,
    List<OptimizationJob> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<OptimizationJob>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [OptimizationJob] and returns the inserted row.
  ///
  /// The returned [OptimizationJob] will have its `id` field set.
  Future<OptimizationJob> insertRow(
    _is.DatabaseSession session,
    OptimizationJob row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<OptimizationJob>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [OptimizationJob]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [OptimizationJob]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OptimizationJob>> upsert(
    _is.DatabaseSession session,
    List<OptimizationJob> rows, {
    required _is.ColumnSelections<OptimizationJobTable> conflictColumns,
    _is.ColumnSelections<OptimizationJobTable>? updateColumns,
    _is.WhereExpressionBuilder<OptimizationJobTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<OptimizationJob>(
      rows,
      conflictColumns: conflictColumns(OptimizationJob.t),
      updateColumns: updateColumns?.call(OptimizationJob.t),
      updateWhere: updateWhere?.call(OptimizationJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [OptimizationJob] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [OptimizationJob] will have its `id` field set.
  Future<OptimizationJob?> upsertRow(
    _is.DatabaseSession session,
    OptimizationJob row, {
    required _is.ColumnSelections<OptimizationJobTable> conflictColumns,
    _is.ColumnSelections<OptimizationJobTable>? updateColumns,
    _is.WhereExpressionBuilder<OptimizationJobTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<OptimizationJob>(
      row,
      conflictColumns: conflictColumns(OptimizationJob.t),
      updateColumns: updateColumns?.call(OptimizationJob.t),
      updateWhere: updateWhere?.call(OptimizationJob.t),
      transaction: transaction,
    );
  }

  /// Updates all [OptimizationJob]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OptimizationJob>> update(
    _is.DatabaseSession session,
    List<OptimizationJob> rows, {
    _is.ColumnSelections<OptimizationJobTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<OptimizationJob>(
      rows,
      columns: columns?.call(OptimizationJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [OptimizationJob]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<OptimizationJob> updateRow(
    _is.DatabaseSession session,
    OptimizationJob row, {
    _is.ColumnSelections<OptimizationJobTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<OptimizationJob>(
      row,
      columns: columns?.call(OptimizationJob.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OptimizationJob] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<OptimizationJob?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<OptimizationJobUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<OptimizationJob>(
      id,
      columnValues: columnValues(OptimizationJob.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [OptimizationJob]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OptimizationJob>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<OptimizationJobUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<OptimizationJobTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OptimizationJobTable>? orderBy,
    _is.OrderByListBuilder<OptimizationJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<OptimizationJob>(
      columnValues: columnValues(OptimizationJob.t.updateTable),
      where: where(OptimizationJob.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OptimizationJob.t),
      orderByList: orderByList?.call(OptimizationJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [OptimizationJob]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OptimizationJob>> delete(
    _is.DatabaseSession session,
    List<OptimizationJob> rows, {
    _is.OrderByBuilder<OptimizationJobTable>? orderBy,
    _is.OrderByListBuilder<OptimizationJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<OptimizationJob>(
      rows,
      orderBy: orderBy?.call(OptimizationJob.t),
      orderByList: orderByList?.call(OptimizationJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [OptimizationJob].
  Future<OptimizationJob> deleteRow(
    _is.DatabaseSession session,
    OptimizationJob row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<OptimizationJob>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OptimizationJob>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<OptimizationJobTable> where,
    _is.OrderByBuilder<OptimizationJobTable>? orderBy,
    _is.OrderByListBuilder<OptimizationJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<OptimizationJob>(
      where: where(OptimizationJob.t),
      orderBy: orderBy?.call(OptimizationJob.t),
      orderByList: orderByList?.call(OptimizationJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OptimizationJobTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<OptimizationJob>(
      where: where?.call(OptimizationJob.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [OptimizationJob] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<OptimizationJobTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<OptimizationJob>(
      where: where(OptimizationJob.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
