# EcoDelvy

EcoDelvy is a capacitated vehicle-routing-with-time-windows application using Flutter Web, Serverpod, PostgreSQL, FastAPI, and a private Python optimization worker.

## Architecture

- `eco_delvy_flutter/`: Flutter Web client
- `eco_delvy_server/`: Serverpod API, authentication, PostgreSQL models, jobs, logs, and worker routes
- `eco_delvy_client/`: generated Serverpod client
- `optimization_service/`: private Python optimization worker
- `src/`: existing solver and problem-building implementation
- `webui/`: legacy React and FastAPI interface
- `inputs/`: tracked CVRPTW example fixtures

## Local setup

### 1. Configure Python

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Set `AUTH_SECRET_KEY` in `.env` to the generated value. The legacy UI can use `AUTH_EMAIL` and `AUTH_PASSWORD`. Keep `.env` and all passwords out of Git.

### 2. Configure worker and Serverpod secrets

Set matching values:

```text
OPTIMIZATION_WORKER_TOKEN=<long-random-secret>
SERVERPOD_WORKER_API_URL=http://localhost:8082
```

Add the same secret to the git-ignored Serverpod password file:

```yaml
# eco_delvy_server/config/passwords.yaml
shared:
  optimizationWorkerToken: '<same-long-random-token>'
```

Deployments may instead set `SERVERPOD_PASSWORD_optimizationWorkerToken`.

### 3. Start PostgreSQL

```powershell
serverpod database start --server-dir eco_delvy_server
```

The development database uses port `8190`.

### 4. Start Serverpod

```powershell
cd eco_delvy_server
serverpod start --no-docker --no-flutter --no-attach
```

Serverpod serves:

- API: `http://localhost:8080`
- Insights: `http://localhost:8081`
- Web and worker routes: `http://localhost:8082`

### 5. Start the Python worker

```powershell
cd ..
.\.venv\Scripts\Activate.ps1
python -m uvicorn optimization_service.app:app --host 127.0.0.1 --port 8001
```

The worker URL must be the Serverpod web-server origin, not the API origin.

### 6. Run Flutter Web

```powershell
cd eco_delvy_flutter
flutter pub get
flutter run -d chrome --web-port 3000
```

The fixed origin `http://localhost:3000` is allowed in the development Serverpod configuration.

## Legacy FastAPI and React UI

```powershell
python -m uvicorn src.app:app --host 127.0.0.1 --port 8000
```

Authentication uses an HttpOnly session cookie. Start the React UI through its existing webui scripts and keep `REACT_APP_API_URL` pointed at the FastAPI URL.

## Docker worker

```powershell
cd optimization_service
docker compose --env-file ..\.env up --build
```

Set `SERVERPOD_WORKER_API_URL`, `OPTIMIZATION_WORKER_TOKEN`, and optional OSRM or Gurobi settings for the worker container.

## Testing

```powershell
.\.venv\Scripts\python.exe -m unittest optimization_service.test_worker -v
.\.venv\Scripts\python.exe -m unittest discover -s tests -v

dart analyze eco_delvy_server
cd eco_delvy_server
dart test
serverpod generate

cd ..\eco_delvy_flutter
flutter analyze
flutter test
flutter build web --release
```

## Production placeholders

Before deployment, configure real database credentials and replace `examplepod.com` placeholders in `eco_delvy_server/config/production.yaml` and `eco_delvy_server/config/staging.yaml`.
