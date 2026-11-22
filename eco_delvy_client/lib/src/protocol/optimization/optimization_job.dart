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

abstract class OptimizationJob
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
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

  /// Returns a shallow copy of this [OptimizationJob]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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
    DateTime? startedAt = const _isc.$UndefinedDateTime(),
    DateTime? completedAt = const _isc.$UndefinedDateTime(),
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
       );

  /// Returns a shallow copy of this [OptimizationJob]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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
    DateTime? startedAt = const _isc.$UndefinedDateTime(),
    DateTime? completedAt = const _isc.$UndefinedDateTime(),
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
      startedAt: startedAt is _isc.UndefinedSentinel
          ? this.startedAt
          : startedAt,
      completedAt: completedAt is _isc.UndefinedSentinel
          ? this.completedAt
          : completedAt,
    );
  }
}
