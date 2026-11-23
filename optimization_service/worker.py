"""Poll Serverpod for persisted jobs and execute them with the original solvers."""

import asyncio
import json
import logging
import math
import os
import urllib.error
import urllib.request
from typing import Any

from src.services.solver_service import SolverService

logger = logging.getLogger(__name__)
_solver_service: SolverService | None = None


def _validate_location(value: Any, field: str) -> None:
    if not isinstance(value, list) or len(value) != 2:
        raise ValueError(f"{field} must contain [latitude, longitude].")
    latitude, longitude = value
    if (
        isinstance(latitude, bool)
        or isinstance(longitude, bool)
        or not isinstance(latitude, (int, float))
        or not isinstance(longitude, (int, float))
        or not math.isfinite(latitude)
        or not math.isfinite(longitude)
        or not -90 <= latitude <= 90
        or not -180 <= longitude <= 180
    ):
        raise ValueError(f"{field} must contain valid geographic coordinates.")


def _validate_time_window(value: Any, field: str) -> None:
    if value is None:
        return
    if not isinstance(value, dict):
        raise ValueError(f"{field} must be an object.")
    start = value.get("start_min")
    end = value.get("end_min")
    if (
        not isinstance(start, int)
        or isinstance(start, bool)
        or not isinstance(end, int)
        or isinstance(end, bool)
        or not 0 <= start <= end <= 1440
    ):
        raise ValueError(f"{field} must contain valid start_min and end_min values.")


def _validate_demand(value: Any, field: str) -> None:
    if (
        not isinstance(value, int)
        or isinstance(value, bool)
        or value < 0
    ):
        raise ValueError(f"{field} must be a non-negative integer.")


def validate_job(value: Any) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValueError("The claimed job must be a JSON object.")

    job_id = value.get("jobId")
    if not isinstance(job_id, int) or isinstance(job_id, bool) or job_id < 1:
        raise ValueError("The claimed job has an invalid jobId.")

    lease_token = value.get("leaseToken")
    if not isinstance(lease_token, str) or not lease_token:
        raise ValueError("The claimed job has no worker lease token.")

    payload = value.get("payload")
    if not isinstance(payload, dict):
        raise ValueError("The claimed job has no problem payload.")
    if not isinstance(payload.get("depot"), dict):
        raise ValueError("The problem must include a depot object.")
    if not isinstance(payload.get("vehicles"), list):
        raise ValueError("The problem must include a vehicles array.")
    if not isinstance(payload.get("customers"), list):
        raise ValueError("The problem must include a customers array.")
    _validate_location(payload["depot"].get("location"), "depot.location")

    vehicles = payload["vehicles"]
    if not vehicles:
        raise ValueError("The problem must include at least one vehicle.")
    for index, vehicle in enumerate(vehicles):
        if not isinstance(vehicle, dict):
            raise ValueError(f"vehicles[{index}] must be an object.")
        capacity = vehicle.get("capacity_units")
        if (
            not isinstance(capacity, int)
            or isinstance(capacity, bool)
            or capacity < 0
        ):
            raise ValueError(
                f"vehicles[{index}].capacity_units must be a non-negative integer."
            )
        _validate_time_window(
            vehicle.get("time_window"),
            f"vehicles[{index}].time_window",
        )

    customers = payload["customers"]
    if not customers:
        raise ValueError("The problem must include at least one customer.")
    for index, customer in enumerate(customers):
        if not isinstance(customer, dict):
            raise ValueError(f"customers[{index}] must be an object.")
        _validate_location(
            customer.get("location"),
            f"customers[{index}].location",
        )
        demand = customer.get("demand_units")
        if demand is not None:
            _validate_demand(demand, f"customers[{index}].demand_units")
        date_demands = customer.get("demands_units")
        if date_demands is not None:
            if not isinstance(date_demands, dict):
                raise ValueError(
                    f"customers[{index}].demands_units must be an object keyed by date."
                )
            for date, demand_value in date_demands.items():
                _validate_demand(
                    demand_value,
                    f"customers[{index}].demands_units.{date}",
                )
        _validate_time_window(
            customer.get("time_window"),
            f"customers[{index}].time_window",
        )
        date_windows = customer.get("time_windows")
        if date_windows is not None:
            if not isinstance(date_windows, dict):
                raise ValueError(
                    f"customers[{index}].time_windows must be an object keyed by date."
                )
            for date, time_window in date_windows.items():
                _validate_time_window(
                    time_window,
                    f"customers[{index}].time_windows.{date}",
                )

    metadata = payload.get("metadata")
    if metadata is not None:
        if not isinstance(metadata, dict):
            raise ValueError("metadata must be an object.")
        _validate_time_window(
            metadata.get("depot_time_window"),
            "metadata.depot_time_window",
        )

    solver = value.get("solver")
    if not isinstance(solver, str) or solver not in {"ortools", "gurobi"}:
        raise ValueError("The claimed job uses an unsupported solver.")

    time_limit = value.get("timeLimit")
    if (
        not isinstance(time_limit, int)
        or isinstance(time_limit, bool)
        or not 1 <= time_limit <= 3600
    ):
        raise ValueError("The time limit must be between 1 and 3600 seconds.")

    distance_weight = value.get("distanceWeight")
    if (
        not isinstance(distance_weight, (int, float))
        or isinstance(distance_weight, bool)
        or not math.isfinite(distance_weight)
        or not 0.1 <= distance_weight <= 10
    ):
        raise ValueError("The distance weight must be between 0.1 and 10.")

    mip_gap = value.get("mipGap")
    if (
        not isinstance(mip_gap, (int, float))
        or isinstance(mip_gap, bool)
        or not math.isfinite(mip_gap)
        or not 0.001 <= mip_gap <= 0.5
    ):
        raise ValueError("The MIP gap must be between 0.001 and 0.5.")

    vehicle_penalty = value.get("vehiclePenaltyWeight")
    if vehicle_penalty is not None and (
        not isinstance(vehicle_penalty, (int, float))
        or isinstance(vehicle_penalty, bool)
        or not math.isfinite(vehicle_penalty)
        or vehicle_penalty < 0
    ):
        raise ValueError("The vehicle penalty weight must be non-negative.")

    return value


