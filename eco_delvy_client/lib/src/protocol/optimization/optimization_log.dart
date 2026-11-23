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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

abstract class OptimizationLog
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int jobId;

  int sequence;

  String message;

  DateTime createdAt;

  /// Returns a shallow copy of this [OptimizationLog]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
  @_isc.useResult
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
