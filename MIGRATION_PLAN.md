# EcoDelvy Flutter and Serverpod Migration Plan

**Status:** Phase 1 analysis complete. No application code has been replaced or deleted.

## 1. Executive summary

EcoDelvy is a single-user CVRPTW route optimizer. The React browser UI uploads and filters a JSON problem, then calls a FastAPI service. The Python service normalizes the request, obtains road-distance and travel-time matrices from OSRM with a SQLite cache, runs either OR-Tools or Gurobi, and returns detailed route and summary data. The UI shows logs, statistics, a timeline, and a Leaflet route map.

The solver libraries are Python/native-library integrations. The inspected OR-Tools documentation lists C++, Python, C#, and Java examples; the existing Gurobi integration is `gurobipy`. No supported Dart API is present in this project. A direct Dart rewrite would risk changing the optimization model and is not justified. **Keep the existing mathematical engines in a private Python optimization service.** Migrate the public application API, authentication, durable jobs, data persistence, and Flutter UI to Dart/Serverpod.

Serverpod Cloud is compatible with the Dart control plane, Flutter Web build, and PostgreSQL database. The Python solver must run as a separate containerized worker on a Python-capable host; Serverpod Cloud deployment packages and runs the Serverpod server, not a Python runtime.

## 2. Existing architecture and request flow

| Layer | Current implementation |
|---|---|
| Browser UI | React 18 / Create React App in `webui/`; custom CSS; React Leaflet and Leaflet |
| API | FastAPI application in `src/app.py`; route handlers in `src/api/routes.py` |
| Authentication | Optional static `API_KEY`, checked by `src/api/dependencies.py` on solve endpoints |
| Domain/request models | Pydantic models in `src/models/domain.py` and `src/models/api.py`; the solve routes currently accept a raw dictionary |
| Orchestration | `SolverService` in `src/services/solver_service.py` |
| Problem normalization | `ProblemBuilder` in `src/services/problem_builder.py` |
| Solvers | OR-Tools routing model and Gurobi MILP under `src/core/solvers/` |
| Distance data | OSRM requests, Haversine fallback, and SQLite cache in `src/services/distance_cache.py` |
| Inputs | Two tracked fixtures under `inputs/`; no tracked results database or job store |
| Deployment | Dockerfile and `docker/docker-compose.yml`; separate local React/API instructions in the READMEs |

The application flow is:

1. `FileUpload` reads a selected JSON file in the browser. The example-download button calls the API.
2. `SelectionModal` starts with all vehicles and customers selected, supports individual/select-all toggles, and submits a filtered copy of the input.
3. `App` sends the JSON and solver parameters to `POST /solve-stream`; it reads SSE `data:` events and displays log, result, or error events.
4. `ProblemBuilder` infers the requested date, selects customers with positive demand for that date, and constructs the solver's indexed arrays (depot first).
5. `SolverService` fills distance and three time matrices, chooses the configured solver and defaults, then calls the solver.
6. The result is enriched with customer/depot details and returned through SSE.
7. React renders the summary, route cards, timeline, and a route-detail overlay. The map makes a separate OSRM route-geometry request and falls back to straight lines.

There is a process-local nonblocking solver lock. It allows only one solve at a time in a process and is not a durable or multi-instance job queue. The SSE handler attaches to loggers and forwards messages while a worker thread runs. A disconnected client does not have a durable job/log history to resume.

## 3. Existing API endpoints

| Current endpoint | Behavior | Authentication |
|---|---|---|
| `GET /health` | Returns `ready` or `busy` from the process-local solver state | Public |
| `POST /solve` | Synchronously solves a JSON payload; query parameters include `time_limit`, `solver`, `vehicle_penalty_weight`, `distance_weight`, and `mip_gap` | Requires `api-key` when `API_KEY` is configured |
| `POST /solve-stream` | Same solve inputs; streams log/result/error events as SSE | Requires `api-key` when configured |
| `GET /download-examples` | Builds a ZIP from the example paths that exist at the server's working directory | Public |

The repository tracks `CVRPTW_SMALL.json`, `CVRPTW_MEDIUM.json`, and `CVRPTW_LARGE.json`. Keep all three fixtures byte-identical between `inputs/` and `eco_delvy_server/assets/inputs/`.

