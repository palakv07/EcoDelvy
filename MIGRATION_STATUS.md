# Migration Status

## Completed

- Flutter Web, Serverpod, generated client, PostgreSQL model, and Python worker project structure
- Durable optimization job and ordered log models with generated migrations
- Authenticated job submission, status, and log endpoints
- Worker claim, lease renewal, log, and completion routes with private-token authorization
- Atomic job claim and retry/lease handling
- Worker-side coordinate, demand, time-window, numeric, and solver validation
- Existing OR-Tools and Gurobi solver modules preserved unchanged
- Existing OSRM and SQLite cache behavior preserved in the Python service
- Tracked example JSON packaged under `eco_delvy_server/assets/inputs`
- Flutter upload, filtering, solver controls, polling, logs, summary, timeline, route cards, and map fallback UI
- Serverpod and Flutter production/development configuration updated
- Worker Docker cache changed to a named volume and loopback-only binding
- Safe environment-variable template added

## Modified/added areas

- `eco_delvy_server/`: endpoints, worker routes, validation, models, migrations, Serverpod configuration
- `eco_delvy_flutter/`: client setup, authentication shell, optimizer UI, map/timeline widgets, tests
- `eco_delvy_client/`: regenerated protocol/client
- `optimization_service/`: worker adapter, lease heartbeat, health service, Docker deployment
- `src/services/problem_builder.py`: null/alternate date-field robustness without replacing solver logic
- `eco_delvy_server/assets/inputs/`: exact copies of all three tracked example JSON files

## Verified

Commands that completed successfully:

- `dart analyze eco_delvy_server`
- `eco_delvy_server/dart test`
- `flutter analyze`
- `flutter test`
- `flutter build web --release`
- Python worker unittest suite
- Python problem-builder and packaged-assets unittest suites
- Serverpod code generation
- Serverpod migration generation
- Embedded PostgreSQL start on port `8190`
- Serverpod live startup on API 8080, Insights 8081, and Web 8082
- Web liveness probe returned HTTP 200
- API root listener returned HTTP 200
- `/download-examples` returned a ZIP containing all three tracked fixtures

## Tests not fully verified

- Live Serverpod HTTP/job round-trip requires the Serverpod process and authenticated session
- PostgreSQL migration application against a persistent database requires the final Serverpod startup
- Actual OR-Tools solver invocation against all three tracked fixtures
- Gurobi solver execution: license status is unknown
- OSRM network behavior and cache population
- SQLite cache import to PostgreSQL: no active Serverpod PostgreSQL cache models/import utility is implemented
- Serverpod Cloud deployment
- Python worker hosting

## External blockers

- PostgreSQL/Serverpod startup can be blocked by occupied ports or unavailable native database tooling
- Gurobi requires a valid license on the Python worker host
- Serverpod Cloud credentials and project configuration are unavailable locally
- Python worker host URL and worker secret must be supplied by deployment operators
- OSRM availability and network access must be verified from the deployed worker

## Deployment remaining

1. Configure real database credentials and production hosts.
2. Apply both migrations to a clean PostgreSQL database.
3. Run the worker and solve all three tracked fixtures through a live Serverpod job.
4. Compare output against the original FastAPI/Python baseline.
5. Import or recreate the SQLite cache and verify OSRM fallbacks.
6. Configure Gurobi licensing only if permitted on the selected worker host.
7. Deploy Serverpod/Flutter and the private Python worker, then verify health and authentication.
