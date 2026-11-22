import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXAMPLE_NAMES = (
    "CVRPTW_SMALL.json",
    "CVRPTW_MEDIUM.json",
    "CVRPTW_LARGE.json",
)


class ServerAssetTests(unittest.TestCase):
    def test_server_examples_match_the_tracked_inputs(self) -> None:
        for name in EXAMPLE_NAMES:
            with self.subTest(name=name):
                source = (ROOT / "inputs" / name).read_bytes()
                packaged = (
                    ROOT / "eco_delvy_server" / "assets" / "inputs" / name
                ).read_bytes()
                self.assertEqual(packaged, source)


if __name__ == "__main__":
    unittest.main()
