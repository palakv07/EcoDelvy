import os
import sqlite3
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from src.services.distance_cache import DistanceCacheService


class DistanceCachePathTests(unittest.TestCase):
    def test_relative_database_path_survives_working_directory_change(self):
        original_cwd = Path.cwd()

        with tempfile.TemporaryDirectory() as temp_dir:
            startup_dir = Path(temp_dir) / "startup"
            runtime_dir = Path(temp_dir) / "runtime"
            startup_dir.mkdir()
            runtime_dir.mkdir()

            try:
                os.chdir(startup_dir)
                cache = DistanceCacheService(db_path="distance_cache.db")

                os.chdir(runtime_dir)
                with patch.object(cache, "_fetch_from_osrm", return_value=(10.0, 15.0)):
                    distance_matrix, *_ = cache.populate_matrix_all_times(
                        [(40.0, -73.0), (40.1, -73.1)]
                    )

                self.assertEqual(distance_matrix[0][1], 10.0)
                self.assertFalse((runtime_dir / "distance_cache.db").exists())

                connection = sqlite3.connect(cache.db_path)
                try:
                    tables = {
                        row[0]
                        for row in connection.execute(
                            "SELECT name FROM sqlite_master WHERE type='table'"
                        )
                    }
                finally:
                    connection.close()

                self.assertIn("distances", tables)
            finally:
                os.chdir(original_cwd)


if __name__ == "__main__":
    unittest.main()