The `SolveRequest`, `SolveResponse`, and `SolverConfig` Pydantic models are defined, but the routes accept `payload: dict`. The regular `/solve` response declares `SolveResponse` while the service returns additional fields and a nested `summary`; the streamed frontend consumes the service result directly. The migration contract should be based on the actual streamed result and input fixtures, then validated with regression tests.

## 4. Existing data structures and behavior to preserve

### Input JSON

The request has `depot.location`, `vehicles`, and `customers`; fixture locations are two-element arrays in **[latitude, longitude]** order. The small fixture has 5 vehicles and 4 customers; the medium fixture has 38 vehicles and 13 customers. Fixtures use scalar `demand_units` and `time_window`. The domain models and `ProblemBuilder` also support date-keyed `demands_units` / `time_windows`, top-level or metadata dates, and a metadata depot time window.

The builder creates a solver list with depot at index 0, customer locations after it, depot demand 0, capacities per vehicle, and per-location time windows. It uses a fallback customer window of 04:00-21:00 and derives the depot window from metadata or the minimum/maximum vehicle windows. The input vehicle's `start_location` and `type` are not used by the current builder; routes start and end at the one shared depot.

Although `service_time_min` exists on the Pydantic `Customer` model, the current solver time matrices and result calculations use **10 minutes + 2 minutes per delivered unit**. Do not silently substitute the input field during migration; first preserve this observed behavior and decide any business-rule correction separately.

### Solver outputs

The UI consumes `status`, solver-specific `routes`, and summary metrics such as vehicles used, distance, load, saturation, duration, and travel/service time. Each route includes a vehicle index, capacity, ordered stops, segment distances, and route metrics. OR-Tools stop time is named `time`; Gurobi uses `arrival_time`; the timeline currently understands both. The new typed protocol should normalize these representations without losing fields used by the map, route detail, or timeline.

### Optimization semantics

