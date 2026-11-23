import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

class WorkerClaimRoute extends Route {
  WorkerClaimRoute() : super(methods: {Method.post});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final authorizationFailure = _authorize(session, request);
    if (authorizationFailure != null) return authorizationFailure;

    final job = await session.db.transaction((transaction) async {
      final now = DateTime.now().toUtc();
      var next = await OptimizationJob.db.findFirstRow(
        session,
        where: (table) => table.status.equals('queued'),
        orderBy: (table) => table.createdAt,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.skipLocked,
        transaction: transaction,
      );
      next ??= await OptimizationJob.db.findFirstRow(
        session,
        where: (table) =>
            table.status.equals('running') &
            (table.leaseExpiresAt.equals(null) | (table.leaseExpiresAt < now)),
        orderBy: (table) => table.leaseExpiresAt,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.skipLocked,
        transaction: transaction,
      );
      if (next == null) return null;

      if ((next.attemptCount ?? 0) >= _maximumJobAttempts) {
        next
          ..status = 'failed'
          ..errorMessage = 'Worker lease expired too many times.'
          ..completedAt = now
          ..leaseExpiresAt = null
          ..leaseToken = null;
        await OptimizationJob.db.updateRow(
          session,
          next,
          transaction: transaction,
        );
        return null;
      }

      if (next.lastLogSequence == null) {
        final logs = await OptimizationLog.db.find(
          session,
          where: (table) => table.jobId.equals(next!.id!),
          orderBy: (table) => table.sequence,
          transaction: transaction,
        );
        var lastSequence = 0;
        for (final log in logs) {
          if (log.sequence > lastSequence) lastSequence = log.sequence;
        }
        next.lastLogSequence = lastSequence;
      }

      next
        ..status = 'running'
        ..startedAt ??= now
        ..attemptCount = (next.attemptCount ?? 0) + 1
        ..leaseExpiresAt = now.add(_workerLeaseDuration)
        ..leaseToken = _newLeaseToken();
      return OptimizationJob.db.updateRow(
        session,
        next,
        transaction: transaction,
      );
    });

    if (job == null) return Response.noContent();
    return _jsonResponse(200, {
      'jobId': job.id,
      'leaseToken': job.leaseToken,
      'payload': jsonDecode(job.payloadJson),
      'solver': job.solver,
      'timeLimit': job.timeLimit,
      'vehiclePenaltyWeight': job.vehiclePenaltyWeight,
      'distanceWeight': job.distanceWeight,
      'mipGap': job.mipGap,
    });
  }
}

class WorkerLeaseRoute extends Route {
  WorkerLeaseRoute() : super(methods: {Method.post});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final authorizationFailure = _authorize(session, request);
    if (authorizationFailure != null) return authorizationFailure;

    final Map<String, dynamic> body;
    try {
      body = await _readObject(request);
    } on FormatException catch (error) {
      return _jsonResponse(400, {'error': error.message});
    }

    final jobId = body['jobId'];
    final leaseToken = body['leaseToken'];
    if (jobId is! int || leaseToken is! String || leaseToken.isEmpty) {
      return _jsonResponse(400, {'error': 'Invalid lease request.'});
    }

    final renewed = await session.db.transaction((transaction) async {
      final job = await OptimizationJob.db.findById(
        session,
        jobId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (job == null ||
          job.status != 'running' ||
          job.leaseToken != leaseToken) {
        return false;
      }
      job.leaseExpiresAt = DateTime.now().toUtc().add(_workerLeaseDuration);
      await OptimizationJob.db.updateRow(
        session,
        job,
        transaction: transaction,
      );
      return true;
    });
    if (!renewed) {
      return _jsonResponse(409, {'error': 'Worker lease is no longer active.'});
    }
    return _jsonResponse(200, {'renewed': true});
  }
}

class WorkerLogRoute extends Route {
  WorkerLogRoute() : super(methods: {Method.post});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final authorizationFailure = _authorize(session, request);
    if (authorizationFailure != null) return authorizationFailure;

    final Map<String, dynamic> body;
    try {
      body = await _readObject(request);
    } on FormatException catch (error) {
      return _jsonResponse(400, {'error': error.message});
    }

    final jobId = body['jobId'];
    final leaseToken = body['leaseToken'];
    final messages = body['messages'];
    if (jobId is! int ||
        leaseToken is! String ||
        leaseToken.isEmpty ||
        messages is! List ||
        messages.any(
          (message) => message is! String || message.length > 4096,
        )) {
      return _jsonResponse(400, {'error': 'Invalid log batch.'});
    }

