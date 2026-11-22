import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../client.dart';
import '../core/app_config.dart';
import '../core/theme/app_theme.dart';
import '../widgets/route_results.dart';

enum _DashboardPage {
  overview,
  optimizer,
  customers,
  vehicles,
  history,
  analytics,
  settings,
}

class OptimizerScreen extends StatefulWidget {
  const OptimizerScreen({super.key});

  @override
  State<OptimizerScreen> createState() => _OptimizerScreenState();
}

class _OptimizerScreenState extends State<OptimizerScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _originalData;
  Map<String, dynamic>? _selectedData;
  List<int>? _selectedVehicleIndices;
  List<int>? _selectedCustomerIndices;
  Map<String, dynamic>? _solution;
  int? _jobId;
  String _jobStatus = 'idle';
  bool _busy = false;
  bool _showAdvanced = false;
  bool _sidebarCollapsed = false;
  bool _dropHovered = false;
  String? _error;
  String? _selectedFileName;
  int? _selectedFileSize;
  String _customerSearch = '';
  String _solver = 'ortools';
  DropzoneViewController? _dropzoneController;
  _DashboardPage _activePage = _DashboardPage.overview;
  final List<String> _logs = [];
  final _timeLimitController = TextEditingController(text: '60');
  final _vehiclePenaltyController = TextEditingController();
  final _distanceWeightController = TextEditingController(text: '1.0');
  final _mipGapController = TextEditingController(text: '0.01');

  @override
  void dispose() {
    _timeLimitController.dispose();
    _vehiclePenaltyController.dispose();
    _distanceWeightController.dispose();
    _mipGapController.dispose();
    super.dispose();
  }

  List<dynamic> _items(String key) =>
      (_selectedData?[key] as List<dynamic>?) ?? const [];

  List<dynamic> _originalItems(String key) =>
      (_originalData?[key] as List<dynamic>?) ?? const [];

  Future<void> _loadFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (files.isEmpty) return;

      final file = files.single;
      await _loadProblemFile(file.name, await file.readAsBytes());
    } on FormatException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Could not load the JSON file: $error');
    }
  }

  Future<void> _loadDroppedFile(DropzoneFileInterface file) async {
    try {
      if (!file.name.toLowerCase().endsWith('.json')) {
        throw const FormatException('Choose a JSON problem file.');
      }
      final controller = _dropzoneController;
      if (controller == null) {
        throw StateError('The file drop area is not ready yet.');
      }
      await _loadProblemFile(
        file.name,
        await controller.getFileData(file),
      );
    } on FormatException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Could not load the dropped file: $error');
    }
  }

  Future<void> _loadProblemFile(String fileName, Uint8List bytes) async {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['depot'] is! Map<String, dynamic> ||
        decoded['vehicles'] is! List ||
        decoded['customers'] is! List) {
      throw const FormatException(
        'JSON must contain depot, vehicles, and customers.',
      );
    }

    final data = Map<String, dynamic>.from(decoded);
    final vehicleCount = (data['vehicles'] as List).length;
    final customerCount = (data['customers'] as List).length;
    if (vehicleCount == 0 || customerCount == 0) {
      throw const FormatException(
        'The file must contain at least one vehicle and one customer.',
      );
    }
    if ((data['vehicles'] as List).any((item) => item is! Map) ||
        (data['customers'] as List).any((item) => item is! Map)) {
      throw const FormatException(
        'Every vehicle and customer entry must be an object.',
      );
    }

    setState(() {
      _originalData = data;
      _selectedFileName = fileName;
      _selectedFileSize = bytes.length;
      _selectedData = null;
      _selectedVehicleIndices = null;
      _selectedCustomerIndices = null;
      _solution = null;
      _logs.clear();
      _error = null;
    });
    await _showSelectionDialog();
  }

  void _removeProblemFile() {
    if (_busy) return;
    setState(() {
      _originalData = null;
      _selectedData = null;
      _selectedFileName = null;
      _selectedFileSize = null;
      _selectedVehicleIndices = null;
      _selectedCustomerIndices = null;
      _solution = null;
      _logs.clear();
      _error = null;
    });
  }

  Future<void> _showSelectionDialog() async {
    final data = _originalData;
    if (data == null) return;
    final vehicles = data['vehicles'] as List<dynamic>;
    final customers = data['customers'] as List<dynamic>;
    final initialVehicles = _selectedVehicleIndices == null
        ? Set<int>.from(List.generate(vehicles.length, (index) => index))
        : Set<int>.from(_selectedVehicleIndices!);
    final initialCustomers = _selectedCustomerIndices == null
        ? Set<int>.from(List.generate(customers.length, (index) => index))
        : Set<int>.from(_selectedCustomerIndices!);

    final selection = await showDialog<_Selection>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SelectionDialog(
        vehicles: vehicles,
        customers: customers,
        selectedVehicles: initialVehicles,
        selectedCustomers: initialCustomers,
      ),
    );
    if (selection == null) return;
    final filtered = Map<String, dynamic>.from(data)
      ..['vehicles'] = [
        for (var index = 0; index < vehicles.length; index++)
          if (selection.vehicles.contains(index)) vehicles[index],
      ]
      ..['customers'] = [
        for (var index = 0; index < customers.length; index++)
          if (selection.customers.contains(index)) customers[index],
      ];
    setState(() {
      _selectedData = filtered;
      _selectedVehicleIndices = selection.vehicles.toList()..sort();
      _selectedCustomerIndices = selection.customers.toList()..sort();
      _solution = null;
      _error = null;
    });
  }

  Future<void> _downloadExamples() async {
    try {
      final downloadUrl = Uri.parse(webServerUrl).resolve('/download-examples');
      final response = await http
          .get(downloadUrl)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw StateError(
          'Example download failed with HTTP ${response.statusCode}.',
        );
      }
      await FileSaver.instance.saveFile(
        name: 'cvrptw_examples',
        bytes: Uint8List.fromList(response.bodyBytes),
        fileExtension: 'zip',
        mimeType: MimeType.zip,
      );
    } catch (error) {
      _showError('Could not download examples: $error');
    }
  }

  Future<void> _solve() async {
    final payload = _selectedData;
    if (payload == null) {
      _showError('Load a JSON problem before solving.');
      return;
    }
    if (_busy) return;
    final parsedTimeLimit = int.tryParse(_timeLimitController.text);
    final parsedDistanceWeight = double.tryParse(
      _distanceWeightController.text,
    );
    final parsedVehiclePenalty = _vehiclePenaltyController.text.trim().isEmpty
        ? null
        : double.tryParse(_vehiclePenaltyController.text);
    final parsedMipGap = double.tryParse(_mipGapController.text);
    if (parsedTimeLimit == null ||
        parsedTimeLimit < 1 ||
        parsedTimeLimit > 3600 ||
        parsedDistanceWeight == null ||
        !parsedDistanceWeight.isFinite ||
        parsedDistanceWeight < 0.1 ||
        parsedDistanceWeight > 10 ||
        (_solver == 'gurobi' &&
            (parsedMipGap == null ||
                !parsedMipGap.isFinite ||
                parsedMipGap < 0.001 ||
                parsedMipGap > 0.5)) ||
        (_vehiclePenaltyController.text.trim().isNotEmpty &&
            (parsedVehiclePenalty == null ||
                !parsedVehiclePenalty.isFinite ||
                parsedVehiclePenalty < 0))) {
      _showError('Check the solver settings and try again.');
      return;
    }

    setState(() {
      _busy = true;
      _jobStatus = 'submitting';
      _jobId = null;
      _solution = null;
      _logs.clear();
      _error = null;
    });

    try {
      final job = await client.optimization.start(
        payloadJson: jsonEncode(payload),
        solver: _solver,
        timeLimit: parsedTimeLimit,
        vehiclePenaltyWeight: parsedVehiclePenalty,
        distanceWeight: parsedDistanceWeight,
        mipGap: parsedMipGap ?? 0.01,
      );
      final jobId = job.id;
      if (jobId == null) {
        throw StateError(
          'Serverpod returned an optimization job without an id.',
        );
      }
      if (!mounted) return;
      setState(() {
        _jobId = jobId;
        _jobStatus = job.status;
      });
      unawaited(_pollJob(jobId));
    } catch (error) {
      if (!mounted) return;
      _showError('Could not start optimization: $error');
      setState(() {
        _busy = false;
        _jobStatus = 'failed';
      });
    }
  }

  Future<void> _pollJob(int jobId) async {
    var lastSequence = 0;
    var consecutiveFailures = 0;
    while (mounted && _jobId == jobId) {
      try {
        final job = await client.optimization.getJob(jobId);
        final newLogs = await client.optimization.getLogs(jobId, lastSequence);
        if (!mounted || _jobId != jobId) return;
        consecutiveFailures = 0;
        for (final log in newLogs) {
          if (log.sequence > lastSequence) lastSequence = log.sequence;
        }
        final done = job.status == 'succeeded' || job.status == 'failed';
        setState(() {
          _jobStatus = job.status;
          _logs.addAll(newLogs.map((log) => log.message));
          if (job.status == 'succeeded') {
            final resultJson = job.resultJson;
            if (resultJson != null) {
              _solution = jsonDecode(resultJson) as Map<String, dynamic>;
            } else {
              _error = 'The worker completed without returning a result.';
              _jobStatus = 'failed';
            }
          } else if (job.status == 'failed') {
            _error = job.errorMessage ?? 'Optimization failed.';
          }
          if (done || _jobStatus == 'failed') _busy = false;
        });
        if (done || _jobStatus == 'failed') return;
      } catch (error) {
        if (!mounted || _jobId != jobId) return;
        consecutiveFailures++;
        if (consecutiveFailures >= 3) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _jobStatus = 'failed';
            _error =
                'Could not retrieve optimization status after 3 attempts: $error';
          });
          return;
        }
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1080;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.canvas,
      drawer: wide
          ? null
          : Drawer(
              width: 250,
              child: _buildNavigation(expanded: true),
            ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: wide
            ? IconButton(
                tooltip: _sidebarCollapsed
                    ? 'Expand sidebar'
                    : 'Collapse sidebar',
                onPressed: () =>
                    setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                icon: const Icon(Icons.menu_rounded),
              )
            : IconButton(
                tooltip: 'Open navigation',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
        titleSpacing: 4,
        title: _buildTopTitle(context),
        actions: [
          if (wide) ...[
            const _ConnectionBadge(),
            const SizedBox(width: 14),
          ],
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) async {
              if (value == 'signOut') await client.auth.signOutDevice();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'signOut',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFFE7F8F1),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: AppTheme.greenDark,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (wide) _buildNavigation(expanded: !_sidebarCollapsed),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1480),
                child: _buildActivePage(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTitle(BuildContext context) {
    final page = _activePage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(page.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(
          'Workspace  /  ${page.title}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigation({required bool expanded}) {
    return Container(
      width: expanded ? 250 : 76,
      color: AppTheme.sidebar,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(expanded ? 20 : 13, 23, 16, 24),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EcoDelvy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'FLEET PLATFORM',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (expanded)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 9),
                child: Text(
                  'WORKSPACE',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            for (final page in _DashboardPage.values)
              _NavigationItem(
                page: page,
                selected: page == _activePage,
                expanded: expanded,
                onTap: () {
                  setState(() => _activePage = page);
                  if (MediaQuery.sizeOf(context).width < 1080) {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            const Spacer(),
            if (expanded)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Text(
                  'Route intelligence for a\nmore efficient fleet.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    height: 1.5,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePage(BuildContext context) {
    switch (_activePage) {
      case _DashboardPage.overview:
        return _buildOverview(context);
      case _DashboardPage.optimizer:
        return _buildOptimizerPage(context);
      case _DashboardPage.customers:
        return _buildDataPage(context, customers: true);
      case _DashboardPage.vehicles:
        return _buildDataPage(context, customers: false);
      case _DashboardPage.history:
        return _buildEmptyPage(
          context,
          icon: Icons.history_rounded,
          title: 'No optimization history yet',
          description:
              'Completed jobs will appear here. Run an optimization to get started.',
          action: 'Open route optimizer',
          onAction: () =>
              setState(() => _activePage = _DashboardPage.optimizer),
        );
      case _DashboardPage.analytics:
        return _buildAnalyticsPage(context);
      case _DashboardPage.settings:
        return _buildSettingsPage(context);
    }
  }

  Widget _buildOptimizerPage(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        _PageHeading(
          eyebrow: 'PLANNING WORKSPACE',
          title: 'Route Optimizer',
          subtitle:
              'Plan efficient delivery routes with intelligent optimization.',
        ),
        const SizedBox(height: 22),
        _buildControls(
          context,
          colors,
          _items('vehicles'),
          _items('customers'),
        ),
        if (_busy || _logs.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildLogPanel(context),
        ],
        if (_error != null) ...[
          const SizedBox(height: 18),
          _buildError(context, colors),
        ],
        if (_solution != null) ...[
          const SizedBox(height: 22),
          RouteResults(
            solution: _solution!,
            onRouteTap: (route) => showDialog<void>(
              context: context,
              builder: (_) => RouteMapDialog(route: route),
            ),
          ),
        ] else if (!_busy) ...[
          const SizedBox(height: 18),
          const _InlineEmptyState(
            icon: Icons.alt_route_rounded,
            title: 'Your optimization results will appear here',
            description:
                'Upload a CVRPTW problem and run the solver to see route plans, schedules, and performance metrics.',
          ),
        ],
      ],
    );
  }

  Widget _buildOverview(BuildContext context) {
    final customers = _originalItems('customers');
    final vehicles = _originalItems('vehicles');
    final summary = _solution?['summary'] is Map
        ? Map<String, dynamic>.from(_solution!['summary'] as Map)
        : const <String, dynamic>{};
    final distance = summary['total_distance_km'] ?? summary['total_distance'];
    final utilized = summary['num_vehicles_used'];
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _PageHeading(
                eyebrow: 'YOUR OPERATIONS',
                title: 'Fleet Overview',
                subtitle:
                    'Monitor your fleet, optimize delivery routes, and make smarter logistics decisions.',
              ),
            ),
            const SizedBox(width: 14),
            FilledButton.icon(
              onPressed: () =>
                  setState(() => _activePage = _DashboardPage.optimizer),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New optimization'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 620
                ? 2
                : 1;
            final gap = 14.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: width,
                  child: _StatCard(
                    label: 'Total customers',
                    value: customers.isEmpty ? '—' : '${customers.length}',
                    icon: Icons.people_alt_outlined,
                    footnote: customers.isEmpty
                        ? 'Upload a problem to get started'
                        : 'From loaded problem',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _StatCard(
                    label: 'Available vehicles',
                    value: vehicles.isEmpty ? '—' : '${vehicles.length}',
                    icon: Icons.local_shipping_outlined,
                    footnote: vehicles.isEmpty
                        ? 'No fleet data loaded'
                        : 'From loaded problem',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _StatCard(
                    label: 'Total distance',
                    value: distance == null
                        ? '—'
                        : '${_formatMetric(distance)} km',
                    icon: Icons.route_outlined,
                    footnote: distance == null
                        ? 'Available after optimization'
                        : 'Latest optimization result',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _StatCard(
                    label: 'Vehicles utilized',
                    value: utilized == null
                        ? '—'
                        : '$utilized${vehicles.isEmpty ? '' : ' / ${vehicles.length}'}',
                    icon: Icons.local_shipping_rounded,
                    footnote: utilized == null
                        ? 'Available after optimization'
                        : 'Latest optimization result',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final analytics = _buildOverviewAnalytics(context);
            final activity = _buildRecentActivity(context);
            if (constraints.maxWidth < 850) {
              return Column(
                children: [
                  analytics,
                  const SizedBox(height: 16),
                  activity,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: analytics),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: activity),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewAnalytics(BuildContext context) {
    final routes = _solutionRoutes;
    return _Panel(
      title: 'Fleet performance',
      subtitle: 'Based on the latest completed optimization',
      trailing: TextButton(
        onPressed: () => setState(() => _activePage = _DashboardPage.analytics),
        child: const Text('View analytics'),
      ),
      child: routes.isEmpty
          ? const _CompactEmptyState(
              icon: Icons.query_stats_rounded,
              message: 'Optimization insights appear here after a run.',
            )
          : SizedBox(height: 208, child: _distanceChart(context, routes)),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return _Panel(
      title: 'Recent activity',
      subtitle: 'Latest work in this session',
      child: _solution == null
          ? const _CompactEmptyState(
              icon: Icons.history_rounded,
              message: 'No optimization activity yet.',
            )
          : ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE7F8F1),
                child: Icon(
                  Icons.check_rounded,
                  color: AppTheme.greenDark,
                ),
              ),
              title: Text('Optimization ${_jobId ?? ''}'.trim()),
              subtitle: Text(
                '${_solution!['solver'] ?? _solver} · ${_solution!['date'] ?? 'Date unavailable'}',
              ),
              trailing: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.greenDark,
              ),
            ),
    );
  }

  Widget _buildDataPage(BuildContext context, {required bool customers}) {
    final title = customers ? 'Customers' : 'Vehicles';
    final allItems = _originalItems(customers ? 'customers' : 'vehicles');
    final filteredItems = customers && _customerSearch.trim().isNotEmpty
        ? allItems.where((value) {
            if (value is! Map) return false;
            final search = _customerSearch.toLowerCase();
            return [
              value['id'],
              value['name'],
              value['customer_name'],
            ].any(
              (field) =>
                  field?.toString().toLowerCase().contains(search) ?? false,
            );
          }).toList()
        : allItems;
    final selected = customers
        ? (_selectedCustomerIndices ?? <int>{}).length
        : (_selectedVehicleIndices ?? <int>{}).length;

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        _PageHeading(
          eyebrow: 'FLEET DATA',
          title: title,
          subtitle: customers
              ? 'Review customer locations and delivery requirements from your loaded problem.'
              : 'Review vehicle capacity and availability from your loaded problem.',
        ),
        const SizedBox(height: 22),
        if (allItems.isEmpty)
          _InlineEmptyState(
            icon: customers
                ? Icons.people_alt_outlined
                : Icons.local_shipping_outlined,
            title: 'No $title data loaded',
            description:
                'Upload a CVRPTW problem to review its ${title.toLowerCase()}. EcoDelvy only shows data provided by your input.',
            actionLabel: 'Open route optimizer',
            onAction: () =>
                setState(() => _activePage = _DashboardPage.optimizer),
          )
        else
          _Panel(
            title: '$title in current problem',
            subtitle: '$selected selected for the next optimization',
            trailing: customers
                ? SizedBox(
                    width: 250,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by name or ID',
                        prefixIcon: Icon(Icons.search_rounded),
                        isDense: true,
                      ),
                      onChanged: (value) =>
                          setState(() => _customerSearch = value),
                    ),
                  )
                : TextButton.icon(
                    onPressed: () =>
                        setState(() => _activePage = _DashboardPage.optimizer),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Change selection'),
                  ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 48,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 68,
                columns: customers
                    ? const [
                        DataColumn(label: Text('CUSTOMER')),
                        DataColumn(label: Text('LOCATION')),
                        DataColumn(label: Text('DEMAND')),
                        DataColumn(label: Text('TIME WINDOW')),
                        DataColumn(label: Text('SERVICE TIME')),
                      ]
                    : const [
                        DataColumn(label: Text('VEHICLE')),
                        DataColumn(label: Text('TYPE')),
                        DataColumn(label: Text('CAPACITY')),
                        DataColumn(label: Text('AVAILABILITY')),
                        DataColumn(label: Text('ASSIGNED')),
                      ],
                rows: [
                  for (final item in filteredItems.whereType<Map>())
                    DataRow(
                      cells: customers
                          ? [
                              DataCell(
                                _NameCell(
                                  title:
                                      (item['name'] ??
                                              item['customer_name'] ??
                                              'Customer')
                                          .toString(),
                                  subtitle: 'ID ${item['id'] ?? '—'}',
                                  icon: Icons.person_outline_rounded,
                                ),
                              ),
                              DataCell(Text(_locationLabel(item['location']))),
                              DataCell(
                                Text('${_customerDemand(item)} units'),
                              ),
                              DataCell(Text(_windowLabel(item))),
                              DataCell(
                                Text(
                                  item['service_time_minutes'] == null
                                      ? '—'
                                      : '${item['service_time_minutes']} min',
                                ),
                              ),
                            ]
                          : [
                              DataCell(
                                _NameCell(
                                  title: (item['id'] ?? 'Vehicle').toString(),
                                  subtitle: 'Vehicle',
                                  icon: Icons.local_shipping_outlined,
                                ),
                              ),
                              DataCell(Text('${item['type'] ?? '—'}')),
                              DataCell(
                                Text('${item['capacity_units'] ?? '—'} units'),
                              ),
                              DataCell(Text(_windowLabel(item))),
                              DataCell(
                                Text(_assignedCustomerCount(item['id'])),
                              ),
                            ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalyticsPage(BuildContext context) {
    final routes = _solutionRoutes;
    if (routes.isEmpty) {
      return _buildEmptyPage(
        context,
        icon: Icons.query_stats_rounded,
        title: 'No analytics available yet',
        description:
            'Run an optimization to explore distance and vehicle utilization based on actual solver results.',
        action: 'Run optimization',
        onAction: () => setState(() => _activePage = _DashboardPage.optimizer),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const _PageHeading(
          eyebrow: 'PERFORMANCE',
          title: 'Analytics',
          subtitle: 'Insights calculated from the latest solver result.',
        ),
        const SizedBox(height: 22),
        _buildAnalyticsRow(context, [
          _Panel(
            title: 'Distance by vehicle',
            subtitle: 'Route distance in km from the optimization response',
            child: SizedBox(
              height: 250,
              child: _distanceChart(context, routes),
            ),
          ),
          _Panel(
            title: 'Capacity utilization',
            subtitle: 'Delivered load as a percentage of vehicle capacity',
            child: SizedBox(
              height: 250,
              child: _capacityChart(context, routes),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _buildAnalyticsRow(context, [
          _Panel(
            title: 'Duration by vehicle',
            subtitle: 'Route duration in minutes returned by the solver',
            child: SizedBox(
              height: 250,
              child: _durationChart(context, routes),
            ),
          ),
          _Panel(
            title: 'Customers by route',
            subtitle: 'Customer stops served for each planned route',
            child: SizedBox(
              height: 250,
              child: _customersChart(context, routes),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildAnalyticsRow(BuildContext context, List<Widget> panels) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return Column(
            children: [
              panels[0],
              const SizedBox(height: 16),
              panels[1],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: panels[0]),
            const SizedBox(width: 16),
            Expanded(child: panels[1]),
          ],
        );
      },
    );
  }

  Widget _buildSettingsPage(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const _PageHeading(
          eyebrow: 'PREFERENCES',
          title: 'Settings',
          subtitle: 'Review the active service endpoints for this session.',
        ),
        const SizedBox(height: 22),
        _Panel(
          title: 'Service configuration',
          subtitle: 'Endpoints are configured at build or app startup.',
          child: Column(
            children: [
              FutureBuilder<String>(
                future: serverUrl,
                builder: (context, snapshot) => _SettingsRow(
                  icon: Icons.hub_outlined,
                  label: 'Serverpod API',
                  value: snapshot.hasData
                      ? snapshot.data.toString()
                      : 'Loading configuration…',
                ),
              ),
              const Divider(height: 22),
              _SettingsRow(
                icon: Icons.download_outlined,
                label: 'Examples and web routes',
                value: webServerUrl,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String action,
    required VoidCallback onAction,
  }) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        _PageHeading(
          eyebrow: 'WORKSPACE',
          title: _activePage.title,
          subtitle: _activePage.subtitle,
        ),
        const SizedBox(height: 22),
        _InlineEmptyState(
          icon: icon,
          title: title,
          description: description,
          actionLabel: action,
          onAction: onAction,
        ),
      ],
    );
  }

  Widget _distanceChart(
    BuildContext context,
    List<Map<String, dynamic>> routes,
  ) {
    return _routeMetricChart(
      context,
      routes,
      metric: 'distance',
      color: AppTheme.greenDark,
      emptyMessage: 'Distance details were not returned for these routes.',
    );
  }

  Widget _durationChart(
    BuildContext context,
    List<Map<String, dynamic>> routes,
  ) {
    return _routeMetricChart(
      context,
      routes,
      metric: 'duration_minutes',
      color: const Color(0xFF0F766E),
      emptyMessage: 'Duration details were not returned for these routes.',
    );
  }

  Widget _customersChart(
    BuildContext context,
    List<Map<String, dynamic>> routes,
  ) {
    return _routeMetricChart(
      context,
      routes,
      metric: 'num_customers',
      color: const Color(0xFF34D399),
      emptyMessage: 'Customer counts were not returned for these routes.',
    );
  }

  Widget _routeMetricChart(
    BuildContext context,
    List<Map<String, dynamic>> routes, {
    required String metric,
    required Color color,
    required String emptyMessage,
  }) {
    final points = <(String, double)>[];
    for (var index = 0; index < routes.length; index++) {
      final value = _asDouble(routes[index][metric]);
      if (value != null) {
        points.add(('V${_vehicleLabel(routes[index], index)}', value));
      }
    }
    if (points.isEmpty) {
      return _CompactEmptyState(
        icon: Icons.bar_chart_rounded,
        message: emptyMessage,
      );
    }
    final maxY = points
        .map((point) => point.$2)
        .reduce((a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.15,
        barGroups: [
          for (var index = 0; index < points.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: points[index].$2,
                  color: color,
                  width: 22,
                  borderRadius: BorderRadius.circular(5),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY <= 0 ? 1 : maxY * 1.15,
                    color: const Color(0xFFF1F5F9),
                  ),
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    points[index].$1,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
      ),
      duration: const Duration(milliseconds: 350),
    );
  }

  Widget _capacityChart(
    BuildContext context,
    List<Map<String, dynamic>> routes,
  ) {
    final vehicles = _originalItems('vehicles');
    final points = <(String, double)>[];
    for (var index = 0; index < routes.length; index++) {
      final route = routes[index];
      final vehicleIndex = _vehicleIndex(route, index);
      if (vehicleIndex < 0 || vehicleIndex >= vehicles.length) continue;
      final vehicle = vehicles[vehicleIndex];
      if (vehicle is! Map) continue;
      final load = _asDouble(route['load']);
      final capacity = _asDouble(vehicle['capacity_units']);
      if (load == null || capacity == null || capacity <= 0) continue;
      points.add((
        'V${_vehicleLabel(route, index)}',
        (load / capacity * 100).clamp(0, 100).toDouble(),
      ));
    }
    if (points.isEmpty) {
      return const _CompactEmptyState(
        icon: Icons.speed_rounded,
        message:
            'Capacity utilization needs route loads and vehicle capacities.',
      );
    }
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 100,
        barGroups: [
          for (var index = 0; index < points.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: points[index].$2,
                  color: AppTheme.green,
                  width: 22,
                  borderRadius: BorderRadius.circular(5),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: Color(0xFFF1F5F9),
                  ),
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    points[index].$1,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  List<Map<String, dynamic>> get _solutionRoutes {
    final value = _solution?['routes'];
    return value is List
        ? value
              .whereType<Map>()
              .map((route) => Map<String, dynamic>.from(route))
              .toList()
        : const [];
  }

  int _vehicleIndex(Map route, int fallback) => route['vehicle_id'] is num
      ? (route['vehicle_id'] as num).toInt()
      : fallback;

  int _vehicleLabel(Map route, int fallback) =>
      _vehicleIndex(route, fallback) + 1;

  String _assignedCustomerCount(Object? vehicleId) {
    final routes = _solutionRoutes.where((route) {
      final routeId = route['vehicle_id'];
      final vehicles = _originalItems('vehicles');
      if (routeId is! num ||
          routeId.toInt() < 0 ||
          routeId.toInt() >= vehicles.length) {
        return routeId?.toString() == vehicleId?.toString();
      }
      final vehicle = vehicles[routeId.toInt()];
      return vehicle is Map &&
          vehicle['id']?.toString() == vehicleId?.toString();
    });
    if (routes.isEmpty) return '—';
    final value = routes.first['num_customers'];
    return value == null ? '—' : '$value';
  }

  int _customerDemand(Map item) {
    final scalar = item['demand_units'];
    if (scalar is num) return scalar.toInt();
    final demands = item['demands_units'];
    if (demands is Map) {
      final date = _problemDate;
      final value = demands[date];
      if (value is num) return value.toInt();
      final first = demands.values.whereType<num>().firstOrNull;
      if (first != null) return first.toInt();
    }
    return 0;
  }

  String? get _problemDate {
    final data = _originalData;
    final metadata = data?['metadata'];
    final date = data?['date'] ?? (metadata is Map ? metadata['date'] : null);
    return date?.toString();
  }

  String _windowLabel(Map item) {
    dynamic window = item['time_window'];
    if (window == null && item['time_windows'] is Map) {
      final windows = item['time_windows'] as Map;
      window =
          windows[_problemDate] ??
          (windows.isEmpty ? null : windows.values.first);
    }
    if (window is! Map) return '—';
    final start = window['start_min'];
    final end = window['end_min'];
    if (start is! num || end is! num) return '—';
    return '${_formatClock(start.toInt())}–${_formatClock(end.toInt())}';
  }

  String _locationLabel(Object? value) {
    if (value is List &&
        value.length == 2 &&
        value[0] is num &&
        value[1] is num) {
      return '${(value[0] as num).toStringAsFixed(3)}, ${(value[1] as num).toStringAsFixed(3)}';
    }
    return '—';
  }

  double? _asDouble(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');

  String _formatMetric(Object value) =>
      _asDouble(value)?.toStringAsFixed(1) ?? value.toString();

  Widget _buildControls(
    BuildContext context,
    ColorScheme colors,
    List<dynamic> vehicles,
    List<dynamic> customers,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inputPanel = _Panel(
          title: 'Problem configuration',
          subtitle: 'Load and review your delivery data',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_originalData == null)
                _buildFileDropZone()
              else
                _buildSelectedFileCard(context),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _loadFile,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: Text(
                      _originalData == null ? 'Browse JSON' : 'Replace file',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _downloadExamples,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download examples'),
                  ),
                  if (_originalData != null)
                    TextButton.icon(
                      onPressed: _busy ? null : _showSelectionDialog,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Select data'),
                    ),
                ],
              ),
              if (_originalData != null) ...[
                const SizedBox(height: 20),
                const _SectionLabel(label: 'PROBLEM SUMMARY'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _SummaryPill(
                      label: '${_originalItems('customers').length} customers',
                      icon: Icons.people_alt_outlined,
                    ),
                    _SummaryPill(
                      label: '${_originalItems('vehicles').length} vehicles',
                      icon: Icons.local_shipping_outlined,
                    ),
                    _SummaryPill(
                      label:
                          '${_originalItems('customers').whereType<Map>().fold<int>(0, (total, customer) => total + _customerDemand(customer))} units demand',
                      icon: Icons.inventory_2_outlined,
                    ),
                    _SummaryPill(
                      label: _problemDate ?? 'Date not specified',
                      icon: Icons.calendar_today_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Text(
                  'Depot  ${_locationLabel((_originalData!['depot'] as Map)['location'])}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _showSelectionDialog,
                  icon: const Icon(Icons.checklist_rounded, size: 18),
                  label: Text(
                    '${customers.length} customers · ${vehicles.length} vehicles selected',
                  ),
                ),
              ],
            ],
          ),
        );

        final configurationPanel = _Panel(
          title: 'Optimization settings',
          subtitle: 'Choose a solver and tune the run',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(label: 'SOLVER'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'ortools',
                      label: Text('OR-Tools'),
                      icon: Icon(Icons.bolt_rounded),
                    ),
                    ButtonSegment(
                      value: 'gurobi',
                      label: Text('Gurobi'),
                      icon: Icon(Icons.functions_rounded),
                    ),
                  ],
                  selected: {_solver},
                  onSelectionChanged: _busy
                      ? null
                      : (selection) =>
                            setState(() => _solver = selection.first),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _timeLimitController,
                enabled: !_busy,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Time limit',
                  suffixText: 'seconds',
                  helperText: 'Between 1 and 3600 seconds',
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _busy
                    ? null
                    : () => setState(() => _showAdvanced = !_showAdvanced),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Advanced parameters')),
                      Icon(
                        _showAdvanced
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showAdvanced) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _vehiclePenaltyController,
                  enabled: !_busy,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Vehicle penalty weight',
                    hintText: _solver == 'ortools' ? '100000' : '1000',
                    helperText: 'Larger values favor fewer vehicles.',
                    suffixIcon: const Tooltip(
                      message:
                          'Controls the trade-off between route distance and the number of vehicles used.',
                      child: Icon(Icons.info_outline_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _distanceWeightController,
                  enabled: !_busy,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Distance weight',
                    helperText: 'Range: 0.1 to 10',
                    suffixIcon: Tooltip(
                      message:
                          'Scales the distance component of the solver objective.',
                      child: Icon(Icons.info_outline_rounded),
                    ),
                  ),
                ),
                if (_solver == 'gurobi') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mipGapController,
                    enabled: !_busy,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Gurobi MIP gap',
                      helperText: 'Range: 0.001 to 0.5',
                      suffixIcon: Tooltip(
                        message:
                            'Sets the relative optimality gap at which Gurobi may stop.',
                        child: Icon(Icons.info_outline_rounded),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selectedData == null || _busy || !_settingsValid
                      ? null
                      : _solve,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _busy ? 'Optimizing · $_jobStatus' : 'Run optimization',
                  ),
                ),
              ),
              if (_selectedData == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Load a problem and select at least one vehicle and customer.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );

        if (constraints.maxWidth < 920) {
          return Column(
            children: [
              inputPanel,
              const SizedBox(height: 16),
              configurationPanel,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: inputPanel),
            const SizedBox(width: 16),
            Expanded(flex: 5, child: configurationPanel),
          ],
        );
      },
    );
  }

  bool get _settingsValid {
    final timeLimit = int.tryParse(_timeLimitController.text);
    final distanceWeight = double.tryParse(_distanceWeightController.text);
    final vehiclePenaltyText = _vehiclePenaltyController.text.trim();
    final vehiclePenalty = vehiclePenaltyText.isEmpty
        ? null
        : double.tryParse(vehiclePenaltyText);
    final mipGap = double.tryParse(_mipGapController.text);
    return timeLimit != null &&
        timeLimit >= 1 &&
        timeLimit <= 3600 &&
        distanceWeight != null &&
        distanceWeight >= 0.1 &&
        distanceWeight <= 10 &&
        (vehiclePenaltyText.isEmpty ||
            (vehiclePenalty != null && vehiclePenalty >= 0)) &&
        (_solver != 'gurobi' ||
            (mipGap != null && mipGap >= 0.001 && mipGap <= 0.5));
  }

  Widget _buildFileDropZone() {
    return SizedBox(
      height: 184,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            if (kIsWeb)
              DropzoneView(
                operation: DragOperation.copy,
                mime: const [
                  'application/json',
                  'text/json',
                  'application/octet-stream',
                ],
                onCreated: (controller) => _dropzoneController = controller,
                onHover: () => setState(() => _dropHovered = true),
                onLeave: () => setState(() => _dropHovered = false),
                onDropFile: (file) {
                  setState(() => _dropHovered = false);
                  unawaited(_loadDroppedFile(file));
                },
                onError: (error) => _showError('File drop failed: $error'),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: _dropHovered
                        ? const Color(0xFFE7F8F1)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _dropHovered
                          ? AppTheme.greenDark
                          : AppTheme.border,
                      width: _dropHovered ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _dropHovered
                              ? Icons.file_download_done_rounded
                              : Icons.cloud_upload_outlined,
                          color: AppTheme.greenDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _dropHovered
                            ? 'Drop your JSON file here'
                            : 'Drop a CVRPTW JSON file here',
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'or browse your computer · JSON up to the server limit',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 21,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.data_object_rounded,
              color: AppTheme.greenDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFileName ?? 'Problem file',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_fileSizeLabel(_selectedFileSize)} · JSON validated',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.greenDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove problem',
            onPressed: _busy ? null : _removeProblemFile,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  String _fileSizeLabel(int? size) {
    if (size == null) return 'Size unavailable';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildLogPanel(BuildContext context) {
    return _Panel(
      title: 'Live optimization',
      subtitle: _jobId == null
          ? 'Worker output'
          : 'Worker output · job #$_jobId',
      trailing: _StatusPill(status: _jobStatus),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF101827),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: _logs.isEmpty
            ? Center(
                child:
                    _jobStatus == 'running' ||
                        _jobStatus == 'submitting' ||
                        _jobStatus == 'pending'
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.green,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Waiting for worker output…',
                            style: TextStyle(color: Color(0xFFCBD5E1)),
                          ),
                        ],
                      )
                    : const Text(
                        'No worker output available.',
                        style: TextStyle(color: Color(0xFFCBD5E1)),
                      ),
              )
            : ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final message = _logs[index];
                  final color = _logColor(message);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Icon(Icons.circle, size: 7, color: color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SelectableText(
                            message,
                            style: TextStyle(
                              color: color,
                              fontFamily: 'monospace',
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Color _logColor(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('error') ||
        normalized.contains('failed') ||
        normalized.contains('exception')) {
      return const Color(0xFFFCA5A5);
    }
    if (normalized.contains('warning') || normalized.contains('warn')) {
      return const Color(0xFFFCD34D);
    }
    if (normalized.contains('success') ||
        normalized.contains('completed') ||
        normalized.contains('succeeded')) {
      return const Color(0xFF6EE7B7);
    }
    return const Color(0xFFCBD5E1);
  }

  Widget _buildError(BuildContext context, ColorScheme colors) {
    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: colors.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: SelectableText(
                _error!,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: () => setState(() => _error = null),
              icon: Icon(Icons.close, color: colors.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}

extension on _DashboardPage {
  String get title => switch (this) {
    _DashboardPage.overview => 'Fleet Overview',
    _DashboardPage.optimizer => 'Route Optimizer',
    _DashboardPage.customers => 'Customers',
    _DashboardPage.vehicles => 'Vehicles',
    _DashboardPage.history => 'Optimization History',
    _DashboardPage.analytics => 'Analytics',
    _DashboardPage.settings => 'Settings',
  };

  String get subtitle => switch (this) {
    _DashboardPage.overview =>
      'Monitor your fleet, optimize delivery routes, and make smarter logistics decisions.',
    _DashboardPage.optimizer =>
      'Plan efficient delivery routes with intelligent optimization.',
    _DashboardPage.customers => 'Customer data from your loaded problem.',
    _DashboardPage.vehicles => 'Vehicle data from your loaded problem.',
    _DashboardPage.history => 'Review completed optimization jobs.',
    _DashboardPage.analytics => 'Explore metrics from actual solver results.',
    _DashboardPage.settings => 'Review application and service configuration.',
  };

  IconData get icon => switch (this) {
    _DashboardPage.overview => Icons.space_dashboard_outlined,
    _DashboardPage.optimizer => Icons.alt_route_rounded,
    _DashboardPage.customers => Icons.people_alt_outlined,
    _DashboardPage.vehicles => Icons.local_shipping_outlined,
    _DashboardPage.history => Icons.history_rounded,
    _DashboardPage.analytics => Icons.query_stats_rounded,
    _DashboardPage.settings => Icons.settings_outlined,
  };
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.page,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final _DashboardPage page;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 46,
      margin: EdgeInsets.fromLTRB(expanded ? 10 : 9, 3, expanded ? 10 : 9, 3),
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1F3A35) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: selected ? Border.all(color: const Color(0xFF29564A)) : null,
      ),
      child: Row(
        mainAxisAlignment: expanded
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Icon(
            page.icon,
            size: 19,
            color: selected ? AppTheme.green : const Color(0xFF94A3B8),
          ),
          if (expanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                page.title,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFCBD5E1),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    final item = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: child,
    );
    return expanded ? item : Tooltip(message: page.title, child: item);
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.greenDark,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final heading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ],
                );
                if (trailing == null) return heading;
                if (constraints.maxWidth < 560) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heading,
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerLeft, child: trailing!),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.footnote,
  });

  final String label;
  final String value;
  final IconData icon;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F8F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppTheme.greenDark),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              footnote,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.muted),
          const SizedBox(width: 7),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppTheme.muted,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.7,
    ),
  );
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F8F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppTheme.greenDark, size: 25),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.muted,
                  height: 1.5,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactEmptyState extends StatelessWidget {
  const _CompactEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF94A3B8), size: 28),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F8F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.circle, size: 8, color: AppTheme.greenDark),
          SizedBox(width: 7),
          Text(
            'Serverpod session',
            style: TextStyle(
              color: AppTheme.greenDark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'succeeded' || 'success' || 'completed' => AppTheme.greenDark,
      'failed' => const Color(0xFFDC2626),
      'running' || 'submitting' || 'pending' => const Color(0xFFB45309),
      _ => AppTheme.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(
        radius: 17,
        backgroundColor: const Color(0xFFF1F5F9),
        child: Icon(icon, size: 17, color: AppTheme.muted),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    ],
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppTheme.greenDark),
    title: Text(label),
    subtitle: SelectableText(value),
  );
}

class _Selection {
  const _Selection(this.vehicles, this.customers);

  final Set<int> vehicles;
  final Set<int> customers;
}

class _SelectionDialog extends StatefulWidget {
  const _SelectionDialog({
    required this.vehicles,
    required this.customers,
    required this.selectedVehicles,
    required this.selectedCustomers,
  });

  final List<dynamic> vehicles;
  final List<dynamic> customers;
  final Set<int> selectedVehicles;
  final Set<int> selectedCustomers;

  @override
  State<_SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<_SelectionDialog> {
  late final Set<int> _vehicles = Set<int>.from(widget.selectedVehicles);
  late final Set<int> _customers = Set<int>.from(widget.selectedCustomers);
  final _customerSearchController = TextEditingController();

  @override
  void dispose() {
    _customerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.68;
    final width = (MediaQuery.sizeOf(context).width - 48)
        .clamp(320, 960)
        .toDouble();
    return AlertDialog(
      title: const Text('Select your planning data'),
      content: SizedBox(
        width: width,
        height: height.clamp(320, 720).toDouble(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final vehicleList = _buildList(
              title: 'Vehicles',
              items: widget.vehicles,
              selected: _vehicles,
              customerList: false,
            );
            final customerList = _buildList(
              title: 'Customers',
              items: widget.customers,
              selected: _customers,
              customerList: true,
            );
            if (constraints.maxWidth < 620) {
              return Column(
                children: [
                  Expanded(child: vehicleList),
                  const Divider(height: 20),
                  Expanded(child: customerList),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: vehicleList),
                const VerticalDivider(width: 24),
                Expanded(child: customerList),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _vehicles.isEmpty || _customers.isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  _Selection(Set.of(_vehicles), Set.of(_customers)),
                ),
          child: const Text('Confirm selection'),
        ),
      ],
    );
  }

  Widget _buildList({
    required String title,
    required List<dynamic> items,
    required Set<int> selected,
    required bool customerList,
  }) {
    final allSelected = selected.length == items.length;
    final query = customerList
        ? _customerSearchController.text.trim().toLowerCase()
        : '';
    final indexes = [
      for (var index = 0; index < items.length; index++)
        if (query.isEmpty ||
            (items[index] is Map &&
                [
                  (items[index] as Map)['id'],
                  (items[index] as Map)['name'],
                  (items[index] as Map)['customer_name'],
                ].any(
                  (field) =>
                      field?.toString().toLowerCase().contains(query) ?? false,
                )))
          index,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$title (${selected.length}/${items.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                if (allSelected) {
                  selected.clear();
                } else {
                  selected
                    ..clear()
                    ..addAll(List.generate(items.length, (index) => index));
                }
              }),
              child: Text(allSelected ? 'Clear all' : 'Select all'),
            ),
          ],
        ),
        if (customerList) ...[
          const SizedBox(height: 4),
          TextField(
            controller: _customerSearchController,
            decoration: const InputDecoration(
              hintText: 'Search customers',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: indexes.length,
            itemBuilder: (context, index) {
              final itemIndex = indexes[index];
              final item = Map<String, dynamic>.from(items[itemIndex] as Map);
              final id =
                  item['id']?.toString() ??
                  '${customerList ? 'Customer' : 'Vehicle'} ${itemIndex + 1}';
              final titleText = customerList
                  ? ((item['name'] ?? item['customer_name'])
                                ?.toString()
                                .isNotEmpty ==
                            true
                        ? (item['name'] ?? item['customer_name']).toString()
                        : id)
                  : id;
              final detail = customerList
                  ? 'Demand: ${item['demand_units'] ?? 'date-based'} units'
                  : 'Type: ${item['type'] ?? 'vehicle'} · Capacity: ${item['capacity_units'] ?? '—'} units';
              return CheckboxListTile(
                dense: true,
                value: selected.contains(index),
                title: Text(
                  titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '$detail\n${_locationText(item, customerList)} · ${_timeWindow(item)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    selected.add(itemIndex);
                  } else {
                    selected.remove(itemIndex);
                  }
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

String _locationText(Map<String, dynamic> item, bool isCustomer) {
  final value = isCustomer ? item['location'] : item['start_location'];
  if (value is List &&
      value.length == 2 &&
      value[0] is num &&
      value[1] is num) {
    return 'Location: ${(value[0] as num).toStringAsFixed(4)}, ${(value[1] as num).toStringAsFixed(4)}';
  }
  return isCustomer ? 'Location not set' : 'Starts at depot';
}

String _timeWindow(Map<String, dynamic> item) {
  dynamic window = item['time_window'];
  if (window == null && item['time_windows'] is Map) {
    final windows = item['time_windows'] as Map;
    window = windows.isEmpty ? null : windows.values.first;
  }
  if (window is! Map) return 'Time window: varies by date';
  final start = window['start_min'];
  final end = window['end_min'];
  if (start is! num || end is! num) return 'Time window: varies by date';
  return 'Time: ${_formatClock(start.toInt())}–${_formatClock(end.toInt())}';
}

String _formatClock(int minutes) {
  final hours = (minutes ~/ 60).toString().padLeft(2, '0');
  final remainder = (minutes % 60).toString().padLeft(2, '0');
  return '$hours:$remainder';
}
