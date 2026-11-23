import unittest

from src.services.problem_builder import ProblemBuilder


class ProblemBuilderTests(unittest.TestCase):
    def test_handles_null_optional_payload_fields(self) -> None:
        payload = {
            "depot": {"location": [38.1, 13.2]},
            "metadata": None,
            "vehicles": [{"capacity_units": 10}],
            "customers": [
                {
                    "location": [38.2, 13.3],
                    "demands_units": None,
                    "demand_units": 4,
                    "time_windows": None,
                    "time_window": {"start_min": 300, "end_min": 600},
                }
            ],
        }

        problem = ProblemBuilder.build_from_payload(payload, "2026-01-01")

        self.assertIsNotNone(problem)
        assert problem is not None
        self.assertEqual(problem["demands"], [0, 4])
        self.assertEqual(problem["time_windows"], [(240, 1260), (300, 600)])

    def test_enrich_routes_handles_null_demands_units(self) -> None:
        payload = {
            "depot": {"location": [38.1, 13.2]},
            "vehicles": [{"capacity_units": 10}],
            "customers": [
                {
                    "location": [38.2, 13.3],
                    "demands_units": None,
                    "demand_units": 4,
                }
            ],
        }
        problem = ProblemBuilder.build_from_payload(payload, "2026-01-01")
        solution = {
            "routes": [
                {
                    "route": [
                        {"location": 0},
                        {"location": 1},
                        {"location": 0},
                    ]
                }
            ]
        }

        enriched = ProblemBuilder.enrich_solution_routes(
            solution,
            problem,
            payload,
            "2026-01-01",
        )

        self.assertEqual(len(enriched), 1)


if __name__ == "__main__":
    unittest.main()
