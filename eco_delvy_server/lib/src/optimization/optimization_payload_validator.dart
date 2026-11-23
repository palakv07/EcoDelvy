import 'dart:convert';

class OptimizationPayloadValidator {
  static Map<String, dynamic> parseAndValidate(String payloadJson) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(payloadJson);
    } on FormatException catch (error) {
      throw FormatException('Input must be valid JSON: ${error.message}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The problem must be a JSON object.');
    }

    final depot = decoded['depot'];
    if (depot is! Map<String, dynamic>) {
      throw const FormatException('A depot object is required.');
    }
    _validateLocation(depot['location'], 'depot.location');

    final vehicles = decoded['vehicles'];
    if (vehicles is! List || vehicles.isEmpty) {
      throw const FormatException('At least one vehicle is required.');
    }
    for (var index = 0; index < vehicles.length; index++) {
      final vehicle = vehicles[index];
      if (vehicle is! Map<String, dynamic>) {
        throw FormatException('vehicles[$index] must be an object.');
      }
      final capacity = vehicle['capacity_units'];
      if (capacity is! int || capacity < 0) {
        throw FormatException(
          'vehicles[$index].capacity_units must be a non-negative integer.',
        );
      }
      final timeWindow = vehicle['time_window'];
      if (timeWindow != null) {
        _validateTimeWindow(timeWindow, 'vehicles[$index].time_window');
      }
    }

    final customers = decoded['customers'];
    if (customers is! List || customers.isEmpty) {
      throw const FormatException('At least one customer is required.');
    }
    for (var index = 0; index < customers.length; index++) {
      final customer = customers[index];
      if (customer is! Map<String, dynamic>) {
        throw FormatException('customers[$index] must be an object.');
      }
      _validateLocation(customer['location'], 'customers[$index].location');
      final demand = customer['demand_units'];
      if (demand != null) {
        _validateDemand(demand, 'customers[$index].demand_units');
      }
      final dateDemands = customer['demands_units'];
      if (dateDemands != null) {
        if (dateDemands is! Map<String, dynamic>) {
          throw FormatException(
            'customers[$index].demands_units must be an object keyed by date.',
          );
        }
        for (final entry in dateDemands.entries) {
          _validateDemand(
            entry.value,
            'customers[$index].demands_units.${entry.key}',
          );
        }
      }
      final timeWindow = customer['time_window'];
      if (timeWindow != null) {
        _validateTimeWindow(timeWindow, 'customers[$index].time_window');
      }
      final dateTimeWindows = customer['time_windows'];
      if (dateTimeWindows != null) {
        if (dateTimeWindows is! Map<String, dynamic>) {
          throw FormatException(
            'customers[$index].time_windows must be an object keyed by date.',
          );
        }
        for (final entry in dateTimeWindows.entries) {
          _validateTimeWindow(
            entry.value,
            'customers[$index].time_windows.${entry.key}',
          );
        }
      }
    }

    final metadata = decoded['metadata'];
    if (metadata != null) {
      if (metadata is! Map<String, dynamic>) {
        throw const FormatException('metadata must be an object.');
      }
      final depotTimeWindow = metadata['depot_time_window'];
      if (depotTimeWindow != null) {
        _validateTimeWindow(
          depotTimeWindow,
          'metadata.depot_time_window',
        );
      }
    }

    return decoded;
  }

  static void _validateDemand(dynamic value, String field) {
    if (value is! int || value < 0) {
      throw FormatException('$field must be a non-negative integer.');
    }
  }

  static void _validateTimeWindow(dynamic value, String field) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('$field must be an object.');
    }
    final start = value['start_min'];
    final end = value['end_min'];
    if (start is! int ||
        end is! int ||
        start < 0 ||
        end > 1440 ||
        start > end) {
      throw FormatException(
        '$field must contain valid start_min and end_min values.',
      );
    }
  }

  static void _validateLocation(dynamic value, String field) {
    if (value is! List || value.length != 2) {
      throw FormatException('$field must contain [latitude, longitude].');
    }
    final latitude = value[0];
    final longitude = value[1];
    if (latitude is! num ||
        longitude is! num ||
        latitude is bool ||
        longitude is bool ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw FormatException(
        '$field must contain valid geographic coordinates.',
      );
    }
  }

  static void validateSolverSettings({
    required String solver,
    required int timeLimit,
    required double? vehiclePenaltyWeight,
    required double distanceWeight,
    required double mipGap,
  }) {
    if (solver != 'ortools' && solver != 'gurobi') {
      throw const FormatException('Solver must be "ortools" or "gurobi".');
    }
    if (timeLimit < 1 || timeLimit > 3600) {
      throw const FormatException(
        'Time limit must be between 1 and 3600 seconds.',
      );
    }
    if (vehiclePenaltyWeight != null &&
        (!vehiclePenaltyWeight.isFinite || vehiclePenaltyWeight < 0)) {
      throw const FormatException(
        'Vehicle penalty weight must be a non-negative number.',
      );
    }
    if (!distanceWeight.isFinite ||
        distanceWeight < 0.1 ||
        distanceWeight > 10) {
      throw const FormatException(
        'Distance weight must be between 0.1 and 10.',
      );
    }
    if (!mipGap.isFinite || mipGap < 0.001 || mipGap > 0.5) {
      throw const FormatException('MIP gap must be between 0.001 and 0.5.');
    }
  }
}
