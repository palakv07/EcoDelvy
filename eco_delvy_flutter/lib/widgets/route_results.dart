import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResults extends StatelessWidget {
  const RouteResults({
    super.key,
    required this.solution,
    required this.onRouteTap,
  });

  final Map<String, dynamic> solution;
  final ValueChanged<Map<String, dynamic>> onRouteTap;

  @override
  Widget build(BuildContext context) {
    final status = solution['status'];
    if (status == 'no_active_customers') {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'There are no active customers for the selected date.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final routeValues = solution['routes'];
    final routes = routeValues is List
        ? routeValues
              .whereType<Map>()
              .map((route) => Map<String, dynamic>.from(route))
              .toList()
        : <Map<String, dynamic>>[];
    final summary = solution['summary'] is Map
        ? Map<String, dynamic>.from(solution['summary'] as Map)
        : <String, dynamic>{};
    if (summary.isEmpty && routes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('The solver returned no route data.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryPanel(
          summary: summary,
          solution: solution,
          routeCount: routes.length,
        ),
        const SizedBox(height: 16),
        if (routes.isNotEmpty) ...[
          _TimelinePanel(routes: routes),
          const SizedBox(height: 16),
          _RoutesPanel(routes: routes, onRouteTap: onRouteTap),
        ],
      ],
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.summary,
    required this.solution,
    required this.routeCount,
  });

  final Map<String, dynamic> summary;
  final Map<String, dynamic> solution;
  final int routeCount;

  @override
  Widget build(BuildContext context) {
    final metrics = <(String, String, IconData)>[
      (
        'Vehicles used',
        _display(summary['num_vehicles_used'] ?? routeCount),
        Icons.local_shipping_outlined,
      ),
      (
        'Total distance',
        _displayDistance(
          summary['total_distance_km'] ?? summary['total_distance'],
        ),
        Icons.route_outlined,
      ),
      (
        'Delivered load',
        '${_display(summary['total_load'])} units',
        Icons.inventory_2_outlined,
      ),
      (
        'Average saturation',
        '${_display(summary['average_saturation_pct'])}%',
        Icons.pie_chart_outline,
      ),
      (
        'Solver',
        _display(solution['solver']),
        Icons.functions,
      ),
      (
        'Execution time',
        solution['execution_time_seconds'] is num
            ? '${(solution['execution_time_seconds'] as num).toStringAsFixed(2)} s'
            : '—',
        Icons.timer_outlined,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solution summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (solution['date'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Date: ${solution['date']}'),
              ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 560
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final (label, value, icon) in metrics)
                      SizedBox(
                        width: width,
                        child: _MetricCard(
                          label: label,
                          value: value,
                          icon: icon,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.routes});

  final List<Map<String, dynamic>> routes;

  @override
  Widget build(BuildContext context) {
    final timeValues = <double>[];
    for (final route in routes) {
      for (final stop in _routeStops(route)) {
        final arrival = _arrival(stop);
        timeValues
          ..add(arrival)
          ..add(arrival + _serviceMinutes(stop));
      }
    }
    if (timeValues.isEmpty) return const SizedBox.shrink();
    var minimum =
        (timeValues.reduce((left, right) => math.min(left, right)) / 60)
            .floor() *
        60.0;
    var maximum =
        (timeValues.reduce((left, right) => math.max(left, right)) / 60)
            .ceil() *
        60.0;
    if (maximum <= minimum) maximum = minimum + 60;
    final duration = maximum - minimum;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final tickIntervals = compact ? 2 : 6;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery timeline',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (!compact) const SizedBox(width: 160),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var index = 0; index <= tickIntervals; index++)
                            Text(
                              _clock(
                                minimum + duration * index / tickIntervals,
                              ),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final route in routes) ...[
                  _TimelineRoute(
                    route: route,
                    minimum: minimum,
                    duration: duration,
                    compact: compact,
                  ),
                  const SizedBox(height: 12),
                ],
                const Row(
                  children: [
                    _LegendDot(color: Color(0xFF059669), label: 'Travel'),
                    SizedBox(width: 18),
                    _LegendDot(color: Color(0xFF6EE7B7), label: 'Service'),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TimelineRoute extends StatelessWidget {
  const _TimelineRoute({
    required this.route,
    required this.minimum,
    required this.duration,
    required this.compact,
  });

  final Map<String, dynamic> route;
  final double minimum;
  final double duration;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final stops = _routeStops(route);
    final segments = <_TimelineSegment>[];
    for (var index = 1; index < stops.length; index++) {
      final previous = stops[index - 1];
      final current = stops[index];
      final previousArrival = _arrival(previous);
      final departure = previousArrival + _serviceMinutes(previous);
      final arrival = _arrival(current);
      if (arrival > departure) {
        segments.add(
          _TimelineSegment(
            start: departure,
            end: arrival,
            label: 'Travel',
            color: const Color(0xFF059669),
          ),
        );
      }
      final service = _serviceMinutes(current);
      if (service > 0) {
        segments.add(
          _TimelineSegment(
            start: arrival,
            end: arrival + service,
            label: _stopName(current, index),
            color: const Color(0xFF6EE7B7),
          ),
        );
      }
    }

    final label = Text(
      'Vehicle ${_number(route['vehicle_id'], 0).toInt() + 1}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleSmall,
    );
    final bar = SizedBox(
      height: 28,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            for (final segment in segments)
              Positioned(
                left:
                    ((segment.start - minimum) /
                            duration *
                            constraints.maxWidth)
                        .clamp(0, constraints.maxWidth)
                        .toDouble(),
                width: math
                    .max(
                      2.0,
                      ((segment.end - segment.start) /
                              duration *
                              constraints.maxWidth)
                          .clamp(0, constraints.maxWidth)
                          .toDouble(),
                    )
                    .toDouble(),
                top: 3,
                bottom: 3,
                child: Tooltip(
                  message: segment.label,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: segment.color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: bar),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(width: 160, child: label),
        Expanded(child: bar),
      ],
    );
  }
}

class _TimelineSegment {
  const _TimelineSegment({
    required this.start,
    required this.end,
    required this.label,
    required this.color,
  });

  final double start;
  final double end;
  final String label;
  final Color color;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _RoutesPanel extends StatelessWidget {
  const _RoutesPanel({required this.routes, required this.onRouteTap});

  final List<Map<String, dynamic>> routes;
  final ValueChanged<Map<String, dynamic>> onRouteTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routes (${routes.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 850 ? 2 : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var index = 0; index < routes.length; index++)
                      SizedBox(
                        width: width,
                        child: _RouteCard(
                          route: routes[index],
                          tripNumber: index + 1,
                          onTap: () => onRouteTap(routes[index]),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.tripNumber,
    required this.onTap,
  });

  final Map<String, dynamic> route;
  final int tripNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stops = _routeStops(route);
    final firstTime = stops.isEmpty ? '—' : _stopTime(stops.first);
    final lastTime = stops.isEmpty ? '—' : _stopTime(stops.last);
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Vehicle ${_number(route['vehicle_id'], 0).toInt() + 1}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Chip(label: Text('Trip $tripNumber')),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _RouteValue(
                    icon: Icons.route,
                    value: _distance(
                      route['distance_formatted'],
                      route['distance'],
                    ),
                  ),
                  _RouteValue(
                    icon: Icons.inventory_2_outlined,
                    value:
                        '${_display(route['load_formatted'] ?? route['load'])} load',
                  ),
                  _RouteValue(
                    icon: Icons.timer_outlined,
                    value: _display(
                      route['duration_formatted'] ?? route['duration_minutes'],
                    ),
                  ),
                  _RouteValue(
                    icon: Icons.place_outlined,
                    value:
                        '${_number(route['num_customers'], 0).toInt()} stops',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final timeRange = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 18),
                      const SizedBox(width: 6),
                      Text('$firstTime  →  $lastTime'),
                    ],
                  );
                  final mapButton = TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View map'),
                  );
                  if (constraints.maxWidth < 360) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        timeRange,
                        const SizedBox(height: 8),
                        mapButton,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      timeRange,
                      const Spacer(),
                      mapButton,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteValue extends StatelessWidget {
  const _RouteValue({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 5),
        Text(value),
      ],
    );
  }
}

class RouteMapDialog extends StatefulWidget {
  const RouteMapDialog({super.key, required this.route});

  final Map<String, dynamic> route;

  @override
  State<RouteMapDialog> createState() => _RouteMapDialogState();
}

class _RouteMapDialogState extends State<RouteMapDialog> {
  final MapController _mapController = MapController();
  late final List<Map<String, dynamic>> _stops = _routeStops(widget.route);
  late final List<int> _locationStopIndexes = [
    for (var index = 0; index < _stops.length; index++)
      if (_coordinates(_stops[index]) != null) index,
  ];
  late final List<LatLng> _locations = [
    for (final index in _locationStopIndexes) _coordinates(_stops[index])!,
  ];
  List<LatLng> _path = [];
  bool _loading = true;
  bool _usedRoadRouting = false;
  String? _routingMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRoute());
  }

  Future<void> _loadRoute() async {
    if (_locations.length < 2) {
      setState(() {
        _path = _locations;
        _loading = false;
      });
      return;
    }
    try {
      final coordinates = _locations
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordinates'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw StateError('OSRM returned HTTP ${response.statusCode}.');
      }
      final data = jsonDecode(response.body);
      final routes = data is Map ? data['routes'] : null;
      if (data is! Map ||
          data['code'] != 'Ok' ||
          routes is! List ||
          routes.isEmpty ||
          routes.first is! Map) {
        throw StateError('OSRM did not return a route for these stops.');
      }
      final geometry = (routes.first as Map)['geometry'];
      final coordinatesData = geometry is Map ? geometry['coordinates'] : null;
      if (coordinatesData is! List || coordinatesData.isEmpty) {
        throw StateError('OSRM returned an empty route geometry.');
      }
      final path = coordinatesData.map<LatLng>((coordinate) {
        if (coordinate is! List ||
            coordinate.length != 2 ||
            coordinate[0] is! num ||
            coordinate[1] is! num) {
          throw const FormatException('OSRM returned invalid coordinates.');
        }
        return LatLng(
          (coordinate[1] as num).toDouble(),
          (coordinate[0] as num).toDouble(),
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _path = path;
        _usedRoadRouting = true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _path = _locations;
        _routingMessage =
            'Road routing unavailable; showing straight lines. $error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = math
        .min(MediaQuery.sizeOf(context).width - 32, 1160.0)
        .toDouble();
    final height = math
        .min(MediaQuery.sizeOf(context).height - 32, 820.0)
        .toDouble();
    final center = _locations.isEmpty ? null : _locations.first;
    final routeStops = _stops;
    return Dialog(
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Vehicle ${_number(widget.route['vehicle_id'], 0).toInt() + 1} route',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close map',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  _RouteValue(
                    icon: Icons.route,
                    value: _distance(
                      widget.route['distance_formatted'],
                      widget.route['distance'],
                    ),
                  ),
                  _RouteValue(
                    icon: Icons.inventory_2_outlined,
                    value:
                        '${_display(widget.route['load_formatted'] ?? widget.route['load'])} load',
                  ),
                  _RouteValue(
                    icon: Icons.timer_outlined,
                    value: _display(
                      widget.route['duration_formatted'] ??
                          widget.route['duration_minutes'],
                    ),
                  ),
                  _RouteValue(
                    icon: Icons.place_outlined,
                    value:
                        '${_number(widget.route['num_customers'], 0).toInt()} customers',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_routingMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _routingMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 720;
                    final details = _RouteStops(stops: routeStops);
                    final map = center == null
                        ? Container(
                            color: const Color(0xFFF1F5F9),
                            alignment: Alignment.center,
                            child: const Text(
                              'This route has no valid coordinates to display.',
                            ),
                          )
                        : Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: center,
                                  initialZoom: 9,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'com.ecodelvy.optimizer',
                                    maxZoom: 19,
                                  ),
                                  if (_path.length > 1)
                                    PolylineLayer(
                                      polylines: [
                                        Polyline(
                                          points: _path,
                                          strokeWidth: 4,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                  MarkerLayer(
                                    markers: [
                                      for (
                                        var index = 0;
                                        index < _locations.length;
                                        index++
                                      )
                                        Marker(
                                          point: _locations[index],
                                          width: 38,
                                          height: 38,
                                          child: Tooltip(
                                            message:
                                                _isDepotStop(
                                                  routeStops[_locationStopIndexes[index]],
                                                )
                                                ? 'Depot'
                                                : _stopName(
                                                    routeStops[_locationStopIndexes[index]],
                                                    _locationStopIndexes[index],
                                                  ),
                                            child: InkWell(
                                              customBorder:
                                                  const CircleBorder(),
                                              onTap: () => _showStopDetails(
                                                context,
                                                routeStops[_locationStopIndexes[index]],
                                                _locationStopIndexes[index],
                                                widget.route,
                                              ),
                                              child: CircleAvatar(
                                                backgroundColor:
                                                    _isDepotStop(
                                                      routeStops[_locationStopIndexes[index]],
                                                    )
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.secondary,
                                                foregroundColor: Colors.white,
                                                child: Text(
                                                  _isDepotStop(
                                                        routeStops[_locationStopIndexes[index]],
                                                      )
                                                      ? 'D'
                                                      : '${_locationStopIndexes[index]}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  RichAttributionWidget(
                                    attributions: [
                                      TextSourceAttribution(
                                        'OpenStreetMap contributors',
                                        onTap: () {},
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: Card(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Zoom in',
                                        onPressed: () {
                                          final camera = _mapController.camera;
                                          _mapController.move(
                                            camera.center,
                                            camera.zoom + 1,
                                          );
                                        },
                                        icon: const Icon(Icons.add_rounded),
                                      ),
                                      const Divider(height: 1),
                                      IconButton(
                                        tooltip: 'Zoom out',
                                        onPressed: () {
                                          final camera = _mapController.camera;
                                          _mapController.move(
                                            camera.center,
                                            camera.zoom - 1,
                                          );
                                        },
                                        icon: const Icon(Icons.remove_rounded),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_loading)
                                const Positioned.fill(
                                  child: ColoredBox(
                                    color: Color(0x66000000),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ),
                              if (!_loading && !_usedRoadRouting)
                                Positioned(
                                  left: 12,
                                  top: 12,
                                  child: Chip(
                                    avatar: const Icon(
                                      Icons.show_chart,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Straight-line fallback',
                                    ),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                  ),
                                ),
                            ],
                          );
                    if (narrow) {
                      return Column(
                        children: [
                          SizedBox(
                            height: constraints.maxHeight * 0.58,
                            child: map,
                          ),
                          const SizedBox(height: 12),
                          Expanded(child: details),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        SizedBox(width: 340, child: details),
                        const SizedBox(width: 14),
                        Expanded(child: map),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStopDetails(
    BuildContext context,
    Map<String, dynamic> stop,
    int index,
    Map<String, dynamic> route,
  ) {
    final info = stop['location_info'] is Map
        ? Map<String, dynamic>.from(stop['location_info'] as Map)
        : <String, dynamic>{};
    final isDepot = _isDepotStop(stop);
    final demand =
        stop['demand'] ??
        (_number(stop['load_before'], 0) - _number(stop['load_after'], 0));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDepot ? 'Depot' : _stopName(stop, index),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (!isDepot && info['customer_id'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text('Customer ID ${info['customer_id']}'),
                ),
              const SizedBox(height: 14),
              _StopDetailRow(
                label: 'Vehicle',
                value: 'Vehicle ${_number(route['vehicle_id'], 0).toInt() + 1}',
              ),
              _StopDetailRow(
                label: 'Arrival time',
                value: _stopTime(stop),
              ),
              if (!isDepot)
                _StopDetailRow(label: 'Demand', value: '$demand units'),
              if (stop['time_window_formatted'] != null)
                _StopDetailRow(
                  label: 'Time window',
                  value: stop['time_window_formatted'].toString(),
                ),
              if (info['location'] is List)
                _StopDetailRow(
                  label: 'Coordinates',
                  value: _coordinateLabel(info['location']),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _coordinateLabel(Object? value) {
  if (value is List &&
      value.length == 2 &&
      value[0] is num &&
      value[1] is num) {
    return '${(value[0] as num).toStringAsFixed(5)}, '
        '${(value[1] as num).toStringAsFixed(5)}';
  }
  return '—';
}

class _StopDetailRow extends StatelessWidget {
  const _StopDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _RouteStops extends StatelessWidget {
  const _RouteStops({required this.stops});

  final List<Map<String, dynamic>> stops;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return const Center(child: Text('No stop details available.'));
    }
    return ListView.separated(
      itemCount: stops.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final stop = stops[index];
        final info = stop['location_info'] is Map
            ? Map<String, dynamic>.from(stop['location_info'] as Map)
            : <String, dynamic>{};
        final isDepot = info['type'] == 'depot' || stop['location'] == 0;
        final title = isDepot
            ? (index == stops.length - 1 && index > 0
                  ? 'Return to depot'
                  : 'Depot')
            : _stopName(stop, index);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 4,
          ),
          leading: CircleAvatar(
            radius: 16,
            child: Text(isDepot ? 'D' : '$index'),
          ),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [
              'Arrival ${_stopTime(stop)}',
              if (!isDepot && stop['time_window_formatted'] != null)
                'Window ${stop['time_window_formatted']}',
              if (stop['load_before'] != null && stop['load_after'] != null)
                'Load ${stop['load_before']} → ${stop['load_after']}',
              if (_number(stop['segment_distance'], 0) > 0)
                '${_distance(stop['segment_distance_formatted'], stop['segment_distance'])} from previous',
            ].join(' · '),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

bool _isDepotStop(Map<String, dynamic> stop) {
  final info = stop['location_info'];
  final type = info is Map ? info['type'] : null;
  return type == 'depot' || (type == null && stop['location'] == 0);
}

List<Map<String, dynamic>> _routeStops(Map<String, dynamic> route) {
  final values = route['route'];
  if (values is! List) return [];
  return values
      .whereType<Map>()
      .map((stop) => Map<String, dynamic>.from(stop))
      .toList();
}

double _arrival(Map<String, dynamic> stop) =>
    _number(stop['arrival_time'] ?? stop['time'], 0).toDouble();

double _serviceMinutes(Map<String, dynamic> stop) {
  final info = stop['location_info'] is Map
      ? Map<String, dynamic>.from(stop['location_info'] as Map)
      : <String, dynamic>{};
  if (info['type'] == 'depot' ||
      stop['location'] == 0 ||
      (stop['demand'] != null && _number(stop['demand'], 0) == 0)) {
    return 0;
  }
  final demand = stop['demand'] != null
      ? _number(stop['demand'], 0)
      : _number(stop['load_before'], 0) - _number(stop['load_after'], 0);
  return (10 + 2 * demand).toDouble();
}

LatLng? _coordinates(Map<String, dynamic> stop) {
  final info = stop['location_info'];
  final location = info is Map ? info['location'] : null;
  if (location is! List ||
      location.length != 2 ||
      location[0] is! num ||
      location[1] is! num) {
    return null;
  }
  return LatLng(
    (location[0] as num).toDouble(),
    (location[1] as num).toDouble(),
  );
}

String _stopName(Map<String, dynamic> stop, int index) {
  final info = stop['location_info'];
  if (info is Map) {
    return (info['customer_name'] ?? info['customer_id'] ?? 'Customer $index')
        .toString();
  }
  return 'Customer $index';
}

String _stopTime(Map<String, dynamic> stop) =>
    (stop['time_formatted'] ?? _clock(_arrival(stop))).toString();

String _clock(num minutesValue) {
  final minutes = minutesValue.toInt();
  return '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}

num _number(dynamic value, num fallback) =>
    value is num && value.isFinite ? value : fallback;

String _display(dynamic value) {
  if (value == null) return '—';
  if (value is num) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
  return value.toString();
}

String _displayDistance(dynamic value) {
  if (value is String) return value;
  if (value is num) return '${value.toStringAsFixed(2)} km';
  return '—';
}

String _distance(dynamic formatted, dynamic value) {
  if (formatted is String && formatted.isNotEmpty) return formatted;
  if (value is num) return '${value.toStringAsFixed(2)} km';
  return '—';
}