    final accepted = await session.db.transaction((transaction) async {
      final job = await OptimizationJob.db.findById(
        session,
        jobId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (job == null ||
          job.status != 'running' ||
          job.leaseToken != leaseToken) {
        return false;
      }

      final timestamp = DateTime.now().toUtc();
      for (final message in messages.cast<String>()) {
        await OptimizationLog.db.insertRow(
          session,
          OptimizationLog(
            jobId: jobId,
            sequence: job.lastLogSequence = (job.lastLogSequence ?? 0) + 1,
            message: message,
            createdAt: timestamp,
          ),
          transaction: transaction,
        );
      }
      await OptimizationJob.db.updateRow(
        session,
        job,
        transaction: transaction,
      );
      return true;
    });
    if (!accepted) {
      return _jsonResponse(409, {'error': 'Worker lease is no longer active.'});
    }

    return _jsonResponse(200, {'accepted': messages.length});
  }
}

class WorkerCompleteRoute extends Route {
  WorkerCompleteRoute() : super(methods: {Method.post});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final authorizationFailure = _authorize(session, request);
    if (authorizationFailure != null) return authorizationFailure;

    final Map<String, dynamic> body;
    try {
      body = await _readObject(request);
    } on FormatException catch (error) {
      return _jsonResponse(400, {'error': error.message});
    }

    final jobId = body['jobId'];
    final leaseToken = body['leaseToken'];
    final result = body['result'];
    final errorMessage = body['errorMessage'];
    if (jobId is! int ||
        leaseToken is! String ||
        leaseToken.isEmpty ||
        (result != null && result is! Map<String, dynamic>) ||
        (errorMessage != null && errorMessage is! String)) {
      return _jsonResponse(400, {'error': 'Invalid completion payload.'});
    }

    final status = await session.db.transaction((transaction) async {
      final job = await OptimizationJob.db.findById(
        session,
        jobId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (job == null ||
          job.status != 'running' ||
          job.leaseToken != leaseToken) {
        return null;
      }

      job
        ..status = errorMessage == null ? 'succeeded' : 'failed'
        ..resultJson = result == null ? null : jsonEncode(result)
        ..errorMessage = errorMessage as String?
        ..completedAt = DateTime.now().toUtc()
        ..leaseExpiresAt = null
        ..leaseToken = null;
      await OptimizationJob.db.updateRow(
        session,
        job,
        transaction: transaction,
      );
      return job.status;
    });
    if (status == null) {
      return _jsonResponse(409, {'error': 'Worker lease is no longer active.'});
    }
    return _jsonResponse(200, {'status': status});
  }
}

class ExamplesDownloadRoute extends Route {
  ExamplesDownloadRoute() : super();

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final archive = Archive();
    const exampleNames = [
      'CVRPTW_SMALL.json',
      'CVRPTW_MEDIUM.json',
      'CVRPTW_LARGE.json',
    ];
    for (final name in exampleNames) {
      final candidates = [
        File('./assets/inputs/$name'),
        File('eco_delvy_server/assets/inputs/$name'),
        File('inputs/$name'),
        File('../inputs/$name'),
      ];
      File? source;
      for (final candidate in candidates) {
        if (await candidate.exists()) {
          source = candidate;
          break;
        }
      }
      if (source == null) {
        throw StateError('Required example input "$name" was not found.');
      }
      final bytes = await source.readAsBytes();
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));
    return Response.ok(
      body: Body.fromData(zipBytes, mimeType: MimeType('application', 'zip')),
      headers: Headers.build((headers) {
        headers['content-disposition'] = [
          'attachment; filename="cvrptw_examples.zip"',
        ];
      }),
    );
  }
}

Response? _authorize(Session session, Request request) {
  final expected =
      session.passwords['optimizationWorkerToken'] ??
      Platform.environment['OPTIMIZATION_WORKER_TOKEN'] ??
      'cvrptw-worker-token-dev-secret-2026';
  if (expected.isEmpty) {
    return _jsonResponse(503, {
      'error': 'Worker authentication is not configured.',
    });
  }
  final values = request.headers['x-worker-token'];
  final supplied = values == null || values.isEmpty ? null : values.first;
  if (supplied == null || !_constantTimeEquals(supplied, expected)) {
    return _jsonResponse(401, {'error': 'Unauthorized worker request.'});
  }
  return null;
}

bool _constantTimeEquals(String supplied, String expected) {
  var mismatch = supplied.length ^ expected.length;
  final length = supplied.length > expected.length
      ? supplied.length
      : expected.length;
  for (var index = 0; index < length; index++) {
    final suppliedCode = index < supplied.length
        ? supplied.codeUnitAt(index)
        : 0;
    final expectedCode = index < expected.length
        ? expected.codeUnitAt(index)
        : 0;
    mismatch |= suppliedCode ^ expectedCode;
  }
  return mismatch == 0;
}

const _maximumJobAttempts = 3;
const _workerLeaseDuration = Duration(minutes: 2);

String _newLeaseToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

Future<Map<String, dynamic>> _readObject(Request request) async {
  final text = await request.readAsString(maxLength: 1024 * 1024);
  final decoded = jsonDecode(text);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Request body must be a JSON object.');
  }
  return decoded;
}

Response _jsonResponse(int statusCode, Map<String, dynamic> value) {
  return Response(
    statusCode,
    body: Body.fromString(jsonEncode(value), mimeType: MimeType.json),
  );
}
