# EcoDelvy

EcoDelvy is a capacitated vehicle-routing-with-time-windows (CVRPTW) application using Flutter Web, Serverpod, PostgreSQL, and a private Python optimization worker.

## Architecture

- `eco_delvy_flutter/`: Flutter Web frontend client
- `eco_delvy_server/`: Serverpod API (port 8080), PostgreSQL models, job queues, logs, and worker internal endpoints (port 8082)
- `eco_delvy_client/`: generated Serverpod Dart client
- `optimization_service/`: private Python optimization worker running Google OR-Tools and Gurobi solvers
- `src/`: core solver implementation, distance caching, and problem builders
- `inputs/`: tracked CVRPTW example JSON fixtures (`CVRPTW_SMALL.json`, `CVRPTW_MEDIUM.json`, `CVRPTW_LARGE.json`)

## How Job Processing Works

1. In Flutter Web, you upload a problem JSON file and click **Optimize**.
2. Flutter submits the job to Serverpod API (`http://localhost:8080`). Serverpod marks it as `queued` in PostgreSQL.
3. The **Python Optimization Worker** polls Serverpod (`http://localhost:8082/internal/worker/claim`), claims the job, runs the OR-Tools / Gurobi solver, streams execution logs, and posts the completed routes back to Serverpod.
4. Serverpod stores the solution and marks the job `succeeded`.
5. Flutter polls Serverpod, receives the solution, and displays the routes, interactive map, summary cards, and timeline.

> **Note**: Both Serverpod AND the Python worker must be running for optimization jobs to complete and return output for your JSON files.

## Local Setup & Quick Start

### 1. Start PostgreSQL Database
```powershell
serverpod database start --server-dir eco_delvy_server
# Or using docker compose inside eco_delvy_server:
# docker compose up -d
```
The development PostgreSQL runs on port `8190`.

### 2. Start Serverpod Backend
```powershell
cd eco_delvy_server
serverpod start --no-flutter
```
Serverpod serves:
- API endpoint: `http://localhost:8080`
- Insights tool: `http://localhost:8081`
- Web server & worker routes: `http://localhost:8082`

### 3. Start the Python Optimization Worker
In a new terminal window:
```powershell
cd EcoDelvy
.\run_worker.ps1
# Or:
# .\.venv\Scripts\python.exe -m optimization_service.worker
```
The worker connects to Serverpod on port `8082` and automatically processes queued jobs.

### 4. Run Flutter Web Frontend

There are two ways to run the Flutter frontend:

#### Option A (Instant Load via Serverpod Web Server - Recommended)
Build the Flutter web app once:
```powershell
cd eco_delvy_server
serverpod run flutter_build
```
This builds the Flutter app and copies it to `eco_delvy_server/web/app`.
Now Serverpod serves your Flutter app directly at **`http://localhost:8082/`** instantly with **zero compilation wait time**!

#### Option B (Development Mode)
If actively developing Flutter UI code:
```powershell
cd eco_delvy_flutter
flutter run -d chrome --web-port 3000
```
*Tip*: Using `-d chrome` supports hot-restart and is much faster than `-d web-server`.

## Worker & Serverpod Security
The worker and Serverpod communicate using a shared secret token:
- In `eco_delvy_server/config/passwords.yaml`: `shared.optimizationWorkerToken`
- In `EcoDelvy/.env`: `OPTIMIZATION_WORKER_TOKEN`
Both default to `cvrptw-worker-token-dev-secret-2026` for seamless local development.

## Testing
```powershell
# Python solver and worker tests
Set-Location EcoDelvy
.\.venv\Scripts\python.exe -m unittest optimization_service.test_worker -v
.\.venv\Scripts\python.exe -m unittest discover -s tests -v

# Serverpod server tests
cd eco_delvy_server
dart test

# Flutter web tests
cd ..\eco_delvy_flutter
flutter test
```
