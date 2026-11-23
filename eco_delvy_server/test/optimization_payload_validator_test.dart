import 'dart:convert';

import 'package:eco_delvy_server/src/optimization/optimization_payload_validator.dart';
import 'package:test/test.dart';

void main() {
  group('OptimizationPayloadValidator', () {
    test('accepts a problem with valid coordinates and vehicles', () {
      final payload = OptimizationPayloadValidator.parseAndValidate('''
        {
          "depot": {"location": [38.1, 13.2]},
          "vehicles": [{"capacity_units": 10}],
          "customers": [{"location": [38.2, 13.3], "demands_units": {"2026-01-01": 4}}]
        }
      ''');

      expect(payload['customers'], hasLength(1));
    });

    test('rejects invalid coordinates before queuing a job', () {
      expect(
        () => OptimizationPayloadValidator.parseAndValidate('''
          {
            "depot": {"location": [91, 13.2]},
            "vehicles": [{"capacity_units": 10}],
            "customers": [{"location": [38.2, 13.3]}]
          }
        '''),
        throwsFormatException,
      );
    });

    test('rejects invalid solver settings', () {
      expect(
        () => OptimizationPayloadValidator.validateSolverSettings(
          solver: 'ortools',
          timeLimit: 0,
          vehiclePenaltyWeight: null,
          distanceWeight: 1,
          mipGap: 0.01,
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid demand and time window values', () {
      for (final customer in [
        {
          'location': [38.2, 13.3],
          'demand_units': -1,
        },
        {
          'location': [38.2, 13.3],
          'time_window': {'start_min': 600, 'end_min': 300},
        },
      ]) {
        expect(
          () => OptimizationPayloadValidator.parseAndValidate(
            '{"depot":{"location":[38.1,13.2]},'
            '"vehicles":[{"capacity_units":10}],'
            '"customers":[${jsonEncode(customer)}]}',
          ),
          throwsFormatException,
        );
      }
    });
  });
}
