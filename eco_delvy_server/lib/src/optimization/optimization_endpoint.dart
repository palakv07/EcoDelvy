import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'optimization_payload_validator.dart';

class OptimizationEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<OptimizationJob> start(
    Session session, {
    required String payloadJson,
    required String solver,
    required int timeLimit,
    required double? vehiclePenaltyWeight,
    required double distanceWeight,
    required double mipGap,
  }) async {
    OptimizationPayloadValidator.parseAndValidate(payloadJson);
    OptimizationPayloadValidator.validateSolverSettings(
      solver: solver,
      timeLimit: timeLimit,
      vehiclePenaltyWeight: vehiclePenaltyWeight,
      distanceWeight: distanceWeight,
      mipGap: mipGap,
    );

    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) {
      throw StateError('An authenticated user is required to start a job.');
    }

    return OptimizationJob.db.insertRow(
      session,
      OptimizationJob(
        userIdentifier: userIdentifier,
        status: 'queued',
        solver: solver,
        payloadJson: payloadJson,
        timeLimit: timeLimit,
        vehiclePenaltyWeight: vehiclePenaltyWeight,
        distanceWeight: distanceWeight,
        mipGap: mipGap,
        resultJson: null,
        errorMessage: null,
        createdAt: DateTime.now().toUtc(),
        startedAt: null,
        completedAt: null,
        attemptCount: 0,
        leaseExpiresAt: null,
        leaseToken: null,
        lastLogSequence: 0,
      ),
    );
  }

  Future<OptimizationJob> getJob(Session session, int jobId) async {
    final job = await OptimizationJob.db.findById(session, jobId);
    if (job == null ||
        job.userIdentifier != session.authenticated?.userIdentifier) {
      throw StateError('Optimization job not found.');
    }
    return job;
  }

  Future<List<OptimizationLog>> getLogs(
    Session session,
    int jobId,
    int afterSequence,
  ) async {
    await getJob(session, jobId);
    final logs = await OptimizationLog.db.find(
      session,
      where: (table) =>
          table.jobId.equals(jobId) & (table.sequence > afterSequence),
      orderBy: (table) => table.sequence,
      limit: 500,
    );
    return logs;
  }
}