- Both solvers constrain customer demand by vehicle capacity, enforce customer/depot time windows, model depot starts/returns, and use a dynamic service time of `10 + 2 * units` minutes per customer.
- OR-Tools uses `RoutingModel`, a capacity dimension, a time dimension with waiting slack, guided local search, a path-cheapest-arc initial strategy, a per-used-vehicle fixed cost, and a very large disjunction penalty to discourage dropped customers. It logs periodic elapsed-time messages but does not expose intermediate incumbent statistics.
- Gurobi uses binary arc/visit/vehicle/unserved variables, flow and start/end constraints, capacity and Big-M time-window constraints, and an objective consisting of distance, vehicle-use penalty, and a large unserved-customer penalty. `MIPGap` and `TimeLimit` are applied; its callback logs incumbent statistics about every five seconds when a solution event occurs.
- API defaults are 60 seconds, OR-Tools, distance weight 1.0, MIP gap 0.01; vehicle penalty defaults are settings-based (100000 for OR-Tools and 1000 for Gurobi). The solver wrappers have their own defaults; the orchestration service is the source of API behavior.
- The objective scaling differs between the two implementations (OR-Tools scales distance arc costs by 100; Gurobi's distance objective uses matrix values directly). Do not assume their numeric objective values are interchangeable. Preserve each engine independently and compare each against its own baseline.

### OSRM and cache

`DistanceCacheService` requests OSRM's driving route endpoint with coordinates serialized as `longitude,latitude;longitude,latitude`, converts meters/seconds to kilometers/minutes, and stores each directed pair plus morning/afternoon/evening times. The current cache key hashes coordinates rounded to six decimals. It writes the reverse pair as symmetric. OSRM traffic is estimated from baseline duration (morning +15%, afternoon baseline, evening +10%); it is not live traffic data. If OSRM fails, Haversine distance and a 40 km/h estimate are used for all three periods.

`SolverService` selects a traffic matrix for each customer according to that customer's window start (before noon, noon-18:00, after 18:00); return-to-depot travel uses the afternoon matrix. Time values are scaled by 100 for solver precision. The local ignored `distance_cache.db` was inspected without reading row values: its tables are `locations(location_hash, latitude, longitude, created_at)` and `distances(from_hash, to_hash, distance_km, time_morning_min, time_afternoon_min, time_evening_min, updated_at)`.

## 5. Target architecture

```text
Flutter Web (Material 3)
        | generated Serverpod client
        v
Serverpod Dart API and orchestration ---- Serverpod-managed PostgreSQL
        |
        | private, authenticated job/worker contract
        v
Python optimization worker (container on Python-capable hosting)
        |-- existing OR-Tools implementation
        |-- existing Gurobi implementation and license configuration
        |-- OSRM access and Haversine fallback
```

### Flutter

Use the Serverpod-generated client and typed models rather than hand-maintained REST maps. Keep the existing JSON shape accepted and parsed at the UI boundary. Split the UI into feature areas matching the current behavior: dashboard/controls, file upload and validation, customer/vehicle selection, optimization settings, job status/logs, results, route details, timeline, and map. Use Material 3 responsive layouts and `flutter_map` for route lines, markers, and stop details. Preserve [latitude, longitude] in application models and only swap to longitude/latitude at OSRM boundaries.

### Serverpod

Use the installed Serverpod CLI generation line (4.1.x; local CLI observed as 4.1.2) and its generated full-stack project conventions. Serverpod endpoints validate typed problem/config models, create jobs, report health, provide example inputs, and return job status, ordered logs, results, routes, and distance data. Use Serverpod authentication or server-side authorization; do not put the existing shared API key in Flutter build-time variables.

Serve the Flutter Web build from the Serverpod web server (`FlutterRoute`) so the web UI and API can share an origin. Keep the worker URL and worker credential in server-side environment/password configuration.

### Optimization jobs and logs

The API should validate and persist a job, return a unique job ID immediately, and not hold an endpoint request open for the entire optimization. Store state transitions (`queued`, `running`, `succeeded`, `failed`, with cancellation only if implemented), start/finish times, attempt/lease data, selected solver and exact parameters. A worker claims jobs atomically, making retries idempotent and preventing two workers from running the same job concurrently. Store sequenced log records and the final result so a disconnected browser can resume.

Use polling for durable log/result retrieval in the first migration: `getJob(jobId)` and `getLogs(jobId, afterSequence, limit)` allow Flutter to recover after disconnects. Serverpod 4.1 also supports typed WebSocket streaming; it can be added as a latency optimization later, backed by the same persisted log stream. Serverpod future calls are at-least-once and require idempotency; the current Serverpod Cloud documentation also limits them to Growth/Enterprise plans and excludes scale-to-zero projects. They do not remove the need for a Python worker.

### Python optimization worker

Keep the current Python solver modules intact behind a small private worker adapter. Define a versioned typed job/result contract and capture raw input/config for reproducibility. The worker must not be a public unauthenticated API. Persist progress and terminal status through a narrow authenticated server-to-worker interface. Deploy this worker separately in an environment that supports the native OR-Tools dependencies and the required Gurobi version/license. Serverpod Cloud can host the Dart API and database, but the Python worker's hosting, network access, secrets, scaling, and cost are separate deployment requirements.

## 6. Proposed PostgreSQL/Serverpod schema

Use Serverpod `.spy.yaml` table models and generated migrations. Serverpod supplies its own integer row IDs; expose a separate `UuidValue jobId` for client-facing job identity. The following is a logical schema to refine against the generated Serverpod version, not a claim that migrations already exist.

| Model/table | Important fields and relations |
|---|---|
| `OptimizationJob` | Public UUID, status, created/started/finished timestamps, requested solver and all optimization parameters, progress/attempt/lease fields, input payload JSONB (retention-controlled), error code/message; index by status/created time |
| `ProblemVehicle` | Job FK, original ID, capacity, time-window bounds, source index; index by job |
| `ProblemCustomer` | Job FK, original ID/name, latitude/longitude, date-specific demand/window, service-time input, source index; index by job and ID |
| `OptimizationResult` | One-to-one job FK, solver/status, objective, execution time, summary metrics, dropped-customer data, result schema version |
| `VehicleRoute` | Result/job FK, vehicle source index/ID, distance, load, capacity/saturation, total/travel/service duration; index by job and vehicle |
| `RouteStop` | Route FK, ordered sequence, depot/customer type and reference, coordinates, arrival/departure, time window, demand, load-before/after, segment distance/time; unique `(route_id, sequence)` |
| `OptimizationLog` | Job FK, monotonically increasing sequence, timestamp, severity, message; unique `(job_id, sequence)` and index for cursor-based reads |
| `CachedLocation` | Existing rounded-coordinate hash, latitude/longitude, created/updated time; unique hash |
| `DistanceCacheEntry` | Origin/destination location FKs or hashes, distance km, three time-period durations, updated time; unique directed `(from, to)` pair |

Keep original input JSON and solver result data only as long as required; normalized problem/route rows support selection, querying, and display. Store location data only for the job/cache purpose, restrict access, and define cache/job retention before production. Make the cache lookup indexed and preserve the existing cache key/rounding and stored period values during the initial import.

The local SQLite cache is not tracked by Git. Add a one-time, restartable SQLite-to-PostgreSQL import utility that copies locations and directed distance rows, verifies counts/checksums and sample lookups, and never deletes the original DB. Existing example JSON files remain unchanged and can be shipped with the Serverpod server as assets.

## 7. Dependency and migration challenges

| Existing dependency/behavior | Migration decision |
|---|---|
| `ortools` Python package | Keep in the Python worker; no verified first-party Dart binding in the project or official language list. Do not substitute heuristics. |
| `gurobipy` and Gurobi license | Keep in the Python worker; validate a supported runtime and license for the selected hosting provider. Gurobi availability remains conditional, as it is today. Never put license data in Flutter or source control. |
| FastAPI / Pydantic | Replace the public API/contracts with Serverpod endpoints and generated protocol models. Keep Python-side validation at the worker boundary until job parity is proven. |
| SQLite | Replace active cache persistence with PostgreSQL via Serverpod ORM; provide a tested, non-destructive import path for the local ignored DB. |
| `urllib` OSRM client and Haversine | Reimplement the distance service in Dart or retain it in the Python worker during the first parity phase. Use coordinate conversion tests and preserve fallbacks and traffic-period multipliers. |
| React / Leaflet / CSS | Replace UI with Flutter Web and Material 3; use `flutter_map` or a comparable Flutter map package. Recreate route/timeline interactions from the existing result contract. |
| SSE logs and in-process thread/lock | Replace with durable job state and log rows plus cursor polling; optional Serverpod typed stream can push updates without becoming the only copy of logs. |
| Static `API_KEY` | Replace browser-exposed shared-key usage with Serverpod authentication/authorization and worker-to-server credentials. |
| Docker Compose | Replace the single backend/frontend stack with Serverpod server/database plus the separately deployed Python worker; keep local developer orchestration as a later deliverable. |

Serverpod documents typed endpoints and models, PostgreSQL ORM/migrations, Flutter Web serving, and typed streams. Serverpod Cloud provisions managed PostgreSQL and applies migrations during deploy. Its managed DB uses PostgreSQL 17 and Cloud-injected credentials; do not commit database credentials or copy them into config files.

## 8. File-by-file migration map

| Existing file(s) | Planned destination/action |
|---|---|
| `src/app.py` | Replace public ASGI bootstrapping with `eco_delvy_server/bin/main.dart` and Serverpod server setup |
| `src/api/__init__.py`, `src/api/routes.py` | `eco_delvy_server/lib/src/endpoints/` (health, examples, validation, optimization jobs, status/log/result/route endpoints) |
| `src/api/dependencies.py` | Serverpod endpoint auth/authorization and internal worker authentication; no shared browser API secret |
| `src/models/domain.py`, `src/models/api.py` | Typed `.spy.yaml` input, config, result, job, route, and exception models; preserve nullable/date-keyed JSON cases |
| `src/core/solvers/base.py`, `src/core/solvers/__init__.py` | Keep as Python worker domain/interface; Serverpod gets a Dart worker-client interface |
| `src/core/solvers/factory.py` | Keep in Python worker; server-side typed solver selector validates `ortools`/`gurobi` |
| `src/core/solvers/ortools_solver.py`, `src/core/solvers/ortools_impl.py` | Preserve in worker unchanged until solver regression tests pass |
| `src/core/solvers/gurobi_solver.py`, `src/core/solvers/gurobi_impl.py` | Preserve in worker unchanged; add license/runtime integration tests and deployment secret setup |
| `src/services/problem_builder.py` | Port input validation/date selection to shared typed Serverpod contract; retain Python normalization adapter and compare payloads during transition |
| `src/services/solver_service.py` | Split into Serverpod job orchestration and worker-side execution; retain Python implementation as a parity baseline until cutover |
| `src/services/distance_cache.py` | Serverpod/Dart distance-cache service using PostgreSQL; import existing SQLite cache; keep a Python adapter as needed for worker parity |
| `src/utils/distance_calculator.py`, `src/utils/time_formatter.py` | Port to Dart utilities with unit tests; preserve units, coordinate order, 5-minute rounding, and formatting |
| `src/config/settings.py`, `src/config/logging.py`, `src/config/__init__.py` | Serverpod run-mode config, Cloud-managed passwords/environment values, and structured Serverpod logging |
| `src/__init__.py`, `src/core/__init__.py`, `src/models/__init__.py`, `src/services/__init__.py`, `src/utils/__init__.py` | Keep package boundaries in the Python worker only where imports still require them; do not mechanically port Python package structure into Dart |
| `webui/src/App.js`, `webui/src/index.js`, `webui/src/App.css`, `webui/src/index.css` | `flutter_app/lib/main.dart`, app shell, theme, routing, responsive dashboard, and view-model/state providers |
| `webui/src/components/FileUpload.js` and `FileUpload.css` | Flutter file picker, JSON parser/validator, uploaded-file status, and example input download |
| `webui/src/components/SelectionModal.js` and `SelectionModal.css` | Customer/vehicle selection feature with individual/select-all/deselect-all behavior and selection persistence |
| `webui/src/components/LogViewer.js` and `LogViewer.css` | Durable log viewer, polling cursor, auto-scroll, errors, and loading/progress state |
| `webui/src/components/SolutionSummary.js` and `SolutionSummary.css` | Material 3 result cards including existing metrics plus objective, solver, and execution time |
| `webui/src/components/RoutesList.js` and `RoutesList.css` | Vehicle route cards and selection/navigation to route details |
| `webui/src/components/RouteMap.js` and `RouteMap.css` | `flutter_map` route detail map, OSRM geometry, stop markers/popups, and straight-line fallback |
| `webui/src/components/Timeline.js` and `Timeline.css` | Flutter timeline preserving ordered travel/service segments, time markers, and vehicle rows |
| `webui/public/index.html`, `webui/package.json`, `webui/README.md` | Retire only after Flutter Web build/serving and deployment docs are verified |
| `inputs/CVRPTW_SMALL.json`, `inputs/CVRPTW_MEDIUM.json`, `inputs/CVRPTW_LARGE.json` | Keep unchanged as example assets and regression fixtures |
| `distance_cache.db` (local ignored file) | Preserve source; import via explicit one-time utility and verify before any manual archival |
| `Dockerfile`, `docker/docker-compose.yml`, `docker/README.md` | Replace with local Serverpod/PostgreSQL and Python worker orchestration; keep deployment instructions consistent with Serverpod Cloud and the worker host |
| `.dockerignore`, `webui/.gitignore` | Revisit ignore rules for generated Flutter/Serverpod artifacts, local env files, and Cloud packaging; never include secrets or local build output |
| `requirements.txt` | Retain only for the Python worker after migration; split worker dependencies from Dart package manifests |
| `README.md`, `.env.example` | Update architecture, local run/deploy, auth, worker and migration instructions after tested phases; do not overwrite local `.env` or other user config |
| `assets/logo.png` | Reuse as EcoDelvy branding in Flutter if the asset is suitable and licensing permits |

Generated Serverpod client/protocol files and migration SQL should be produced by the installed Serverpod CLI, not hand-authored.

## 9. Incremental implementation and test strategy

Do not delete the React/FastAPI implementation until its replacement has feature parity, solver tests pass, and a rollback point exists. The recommended stages are:

1. **Analysis and contracts (complete):** this document, baseline input/output contracts, dependency and hosting decision.
2. **Serverpod/Flutter scaffold:** generate a version-matched full-stack project; verify web serving, generated client, health endpoint, and local PostgreSQL connection.
3. **Typed problem/result contracts and endpoint tests:** preserve fixture JSON and all solver parameter meanings; validate serialization and malformed-input errors.
4. **Python worker adapter:** retain existing engines; add an authenticated, versioned job contract; compare worker results against the unmodified Python baseline.
5. **PostgreSQL persistence and cache migration:** models/migrations for jobs, results, routes, logs, and cache; test fresh DB, restart, duplicate claim, cursor logs, and idempotent SQLite import.
6. **Background execution and logs:** queued/running/terminal status, lease/timeout/retry behavior, durable log polling, browser disconnect/reconnect, and duplicate submission protection.
7. **Flutter feature migration:** upload/validation/download, selection, all optimization controls, logs, summary, route cards/details, map, and timeline; desktop/tablet/mobile widget coverage.
8. **Regression and deployment:** run SMALL, MEDIUM, and LARGE through both available engines against the baseline; test OSRM and fallback, Gurobi only with a real license, Flutter Web build, Serverpod tests/PostgreSQL migration, worker deployment and Cloud configuration.
9. **Cutover and cleanup:** only after acceptance tests pass, switch documented startup paths and then remove obsolete React/FastAPI code in a separate reviewed change with a rollback commit.

Acceptance tests should include:

- Parse all three tracked fixture files without changing their JSON format; invalid/missing fields produce validation errors.
- Select, deselect, and reselect customers/vehicles; verify only selected items are sent and their original identifiers/order remain coherent.
- Run OR-Tools on SMALL, MEDIUM, and LARGE; verify capacity, windows, depot return, service-time arithmetic, dropped-customer behavior, and metrics against the existing solver. Compare feasibility and objective within an agreed tolerance; route order may vary with heuristic/runtime.
- Run Gurobi under a licensed environment; verify `TimeLimit`, `MIPGap`, objective components, dropped-customer reporting, and output against the existing Gurobi baseline. If no license is available, mark this integration unverified rather than claiming success.
- Verify OSRM uses `[lon,lat]` on the wire and `[lat,lon]` in the app; check route, matrix, morning/afternoon/evening values, cache hits, Haversine fallback, and reverse-pair behavior.
- Verify job uniqueness/atomic claims, retry/timeout/failure states, durable ordered logs, final results, and browser reconnect.
- Run Flutter unit/widget tests, responsive checks, and `flutter build web`; run Serverpod code generation, server tests, migrations on clean and existing PostgreSQL, and Cloud packaging checks.

There is no tracked automated test suite in the current repository. At analysis time Flutter 3.50.1, Dart 3.14.0, and Serverpod CLI 4.1.2 are installed; Docker and `psql` are not available. PostgreSQL/Cloud, OSRM network behavior, solver installation, and Gurobi licensing must be verified in the later phases and must not be reported as tested until actually run.

## 10. Decision and risks before implementation

The key architecture decision is settled by dependency compatibility: keep OR-Tools and Gurobi in the private Python worker. Before deployment, choose a Python/container host reachable by Serverpod Cloud and confirm a Gurobi license is permitted there. The public Flutter client must never receive the worker credential or Gurobi secrets.

Other migration risks are preserving solver-specific objective scaling and route-time fields, handling larger JSON bodies (Serverpod endpoint request bodies have a default size limit), migrating the ignored local cache without deleting it, and ensuring Cloud job execution does not rely on unsupported plan features or scale-to-zero behavior. These are explicit acceptance gates, not reasons to substitute algorithms or discard features.

## 11. Official Serverpod references

- [Serverpod 4.1 Quickstart and Cloud deployment](https://docs.serverpod.dev/quickstart)
- [Typed models](https://docs.serverpod.dev/concepts/data-and-the-database/models)
- [Tables and ORM](https://docs.serverpod.dev/concepts/data-and-the-database/database/tables)
- [Migrations](https://docs.serverpod.dev/concepts/data-and-the-database/database/migrations)
- [Typed endpoints](https://docs.serverpod.dev/concepts/endpoints-and-apis)
- [Endpoint streaming](https://docs.serverpod.dev/concepts/endpoints-and-apis/streaming)
- [Serverpod scheduling guarantees](https://docs.serverpod.dev/concepts/scheduling/overview)
- [Flutter Web serving](https://docs.serverpod.dev/concepts/web-server/flutter-web)
- [Serverpod Cloud PostgreSQL](https://docs.serverpod.dev/cloud/concepts/database)
- [Serverpod Cloud scale-to-zero limitations](https://docs.serverpod.dev/cloud/concepts/scale-to-zero)
- [Shipping non-Dart assets](https://docs.serverpod.dev/cloud/guides/ship-non-dart-files)
- [Google OR-Tools language overview](https://developers.google.com/optimization)
