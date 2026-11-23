/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:eco_delvy_client/src/protocol/optimization/optimization_log.dart'
    as _ist9bqdt;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'optimization/optimization_job.dart' as _i9k4eqq4;
import 'optimization/optimization_log.dart' as _io9o31tr;
export 'optimization/optimization_job.dart';
export 'optimization/optimization_log.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager
    implements _isc.ProtocolDeserializationProvider {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  @override
  _isc.ProtocolDeserialization get deserializationMetadata =>
      _isc.ProtocolDeserialization.cached(
        this,
        types: const [
          _isc.getType<_i9k4eqq4.OptimizationJob>,
          _isc.getType<_io9o31tr.OptimizationLog>,
          _isc.getType<_i9k4eqq4.OptimizationJob?>,
          _isc.getType<_io9o31tr.OptimizationLog?>,
          _isc.getType<List<_ist9bqdt.OptimizationLog>>,
        ],
        modules: const [
          _iaic.Protocol.new,
          _iacc.Protocol.new,
        ],
        classNames: const [
          'OptimizationJob',
          'OptimizationLog',
        ],
      );

  static String? getClassNameFromObjectJson(dynamic data) =>
      _isc.ProtocolDeserialization.readClassName(data);

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    final rawDataClassName = _isc.ProtocolDeserialization.readClassName(data);
    final dataClassName = rawDataClassName;
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i9k4eqq4.OptimizationJob) {
      return _i9k4eqq4.OptimizationJob.fromJson(data) as T;
    }
    if (t == _io9o31tr.OptimizationLog) {
      return _io9o31tr.OptimizationLog.fromJson(data) as T;
    }
    if (t == _isc.getType<_i9k4eqq4.OptimizationJob?>()) {
      return (data != null ? _i9k4eqq4.OptimizationJob.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_io9o31tr.OptimizationLog?>()) {
      return (data != null ? _io9o31tr.OptimizationLog.fromJson(data) : null)
          as T;
    }
    if (t == List<_ist9bqdt.OptimizationLog>) {
      return (data as List)
              .map((e) => deserialize<_ist9bqdt.OptimizationLog>(e))
              .toList()
          as T;
    }
    final modules = deserializationMetadata.modulesForDeserialization(
      t,
      className: rawDataClassName,
    );
    for (final module in modules) {
      try {
        return module.deserialize<T>(data, t);
      } on _isc.DeserializationTypeNotFoundException catch (_) {}
    }

    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i9k4eqq4.OptimizationJob => 'OptimizationJob',
      _io9o31tr.OptimizationLog => 'OptimizationLog',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('eco_delvy.', '');
    }

    switch (data) {
      case _i9k4eqq4.OptimizationJob():
        return 'OptimizationJob';
      case _io9o31tr.OptimizationLog():
        return 'OptimizationLog';
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'OptimizationJob') {
      return deserialize<_i9k4eqq4.OptimizationJob>(data['data']);
    }
    if (dataClassName == 'OptimizationLog') {
      return deserialize<_io9o31tr.OptimizationLog>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      return _iaic.Protocol().deserializeByClassName({
        ...data,
        'className': dataClassName.substring(19),
      });
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      return _iacc.Protocol().deserializeByClassName({
        ...data,
        'className': dataClassName.substring(20),
      });
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iaic.Protocol().registerHostProtocol('eco_delvy', this);
    _iacc.Protocol().registerHostProtocol('eco_delvy', this);
  }

  @override
  String getModuleName() => 'eco_delvy';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
