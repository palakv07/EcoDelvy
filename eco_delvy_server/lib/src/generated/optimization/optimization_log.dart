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

abstract class OptimizationLog
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  OptimizationLog._({
    this.id,
    required this.jobId,
    required this.sequence,
    required this.message,
    required this.createdAt,
  });

  factory OptimizationLog({
    int? id,
    required int jobId,
    required int sequence,
    required String message,
    required DateTime createdAt,
  }) = _OptimizationLogImpl;

  factory OptimizationLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return OptimizationLog(
      id: jsonSerialization['id'] as int?,
      jobId: jsonSerialization['jobId'] as int,
      sequence: jsonSerialization['sequence'] as int,
      message: jsonSerialization['message'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = OptimizationLogTable();

  static const db = OptimizationLogRepository._();

  @override
  int? id;

  int jobId;

  int sequence;

  String message;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [OptimizationLog]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  OptimizationLog copyWith({
    int? id,
    int? jobId,
    int? sequence,
    String? message,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OptimizationLog',
      if (id != null) 'id': id,
      'jobId': jobId,
      'sequence': sequence,
      'message': message,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OptimizationLog',
      if (id != null) 'id': id,
      'jobId': jobId,
      'sequence': sequence,
      'message': message,
      'createdAt': createdAt.toJson(),
    };
  }

  static OptimizationLogInclude include() {
    return OptimizationLogInclude._();
  }

  static OptimizationLogIncludeList includeList({
    _is.WhereExpressionBuilder<OptimizationLogTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OptimizationLogTable>? orderBy,
    _is.OrderByListBuilder<OptimizationLogTable>? orderByList,
    OptimizationLogInclude? include,
  }) {
    return OptimizationLogIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OptimizationLog.t),
      orderByList: orderByList?.call(OptimizationLog.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OptimizationLogImpl extends OptimizationLog {
  _OptimizationLogImpl({
    int? id,
    required int jobId,
    required int sequence,
    required String message,
    required DateTime createdAt,
  }) : super._(
         id: id,
         jobId: jobId,
         sequence: sequence,
         message: message,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [OptimizationLog]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  OptimizationLog copyWith({
    Object? id = _Undefined,
    int? jobId,
    int? sequence,
    String? message,
    DateTime? createdAt,
  }) {
    return OptimizationLog(
      id: id is int? ? id : this.id,
      jobId: jobId ?? this.jobId,
      sequence: sequence ?? this.sequence,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class OptimizationLogUpdateTable extends _is.UpdateTable<OptimizationLogTable> {
  OptimizationLogUpdateTable(super.table);

  _is.ColumnValue<int, int> jobId(int value) => _is.ColumnValue(
    table.jobId,
    value,
  );

  _is.ColumnValue<int, int> sequence(int value) => _is.ColumnValue(
    table.sequence,
    value,
  );

  _is.ColumnValue<String, String> message(String value) => _is.ColumnValue(
    table.message,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class OptimizationLogTable extends _is.Table<int?> {
  OptimizationLogTable({super.tableRelation})
    : super(tableName: 'optimization_log') {
    updateTable = OptimizationLogUpdateTable(this);
    jobId = _is.ColumnInt(
      'jobId',
      this,
    );
    sequence = _is.ColumnInt(
      'sequence',
      this,
    );
    message = _is.ColumnString(
      'message',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final OptimizationLogUpdateTable updateTable;

  late final _is.ColumnInt jobId;

  late final _is.ColumnInt sequence;

  late final _is.ColumnString message;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    jobId,
    sequence,
    message,
    createdAt,
  ];
}

class OptimizationLogInclude extends _is.IncludeObject {
  OptimizationLogInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => OptimizationLog.t;
}

class OptimizationLogIncludeList extends _is.IncludeList {
  OptimizationLogIncludeList._({
    _is.WhereExpressionBuilder<OptimizationLogTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(OptimizationLog.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => OptimizationLog.t;
}

class OptimizationLogRepository {
  const OptimizationLogRepository._();

  /// Returns a list of [OptimizationLog]s matching the given query parameters.
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
  Future<List<OptimizationLog>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OptimizationLogTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OptimizationLogTable>? orderBy,
    _is.OrderByListBuilder<OptimizationLogTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<OptimizationLog>(
      where: where?.call(OptimizationLog.t),
      orderBy: orderBy?.call(OptimizationLog.t),
      orderByList: orderByList?.call(OptimizationLog.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [OptimizationLog]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `OptimizationLog.t`.
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
  _ida.Stream<List<OptimizationLog>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OptimizationLogTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OptimizationLogTable>? orderBy,
    _is.OrderByListBuilder<OptimizationLogTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<OptimizationLog>(
      where: where?.call(OptimizationLog.t),
      orderBy: orderBy?.call(OptimizationLog.t),
      orderByList: orderByList?.call(OptimizationLog.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [OptimizationLog] matching the given query parameters.
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
  Future<OptimizationLog?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OptimizationLogTable>? where,
    int? offset,
    _is.OrderByBuilder<OptimizationLogTable>? orderBy,
    _is.OrderByListBuilder<OptimizationLogTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<OptimizationLog>(
      where: where?.call(OptimizationLog.t),
      orderBy: orderBy?.call(OptimizationLog.t),
      orderByList: orderByList?.call(OptimizationLog.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [OptimizationLog] by its [id] or null if no such row exists.
  Future<OptimizationLog?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<OptimizationLog>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [OptimizationLog]s in the list and returns the inserted rows.
  ///
  /// The returned [OptimizationLog]s will have their `id` fields set.
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
  Future<List<OptimizationLog>> insert(
    _is.DatabaseSession session,
    List<OptimizationLog> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<OptimizationLog>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [OptimizationLog] and returns the inserted row.
  ///
  /// The returned [OptimizationLog] will have its `id` field set.
  Future<OptimizationLog> insertRow(
    _is.DatabaseSession session,
    OptimizationLog row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<OptimizationLog>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [OptimizationLog]s in the list and returns the resulting rows.
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
  /// The returned [OptimizationLog]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OptimizationLog>> upsert(
    _is.DatabaseSession session,
    List<OptimizationLog> rows, {
    required _is.ColumnSelections<OptimizationLogTable> conflictColumns,
    _is.ColumnSelections<OptimizationLogTable>? updateColumns,
    _is.WhereExpressionBuilder<OptimizationLogTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<OptimizationLog>(
      rows,
      conflictColumns: conflictColumns(OptimizationLog.t),
      updateColumns: updateColumns?.call(OptimizationLog.t),
      updateWhere: updateWhere?.call(OptimizationLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [OptimizationLog] and returns the resulting row.
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
  /// The returned [OptimizationLog] will have its `id` field set.
  Future<OptimizationLog?> upsertRow(
    _is.DatabaseSession session,
    OptimizationLog row, {
    required _is.ColumnSelections<OptimizationLogTable> conflictColumns,
    _is.ColumnSelections<OptimizationLogTable>? updateColumns,
    _is.WhereExpressionBuilder<OptimizationLogTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<OptimizationLog>(
      row,
      conflictColumns: conflictColumns(OptimizationLog.t),
      updateColumns: updateColumns?.call(OptimizationLog.t),
      updateWhere: updateWhere?.call(OptimizationLog.t),
      transaction: transaction,
    );
  }

  /// Updates all [OptimizationLog]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OptimizationLog>> update(
    _is.DatabaseSession session,
    List<OptimizationLog> rows, {
    _is.ColumnSelections<OptimizationLogTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<OptimizationLog>(
      rows,
      columns: columns?.call(OptimizationLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [OptimizationLog]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<OptimizationLog> updateRow(
    _is.DatabaseSession session,
    OptimizationLog row, {
    _is.ColumnSelections<OptimizationLogTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<OptimizationLog>(
      row,
      columns: columns?.call(OptimizationLog.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OptimizationLog] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<OptimizationLog?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<OptimizationLogUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<OptimizationLog>(
      id,
      columnValues: columnValues(OptimizationLog.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [OptimizationLog]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OptimizationLog>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<OptimizationLogUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<OptimizationLogTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OptimizationLogTable>? orderBy,
    _is.OrderByListBuilder<OptimizationLogTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<OptimizationLog>(
      columnValues: columnValues(OptimizationLog.t.updateTable),
      where: where(OptimizationLog.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OptimizationLog.t),
      orderByList: orderByList?.call(OptimizationLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [OptimizationLog]s in the list and returns the deleted rows.
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
  Future<List<OptimizationLog>> delete(
    _is.DatabaseSession session,
    List<OptimizationLog> rows, {
    _is.OrderByBuilder<OptimizationLogTable>? orderBy,
    _is.OrderByListBuilder<OptimizationLogTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<OptimizationLog>(
      rows,
      orderBy: orderBy?.call(OptimizationLog.t),
      orderByList: orderByList?.call(OptimizationLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [OptimizationLog].
  Future<OptimizationLog> deleteRow(
    _is.DatabaseSession session,
    OptimizationLog row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<OptimizationLog>(
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
  Future<List<OptimizationLog>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<OptimizationLogTable> where,
    _is.OrderByBuilder<OptimizationLogTable>? orderBy,
    _is.OrderByListBuilder<OptimizationLogTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<OptimizationLog>(
      where: where(OptimizationLog.t),
      orderBy: orderBy?.call(OptimizationLog.t),
      orderByList: orderByList?.call(OptimizationLog.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OptimizationLogTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<OptimizationLog>(
      where: where?.call(OptimizationLog.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [OptimizationLog] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<OptimizationLogTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<OptimizationLog>(
      where: where(OptimizationLog.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