def _serverpod_request(path: str, payload: dict[str, Any] | None = None) -> Any:
    base_url = (
        os.environ.get("SERVERPOD_WORKER_API_URL", "").strip()
        or "http://localhost:8082"
    ).rstrip("/")
    token = (
        os.environ.get("OPTIMIZATION_WORKER_TOKEN", "").strip()
        or "cvrptw-worker-token-dev-secret-2026"
    )
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        f"{base_url}/internal/worker/{path}",
        data=body,
        headers={
            "Content-Type": "application/json",
            "X-Worker-Token": token,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            if response.status == 204:
                return None
            response_body = response.read(10 * 1024 * 1024)
            if not response_body:
                return None
            return json.loads(response_body.decode("utf-8"))
    except urllib.error.HTTPError as error:
        detail = error.read(2048).decode("utf-8", errors="replace")
        raise RuntimeError(
            f"Serverpod worker endpoint returned HTTP {error.code}: {detail}"
        ) from error


class _AsyncLogHandler(logging.Handler):
    def __init__(
        self,
        loop: asyncio.AbstractEventLoop,
        messages: asyncio.Queue[str | None],
    ) -> None:
        super().__init__()
        self._loop = loop
        self._messages = messages
        self.setFormatter(
            logging.Formatter(
                "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
            )
        )

    def emit(self, record: logging.LogRecord) -> None:
        try:
            self._loop.call_soon_threadsafe(
                self._messages.put_nowait,
                self.format(record),
            )
        except RuntimeError:
            self.handleError(record)


async def _forward_logs(
    job_id: int,
    lease_token: str,
    messages: asyncio.Queue[str | None],
) -> None:
    batch: list[str] = []
    while True:
        message = await messages.get()
        if message is None:
            if batch:
                await asyncio.to_thread(
                    _serverpod_request,
                    "logs",
                    {
                        "jobId": job_id,
                        "leaseToken": lease_token,
                        "messages": batch,
                    },
                )
            return
        batch.append(message)
        if len(batch) >= 20:
            await asyncio.to_thread(
                _serverpod_request,
                "logs",
                {
                    "jobId": job_id,
                    "leaseToken": lease_token,
                    "messages": batch,
                },
            )
            batch = []


async def _renew_lease(
    job_id: int,
    lease_token: str,
    stop: asyncio.Event,
) -> None:
    while not stop.is_set():
        try:
            await asyncio.to_thread(
                _serverpod_request,
                "lease",
                {"jobId": job_id, "leaseToken": lease_token},
            )
        except Exception:
            logger.exception("Could not renew lease for optimization job %s.", job_id)

        try:
            await asyncio.wait_for(stop.wait(), timeout=30)
        except asyncio.TimeoutError:
            pass


def _get_solver_service() -> SolverService:
    global _solver_service
    if _solver_service is None:
        _solver_service = SolverService()
    return _solver_service


async def process_job(job_data: Any) -> None:
    try:
        job = validate_job(job_data)
    except ValueError as error:
        if (
            isinstance(job_data, dict)
            and isinstance(job_data.get("jobId"), int)
            and not isinstance(job_data.get("jobId"), bool)
            and isinstance(job_data.get("leaseToken"), str)
        ):
            await asyncio.to_thread(
                _serverpod_request,
                "complete",
                {
                    "jobId": job_data["jobId"],
                    "leaseToken": job_data["leaseToken"],
                    "result": None,
                    "errorMessage": str(error),
                },
            )
        raise

    job_id = job["jobId"]
    lease_token = job["leaseToken"]
    messages: asyncio.Queue[str | None] = asyncio.Queue()
    loop = asyncio.get_running_loop()
    log_handler = _AsyncLogHandler(loop, messages)
    root_logger = logging.getLogger()
    root_logger.addHandler(log_handler)
    log_forwarder = asyncio.create_task(
        _forward_logs(job_id, lease_token, messages)
    )
    heartbeat_stop = asyncio.Event()
    heartbeat = asyncio.create_task(
        _renew_lease(job_id, lease_token, heartbeat_stop)
    )

    result: dict[str, Any] | None = None
    error_message: str | None = None
    try:
        result = await asyncio.to_thread(
            _get_solver_service().solve,
            payload=job["payload"],
            solver_type=job["solver"],
            time_limit=job["timeLimit"],
            vehicle_penalty_weight=job["vehiclePenaltyWeight"],
            distance_weight=job["distanceWeight"],
            mip_gap=job["mipGap"],
        )
        if result.get("status") in {"error", "no_solution_found"}:
            error_message = result.get("message", "The solver did not find a solution.")
    except Exception as error:
        logger.exception("Optimization job %s failed.", job_id)
        error_message = str(error) or error.__class__.__name__
    finally:
        root_logger.removeHandler(log_handler)
        await messages.put(None)

    try:
        await log_forwarder
    except Exception as error:
        logger.exception("Could not persist logs for optimization job %s.", job_id)
        error_message = (
            f"{error_message}; log persistence failed: {error}"
            if error_message
            else f"Optimization log persistence failed: {error}"
        )
    finally:
        heartbeat_stop.set()
        await heartbeat

    completion = {
        "jobId": job_id,
        "leaseToken": lease_token,
        "result": result,
        "errorMessage": error_message,
    }
    await asyncio.to_thread(_serverpod_request, "complete", completion)


async def dispatch_jobs(stop: asyncio.Event, poll_interval: float) -> None:
    while not stop.is_set():
        try:
            job = await asyncio.to_thread(_serverpod_request, "claim")
            if job is not None:
                await process_job(job)
                continue
        except asyncio.CancelledError:
            raise
        except Exception as error:
            error_str = str(error)
            if "10061" in error_str or "Connection refused" in error_str:
                logger.warning(
                    "Waiting for Serverpod web service at %s...",
                    os.environ.get("SERVERPOD_WORKER_API_URL", "http://localhost:8082"),
                )
            else:
                logger.exception("Worker could not claim or process a job: %s", error)

        try:
            await asyncio.wait_for(stop.wait(), timeout=poll_interval)
        except asyncio.TimeoutError:
            pass


def worker_configuration() -> tuple[str, str, float]:
    serverpod_url = (
        os.environ.get("SERVERPOD_WORKER_API_URL", "").strip()
        or "http://localhost:8082"
    )
    token = (
        os.environ.get("OPTIMIZATION_WORKER_TOKEN", "").strip()
        or "cvrptw-worker-token-dev-secret-2026"
    )
    if not serverpod_url:
        raise RuntimeError("SERVERPOD_WORKER_API_URL must be configured.")
    if not token:
        raise RuntimeError("OPTIMIZATION_WORKER_TOKEN must be configured.")

    try:
        poll_interval = float(os.environ.get("WORKER_POLL_INTERVAL_SECONDS", "2"))
    except ValueError as error:
        raise RuntimeError("WORKER_POLL_INTERVAL_SECONDS must be numeric.") from error
    if not 0.2 <= poll_interval <= 60:
        raise RuntimeError(
            "WORKER_POLL_INTERVAL_SECONDS must be between 0.2 and 60."
        )
    return serverpod_url.rstrip("/"), token, poll_interval


if __name__ == "__main__":
    from pathlib import Path
    from dotenv import load_dotenv
    from src.config import setup_logging

    env_path = Path(__file__).resolve().parent.parent / ".env"
    if env_path.exists():
        load_dotenv(env_path)
    else:
        load_dotenv()
    setup_logging()

    url, _, interval = worker_configuration()
    logger.info("EcoDelvy optimization worker running (polling %s every %gs)...", url, interval)
    stop_event = asyncio.Event()
    try:
        asyncio.run(dispatch_jobs(stop_event, interval))
    except (KeyboardInterrupt, SystemExit):
        stop_event.set()
        logger.info("Optimization worker stopped.")
