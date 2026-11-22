import unittest
import os
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

from src.config.settings import Settings

from optimization_service.worker import validate_job


def valid_job() -> dict:
    return {
        "jobId": 1,
        "leaseToken": "opaque-worker-lease",
        "payload": {
            "depot": {"location": [38.1, 13.2]},
            "vehicles": [{"capacity_units": 10}],
            "customers": [{"location": [38.2, 13.3], "demand_units": 4}],
        },
        "solver": "ortools",
        "timeLimit": 60,
        "vehiclePenaltyWeight": None,
        "distanceWeight": 1.0,
        "mipGap": 0.01,
    }


class ValidateJobTests(unittest.TestCase):
    def test_settings_ignore_serverpod_worker_extra_keys_from_dotenv(self) -> None:
        with TemporaryDirectory() as temp_dir:
            env_file = Path(temp_dir) / ".env"
            env_file.write_text(
                "\n".join([
                    "serverpod_db_password=ignored",
                    "serverpod_test_db_password=ignored",
                    "serverpod_worker_api_url=http://localhost:8082",
                    "optimization_worker_token=ignored",
                    "worker_poll_interval_seconds=5",
                ]),
                encoding="utf-8",
            )
            previous = os.getcwd()
            try:
                os.chdir(temp_dir)
                Settings()
            finally:
                os.chdir(previous)

    def test_preserves_date_keyed_problem_payload(self) -> None:
        job = valid_job()
        job["payload"]["customers"][0] = {
            "location": [38.2, 13.3],
            "demands_units": {"2026-01-01": 4},
        }

        self.assertEqual(validate_job(job)["payload"], job["payload"])

    def test_rejects_invalid_worker_settings(self) -> None:
        invalid_values = {
            "solver": "unknown",
            "timeLimit": 0,
            "distanceWeight": 11,
            "mipGap": 0.9,
            "jobId": True,
            "vehiclePenaltyWeight": float("nan"),
        }
        for field, value in invalid_values.items():
            with self.subTest(field=field):
                job = valid_job()
                job[field] = value
                with self.assertRaises(ValueError):
                    validate_job(job)

    def test_rejects_invalid_problem_data_and_missing_lease(self) -> None:
        invalid_jobs = []

        invalid_coordinates = valid_job()
        invalid_coordinates["payload"]["customers"][0]["location"] = [91, 13.3]
        invalid_jobs.append(invalid_coordinates)

        invalid_time_window = valid_job()
        invalid_time_window["payload"]["customers"][0]["time_window"] = {
            "start_min": 600,
            "end_min": 300,
        }
        invalid_jobs.append(invalid_time_window)

        missing_lease = valid_job()
        missing_lease.pop("leaseToken")
        invalid_jobs.append(missing_lease)

        for job in invalid_jobs:
            with self.subTest(job=job):
                with self.assertRaises(ValueError):
                    validate_job(job)
