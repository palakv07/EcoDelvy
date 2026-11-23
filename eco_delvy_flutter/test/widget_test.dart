import 'package:eco_delvy/widgets/route_results.dart';
import 'package:eco_delvy/screens/optimizer_screen.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard navigates to optimizer before solving', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: OptimizerScreen()),
    );

    expect(find.text('Fleet Overview'), findsWidgets);
    await tester.tap(find.text('New optimization'));
    await tester.pumpAndSettle();
    expect(find.text('Browse JSON'), findsOneWidget);
    final solveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Run optimization'),
    );
    expect(solveButton.onPressed, isNull);
  });

  testWidgets('mobile navigation opens the customers empty state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: OptimizerScreen()),
    );

    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customers'));
    await tester.pumpAndSettle();

    expect(find.text('No Customers data loaded'), findsOneWidget);
    expect(find.text('Open route optimizer'), findsOneWidget);
  });

  testWidgets('route summary shows solver metrics and route details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              RouteResults(
                solution: {
                  'date': '2026-01-01',
                  'solver': 'ortools',
                  'execution_time_seconds': 2.5,
                  'summary': {
                    'num_vehicles_used': 1,
                    'total_distance_km': 12.5,
                    'total_load': 4,
                    'average_saturation_pct': 40,
                  },
                  'routes': [
                    {
                      'vehicle_id': 0,
                      'distance': 12.5,
                      'distance_formatted': '12.50 km',
                      'load': 4,
                      'load_formatted': '4 units',
                      'duration_formatted': '1h 20m',
                      'num_customers': 1,
                      'route': [
                        {'location': 0, 'time_formatted': '08:00'},
                        {'location': 1, 'time_formatted': '08:40'},
                        {'location': 0, 'time_formatted': '09:20'},
                      ],
                    },
                  ],
                },
                onRouteTap: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('12.50 km'), findsWidgets);
    expect(find.text('Delivery timeline'), findsOneWidget);
    expect(find.text('Vehicle 1'), findsWidgets);
    expect(find.text('Trip 1'), findsOneWidget);
  });

  testWidgets('customer stop name is not shown as Depot', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              RouteResults(
                solution: {
                  'routes': [
                    {
                      'vehicle_id': 0,
                      'route': [
                        {
                          'location': 0,
                          'location_info': {'type': 'depot'},
                        },
                        {
                          'location': 4,
                          'time': 510,
                          'time_formatted': '08:30',
                          'load_before': 12,
                          'load_after': 0,
                          'location_info': {
                            'type': 'customer',
                            'index': 4,
                            'customer_id': 1505,
                            'customer_name': 'TEST21',
                            'location': [38.1, 13.2],
                          },
                        },
                        {
                          'location': 0,
                          'location_info': {'type': 'depot'},
                        },
                      ],
                    },
                  ],
                },
                onRouteTap: (route) {
                  showDialog<void>(
                    context: tester.element(find.byType(RouteResults)),
                    builder: (_) => RouteMapDialog(route: route),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Vehicle 1').last);
    await tester.pumpAndSettle();

    expect(find.text('TEST21'), findsOneWidget);
    expect(find.text('Depot'), findsOneWidget);
    expect(find.text('Return to depot'), findsOneWidget);
  });
}
